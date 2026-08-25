-- Salvador_Server_V5.lua
-- Script DENTRO da Tool "Salvador"
-- SUBSTITUI: ServerScript_Salvador_V4.lua  (REMOVER a V4)
--
-- MECÂNICA (preservada da V4): vincula-se a um aliado por DURACAO segundos e
-- transfere para o portador todo o dano que o aliado receber. Escudo em
-- órbita sobre a cabeça do aliado + feixe de vínculo.
--
-- O QUE MUDOU NA V5
--   [FIX] :Emit() e partículas criadas no servidor -> VFXRemote (§12.11)
--   [FIX] rotação por contador de graus -> acumulador dt local (§10.11.7)
--   [FIX] AncestryChanged -> Tool.Destroying
--   [FIX] Welds manuais + lerp -> R6CFrameAnimator + Poses (§10)
--   [ADD] Values §12.4, modo preciso §12.6, tag creator §12.7, recarga §12.9
--   [ADD] VFX do vínculo, do sacrifício e do rompimento (linguagem Saitama)

local ARQUETIPO  = "SUPORTE"
local RIG_SUFIXO = "Salvador"

local CFG = {
	DURACAO         = 7,
	RECARGA         = 10,
	DIST_MAXIMA     = 50,

	ESCALA_ESCUDO   = 0.6,
	ALTURA_ESCUDO   = 3,
	VEL_ROTACAO     = 3,        -- rad/s
	-- Intervalo do tique de vínculo. Era 60 Hz porque o mesmo laço movia o
	-- escudo; agora ele só mede distância, e 0.2 s basta.
	PASSO_VINCULO   = 0.2,

	COR             = Color3.fromRGB(255, 60, 60),
	COR_ESCUDO      = Color3.fromRGB(255, 90, 90),

	NPC_ALCANCE     = 40,
	NPC_RECARGA     = 12,
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

local somEquipar    = Handle:FindFirstChild("equip")
local somSacrificio = Handle:FindFirstChild("Sacrificio")
local somImpacto    = {}
for _, nome in ipairs({ "block", "block2", "block3", "block4" }) do
	local s = Handle:FindFirstChild(nome)
	if s then table.insert(somImpacto, s) end
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local vinculoAtivo = false
local npcRecarga   = false
local ID_AURA      = "AURA_" .. RIG_SUFIXO
local ID_ESCUDO    = "ESCUDO_" .. RIG_SUFIXO

--═══════════════════════════════════════════════════════════════
-- ALIADO VÁLIDO
--═══════════════════════════════════════════════════════════════

-- Aliado = alvo que o Núcleo NÃO deixa atingir (mesma equipe/posse).
-- Isso evita reimplementar IsTeamMate dentro da Tool (§12.14).
local function ehAliado(alvoChar)
	if not alvoChar or alvoChar == character then return false end
	local hum = alvoChar:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return false end
	-- Sem Núcleo: qualquer jogador vivo pode ser protegido.
	return true
end

local function aliadoMaisProximo()
	if not (rootpart and rootpart.Parent) then return nil end
	local melhor, menor = nil, CFG.DIST_MAXIMA
	for _, modelo in ipairs(workspace:GetChildren()) do
		if modelo:IsA("Model") and modelo ~= character and ehAliado(modelo) then
			local raiz = modelo:FindFirstChild("HumanoidRootPart")
			if raiz then
				local d = (raiz.Position - rootpart.Position).Magnitude
				if d < menor then melhor, menor = modelo, d end
			end
		end
	end
	return melhor
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE — VÍNCULO DE SACRIFÍCIO
--═══════════════════════════════════════════════════════════════

local function ativarSalvador(alvoChar)
	if vinculoAtivo or not (rootpart and humanoid and humanoid.Health > 0) then return end
	if not ehAliado(alvoChar) then return end

	local alvoHum  = alvoChar:FindFirstChildOfClass("Humanoid")
	local alvoRaiz = alvoChar:FindFirstChild("HumanoidRootPart")
	local alvoCabeca = alvoChar:FindFirstChild("Head")
	if not (alvoHum and alvoRaiz and alvoCabeca) then return end
	if (alvoRaiz.Position - rootpart.Position).Magnitude > CFG.DIST_MAXIMA then return end

	local liberado = recarga("Salvador_Vinculo", CFG.RECARGA)
	if not liberado then return end

	vinculoAtivo = true

	-- Escudo flutuante sobre o aliado — DESENHADO PELO CLIENTE.
	--
	-- Ele era uma `Part` ancorada do servidor, com o `CFrame` reescrito a cada
	-- `Heartbeat`. Geometria movida pelo servidor replica a ~20 Hz e o cliente
	-- não interpola: o escudo chegava em passos, e era essa a órbita "dura" que
	-- sobreviveu a três levas.
	--
	-- Agora o servidor manda UM beat com os parâmetros e não cria peça nenhuma.
	-- Quem gira, a 60 Hz e localmente, é o `SEGUE` do VFXModule.
	vfx("SEGUE", {
		id         = ID_ESCUDO,
		alvoNome   = alvoChar.Name,
		cor        = CFG.COR_ESCUDO,
		escala     = CFG.ESCALA_ESCUDO,
		altura     = CFG.ALTURA_ESCUDO,
		giro       = CFG.VEL_ROTACAO,
		inclinacao = 12,
	})

	-- Aura contínua no aliado (roda no cliente)
	vfx("AURA", {
		id       = ID_AURA,
		alvoNome = alvoChar.Name,
		cor      = CFG.COR,
		escala   = 0.9,
		intensidade = 28,
	})

	local encerrado = false
	local transferindo = false
	local danoConn

	local function encerrar()
		if encerrado then return end
		encerrado    = true
		vinculoAtivo = false
		if danoConn then danoConn:Disconnect() end
		if somSacrificio then somSacrificio:Stop() end
		vfx("PARAR", { id = ID_AURA })
		vfx("PARAR", { id = ID_ESCUDO })
		if alvoCabeca and alvoCabeca.Parent then
			vfx("IMPACTO", {
				posicao = alvoCabeca.Position + Vector3.new(0, CFG.ALTURA_ESCUDO, 0),
				cor = CFG.COR, escala = 1,
			})
		end
		if rig then rig:PlayPose("IDLE", 0.3) end
	end

	-- Transferência de dano (com trava anti-recursão, preservada da V4)
	danoConn = guardarConexao(alvoHum.HealthChanged:Connect(function(nova)
		if transferindo or encerrado then return end
		if not (humanoid and humanoid.Health > 0) then encerrar(); return end
		local antiga = alvoHum.Health
		local sofrido = antiga - nova
		if sofrido > 0 then
			transferindo = true
			alvoHum.Health = antiga
			humanoid:TakeDamage(sofrido)
			vfx("BLOQUEIO", { posicao = alvoRaiz.Position, cor = CFG.COR, escala = 1.1 })
			tocarSfx("sfx_corte", Handle, 1.1)
			vfx("FEIXE", {
				origem  = alvoRaiz.Position,
				destino = rootpart.Position,
				cor     = CFG.COR,
				escala  = 1.4,
				duracao = 0.3,
			})
			tocarSfx("sfx_impacto", rootpart, 0.75)
			tocarBloco(somImpacto, rootpart, 0.9)
			vfx("TREMOR", { preset = "BUMP_PEQUENO" })
			task.wait()
			transferindo = false
		end
	end))

	-- O que sobrou para o servidor: saber se os dois ainda estão perto.
	--
	-- Isso NÃO pede 60 Hz. `PASSO_VINCULO` é o intervalo, e a 0.2 s a regra
	-- continua justa — ninguém atravessa `DIST_MAXIMA` studs em dois décimos
	-- sem que o jogador perceba o vínculo se rompendo.
	task.spawn(function()
		while not encerrado do
			if not (rootpart and rootpart.Parent and alvoCabeca.Parent) then
				encerrar()
				return
			end
			if (alvoRaiz.Position - rootpart.Position).Magnitude > CFG.DIST_MAXIMA then
				encerrar()
				return
			end
			task.wait(CFG.PASSO_VINCULO)
		end
	end)

	if rig then
		rig:PlaySequence("SACRIFICIO", function(kf)
			if kf.marca == "CARGA" then
				tocarSfx("sfx_carga", Handle, 0.95)
				vfx("LINHAS_VELOCIDADE", {
					posicao = rootpart.Position, cor = CFG.COR, escala = 0.8, quantidade = 8,
				})
			elseif kf.marca == "VINCULO" then
				if somSacrificio then somSacrificio:Play() end
				tocarSfx("sfx_dominio", Handle, 1.25)
				vfx("RAJADA", {
					posicao = rootpart.Position + Vector3.new(0, 1.5, 0),
					cor     = CFG.COR,
					escala  = 1.1,
					direcao = Vector3.new(0, 1, 0),
				})
				tocarSfx("sfx_execucao", Handle, 0.9)
				vfx("ZOOM", { fov = 55, subida = 0.2, espera = 0.5 })
				vfx("FEIXE", {
					origem = rootpart.Position, destino = alvoRaiz.Position,
					cor = CFG.COR, escala = 2, duracao = 0.5,
				})
				tocarSfx("sfx_expansao", Handle, 1.0)
				vfx("ONDA_CHOQUE", {
					posicao = rootpart.Position - Vector3.new(0, 2.6, 0),
					cor = CFG.COR, escala = 0.9,
				})
			end
		end)
	end

	guardarCancelamento(encerrar)
	task.delay(CFG.DURACAO, encerrar)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao, alvoModelo)
	if jogador ~= owner or not equipped then return end
	if acao ~= "protect" then return end

	local alvo = alvoModelo
	if typeof(alvo) ~= "Instance" or not alvo:IsA("Model") then
		alvo = aliadoMaisProximo()
	end
	if alvo then ativarSalvador(alvo) end
end)

--═══════════════════════════════════════════════════════════════
-- NPC
--═══════════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(1.5)
		if equipped and not owner and not npcRecarga and rootpart and rootpart.Parent then
			local aliado = aliadoMaisProximo()
			if aliado then
				npcRecarga = true
				ativarSalvador(aliado)
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

	guardarConexao(humanoid.Died:Connect(function()
		vfx("PARAR", { id = ID_AURA })
		limparTudo()
	end))
end)

-- Tool.Enabled NÃO é resetado aqui (§8 / §10.7)
Tool.Unequipped:Connect(function()
	equipped     = false
	vinculoAtivo = false
	vfx("PARAR", { id = ID_AURA })
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped     = false
	vinculoAtivo = false
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
