-- Poses.lua
-- ModuleScript "Poses" — Cajado Curador  (conjunto MARIA)
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
--   CURAR        conjuração       1.20s · 4 passo(s)
--   ROUBAR       conjuração       1.14s · 4 passo(s)
--   BENCAO       sustentada       1.48s · 4 passo(s)
--   RESSURGIR    golpe pesado     1.60s · 4 passo(s)
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

P.BATE_CHAO = {
	RightArm = CFrame.new(1.42, -0.34, -0.4) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(22)),
	LeftArm = CFrame.new(-1.4, -0.2, -0.44) * CFrame.Angles(math.rad(34), math.rad(-10), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.44, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.52) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.66, -0.44) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
}

P.DUAS_MAOS = {
	RightArm = CFrame.new(1.4, 0.66, -0.3) * CFrame.Angles(math.rad(140), math.rad(-12), math.rad(-20)),
	LeftArm = CFrame.new(-1.4, 0.66, -0.3) * CFrame.Angles(math.rad(140), math.rad(12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.12) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.ERGUE = {
	RightArm = CFrame.new(1.44, 0.84, -0.04) * CFrame.Angles(math.rad(168), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
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

P.SEQUENCIAS = {

	-- conjuração · 1.20s · 4 passo(s)
	CURAR = {
		{ pose = "APONTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.46, style = "Sine", dir = "InOut", tremor = 0.025, freq = 20, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.14s · 4 passo(s)
	ROUBAR = {
		{ pose = "APONTA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "RECOLHE", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22, marca = "SEGURA" },
		{ pose = "RECOLHE", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.48s · 4 passo(s)
	BENCAO = {
		{ pose = "ERGUE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ERGUE", time = 0.64, style = "Sine", dir = "InOut", tremor = 0.03, freq = 19, marca = "SEGURA" },
		{ pose = "ERGUE", time = 0.2, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.60s · 4 passo(s)
	RESSURGIR = {
		{ pose = "DUAS_MAOS", time = 0.34, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "DUAS_MAOS", time = 0.72, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "SEGURA" },
		{ pose = "BATE_CHAO", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.36, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
