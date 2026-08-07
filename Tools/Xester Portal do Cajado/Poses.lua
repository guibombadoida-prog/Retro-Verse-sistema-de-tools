-- Poses.lua
-- ModuleScript "Poses" — Xester Portal do Cajado
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

P.PROCISSAO_DE_CARTAS_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.PROCISSAO_DE_CARTAS_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-17.746), math.rad(28.056), math.rad(-12.978)),
	Head = CFrame.new(0.023, 2.005, 0.055) * CFrame.Angles(math.rad(-1.968), math.rad(-27.061), math.rad(1.058)),
	LeftArm = CFrame.new(-2.353, 0.443, 0.326) * CFrame.Angles(math.rad(98.67), math.rad(0.653), math.rad(-114.328)),
	LeftLeg = CFrame.new(-0.853, -1.941, -0.974) * CFrame.Angles(math.rad(-12.839), math.rad(26.606), math.rad(5.374)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.323, -2.009, -0.309) * CFrame.Angles(math.rad(-25.964), math.rad(-32.422), math.rad(2.795)),
}

P.PROCISSAO_DE_CARTAS_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-36.4), math.rad(-42.48), math.rad(4.026)),
	Head = CFrame.new(0.038, 2.009, 0.088) * CFrame.Angles(math.rad(10.445), math.rad(39.336), math.rad(-8.544)),
	LeftArm = CFrame.new(-1.253, 0.752, -1.519) * CFrame.Angles(math.rad(98.886), math.rad(-0.337), math.rad(24.781)),
	LeftLeg = CFrame.new(-1.78, -1.868, -1.089) * CFrame.Angles(math.rad(48.066), math.rad(33.722), math.rad(-39.71)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(0.926, -1.819, -0.307) * CFrame.Angles(math.rad(-63.229), math.rad(-29.312), math.rad(-17.349)),
}

P.PROCISSAO_DE_CARTAS_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.621), math.rad(-56.256), math.rad(2.9)),
	Head = CFrame.new(0.041, 1.965, 0.095) * CFrame.Angles(math.rad(24.454), math.rad(43.474), math.rad(-19.174)),
	LeftArm = CFrame.new(-2.376, 1.372, -0.992) * CFrame.Angles(math.rad(102.586), math.rad(-36.182), math.rad(-43.442)),
	LeftLeg = CFrame.new(-1.759, -2.083, -0.7) * CFrame.Angles(math.rad(50.504), math.rad(38.924), math.rad(-44.296)),
	RightArm = CFrame.new(2.353, -0.045, 0.249) * CFrame.Angles(math.rad(26.991), math.rad(-39.131), math.rad(42.94)),
	RightLeg = CFrame.new(0.982, -1.905, -0.983) * CFrame.Angles(math.rad(-19.047), math.rad(-21.043), math.rad(-17.92)),
}

P.SEQUENCIAS = {

	PROCISSAO_DE_CARTAS = {
		{ pose = "PROCISSAO_DE_CARTAS_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "PROCISSAO_DE_CARTAS_3", time = 0.433, style = "Exponential", dir = "Out" },
		{ pose = "PROCISSAO_DE_CARTAS_4", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
