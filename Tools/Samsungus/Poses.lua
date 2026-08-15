-- Poses.lua
-- ModuleScript "Poses" — Samsungus  (conjunto REALITY GUI)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- Sequência usa `time` / `style` / `dir` (V2).
--
-- AUTORAL, pela GRAMATICA_R6.md. Nenhum script da origem atravessou a
-- quarentena do `reality_tools.rbxmx` — só geometria, som e malha.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   BATIDA       golpe rápido     0.84s · 5 passo(s)
--   CHAMADA      golpe pesado     1.30s · 5 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_reality.py.

local P = {}


P.BATE_LADO = {
	RightArm = CFrame.new(1.5, 0.28, -1.06) * CFrame.Angles(math.rad(78), math.rad(-30), math.rad(-8)),
	LeftArm = CFrame.new(-1.4, 0.02, -0.38) * CFrame.Angles(math.rad(32), math.rad(14), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(-26), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(5), math.rad(34), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.GIRA_MAO = {
	RightArm = CFrame.new(1.44, 0.34, -0.56) * CFrame.Angles(math.rad(88), math.rad(-26), math.rad(-22)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.26) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(16), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(-18), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.84s · 5 passo(s)
	BATIDA = {
		{ pose = "GIRA_MAO", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GIRA_MAO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "BATE_LADO", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_LADO", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

	-- golpe pesado · 1.30s · 5 passo(s)
	CHAMADA = {
		{ pose = "GIRA_MAO", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GIRA_MAO", time = 0.46, style = "Sine", dir = "InOut", tremor = 0.04, freq = 26, marca = "SEGURA" },
		{ pose = "BATE_LADO", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_LADO", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
