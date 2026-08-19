-- Poses.lua
-- ModuleScript "Poses" — Cajado Relampago  (conjunto MARIA)
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
--   RAIOS        golpe pesado     1.28s · 4 passo(s)
--   TEMPESTADE   canalizada       3.59s · 5 passo(s)
--   CORRENTE     golpe rápido     0.72s · 4 passo(s)
--   PARARAIOS    conjuração       1.14s · 4 passo(s)
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

	-- golpe pesado · 1.28s · 4 passo(s)
	RAIOS = {
		{ pose = "ERGUE", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ERGUE", time = 0.52, style = "Sine", dir = "InOut", tremor = 0.05, freq = 30, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- canalizada · 3.59s · 5 passo(s)
	TEMPESTADE = {
		{ pose = "ERGUE", time = 0.55, style = "Back", dir = "In", tremor = 0.035, freq = 20, marca = "CARGA" },
		{ pose = "ERGUE", time = 1.0, style = "Sine", dir = "InOut", tremor = 0.055, freq = 26 },
		{ pose = "DUAS_MAOS", time = 1.2, style = "Sine", dir = "InOut", tremor = 0.075, freq = 32, marca = "SEGURA" },
		{ pose = "ERGUE", time = 0.24, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.6, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.72s · 4 passo(s)
	CORRENTE = {
		{ pose = "APONTA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
		{ pose = "IDLE", time = 0.1, style = "Sine", dir = "InOut" },
	},

	-- conjuração · 1.14s · 4 passo(s)
	PARARAIOS = {
		{ pose = "APONTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
