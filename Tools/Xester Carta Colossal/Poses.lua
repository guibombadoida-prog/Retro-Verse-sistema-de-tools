-- Poses.lua
-- ModuleScript "Poses" — Xester Carta Colossal
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

P.CARTA_COLOSSAL_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.455, 1.243, 0.16) * CFrame.Angles(math.rad(178.242), math.rad(9.846), math.rad(10.151)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.411, 1.183, 0.344) * CFrame.Angles(math.rad(-161.762), math.rad(12.693), math.rad(6.204)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.472, 0.213, -0.667) * CFrame.Angles(math.rad(75.387), math.rad(-7.713), math.rad(13.5)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(49.98), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.551, 1.298, -0.133) * CFrame.Angles(math.rad(-179.797), math.rad(-50), math.rad(0.094)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-14.998), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.933, 0.318, 0.634) * CFrame.Angles(math.rad(19.521), math.rad(-14.41), math.rad(90.241)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(9.999), math.rad(14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.665, 0.5, -1.413) * CFrame.Angles(math.rad(89.998), math.rad(0.002), math.rad(-24.997)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SEQUENCIAS = {

	CARTA_COLOSSAL = {
		{ pose = "CARTA_COLOSSAL_2", time = 0.500, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "CARTA_COLOSSAL_3", time = 0.217, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_COLOSSAL_4", time = 0.400, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	BOLA_DE_FOGO_IMENSA = {
		{ pose = "BOLA_DE_FOGO_IMENSA_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "BOLA_DE_FOGO_IMENSA_3", time = 0.250, style = "Exponential", dir = "Out" },
		{ pose = "BOLA_DE_FOGO_IMENSA_4", time = 0.250, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
