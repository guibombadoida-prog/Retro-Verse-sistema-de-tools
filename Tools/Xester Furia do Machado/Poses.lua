-- Poses.lua
-- ModuleScript "Poses" — Xester Furia do Machado
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
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.FURIA_DO_MACHADO_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-14.9), math.rad(-43.1), math.rad(4.4)),
	Head = CFrame.new(-0.003, 2.002, -0.004) * CFrame.Angles(math.rad(-3.925), math.rad(40.134), math.rad(2.532)),
	LeftArm = CFrame.new(-2.383, 0.304, 0.266) * CFrame.Angles(math.rad(-5.78), math.rad(11.849), math.rad(-48.21)),
	LeftLeg = CFrame.new(-1.743, -2.049, -0.483) * CFrame.Angles(math.rad(45.814), math.rad(41.32), math.rad(-42.864)),
	RightArm = CFrame.new(2.413, 0.189, -0.103) * CFrame.Angles(math.rad(26.004), math.rad(-2.959), math.rad(47.972)),
	RightLeg = CFrame.new(0.875, -1.869, -0.559) * CFrame.Angles(math.rad(-24.193), math.rad(-20.324), math.rad(-8.869)),
}

P.FURIA_DO_MACHADO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-27.488), math.rad(-40.75), math.rad(-28.28)),
	Head = CFrame.new(0.068, 2.006, 0.101) * CFrame.Angles(math.rad(4.565), math.rad(41.56), math.rad(3.095)),
	LeftArm = CFrame.new(-2.192, 0.097, -0.593) * CFrame.Angles(math.rad(47.976), math.rad(-17.098), math.rad(-35.404)),
	LeftLeg = CFrame.new(-1.432, -2.014, -0.959) * CFrame.Angles(math.rad(45.645), math.rad(31.864), math.rad(-26.936)),
	RightArm = CFrame.new(2.155, 1.397, -0.617) * CFrame.Angles(math.rad(138.257), math.rad(44.804), math.rad(-1.525)),
	RightLeg = CFrame.new(1.196, -1.809, -0.93) * CFrame.Angles(math.rad(-18.901), math.rad(-20.973), math.rad(11.332)),
}

P.FURIA_DO_MACHADO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-27.599), math.rad(-40.7), math.rad(16.148)),
	Head = CFrame.new(0.095, 2.003, 0.14) * CFrame.Angles(math.rad(5.462), math.rad(28.49), math.rad(2.63)),
	LeftArm = CFrame.new(-2.258, 0.137, 0.575) * CFrame.Angles(math.rad(-13.597), math.rad(26.857), math.rad(-28.932)),
	LeftLeg = CFrame.new(-1.452, -2.001, -0.99) * CFrame.Angles(math.rad(-11.455), math.rad(39.857), math.rad(8.627)),
	RightArm = CFrame.new(0.932, 1.322, -1.309) * CFrame.Angles(math.rad(142.845), math.rad(10.33), math.rad(-53.078)),
	RightLeg = CFrame.new(1.199, -1.808, -0.934) * CFrame.Angles(math.rad(-18.847), math.rad(-20.97), math.rad(11.536)),
}

P.GARGALHADA_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-14.9), math.rad(-43.1), math.rad(4.4)),
	Head = CFrame.new(-0.003, 2.002, -0.004) * CFrame.Angles(math.rad(-3.925), math.rad(40.134), math.rad(2.532)),
	LeftArm = CFrame.new(-2.383, 0.304, 0.266) * CFrame.Angles(math.rad(-5.78), math.rad(11.849), math.rad(-48.21)),
	LeftLeg = CFrame.new(-1.743, -2.049, -0.483) * CFrame.Angles(math.rad(45.814), math.rad(41.32), math.rad(-42.864)),
	RightArm = CFrame.new(2.413, 0.189, -0.103) * CFrame.Angles(math.rad(26.004), math.rad(-2.959), math.rad(47.972)),
	RightLeg = CFrame.new(0.875, -1.869, -0.559) * CFrame.Angles(math.rad(-24.193), math.rad(-20.324), math.rad(-8.869)),
}

P.SEQUENCIAS = {

	FURIA_DO_MACHADO = {
		{ pose = "FURIA_DO_MACHADO_2", time = 0.150, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "FURIA_DO_MACHADO_3", time = 0.150, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	GARGALHADA = {
		{ pose = "GARGALHADA_1", time = 0.12, style = "Quad", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
