-- Poses.lua
-- ModuleScript "Poses" — Escudo Partido
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
--   ARREMESSO_CARREGADO  golpe rápido carregado 1.10s · impacto 57% · 1 segurado(s)
--   CORTE_COMBO          combo (35:65)          1.12s · impacto 41% · 1 segurado(s)
--   EXECUCAO             ultimate (64–86%)      5.99s · impacto 88% · 2 segurado(s)
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

P.CORTE_A = { -- [8] carga curta
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-6.97), math.rad(1.72), math.rad(2.47)),
	RightArm = CFrame.new(1.648, 0.353, -0.45) * CFrame.Angles(math.rad(85.81), math.rad(11.16), math.rad(-2.5)),
	LeftArm = CFrame.new(-1.591, 0.359, 0.528) * CFrame.Angles(math.rad(52.74), math.rad(-1.49), math.rad(-51.85)),
	Head = CFrame.new(0.026, 1.499, -0.001) * CFrame.Angles(math.rad(-0.03), math.rad(1.3), math.rad(-2.94)),
}

P.CORTE_B = { -- [24] corte descendente
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-25.94), math.rad(-34.21), math.rad(-11.18)),
	RightArm = CFrame.new(1.412, 0.635, -0.466) * CFrame.Angles(math.rad(120.14), math.rad(17.49), math.rad(0.43)),
	LeftArm = CFrame.new(-1.52, 0.803, -1.489) * CFrame.Angles(math.rad(107.06), math.rad(-3.02), math.rad(-28.56)),
	Head = CFrame.new(-0.011, 1.495, 0.072) * CFrame.Angles(math.rad(7.57), math.rad(28.91), math.rad(1.39)),
}

P.CORTE_C = { -- [31] corte alto
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-32.63), math.rad(-7.69), math.rad(-8.35)),
	RightArm = CFrame.new(1.38, 1.053, -0.632) * CFrame.Angles(math.rad(136.61), math.rad(19.06), math.rad(-2.27)),
	LeftArm = CFrame.new(-1.813, 0.573, -1.182) * CFrame.Angles(math.rad(113.48), math.rad(-5.17), math.rad(-14.42)),
	Head = CFrame.new(0.012, 1.49, 0.097) * CFrame.Angles(math.rad(11.47), math.rad(12.46), math.rad(-1.41)),
}

P.CORTE_D = { -- [44] transversal
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.19), math.rad(-30.08), math.rad(-13.12)),
	RightArm = CFrame.new(1.159, 0.819, -0.625) * CFrame.Angles(math.rad(134.11), math.rad(16.88), math.rad(-14.85)),
	LeftArm = CFrame.new(-1.875, 0.744, -1.164) * CFrame.Angles(math.rad(119.59), math.rad(-9.75), math.rad(-32.31)),
	Head = CFrame.new(0.005, 1.498, 0.047) * CFrame.Angles(math.rad(5.8), math.rad(31.66), math.rad(-0.68)),
}

P.CORTE_E = { -- [57] retorno
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-25.02), math.rad(-34.36), math.rad(-10.66)),
	RightArm = CFrame.new(1.254, 0.655, -0.599) * CFrame.Angles(math.rad(120.14), math.rad(17.49), math.rad(-16.44)),
	LeftArm = CFrame.new(-1.772, 0.912, -1.177) * CFrame.Angles(math.rad(134.81), math.rad(-16.72), math.rad(-26.54)),
	Head = CFrame.new(-0.037, 1.498, 0.024) * CFrame.Angles(math.rad(-0.12), math.rad(33.98), math.rad(5.11)),
}

P.CORTE_F = { -- [70] abertura reversa
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-24.83), math.rad(43.09), math.rad(15.3)),
	RightArm = CFrame.new(1.883, 0.722, -0.885) * CFrame.Angles(math.rad(91.4), math.rad(19.63), math.rad(33.13)),
	LeftArm = CFrame.new(-1.729, 0.313, -0.144) * CFrame.Angles(math.rad(60.51), math.rad(-2.69), math.rad(-26.59)),
	Head = CFrame.new(0.035, 1.493, 0.075) * CFrame.Angles(math.rad(5.82), math.rad(-34.64), math.rad(-4.93)),
}

P.EXEC_POSTURA = { -- [85] postura baixa, peso no pé de trás
	HRP = CFrame.new(0.087, -0.246, 0.013) * CFrame.Angles(math.rad(-0.51), math.rad(-8.57), math.rad(-0.43)),
	RightArm = CFrame.new(1.012, 0.09, -0.47) * CFrame.Angles(math.rad(97.98), math.rad(-44.97), math.rad(-38.22)),
	LeftArm = CFrame.new(-1.529, 0, 0.14) * CFrame.Angles(math.rad(0.34), math.rad(25.29), math.rad(-4.26)),
	RightLeg = CFrame.new(0.718, -1.988, 0.092) * CFrame.Angles(math.rad(-20.97), math.rad(-14.02), math.rad(10.14)),
	LeftLeg = CFrame.new(-0.56, -1.815, -0.323) * CFrame.Angles(math.rad(3.1), math.rad(5.2), math.rad(-3.91)),
	Head = CFrame.new(-0.102, 1.477, -0.112) * CFrame.Angles(math.rad(-16.48), math.rad(15.39), math.rad(12.21)),
}

P.EXEC_AVANCO = { -- [180] arranque
	HRP = CFrame.new(0.112, -0.539, 1.312) * CFrame.Angles(math.rad(-46.14), math.rad(-57.57), math.rad(-31.86)),
	RightArm = CFrame.new(1.35, 0.488, -0.194) * CFrame.Angles(math.rad(102.27), math.rad(20.9), math.rad(5.59)),
	LeftArm = CFrame.new(-1.708, 0.402, -0.657) * CFrame.Angles(math.rad(75.16), math.rad(-24.42), math.rad(-20.3)),
	RightLeg = CFrame.new(0.747, -1.747, -0.442) * CFrame.Angles(math.rad(5.87), math.rad(-24.24), math.rad(16.57)),
	LeftLeg = CFrame.new(-0.899, -1.149, -1.12) * CFrame.Angles(math.rad(39.07), math.rad(15.89), math.rad(-21)),
	Head = CFrame.new(-0.145, 1.478, -0.021) * CFrame.Angles(math.rad(-13.58), math.rad(32.34), math.rad(20.08)),
}

P.EXEC_CORTE1 = { -- [260] primeiro corte (tronco a -147°)
	HRP = CFrame.new(-0.024, -0.822, 1.275) * CFrame.Angles(math.rad(-147.03), math.rad(-50.21), math.rad(-131.38)),
	RightArm = CFrame.new(1.373, 0.272, 0.673) * CFrame.Angles(math.rad(99.93), math.rad(-2.37), math.rad(62.7)),
	LeftArm = CFrame.new(-1.254, 0.531, -0.737) * CFrame.Angles(math.rad(121.9), math.rad(-44.4), math.rad(4.03)),
	RightLeg = CFrame.new(0.653, -1.385, -1.125) * CFrame.Angles(math.rad(34.35), math.rad(-20.96), math.rad(4.44)),
	LeftLeg = CFrame.new(-1.443, -0.935, -0.603) * CFrame.Angles(math.rad(9.38), math.rad(39.82), math.rad(-39.23)),
	Head = CFrame.new(-0.166, 1.47, -0.038) * CFrame.Angles(math.rad(-20.39), math.rad(37.85), math.rad(24.81)),
}

P.EXEC_CORTE2 = { -- [298] segundo corte
	HRP = CFrame.new(0.116, -0.9, 0.666) * CFrame.Angles(math.rad(-75.56), math.rad(-50.75), math.rad(-55.57)),
	RightArm = CFrame.new(1.118, 0.066, 0.519) * CFrame.Angles(math.rad(134.62), math.rad(-19.51), math.rad(70.72)),
	LeftArm = CFrame.new(-1.228, 0.402, -0.595) * CFrame.Angles(math.rad(109.85), math.rad(-5.86), math.rad(33.48)),
	RightLeg = CFrame.new(1.114, -1.901, -0.595) * CFrame.Angles(math.rad(4.43), math.rad(-4.87), math.rad(23.74)),
	LeftLeg = CFrame.new(-0.576, -0.485, -1.173) * CFrame.Angles(math.rad(19.27), math.rad(33.17), math.rad(-5.14)),
	Head = CFrame.new(-0.158, 1.474, -0.007) * CFrame.Angles(math.rad(-6.12), math.rad(15.61), math.rad(19.18)),
}

P.EXEC_FINAL = { -- [349] pose de saída, costas para o alvo
	HRP = CFrame.new(0.128, -0.78, 0.544) * CFrame.Angles(math.rad(-33.55), math.rad(41.54), math.rad(22.64)),
	RightArm = CFrame.new(1.857, 1.006, -0.642) * CFrame.Angles(math.rad(96.52), math.rad(20.99), math.rad(50.91)),
	LeftArm = CFrame.new(-1.127, -0.11, 0.528) * CFrame.Angles(math.rad(143.16), math.rad(41.29), math.rad(-82.69)),
	RightLeg = CFrame.new(0.147, -1.818, 0.438) * CFrame.Angles(math.rad(-45.22), math.rad(-17.42), math.rad(-34.66)),
	LeftLeg = CFrame.new(-0.377, -0.935, -1.284) * CFrame.Angles(math.rad(33.47), math.rad(-20.96), math.rad(-0.25)),
	Head = CFrame.new(0.083, 1.493, 0) * CFrame.Angles(math.rad(-7.04), math.rad(-35.79), math.rad(-11.83)),
}

P.SEQUENCIAS = {

	-- golpe rápido carregado · 1.10s · 5 passo(s), 1 segurado(s)
	ARREMESSO_CARREGADO = {
		{ pose = "ARREMESSO_CARGA", time = 0.24, style = "Back", dir = "In", tremor = 0.035, freq = 26, marca = "CARGA" },
		{ pose = "ARREMESSO_CARGA", time = 0.31, style = "Sine", dir = "InOut", tremor = 0.035, freq = 26 },
		{ pose = "ARREMESSO_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO", time = 0.2, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.27, style = "Quad", dir = "Out" },
	},

	-- combo (35:65) · 1.12s · 8 passo(s), 1 segurado(s)
	CORTE_COMBO = {
		{ pose = "CORTE_A", time = 0.16, style = "Back", dir = "In" },
		{ pose = "CORTE_A", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "CORTE_B", time = 0.08, style = "Quint", dir = "Out", marca = "CORTE1" },
		{ pose = "CORTE_C", time = 0.11, style = "Back", dir = "In" },
		{ pose = "CORTE_D", time = 0.08, style = "Quint", dir = "Out", marca = "CORTE2" },
		{ pose = "CORTE_E", time = 0.11, style = "Back", dir = "In" },
		{ pose = "CORTE_F", time = 0.08, style = "Quint", dir = "Out", marca = "CORTE3" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

	-- ultimate (64–86%) · 5.99s · 12 passo(s), 2 segurado(s)
	EXECUCAO = {
		{ pose = "EXEC_POSTURA", time = 0.6, style = "Back", dir = "In", tremor = 0.02, freq = 18, marca = "POSTURA" },
		{ pose = "EXEC_POSTURA", time = 1.8, style = "Sine", dir = "InOut", tremor = 0.02, freq = 18 },
		{ pose = "EXEC_AVANCO", time = 0.35, style = "Quint", dir = "Out", marca = "TEMPO" },
		{ pose = "EXEC_AVANCO", time = 1.4, style = "Sine", dir = "InOut" },
		{ pose = "EXEC_CORTE1", time = 0.2, style = "Quint", dir = "Out", tremor = 0.05, freq = 30, marca = "GRADE" },
		{ pose = "EXEC_CORTE2", time = 0.12, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE1", time = 0.11, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE2", time = 0.11, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE1", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE2", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_FINAL", time = 0.4, style = "Back", dir = "Out", marca = "MORTAL" },
		{ pose = "IDLE", time = 0.7, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

--══════════════════════════════════════════════════════════════
-- CÂMERA DA CUTSCENE — reescalada por 2.70x junto com a
-- sequência. Esticar a animação e deixar a câmera no tempo
-- antigo dessincroniza os dois.
--══════════════════════════════════════════════════════════════

P.CAMERA_EXECUCAO = {
	{ t = 0.00, cf = CFrame.new(1.042, 1.045, -2.163) * CFrame.Angles(math.rad(-153.67), math.rad(27.45), math.rad(169.74)) },
	{ t = 1.21, cf = CFrame.new(2.081, 1.996, -3.803) * CFrame.Angles(math.rad(-151.14), math.rad(26.83), math.rad(163.80)) },
	{ t = 1.89, cf = CFrame.new(2.792, 2.024, -3.831) * CFrame.Angles(math.rad(-137.97), math.rad(-6.23), math.rad(-159.19)) },
	{ t = 2.56, cf = CFrame.new(-3.658, 3.454, -5.347) * CFrame.Angles(math.rad(-153.86), math.rad(-21.99), math.rad(-158.36)) },
	{ t = 3.37, cf = CFrame.new(2.819, 0.310, -1.877) * CFrame.Angles(math.rad(-152.79), math.rad(27.46), math.rad(165.08)) },
	{ t = 4.18, cf = CFrame.new(3.027, 0.019, -1.065) * CFrame.Angles(math.rad(-151.65), math.rad(40.88), math.rad(155.28)) },
	{ t = 4.99, cf = CFrame.new(3.023, -0.245, 0.322) * CFrame.Angles(math.rad(-130.92), math.rad(67.71), math.rad(123.45)) },
	{ t = 6.21, cf = CFrame.new(1.822, 1.700, 5.456) * CFrame.Angles(math.rad(-6.48), math.rad(2.20), math.rad(3.20)) },
	{ t = 7.82, cf = CFrame.new(1.707, 1.764, 6.039) * CFrame.Angles(math.rad(-1.96), math.rad(2.44), math.rad(3.02)) },
}

return P
