-- Poses.lua
-- ModuleScript "Poses" — Escudo Bumerangue
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
--   ARREMESSO            golpe rápido           0.90s · impacto 59% · 1 segurado(s)
--   ARREMESSO_CARREGADO  golpe rápido carregado 1.10s · impacto 57% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.ARREMESSO_CARGA = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-180), math.rad(75.6), math.rad(180)),
	RightArm = CFrame.new(0.95, 0.482, -0.945) * CFrame.Angles(math.rad(90.19), math.rad(2.32), math.rad(-46.57)),
	LeftArm = CFrame.new(-1.31, -0.135, 0.036) * CFrame.Angles(math.rad(-1.36), math.rad(3.89), math.rad(18.95)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-77.85), math.rad(0)),
}

P.ARREMESSO_SOLTA = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-180), math.rad(69.16), math.rad(180)),
	RightArm = CFrame.new(0.756, 0.649, -1.012) * CFrame.Angles(math.rad(98.73), math.rad(-5.51), math.rad(-65.76)),
	LeftArm = CFrame.new(-1.323, -0.122, 0.092) * CFrame.Angles(math.rad(-3.39), math.rad(9.68), math.rad(17.38)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-82.49), math.rad(0)),
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

	-- golpe rápido · 0.90s · 5 passo(s), 1 segurado(s)
	ARREMESSO = {
		{ pose = "ARREMESSO_CARGA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ARREMESSO_CARGA", time = 0.25, style = "Sine", dir = "InOut" },
		{ pose = "ARREMESSO_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO", time = 0.16, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.21, style = "Quad", dir = "Out" },
	},

	-- golpe rápido carregado · 1.10s · 5 passo(s), 1 segurado(s)
	ARREMESSO_CARREGADO = {
		{ pose = "ARREMESSO_CARGA", time = 0.24, style = "Back", dir = "In", tremor = 0.035, freq = 26, marca = "CARGA" },
		{ pose = "ARREMESSO_CARGA", time = 0.31, style = "Sine", dir = "InOut", tremor = 0.035, freq = 26 },
		{ pose = "ARREMESSO_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO", time = 0.2, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.27, style = "Quad", dir = "Out" },
	},

}

return P
