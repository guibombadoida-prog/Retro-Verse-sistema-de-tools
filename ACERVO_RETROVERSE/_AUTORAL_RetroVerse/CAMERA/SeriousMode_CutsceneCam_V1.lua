-- SeriousMode_CutsceneCam_V1 (LocalScript "CutsceneCam" dentro da Tool)
-- Câmera 100% client-side (§10.11.8). Beats: START → ORBIT → CLOSE → PUNCH → STOP.
-- Técnicas (análise do pack): órbita bezier de 2 estágios + CONTRASTE de FOV
-- (fecha a 38 na carga, estoura a 96 no burst) + shake por acumulador dt.
-- Sem ScreenGui / ColorCorrection / Animation / math.random / tick().

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS          = game:GetService("ContextActionService")

local Tool   = script.Parent
local Remote = Tool:WaitForChild("CutsceneRemote")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FOV_BASE  = 70
local FOV_CLOSE = 38   -- telefoto na carga (tensão)
local FOV_PUNCH = 96   -- estouro no burst (contraste é o que vende o golpe)
local SKIP_HOLD = 1.5

local active    = false
local camConn   = nil
local savedType = nil
local holdAccum = 0
local holding   = false
local stage     = "A"  -- A = órbita de abertura | B = órbita de carga
local elapsed   = 0
local duracao   = 15

-- Bezier quadrática — arco de grua, nunca linha reta mecânica
local function bezier(t, p0, p1, p2)
	local u = 1 - t
	return (p0 * (u * u)) + (p1 * (2 * u * t)) + (p2 * (t * t))
end

-- Pontos de controle DETERMINÍSTICOS derivados do HRP (§10.11.8)
local ptsA = nil -- abertura: meia-altura, de frente, distancia média
local ptsB = nil -- carga: mais baixo e mais perto (peso)
local function computePoints(hrp)
	local base = hrp.CFrame
	ptsA = {
		(base * CFrame.new(-5, 3.2, 9)).Position,
		(base * CFrame.new(-11, 5.5, 1)).Position,
		(base * CFrame.new(-3, 2.6, -8)).Position,
	}
	ptsB = {
		(base * CFrame.new(3, 1.4, 7)).Position,
		(base * CFrame.new(7, 1.0, 0)).Position,
		(base * CFrame.new(2, 1.8, -6)).Position,
	}
end

local function stopCutscene()
	if not active then return end
	active = false
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	CAS:UnbindAction("SeriousModeSkip")
	camera.FieldOfView = FOV_BASE
	camera.CameraType  = savedType or Enum.CameraType.Custom
	savedType = nil
	holdAccum = 0
	holding   = false
	stage     = "A"
end

local function onSkip(_, state)
	if state == Enum.UserInputState.Begin then
		holding = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		holding = false
		holdAccum = 0
	end
	return Enum.ContextActionResult.Sink
end

local function startCutscene(total)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	stopCutscene()

	duracao   = total or 15
	savedType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	active  = true
	elapsed = 0
	stage   = "A"
	computePoints(hrp)
	CAS:BindAction("SeriousModeSkip", onSkip, true, Enum.KeyCode.E)

	camConn = RunService.RenderStepped:Connect(function(dt)
		if not active then return end
		local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not h then
			stopCutscene()
			return
		end

		elapsed = elapsed + dt
		local t = math.min(elapsed / duracao, 1)

		local pts = (stage == "A") and ptsA or ptsB
		local pos = bezier(t, pts[1], pts[2], pts[3])
		local alvo = h.Position + Vector3.new(0, 1.4, 0)

		-- roll sutil + shake senoidal por acumulador dt (cresce com a carga)
		local roll  = math.sin(t * math.pi) * math.rad(3)
		local shake = math.sin(elapsed * 24) * 0.03 * t
			+ math.sin(elapsed * 41) * 0.012 * t
		camera.CFrame = CFrame.lookAt(pos + Vector3.new(shake, shake * 0.5, 0), alvo)
			* CFrame.Angles(0, 0, roll)

		if holding then
			holdAccum = holdAccum + dt
			if holdAccum >= SKIP_HOLD then
				stopCutscene() -- puramente visual: NÃO afeta a timeline do servidor
			end
		end
	end)
end

local function orbitStage()
	if not active then return end
	stage = "B" -- troca de estágio de órbita: mais baixo, mais perto
end

local function closeFov()
	if not active then return end
	TweenService:Create(
		camera,
		TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ FieldOfView = FOV_CLOSE }
	):Play()
end

local function fovPunch()
	if not active then return end
	camera.FieldOfView = FOV_PUNCH
	TweenService:Create(
		camera,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = FOV_BASE }
	):Play()
end

Remote.OnClientEvent:Connect(function(beat, total)
	if beat == "START" then
		startCutscene(total or 15)
	elseif beat == "ORBIT" then
		orbitStage()
	elseif beat == "CLOSE" then
		closeFov()
	elseif beat == "PUNCH" then
		fovPunch()
	elseif beat == "STOP" or beat == "CANCEL" then
		stopCutscene()
	end
end)

Tool.Unequipped:Connect(stopCutscene)
Tool.Destroying:Connect(stopCutscene)
