-- Poses.lua
-- ModuleScript "Poses" — Xester Portal do Cajado  (Xester Forma 2)
--
-- RECRIADA DO ZERO. A Tool já existia com M1 mais uma Extra; agora
-- são QUATRO habilidades, e cada uma tem a própria sequência.
--
-- Forma 2 é O DESPERTAR: cajado, machado e invocação, corpo inteiro
-- — regra 7, e mágico de salão não se debate.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   PORTAL         golpe pesado     1.34s · 4 passo(s)
--   SAIDA          conjuração       1.11s · 4 passo(s)
--   ATRAVESSAR     conjuração       1.11s · 4 passo(s)
--   FECHAR         golpe pesado     1.34s · 4 passo(s)
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

P.CAJADO_CHAO = {
	RightArm = CFrame.new(1.42, -0.34, -0.4) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(22)),
	LeftArm = CFrame.new(-1.4, -0.2, -0.44) * CFrame.Angles(math.rad(34), math.rad(-10), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.44, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.52) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.66, -0.44) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
}

P.CAJADO_ERGUE = {
	RightArm = CFrame.new(1.44, 0.84, -0.04) * CFrame.Angles(math.rad(168), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.RECOLHE = {
	RightArm = CFrame.new(1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(-34), math.rad(-40)),
	LeftArm = CFrame.new(-1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(34), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.SOME = {
	RightArm = CFrame.new(1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(-30), math.rad(-44)),
	LeftArm = CFrame.new(-1.3, 0.2, -0.2) * CFrame.Angles(math.rad(60), math.rad(30), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.34s · 4 passo(s)
	PORTAL = {
		{ pose = "CAJADO_ERGUE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CAJADO_ERGUE", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.05, freq = 24, marca = "SEGURA" },
		{ pose = "CAJADO_APONTA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	SAIDA = {
		{ pose = "CAJADO_APONTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CAJADO_APONTA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "CAJADO_APONTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.11s · 4 passo(s)
	ATRAVESSAR = {
		{ pose = "SOME", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SOME", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.02, freq = 25 },
		{ pose = "SOME", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	FECHAR = {
		{ pose = "RECOLHE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "RECOLHE", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26, marca = "SEGURA" },
		{ pose = "CAJADO_CHAO", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
