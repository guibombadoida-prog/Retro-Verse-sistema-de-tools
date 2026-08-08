-- Poses.lua
-- ModuleScript "Poses" — Salvador
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
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, os sete escudos dividiam o mesmo
-- arquivo de 440 linhas — este traz só o que esta Tool usa.
--
-- As SILHUETAS são as da remasterização e não mudaram: é a mesma habilidade,
-- do mesmo modelo. O que mudou foi o TEMPO, re-cronometrado pela gramática
-- medida no pack de referência (ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md).
--
-- O que a gramática impôs aqui:
--   SACRIFICIO           golpe rápido           0.95s · impacto 60% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.SACRIFICIO_CARGA = {
	HRP = CFrame.new(0.012, -0.038, 0.048) * CFrame.Angles(math.rad(-39.13), math.rad(-31.46), math.rad(-14.97)),
	RightArm = CFrame.new(1.73, 0.007, -0.191) * CFrame.Angles(math.rad(20.45), math.rad(4.51), math.rad(31.9)),
	LeftArm = CFrame.new(-1.52, -0.154, 0.317) * CFrame.Angles(math.rad(26.35), math.rad(12.04), math.rad(-8.3)),
	Head = CFrame.new(0.036, 1.457, 0.199) * CFrame.Angles(math.rad(26.7), math.rad(38), math.rad(-5.2)),
}

P.SACRIFICIO_ALTO = {
	HRP = CFrame.new(0.085, 0.336, -0.174) * CFrame.Angles(math.rad(102.99), math.rad(62.95), math.rad(-91.13)),
	RightArm = CFrame.new(1.774, 1.715, -0.269) * CFrame.Angles(math.rad(-30.91), math.rad(-37.17), math.rad(164.04)),
	LeftArm = CFrame.new(-1.648, 0.092, 0.41) * CFrame.Angles(math.rad(38.8), math.rad(10.33), math.rad(-33.88)),
	Head = CFrame.new(0.097, 1.453, -0.188) * CFrame.Angles(math.rad(-60.03), math.rad(-72.08), math.rad(-38.9)),
}

P.GUARDA_FIRME = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-18.28), math.rad(-39.56), math.rad(-11.01)),
	RightArm = CFrame.new(1.564, 0.422, -0.017) * CFrame.Angles(math.rad(72.6), math.rad(4.68), math.rad(22.04)),
	LeftArm = CFrame.new(-1.566, 0.077, -0.035) * CFrame.Angles(math.rad(3.89), math.rad(-0.68), math.rad(-8.11)),
	Head = CFrame.new(0, 1.466, -0.182) * CFrame.Angles(math.rad(-21.4), math.rad(-0.85), math.rad(0.03)),
}

P.IDLE = {
	RightArm = CFrame.new(
		1.40557981, 0.499999762, -0.579227924,
		0.98480767, 0.173648134, 0,
		0, 0, -0.999999821,
		-0.173648134, 0.98480767, 0
	),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(6), 0, math.rad(6)),
	Head = CFrame.new(
		0, 1.49999976, 0,
		0.173648208, 0, -0.98480767,
		0, 0.999999881, 0,
		0.98480767, 0, 0.173648208
	),
	HRP = CFrame.new(
		0, 0, 0,
		0.173648134, 0, 0.98480773,
		0, 0.99999994, 0,
		-0.98480773, 0, 0.173648134
	),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.95s · 5 passo(s), 1 segurado(s)
	SACRIFICIO = {
		{ pose = "SACRIFICIO_CARGA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SACRIFICIO_CARGA", time = 0.25, style = "Sine", dir = "InOut", tremor = 0.03, freq = 20 },
		{ pose = "SACRIFICIO_ALTO", time = 0.1, style = "Quint", dir = "Out", tremor = 0.03, freq = 20, marca = "VINCULO" },
		{ pose = "GUARDA_FIRME", time = 0.16, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

}

return P
