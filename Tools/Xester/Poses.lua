-- Poses.lua
-- ModuleScript "Poses" — Xester  (UMA Tool, DUAS formas)
--
-- 13 habilidades e 3 cutscenes: 24 sequências num arquivo só, porque a Tool
-- troca de forma em jogo e as duas gramáticas de corpo convivem nela.
--
-- FORMA 1, o BARALHO — gesto de mão, carta e leque. O braço direito lidera e
-- o corpo quase não sai do lugar: mágico de salão não se debate.
--
-- FORMA 2, o DRAGÃO — o corpo entra inteiro, o HRP lidera o que é peso, e as
-- pausas são mais longas.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada trava a caminhada.
--
-- AS CUTSCENES SÃO SEQUÊNCIAS COMO AS OUTRAS
--
--   O que muda é que cada passo carrega um BEAT NOMEADO, e é esse nome que
--   chega à câmera. A duração da cutscene É a duração da sequência: quem manda
--   o `FIM` é o fim da animação, não um `task.wait` paralelo que poderia
--   dessincronizar com ela.
--

-- AS SEQUÊNCIAS
--
--   CURTAIN_CALL     conjuração  1.11s · CARGA GOLPE FIM
--   ARSENAL          conjuração  1.11s · CARGA GOLPE FIM
--   DISPARA_NAIPE    golpe rápido 0.83s · CARGA GOLPE FIM
--   LABIRINTO        golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   ACE_GATE         golpe rápido 0.83s · CARGA GOLPE FIM
--   ACE_PORTAO       conjuração  1.11s · CARGA GOLPE FIM
--   CASTELO          golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   DESABA           golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   ECLIPSE          golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   GUARDA_REAL      conjuração  1.11s · CARGA GOLPE FIM
--   REI_LANCA        golpe rápido 0.83s · CARGA GOLPE FIM
--   REI_BAQUE        golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   CARTA_SIMPLES    golpe rápido 0.83s · CARGA GOLPE FIM
--   WYRM             golpe rápido 0.83s · CARGA GOLPE FIM
--   COROA_BRASAS     conjuração  1.11s · CARGA GOLPE FIM
--   BRASAS_CAEM      golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   REQUIEM_CARGA    sustentada  1.52s · CARGA SEGURA GOLPE FIM
--   REQUIEM_SOPRO    golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   PRISMA           sustentada  1.52s · CARGA SEGURA GOLPE FIM
--   PAGINA_FINAL     golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   CHAMA_SIMPLES    golpe rápido 0.83s · CARGA GOLPE FIM
--   TRANSFORMAR      cutscene    3.00s · MAO NAIPES CORINGA CONGELA RASGA TITULO
--   REVERTER         cutscene    1.80s · ABSORVE APAGA FECHA
--   CENA_PAGINA      cutscene    1.80s · PARA RELOGIO QUEBRA VOLTA
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v2.py.

local P = {}


P.ANEL_MAO = {
	RightArm = CFrame.new(1.46, 0.46, -0.86) * CFrame.Angles(math.rad(108), math.rad(-30), math.rad(-14)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.34) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(-4), math.rad(0)),
}

P.APONTA_CEU = {
	RightArm = CFrame.new(1.44, 0.88, 0.06) * CFrame.Angles(math.rad(176), math.rad(-6), math.rad(-10)),
	LeftArm = CFrame.new(-1.46, 0.12, -0.3) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
}

P.ARREMESSA_AS = {
	RightArm = CFrame.new(1.4, 0.5, 0.4) * CFrame.Angles(math.rad(148), math.rad(-18), math.rad(-8)),
	LeftArm = CFrame.new(-1.46, 0.16, -0.42) * CFrame.Angles(math.rad(38), math.rad(14), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(-12), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-20), math.rad(0)),
}

P.ATIRA_CARTA = {
	RightArm = CFrame.new(1.52, 0.3, -1.16) * CFrame.Angles(math.rad(92), math.rad(-12), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, 0.14, -0.4) * CFrame.Angles(math.rad(44), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(18), math.rad(0)),
}

P.CAJADO_CHAO = {
	RightArm = CFrame.new(1.42, -0.34, -0.4) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(22)),
	LeftArm = CFrame.new(-1.4, -0.2, -0.44) * CFrame.Angles(math.rad(34), math.rad(-10), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.44, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.52) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.66, -0.44) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
}

P.CENA_FECHA = {
	RightArm = CFrame.new(1.3, 0.1, -0.44) * CFrame.Angles(math.rad(62), math.rad(-40), math.rad(-48)),
	LeftArm = CFrame.new(-1.3, 0.1, -0.44) * CFrame.Angles(math.rad(62), math.rad(40), math.rad(48)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.CENA_MAO = {
	RightArm = CFrame.new(1.46, 0.42, -0.98) * CFrame.Angles(math.rad(112), math.rad(-18), math.rad(-10)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.32) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(10), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-6), math.rad(-8), math.rad(0)),
}

P.CENA_QUEIMA = {
	RightArm = CFrame.new(1.44, 0.56, -0.9) * CFrame.Angles(math.rad(126), math.rad(-14), math.rad(-12)),
	LeftArm = CFrame.new(-1.4, 0.24, -0.46) * CFrame.Angles(math.rad(52), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-24), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-12), math.rad(-4), math.rad(0)),
}

P.CENA_RASGA = {
	RightArm = CFrame.new(1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(-38), math.rad(-44)),
	LeftArm = CFrame.new(-1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(38), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.24) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.CENA_TITULO = {
	RightArm = CFrame.new(1.58, 0.34, 0.36) * CFrame.Angles(math.rad(24), math.rad(-34), math.rad(-68)),
	LeftArm = CFrame.new(-1.58, 0.34, 0.36) * CFrame.Angles(math.rad(24), math.rad(34), math.rad(68)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
}

P.CERCA = {
	RightArm = CFrame.new(1.46, -0.2, -0.76) * CFrame.Angles(math.rad(44), math.rad(-22), math.rad(-12)),
	LeftArm = CFrame.new(-1.46, -0.2, -0.76) * CFrame.Angles(math.rad(44), math.rad(22), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.22, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.COROA = {
	RightArm = CFrame.new(1.34, 0.86, -0.16) * CFrame.Angles(math.rad(164), math.rad(-22), math.rad(-34)),
	LeftArm = CFrame.new(-1.34, 0.86, -0.16) * CFrame.Angles(math.rad(164), math.rad(22), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
}

P.CORTINA = {
	RightArm = CFrame.new(1.24, 0.18, -0.66) * CFrame.Angles(math.rad(74), math.rad(-52), math.rad(-58)),
	LeftArm = CFrame.new(-1.24, 0.18, -0.66) * CFrame.Angles(math.rad(74), math.rad(52), math.rad(58)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.EMPILHA = {
	RightArm = CFrame.new(1.42, 0.66, -0.5) * CFrame.Angles(math.rad(126), math.rad(-16), math.rad(-20)),
	LeftArm = CFrame.new(-1.42, 0.34, -0.7) * CFrame.Angles(math.rad(92), math.rad(18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.EMPURRA = {
	RightArm = CFrame.new(1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.84, -0.3) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.ENCHE_PEITO = {
	RightArm = CFrame.new(1.36, 0.3, -0.28) * CFrame.Angles(math.rad(78), math.rad(-36), math.rad(-40)),
	LeftArm = CFrame.new(-1.36, 0.3, -0.28) * CFrame.Angles(math.rad(78), math.rad(36), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.2) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.86, -0.24) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.ESTOCA = {
	RightArm = CFrame.new(1.5, 0.24, -1.04) * CFrame.Angles(math.rad(84), math.rad(-14), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, 0.06, -0.3) * CFrame.Angles(math.rad(24), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-10), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(14), math.rad(0)),
}

P.GIRO = {
	RightArm = CFrame.new(1.5, 0.3, -0.94) * CFrame.Angles(math.rad(80), math.rad(-44), math.rad(-16)),
	LeftArm = CFrame.new(-1.5, 0.3, -0.94) * CFrame.Angles(math.rad(80), math.rad(44), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(40), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(5), math.rad(-52), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.LEQUE = {
	RightArm = CFrame.new(1.44, 0.34, -0.62) * CFrame.Angles(math.rad(96), math.rad(-22), math.rad(-18)),
	LeftArm = CFrame.new(-1.4, 0.28, -0.5) * CFrame.Angles(math.rad(82), math.rad(20), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(-6), math.rad(0)),
}

P.PUNHO_FECHA = {
	RightArm = CFrame.new(1.3, 0.44, -0.5) * CFrame.Angles(math.rad(104), math.rad(-40), math.rad(-46)),
	LeftArm = CFrame.new(-1.42, 0.2, -0.44) * CFrame.Angles(math.rad(46), math.rad(18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
}

P.REVELA = {
	RightArm = CFrame.new(1.54, 0.26, 0.28) * CFrame.Angles(math.rad(30), math.rad(-28), math.rad(-62)),
	LeftArm = CFrame.new(-1.54, 0.26, 0.28) * CFrame.Angles(math.rad(30), math.rad(28), math.rad(62)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.SENTINELA = {
	RightArm = CFrame.new(1.5, 0.06, -0.5) * CFrame.Angles(math.rad(46), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, 0.06, -0.5) * CFrame.Angles(math.rad(46), math.rad(10), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.94, -0.14) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.14) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.SOME = {
	RightArm = CFrame.new(1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(-30), math.rad(-44)),
	LeftArm = CFrame.new(-1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(30), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.SOPRA = {
	RightArm = CFrame.new(1.5, 0.16, -1.18) * CFrame.Angles(math.rad(84), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, 0.16, -1.18) * CFrame.Angles(math.rad(84), math.rad(10), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.78, -0.38) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
}

P.TRIANGULO = {
	RightArm = CFrame.new(1.48, 0.58, -0.74) * CFrame.Angles(math.rad(122), math.rad(-26), math.rad(-16)),
	LeftArm = CFrame.new(-1.48, 0.58, -0.74) * CFrame.Angles(math.rad(122), math.rad(26), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.VIRA_PAGINA = {
	RightArm = CFrame.new(1.38, 0.5, -0.34) * CFrame.Angles(math.rad(122), math.rad(-44), math.rad(-52)),
	LeftArm = CFrame.new(-1.44, -0.06, -0.24) * CFrame.Angles(math.rad(18), math.rad(12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(22), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-6), math.rad(-26), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	CURTAIN_CALL = {
		{ pose = "CORTINA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CORTINA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.02, freq = 24 },
		{ pose = "REVELA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	ARSENAL = {
		{ pose = "ANEL_MAO", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ANEL_MAO", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "ANEL_MAO", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	DISPARA_NAIPE = {
		{ pose = "LEQUE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ATIRA_CARTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	LABIRINTO = {
		{ pose = "CERCA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CERCA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.05, freq = 26, marca = "SEGURA" },
		{ pose = "PUNHO_FECHA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	ACE_GATE = {
		{ pose = "ARREMESSA_AS", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ARREMESSA_AS", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ATIRA_CARTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	ACE_PORTAO = {
		{ pose = "SOME", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SOME", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.02, freq = 26 },
		{ pose = "SOME", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	CASTELO = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "SEGURA" },
		{ pose = "EMPILHA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	DESABA = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.06, freq = 29, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	ECLIPSE = {
		{ pose = "APONTA_CEU", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_CEU", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.055, freq = 27, marca = "SEGURA" },
		{ pose = "PUNHO_FECHA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	GUARDA_REAL = {
		{ pose = "SENTINELA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SENTINELA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "SENTINELA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	REI_LANCA = {
		{ pose = "LEQUE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ATIRA_CARTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	REI_BAQUE = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.065, freq = 30, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	CARTA_SIMPLES = {
		{ pose = "LEQUE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ATIRA_CARTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	WYRM = {
		{ pose = "ESTOCA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESTOCA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ESTOCA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESTOCA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	COROA_BRASAS = {
		{ pose = "COROA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "COROA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "COROA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	BRASAS_CAEM = {
		{ pose = "COROA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "COROA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.05, freq = 26, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.52s · 4 passo(s)
	REQUIEM_CARGA = {
		{ pose = "ENCHE_PEITO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ENCHE_PEITO", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.05, freq = 23, marca = "SEGURA" },
		{ pose = "ENCHE_PEITO", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	REQUIEM_SOPRO = {
		{ pose = "ENCHE_PEITO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ENCHE_PEITO", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.06, freq = 28, marca = "SEGURA" },
		{ pose = "SOPRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.52s · 4 passo(s)
	PRISMA = {
		{ pose = "TRIANGULO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "TRIANGULO", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.035, freq = 20, marca = "SEGURA" },
		{ pose = "TRIANGULO", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	PAGINA_FINAL = {
		{ pose = "VIRA_PAGINA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "VIRA_PAGINA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.07, freq = 31, marca = "SEGURA" },
		{ pose = "CAJADO_CHAO", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	CHAMA_SIMPLES = {
		{ pose = "ESTOCA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESTOCA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "GIRO", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "GIRO", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- cutscene · 3.00s · 6 passo(s)
	TRANSFORMAR = {
		{ pose = "CENA_MAO", time = 0.55, style = "Sine", dir = "InOut", marca = "MAO" },
		{ pose = "CENA_MAO", time = 0.45, style = "Sine", dir = "InOut", marca = "NAIPES" },
		{ pose = "CENA_QUEIMA", time = 0.5, style = "Sine", dir = "InOut", marca = "CORINGA" },
		{ pose = "CENA_QUEIMA", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.02, freq = 21, marca = "CONGELA" },
		{ pose = "CENA_RASGA", time = 0.45, style = "Sine", dir = "InOut", marca = "RASGA" },
		{ pose = "CENA_TITULO", time = 0.55, style = "Quad", dir = "Out", marca = "TITULO" },
	},

	-- cutscene · 1.80s · 3 passo(s)
	REVERTER = {
		{ pose = "CENA_RASGA", time = 0.6, style = "Sine", dir = "InOut", marca = "ABSORVE" },
		{ pose = "CENA_FECHA", time = 0.6, style = "Sine", dir = "InOut", marca = "APAGA" },
		{ pose = "IDLE", time = 0.6, style = "Quad", dir = "Out", marca = "FECHA" },
	},

	-- cutscene · 1.80s · 4 passo(s)
	CENA_PAGINA = {
		{ pose = "VIRA_PAGINA", time = 0.45, style = "Sine", dir = "InOut", marca = "PARA" },
		{ pose = "APONTA_CEU", time = 0.45, style = "Sine", dir = "InOut", tremor = 0.02, freq = 21, marca = "RELOGIO" },
		{ pose = "PUNHO_FECHA", time = 0.4, style = "Sine", dir = "InOut", marca = "QUEBRA" },
		{ pose = "CENA_TITULO", time = 0.5, style = "Quad", dir = "Out", marca = "VOLTA" },
	},

}

return P
