-- Poses.lua
-- ModuleScript "Poses" — Xester Escudo de Cartas  (Xester Forma 1)
--
-- RECRIADA DO ZERO. A Tool já existia com M1 mais uma Extra; agora
-- são QUATRO habilidades, e cada uma tem a própria sequência.
--
-- Forma 1 é o BARALHO: gesto de mão, carta e leque, corpo quase parado
-- — regra 7, e mágico de salão não se debate.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   ESCUDO         conjuração       1.11s · 4 passo(s)
--   REBATER        golpe rápido     0.83s · 5 passo(s)
--   ESTILHACAR     golpe pesado     1.34s · 4 passo(s)
--   BLINDADO       sustentada       1.52s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_novo.py.

local P = {}


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

P.PALMA_ABERTA = {
	RightArm = CFrame.new(1.5, 0.32, -1.08) * CFrame.Angles(math.rad(88), math.rad(-16), math.rad(-8)),
	LeftArm = CFrame.new(-1.5, 0.32, -1.08) * CFrame.Angles(math.rad(88), math.rad(16), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
}

P.RECOLHE = {
	RightArm = CFrame.new(1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(-34), math.rad(-40)),
	LeftArm = CFrame.new(-1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(34), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	ESCUDO = {
		{ pose = "PALMA_ABERTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PALMA_ABERTA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "PALMA_ABERTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	REBATER = {
		{ pose = "LEQUE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "PALMA_ABERTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "PALMA_ABERTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	ESTILHACAR = {
		{ pose = "RECOLHE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "RECOLHE", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26, marca = "SEGURA" },
		{ pose = "PALMA_ABERTA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.52s · 4 passo(s)
	BLINDADO = {
		{ pose = "PALMA_ABERTA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PALMA_ABERTA", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.03, freq = 19, marca = "SEGURA" },
		{ pose = "PALMA_ABERTA", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
