-- Poses_CosmicSword_V1.lua
-- ModuleScript "Poses" — Cosmic Sword Revamp
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada permanentemente trava a
-- caminhada — nenhuma pose daqui deve ser aplicada fora de sequência.
--
--═══════════════════════════════════════════════════════════════
-- DE ONDE VIERAM AS SILHUETAS (§12.12)
--═══════════════════════════════════════════════════════════════
--
--   A Tool de origem trazia SEIS `Animation` numa pasta `Animations/R6`:
--   `Unleash`, `Slam`, `Spin`, `Summon`, `Ground`, `Stab`. `Animation` é
--   proibida pela REGRA_ANIMACAO_R6 — é asset de fora, some se o id sair do
--   ar, e briga com o `Animate` padrão do personagem.
--
--   As silhuetas abaixo são AUTORAIS. O que veio da origem foi a CADÊNCIA que
--   os nomes declaram, e o momento em que cada `LoadAnimation` era chamado no
--   `Server` antigo:
--
--     Spin   + Stab    → `CORTE`      o M1: giro curto e estocada
--     Ground + Slam    → `SUPERNOVA`  o E: firma no chão e desce a lâmina
--     Summon           → `INVOCAR`    o Q: ergue a shuriken do espaço
--     Unleash          → `DOBRAR`     o X: abre a dobra e atravessa
--     Unleash + Slam   → `HAWKING`    a grande: ergue devagar, e solta
--
--   Nada foi copiado; nem havia o que copiar, porque um `Animation` é um id.

local P = {}

--═══════════════════════════════════════════════════════════════
-- 1. BASE — a guarda da espada cósmica
--═══════════════════════════════════════════════════════════════

-- Lâmina baixa à direita, ombro solto, cabeça um grau à frente.
P.IDLE = {
	RightArm = CFrame.new(1.46, 0.14, -0.2) * CFrame.Angles(math.rad(24), math.rad(5), math.rad(8)),
	LeftArm = CFrame.new(-1.5, 0.02, 0.04) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(-7), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-9), 0),
}

--═══════════════════════════════════════════════════════════════
-- 2. CORTE — cadência do `Spin` e do `Stab`
--
-- Três golpes na MESMA entrada continuam sendo UMA habilidade
-- (REGRA_DISTRIBUICAO, "o que conta como habilidade"). O que muda é a pose de
-- ataque, escolhida pelo índice do combo no servidor.
--═══════════════════════════════════════════════════════════════

-- Recuo: o peso volta para o pé de trás antes de qualquer coisa.
P.CORTE_CARGA = {
	RightArm = CFrame.new(1.3, 0.66, -0.34) * CFrame.Angles(math.rad(132), math.rad(-16), math.rad(40)),
	LeftArm = CFrame.new(-1.44, 0.14, -0.2) * CFrame.Angles(math.rad(24), math.rad(10), math.rad(-16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(-24), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-36), math.rad(-4)),
}

-- Corte 1: diagonal de cima à direita para baixo à esquerda.
P.CORTE_DIAGONAL = {
	RightArm = CFrame.new(1.52, -0.1, -0.96) * CFrame.Angles(math.rad(70), math.rad(20), math.rad(-48)),
	LeftArm = CFrame.new(-1.4, -0.08, 0.24) * CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(7), math.rad(28), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(40), math.rad(5)),
}

-- Corte 2: o `Spin` — o tronco gira inteiro e a lâmina vem de fora para dentro.
P.CORTE_GIRO = {
	RightArm = CFrame.new(1.38, 0.3, -1.12) * CFrame.Angles(math.rad(96), math.rad(-28), math.rad(-16)),
	LeftArm = CFrame.new(-1.34, 0.24, -0.5) * CFrame.Angles(math.rad(58), math.rad(22), math.rad(-30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-40), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(0, math.rad(-96), math.rad(-7)),
}

-- Corte 3: o `Stab` — braço estendido, ombro atrás da ponta.
P.CORTE_ESTOCADA = {
	RightArm = CFrame.new(1.5, 0.06, -1.34) * CFrame.Angles(math.rad(88), math.rad(2), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, -0.16, 0.4) * CFrame.Angles(math.rad(-26), math.rad(-18), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(4), 0),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(-18), math.rad(10), 0),
	RightLeg = CFrame.new(0.5, -1.76, 0.58) * CFrame.Angles(math.rad(26), math.rad(2), 0),
	LeftLeg = CFrame.new(-0.54, -1.9, -0.5) * CFrame.Angles(math.rad(-22), math.rad(-3), 0),
}

P.CORTE_RECUO = {
	RightArm = CFrame.new(1.47, 0.08, -0.4) * CFrame.Angles(math.rad(42), math.rad(7), math.rad(-6)),
	LeftArm = CFrame.new(-1.49, 0.02, 0.06) * CFrame.Angles(math.rad(2), 0, math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(11), 0),
}

--═══════════════════════════════════════════════════════════════
-- 3. SUPERNOVA — cadência do `Ground` seguido do `Slam`
--
-- O original carregava as duas em sequência: firma no chão, depois desce. As
-- pernas entram aqui porque o peso é o ponto da pose.
--═══════════════════════════════════════════════════════════════

P.NOVA_FIRMA = {
	RightArm = CFrame.new(1.24, 0.86, -0.5) * CFrame.Angles(math.rad(158), math.rad(-12), math.rad(30)),
	LeftArm = CFrame.new(-1.28, 0.8, -0.44) * CFrame.Angles(math.rad(152), math.rad(14), math.rad(-28)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), 0, 0),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(-8), 0, 0),
	RightLeg = CFrame.new(0.56, -1.82, -0.3) * CFrame.Angles(math.rad(-18), math.rad(-8), math.rad(5)),
	LeftLeg = CFrame.new(-0.58, -1.82, -0.3) * CFrame.Angles(math.rad(-18), math.rad(8), math.rad(-5)),
}

P.NOVA_DESCE = {
	RightArm = CFrame.new(1.4, -0.34, -0.52) * CFrame.Angles(math.rad(18), math.rad(-6), math.rad(14)),
	LeftArm = CFrame.new(-1.42, -0.32, -0.48) * CFrame.Angles(math.rad(16), math.rad(6), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), 0, 0),
	HRP = CFrame.new(0, -0.72, 0) * CFrame.Angles(math.rad(20), 0, 0),
	RightLeg = CFrame.new(0.52, -1.58, 0.2) * CFrame.Angles(math.rad(38), math.rad(-4), 0),
	LeftLeg = CFrame.new(-0.56, -1.6, 0.18) * CFrame.Angles(math.rad(36), math.rad(4), 0),
}

--═══════════════════════════════════════════════════════════════
-- 4. INVOCAR — cadência do `Summon`
--
-- Braço para cima, palma aberta: a shuriken nasce acima da mão.
--═══════════════════════════════════════════════════════════════

P.INVOCAR_ERGUE = {
	RightArm = CFrame.new(1.5, 0.94, 0.06) * CFrame.Angles(math.rad(-166), math.rad(-8), math.rad(10)),
	LeftArm = CFrame.new(-1.46, 0.28, -0.22) * CFrame.Angles(math.rad(46), math.rad(12), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(6), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-6), math.rad(-6), 0),
}

P.INVOCAR_SOLTA = {
	RightArm = CFrame.new(1.52, 0.22, -1.1) * CFrame.Angles(math.rad(84), math.rad(6), math.rad(-14)),
	LeftArm = CFrame.new(-1.5, -0.06, 0.18) * CFrame.Angles(math.rad(-12), math.rad(-10), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(12), 0),
}

--═══════════════════════════════════════════════════════════════
-- 5. DOBRAR — cadência do `Unleash`, na versão curta
--
-- O X do original: a dobra abre à frente e o corpo atravessa. Curta de
-- propósito — teleporte que demora deixa de ser fuga.
--═══════════════════════════════════════════════════════════════

P.DOBRA_ABRE = {
	RightArm = CFrame.new(1.44, 0.5, -0.86) * CFrame.Angles(math.rad(112), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.44, 0.48, -0.84) * CFrame.Angles(math.rad(110), math.rad(10), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-8), 0, 0),
}

P.DOBRA_ATRAVESSA = {
	RightArm = CFrame.new(1.48, -0.12, 0.42) * CFrame.Angles(math.rad(-32), math.rad(-14), math.rad(18)),
	LeftArm = CFrame.new(-1.48, -0.12, 0.42) * CFrame.Angles(math.rad(-32), math.rad(14), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(14), 0, 0),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(16), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- 6. HAWKING — o `Unleash` inteiro, seguido do `Slam`
--
-- É a grande. Lenta de propósito: o tempo da pose é o aviso que o adversário
-- tem de que ela está vindo.
--═══════════════════════════════════════════════════════════════

P.HAWKING_ERGUE = {
	RightArm = CFrame.new(1.52, 1.0, 0.14) * CFrame.Angles(math.rad(-172), math.rad(-6), math.rad(8)),
	LeftArm = CFrame.new(-1.52, 1.0, 0.14) * CFrame.Angles(math.rad(-172), math.rad(6), math.rad(-8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), 0, 0),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-12), 0, 0),
	RightLeg = CFrame.new(0.52, -1.9, -0.18) * CFrame.Angles(math.rad(-10), math.rad(-6), 0),
	LeftLeg = CFrame.new(-0.56, -1.9, -0.18) * CFrame.Angles(math.rad(-10), math.rad(6), 0),
}

P.HAWKING_SOLTA = {
	RightArm = CFrame.new(1.5, 0.16, -1.24) * CFrame.Angles(math.rad(90), math.rad(4), math.rad(-10)),
	LeftArm = CFrame.new(-1.5, 0.16, -1.24) * CFrame.Angles(math.rad(90), math.rad(-4), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), 0, 0),
	HRP = CFrame.new(0, -0.24, 0) * CFrame.Angles(math.rad(14), 0, 0),
	RightLeg = CFrame.new(0.5, -1.66, 0.34) * CFrame.Angles(math.rad(30), 0, 0),
	LeftLeg = CFrame.new(-0.56, -1.78, -0.28) * CFrame.Angles(math.rad(-16), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--
-- Toda `marca` daqui é despachada pelo Server. `TESTES/verificar_beats.py`
-- confere os dois lados: beat despachado que não existe aqui é erro, e
-- keyframe daqui que ninguém despacha é só uma pose sem trabalho — legal.
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- M1, golpe 1 de 3: a diagonal
	CORTE_A = {
		{ pose = "CORTE_CARGA", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CORTE_DIAGONAL", time = 0.08, style = "Quint", dir = "Out", marca = "CORTA" },
		{ pose = "CORTE_RECUO", time = 0.13, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- M1, golpe 2 de 3: o giro do `Spin`
	CORTE_B = {
		{ pose = "CORTE_CARGA", time = 0.09, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CORTE_GIRO", time = 0.1, style = "Quint", dir = "Out", marca = "CORTA" },
		{ pose = "CORTE_RECUO", time = 0.14, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- M1, golpe 3 de 3: a estocada do `Stab`, que empurra
	CORTE_C = {
		{ pose = "CORTE_CARGA", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CORTE_ESTOCADA", time = 0.08, style = "Quint", dir = "Out", tremor = 0.02, freq = 26, marca = "CORTA" },
		{ pose = "CORTE_RECUO", time = 0.18, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- E: `Ground` + `Slam`
	SUPERNOVA = {
		{ pose = "NOVA_FIRMA", time = 0.26, style = "Back", dir = "In", tremor = 0.025, freq = 22, marca = "FIRMA" },
		{ pose = "NOVA_DESCE", time = 0.1, style = "Quint", dir = "Out", tremor = 0.05, freq = 30, marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},

	-- Q: `Summon`
	INVOCAR = {
		{ pose = "INVOCAR_ERGUE", time = 0.22, style = "Quad", dir = "InOut", marca = "NASCE" },
		{ pose = "INVOCAR_SOLTA", time = 0.11, style = "Quint", dir = "Out", marca = "LANCA" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

	-- X: `Unleash` curto
	DOBRAR = {
		{ pose = "DOBRA_ABRE", time = 0.12, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "DOBRA_ATRAVESSA", time = 0.09, style = "Quint", dir = "Out", marca = "ATRAVESSA" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- H: a grande
	HAWKING = {
		{ pose = "HAWKING_ERGUE", time = 0.46, style = "Quad", dir = "InOut", tremor = 0.03, freq = 20, marca = "ERGUE" },
		{ pose = "HAWKING_SOLTA", time = 0.14, style = "Quint", dir = "Out", tremor = 0.06, freq = 32, marca = "SOLTA" },
		{ pose = "IDLE", time = 0.36, style = "Quad", dir = "Out" },
	},
}

return P
