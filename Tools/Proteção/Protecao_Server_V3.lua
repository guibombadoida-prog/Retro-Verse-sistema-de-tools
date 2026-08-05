-- Protecao_Server_V3.lua
-- Script DENTRO da Tool "Proteção"
-- SUBSTITUI: ServerScript_Protecao_V2.lua  (REMOVER a V2)
--
-- MECÂNICA (preservada da V2): escudo orbital que intercepta projéteis
-- inimigos, devolve-os na direção do inimigo mais próximo e causa dano leve.
--
-- O QUE MUDOU NA V3
--   [FIX] tick() no loop de órbita -> acumulador dt (§10.11.7)
--   [FIX] partículas/luzes criadas no servidor -> VFXRemote (§12.11)
--   [FIX] AncestryChanged -> Tool.Destroying
--   [FIX] Welds manuais + lerp -> R6CFrameAnimator + Poses (§10)
--   [ADD] Values §12.4, modo preciso §12.6, tag creator §12.7, recarga §12.9

local ARQUETIPO  = "SUPORTE"
local RIG_SUFIXO = "Protecao"

local CFG = {
	DURACAO         = 4,
	RECARGA         = 7,

	RAIO_ORBITA     = 4,
	VEL_ORBITA      = 8,        -- rad/s
	ALTURA_ORBITA   = 1,
	ESCALA_ESCUDO   = 0.7,

	RAIO_REFLEXO    = 8,
	FORCA_REFLEXO   = 100,
	DANO_REFLEXO    = 5,
	RAIO_INIMIGO    = 120,

	COR             = Color3.fromRGB(0, 150, 255),
	COR_REFLEXO     = Color3.fromRGB(255, 100, 0),

	NPC_ALCANCE     = 30,
	NPC_RECARGA     = 10,
}

--═══════════════════════════════════════════════════════════════
-- NÚCLEO COMPARTILHADO (§12.6 — modo preciso, sempre com guarda)
-- Nada aqui reimplementa regra de combate: quando _G.Combate existe,
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
	if _G.Combate and _G.Combate.podeCausarDano then
		return _G.Combate.podeCausarDano(owner, alvoHum, humanoid) and true or false
	end
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
	local final = (_G.Combate and _G.Combate.calcular
		and _G.Combate.calcular(owner, alvoHum, bruto)) or bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--── Recarga global anti-clone (§12.9) ──
local function recarga(chave, segundos)
	if _G.Combate and _G.Combate.recargaGlobal then
		return _G.Combate.recargaGlobal(owner, chave, segundos)
	end
	return true, 0
end

--── Detecção em área (§12.8) ──
local function detectar(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		local achados = _G.Combate.detectarHumanoides(posicao, raio, character, owner, humanoid, limite)
		if achados then return achados end
	end
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

local somEquipar  = Handle:FindFirstChild("equip")
local somProtecao = Handle:FindFirstChild("Protecao")
local somImpacto  = {}
for _, nome in ipairs({ "block", "block2", "block3", "block4" }) do
	local s = Handle:FindFirstChild(nome)
	if s then table.insert(somImpacto, s) end
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local barreiraAtiva = false
local npcRecarga    = false
local ID_AURA       = "AURA_" .. RIG_SUFIXO

--═══════════════════════════════════════════════════════════════
-- PROJÉTEIS INIMIGOS
--═══════════════════════════════════════════════════════════════

-- Projétil = BasePart solta em workspace, sem Humanoid no pai, com
-- velocidade relevante e vindo em direção ao portador.
local function projeteisProximos()
	local achados = {}
	if not (rootpart and rootpart.Parent) then return achados end
	local centro = rootpart.Position

	for _, inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("BasePart") and not inst.Anchored and inst ~= Handle then
			local vel = inst.AssemblyLinearVelocity
			if vel and vel.Magnitude > 20 then
				local delta = centro - inst.Position
				local dist  = delta.Magnitude
				if dist <= CFG.RAIO_REFLEXO * 2.5 and delta.Unit:Dot(vel.Unit) > 0.35 then
					table.insert(achados, inst)
				end
			end
		end
	end
	return achados
end

local function inimigoMaisProximo()
	if not (rootpart and rootpart.Parent) then return nil end
	local lista = detectar(rootpart.Position, CFG.RAIO_INIMIGO, 8)
	local melhor, menor = nil, math.huge
	for _, hum in ipairs(lista) do
		local raiz = raizDe(hum)
		if raiz then
			local d = (raiz.Position - rootpart.Position).Magnitude
			if d < menor then melhor, menor = raiz, d end
		end
	end
	return melhor
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE — BARREIRA ORBITAL
--═══════════════════════════════════════════════════════════════

local function ativarProtecao()
	if barreiraAtiva or not (rootpart and humanoid and humanoid.Health > 0) then return end

	local liberado = recarga("Protecao_Barreira", CFG.RECARGA)
	if not liberado then return end

	barreiraAtiva = true
	if somProtecao then somProtecao:Play() end

	local escudo = Handle:Clone()
	escudo.Name         = "EscudoProtecao"
	escudo.CanCollide   = false
	escudo.CanTouch     = false
	escudo.CanQuery     = false
	escudo.Anchored     = true
	escudo.Massless     = true
	escudo.Material     = Enum.Material.ForceField
	escudo.Color        = CFG.COR
	escudo.Transparency = 0.2
	for _, filho in ipairs(escudo:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	local malha = escudo:FindFirstChildOfClass("SpecialMesh")
	if malha then malha.Scale = malha.Scale * CFG.ESCALA_ESCUDO end
	escudo.CFrame = rootpart.CFrame
	escudo.Parent = workspace
	guardarParte(escudo)

	vfx("AURA", {
		id = ID_AURA, alvoNome = character.Name,
		cor = CFG.COR, escala = 0.8, intensidade = 22,
	})

	local angulo    = 0
	local decorrido = 0
	local refletidos = {}
	local encerrado  = false

	local function encerrar()
		if encerrado then return end
		encerrado     = true
		barreiraAtiva = false
		if somProtecao then somProtecao:Stop() end
		vfx("PARAR", { id = ID_AURA })
		if escudo and escudo.Parent then
			vfx("BLOQUEIO", { posicao = escudo.Position, cor = CFG.COR, escala = 1.2 })
			escudo.Parent = nil
		end
		if rig then rig:PlayPose("IDLE", 0.3) end
	end

	guardarConexao(RunService.Heartbeat:Connect(function(dt)
		if encerrado then return end
		if not (escudo.Parent and rootpart and rootpart.Parent) then encerrar(); return end

		decorrido = decorrido + dt
		if decorrido >= CFG.DURACAO then encerrar(); return end

		angulo = angulo + CFG.VEL_ORBITA * dt
		local base = rootpart.Position + Vector3.new(0, CFG.ALTURA_ORBITA, 0)
		local projeteis = projeteisProximos()

		if #projeteis > 0 then
			-- Escolhe o mais próximo e posiciona o escudo na frente dele
			local alvo, menor = projeteis[1], math.huge
			for _, p in ipairs(projeteis) do
				local d = (p.Position - rootpart.Position).Magnitude
				if d < menor then alvo, menor = p, d end
			end

			local dir = (alvo.Position - rootpart.Position)
			if dir.Magnitude > 0.1 then
				escudo.CFrame = CFrame.new(base + dir.Unit * CFG.RAIO_ORBITA, alvo.Position)
			end

			if menor < CFG.RAIO_ORBITA + 2 and not refletidos[alvo] then
				refletidos[alvo] = true
				local inimigo = inimigoMaisProximo()
				local saida = inimigo
					and (inimigo.Position - alvo.Position).Unit
					or rootpart.CFrame.LookVector

				-- SFX -> física -> VFX -> dano (§8 V2)
				tocarSfx("sfx_corte", escudo, 1.4)
				tocarBloco(somImpacto, escudo, 1.25)
				alvo.AssemblyLinearVelocity = saida * CFG.FORCA_REFLEXO
				vfx("BLOQUEIO", { posicao = alvo.Position, cor = CFG.COR_REFLEXO, escala = 1 })
				-- [DE] o projétil devolvido sai cortado em X
				vfx("CORTE_X", { posicao = alvo.Position, cor = CFG.COR_REFLEXO, escala = 0.85 })
				vfx("TREMOR", { preset = "BUMP_PEQUENO" })
				vfx("LINHAS_VELOCIDADE", {
					posicao = alvo.Position, cor = CFG.COR_REFLEXO,
					escala = 0.8, quantidade = 7,
				})

				local perto = detectar(alvo.Position, CFG.RAIO_REFLEXO, 4)
				for _, hum in ipairs(perto) do
					aplicarDano(hum, CFG.DANO_REFLEXO)
				end

				task.delay(1, function() refletidos[alvo] = nil end)
			end
		else
			escudo.CFrame = CFrame.new(
				base + Vector3.new(math.cos(angulo), 0, math.sin(angulo)) * CFG.RAIO_ORBITA
			) * CFrame.Angles(0, -angulo, math.rad(10))
		end
	end))

	if rig then
		rig:PlaySequence("BARREIRA", function(kf)
			if kf.marca == "CARGA" then
				tocarSfx("sfx_carga", Handle, 1.05)
				vfx("LINHAS_VELOCIDADE", {
					posicao = rootpart.Position, cor = CFG.COR, escala = 0.7, quantidade = 6,
				})
			elseif kf.marca == "ABRIR" then
				vfx("BLOQUEIO", { posicao = rootpart.Position, cor = CFG.COR, escala = 1.6 })
				vfx("RAJADA", {
					posicao = rootpart.Position + Vector3.new(0, 1.5, 0),
					cor     = CFG.COR,
					escala  = 0.9,
					direcao = Vector3.new(0, 1, 0),
				})
				vfx("ONDA_CHOQUE", {
					posicao = rootpart.Position - Vector3.new(0, 2.6, 0),
					cor = CFG.COR, escala = 0.8,
				})
			end
		end)
	end

	guardarCancelamento(encerrar)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao)
	if jogador ~= owner or not equipped then return end
	if acao == "activate" then ativarProtecao() end
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
				ativarProtecao()
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
	equipped      = false
	barreiraAtiva = false
	vfx("PARAR", { id = ID_AURA })
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped      = false
	barreiraAtiva = false
	vfx("PARAR", { id = ID_AURA })
	limparTudo()
end)
