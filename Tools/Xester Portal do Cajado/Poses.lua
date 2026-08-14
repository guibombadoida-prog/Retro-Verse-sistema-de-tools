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

P.PORTAL_DO_CAJADO_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-4), math.rad(-18), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(14), math.rad(0)),
	LeftArm = CFrame.new(-1.42, 0.06, -0.3) * CFrame.Angles(math.rad(28), math.rad(10), math.rad(16)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.16) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.34, 0.18, -0.52) * CFrame.Angles(math.rad(62), math.rad(-16), math.rad(-24)),
	RightLeg = CFrame.new(0.5, -1.92, -0.18) * CFrame.Angles(math.rad(-9), math.rad(0), math.rad(0)),
}

P.PORTAL_DO_CAJADO_2 = {
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-12), math.rad(-32), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-16), math.rad(26), math.rad(0)),
	LeftArm = CFrame.new(-1.36, 0.24, -0.62) * CFrame.Angles(math.rad(72), math.rad(14), math.rad(24)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.22) * CFrame.Angles(math.rad(11), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.52, 0.44, -1.16) * CFrame.Angles(math.rad(104), math.rad(-22), math.rad(-10)),
	RightLeg = CFrame.new(0.5, -1.88, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), math.rad(0)),
}

P.PORTAL_DO_CAJADO_3 = {
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-11), math.rad(-30), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-15), math.rad(24), math.rad(0)),
	LeftArm = CFrame.new(-1.35, 0.26, -0.64) * CFrame.Angles(math.rad(74), math.rad(13), math.rad(23)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.22) * CFrame.Angles(math.rad(11), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.53, 0.46, -1.18) * CFrame.Angles(math.rad(106), math.rad(-21), math.rad(-9)),
	RightLeg = CFrame.new(0.5, -1.88, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), math.rad(0)),
}

P.PORTAL_DO_CAJADO_4 = {
	HRP = CFrame.new(0, -0.08, 0) * CFrame.Angles(math.rad(14), math.rad(28), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(-22), math.rad(0)),
	LeftArm = CFrame.new(-1.44, -0.04, -0.36) * CFrame.Angles(math.rad(32), math.rad(-12), math.rad(-18)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.28) * CFrame.Angles(math.rad(15), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.44, -0.22, -0.74) * CFrame.Angles(math.rad(42), math.rad(24), math.rad(18)),
	RightLeg = CFrame.new(0.5, -1.82, -0.42) * CFrame.Angles(math.rad(-21), math.rad(0), math.rad(0)),
}

P.PORTAL_DO_CAJADO_5 = {
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(11), math.rad(22), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(9), math.rad(-18), math.rad(0)),
	LeftArm = CFrame.new(-1.44, -0.02, -0.34) * CFrame.Angles(math.rad(30), math.rad(-10), math.rad(-16)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.26) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.42, -0.18, -0.68) * CFrame.Angles(math.rad(38), math.rad(20), math.rad(16)),
	RightLeg = CFrame.new(0.5, -1.84, -0.38) * CFrame.Angles(math.rad(-19), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	PORTAL_DO_CAJADO = {
		{ pose = "PORTAL_DO_CAJADO_2", time = 0.420, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "PORTAL_DO_CAJADO_3", time = 0.180, style = "Exponential", dir = "Out" },
		{ pose = "PORTAL_DO_CAJADO_4", time = 0.140, style = "Exponential", dir = "Out" },
		{ pose = "PORTAL_DO_CAJADO_5", time = 0.400, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
