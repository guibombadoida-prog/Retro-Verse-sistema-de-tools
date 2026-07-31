-- R6CFrameAnimator_V1.lua
-- ModuleScript reutilizável — sistema de animação R6 procedural em CFrame
-- Colocar como ModuleScript dentro da Tool (ou em ReplicatedStorage/módulo compartilhado)
-- e requerer no Server Script: local Animator = require(script.R6CFrameAnimator)

--[==[
═══════════════════════════════════════════════════════════════
        R6 CFRAME ANIMATOR V1
═══════════════════════════════════════════════════════════════
Extraído das Tools da família His Cube (Server V5 / variantes V1).
Anima o R6 SEM Animation assets: cria Welds manuais e faz lerp/tween
do C0 a cada frame. Compatível com todas as regras do projeto:

- CFrame procedural (Weld.C0), nunca Animation/AnimationTrack
- Idle bob via acumulador dt a partir de zero (nunca tick()*speed)
- Sem wait()/spawn() — exclusivamente task.* / RunService
- Sem +=, sem continue
- Welds removidos por reparent (Parent=nil), nunca :Destroy() manual
- Não reseta estado no Unequipped além do necessário

USO BÁSICO:
  local Animator = require(script.R6CFrameAnimator)
  local rig = Animator.new(character, "HisCube", POSES) -- POSES opcional
  rig:PlayPose("IDLE", 0.3)
  rig:StartIdleBob("IDLE", "RightArm")   -- opcional
  ...
  rig:Destroy()  -- no Unequipped / morte

Cada "pose" é uma tabela de C0 alvo por junta:
  POSES.SHOOT = {
      RightArm = CFrame.new(...) * CFrame.Angles(...),
      Head     = CFrame.new(0,1.5,0),
      HRP      = CFrame.new(),
  }
Juntas suportadas: RightArm, LeftArm, Head, HRP (HumanoidRootPart→Torso).
═══════════════════════════════════════════════════════════════
--]==]

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local Animator = {}
Animator.__index = Animator

-- Poses padrão (mesmas do His Cube V5) — usadas se nenhuma for passada
local DEFAULT_POSES = {
	IDLE = {
		RightArm = CFrame.new(1.5, 0.2, -0.2) * CFrame.Angles(math.rad(50), 0, math.rad(8)),
		Head     = CFrame.new(0, 1.5, 0),
		HRP      = CFrame.new(),
	},
	SHOOT = {
		RightArm = CFrame.new(1.2, 0.5, -1.0) * CFrame.Angles(math.rad(90), 0, math.rad(-10)),
		Head     = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-5), math.rad(-10), 0),
		HRP      = CFrame.new(0, 0, -0.2) * CFrame.Angles(0, math.rad(-15), 0),
	},
	CAST_Q = {
		RightArm = CFrame.new(1.3, 0.8, 0) * CFrame.Angles(math.rad(150), 0, math.rad(15)),
		Head     = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(15), 0, 0),
		HRP      = CFrame.new(),
	},
	CAST_E = {
		RightArm = CFrame.new(1.5, 0.8, 0) * CFrame.Angles(math.rad(160), 0, math.rad(20)),
		Head     = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), 0, 0),
		HRP      = CFrame.new() * CFrame.Angles(math.rad(-5), 0, 0),
	},
}
Animator.DefaultPoses = DEFAULT_POSES

--[[
	Animator.new(character, weldSuffix, poses)
	- character:  Model R6 do portador
	- weldSuffix: string única por Tool (evita colisão de nomes de Weld)
	- poses:      tabela de poses (opcional; usa DEFAULT_POSES se nil)
	Retorna o rig, ou nil se o R6 não estiver montado.
]]
function Animator.new(character, weldSuffix, poses)
	if not character then return nil end
	local torso = character:FindFirstChild("Torso")
	local rArm  = character:FindFirstChild("Right Arm")
	local lArm  = character:FindFirstChild("Left Arm")
	local head  = character:FindFirstChild("Head")
	local root  = character:FindFirstChild("HumanoidRootPart")
	if not (torso and rArm and head and root) then return nil end

	local self = setmetatable({}, Animator)
	self.Character  = character
	self.Suffix     = weldSuffix or "Rig"
	self.Poses      = poses or DEFAULT_POSES
	self.Welds      = {}
	self.IdleConn   = nil
	self.Destroyed  = false

	-- Fixar o RightGrip para a Tool ficar na mão em pose neutra
	local rg = rArm:FindFirstChild("RightGrip")
	if rg then rg.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0) end

	local function makeWeld(name, p0, p1, c0)
		local w = Instance.new("Weld")
		w.Name  = name .. self.Suffix
		w.Part0 = p0
		w.Part1 = p1
		w.C0    = c0
		w.Parent = p0
		return w
	end

	self.Welds.RightArm = makeWeld("RightArmWeld", torso, rArm, CFrame.new(1.5, 0, 0))
	self.Welds.Head     = makeWeld("HeadWeld",     torso, head, CFrame.new(0, 1.5, 0))
	self.Welds.HRP      = makeWeld("HRPWeld",      root,  torso, CFrame.new())
	if lArm then
		self.Welds.LeftArm = makeWeld("LeftArmWeld", torso, lArm, CFrame.new(-1.5, 0, 0))
	end

	return self
end

-- Aplica uma pose (tween do C0 de cada junta presente na pose)
function Animator:PlayPose(poseName, duration, easingStyle, easingDir)
	if self.Destroyed then return end
	local pose = self.Poses[poseName]
	if not pose then return end
	local ti = TweenInfo.new(
		duration or 0.2,
		easingStyle or Enum.EasingStyle.Quad,
		easingDir or Enum.EasingDirection.Out
	)
	for joint, c0 in pairs(pose) do
		local w = self.Welds[joint]
		if w and w.Parent then
			TweenService:Create(w, ti, { C0 = c0 }):Play()
		end
	end
end

-- Define o C0 de uma junta instantaneamente (sem tween)
function Animator:SetJoint(joint, c0)
	if self.Destroyed then return end
	local w = self.Welds[joint]
	if w and w.Parent then w.C0 = c0 end
end

-- Loop de respiração/idle: pequeno bob senoidal via acumulador dt.
-- shouldRun() (opcional) permite pausar durante outras animações.
function Animator:StartIdleBob(poseName, joint, amplitude, speed, shouldRun)
	if self.Destroyed then return end
	self:StopIdleBob()
	local pose = self.Poses[poseName]
	if not pose or not pose[joint] then return end
	local baseC0 = pose[joint]
	amplitude = amplitude or 0.02
	speed     = speed or 2

	local t = 0
	self.IdleConn = RunService.Heartbeat:Connect(function(dt)
		if self.Destroyed then return end
		t = t + dt
		local run = (shouldRun == nil) or shouldRun()
		if run then
			local b = math.sin(t * speed) * amplitude
			local w = self.Welds[joint]
			if w and w.Parent then
				w.C0 = w.C0:Lerp(baseC0 * CFrame.new(0, b, 0), 0.05)
			end
		end
	end)
end

function Animator:StopIdleBob()
	if self.IdleConn then
		self.IdleConn:Disconnect()
		self.IdleConn = nil
	end
end

-- Remove todos os Welds (reparent, nunca :Destroy() manual) e para o idle.
function Animator:Destroy()
	self.Destroyed = true
	self:StopIdleBob()
	for _, w in pairs(self.Welds) do
		if w and w.Parent then w.Parent = nil end
	end
	self.Welds = {}
end

return Animator
