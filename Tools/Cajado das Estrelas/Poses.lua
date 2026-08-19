-- Poses.lua
-- ModuleScript "Poses" — Cajado das Estrelas  (conjunto MARIA)
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
--   ESTRELA      conjuração       1.10s · 4 passo(s)
--   CHUVA        golpe pesado     1.42s · 4 passo(s)
--   CONSTELACAO  sustentada       1.50s · 4 passo(s)
--   GUIA         conjuração       1.12s · 4 passo(s)
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

P.SEQUENCIAS = {

	-- conjuração · 1.10s · 4 passo(s)
	ESTRELA = {
		{ pose = "ERGUE", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ERGUE", time = 0.38, style = "Sine", dir = "InOut", tremor = 0.035, freq = 24 },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.42s · 4 passo(s)
	CHUVA = {
		{ pose = "DUAS_MAOS", time = 0.32, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "DUAS_MAOS", time = 0.58, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26, marca = "SEGURA" },
		{ pose = "ERGUE", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.50s · 4 passo(s)
	CONSTELACAO = {
		{ pose = "ERGUE", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ERGUE", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.03, freq = 20, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.12s · 4 passo(s)
	GUIA = {
		{ pose = "APONTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
