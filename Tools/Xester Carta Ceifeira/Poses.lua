-- Poses.lua
-- ModuleScript "Poses" — Xester Carta Ceifeira
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

P.CARTA_CEIFEIRA_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.CARTA_CEIFEIRA_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.604), math.rad(-35.235), math.rad(6.974)),
	Head = CFrame.new(0.005, 2.005, 0.037) * CFrame.Angles(math.rad(-2.019), math.rad(24.562), math.rad(-1.68)),
	LeftArm = CFrame.new(-2.319, 1, -1.072) * CFrame.Angles(math.rad(109.327), math.rad(-21.372), math.rad(-32.018)),
	LeftLeg = CFrame.new(-1.577, -1.913, -0.743) * CFrame.Angles(math.rad(23.261), math.rad(24.987), math.rad(-28.601)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.136, -2.079, -0.44) * CFrame.Angles(math.rad(-26.919), math.rad(-16.362), math.rad(3.895)),
}

P.CARTA_CEIFEIRA_3 = {
	HRP = CFrame.new(-0.199, 0, 1.988) * CFrame.Angles(math.rad(7.338), math.rad(-28.758), math.rad(22.622)),
	Head = CFrame.new(0.01, 1.933, -0.184) * CFrame.Angles(math.rad(-18.281), math.rad(24.16), math.rad(5.042)),
	LeftArm = CFrame.new(-2.32, 1.003, -1.073) * CFrame.Angles(math.rad(109.396), math.rad(-21.463), math.rad(-32.024)),
	LeftLeg = CFrame.new(-1.64, -2.283, -0.188) * CFrame.Angles(math.rad(-6.149), math.rad(35.091), math.rad(-23.621)),
	RightArm = CFrame.new(0.828, 0.366, 1.292) * CFrame.Angles(math.rad(-101.796), math.rad(-27.609), math.rad(-74.92)),
	RightLeg = CFrame.new(0.976, -2.232, -0.068) * CFrame.Angles(math.rad(-26.9), math.rad(-16.361), math.rad(3.9)),
}

P.CARTA_CEIFEIRA_4 = {
	HRP = CFrame.new(-0.028, 0, 0.283) * CFrame.Angles(math.rad(-21.916), math.rad(-56.016), math.rad(-0.619)),
	Head = CFrame.new(0.043, 2.007, 0.076) * CFrame.Angles(math.rad(3.592), math.rad(50.94), math.rad(3.809)),
	LeftArm = CFrame.new(-0.328, 0.74, -1.507) * CFrame.Angles(math.rad(116.05), math.rad(-0.806), math.rad(71.826)),
	LeftLeg = CFrame.new(-1.757, -2.084, -0.694) * CFrame.Angles(math.rad(50.187), math.rad(38.966), math.rad(-44.189)),
	RightArm = CFrame.new(1.311, 0.68, -1.064) * CFrame.Angles(math.rad(113.816), math.rad(-0.362), math.rad(-49.996)),
	RightLeg = CFrame.new(0.981, -1.908, -0.982) * CFrame.Angles(math.rad(-18.951), math.rad(-20.984), math.rad(-17.809)),
}

P.CARTA_CEIFEIRA_5 = {
	HRP = CFrame.new(-0.001, 0, 0.011) * CFrame.Angles(math.rad(-30.701), math.rad(-60.051), math.rad(-8.44)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.753), math.rad(51.09), math.rad(3.754)),
	LeftArm = CFrame.new(-0.339, 0.681, -1.429) * CFrame.Angles(math.rad(109.648), math.rad(-9.934), math.rad(55.303)),
	LeftLeg = CFrame.new(-1.758, -2.083, -0.698) * CFrame.Angles(math.rad(50.512), math.rad(38.94), math.rad(-44.311)),
	RightArm = CFrame.new(1.707, 0.969, -1.129) * CFrame.Angles(math.rad(125.548), math.rad(-5.65), math.rad(-9.14)),
	RightLeg = CFrame.new(0.982, -1.906, -0.986) * CFrame.Angles(math.rad(-18.911), math.rad(-21.019), math.rad(-17.933)),
}

P.SEQUENCIAS = {

	CARTA_CEIFEIRA = {
		{ pose = "CARTA_CEIFEIRA_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "CARTA_CEIFEIRA_3", time = 0.167, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_CEIFEIRA_4", time = 0.200, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_CEIFEIRA_5", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
