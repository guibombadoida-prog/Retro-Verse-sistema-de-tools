-- EscudoBloqueador_Server_V6.lua
-- Script DENTRO da Tool "Escudo Bloqueador"
-- SUBSTITUI: ServerScript_EscudoBloqueador_V5.lua  (REMOVER a V5)
--
-- MECÂNICA (preservada da V5): redução passiva de dano no portador, reflexão
-- de parte do dano no atacante e uma habilidade extra (Q) que teleporta o
-- portador até o aliado sob ataque e repele o agressor.
--
-- O QUE MUDOU NA V6
--   [FIX] AncestryChanged -> Tool.Destroying
--   [FIX] Welds manuais + lerp -> R6CFrameAnimator + Poses (§10)
--   [FIX] efeitos criados no servidor -> VFXRemote (§12.11)
--   [FIX] workspace:GetChildren() por frame -> detectar() (§12.8)
--   [MIG] A redução é mecânica da própria Tool, com volta garantida
--         (§12.10 — redução é regra compartilhada, sai da Tool).
--         Sem o NucleoCombate instalado, cai num FALLBACK local que corrige
--         apenas a vida do PORTADOR, com trava anti-recursão. Esse fallback
--         deve sumir quando o Núcleo entrar no place.
--   [ADD] Values §12.4, modo preciso §12.6, tag creator §12.7, recarga §12.9

local ARQUETIPO  = "SUPORTE"
local RIG_SUFIXO = "EscudoBloqueador"

local CFG = {
	-- ===== PASSIVO =====
	REDUCAO_PORTADOR = 0.25,
	REFLEXAO_ATAQUE  = 0.15,
	ALCANCE_ATACANTE = 60,

	-- ===== PROTEÇÃO ATIVA (Q) =====
	ALCANCE_PROTECAO = 15,
	RECARGA_PROTECAO = 8,
	REFLEXAO_PROTECAO = 0.52,
	FORCA_REPULSAO   = 90,

	-- ===== VISUAL =====
	COR_BLOQUEIO     = Color3.fromRGB(0, 178, 255),
	COR_REFLEXO      = Color3.fromRGB(255, 0, 0),
	COR_PROTECAO     = Color3.fromRGB(0, 255, 0),

	-- ===== NPC =====
	NPC_ALCANCE      = 50,
	NPC_RECARGA      = 8,
}

--═══════════════════════════════════════════════════════════════
-- NÚCLEO COMPARTILHADO (§12.6 — modo preciso, sempre com guarda)
-- Nada aqui reimplementa regra de combate de terceiro:
-- ele decide. Quando não existe, a Tool cai num guard mínimo (alvo vivo
-- e diferente do portador) — TakeDamage já respeita ForceField nativo.
--═══════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local Tool   = script.Parent
local Handle = Tool:WaitForChild("Handle")

local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Poses     = require(Tool:WaitForChild("Poses"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

local RemoteEvent = Tool:WaitForChild("RemoteEvent")   -- entrada: cliente -> servidor
local VFXRemote   = Tool:WaitForChild("VFXRemote")     -- saída: servidor -> cliente (unidirecional)

-- Values declarados na Tool (§12.4) — todos opcionais
local function lerValue(nome, padrao)
	local v = Tool:FindFirstChild(nome)
	if v and v.Value ~= nil and v.Value ~= "" then return v.Value end
	return padrao
end

local owner, character, humanoid, rootpart

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA. `Vector3.new(0/0, 0/0, 0/0)` é um
--    `Vector3` legítimo para o `typeof`; um cliente modificado manda isso,
--    `.Unit` devolve NaN, e força NaN envenena a assembly do alvo. Nenhum
--    `pcall` pega, porque não há erro — a conta só não tem resultado.
--
--    `n ~= n` é o único teste de NaN em Lua: NaN é o único valor que não é
--    igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda junto.
--
-- E RATE LIMIT É DO SERVIDOR. O `Client` limita a taxa dele e isso não vale
-- nada: quem manda o pacote é o cliente, e cliente modificado manda o quanto
-- quiser. O limite que conta é o daqui.
--
-- Revisão do Codex no PR #1, item P1.6.
--═══════════════════════════════════════════════════════════════

local MIRA_MAX = 400
local PEDIDOS_POR_SEG = 30

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not rootpart then return nil end
	local delta = v - rootpart.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > MIRA_MAX then
		return rootpart.Position + delta.Unit * MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem abusa é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= PEDIDOS_POR_SEG
end
local equipped = false
local rig      = nil

-- Registro de tudo que nasce fora da Tool (§ limpeza)
local Ativos = {
	Partes      = {},
	Sons        = {},
	Conexoes    = {},
	Cancelar    = {},   -- funções de cancelamento devolvidas pelo Núcleo
}

local function guardarParte(p, vida)
	table.insert(Ativos.Partes, p)
	if vida then Debris:AddItem(p, vida) end
	return p
end

local function guardarConexao(c)
	table.insert(Ativos.Conexoes, c)
	return c
end

local function guardarCancelamento(fn)
	if type(fn) == "function" then table.insert(Ativos.Cancelar, fn) end
	return fn
end

--── VFX: o servidor TRANSMITE, nunca emite (§12.11) ──
local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

--── Alvo válido ──
local function podeAtingir(alvoHum, alvoChar)
	if not (alvoHum and alvoChar) then return false end
	if alvoChar == character then return false end
	if alvoHum.Health <= 0 then return false end
	return true
end

--── Crédito de abate — ORDEM DAS PROPRIEDADES (§12.7) ──
local function creditar(alvoHum)
	if not owner then return end
	local antigo = alvoHum:FindFirstChild("creator")
	if antigo then antigo.Parent = nil end
	local credito = Instance.new("ObjectValue")
	credito.Name   = "creator"   -- 1º
	credito.Value  = owner       -- 2º
	credito.Parent = alvoHum     -- 3º, sempre por último
	Debris:AddItem(credito, 5)
end

--── Dano: modo preciso, uma linha, sem require (§12.6) ──
local function aplicarDano(alvoHum, bruto)
	local final = bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--── Recarga global anti-clone (§12.9) ──
local function recarga(chave, segundos)
	return true, 0
end

--── Detecção em área (§12.8) ──
local function detectar(posicao, raio, limite)
	local lista = {}
	for _, modelo in ipairs(workspace:GetChildren()) do
		if modelo:IsA("Model") and modelo ~= character then
			local hum  = modelo:FindFirstChildOfClass("Humanoid")
			local raiz = modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
			if hum and raiz and podeAtingir(hum, modelo) then
				if (raiz.Position - posicao).Magnitude <= raio then
					table.insert(lista, hum)
					if limite and #lista >= limite then break end
				end
			end
		end
	end
	return lista
end

local function raizDe(hum)
	local m = hum.Parent
	if not m then return nil end
	return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
end

--── Empurrão padronizado (BodyVelocity temporário, sem :Destroy) ──
local function empurrar(parte, direcao, forca, duracao)
	if not (parte and parte.Parent) then return end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Velocity = direcao.Unit * forca
	bv.Parent   = parte
	Debris:AddItem(bv, duracao or 0.2)
end

--── Sons: sequenciais, nunca math.random ──
local somIndice = 1
local function tocarBloco(lista, parent, pitch)
	if #lista == 0 then return end
	local base = lista[somIndice]
	somIndice = (somIndice % #lista) + 1
	if not base then return end
	local s = base:Clone()
	s.Parent        = parent or Handle
	s.PlaybackSpeed = pitch or 1
	s:Play()
	table.insert(Ativos.Sons, s)
	Debris:AddItem(s, 3)
end

--[[
	tocarSfx(nome, parent, pitch)
	Sons importados dos modelos de referência (§12.12), instalados dentro do
	Handle de cada Tool:
	  sfx_carga     10555593530  [JC] ChangeE — carga/anúncio
	  sfx_corte     1086616651   [DE] corte
	  sfx_impacto   220834019    [JC] Hit4 — impacto seco
	  sfx_execucao  5989940114   [JC] Judgement Cut End Start — cutscene
	  sfx_dominio   270070244    [DE] gongo de abertura
	  sfx_expansao  357558938    [DE] estouro da cúpula
	Ausente o som, a função não faz nada — a Tool nunca quebra por SFX.
]]
local function tocarSfx(nome, parent, pitch)
	local base = Handle:FindFirstChild(nome)
	if not base then return nil end
	local s = base:Clone()
	s.Parent        = parent or Handle
	s.PlaybackSpeed = pitch or 1
	s:Play()
	table.insert(Ativos.Sons, s)
	Debris:AddItem(s, 12)
	return s
end

--═══════════════════════════════════════════════════════════════
-- RIG DE ANIMAÇÃO R6 (§10 / §12.10)
--═══════════════════════════════════════════════════════════════

local function montarRig()
	if rig then return rig end
	rig = Animator.new(character, RIG_SUFIXO, Poses, Poses.SEQUENCIAS)
	if rig then
		rig:PlayPose("IDLE", 0.25)
		rig:StartIdleBob("IDLE", "RightArm", 0.03, 1.8, function()
			return equipped
		end)
	end
	return rig
end

local function soltarRig()
	if rig then
		rig:Destroy()
		rig = nil
	end
end

--═══════════════════════════════════════════════════════════════
-- LIMPEZA
--═══════════════════════════════════════════════════════════════

local function limparTudo()
	soltarRig()

	for _, fn in ipairs(Ativos.Cancelar) do
		pcall(fn)
	end
	table.clear(Ativos.Cancelar)

	for _, p in ipairs(Ativos.Partes) do
		if p and p.Parent then p.Parent = nil end
	end
	table.clear(Ativos.Partes)

	for _, s in ipairs(Ativos.Sons) do
		if s and s.Parent then s:Stop(); s.Parent = nil end
	end
	table.clear(Ativos.Sons)

	for _, c in ipairs(Ativos.Conexoes) do
		if c then c:Disconnect() end
	end
	table.clear(Ativos.Conexoes)

	if Handle and Handle.Parent then
		Handle.Transparency = 0
	end
end


--═══════════════════════════════════════════════════════════════
-- SONS
--═══════════════════════════════════════════════════════════════

local somEquipar = Handle:FindFirstChild("equip")
local somImpacto = {}
for _, nome in ipairs({ "block", "block2", "block3", "block4" }) do
	local s = Handle:FindFirstChild(nome)
	if s then table.insert(somImpacto, s) end
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local vidaAnterior   = nil
local corrigindoVida = false     -- trava anti-recursão do fallback
local npcRecarga     = false
local ID_AURA        = "AURA_" .. RIG_SUFIXO

--═══════════════════════════════════════════════════════════════
-- ATACANTE MAIS PRÓXIMO
--═══════════════════════════════════════════════════════════════

local function atacanteMaisProximo(deOnde)
	local origem = deOnde or (rootpart and rootpart.Position)
	if not origem then return nil end
	local lista = detectar(origem, CFG.ALCANCE_ATACANTE, 8)
	local melhor, menor = nil, math.huge
	for _, hum in ipairs(lista) do
		local raiz = raizDe(hum)
		if raiz then
			local d = (raiz.Position - origem).Magnitude
			if d < menor then melhor, menor = hum, d end
		end
	end
	return melhor
end

--═══════════════════════════════════════════════════════════════
-- PASSIVO — REDUÇÃO + REFLEXÃO
--═══════════════════════════════════════════════════════════════

local function ligarPassivo()
	if not (humanoid and rootpart) then return end

	-- Caminho correto (§12.10): a redução é regra do Núcleo.

	vidaAnterior = humanoid.Health

	guardarConexao(humanoid.HealthChanged:Connect(function(nova)
		if corrigindoVida then return end
		local anterior = vidaAnterior or nova
		local sofrido  = anterior - nova
		vidaAnterior   = nova

		if sofrido <= 0 or humanoid.Health <= 0 then return end

		-- FALLBACK §12.8 — só quando NÃO existe Núcleo. Corrige apenas a
		-- vida do PORTADOR; nenhuma regra de alvo é reimplementada aqui.
		corrigindoVida = true
		local devolver = sofrido * CFG.REDUCAO_PORTADOR
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + devolver)
		vidaAnterior = humanoid.Health
		task.wait()
		corrigindoVida = false

		-- Reflexão: devolve parte do golpe ao inimigo mais próximo
		tocarSfx("sfx_impacto", rootpart, 1.0)
		tocarBloco(somImpacto, rootpart, 1.0)
		vfx("BLOQUEIO", { posicao = rootpart.Position, cor = CFG.COR_BLOQUEIO, escala = 1 })
		vfx("TREMOR", { preset = "BUMP_PEQUENO" })

		local atacante = atacanteMaisProximo()
		if atacante then
			local raiz = raizDe(atacante)
			if raiz then
				vfx("FEIXE", {
					origem = rootpart.Position, destino = raiz.Position,
					cor = CFG.COR_REFLEXO, escala = 1.2, duracao = 0.3,
				})
				vfx("IMPACTO", { posicao = raiz.Position, cor = CFG.COR_REFLEXO, escala = 0.9 })
				-- [DE] a reflexão devolve o golpe como corte em X
				tocarSfx("sfx_corte", Handle, 1.15)
				vfx("CORTE_X", { posicao = raiz.Position, cor = CFG.COR_REFLEXO, escala = 0.9 })
				aplicarDano(atacante, sofrido * CFG.REFLEXAO_ATAQUE)
			end
		end
	end))
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE EXTRA — PROTEÇÃO DE ALIADO
--═══════════════════════════════════════════════════════════════

local function protegerAliado()
	if not (rootpart and humanoid and humanoid.Health > 0) then return end

	local liberado = recarga("EscudoBloqueador_Protecao", CFG.RECARGA_PROTECAO)
	if not liberado then return end

	local alvo = atacanteMaisProximo()
	local raizAlvo = alvo and raizDe(alvo) or nil
	local posicaoOriginal = rootpart.CFrame

	tocarSfx("sfx_dominio", Handle, 0.85)
	vfx("AURA", {
		id = ID_AURA, alvoNome = character.Name,
		cor = CFG.COR_PROTECAO, escala = 0.9, intensidade = 30,
	})

	if rig then
		rig:PlaySequence("PROTEGER", function(kf)
			if kf.marca == "SAIDA" then
				tocarSfx("sfx_carga", Handle, 1.2)
				tocarBloco(somImpacto, Handle, 0.85)
				vfx("LINHAS_VELOCIDADE", {
					posicao = rootpart.Position, cor = CFG.COR_PROTECAO,
					escala = 1.1, quantidade = 12,
				})
				vfx("RAJADA", {
					posicao = rootpart.Position + Vector3.new(0, 1.5, 0),
					cor     = CFG.COR_PROTECAO,
					escala  = 0.9,
					direcao = rootpart.CFrame.LookVector,
				})
				vfx("ZOOM", { fov = 52, subida = 0.15, espera = 0.35 })

			elseif kf.marca == "CHEGADA" then
				if raizAlvo and raizAlvo.Parent and rootpart and rootpart.Parent then
					local destino = raizAlvo.Position
						+ (rootpart.Position - raizAlvo.Position).Unit * 4
					rootpart.CFrame = CFrame.new(
						Vector3.new(destino.X, raizAlvo.Position.Y, destino.Z),
						raizAlvo.Position
					)
					tocarSfx("sfx_expansao", Handle, 1.0)
					vfx("ONDA_CHOQUE", {
						posicao = rootpart.Position - Vector3.new(0, 2.6, 0),
						cor = CFG.COR_PROTECAO, escala = 1,
					})
				end

			elseif kf.marca == "REPULSAO" then
				if raizAlvo and raizAlvo.Parent then
					-- SFX -> física -> VFX -> dano (§8 V2)
					tocarSfx("sfx_impacto", raizAlvo, 0.8)
					tocarBloco(somImpacto, raizAlvo, 1.6)
					empurrar(
						raizAlvo,
						(raizAlvo.Position - rootpart.Position) + Vector3.new(0, 0.5, 0),
						CFG.FORCA_REPULSAO, 0.35
					)
					tocarSfx("sfx_execucao", Handle, 0.9)
					vfx("IMPACTO_NOVA", {
						posicao = raizAlvo.Position, cor = CFG.COR_PROTECAO, escala = 1.3,
					})
					vfx("DESTROCOS", {
						posicao    = raizAlvo.Position - Vector3.new(0, 2.6, 0),
						cor        = CFG.COR_PROTECAO,
						escala     = 0.8,
						quantidade = 12,
						raio       = 14,
					})
					vfx("TREMOR", { preset = "EXPLOSAO_PEQUENA" })
					if alvo and alvo.Health > 0 then
						aplicarDano(alvo, (alvo.MaxHealth * 0.02) + 8)
					end
				end
			end
		end, function()
			vfx("PARAR", { id = ID_AURA })
			if not raizAlvo and rootpart and rootpart.Parent then
				rootpart.CFrame = posicaoOriginal
			end
		end)
	else
		vfx("PARAR", { id = ID_AURA })
	end
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao)
	if jogador ~= owner or not equipped then return end
	if not taxaOk() then return end
	if acao == "toggleProtection" or acao == "activate" then
		protegerAliado()
	end
end)

--═══════════════════════════════════════════════════════════════
-- NPC
--═══════════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(1.5)
		if equipped and not owner and not npcRecarga and rootpart and rootpart.Parent then
			local perto = detectar(rootpart.Position, CFG.NPC_ALCANCE, 1)
			if #perto > 0 then
				npcRecarga = true
				protegerAliado()
				task.delay(CFG.NPC_RECARGA, function() npcRecarga = false end)
			end
		end
	end
end)

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

Tool.Equipped:Connect(function()
	character = Tool.Parent
	if not character then return end
	owner    = Players:GetPlayerFromCharacter(character)
	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootpart = character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootpart) then return end

	equipped = true
	if somEquipar then somEquipar:Play() end
	montarRig()
	ligarPassivo()

	guardarConexao(humanoid.Died:Connect(function()
		vfx("PARAR", { id = ID_AURA })
		limparTudo()
	end))
end)

-- Tool.Enabled NÃO é resetado aqui (§8 / §10.7)
Tool.Unequipped:Connect(function()
	equipped     = false
	vidaAnterior = nil
	vfx("PARAR", { id = ID_AURA })
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped     = false
	vidaAnterior = nil
	vfx("PARAR", { id = ID_AURA })
	limparTudo()
end)

--═══════════════════════════════════════════════════════════════
-- REGRA Nº 2 — o VFX sai da Tool quando ela chega ao jogador
--
-- Uma linha. O `DepositoVFX` liga o ciclo inteiro sozinho: instala na troca de
-- pai (mochila OU mão), desinstala no `Tool.Destroying`, e conta as referências
-- para não arrancar o molde debaixo de quem ainda está com a Tool.
--
-- Ver DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
