-- Poses.lua
-- ModuleScript "Poses" — Xester Esfera do Fim
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

P.ESFERA_DO_FIM_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.ESFERA_DO_FIM_2 = {
	HRP = CFrame.new(0, 0, 2.96) * CFrame.Angles(math.rad(32.865), math.rad(-45.831), math.rad(2.169)),
	Head = CFrame.new(0.077, 1.962, -0.13) * CFrame.Angles(math.rad(-19.82), math.rad(33.614), math.rad(10.237)),
	LeftArm = CFrame.new(-2.317, 0.73, -0.782) * CFrame.Angles(math.rad(96.692), math.rad(-10.377), math.rad(-22.064)),
	LeftLeg = CFrame.new(-1.405, -2.171, -0.331) * CFrame.Angles(math.rad(-13.521), math.rad(35.152), math.rad(-7.537)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.071, -2.294, 0.17) * CFrame.Angles(math.rad(-32.037), math.rad(-14.211), math.rad(4.863)),
}

P.ESFERA_DO_FIM_3 = {
	HRP = CFrame.new(0, 0, 0.083) * CFrame.Angles(math.rad(-31.75), math.rad(37.192), math.rad(0.406)),
	Head = CFrame.new(0.038, 1.902, -0.023) * CFrame.Angles(math.rad(-2.032), math.rad(-35.859), math.rad(1.284)),
	LeftArm = CFrame.new(-0.587, 0.12, -1.133) * CFrame.Angles(math.rad(69.321), math.rad(-26.268), math.rad(69.143)),
	LeftLeg = CFrame.new(-1.093, -1.897, -0.9) * CFrame.Angles(math.rad(-26.747), math.rad(32.905), math.rad(17.306)),
	RightArm = CFrame.new(0.487, 0.343, -1.032) * CFrame.Angles(math.rad(64.915), math.rad(-24.57), math.rad(-81.952)),
	RightLeg = CFrame.new(1.58, -1.757, -0.819) * CFrame.Angles(math.rad(-13.305), math.rad(-48.877), math.rad(11.711)),
}

P.ESFERA_DO_FIM_4 = {
	HRP = CFrame.new(0, 0, 0.001) * CFrame.Angles(math.rad(-9.124), math.rad(-29.775), math.rad(13.933)),
	Head = CFrame.new(0.136, 1.895, -0.091) * CFrame.Angles(math.rad(-3.547), math.rad(34.541), math.rad(-2.904)),
	LeftArm = CFrame.new(-2.484, 0.234, -0.156) * CFrame.Angles(math.rad(122.766), math.rad(31.298), math.rad(-87.939)),
	LeftLeg = CFrame.new(-1.901, -2.021, -0.657) * CFrame.Angles(math.rad(32.249), math.rad(33.563), math.rad(-40.161)),
	RightArm = CFrame.new(2.336, 0.155, -0.332) * CFrame.Angles(math.rad(69.477), math.rad(-24.205), math.rad(68.485)),
	RightLeg = CFrame.new(0.86, -1.695, -0.683) * CFrame.Angles(math.rad(-39.096), math.rad(-21.231), math.rad(8.056)),
}

P.SEQUENCIAS = {

	ESFERA_DO_FIM = {
		{ pose = "ESFERA_DO_FIM_2", time = 0.250, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "ESFERA_DO_FIM_3", time = 0.467, style = "Exponential", dir = "Out" },
		{ pose = "ESFERA_DO_FIM_4", time = 0.583, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
