-- EscudoPartido_Server_V1.lua
-- Script DENTRO da Tool "Escudo Partido"
--
-- ORIGEM: clone estrutural do Escudo Bumerangue (Handle, Mesh, sons, grip).
-- HABILIDADES
--   Primária (clique)  : combo de 3 CORTES. Cada corte lança um arco cortante
--                        à frente que atravessa e some — não volta, ao
--                        contrário do Bumerangue.
--   Extra    (Q / ButtonX): ESCUDO PARTIDO. Lança 2 escudos. Se acertarem um
--                        jogador ou NPC inimigo, abre uma CUTSCENE: portador e
--                        vítima travados, câmera em trilho (pack Saitama), os
--                        2 escudos retalham a vítima várias vezes e o golpe
--                        final aplica DANO_MORTAL de uma vez.
--                        Se nenhum escudo acertar, não há cutscene e a recarga
--                        é reduzida (whiff barato).
--
-- CONFORMIDADE
--   §12.4  Values DamageClass / EnergyCost / RecargaGlobal / ChaveRecarga
--   dano sempre por TakeDamage, que respeita ForceField
--   §12.7  tag creator com Name -> Value -> Parent nessa ordem
--   §12.9  recarga global por chave (imune a clone na mochila)
--   §12.11 servidor só transmite VFX; zero :Emit() aqui
--   §10    animação por R6CFrameAnimator + Poses (pack Saitama)
--   Câmera: keyframes de SERIOUS_PUNCH_CAMERA, executados no CLIENTE.
--   §12.12 Material importado de "Judgement Cut End" (grade de cortes,
--          tempo parado, destroços, rajada, presets de tremor, SFX) e de
--          "Domain Expansion(Elemental)" (corte em X). Passe de
--          conformidade registrado no cabeçalho do VFXModule.
--   Zero: wait/spawn/delay, math.random, tick, :Destroy em part, +=,
--         continue, AncestryChanged, Instance.new("Explosion"), ScreenGui

local ARQUETIPO  = "MELEE"
local RIG_SUFIXO = "EscudoPartido"

local CFG = {
	-- ===== COMBO DE CORTES (primária) =====
	DANO_CORTE      = 21,
	ALCANCE_CORTE   = 30,
	VEL_CORTE       = 105,
	RAIO_CORTE      = 5.5,
	RECUO_CORTE     = 22,
	RECARGA_COMBO   = 2.2,

	-- ===== ESCUDO PARTIDO (extra) =====
	QTD_LANCAS      = 2,
	ALCANCE_LANCA   = 46,
	VEL_LANCA       = 120,
	RAIO_LANCA      = 6,
	ABERTURA_LANCA  = 9,        -- graus entre as duas lanças
	RECARGA_EXEC    = 26,
	RECARGA_ERRO    = 6,        -- recarga quando nenhuma lança acerta

	-- ===== CUTSCENE =====
	DANO_MORTAL     = 299,
	RAIO_TEMPO      = 45,       -- alcance do realce de "tempo parado" [JC]
	QTD_GRADE       = 22,       -- planos suspensos da grade de cortes [JC]
	RAIO_GRADE      = 30,
	ESPERA_GRADE    = 1.1,      -- s até a grade colapsar
	QTD_DESTROCOS   = 15,       -- fragmentos do anel de destroços [JC]
	RAIO_DESTROCOS  = 22,
	RAIO_RETALHO    = 3.2,
	DIST_EXECUCAO   = 5.5,      -- onde o portador para em relação à vítima
	ESCALA_LAMINA   = 0.55,

	-- ===== VISUAL =====
	COR             = Color3.fromRGB(255, 70, 90),
	COR_MORTAL      = Color3.fromRGB(255, 235, 235),

	-- ===== NPC =====
	NPC_ALCANCE     = 38,
	NPC_RECARGA     = 8,
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

--═══════════════════════════════════════════════════════════════
-- EMPURRÃO — `LinearVelocity`, e com DUAS guardas que faltavam
--
-- ⚠️ 1. `direcao.Unit` COM DIREÇÃO ZERO DEVOLVE NaN, e não é caso teórico:
--       o `Escudo Bumerangue` chama `empurrar(raiz, raiz.Position - onde, ...)`
--       e, quando o escudo pousa exatamente em cima do dono, esses dois pontos
--       são o MESMO. `Velocity = NaN` envenena a assembly — a peça vai para
--       coordenada absurda, ou trava. Sem erro, sem aviso: NaN não lança.
--
--       Este NaN não precisa de cliente modificado. Vem da geometria do jogo.
--
--    2. `MaxForce` era FIXO em 1e5. Com teto fixo, alvo pesado quase não sai
--       do lugar e alvo leve voa — o mesmo empurrão, resultados opostos. O
--       teto passa a ser proporcional à massa, que é como o `BLOCO_FISICA` do
--       repositório já faz.
--
-- POR QUE `LinearVelocity` E NÃO `ApplyImpulse`
--
--    A revisão sugeriu `ApplyImpulse`, e para knockback puro ele é mais
--    correto. Mas `BodyVelocity` SUSTENTA a velocidade pelos 0.2 s — segura o
--    alvo no ar contra a gravidade —, e `ApplyImpulse` dá um tranco só e
--    solta. A diferença é sentida, e trocar a SENSAÇÃO de sete Tools que
--    funcionam não é conserto, é redesign.
--
--    `LinearVelocity` com prazo faz o que o `BodyVelocity` fazia, sem a classe
--    obsoleta e sem o teto fixo. Fica igual de jogar, e certo por dentro.
--
--    Revisão do Codex no PR #1, item P1.3.
--═══════════════════════════════════════════════════════════════
local function empurrar(parte, direcao, forca, duracao)
	if not (parte and parte.Parent) then return end
	if parte.Anchored then return end

	local mag = direcao.Magnitude
	-- `mag ~= mag` é NaN; o teto corta Inf. Direção nula não empurra nada.
	if mag ~= mag or mag < 1e-4 or mag == math.huge then return end
	if forca ~= forca or math.abs(forca) == math.huge then return end

	local massa = parte.AssemblyMass
	if massa ~= massa or massa <= 0 then massa = 1 end

	local ponto = parte:FindFirstChild("EscudoEmpurrao")
	if not (ponto and ponto:IsA("Attachment")) then
		ponto = Instance.new("Attachment")
		ponto.Name = "EscudoEmpurrao"
		ponto.Parent = parte
	end

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = ponto
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = massa * 260
	lv.VectorVelocity = direcao.Unit * forca
	lv.Parent = parte
	Debris:AddItem(lv, duracao or 0.2)
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

local comboLocal     = false
local execLocal      = false
local emCutscene     = false
local npcRecarga     = false
-- Havia aqui um `relogio` alimentado por um `Heartbeat:Connect`. Ele era
-- ESCRITO e nunca LIDO: uma conexão por quadro, no servidor, para somar num
-- número que ninguém consultava. Saiu inteiro.

--═══════════════════════════════════════════════════════════════
-- LÂMINA VOADORA — o desenho é do cliente
--
-- Havia aqui um `criarLamina` que clonava o Handle numa `Part` ancorada. Ele
-- ficou órfão quando o voo virou beat: quem desenha a lâmina é o `PROJETIL`
-- do VFXModule, a 60 Hz e localmente. O servidor calcula a mesma trajetória
-- por aritmética, só para saber em quem cortar.
--═══════════════════════════════════════════════════════════════

--[[
	lancarLamina(direcao, opcoes)
	Voa em linha reta, corta quem passa por perto e SOME no fim do alcance.
	opcoes.aoAcertar(hum, raiz) -> se devolver true, a lâmina para ali.
]]
--- Cada lâmina no ar precisa de um `id` só dela: duas voando juntas com o
--- mesmo id fariam o `PARAR` da primeira apagar o desenho da segunda.
local contadorLamina = 0
local function proximaLamina()
	contadorLamina = contadorLamina + 1
	if contadorLamina > 100000 then contadorLamina = 1 end
	return contadorLamina
end

local function lancarLamina(direcao, opcoes)
	opcoes = opcoes or {}
	local origem = Handle.Position + Vector3.new(0, 1, 0)
	local alcance = opcoes.alcance or CFG.ALCANCE_CORTE
	local velocidade = opcoes.velocidade or CFG.VEL_CORTE

	-- A lâmina NÃO existe mais como `Part` do servidor. Vai um beat com origem,
	-- direção, velocidade e alcance; quem voa a 60 Hz é o `PROJETIL`, no
	-- cliente. Aqui a trajetória é a MESMA fórmula, por aritmética, e serve só
	-- para saber em quem cortar.
	local idVoo = "LAMINA_" .. RIG_SUFIXO .. "_" .. tostring(proximaLamina())
	vfx("PROJETIL", {
		id         = idVoo,
		posicao    = origem,
		direcao    = direcao.Unit,
		velocidade = velocidade,
		alcance    = alcance,
		cor        = opcoes.cor or CFG.COR,
		escala     = opcoes.escala or CFG.ESCALA_LAMINA,
		giro       = 18,
	})

	local atingidos = {}
	local percorrido = 0

	task.spawn(function()
		while percorrido < alcance do
			-- ⚠️ `task.wait(x)` NÃO dorme `x`: dorme PELO MENOS `x`, e sob
			--    carga dorme bem mais. O passo era calculado com o valor
			--    PEDIDO (`CFG.PASSO_VOO`) e não com o que passou de verdade,
			--    então o projétil do SERVIDOR andava mais devagar em tempo
			--    real que o do CLIENTE, que usa o `dt` do `Heartbeat`.
			--
			--    O sintoma: o jogador vê o escudo acertar e o dano não sai —
			--    ele sai depois, quando a hitbox finalmente chega ali.
			--
			--    `task.wait` DEVOLVE o tempo real decorrido. Usar o retorno é
			--    o conserto inteiro. (A sincronia por tempo absoluto que a
			--    revisão pede — `GetServerTimeNow` + posição analítica —
			--    continua em aberto: ela mexe também no Client.)
			local passou = task.wait(CFG.PASSO_VOO)
			percorrido = percorrido + velocidade * passou
			local nova = origem + direcao.Unit * math.min(percorrido, alcance)

			local alvos = detectar(nova, opcoes.raio or CFG.RAIO_CORTE, 6)
			for _, hum in ipairs(alvos) do
				if not atingidos[hum] then
					atingidos[hum] = true
					local raiz = raizDe(hum)
					if raiz then
						-- SFX -> física -> VFX -> dano (§8 V2)
						tocarSfx("sfx_impacto", raiz, 1.1)
						tocarBloco(somImpacto, raiz, 1.7)
						empurrar(raiz, direcao, opcoes.recuo or CFG.RECUO_CORTE, 0.2)
						vfx("TREMOR", { preset = "BUMP_PEQUENO" })
						vfx("IMPACTO", { posicao = raiz.Position, cor = opcoes.cor or CFG.COR, escala = 1.2 })

						if opcoes.aoAcertar then
							if opcoes.aoAcertar(hum, raiz) then
								vfx("PARAR", { id = idVoo })
								return
							end
						else
							aplicarDano(hum, opcoes.dano or CFG.DANO_CORTE)
						end
					end
				end
			end
		end

		-- dissipa no fim do alcance: o desenho morre sozinho, e o `PARAR` cobre
		-- o caso de a Tool sumir no meio do voo
		vfx("PARAR", { id = idVoo })
		vfx("LINHAS_VELOCIDADE", {
			posicao    = origem + direcao.Unit * alcance,
			cor        = opcoes.cor or CFG.COR,
			escala     = 0.7,
			quantidade = 6,
		})
	end)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE PRIMÁRIA — COMBO DE 3 CORTES
--═══════════════════════════════════════════════════════════════

local function comboCortes()
	if comboLocal or emCutscene or not (rootpart and rootpart.Parent) then return end

	local liberado = recarga("EscudoPartido_Combo", CFG.RECARGA_COMBO)
	if not liberado then return end

	comboLocal = true
	local passoCorte = 0

	local function disparar()
		passoCorte = passoCorte + 1
		local frente = rootpart.CFrame.LookVector
		-- leque determinístico: -12°, 0°, +12° (sem math.random)
		local desvio = math.rad((passoCorte - 2) * 12)
		local dir = (CFrame.new(Vector3.new(), frente) * CFrame.Angles(0, desvio, 0)).LookVector

		tocarSfx("sfx_corte", Handle, 1.25 + passoCorte * 0.12)
		tocarBloco(somImpacto, Handle, 1.5 + passoCorte * 0.1)
		vfx("CORTE", {
			posicao = rootpart.Position + frente * 3 + Vector3.new(0, 1, 0),
			cor     = CFG.COR,
			escala  = 1.2,
			direcao = dir,
			giro    = desvio * 3,
		})
		lancarLamina(dir, { escala = 0.6 })
	end

	if rig then
		rig:PlaySequence("CORTE_COMBO", function(kf)
			if kf.marca == "CORTE1" or kf.marca == "CORTE2" or kf.marca == "CORTE3" then
				disparar()
			end
		end, function()
			comboLocal = false
		end)
	else
		disparar()
		comboLocal = false
	end
end

--═══════════════════════════════════════════════════════════════
-- CUTSCENE — ESCUDO PARTIDO
--═══════════════════════════════════════════════════════════════

--[[
	travarVitima(hum, travar)
	Guarda os valores ORIGINAIS antes de zerar. Restaurar com 16/50 fixos
	apagaria stats de personagem customizado — era um bug silencioso.
	JumpPower só tem efeito com UseJumpPower = true; por isso JumpHeight
	também entra, cobrindo os dois modos do Humanoid.
]]
local statsVitima = {}

local function travarVitima(vitimaHum, travar)
	if not vitimaHum then return end

	if travar then
		statsVitima = {
			WalkSpeed     = vitimaHum.WalkSpeed,
			JumpPower     = vitimaHum.JumpPower,
			JumpHeight    = vitimaHum.JumpHeight,
			AutoRotate    = vitimaHum.AutoRotate,
			PlatformStand = vitimaHum.PlatformStand,
		}
		vitimaHum.WalkSpeed     = 0
		vitimaHum.JumpPower     = 0
		vitimaHum.JumpHeight    = 0
		vitimaHum.AutoRotate    = false
		vitimaHum.PlatformStand = true
	else
		vitimaHum.WalkSpeed     = statsVitima.WalkSpeed or 16
		vitimaHum.JumpPower     = statsVitima.JumpPower or 50
		vitimaHum.JumpHeight    = statsVitima.JumpHeight or 7.2
		vitimaHum.AutoRotate    = statsVitima.AutoRotate ~= false
		vitimaHum.PlatformStand = false
		statsVitima = {}
	end
end

-- Duas lâminas gêmeas que cruzam a vítima em X, uma vez por corte
local retalhoIndice = 0
local function retalharVitima(centro)
	retalhoIndice = retalhoIndice + 1
	local ang = retalhoIndice * math.rad(137.507764)   -- ângulo áureo

	-- As duas lâminas cruzando eram `Part` do servidor animadas por
	-- `Heartbeat`, e o servidor não lia a posição delas para NADA: puro
	-- desenho, no lugar errado. Viraram um beat só.
	vfx("LAMINAS_X", { posicao = centro, angulo = ang, cor = CFG.COR,
		escala = CFG.ESCALA_LAMINA })

	-- [DE] os dois cortes cruzados em X, do Domain Expansion
	vfx("CORTE_X", { posicao = centro, cor = CFG.COR, escala = 1.15, giro = ang })
	vfx("RETALHO", {
		posicao    = centro,
		cor        = CFG.COR,
		escala     = 1.1,
		quantidade = 6,
	})
	vfx("TREMOR", { preset = "BUMP_PEQUENO" })
end

local function executarCutscene(vitimaHum, vitimaRaiz)
	if emCutscene then return end
	local vitimaChar = vitimaHum.Parent
	if not (vitimaChar and vitimaRaiz and vitimaRaiz.Parent) then return end

	emCutscene   = true
	retalhoIndice = 0

	local vitimaAncorada = vitimaRaiz.Anchored
	travarVitima(vitimaHum, true)
	vitimaRaiz.Anchored = true

	if rig then rig:LockCharacter(true) end

	-- Reposiciona o portador de frente para a vítima
	local frenteVitima = vitimaRaiz.CFrame.LookVector
	local destino = vitimaRaiz.Position + frenteVitima * CFG.DIST_EXECUCAO
	if rootpart and rootpart.Parent then
		rootpart.CFrame = CFrame.new(
			Vector3.new(destino.X, rootpart.Position.Y, destino.Z),
			Vector3.new(vitimaRaiz.Position.X, rootpart.Position.Y, vitimaRaiz.Position.Z)
		)
	end

	-- A câmera roda no CLIENTE (payload de dados puros: nomes, não Instances)
	vfx("CUTSCENE_INICIO", {
		portador = character.Name,
		vitima   = vitimaChar.Name,
		duracao  = 2.9,
		cor      = CFG.COR,
	})

	local function encerrar()
		emCutscene = false
		vfx("PARAR", { id = "TEMPO_" .. RIG_SUFIXO })
		vfx("CUTSCENE_FIM", { portador = character.Name })
		if rig then rig:LockCharacter(false) end
		if vitimaRaiz and vitimaRaiz.Parent then
			vitimaRaiz.Anchored = vitimaAncorada
		end
		if vitimaHum and vitimaHum.Parent then
			travarVitima(vitimaHum, false)
		end
	end

	local ok = rig and rig:PlaySequence("EXECUCAO", function(kf)
		local centro = (vitimaRaiz and vitimaRaiz.Parent) and vitimaRaiz.Position or destino

		if kf.marca == "POSTURA" then
			-- [JC] beat 1: anúncio. Gongo + zoom + rajada cônica de fagulhas.
			tocarSfx("sfx_carga", Handle, 1)
			vfx("ZOOM", { fov = 44, subida = 0.18, espera = 0.9 })
			vfx("RAJADA", {
				posicao = centro,
				cor     = CFG.COR,
				escala  = 1.4,
				direcao = Vector3.new(0, 1, 0),
			})
			vfx("RACHADURA_SOLO", {
				posicao    = centro - Vector3.new(0, 2.8, 0),
				cor        = CFG.COR,
				escala     = 1.2,
				quantidade = 8,
			})

		elseif kf.marca == "TEMPO" then
			-- [JC] beat 2: o mundo trava. No original era ColorCorrection na
			-- tela inteira (proibido §12.12.1); aqui o efeito é no mundo 3D —
			-- realce nos corpos, queda de FOV e poeira suspensa.
			tocarSfx("sfx_execucao", Handle, 1)
			vfx("TEMPO_PARADO", {
				id      = "TEMPO_" .. RIG_SUFIXO,
				posicao = centro,
				cor     = CFG.COR,
				raio    = CFG.RAIO_TEMPO,
				duracao = 1.8,
			})
			vfx("TREMOR", { preset = "BUMP_REMADE" })

		elseif kf.marca == "GRADE" then
			-- [JC] beat 3: a grade de planos de vidro fica suspensa no ar.
			tocarSfx("sfx_dominio", Handle, 0.85)
			vfx("GRADE_CORTES", {
				posicao    = centro,
				cor        = CFG.COR,
				escala     = 1,
				quantidade = CFG.QTD_GRADE,
				raio       = CFG.RAIO_GRADE,
				espera     = CFG.ESPERA_GRADE,
			})
			tocarSfx("sfx_corte", vitimaRaiz, 0.85)
			retalharVitima(centro)

		elseif kf.marca == "CORTE" then
			tocarSfx("sfx_corte", vitimaRaiz, 1.15)
			retalharVitima(centro)

		elseif kf.marca == "MORTAL" then
			-- [JC] beat final: a grade colapsa, o tempo volta, tudo desaba.
			-- SFX -> física -> VFX -> dano (§8 V2)
			tocarSfx("sfx_impacto", vitimaRaiz, 0.6)
			tocarSfx("sfx_expansao", Handle, 1)
			if vitimaRaiz and vitimaRaiz.Parent then
				vitimaRaiz.Anchored = vitimaAncorada
				empurrar(vitimaRaiz, frenteVitima * -1 + Vector3.new(0, 0.6, 0), 95, 0.4)
			end
			vfx("PARAR", { id = "TEMPO_" .. RIG_SUFIXO })
			vfx("IMPACTO_NOVA", { posicao = centro, cor = CFG.COR_MORTAL, escala = 2.2 })
			vfx("RETALHO", { posicao = centro, cor = CFG.COR_MORTAL, escala = 1.8, quantidade = 12 })
			vfx("DESTROCOS", {
				posicao    = centro - Vector3.new(0, 2.6, 0),
				cor        = CFG.COR,
				escala     = 1,
				quantidade = CFG.QTD_DESTROCOS,
				raio       = CFG.RAIO_DESTROCOS,
			})
			vfx("TREMOR", { preset = "EXPLOSAO_GRANDE" })

			if vitimaHum and vitimaHum.Parent and vitimaHum.Health > 0 then
				aplicarDano(vitimaHum, CFG.DANO_MORTAL)
			end

		elseif kf.marca == "FIM" then
			encerrar()
		end
	end, function()
		if emCutscene then encerrar() end
	end)

	if not ok then
		-- Sem rig (R6 incompleto): aplica o golpe sem cutscene
		vfx("IMPACTO_NOVA", { posicao = vitimaRaiz.Position, cor = CFG.COR_MORTAL, escala = 2 })
		aplicarDano(vitimaHum, CFG.DANO_MORTAL)
		encerrar()
	end
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE EXTRA — LANÇAR AS 2 LÂMINAS
--═══════════════════════════════════════════════════════════════

local function escudoPartido()
	if execLocal or emCutscene or not (rootpart and rootpart.Parent) then return end

	local liberado = recarga("EscudoPartido_Execucao", CFG.RECARGA_EXEC)
	if not liberado then return end

	execLocal = true
	local acertou = false

	if rig then rig:PlaySequence("ARREMESSO_CARREGADO", function(kf)
		if kf.marca ~= "SOLTA" then return end

		tocarSfx("sfx_carga", Handle, 1.15)
		tocarBloco(somImpacto, Handle, 0.7)
		local frente = rootpart.CFrame.LookVector
		vfx("RAJADA", {
			posicao = rootpart.Position + frente * 2 + Vector3.new(0, 1.5, 0),
			cor     = CFG.COR,
			escala  = 1,
			direcao = frente,
		})

		for i = 1, CFG.QTD_LANCAS do
			local desvio = math.rad((i - (CFG.QTD_LANCAS + 1) / 2) * CFG.ABERTURA_LANCA * 2)
			local dir = (CFrame.new(Vector3.new(), frente) * CFrame.Angles(0, desvio, 0)).LookVector
			lancarLamina(dir, {
				alcance    = CFG.ALCANCE_LANCA,
				velocidade = CFG.VEL_LANCA,
				raio       = CFG.RAIO_LANCA,
				escala     = 0.9,
				aoAcertar  = function(hum, raiz)
					if acertou or emCutscene then return true end
					acertou = true
					executarCutscene(hum, raiz)
					return true
				end,
			})
		end

		vfx("LINHAS_VELOCIDADE", {
			posicao    = rootpart.Position + frente * 3,
			cor        = CFG.COR,
			escala     = 1.2,
			quantidade = 14,
		})
	end) end

	-- Whiff barato: se nenhuma lança acertou, devolve a recarga longa
	task.delay(CFG.ALCANCE_LANCA / CFG.VEL_LANCA + 0.6, function()
		if not acertou then
			recarga("EscudoPartido_Execucao", CFG.RECARGA_ERRO)
		end
	end)

	task.delay(1.2, function()
		execLocal = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao)
	if jogador ~= owner or not equipped then return end
	if not taxaOk() then return end
	if acao == "activate" then
		comboCortes()
	elseif acao == "partido" then
		escudoPartido()
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
				local raiz = raizDe(perto[1])
				if raiz and rootpart then
					rootpart.CFrame = CFrame.new(rootpart.Position, Vector3.new(
						raiz.Position.X, rootpart.Position.Y, raiz.Position.Z))
				end
				comboCortes()
				task.delay(CFG.NPC_RECARGA, function()
					npcRecarga = false
				end)
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
	owner     = Players:GetPlayerFromCharacter(character)
	humanoid  = character:FindFirstChildOfClass("Humanoid")
	rootpart  = character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootpart) then return end

	equipped = true
	if somEquipar then somEquipar:Play() end

	montarRig()

	guardarConexao(humanoid.Died:Connect(function()
		emCutscene = false
		vfx("CUTSCENE_FIM", { portador = character.Name })
		limparTudo()
	end))
end)

-- Tool.Enabled NÃO é resetado aqui (§8 / §10.7 — bypass de recarga)
Tool.Unequipped:Connect(function()
	equipped = false
	if emCutscene then
		emCutscene = false
		vfx("CUTSCENE_FIM", { portador = character and character.Name or "" })
	end
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped = false
	emCutscene = false
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
