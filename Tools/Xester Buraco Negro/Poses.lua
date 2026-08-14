-- Poses.lua
-- ModuleScript "Poses" — Xester Buraco Negro
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama ReleaseLegs
-- ao fim de toda sequência. Perna soldada permanentemente trava a caminhada.
--
-- ESTAS POSES NÃO SÃO AUTORAIS. Saíram do script original do modelo, pelo
-- FERRAMENTAS/extrair_poses_xester.py: a convenção de Weld foi invertida
-- (o original solda membro→Torso, o animator solda Torso→membro), o pivô do
-- C1 foi composto, e cada keyframe é o ponto que o `:lerp(alvo, alpha)`
-- repetido N quadros REALMENTE alcança — não o alvo escrito no código.
--
-- GUARDA_1 é a postura de `position == "Idle"` do original: é ela que segura
-- tronco e pernas enquanto o golpe move só o braço.

local P = {}


P.GUARDA_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BURACO_NEGRO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BURACO_NEGRO_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.455, 1.245, 0.162) * CFrame.Angles(math.rad(177.39), math.rad(9.77), math.rad(10.223)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.RAIO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.RAIO_2 = {
	HRP = CFrame.new(0, -0.001, 0) * CFrame.Angles(math.rad(0), math.rad(89.691), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.994, 0.49, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(89.573)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SEQUENCIAS = {

	BURACO_NEGRO = {
		{ pose = "BURACO_NEGRO_2", time = 0.250, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	RAIO = {
		{ pose = "RAIO_2", time = 0.250, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
