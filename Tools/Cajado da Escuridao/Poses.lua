-- Poses.lua
-- ModuleScript "Poses" — Cajado da Escuridao  (conjunto MARIA)
--
-- ESCRITA, e não extraída — e o motivo importa.
--
-- A origem TEM animação: cada cajado traz `Animation/R6/Main` e
-- `.../Idle`. Mas são instâncias `Animation` com `AnimationId`,
-- tocadas por `LoadAnimation` — proibidas em Tool aqui. E não há
-- `KeyframeSequence` para converter: o conteúdo mora no servidor da
-- Roblox, atrás do id. Não havia o que extrair.
--
-- QUATRO SEQUÊNCIAS: a da origem mais as três Extras.
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   ORBE         conjuração       0.98s · 4 passo(s)
--   ENXAME       conjuração       1.16s · 4 passo(s)
--   CEGUEIRA     golpe pesado     1.22s · 4 passo(s)
--   MANTO        sustentada       1.50s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_maria.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.08, -0.3) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-5), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.22) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.DUAS_MAOS = {
	RightArm = CFrame.new(1.4, 0.66, -0.3) * CFrame.Angles(math.rad(140), math.rad(-12), math.rad(-20)),
	LeftArm = CFrame.new(-1.4, 0.66, -0.3) * CFrame.Angles(math.rad(140), math.rad(12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.16, -0.34) * CFrame.Angles(math.rad(34), math.rad(-6), math.rad(-10)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(16), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.RECOLHE = {
	RightArm = CFrame.new(1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(-34), math.rad(-40)),
	LeftArm = CFrame.new(-1.32, 0.3, -0.36) * CFrame.Angles(math.rad(86), math.rad(34), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.VARRE = {
	RightArm = CFrame.new(1.5, 0.28, -0.9) * CFrame.Angles(math.rad(76), math.rad(-40), math.rad(-14)),
	LeftArm = CFrame.new(-1.42, 0.06, -0.36) * CFrame.Angles(math.rad(30), math.rad(16), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(4), math.rad(44), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.2) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 0.98s · 4 passo(s)
	ORBE = {
		{ pose = "APONTA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.03, freq = 23 },
		{ pose = "APONTA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.16s · 4 passo(s)
	ENXAME = {
		{ pose = "DUAS_MAOS", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "DUAS_MAOS", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.035, freq = 25 },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.22s · 4 passo(s)
	CEGUEIRA = {
		{ pose = "VARRE", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "VARRE", time = 0.48, style = "Sine", dir = "InOut", tremor = 0.04, freq = 26, marca = "SEGURA" },
		{ pose = "VARRE", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.50s · 4 passo(s)
	MANTO = {
		{ pose = "RECOLHE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "RECOLHE", time = 0.68, style = "Sine", dir = "InOut", tremor = 0.03, freq = 18, marca = "SEGURA" },
		{ pose = "RECOLHE", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
