-- Poses.lua
-- ModuleScript "Poses" — Jupiter Espada de Pressao  (conjunto JUPITER)
--
-- AUTORAL. O modelo de origem tem 6 `Animation` e 6
-- `LoadAnimation` — asset de animação é proibido (§10), e o que a
-- ficha registra são ids, não CFrame. Não havia pose a extrair.
--
-- A GRAMÁTICA DO CONJUNTO É PESO. Júpiter é o corpo mais pesado do
-- sistema, e as sete são sobre pressão: a `conjuração pesada` leva
-- 1.20 s com o impacto a ~62%, e o atraso É o peso. Só o raio e a
-- espada usam o ritmo rápido.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) ·
--   HRP () · RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim. Perna soldada trava a caminhada.
--
-- JUNTA QUE LIDERA: **HRP** (regra 6).
--
--   GOLPE            conjuração rápida   0.78s · CARGA GOLPE FIM
--   ESTOCADA         conjuração rápida   0.78s · CARGA GOLPE FIM
--   CORTE_GIGANTE    conjuração pesada   1.20s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_jupiter.py.

local P = {}


P.CORTE_LARGO = {
	RightArm = CFrame.new(1.52, 0.32, -0.92) * CFrame.Angles(math.rad(80), math.rad(-48), math.rad(-14)),
	LeftArm = CFrame.new(-1.5, 0.3, -0.9) * CFrame.Angles(math.rad(78), math.rad(46), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(42), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(4), math.rad(-50), math.rad(0)),
}

P.ESPADA_ALTA = {
	RightArm = CFrame.new(1.4, 0.82, -0.08) * CFrame.Angles(math.rad(170), math.rad(-10), math.rad(-18)),
	LeftArm = CFrame.new(-1.4, 0.82, -0.08) * CFrame.Angles(math.rad(170), math.rad(10), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.ESPADA_DESCE = {
	RightArm = CFrame.new(1.44, -0.28, -0.84) * CFrame.Angles(math.rad(18), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, -0.28, -0.84) * CFrame.Angles(math.rad(18), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.44, 0) * CFrame.Angles(math.rad(34), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.56, -0.56) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.56, -0.56) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
}

P.ESTOCA = {
	RightArm = CFrame.new(1.5, 0.2, -1.26) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-2)),
	LeftArm = CFrame.new(-1.4, -0.02, -0.2) * CFrame.Angles(math.rad(14), math.rad(12), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(12), math.rad(10), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.72, -0.5) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.RECOLHE = {
	RightArm = CFrame.new(1.3, 0.28, -0.34) * CFrame.Angles(math.rad(84), math.rad(-36), math.rad(-44)),
	LeftArm = CFrame.new(-1.3, 0.28, -0.34) * CFrame.Angles(math.rad(84), math.rad(36), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(13), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração rápida · 0.78s · 5 passo(s)
	GOLPE = {
		{ pose = "ESPADA_ALTA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESPADA_ALTA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ESPADA_DESCE", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESPADA_DESCE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração rápida · 0.78s · 5 passo(s)
	ESTOCADA = {
		{ pose = "RECOLHE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "RECOLHE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ESTOCA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESTOCA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração pesada · 1.20s · 5 passo(s)
	CORTE_GIGANTE = {
		{ pose = "ESPADA_ALTA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESPADA_ALTA", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.06, freq = 28, marca = "SEGURA" },
		{ pose = "CORTE_LARGO", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CORTE_LARGO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
