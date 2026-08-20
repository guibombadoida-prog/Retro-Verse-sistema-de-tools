-- Poses.lua
-- ModuleScript "Poses" — Jupiter Queda do Gigante  (conjunto JUPITER)
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
--   INVOCAR          conjuração pesada   1.20s · CARGA SEGURA GOLPE FIM
--   PRESENCA         sustentada          1.60s · CARGA SEGURA GOLPE FIM
--   IMPACTO          conjuração pesada   1.20s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_jupiter.py.

local P = {}


P.CHAMA_CEU = {
	RightArm = CFrame.new(1.44, 0.86, 0.02) * CFrame.Angles(math.rad(172), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-17), math.rad(0), math.rad(0)),
}

P.DERRUBA = {
	RightArm = CFrame.new(1.5, -0.24, -0.9) * CFrame.Angles(math.rad(24), math.rad(-14), math.rad(-8)),
	LeftArm = CFrame.new(-1.5, -0.24, -0.9) * CFrame.Angles(math.rad(24), math.rad(14), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(36), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.52, -0.6) * CFrame.Angles(math.rad(-44), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.52, -0.6) * CFrame.Angles(math.rad(-44), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.2) * CFrame.Angles(math.rad(16), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.SEGURA_PLANETA = {
	RightArm = CFrame.new(1.36, 0.9, -0.12) * CFrame.Angles(math.rad(168), math.rad(-20), math.rad(-30)),
	LeftArm = CFrame.new(-1.36, 0.9, -0.12) * CFrame.Angles(math.rad(168), math.rad(20), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.92, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.92, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração pesada · 1.20s · 5 passo(s)
	INVOCAR = {
		{ pose = "CHAMA_CEU", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHAMA_CEU", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.05, freq = 24, marca = "SEGURA" },
		{ pose = "SEGURA_PLANETA", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "SEGURA_PLANETA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.60s · 5 passo(s)
	PRESENCA = {
		{ pose = "SEGURA_PLANETA", time = 0.28, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "SEGURA_PLANETA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.045, freq = 22, marca = "SEGURA" },
		{ pose = "SEGURA_PLANETA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26 },
		{ pose = "SEGURA_PLANETA", time = 0.28, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração pesada · 1.20s · 5 passo(s)
	IMPACTO = {
		{ pose = "SEGURA_PLANETA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SEGURA_PLANETA", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.08, freq = 33, marca = "SEGURA" },
		{ pose = "DERRUBA", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "DERRUBA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
