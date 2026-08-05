-- EscudoBloqueador_Client_V6.lua
-- LocalScript "Client" DENTRO da Tool "Escudo Bloqueador"
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

local conexaoClique = nil

ligarEntrada = function()
	if conexaoClique then conexaoClique:Disconnect() end
	conexaoClique = Tool.Activated:Connect(function()
		if equipado then RemoteEvent:FireServer("activate") end
	end)

	ContextActionService:BindAction(
		"BloqueadorProtecao", function(_, estado)
			if estado == Enum.UserInputState.Begin and equipado then
				RemoteEvent:FireServer("toggleProtection")
			end
		end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonX
	)
	ContextActionService:SetTitle("BloqueadorProtecao", "Proteção")
	ContextActionService:SetPosition("BloqueadorProtecao", UDim2.new(0.85, 0, 0.15, 0))
end

desligarEntrada = function()
	if conexaoClique then
		conexaoClique:Disconnect()
		conexaoClique = nil
	end
	ContextActionService:UnbindAction("BloqueadorProtecao")
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
