-- EscudoBumerangue_Server_V6.lua
-- Script DENTRO da Tool "Escudo Bumerangue"
-- SUBSTITUI: ServerScript_EscudoBumerangue_V5.lua  (REMOVER a V5)
--
-- MECÂNICA (preservada da V5): 3 modos de arremesso — normal (clique),
-- carregado (segurar) e múltiplo (clique duplo). O escudo vai, corta e VOLTA.
--
-- O QUE MUDOU NA V6
--   [FIX] :Emit(30) no servidor -> VFXRemote (§12.11) — era o pior desvio
--   [FIX] tick() no sistema de combo -> acumulador dt (§10.11.7)
--   [FIX] AncestryChanged -> Tool.Destroying
--   [FIX] Welds manuais + lerp -> R6CFrameAnimator + Poses (§10)
--   [FIX] workspace:GetChildren() por frame -> detectar() (§12.8)
--   [ADD] Values §12.4, modo preciso §12.6, tag creator §12.7, recarga §12.9
--   [ADD] Nova de retorno, estrias de velocidade e rachadura no combo alto

local ARQUETIPO  = "HIBRIDO"
local RIG_SUFIXO = "EscudoBumerangue"

local CFG = {
	-- ===== NORMAL =====
	DANO_NORMAL      = 18,
	VEL_NORMAL       = 80,
	ALCANCE_NORMAL   = 50,
	RECARGA_NORMAL   = 1,
	RECUO_NORMAL     = 15,

	-- ===== CARREGADO =====
	DANO_CARREGADO   = 32,
	VEL_CARREGADO    = 100,
	ALCANCE_CARREGADO = 80,
	RECARGA_CARREGADO = 2,
	RECUO_CARREGADO  = 25,

	-- ===== MÚLTIPLO =====
	QTD_MULTI        = 3,
	DANO_MULTI       = 14,
	VEL_MULTI        = 90,
	ABERTURA_MULTI   = 15,
	RECARGA_MULTI    = 3,

	-- ===== COMBO =====
	JANELA_COMBO     = 3,
	BONUS_COMBO      = 0.10,
	TETO_COMBO       = 2.0,
	COMBO_ALTO       = 3,       -- a partir daqui, VFX reforçado

	-- ===== DETECÇÃO =====
	RAIO_ACERTO      = 5,
	-- Tique do voo no servidor. A 30 Hz o passo é menor que RAIO_ACERTO,
	-- então ninguém passa despercebido entre dois tiques.
	PASSO_VOO       = 1 / 30,
	REACERTO_IDA     = 0.5,

	-- ===== VISUAL =====
	COR              = Color3.fromRGB(0, 178, 255),
	COR_CARREGADO    = Color3.fromRGB(255, 128, 0),
	COR_COMBO        = Color3.fromRGB(255, 225, 60),

	-- ===== NPC =====
	NPC_ALCANCE      = 50,
	NPC_RECARGA      = 3,
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

local somEquipar = Handle:FindFirstChild("equip")
local somImpacto = {}
for _, nome in ipairs({ "block", "block2", "block3", "block4" }) do
	local s = Handle:FindFirstChild(nome)
	if s then table.insert(somImpacto, s) end
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

--- A janela de combo mede RECARGA, não animação, e recarga é `os.clock()`.
---
--- Era um acumulador `dt` alimentado por um `Heartbeat:Connect` que existia só
--- para somar. Uma conexão por quadro, no servidor, para fazer o que uma
--- chamada de função faz — e ela ainda fazia o verificador de fluidez marcar
--- este arquivo como "move geometria por frame", porque a heurística dele é
--- por ARQUIVO: qualquer `.CFrame =` num arquivo que tenha um `Heartbeat`.
local combo       = 0
local marcaCombo  = -99
local voando      = 0        -- quantos escudos estão no ar
local npcRecarga  = false
local travaNormal, travaCarregado, travaMulti = false, false, false

--═══════════════════════════════════════════════════════════════
-- COMBO
--═══════════════════════════════════════════════════════════════

local function atualizarCombo()
	if os.clock() - marcaCombo > CFG.JANELA_COMBO then
		combo = 0
	end
	combo = combo + 1
	marcaCombo = os.clock()
	return math.min(1 + combo * CFG.BONUS_COMBO, CFG.TETO_COMBO)
end

--═══════════════════════════════════════════════════════════════
-- ARREMESSO
--═══════════════════════════════════════════════════════════════

--- O projétil NÃO existe mais como `Part` do servidor.
---
--- Ele era `Handle:Clone()` ancorado, com o `CFrame` reescrito a cada
--- `Heartbeat`. Geometria movida pelo servidor replica a ~20 Hz e o cliente
--- não interpola: o voo chegava em passos, e era esse o "não fluido" que
--- sobreviveu a três levas.
---
--- Agora o servidor manda UM beat com origem, direção, velocidade e alcance —
--- tudo o que ele já sabia antes de criar peça alguma — e calcula a MESMA
--- trajetória por aritmética para saber em quem bater. Quem voa a 60 Hz é o
--- `PROJETIL` do VFXModule, no cliente.

--═══════════════════════════════════════════════════════════════
-- SOM NUM PONTO, SEM PEÇA PARA PENDURAR
--
-- Os dois de cima penduram o `Sound` numa instância. Enquanto o projétil era
-- uma `Part` do servidor, ela servia de suporte; agora não há peça nenhuma —
-- quem voa é desenho de cliente.
--
-- Um `Sound` só toca enquanto tem pai no DataModel, então a saída é uma âncora
-- invisível própria, com prazo pelo `Debris`. É o mesmo `tocarEm` que o resto
-- do repositório usa, e existe pelo mesmo motivo.
--═══════════════════════════════════════════════════════════════

local function ancoraEm(posicao, prazo)
	local a = Instance.new("Part")
	a.Size = Vector3.new(0.2, 0.2, 0.2)
	a.Transparency = 1
	a.Anchored = true
	a.CanCollide, a.CanQuery, a.CanTouch = false, false, false
	a.CFrame = CFrame.new(posicao or Vector3.new())
	a.Parent = workspace
	Debris:AddItem(a, prazo or 6)
	return a
end

local function tocarSfxEm(nome, posicao, pitch)
	return tocarSfx(nome, ancoraEm(posicao, 12), pitch)
end

local function tocarBlocoEm(lista, posicao, pitch)
	return tocarBloco(lista, ancoraEm(posicao, 6), pitch)
end

--- Contador de voo: cada arremesso precisa de um `id` só dele, senão dois
--- bumerangues no ar dividem o mesmo registro e o `PARAR` do primeiro apaga o
--- desenho do segundo.
local contadorVoo = 0
local function proximoVoo()
	contadorVoo = contadorVoo + 1
	if contadorVoo > 100000 then contadorVoo = 1 end
	return contadorVoo
end

local function arremessar(destino, modo)
	local dano, velocidade, alcance, recuo, corProjetil

	if modo == "carregado" then
		dano, velocidade, alcance, recuo = CFG.DANO_CARREGADO, CFG.VEL_CARREGADO, CFG.ALCANCE_CARREGADO, CFG.RECUO_CARREGADO
		corProjetil = CFG.COR_CARREGADO
	elseif modo == "multi" then
		dano, velocidade, alcance, recuo = CFG.DANO_MULTI, CFG.VEL_MULTI, CFG.ALCANCE_NORMAL, CFG.RECUO_NORMAL
		corProjetil = CFG.COR
	else
		dano, velocidade, alcance, recuo = CFG.DANO_NORMAL, CFG.VEL_NORMAL, CFG.ALCANCE_NORMAL, CFG.RECUO_NORMAL
		corProjetil = CFG.COR
	end

	if not (rootpart and rootpart.Parent) then return end

	-- A animação existia no Poses e ninguém a chamava: o Bumerangue arremessava
	-- parado. O rig é do SERVIDOR, então a pose replica para a sala inteira.
	if rig then
		local sequencia = (modo == "carregado") and "ARREMESSO_CARREGADO"
			or "ARREMESSO"
		rig:PlaySequence(sequencia, function(kf)
			if kf.marca == "CARGA" then
				vfx("LINHAS_VELOCIDADE", { posicao = rootpart.Position,
					cor = corProjetil, escala = 0.8, quantidade = 8 })
			end
		end)
	end

	voando = voando + 1
	Handle.Transparency = 1

	local origem = Handle.Position
	local direcao = (destino - origem)
	if direcao.Magnitude < 0.1 then
		direcao = rootpart.CFrame.LookVector
	end
	direcao = direcao.Unit

	local idVoo = "BUMER_" .. RIG_SUFIXO .. "_" .. tostring(proximoVoo())
	vfx("PROJETIL", {
		id         = idVoo,
		posicao    = origem,
		direcao    = direcao,
		velocidade = velocidade,
		alcance    = alcance,
		cor        = corProjetil,
		escala     = modo == "carregado" and 1.25 or 1,
		giro       = 16,
		pecaNome   = personagem and personagem.Name or nil,
	})

	-- O som sai de uma âncora no ponto de saída: sem `Part` de projétil, não há
	-- onde pendurá-lo, e som pendurado em peça que some morre no quadro em que
	-- nasce.
	tocarSfxEm("sfx_carga", origem, modo == "carregado" and 0.85 or 1.2)
	tocarBlocoEm(somImpacto, origem, modo == "carregado" and 0.8 or 1.5)
	-- [JC] rajada cônica no ponto de saída
	tocarSfx("sfx_expansao", Handle, 1.0)
	vfx("RAJADA", {
		posicao = origem, cor = corProjetil,
		escala = modo == "carregado" and 1.2 or 0.8, direcao = direcao,
	})

	local atingidos = {}

	--- `onde` é calculado, não lido de uma peça: a mesma fórmula que o cliente
	--- desenha, avaliada no servidor. É isto que mantém o dano no servidor sem
	--- geometria nenhuma.
	local function checar(fase, onde)
		local alvos = detectar(onde, CFG.RAIO_ACERTO, 6)
		for _, hum in ipairs(alvos) do
			if not atingidos[hum] then
				atingidos[hum] = true
				local raiz = raizDe(hum)
				if raiz then
					local mult = atualizarCombo()
					local alto = combo >= CFG.COMBO_ALTO
					local corHit = alto and CFG.COR_COMBO or corProjetil

					-- SFX -> física -> VFX -> dano (§8 V2)
					tocarSfx("sfx_impacto", raiz, alto and 0.85 or 1.2)
					tocarBloco(somImpacto, raiz, 2.0)
					empurrar(raiz, (raiz.Position - onde), recuo, 0.2)
					if alto then
						tocarSfx("sfx_execucao", Handle, 0.9)
						vfx("IMPACTO_NOVA", { posicao = raiz.Position, cor = corHit, escala = 1.1 })
						tocarSfx("sfx_corte", Handle, 1.15)
						vfx("CORTE_X", { posicao = raiz.Position, cor = corHit, escala = 1 })
						vfx("TREMOR", { preset = "BUMP" })
					else
						vfx("IMPACTO", { posicao = raiz.Position, cor = corHit, escala = 1 })
						vfx("TREMOR", { preset = "BUMP_PEQUENO" })
					end
					aplicarDano(hum, dano * mult)

					if fase == "ida" then
						task.delay(CFG.REACERTO_IDA, function()
							atingidos[hum] = nil
						end)
					end
				end
			end
		end
	end

	--═══════════════════════════════════════════════════════════════
	-- O VOO, DO LADO DO SERVIDOR: aritmética, e nada de `Part`
	--
	-- A posição é `origem + direcao * percorrido` na ida, e a interpolação até
	-- o `Handle` na volta. Exatamente a mesma fórmula que o `PROJETIL` desenha
	-- no cliente — só que aqui ela serve para uma coisa só: saber em quem
	-- bater.
	--
	-- O tique é `PASSO_VOO`, não `Heartbeat`. A 30 Hz o passo do bumerangue é
	-- menor que `RAIO_ACERTO`, então ninguém passa despercebido entre dois
	-- tiques — e o servidor deixa de acordar 60 vezes por segundo por projétil.
	--═══════════════════════════════════════════════════════════════
	task.spawn(function()
		-- FASE 1: ida
		local percorrido = 0
		local onde = origem
		while percorrido < alcance do
			task.wait(CFG.PASSO_VOO)
			if not (Handle and Handle.Parent) then break end
			percorrido = percorrido + velocidade * CFG.PASSO_VOO
			onde = origem + direcao * math.min(percorrido, alcance)
			checar("ida", onde)
		end

		tocarBlocoEm(somImpacto, onde, 1.0)

		-- FASE 2: volta — o alvo é o `Handle`, que anda com o jogador
		while Handle and Handle.Parent do
			task.wait(CFG.PASSO_VOO)
			if not (Handle and Handle.Parent) then break end
			local volta = Handle.Position - onde
			if volta.Magnitude < 3 then break end
			onde = onde + volta.Unit * (velocidade * 0.75 * CFG.PASSO_VOO)
			checar("volta", onde)
		end

		-- o desenho morre sozinho quando chega; o `PARAR` cobre o caso de a
		-- Tool sumir no meio da viagem
		vfx("PARAR", { id = idVoo })
		vfx("IMPACTO_NOVA", {
			posicao = onde,
			cor     = corProjetil,
			escala  = modo == "carregado" and 1.5 or 1,
		})
		if modo == "carregado" then
			-- [JC] anel de destroços no retorno do arremesso pesado
			tocarSfx("sfx_dominio", Handle, 0.85)
			vfx("DESTROCOS", {
				posicao    = onde - Vector3.new(0, 2.6, 0),
				cor        = corProjetil,
				escala     = 0.9,
				quantidade = 12,
				raio       = 16,
			})
			vfx("TREMOR", { preset = "EXPLOSAO_PEQUENA" })
		end

		voando = math.max(0, voando - 1)
		if voando == 0 and Handle and Handle.Parent then
			Handle.Transparency = 0
		end
	end)
end

local function arremessarMulti(destino)
	if not (rootpart and rootpart.Parent) then return end
	local centro = (destino - Handle.Position)
	if centro.Magnitude < 0.1 then centro = rootpart.CFrame.LookVector end
	centro = centro.Unit

	for i = 1, CFG.QTD_MULTI do
		local desvio = math.rad((i - (CFG.QTD_MULTI + 1) / 2) * CFG.ABERTURA_MULTI)
		local dir = (CFrame.new(Vector3.new(), centro) * CFrame.Angles(0, desvio, 0)).LookVector
		arremessar(Handle.Position + dir * CFG.ALCANCE_NORMAL, "multi")
		task.wait(0.1)
	end
end

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS DE ANIMAÇÃO
--═══════════════════════════════════════════════════════════════

local function animarArremesso(seqNome, destino, modo)
	if not rig then
		if modo == "multi" then arremessarMulti(destino) else arremessar(destino, modo) end
		return
	end
	rig:PlaySequence(seqNome, function(kf)
		if kf.marca == "CARGA" then
			vfx("LINHAS_VELOCIDADE", {
				posicao = rootpart.Position, cor = CFG.COR, escala = 0.7, quantidade = 6,
			})
		elseif kf.marca == "SOLTA" then
			if modo == "multi" then
				task.spawn(arremessarMulti, destino)
			else
				arremessar(destino, modo)
			end
		end
	end)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao, mira)
	if jogador ~= owner or not equipped then return end
	if typeof(mira) ~= "Vector3" then
		mira = rootpart and (rootpart.Position + rootpart.CFrame.LookVector * 40) or Vector3.new()
	end

	if acao == "throw" and not travaNormal then
		local liberado = recarga("EscudoBumerangue_Normal", CFG.RECARGA_NORMAL)
		if not liberado then return end
		travaNormal = true
		animarArremesso("ARREMESSO", mira, "normal")
		task.delay(CFG.RECARGA_NORMAL, function() travaNormal = false end)

	elseif acao == "throwCharged" and not travaCarregado then
		local liberado = recarga("EscudoBumerangue_Carregado", CFG.RECARGA_CARREGADO)
		if not liberado then return end
		travaCarregado = true
		animarArremesso("ARREMESSO_CARREGADO", mira, "carregado")
		task.delay(CFG.RECARGA_CARREGADO, function() travaCarregado = false end)

	elseif acao == "throwMulti" and not travaMulti then
		local liberado = recarga("EscudoBumerangue_Multi", CFG.RECARGA_MULTI)
		if not liberado then return end
		travaMulti = true
		animarArremesso("ARREMESSO_CARREGADO", mira, "multi")
		task.delay(CFG.RECARGA_MULTI, function() travaMulti = false end)
	end
end)

--═══════════════════════════════════════════════════════════════
-- NPC
--═══════════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(1)
		if equipped and not owner and not npcRecarga and rootpart and rootpart.Parent then
			local perto = detectar(rootpart.Position, CFG.NPC_ALCANCE, 1)
			if #perto > 0 then
				local raiz = raizDe(perto[1])
				if raiz then
					npcRecarga = true
					animarArremesso("ARREMESSO", raiz.Position, "normal")
					task.delay(CFG.NPC_RECARGA, function() npcRecarga = false end)
				end
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
	combo    = 0
	if somEquipar then somEquipar:Play() end
	montarRig()

	guardarConexao(humanoid.Died:Connect(function()
		limparTudo()
	end))
end)

-- Tool.Enabled NÃO é resetado aqui (§8 / §10.7)
Tool.Unequipped:Connect(function()
	equipped = false
	combo    = 0
	voando   = 0
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped = false
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
