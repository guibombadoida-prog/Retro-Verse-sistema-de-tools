-- Poses.lua
-- ModuleScript "Poses" — Xester Invocacao
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

P.INVOCACAO_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.INVOCACAO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.038, 0.768, -0.509) * CFrame.Angles(math.rad(122.391), math.rad(-2.395), math.rad(-22.707)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.INVOCACAO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-28.109), math.rad(-53.06), math.rad(-6.08)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.708), math.rad(50.883), math.rad(3.792)),
	LeftArm = CFrame.new(-0.331, 0.741, -1.507) * CFrame.Angles(math.rad(116.006), math.rad(-0.667), math.rad(71.863)),
	LeftLeg = CFrame.new(-1.754, -2.083, -0.701) * CFrame.Angles(math.rad(50.33), math.rad(38.899), math.rad(-44.09)),
	RightArm = CFrame.new(1.309, 0.681, -1.06) * CFrame.Angles(math.rad(113.807), math.rad(-0.221), math.rad(-50.037)),
	RightLeg = CFrame.new(0.982, -1.907, -0.982) * CFrame.Angles(math.rad(-18.986), math.rad(-20.981), math.rad(-17.82)),
}

P.INVOCACAO_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.96), math.rad(-59.925), math.rad(-8.67)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.754), math.rad(51.089), math.rad(3.754)),
	LeftArm = CFrame.new(-0.339, 0.681, -1.429) * CFrame.Angles(math.rad(109.648), math.rad(-9.933), math.rad(55.303)),
	LeftLeg = CFrame.new(-1.758, -2.083, -0.698) * CFrame.Angles(math.rad(50.512), math.rad(38.94), math.rad(-44.311)),
	RightArm = CFrame.new(1.707, 0.969, -1.129) * CFrame.Angles(math.rad(125.547), math.rad(-5.65), math.rad(-9.14)),
	RightLeg = CFrame.new(0.982, -1.906, -0.986) * CFrame.Angles(math.rad(-18.911), math.rad(-21.019), math.rad(-17.933)),
}

P.SEQUENCIAS = {

	INVOCACAO = {
		{ pose = "INVOCACAO_2", time = 0.067, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "INVOCACAO_3", time = 0.200, style = "Exponential", dir = "Out" },
		{ pose = "INVOCACAO_4", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
