-- Poses.lua
-- ModuleScript "Poses" — conjunto SUBMUNDO
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
-- ESTAS POSES SÃO AUTORAIS. Não há modelo de origem neste conjunto — os seis
-- conceitos são do autor do projeto. A silhueta é de conjurador com cajado na
-- mão direita, que é o Handle das seis (o `staff` do Xester Forma 2).

local P = {}

--═══════════════════════════════════════════════════════════════
-- BASE
--═══════════════════════════════════════════════════════════════

-- Guarda: cajado plantado ao lado, peso na perna de trás, cabeça baixa.
P.GUARDA = {
	RightArm = CFrame.new(1.52, 0.18, -0.34) * CFrame.Angles(math.rad(38), math.rad(6), math.rad(9)),
	LeftArm = CFrame.new(-1.48, -0.06, 0.12) * CFrame.Angles(math.rad(-8), math.rad(-6), math.rad(-11)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-9), math.rad(-7), 0),
	HRP = CFrame.new(0, -0.08, 0) * CFrame.Angles(math.rad(3), math.rad(-12), 0),
}

--═══════════════════════════════════════════════════════════════
-- ERGUER — o pilar. Cajado sobe e crava no chão.
--═══════════════════════════════════════════════════════════════

P.ERGUER_CARGA = {
	RightArm = CFrame.new(1.42, 0.86, 0.22) * CFrame.Angles(math.rad(158), math.rad(-14), math.rad(22)),
	LeftArm = CFrame.new(-1.46, 0.42, -0.5) * CFrame.Angles(math.rad(62), math.rad(10), math.rad(-16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-28), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-12), 0, 0),
}

P.ERGUER_CRAVA = {
	RightArm = CFrame.new(1.5, -0.22, -0.62) * CFrame.Angles(math.rad(24), math.rad(-6), math.rad(-14)),
	LeftArm = CFrame.new(-1.5, -0.24, -0.58) * CFrame.Angles(math.rad(22), math.rad(6), math.rad(13)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), 0, 0),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(17), 0, 0),
	RightLeg = CFrame.new(0.5, -1.76, -0.38) * CFrame.Angles(math.rad(-22), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.82, 0.26) * CFrame.Angles(math.rad(15), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SELAR — o julgamento. Braço estendido, palma para o alvo.
--═══════════════════════════════════════════════════════════════

P.SELAR_APONTA = {
	RightArm = CFrame.new(1.56, 0.34, -1.32) * CFrame.Angles(math.rad(94), math.rad(8), math.rad(-6)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.22) * CFrame.Angles(math.rad(26), math.rad(-8), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(10), 0),
}

P.SELAR_FECHA = {
	RightArm = CFrame.new(1.5, 0.26, -0.96) * CFrame.Angles(math.rad(76), math.rad(4), math.rad(-2)),
	LeftArm = CFrame.new(-1.46, 0.04, -0.1) * CFrame.Angles(math.rad(12), math.rad(-4), math.rad(-9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(2), 0),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(0, math.rad(5), 0),
}

--═══════════════════════════════════════════════════════════════
-- SOLTAR — a caveira. Mão abre para baixo e larga.
--═══════════════════════════════════════════════════════════════

P.SOLTAR_ABRE = {
	RightArm = CFrame.new(1.64, -0.12, -0.66) * CFrame.Angles(math.rad(56), math.rad(24), math.rad(-28)),
	LeftArm = CFrame.new(-1.62, -0.14, -0.62) * CFrame.Angles(math.rad(54), math.rad(-24), math.rad(27)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(13), 0, 0),
	HRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(10), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- DESFAZER — a perturbação. Corpo abre para trás, braços soltos.
--═══════════════════════════════════════════════════════════════

P.DESFAZER_ABRE = {
	RightArm = CFrame.new(1.7, 0.44, 0.5) * CFrame.Angles(math.rad(-42), math.rad(18), math.rad(34)),
	LeftArm = CFrame.new(-1.7, 0.42, 0.52) * CFrame.Angles(math.rad(-40), math.rad(-18), math.rad(-33)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), 0, 0),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-16), 0, 0),
}

P.DESFAZER_VOLTA = {
	RightArm = CFrame.new(1.54, 0.12, -0.3) * CFrame.Angles(math.rad(30), math.rad(4), math.rad(8)),
	LeftArm = CFrame.new(-1.54, 0.1, -0.28) * CFrame.Angles(math.rad(28), math.rad(-4), math.rad(-7)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), 0, 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(4), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- ABRIR — o portal. Duas mãos descem juntas.
--═══════════════════════════════════════════════════════════════

P.ABRIR_ERGUE = {
	RightArm = CFrame.new(1.46, 0.8, 0.1) * CFrame.Angles(math.rad(168), math.rad(-6), math.rad(12)),
	LeftArm = CFrame.new(-1.46, 0.78, 0.08) * CFrame.Angles(math.rad(166), math.rad(6), math.rad(-11)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-36), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-11), 0, 0),
}

P.ABRIR_DESCE = {
	RightArm = CFrame.new(1.48, -0.3, -0.72) * CFrame.Angles(math.rad(18), math.rad(-10), math.rad(-20)),
	LeftArm = CFrame.new(-1.48, -0.32, -0.7) * CFrame.Angles(math.rad(16), math.rad(10), math.rad(19)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), 0, 0),
	HRP = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(20), 0, 0),
	RightLeg = CFrame.new(0.5, -1.7, -0.42) * CFrame.Angles(math.rad(-25), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.7, -0.4) * CFrame.Angles(math.rad(-24), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- APONTAR — o olho. Cajado ao alto, cabeça atrás dele.
--═══════════════════════════════════════════════════════════════

P.APONTAR_SOBE = {
	RightArm = CFrame.new(1.38, 0.92, 0.06) * CFrame.Angles(math.rad(176), math.rad(-8), math.rad(16)),
	LeftArm = CFrame.new(-1.5, -0.02, 0.08) * CFrame.Angles(math.rad(-6), math.rad(-4), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-40), math.rad(6), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	ERGUER = {
		{ pose = "ERGUER_CARGA", time = 0.34, style = "Back", dir = "Out", tremor = 0.03, freq = 22, marca = "CARGA" },
		{ pose = "ERGUER_CRAVA", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.3, style = "Quad", dir = "Out" },
	},

	SELAR = {
		{ pose = "SELAR_APONTA", time = 0.22, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "SELAR_FECHA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.26, style = "Quad", dir = "Out" },
	},

	SOLTAR = {
		{ pose = "SOLTAR_ABRE", time = 0.18, style = "Back", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.24, style = "Quad", dir = "Out" },
	},

	DESFAZER = {
		{ pose = "DESFAZER_ABRE", time = 0.28, style = "Quint", dir = "Out", marca = "CARGA" },
		{ pose = "DESFAZER_VOLTA", time = 0.2, style = "Quad", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.26, style = "Quad", dir = "Out" },
	},

	ABRIR = {
		{ pose = "ABRIR_ERGUE", time = 0.32, style = "Quad", dir = "InOut", tremor = 0.025, freq = 18, marca = "CARGA" },
		{ pose = "ABRIR_DESCE", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.3, style = "Quad", dir = "Out" },
	},

	APONTAR = {
		{ pose = "APONTAR_SOBE", time = 0.3, style = "Back", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA", time = 0.28, style = "Quad", dir = "Out" },
	},
}

return P
