-- Poses.lua
-- ModuleScript "Poses" — Xester Ato de Desaparecer  (Xester Forma 1)
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
--   SUMIR          conjuração       1.11s · 4 passo(s)
--   BARALHAR       conjuração       1.11s · 4 passo(s)
--   BLEFE          conjuração       1.11s · 4 passo(s)
--   FINAL          golpe pesado     1.34s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_novo.py.

local P = {}


P.ATIRA_CARTA = {
	RightArm = CFrame.new(1.52, 0.3, -1.16) * CFrame.Angles(math.rad(92), math.rad(-12), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, 0.14, -0.4) * CFrame.Angles(math.rad(44), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(18), math.rad(0)),
}

P.CARTOLA = {
	RightArm = CFrame.new(1.4, 0.72, -0.24) * CFrame.Angles(math.rad(146), math.rad(-14), math.rad(-22)),
	LeftArm = CFrame.new(-1.46, 0.08, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(8), math.rad(0)),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-10), math.rad(-8), math.rad(0)),
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

P.PALMA_ABERTA = {
	RightArm = CFrame.new(1.5, 0.32, -1.08) * CFrame.Angles(math.rad(88), math.rad(-16), math.rad(-8)),
	LeftArm = CFrame.new(-1.5, 0.32, -1.08) * CFrame.Angles(math.rad(88), math.rad(16), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
}

P.SOME = {
	RightArm = CFrame.new(1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(-30), math.rad(-44)),
	LeftArm = CFrame.new(-1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(30), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.VENIA = {
	RightArm = CFrame.new(1.36, 0.12, -0.42) * CFrame.Angles(math.rad(58), math.rad(-18), math.rad(-30)),
	LeftArm = CFrame.new(-1.34, -0.04, 0.16) * CFrame.Angles(math.rad(10), math.rad(14), math.rad(42)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.26, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	SUMIR = {
		{ pose = "SOME", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SOME", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "SOME", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	BARALHAR = {
		{ pose = "CARTOLA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARTOLA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "PALMA_ABERTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	BLEFE = {
		{ pose = "LEQUE", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	FINAL = {
		{ pose = "VENIA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "VENIA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26, marca = "SEGURA" },
		{ pose = "PALMA_ABERTA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
