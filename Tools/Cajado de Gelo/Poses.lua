-- Poses.lua
-- ModuleScript "Poses" — Cajado de Gelo  (conjunto MARIA)
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
--   CONGELA      conjuração       1.26s · 4 passo(s)
--   PRISAO       golpe pesado     1.28s · 4 passo(s)
--   TRILHA       conjuração       1.06s · 4 passo(s)
--   ESTILHACAR   golpe rápido     0.81s · 4 passo(s)
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

P.VARRE = {
	RightArm = CFrame.new(1.5, 0.28, -0.9) * CFrame.Angles(math.rad(76), math.rad(-40), math.rad(-14)),
	LeftArm = CFrame.new(-1.42, 0.06, -0.36) * CFrame.Angles(math.rad(30), math.rad(16), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(4), math.rad(44), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.2) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.26s · 4 passo(s)
	CONGELA = {
		{ pose = "APONTA", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.48, style = "Sine", dir = "InOut", tremor = 0.025, freq = 19, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.28s · 4 passo(s)
	PRISAO = {
		{ pose = "BATE_CHAO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BATE_CHAO", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.04, freq = 25, marca = "SEGURA" },
		{ pose = "BATE_CHAO", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.06s · 4 passo(s)
	TRILHA = {
		{ pose = "VARRE", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "VARRE", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.03, freq = 23 },
		{ pose = "VARRE", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.81s · 4 passo(s)
	ESTILHACAR = {
		{ pose = "ERGUE", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BATE_CHAO", time = 0.13, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_CHAO", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
