-- EscudoBumerangue_Client_V6.lua
-- LocalScript "Client" DENTRO da Tool "Escudo Bumerangue"
--
-- Papel (§12.10): capturar entrada e EXECUTAR os VFX recebidos pelo VFXRemote.
-- Todo efeito visual desta Tool nasce aqui, no cliente — o servidor apenas
-- transmite dados (§12.11). Zero ScreenGui, zero AncestryChanged.

--═══════════════════════════════════════════════════════════════
-- NÚCLEO DO CLIENTE — entrada + recepção de VFX (§12.10)
-- O VFXRemote é UNIDIRECIONAL: aqui só existe OnClientEvent.
-- Zero ScreenGui (§12.12).
--═══════════════════════════════════════════════════════════════

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService           = game:GetService("RunService")

local Tool        = script.Parent
local Jogador     = Players.LocalPlayer
local RemoteEvent = Tool:WaitForChild("RemoteEvent")
local VFXRemote   = Tool:WaitForChild("VFXRemote")
local VFX         = require(Tool:WaitForChild("VFXModule"))
local Poses       = require(Tool:WaitForChild("Poses"))

Tool.CanBeDropped   = false
Tool.RequiresHandle = true

local equipado = false

-- Declaração adiantada: o bloco de ENTRADA (abaixo) preenche estas duas.
local ligarEntrada, desligarEntrada

--── Resolve nome de personagem -> BasePart (payload é dado, não Instance) ──
local function parteDe(nome)
	if type(nome) ~= "string" or nome == "" then return nil end
	local modelo = workspace:FindFirstChild(nome)
	if not modelo then return nil end
	return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
end

--═══════════════════════════════════════════════════════════════
-- CÂMERA DE CUTSCENE (trilho de keyframes — pack Saitama)
--═══════════════════════════════════════════════════════════════

local cutsceneConn = nil
local cameraSalva  = nil

local function pararCutscene()
	if cutsceneConn then
		cutsceneConn:Disconnect()
		cutsceneConn = nil
	end
	local cam = workspace.CurrentCamera
	if cam and cameraSalva then
		cam.CameraType    = Enum.CameraType.Custom
		cam.CameraSubject = cameraSalva
		cameraSalva = nil
	end
end

local function iniciarCutscene(dados)
	local trilho = Poses.CAMERA_EXECUCAO
	if not trilho or #trilho < 2 then return end

	local portador = workspace:FindFirstChild(dados.portador or "")
	local ancora   = portador and (portador:FindFirstChild("HumanoidRootPart"))
	if not ancora then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	pararCutscene()
	cameraSalva = cam.CameraSubject
	cam.CameraType = Enum.CameraType.Scriptable

	local duracao = dados.duracao or 2.9
	local escalaT = duracao / trilho[#trilho].t
	local t = 0

	cutsceneConn = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local tempo = t / escalaT

		if t >= duracao or not ancora.Parent then
			pararCutscene()
			return
		end

		-- interpolação linear entre os dois keyframes que cercam 'tempo'
		local a, b = trilho[1], trilho[#trilho]
		for i = 1, #trilho - 1 do
			if tempo >= trilho[i].t and tempo <= trilho[i + 1].t then
				a, b = trilho[i], trilho[i + 1]
				break
			end
		end
		local intervalo = b.t - a.t
		local alfa = (intervalo > 0) and math.clamp((tempo - a.t) / intervalo, 0, 1) or 0

		workspace.CurrentCamera.CFrame = ancora.CFrame * a.cf:Lerp(b.cf, alfa)
	end)
end

--═══════════════════════════════════════════════════════════════
-- RECEPÇÃO DE VFX
--═══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	dados = dados or {}

	if tipo == "PARAR" then
		VFX.Parar(dados.id)
		return
	end

	if tipo == "CUTSCENE_INICIO" then
		-- Só o portador entra no trilho de câmera; os demais sentem o tremor.
		if Jogador.Character and Jogador.Character.Name == dados.portador then
			iniciarCutscene(dados)
		else
			VFX.Executar("TREMOR", { intensidade = 0.5, duracao = 0.6 })
		end
		return
	end

	if tipo == "CUTSCENE_FIM" then
		pararCutscene()
		return
	end

	-- Efeitos presos a um personagem: resolve o nome em part aqui, no cliente
	if dados.alvoNome then
		dados.alvo = parteDe(dados.alvoNome)
		if not dados.alvo then return end
	end

	-- ⚠️ ISTO FALTAVA, e o bumerangue NÃO VOLTAVA.
	--
	--    O Server manda `pecaNome` no `PROJETIL` (a peça para onde o escudo
	--    retorna), o `VFXModule` lê `d.peca` — e ninguém, no meio, transformava
	--    o nome em instância. `volta` era sempre `nil`, e a linha
	--    `if not volta then VFX.Parar(id) end` fazia o projétil SUMIR no
	--    alcance máximo.
	--
	--    O servidor continuava fazendo o retorno e o dano; só o desenho parava.
	--    Por isso nenhum verificador pegou: não há erro, não há aviso, e o
	--    `.rbxmx` é válido. É a mesma família do `pk` de nome inexistente.
	--
	--    `TESTES/verificar_contrato_payload.py` passa a cobrar isto: todo
	--    `<x>Nome` que um Server manda tem de ser resolvido pelo Client dele.
	if dados.pecaNome then
		dados.peca = parteDe(dados.pecaNome)
		if not dados.peca then return end
	end

	VFX.Executar(tipo, dados)
end)

--═══════════════════════════════════════════════════════════════
-- LIMPEZA
--═══════════════════════════════════════════════════════════════

local function limparCliente()
	pararCutscene()
	VFX.LimparTudo()
end


--═══════════════════════════════════════════════════════════════
-- ENTRADA (input)
--═══════════════════════════════════════════════════════════════

-- Clique  = arremesso normal
-- Segurar = arremesso carregado (>= TEMPO_CARGA)
-- Clique duplo = arremesso múltiplo
-- Zero ScreenGui: o feedback de carga é sonoro/visual pelo servidor (§12.12)

local UserInputService = game:GetService("UserInputService")

local TEMPO_CARGA  = 2
local JANELA_DUPLO = 0.3

local mouse         = Jogador:GetMouse()
local segurando     = false
local inicioCarga   = 0
local ultimoClique  = 0
local conexaoDesce, conexaoSobe
local relogio       = 0
local conexaoRelogio = nil

local function mira()
	if mouse and mouse.Hit then return mouse.Hit.Position end
	local p = Jogador.Character and Jogador.Character:FindFirstChild("HumanoidRootPart")
	return p and (p.Position + p.CFrame.LookVector * 40) or Vector3.new()
end

ligarEntrada = function()
	relogio = 0
	if conexaoRelogio then conexaoRelogio:Disconnect() end
	conexaoRelogio = RunService.Heartbeat:Connect(function(dt)
		relogio = relogio + dt
	end)

	if conexaoDesce then conexaoDesce:Disconnect() end
	if conexaoSobe then conexaoSobe:Disconnect() end

	-- `Tool.Activated` / `Tool.Deactivated`, e NÃO `UserInputService`.
	--
	-- Antes esta Tool enganchava InputBegan/InputEnded em MouseButton1 e Touch.
	-- Isso carrega o arremesso com QUALQUER clique na tela — inclusive clique
	-- que não é na Tool — e fura a §9, que manda a primária vir de
	-- `Tool.Activated`. Era a única das sete que não usava o clique da Tool.
	--
	-- O par Activated/Deactivated é exatamente segurar-e-soltar, já filtrado
	-- pelo Roblox, e já funciona no celular sem código extra.
	conexaoDesce = Tool.Activated:Connect(function()
		if not equipado then return end
		segurando   = true
		inicioCarga = relogio
	end)

	conexaoSobe = Tool.Deactivated:Connect(function()
		if not (segurando and equipado) then return end
		segurando = false

		local carga = relogio - inicioCarga
		local alvo  = mira()

		if carga >= TEMPO_CARGA then
			RemoteEvent:FireServer("throwCharged", alvo)
		elseif relogio - ultimoClique <= JANELA_DUPLO then
			RemoteEvent:FireServer("throwMulti", alvo)
			ultimoClique = 0
		else
			RemoteEvent:FireServer("throw", alvo)
			ultimoClique = relogio
		end
	end)
end

desligarEntrada = function()
	segurando = false
	if conexaoDesce then conexaoDesce:Disconnect(); conexaoDesce = nil end
	if conexaoSobe then conexaoSobe:Disconnect(); conexaoSobe = nil end
	if conexaoRelogio then conexaoRelogio:Disconnect(); conexaoRelogio = nil end
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA DO CLIENTE
--═══════════════════════════════════════════════════════════════

Tool.Equipped:Connect(function()
	equipado = true
	if ligarEntrada then ligarEntrada() end
end)

Tool.Unequipped:Connect(function()
	equipado = false
	if desligarEntrada then desligarEntrada() end
	limparCliente()
end)

-- Tool.Destroying, nunca AncestryChanged (§12.12.2)
Tool.Destroying:Connect(function()
	equipado = false
	if desligarEntrada then desligarEntrada() end
	limparCliente()
end)
