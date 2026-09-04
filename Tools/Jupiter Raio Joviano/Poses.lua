-- Poses.lua
-- ModuleScript "Poses" — Jupiter Raio Joviano  (conjunto JUPITER)
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
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   RAIO             conjuração rápida   0.78s · CARGA GOLPE FIM
--   CADEIA           conjuração rápida   0.78s · CARGA GOLPE FIM
--   TORMENTA         conjuração pesada   1.20s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_jupiter.py.

local P = {}


P.ABRE_CAMPO = {
	RightArm = CFrame.new(1.56, 0.3, 0.24) * CFrame.Angles(math.rad(28), math.rad(-30), math.rad(-64)),
	LeftArm = CFrame.new(-1.56, 0.3, 0.24) * CFrame.Angles(math.rad(28), math.rad(30), math.rad(64)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-15), math.rad(0), math.rad(0)),
}

P.APONTA = {
	RightArm = CFrame.new(1.52, 0.28, -1.2) * CFrame.Angles(math.rad(88), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.08, -0.3) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-10), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(14), math.rad(0)),
}

P.CHAMA_CEU = {
	RightArm = CFrame.new(1.44, 0.86, 0.02) * CFrame.Angles(math.rad(172), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-17), math.rad(0), math.rad(0)),
}

P.GIRA = {
	RightArm = CFrame.new(1.46, 0.5, -0.82) * CFrame.Angles(math.rad(116), math.rad(-30), math.rad(-18)),
	LeftArm = CFrame.new(-1.42, 0.16, -0.4) * CFrame.Angles(math.rad(42), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(12), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-8), math.rad(-14), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração rápida · 0.78s · 5 passo(s)
	RAIO = {
		{ pose = "CHAMA_CEU", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHAMA_CEU", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "APONTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "APONTA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração rápida · 0.78s · 5 passo(s)
	CADEIA = {
		{ pose = "APONTA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "GIRA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "GIRA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração pesada · 1.20s · 5 passo(s)
	TORMENTA = {
		{ pose = "CHAMA_CEU", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHAMA_CEU", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.06, freq = 30, marca = "SEGURA" },
		{ pose = "ABRE_CAMPO", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ABRE_CAMPO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
