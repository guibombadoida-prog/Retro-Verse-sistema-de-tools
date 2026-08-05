-- EscudoCyclone_Server_V1.lua
-- Script DENTRO da Tool "Escudo Cyclone"
--
-- ORIGEM: clone estrutural do Escudo Bumerangue (Handle, Mesh, sons, grip).
-- HABILIDADES
--   Primária (clique)  : invoca 5 escudos que orbitam o portador. Enquanto
--                        giram, tracionam inimigos no raio para o centro e
--                        causam dano por contato (com janela por alvo).
--   Extra    (Q / ButtonX): pulso de tração — puxão único e forte para o
--                        centro, com dano de arrasto e rachadura no solo.
--
-- CONFORMIDADE
--   §12.4  Values DamageClass / EnergyCost / RecargaGlobal / ChaveRecarga
--   §12.6  modo preciso: _G.Combate.calcular antes do TakeDamage
--   §12.7  tag creator com Name -> Value -> Parent nessa ordem
--   §12.9  recarga global por chave (imune a clone na mochila)
--   §12.11 servidor só transmite VFX; zero :Emit() aqui
--   §10    animação por R6CFrameAnimator + Poses (pack Saitama + Domain)
--   §12.12 Material importado de "Domain Expansion(Elemental)" (cúpula,
--          poses domaint1/domaint2, gongo e estouro de expansão) e de
--          "Judgement Cut End" (destroços, rajada, presets de tremor).
--          Passe de conformidade registrado no cabeçalho do VFXModule.
--   Zero: wait/spawn/delay, math.random, tick, :Destroy em part, +=,
--         continue, AncestryChanged, Instance.new("Explosion"), ScreenGui

local ARQUETIPO  = "HIBRIDO"
local RIG_SUFIXO = "EscudoCyclone"

local CFG = {
	-- ===== CICLONE (habilidade primária) =====
	QTD_ESCUDOS     = 5,
	DURACAO         = 8,
	RECARGA         = 14,
	RAIO_ORBITA     = 7.5,
	ALTURA_ORBITA   = 2.2,
	VEL_ORBITA      = 4.2,      -- rad/s
	ESCALA_ESCUDO   = 0.7,

	-- ===== TRAÇÃO CONTÍNUA =====
	RAIO_TRACAO     = 26,
	FORCA_TRACAO    = 46,
	DANO_CONTATO    = 12,
	RAIO_CONTATO    = 4.5,
	JANELA_CONTATO  = 0.55,     -- s entre dois danos no mesmo alvo

	-- ===== PULSO (habilidade extra) =====
	RAIO_PULSO      = 30,
	FORCA_PULSO     = 130,
	DANO_PULSO      = 22,
	RECARGA_PULSO   = 9,

	-- ===== DOMÍNIO (cúpula importada do Domain Expansion) =====
	RAIO_DOMO       = 56,
	QTD_DESTROCOS   = 15,
	RAIO_DESTROCOS  = 26,

	-- ===== VISUAL =====
	COR             = Color3.fromRGB(80, 200, 255),
	COR_PULSO       = Color3.fromRGB(150, 240, 255),

	-- ===== NPC =====
	NPC_ALCANCE     = 34,
	NPC_RECARGA     = 16,
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

local somEquipar = Handle:FindFirstChild("equip")
local somImpacto = {}
for _, nome in ipairs({ "block", "block2", "block3", "block4" }) do
	local s = Handle:FindFirstChild(nome)
	if s then table.insert(somImpacto, s) end
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local cicloneAtivo   = false
local escudos        = {}          -- clones orbitais
local orbitaConn     = nil
local ultimoDano     = {}          -- [Humanoid] = tempo acumulado
local relogio        = 0           -- acumulador dt (nunca tick())
local pulsoLocal     = false
local npcRecarga     = false

--═══════════════════════════════════════════════════════════════
-- ESCUDOS ORBITAIS
--═══════════════════════════════════════════════════════════════

local function criarEscudo(indice)
	local e = Handle:Clone()
	e.Name         = "EscudoOrbital"
	e.Transparency = 0.1
	e.CanCollide   = false
	e.CanTouch     = false
	e.CanQuery     = false
	e.Anchored     = true
	e.Massless     = true
	e.Color        = CFG.COR
	e.Material     = Enum.Material.Neon
	for _, filho in ipairs(e:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	local malha = e:FindFirstChildOfClass("SpecialMesh")
	if malha then
		malha.Scale = malha.Scale * CFG.ESCALA_ESCUDO
	else
		e.Size = e.Size * CFG.ESCALA_ESCUDO
	end
	e.CFrame = rootpart.CFrame
	e.Parent = workspace
	guardarParte(e)
	return e
end

local function removerEscudos()
	for _, e in ipairs(escudos) do
		if e and e.Parent then e.Parent = nil end
	end
	table.clear(escudos)
end

--═══════════════════════════════════════════════════════════════
-- LOOP DE ÓRBITA + TRAÇÃO + CONTATO
--═══════════════════════════════════════════════════════════════

local function passoCiclone(dt)
	if not (cicloneAtivo and rootpart and rootpart.Parent) then return end
	relogio = relogio + dt

	local centro = rootpart.Position + Vector3.new(0, CFG.ALTURA_ORBITA, 0)
	local passo  = (math.pi * 2) / CFG.QTD_ESCUDOS

	-- 1. posiciona os escudos
	for i, e in ipairs(escudos) do
		if e and e.Parent then
			local ang = relogio * CFG.VEL_ORBITA + (i - 1) * passo
			local desloc = Vector3.new(
				math.cos(ang) * CFG.RAIO_ORBITA,
				math.sin(relogio * 2 + i) * 0.5,
				math.sin(ang) * CFG.RAIO_ORBITA
			)
			e.CFrame = CFrame.new(centro + desloc)
				* CFrame.Angles(0, -ang + math.pi * 0.5, math.rad(18))
		end
	end

	-- 2. tração e dano por contato
	local alvos = detectar(centro, CFG.RAIO_TRACAO, 12)
	for _, hum in ipairs(alvos) do
		local raiz = raizDe(hum)
		if raiz then
			local delta = centro - raiz.Position
			local dist  = delta.Magnitude

			-- tração proporcional: quanto mais longe, mais puxa
			if dist > 3 then
				local intensidade = CFG.FORCA_TRACAO * math.clamp(dist / CFG.RAIO_TRACAO, 0.25, 1)
				empurrar(raiz, delta, intensidade, 0.16)
			end

			-- contato com qualquer escudo
			local marca = ultimoDano[hum] or -99
			if relogio - marca >= CFG.JANELA_CONTATO then
				for _, e in ipairs(escudos) do
					if e and e.Parent and (e.Position - raiz.Position).Magnitude <= CFG.RAIO_CONTATO then
						ultimoDano[hum] = relogio
						tocarSfx("sfx_impacto", raiz, 1.3)
						tocarBloco(somImpacto, raiz, 1.4)
						vfx("IMPACTO", {
							posicao = raiz.Position,
							cor     = CFG.COR,
							escala  = 1.1,
						})
						aplicarDano(hum, CFG.DANO_CONTATO)
						break
					end
				end
			end
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE PRIMÁRIA — INVOCAR O CICLONE
--═══════════════════════════════════════════════════════════════

local function encerrarCiclone()
	if not cicloneAtivo then return end
	cicloneAtivo = false

	if orbitaConn then
		orbitaConn:Disconnect()
		orbitaConn = nil
	end

	vfx("PARAR", { id = "CICLONE_" .. RIG_SUFIXO })
	vfx("PARAR", { id = "DOMO_" .. RIG_SUFIXO })
	if rootpart and rootpart.Parent then
		vfx("ONDA_CHOQUE", {
			posicao = rootpart.Position - Vector3.new(0, 2.6, 0),
			cor     = CFG.COR,
			escala  = 1.3,
		})
	end

	removerEscudos()
	table.clear(ultimoDano)

	if rig then rig:PlayPose("IDLE", 0.35) end
end

local function invocarCiclone()
	if cicloneAtivo or not (rootpart and rootpart.Parent) then return end

	local liberado = recarga("EscudoCyclone_Ciclone", CFG.RECARGA)
	if not liberado then return end

	cicloneAtivo = true
	relogio      = 0
	table.clear(ultimoDano)

	if rig then
		rig:PlaySequence("DOMINIO", function(kf)
			if kf.marca == "GONGO" then
				-- [DE] beat 1: o gongo de abertura do domínio
				tocarSfx("sfx_dominio", Handle, 1)
				vfx("LINHAS_VELOCIDADE", {
					posicao    = rootpart.Position,
					cor        = CFG.COR,
					escala     = 0.9,
					quantidade = 10,
				})
				vfx("TREMOR", { preset = "VIBRACAO" })

			elseif kf.marca == "EXPANDIR" then
				-- SFX -> física -> VFX -> dano (§8 V2)
				tocarSfx("sfx_expansao", Handle, 1)
				tocarBloco(somImpacto, Handle, 0.75)
				for i = 1, CFG.QTD_ESCUDOS do
					table.insert(escudos, criarEscudo(i))
				end
				-- [DE] a cúpula: casca ForceField + núcleo escuro + discos
				vfx("DOMO", {
					id       = "DOMO_" .. RIG_SUFIXO,
					alvoNome = character.Name,
					cor      = CFG.COR,
					raio     = CFG.RAIO_DOMO,
				})
				vfx("CICLONE", {
					id       = "CICLONE_" .. RIG_SUFIXO,
					alvoNome = character.Name,
					cor      = CFG.COR,
					escala   = 1,
					raio     = CFG.RAIO_ORBITA * 1.6,
				})
				vfx("RAJADA", {
					posicao = rootpart.Position + Vector3.new(0, 2, 0),
					cor     = CFG.COR,
					escala  = 1.5,
					direcao = Vector3.new(0, 1, 0),
				})
				vfx("ZOOM", { fov = 82, subida = 0.25, espera = 0.5 })
				vfx("TREMOR", { preset = "EXPLOSAO" })

			elseif kf.marca == "SUSTENTAR" then
				-- [JC] anel de destroços erguido pela pressão da cúpula
				vfx("DESTROCOS", {
					posicao    = rootpart.Position - Vector3.new(0, 2.8, 0),
					cor        = CFG.COR,
					escala     = 1,
					quantidade = CFG.QTD_DESTROCOS,
					raio       = CFG.RAIO_DESTROCOS,
				})
				vfx("RACHADURA_SOLO", {
					posicao    = rootpart.Position - Vector3.new(0, 2.8, 0),
					cor        = CFG.COR,
					escala     = 1.1,
					quantidade = CFG.QTD_ESCUDOS,
				})
			end
		end)
	else
		for i = 1, CFG.QTD_ESCUDOS do
			table.insert(escudos, criarEscudo(i))
		end
	end

	orbitaConn = guardarConexao(RunService.Heartbeat:Connect(passoCiclone))

	task.delay(CFG.DURACAO, function()
		encerrarCiclone()
	end)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE EXTRA — PULSO DE TRAÇÃO
--═══════════════════════════════════════════════════════════════

local function pulsoTracao()
	if pulsoLocal or not (rootpart and rootpart.Parent) then return end

	local liberado = recarga("EscudoCyclone_Pulso", CFG.RECARGA_PULSO)
	if not liberado then return end

	pulsoLocal = true

	if rig then
		rig:PlaySequence("CICLONE_PUXA", function(kf)
			if kf.marca ~= "PUXAR" then return end

			local centro = rootpart.Position
			tocarSfx("sfx_carga", Handle, 0.9)
			tocarBloco(somImpacto, Handle, 0.6)

			local alvos = detectar(centro, CFG.RAIO_PULSO, 16)
			for _, hum in ipairs(alvos) do
				local raiz = raizDe(hum)
				if raiz then
					local delta = (centro - raiz.Position)
					if delta.Magnitude > 0.5 then
						empurrar(raiz, delta + Vector3.new(0, 12, 0), CFG.FORCA_PULSO, 0.35)
					end
				end
			end

			vfx("PULSO_TRACAO", {
				posicao = centro,
				cor     = CFG.COR_PULSO,
				escala  = 1.4,
				raio    = CFG.RAIO_PULSO * 0.6,
			})
			vfx("RACHADURA_SOLO", {
				posicao    = centro - Vector3.new(0, 2.8, 0),
				cor        = CFG.COR_PULSO,
				escala     = 1.4,
				quantidade = 12,
			})
			vfx("TREMOR", { preset = "EXPLOSAO_PEQUENA" })
			vfx("DESTROCOS", {
				posicao    = centro - Vector3.new(0, 2.8, 0),
				cor        = CFG.COR_PULSO,
				escala     = 0.8,
				quantidade = 12,
				raio       = CFG.RAIO_PULSO * 0.5,
			})

			for _, hum in ipairs(alvos) do
				aplicarDano(hum, CFG.DANO_PULSO)
			end
		end)
	end

	task.delay(CFG.RECARGA_PULSO, function()
		pulsoLocal = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

RemoteEvent.OnServerEvent:Connect(function(jogador, acao)
	if jogador ~= owner or not equipped then return end
	if acao == "activate" then
		invocarCiclone()
	elseif acao == "pulso" then
		pulsoTracao()
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
				invocarCiclone()
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
		encerrarCiclone()
		limparTudo()
	end))
end)

-- Tool.Enabled NÃO é resetado aqui (§8 / §10.7 — bypass de recarga)
Tool.Unequipped:Connect(function()
	equipped = false
	encerrarCiclone()
	limparTudo()
end)

Tool.Destroying:Connect(function()
	equipped = false
	encerrarCiclone()
	limparTudo()
end)
