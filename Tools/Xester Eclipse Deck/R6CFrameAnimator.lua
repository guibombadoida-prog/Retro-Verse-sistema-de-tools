-- R6CFrameAnimator_V2.lua
-- ModuleScript — sistema de animação R6 procedural em CFrame (Retro-Verse)
-- Superset do V1: pernas sob demanda, timelines (PlaySequence), tremor, lock.
--[==[
═══════════════════════════════════════════════════════════════
        R6 CFRAME ANIMATOR V2  (§10.11.7)
═══════════════════════════════════════════════════════════════
Compatível com a API do V1 (PlayPose / SetJoint / StartIdleBob /
StopIdleBob / Destroy) e adiciona:

- Juntas RightLeg / LeftLeg — criadas SOB DEMANDA (só quando uma
  pose as usa) e liberadas ao fim da sequência, para não travar a
  caminhada fora de cutscene.
- rig:PlaySequence(seqName, onBeat, onDone) — timeline encadeada
  por Tween.Completed (nunca task.wait(duração)).
- rig:CancelSequence() — cancela timeline + tremor e volta ao IDLE.
- rig:LockCharacter(bool) — WalkSpeed/JumpPower = 0, AutoRotate
  off; guarda e restaura os valores originais.
- rig:StartTremor(joint, amp, freq) / rig:StopTremor() — vibração
  aditiva por acumulador dt com envelope de fade-in (sem math.random,
  sem tick(): senoide multi-frequência determinística).
- rig:PlayTrack(trackName, onEvent, onDone) — reproduz uma TRACK
  (animação remasterizada do pack): dezenas de keyframes amostrados por
  acumulador dt em Heartbeat, com easing por segmento via
  TweenService:GetValue. Timing EXATO: não encadeia tweens, portanto
  não acumula o ~1 frame de atraso por keyframe que o chaining teria.

Regras do projeto respeitadas: sem wait()/spawn()/delay(), sem
tick(), sem +=/continue, sem math.random, Welds removidos por
reparent, Destroy cancela sequência + tremor + lock.

USO:
  local Animator = require(Tool:WaitForChild("R6CFrameAnimator"))
  local rig = Animator.new(character, "SeriousMode", POSES, SEQUENCES)
  rig:PlaySequence("TRANSFORM", onBeat, onDone)
═══════════════════════════════════════════════════════════════
--]==]

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local Animator = {}
Animator.__index = Animator

local LEG_BASE = {
	RightLeg = CFrame.new(0.5, -2, 0),
	LeftLeg  = CFrame.new(-0.5, -2, 0),
}

local function resolveStyle(name)
	return (name and Enum.EasingStyle[name]) or Enum.EasingStyle.Quad
end
local function resolveDir(name)
	return (name and Enum.EasingDirection[name]) or Enum.EasingDirection.Out
end

--[[
	Animator.new(character, weldSuffix, poses, sequences)
	- character:  Model R6 do portador
	- weldSuffix: string única por Tool (evita colisão de nomes de Weld)
	- poses:      tabela de poses { NOME = { Junta = CFrame, ... } }
	- sequences:  tabela de timelines { NOME = { {pose,time,style,dir,tremor,cam,sfx}, ... } }
	Retorna o rig, ou nil se o R6 não estiver montado.
]]
function Animator.new(character, weldSuffix, poses, sequences, tracks)
	if not character then return nil end
	local torso = character:FindFirstChild("Torso")
	local rArm  = character:FindFirstChild("Right Arm")
	local lArm  = character:FindFirstChild("Left Arm")
	local head  = character:FindFirstChild("Head")
	local root  = character:FindFirstChild("HumanoidRootPart")
	if not (torso and rArm and head and root) then return nil end

	local self = setmetatable({}, Animator)
	self.Character   = character
	self.Suffix      = weldSuffix or "Rig"
	self.Poses       = poses or {}
	self.Sequences   = sequences or {}
	self.Tracks      = tracks or {}
	self.Welds       = {}
	self.IdleConn    = nil
	self.TremorConn  = nil
	self.SeqToken    = 0          -- token de cancelamento da timeline
	self.SeqActive   = false
	self.SeqTweens   = {}
	self.TrackConn   = nil
	self.Locked      = false
	self.SavedWalk   = nil
	self.SavedJump   = nil
	self.SavedRotate = nil
	self.Destroyed   = false

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
	self._makeWeld = makeWeld

	self.Welds.RightArm = makeWeld("RightArmWeld", torso, rArm, CFrame.new(1.5, 0, 0))
	self.Welds.Head     = makeWeld("HeadWeld",     torso, head, CFrame.new(0, 1.5, 0))
	self.Welds.HRP      = makeWeld("HRPWeld",      root,  torso, CFrame.new())
	if lArm then
		self.Welds.LeftArm = makeWeld("LeftArmWeld", torso, lArm, CFrame.new(-1.5, 0, 0))
	end

	return self
end

-- Cria os Welds das pernas sob demanda (a pose pediu RightLeg/LeftLeg)
function Animator:_ensureLeg(joint)
	if self.Destroyed then return nil end
	if self.Welds[joint] and self.Welds[joint].Parent then return self.Welds[joint] end
	local torso = self.Character and self.Character:FindFirstChild("Torso")
	if not torso then return nil end
	local partName = (joint == "RightLeg") and "Right Leg" or "Left Leg"
	local leg = self.Character:FindFirstChild(partName)
	if not leg then return nil end
	self.Welds[joint] = self._makeWeld(joint .. "Weld", torso, leg, LEG_BASE[joint])
	return self.Welds[joint]
end

-- Libera as pernas (reparent) para devolver a caminhada ao Humanoid
function Animator:ReleaseLegs()
	for _, joint in ipairs({ "RightLeg", "LeftLeg" }) do
		local w = self.Welds[joint]
		if w then
			if w.Parent then w.Parent = nil end
			self.Welds[joint] = nil
		end
	end
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
		if not w and LEG_BASE[joint] then
			w = self:_ensureLeg(joint)
		end
		if w and w.Parent then
			TweenService:Create(w, ti, { C0 = c0 }):Play()
		end
	end
end

-- Define o C0 de uma junta instantaneamente (sem tween)
function Animator:SetJoint(joint, c0)
	if self.Destroyed then return end
	local w = self.Welds[joint]
	if not w and LEG_BASE[joint] then w = self:_ensureLeg(joint) end
	if w and w.Parent then w.C0 = c0 end
end

--[[
	rig:PlaySequence(seqName, onBeat, onDone)
	Timeline de keyframes { pose, time, style, dir, tremor, ... }.
	Encadeada por Tween.Completed — o próximo beat só dispara quando o
	tween do anterior conclui. onBeat(kf, índice) roda no INÍCIO de cada
	beat (ponto de disparo de cam/sfx/VFX). onDone() roda ao final.
]]
function Animator:PlaySequence(seqName, onBeat, onDone)
	if self.Destroyed then return false end
	local seq = self.Sequences[seqName]
	if not seq or #seq == 0 then return false end

	self:CancelSequence()
	self.SeqToken = self.SeqToken + 1
	local token = self.SeqToken
	self.SeqActive = true

	local index = 0

	local function step()
		if self.Destroyed or token ~= self.SeqToken then return end
		index = index + 1
		local kf = seq[index]
		if not kf then
			self.SeqActive = false
			self:StopTremor()
			self:ReleaseLegs()
			if onDone then onDone() end
			return
		end

		if kf.tremor and kf.tremor > 0 then
			self:StartTremor("HRP", kf.tremor, kf.freq or 22)
		else
			self:StopTremor()
		end
		if onBeat then onBeat(kf, index) end

		local pose = self.Poses[kf.pose]
		if not pose then
			step()
			return
		end
		local ti = TweenInfo.new(kf.time or 0.3, resolveStyle(kf.style), resolveDir(kf.dir))
		local chained = nil
		for joint, c0 in pairs(pose) do
			local w = self.Welds[joint]
			if not w and LEG_BASE[joint] then w = self:_ensureLeg(joint) end
			if w and w.Parent then
				local tw = TweenService:Create(w, ti, { C0 = c0 })
				table.insert(self.SeqTweens, tw)
				if not chained then chained = tw end
				tw:Play()
			end
		end
		if chained then
			chained.Completed:Once(function()
				if token == self.SeqToken then step() end
			end)
		else
			-- pose sem junta válida: pular para o próximo beat imediatamente
			step()
		end
	end

	step()
	return true
end

--[[
	rig:PlayTrack(trackName, onEvent, onDone)
	Reproduz uma track remasterizada: lista de keyframes
	{ t, style, dir, event, cam, tremor, <Junta> = CFrame, ... }
	Amostragem por acumulador dt a partir de zero; entre dois keyframes o
	C0 de cada junta é interpolado com o easing do segmento de destino.
	onEvent(kf, índice) dispara UMA vez ao cruzar cada keyframe marcado.
]]
function Animator:PlayTrack(trackName, onEvent, onDone)
	if self.Destroyed then return false end
	local track = self.Tracks[trackName]
	if not track or #track < 2 then return false end

	self:CancelSequence()
	self.SeqToken = self.SeqToken + 1
	local token = self.SeqToken
	self.SeqActive = true

	-- garante os Welds de perna se a track os usa
	local first = track[1]
	for joint in pairs(first) do
		if LEG_BASE[joint] then self:_ensureLeg(joint) end
	end

	local duration = track[#track].t
	local elapsed  = 0
	local index    = 1
	local fired    = 0

	self.TrackConn = RunService.Heartbeat:Connect(function(dt)
		if self.Destroyed or token ~= self.SeqToken then return end
		elapsed = elapsed + dt

		-- avança o índice do segmento e dispara os eventos cruzados
		while index < #track and elapsed >= track[index + 1].t do
			index = index + 1
			local kf = track[index]
			if fired < index then
				fired = index
				if kf.tremor and kf.tremor > 0 then
					self:StartTremor("HRP", kf.tremor, kf.freq or 20)
				elseif kf.tremor == nil and self.TremorConn then
					self:StopTremor()
				end
				if onEvent and (kf.event or kf.cam or kf.sfx) then
					onEvent(kf, index)
				end
			end
		end

		local a = track[index]
		local b = track[index + 1]
		if not b then
			-- fim da track
			for joint, c0 in pairs(a) do
				local w = self.Welds[joint]
				if w and w.Parent then w.C0 = c0 end
			end
			self:StopTrack()
			self.SeqActive = false
			self:StopTremor()
			self:ReleaseLegs()
			if onDone then onDone() end
			return
		end

		local span = b.t - a.t
		local alpha = (span > 0) and math.clamp((elapsed - a.t) / span, 0, 1) or 1
		local eased = TweenService:GetValue(alpha, resolveStyle(b.style), resolveDir(b.dir))

		for joint, c0 in pairs(a) do
			if typeof(c0) == "CFrame" then
				local target = b[joint]
				local w = self.Welds[joint]
				if w and w.Parent and typeof(target) == "CFrame" then
					w.C0 = c0:Lerp(target, eased)
				end
			end
		end
	end)

	return true, duration
end

function Animator:StopTrack()
	if self.TrackConn then
		self.TrackConn:Disconnect()
		self.TrackConn = nil
	end
end

-- Cancela a timeline em andamento, para o tremor e libera as pernas.
function Animator:CancelSequence()
	self.SeqToken = self.SeqToken + 1
	self.SeqActive = false
	self:StopTrack()
	for _, tw in ipairs(self.SeqTweens) do
		tw:Cancel()
	end
	table.clear(self.SeqTweens)
	self:StopTremor()
	self:ReleaseLegs()
end

-- Trava/destrava o personagem, guardando e restaurando os valores originais.
function Animator:LockCharacter(lock)
	if self.Destroyed and lock then return end
	local hum = self.Character and self.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if lock and not self.Locked then
		self.Locked      = true
		self.SavedWalk   = hum.WalkSpeed
		self.SavedJump   = hum.JumpPower
		self.SavedRotate = hum.AutoRotate
		hum.WalkSpeed  = 0
		hum.JumpPower  = 0
		hum.AutoRotate = false
	elseif (not lock) and self.Locked then
		self.Locked = false
		hum.WalkSpeed  = self.SavedWalk or 16
		hum.JumpPower  = self.SavedJump or 50
		hum.AutoRotate = (self.SavedRotate == nil) and true or self.SavedRotate
	end
end

--[[
	rig:StartTremor(joint, amp, freq)
	Vibração aditiva determinística sobre o C0 corrente da junta:
	senoide multi-frequência (freq e freq*1.73) com envelope de
	fade-in de 0.35 s, por acumulador dt a partir de zero.
]]
function Animator:StartTremor(joint, amp, freq)
	if self.Destroyed then return end
	self:StopTremor()
	local w = self.Welds[joint]
	if not w then return end
	amp  = amp or 0.03
	freq = freq or 22

	local t = 0
	self.TremorConn = RunService.Heartbeat:Connect(function(dt)
		if self.Destroyed then return end
		local weld = self.Welds[joint]
		if not (weld and weld.Parent) then return end
		t = t + dt
		local envelope = math.min(t / 0.35, 1)
		local a = amp * envelope
		local ox = math.sin(t * freq) * a
		local oy = math.sin(t * freq * 1.73 + 1.1) * a * 0.6
		local oz = math.sin(t * freq * 0.61 + 2.3) * a * 0.4
		weld.C0 = weld.C0 * CFrame.new(ox, oy, oz)
	end)
end

function Animator:StopTremor()
	if self.TremorConn then
		self.TremorConn:Disconnect()
		self.TremorConn = nil
	end
end

-- Loop de respiração/idle: pequeno bob senoidal via acumulador dt.
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
		if run and not self.SeqActive then
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

-- Remove todos os Welds (reparent), cancela sequência/tremor e destrava.
function Animator:Destroy()
	self:CancelSequence()
	self:StopIdleBob()
	self:LockCharacter(false)
	self.Destroyed = true
	for _, w in pairs(self.Welds) do
		if w and w.Parent then w.Parent = nil end
	end
	table.clear(self.Welds)
end

return Animator
