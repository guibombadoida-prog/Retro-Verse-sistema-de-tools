-- Poses.lua
-- ModuleScript "Poses" — Xester Escudo de Cartas
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

P.ESCUDO_DE_CARTAS_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.439, 0.157, -0.471) * CFrame.Angles(math.rad(49.482), math.rad(-14.586), math.rad(3.362)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(-20), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.37, 0.497, -0.927) * CFrame.Angles(math.rad(90), math.rad(-4), math.rad(-20)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(24.786), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.439, 0.159, -0.476) * CFrame.Angles(math.rad(49.667), math.rad(-14.5), math.rad(3.271)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_5 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(-18.735), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.376, 0.495, -0.926) * CFrame.Angles(math.rad(88.825), math.rad(-4.059), math.rad(-19.271)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.935, 0.296, 0.621) * CFrame.Angles(math.rad(19.871), math.rad(-14.022), math.rad(89.56)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-15), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.939, 0.302, 0.624) * CFrame.Angles(math.rad(19.956), math.rad(-14.008), math.rad(89.849)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.665, 0.5, -1.413) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(-25)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SEQUENCIAS = {

	ESCUDO_DE_CARTAS = {
		{ pose = "ESCUDO_DE_CARTAS_2", time = 0.583, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "ESCUDO_DE_CARTAS_3", time = 0.583, style = "Exponential", dir = "Out" },
		{ pose = "ESCUDO_DE_CARTAS_4", time = 0.250, style = "Exponential", dir = "Out" },
		{ pose = "ESCUDO_DE_CARTAS_5", time = 0.167, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	SOPRO_DO_DRAGAO = {
		{ pose = "SOPRO_DO_DRAGAO_2", time = 0.250, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "SOPRO_DO_DRAGAO_3", time = 0.050, style = "Exponential", dir = "Out" },
		{ pose = "SOPRO_DO_DRAGAO_4", time = 0.833, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
