-- Poses_Astral_V1.lua
-- ModuleScript "Poses" — conjunto ASTRAL (Periastron, Nova, Cometa,
-- Singularidade, Constelacao)
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava a
-- caminhada — por isso nenhuma pose daqui deve ser aplicada fora de sequência.
--
-- ORIGEM DAS SILHUETAS (§12.12)
--   O modelo AstralPeriastron trazia 12 `Animation` (R6 e R15). `Animation` é
--   proibida pela REGRA_ANIMACAO_R6: asset de fora, e briga com o script
--   Animate padrão. As silhuetas abaixo são AUTORAIS, escritas em cima da
--   CADÊNCIA das originais — nomes do modelo (Slash, RightSlash, Fire, Smite,
--   Summon) viraram os beats correspondentes. Nada foi copiado; o que veio foi
--   a ideia de tempo: golpe curto, investida com peso, invocação lenta.

local P = {}

--═══════════════════════════════════════════════════════════════
-- 1. BASE
--═══════════════════════════════════════════════════════════════

-- Guarda: lâmina baixa à direita, tronco levemente aberto.
P.IDLE = {
	RightArm = CFrame.new(1.44, 0.18, -0.22) * CFrame.Angles(math.rad(28), math.rad(6), math.rad(9)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(5), 0, math.rad(7)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(-8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-11), 0),
}

--═══════════════════════════════════════════════════════════════
-- 2. GOLPE — cadência do `Slash` / `RightSlash`
--═══════════════════════════════════════════════════════════════

P.GOLPE_CARGA = {
	RightArm = CFrame.new(1.32, 0.62, -0.38) * CFrame.Angles(math.rad(126), math.rad(-14), math.rad(38)),
	LeftArm = CFrame.new(-1.46, 0.12, -0.18) * CFrame.Angles(math.rad(22), math.rad(9), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-9), math.rad(-22), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-34), math.rad(-4)),
}

P.GOLPE_SOLTA = {
	RightArm = CFrame.new(1.52, -0.08, -0.94) * CFrame.Angles(math.rad(72), math.rad(18), math.rad(-46)),
	LeftArm = CFrame.new(-1.41, -0.06, 0.22) * CFrame.Angles(math.rad(-8), math.rad(-12), math.rad(19)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(26), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(38), math.rad(5)),
}

P.GOLPE_RECUO = {
	RightArm = CFrame.new(1.47, 0.06, -0.42) * CFrame.Angles(math.rad(44), math.rad(8), math.rad(-8)),
	LeftArm = CFrame.new(-1.49, 0.02, 0.06) * CFrame.Angles(math.rad(2), 0, math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(9), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(12), 0),
}

--═══════════════════════════════════════════════════════════════
-- 3. INVESTIDA — cadência do `Fire`: peso à frente, perna sob demanda
--═══════════════════════════════════════════════════════════════

P.INVESTIDA_CARGA = {
	RightArm = CFrame.new(1.28, 0.44, -0.66) * CFrame.Angles(math.rad(102), math.rad(-8), math.rad(28)),
	LeftArm = CFrame.new(-1.44, 0.2, -0.3) * CFrame.Angles(math.rad(36), math.rad(14), math.rad(-20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-12), 0),
	HRP = CFrame.new(0, -0.32, 0) * CFrame.Angles(math.rad(-13), math.rad(-20), 0),
	RightLeg = CFrame.new(0.52, -1.86, -0.44) * CFrame.Angles(math.rad(-26), math.rad(-6), math.rad(4)),
	LeftLeg = CFrame.new(-0.54, -1.92, 0.36) * CFrame.Angles(math.rad(19), math.rad(4), math.rad(-3)),
}

P.INVESTIDA_LANCA = {
	RightArm = CFrame.new(1.55, 0.02, -1.22) * CFrame.Angles(math.rad(88), math.rad(4), math.rad(-8)),
	LeftArm = CFrame.new(-1.52, -0.14, 0.34) * CFrame.Angles(math.rad(-22), math.rad(-16), math.rad(24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(9), math.rad(6), 0),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(-22), math.rad(8), 0),
	RightLeg = CFrame.new(0.5, -1.74, 0.62) * CFrame.Angles(math.rad(28), math.rad(2), 0),
	LeftLeg = CFrame.new(-0.52, -1.96, -0.58) * CFrame.Angles(math.rad(-31), math.rad(-3), 0),
}

--═══════════════════════════════════════════════════════════════
-- 4. SEMEAR / APONTAR / DETONAR — os orbes do original
--═══════════════════════════════════════════════════════════════

-- Palma aberta para o lado: o orbe nasce dali.
P.SEMEAR = {
	RightArm = CFrame.new(1.58, 0.34, -0.72) * CFrame.Angles(math.rad(84), math.rad(22), math.rad(-26)),
	LeftArm = CFrame.new(-1.58, 0.28, -0.62) * CFrame.Angles(math.rad(78), math.rad(-18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-11), 0, 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-5), 0, 0),
}

-- Q: braço estendido, dedo apontando o destino dos orbes.
P.APONTAR = {
	RightArm = CFrame.new(1.5, 0.1, -1.16) * CFrame.Angles(math.rad(96), math.rad(2), math.rad(-4)),
	LeftArm = CFrame.new(-1.46, -0.1, 0.18) * CFrame.Angles(math.rad(-14), math.rad(-8), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-7), math.rad(6), 0),
}

-- E: punho fechado que desce — o gesto que estoura os orbes.
P.DETONAR = {
	RightArm = CFrame.new(1.4, -0.22, -0.36) * CFrame.Angles(math.rad(34), math.rad(-6), math.rad(-16)),
	LeftArm = CFrame.new(-1.4, -0.24, -0.34) * CFrame.Angles(math.rad(32), math.rad(6), math.rad(15)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(13), 0, 0),
	HRP = CFrame.new(0, -0.22, 0) * CFrame.Angles(math.rad(11), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 5. INVOCAR — cadência do `Summon` / `Smite`: lento, e para cima
--═══════════════════════════════════════════════════════════════

P.INVOCAR_ERGUE = {
	RightArm = CFrame.new(1.48, 0.78, 0.12) * CFrame.Angles(math.rad(168), math.rad(-6), math.rad(14)),
	LeftArm = CFrame.new(-1.48, 0.74, 0.1) * CFrame.Angles(math.rad(164), math.rad(6), math.rad(-13)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-9), 0, 0),
}

P.INVOCAR_SOLTA = {
	RightArm = CFrame.new(1.56, 0.42, -0.62) * CFrame.Angles(math.rad(112), math.rad(-12), math.rad(-22)),
	LeftArm = CFrame.new(-1.56, 0.38, -0.6) * CFrame.Angles(math.rad(108), math.rad(12), math.rad(21)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(8), 0, 0),
	RightLeg = CFrame.new(0.5, -1.88, -0.22) * CFrame.Angles(math.rad(-13), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.88, -0.2) * CFrame.Angles(math.rad(-12), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 6. NOVA — Astral Nova
--═══════════════════════════════════════════════════════════════

P.NOVA_CARGA = {
	RightArm = CFrame.new(1.36, 0.5, -0.52) * CFrame.Angles(math.rad(118), math.rad(-16), math.rad(30)),
	LeftArm = CFrame.new(-1.36, 0.48, -0.5) * CFrame.Angles(math.rad(116), math.rad(16), math.rad(-29)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), 0, 0),
	HRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(-12), 0, 0),
}

P.NOVA_ESTOURA = {
	RightArm = CFrame.new(1.72, 0.24, -0.96) * CFrame.Angles(math.rad(94), math.rad(30), math.rad(-40)),
	LeftArm = CFrame.new(-1.72, 0.22, -0.94) * CFrame.Angles(math.rad(92), math.rad(-30), math.rad(39)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), 0, 0),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-4), 0, 0),
}

P.COLAPSO_PUXA = {
	RightArm = CFrame.new(1.24, -0.1, -0.5) * CFrame.Angles(math.rad(58), math.rad(-28), math.rad(-34)),
	LeftArm = CFrame.new(-1.24, -0.12, -0.48) * CFrame.Angles(math.rad(56), math.rad(28), math.rad(33)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(17), 0, 0),
	HRP = CFrame.new(0, -0.28, 0) * CFrame.Angles(math.rad(16), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 7. COMETA — Astral Cometa
--═══════════════════════════════════════════════════════════════

P.COMETA_PUXA = {
	RightArm = CFrame.new(1.18, 0.56, 0.42) * CFrame.Angles(math.rad(142), math.rad(-22), math.rad(44)),
	LeftArm = CFrame.new(-1.44, 0.16, -0.28) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(-26), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-38), math.rad(-6)),
}

P.COMETA_LANCA = {
	RightArm = CFrame.new(1.62, 0.04, -1.3) * CFrame.Angles(math.rad(90), math.rad(12), math.rad(-30)),
	LeftArm = CFrame.new(-1.5, -0.12, 0.3) * CFrame.Angles(math.rad(-18), math.rad(-14), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(7), math.rad(20), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-6), math.rad(30), math.rad(4)),
}

P.CHUVA_CHAMA = {
	RightArm = CFrame.new(1.5, 0.82, 0.06) * CFrame.Angles(math.rad(172), math.rad(-4), math.rad(10)),
	LeftArm = CFrame.new(-1.45, 0.1, -0.2) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-36), 0, 0),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-11), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 8. SINGULARIDADE — Astral Singularidade
--═══════════════════════════════════════════════════════════════

P.HORIZONTE_ABRE = {
	RightArm = CFrame.new(1.6, 0.22, -0.86) * CFrame.Angles(math.rad(88), math.rad(26), math.rad(-32)),
	LeftArm = CFrame.new(-1.6, 0.2, -0.84) * CFrame.Angles(math.rad(86), math.rad(-26), math.rad(31)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), 0, 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), 0, 0),
}

P.ESPAGUETE_FECHA = {
	RightArm = CFrame.new(1.1, 0.34, -0.28) * CFrame.Angles(math.rad(74), math.rad(-40), math.rad(-52)),
	LeftArm = CFrame.new(-1.1, 0.32, -0.26) * CFrame.Angles(math.rad(72), math.rad(40), math.rad(51)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-24), 0, 0),
	HRP = CFrame.new(0, -0.36, 0) * CFrame.Angles(math.rad(21), 0, math.rad(9)),
	RightLeg = CFrame.new(0.5, -1.72, -0.5) * CFrame.Angles(math.rad(-30), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.96, 0.42) * CFrame.Angles(math.rad(23), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 9. CONSTELAÇÃO — Astral Constelacao
--═══════════════════════════════════════════════════════════════

P.TRACO_MARCA = {
	RightArm = CFrame.new(1.54, 0.3, -0.9) * CFrame.Angles(math.rad(92), math.rad(16), math.rad(-22)),
	LeftArm = CFrame.new(-1.47, -0.04, 0.1) * CFrame.Angles(math.rad(-9), math.rad(-6), math.rad(13)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-5), math.rad(11), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-4), math.rad(14), 0),
}

P.SENTENCA_FECHA = {
	RightArm = CFrame.new(1.34, 0.66, -0.14) * CFrame.Angles(math.rad(148), math.rad(-10), math.rad(26)),
	LeftArm = CFrame.new(-1.34, 0.64, -0.12) * CFrame.Angles(math.rad(146), math.rad(10), math.rad(-25)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-28), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-13), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- Golpe curto: o beat "SOLTA" é onde a lâmina corta
	GOLPE = {
		{ pose = "GOLPE_CARGA", time = 0.11, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GOLPE_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "CORTA" },
		{ pose = "GOLPE_RECUO", time = 0.14, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.18, style = "Quad", dir = "Out" },
	},

	-- Investida: clique duplo do original, com peso e perna
	INVESTIDA = {
		{ pose = "INVESTIDA_CARGA", time = 0.16, style = "Back", dir = "In", tremor = 0.02, freq = 24, marca = "CARGA" },
		{ pose = "INVESTIDA_LANCA", time = 0.09, style = "Quint", dir = "Out", marca = "LANCA" },
		{ pose = "GOLPE_RECUO", time = 0.2, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

	-- Semear orbes
	SEMEAR = {
		{ pose = "SEMEAR", time = 0.14, style = "Back", dir = "Out", marca = "NASCE" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- Q do original
	APONTAR = {
		{ pose = "APONTAR", time = 0.1, style = "Quint", dir = "Out", marca = "MANDA" },
		{ pose = "IDLE", time = 0.18, style = "Quad", dir = "Out" },
	},

	-- E do original
	DETONAR = {
		{ pose = "DETONAR", time = 0.09, style = "Back", dir = "In", marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- X do original: o Pulsar. Lento de propósito — é a grande.
	INVOCAR = {
		{ pose = "INVOCAR_ERGUE", time = 0.42, style = "Quad", dir = "InOut", tremor = 0.03, freq = 20, marca = "ERGUE" },
		{ pose = "INVOCAR_SOLTA", time = 0.16, style = "Quint", dir = "Out", marca = "NASCE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out" },
	},

	NOVA = {
		{ pose = "NOVA_CARGA", time = 0.2, style = "Back", dir = "In", tremor = 0.025, freq = 22, marca = "CARGA" },
		{ pose = "NOVA_ESTOURA", time = 0.1, style = "Quint", dir = "Out", marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out" },
	},

	COLAPSO = {
		{ pose = "COLAPSO_PUXA", time = 0.24, style = "Quint", dir = "In", tremor = 0.04, freq = 26, marca = "PUXA" },
		{ pose = "NOVA_ESTOURA", time = 0.1, style = "Back", dir = "Out", marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

	COMETA = {
		{ pose = "COMETA_PUXA", time = 0.15, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "COMETA_LANCA", time = 0.08, style = "Quint", dir = "Out", marca = "LANCA" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	CHUVA = {
		{ pose = "CHUVA_CHAMA", time = 0.3, style = "Quad", dir = "InOut", tremor = 0.03, freq = 18, marca = "CHAMA" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},

	HORIZONTE = {
		{ pose = "HORIZONTE_ABRE", time = 0.22, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out" },
	},

	ESPAGUETE = {
		{ pose = "HORIZONTE_ABRE", time = 0.18, style = "Quad", dir = "Out", marca = "MIRA" },
		{ pose = "ESPAGUETE_FECHA", time = 0.14, style = "Quint", dir = "In", tremor = 0.05, freq = 28, marca = "RASGA" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out" },
	},

	TRACO = {
		{ pose = "TRACO_MARCA", time = 0.1, style = "Quint", dir = "Out", marca = "MARCA" },
		{ pose = "IDLE", time = 0.18, style = "Quad", dir = "Out" },
	},

	SENTENCA = {
		{ pose = "SENTENCA_FECHA", time = 0.26, style = "Back", dir = "In", tremor = 0.035, freq = 24, marca = "FECHA" },
		{ pose = "NOVA_ESTOURA", time = 0.1, style = "Quint", dir = "Out", marca = "LIGA" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},
}

return P
