-- Poses.lua
-- ModuleScript "Poses" — Xester Furia do Machado  (Xester Forma 2)
--
-- RECRIADA DO ZERO. A Tool já existia com M1 mais uma Extra; agora
-- são QUATRO habilidades, e cada uma tem a própria sequência.
--
-- Forma 2 é O DESPERTAR: cajado, machado e invocação, corpo inteiro
-- — regra 7, e mágico de salão não se debate.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **HRP** (regra 6).
--
--   MACHADO        golpe rápido     0.83s · 5 passo(s)
--   ARREMESSO      conjuração       1.11s · 4 passo(s)
--   REDEMOINHO     golpe pesado     1.34s · 4 passo(s)
--   DECAPITAR      golpe pesado     1.34s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_novo.py.

local P = {}


P.CAJADO_APONTA = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.08, -0.3) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-5), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.22) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
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

P.MACHADO_ALTO = {
	RightArm = CFrame.new(1.4, 0.8, -0.1) * CFrame.Angles(math.rad(172), math.rad(-10), math.rad(-18)),
	LeftArm = CFrame.new(-1.4, 0.8, -0.1) * CFrame.Angles(math.rad(172), math.rad(10), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-19), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.MACHADO_DESCE = {
	RightArm = CFrame.new(1.44, -0.3, -0.82) * CFrame.Angles(math.rad(20), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, -0.3, -0.82) * CFrame.Angles(math.rad(20), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(28), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.42, 0) * CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.58, -0.54) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.58, -0.54) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.83s · 5 passo(s)
	MACHADO = {
		{ pose = "MACHADO_ALTO", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MACHADO_ALTO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "MACHADO_DESCE", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "MACHADO_DESCE", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	ARREMESSO = {
		{ pose = "MACHADO_ALTO", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MACHADO_ALTO", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "CAJADO_APONTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	REDEMOINHO = {
		{ pose = "GIRO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GIRO", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.055, freq = 27, marca = "SEGURA" },
		{ pose = "GIRO", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	DECAPITAR = {
		{ pose = "MACHADO_ALTO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MACHADO_ALTO", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.065, freq = 30, marca = "SEGURA" },
		{ pose = "MACHADO_DESCE", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
