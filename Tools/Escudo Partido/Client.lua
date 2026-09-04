-- EscudoPartido_Client_V1.lua
-- LocalScript "Client" DENTRO da Tool "Escudo Partido"
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
local TweenService         = game:GetService("TweenService")

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
-- CÂMERA DE CUTSCENE
--
-- Reescrita pela GRAMATICA_CUTSCENE (ACERVO/_AUTORAL_RetroVerse/CAMERA/),
-- medida no molde da casa e no YorrSlayer. O que entrou, e o que faltava:
--
--   CONTRASTE DE FOV     era a maior lacuna: esta Tool não mexia em FOV
--                        nenhum, e as duas fontes tratam isso como A técnica.
--                        70 fecha em 44 na carga e estoura em 92 no golpe
--                        mortal. Amplitude 48 — entre o soco na cara do
--                        SeriousMode (58) e o dragão distante do Yorr (34),
--                        porque a execução do Partido é corpo a corpo mas não
--                        colada no rosto.
--
--   ENQUADRAMENTO POR    o achado do YorrSlayer. Antes, só o portador via a
--   ESPECTADOR           cutscene e o alvo levava um tremor genérico. Agora o
--                        ALVO vê a própria morte chegando: 13 studs atrás de
--                        si, altura de olho, olhando para a própria cabeça.
--
--   PULAR                segurar E por 1.5 s. Uma execução de 6.24 s sem pulo
--                        vira punição para quem já a viu dez vezes. É SÓ
--                        visual: o servidor segue no tempo dele.
--
--   TREMOR COM ENVELOPE  duas frequências que não se repetem (24 e 41), com
--                        envelope que nasce forte e some. Só na janela do
--                        golpe mortal, nunca na cena inteira. Zero math.random.
--
-- O trilho de keyframes do pack continua sendo a espinha do enquadramento do
-- PORTADOR — ele é bom e é o que dá a coreografia. O que mudou em volta dele
-- foi tudo o mais.
--═══════════════════════════════════════════════════════════════

local FOV_BASE  = 70
local FOV_CLOSE = 44   -- fecha na postura (tensão)
local FOV_PUNCH = 92   -- estoura no golpe mortal
local SKIP_HOLD = 1.5
local VELOC_CAM = 3.2

-- janela do tremor: o golpe mortal da EXECUCAO cai em ~85% de 6.24 s
local TREMOR_DE  = 4.6
local TREMOR_ATE = 5.6

local cutsceneConn = nil
local cameraSalva  = nil
local tipoSalvo    = nil
local segurando, acumSkip = false, 0

local function pararCutscene()
	if cutsceneConn then
		cutsceneConn:Disconnect()
		cutsceneConn = nil
	end
	ContextActionService:UnbindAction("PartidoExecucaoSkip")
	segurando, acumSkip = false, 0

	local cam = workspace.CurrentCamera
	if cam then
		-- o FOV volta SEMPRE, mesmo que a cena tenha sido cortada no meio
		TweenService:Create(cam, TweenInfo.new(0.3), { FieldOfView = FOV_BASE }):Play()
		if cameraSalva or tipoSalvo then
			cam.CameraType    = tipoSalvo or Enum.CameraType.Custom
			cam.CameraSubject = cameraSalva
		end
	end
	cameraSalva, tipoSalvo = nil, nil
end

local function aoPular(_, estado)
	if estado == Enum.UserInputState.Begin then
		segurando = true
	elseif estado == Enum.UserInputState.End
		or estado == Enum.UserInputState.Cancel then
		segurando, acumSkip = false, 0
	end
	return Enum.ContextActionResult.Sink
end

--- Jitter determinístico: duas frequências que não se repetem, com envelope
--- que faz o tremor nascer forte e sumir sozinho dentro da janela.
local function tremorEm(t, janelaT)
	local env = math.clamp(1 - janelaT, 0, 1)
	return (math.sin(t * 24) * 0.35 + math.sin(t * 41) * 0.14) * env
end

--- Plano do ALVO: atrás de si mesmo, vendo a própria cara ser alcançada.
local function planoAlvo(alvoRaiz, alvoCabeca)
	local frente = alvoRaiz.CFrame.LookVector
	local pos = alvoRaiz.Position - frente * 13 + Vector3.new(0, 4.5, 0)
	local olhar = (alvoCabeca and alvoCabeca.Position)
		or (alvoRaiz.Position + Vector3.new(0, 1.5, 0))
	return pos, olhar
end

local function iniciarCutscene(dados, ehAlvo)
	local trilho = Poses.CAMERA_EXECUCAO
	local portador = workspace:FindFirstChild(dados.portador or "")
	local ancora   = portador and portador:FindFirstChild("HumanoidRootPart")
	if not ancora then return end
	if not ehAlvo and (not trilho or #trilho < 2) then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	pararCutscene()
	cameraSalva = cam.CameraSubject
	tipoSalvo   = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable

	local alvoModelo = dados.alvoNome and workspace:FindFirstChild(dados.alvoNome)
	local alvoRaiz   = alvoModelo and alvoModelo:FindFirstChild("HumanoidRootPart")
	local alvoCabeca = alvoModelo and alvoModelo:FindFirstChild("Head")
	if ehAlvo and not alvoRaiz then return end

	local duracao = dados.duracao or 6.24
	local escalaT = (trilho and #trilho >= 2)
		and (duracao / trilho[#trilho].t) or 1
	local t = 0
	local estouro = false
	local curPos = cam.CFrame.Position
	local curOlhar = cam.CFrame.Position + cam.CFrame.LookVector

	ContextActionService:BindAction("PartidoExecucaoSkip", aoPular, true,
		Enum.KeyCode.E, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle("PartidoExecucaoSkip", "Pular")

	TweenService:Create(cam, TweenInfo.new(1.2, Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut), { FieldOfView = FOV_CLOSE }):Play()

	cutsceneConn = RunService.RenderStepped:Connect(function(dt)
		t = t + dt

		if t >= duracao or not ancora.Parent then
			pararCutscene()
			return
		end

		-- pular: segura E, solta a câmera. NÃO mexe no tempo do servidor.
		if segurando then
			acumSkip = acumSkip + dt
			if acumSkip >= SKIP_HOLD then
				pararCutscene()
				return
			end
		end

		if ehAlvo then
			if not (alvoRaiz and alvoRaiz.Parent) then
				pararCutscene()
				return
			end
			-- aproximação exponencial: independente de FPS e interrompível
			local metaPos, metaOlhar = planoAlvo(alvoRaiz, alvoCabeca)
			local k = 1 - math.exp(-VELOC_CAM * dt)
			curPos   = curPos:Lerp(metaPos, k)
			curOlhar = curOlhar:Lerp(metaOlhar, k)
			workspace.CurrentCamera.CFrame = CFrame.lookAt(curPos, curOlhar)
		else
			local tempo = t / escalaT
			local a, b = trilho[1], trilho[#trilho]
			for i = 1, #trilho - 1 do
				if tempo >= trilho[i].t and tempo <= trilho[i + 1].t then
					a, b = trilho[i], trilho[i + 1]
					break
				end
			end
			local intervalo = b.t - a.t
			local alfa = (intervalo > 0)
				and math.clamp((tempo - a.t) / intervalo, 0, 1) or 0

			local base = ancora.CFrame * a.cf:Lerp(b.cf, alfa)
			local desvio = Vector3.new()
			if t > TREMOR_DE and t < TREMOR_ATE then
				local j = tremorEm(t, (t - TREMOR_DE) / (TREMOR_ATE - TREMOR_DE))
				desvio = Vector3.new(j, j * 0.5, 0)
			end
			workspace.CurrentCamera.CFrame = base + desvio
		end

		-- o estouro de FOV cai no golpe mortal, e acontece UMA vez
		if not estouro and t >= TREMOR_DE then
			estouro = true
			workspace.CurrentCamera.FieldOfView = FOV_PUNCH
			TweenService:Create(workspace.CurrentCamera,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ FieldOfView = FOV_BASE }):Play()
		end
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
		-- Enquadramento POR ESPECTADOR: o portador segue o trilho do pack; o
		-- ALVO vê a própria morte chegando. Quem não é nem um nem outro segue
		-- com a câmera dele e só sente o tremor.
		local meu = Jogador.Character and Jogador.Character.Name
		if meu and meu == dados.portador then
			iniciarCutscene(dados, false)
		elseif meu and meu == dados.alvoNome then
			iniciarCutscene(dados, true)
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
		"PartidoExecucao", function(_, estado)
			if estado == Enum.UserInputState.Begin and equipado then
				RemoteEvent:FireServer("partido")
			end
		end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonX
	)
	ContextActionService:SetTitle("PartidoExecucao", "Partido")
	ContextActionService:SetPosition("PartidoExecucao", UDim2.new(0.85, 0, 0.15, 0))
end

desligarEntrada = function()
	if conexaoClique then
		conexaoClique:Disconnect()
		conexaoClique = nil
	end
	ContextActionService:UnbindAction("PartidoExecucao")
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
