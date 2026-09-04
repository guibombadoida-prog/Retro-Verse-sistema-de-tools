-- Poses.lua
-- ModuleScript "Poses" — Escudo Bloqueador
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
--   PROTEGER             golpe rápido           0.95s · impacto 61% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.GUARDA_FIRME = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-18.28), math.rad(-39.56), math.rad(-11.01)),
	RightArm = CFrame.new(1.564, 0.422, -0.017) * CFrame.Angles(math.rad(72.6), math.rad(4.68), math.rad(22.04)),
	LeftArm = CFrame.new(-1.566, 0.077, -0.035) * CFrame.Angles(math.rad(3.89), math.rad(-0.68), math.rad(-8.11)),
	Head = CFrame.new(0, 1.466, -0.182) * CFrame.Angles(math.rad(-21.4), math.rad(-0.85), math.rad(0.03)),
}

P.CONTRA_GOLPE = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-20.13), math.rad(37.64), math.rad(16.46)),
	RightArm = CFrame.new(1.443, 0.234, 0.652) * CFrame.Angles(math.rad(99.58), math.rad(-2.93), math.rad(65.63)),
	LeftArm = CFrame.new(-1.659, 0.316, 0.178) * CFrame.Angles(math.rad(12.43), math.rad(17.95), math.rad(-33.49)),
	Head = CFrame.new(0.058, 1.496, -0.013) * CFrame.Angles(math.rad(-4.57), math.rad(-24.32), math.rad(-7.31)),
}

P.CORTE_F = { -- [70] abertura reversa
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-24.83), math.rad(43.09), math.rad(15.3)),
	RightArm = CFrame.new(1.883, 0.722, -0.885) * CFrame.Angles(math.rad(91.4), math.rad(19.63), math.rad(33.13)),
	LeftArm = CFrame.new(-1.729, 0.313, -0.144) * CFrame.Angles(math.rad(60.51), math.rad(-2.69), math.rad(-26.59)),
	Head = CFrame.new(0.035, 1.493, 0.075) * CFrame.Angles(math.rad(5.82), math.rad(-34.64), math.rad(-4.93)),
}

P.ARREMESSO_RECUO = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(78.95), math.rad(0)),
	RightArm = CFrame.new(1.807, 0.563, -0.447) * CFrame.Angles(math.rad(96.02), math.rad(-0.36), math.rad(13.17)),
	LeftArm = CFrame.new(-1.546, 0.051, -0.01) * CFrame.Angles(math.rad(-0.07), math.rad(-1.11), math.rad(-5.6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-65.52), math.rad(0)),
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

	-- golpe rápido · 0.95s · 6 passo(s), 1 segurado(s)
	PROTEGER = {
		{ pose = "GUARDA_FIRME", time = 0.2, style = "Back", dir = "In", marca = "SAIDA" },
		{ pose = "GUARDA_FIRME", time = 0.28, style = "Sine", dir = "InOut" },
		{ pose = "CONTRA_GOLPE", time = 0.1, style = "Quint", dir = "Out", tremor = 0.04, freq = 24, marca = "CHEGADA" },
		{ pose = "CORTE_F", time = 0.09, style = "Quint", dir = "Out", marca = "REPULSAO" },
		{ pose = "ARREMESSO_RECUO", time = 0.14, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.14, style = "Quad", dir = "Out" },
	},

}

return P
