-- Poses.lua
-- ModuleScript "Poses" — Lapada Seca  (conjunto REALITY GUI)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- Sequência usa `time` / `style` / `dir` (V2).
--
-- AUTORAL, pela GRAMATICA_R6.md. Nenhum script da origem atravessou a
-- quarentena do `reality_tools.rbxmx` — só geometria, som e malha.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   TAPA         golpe rápido     0.82s · 5 passo(s)
--   TRIPLA       combo            1.00s · 8 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_reality.py.

local P = {}


P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.TAPA_BATE = {
	RightArm = CFrame.new(1.5, 0.16, -1.0) * CFrame.Angles(math.rad(66), math.rad(-34), math.rad(-14)),
	LeftArm = CFrame.new(-1.42, 0.02, -0.4) * CFrame.Angles(math.rad(34), math.rad(16), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(-30), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(5), math.rad(40), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.TAPA_ERGUE = {
	RightArm = CFrame.new(1.42, 0.66, -0.3) * CFrame.Angles(math.rad(138), math.rad(-20), math.rad(-30)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.3) * CFrame.Angles(math.rad(30), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(22), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(-26), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.82s · 5 passo(s)
	TAPA = {
		{ pose = "TAPA_ERGUE", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "TAPA_ERGUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "TAPA_BATE", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "TAPA_BATE", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

	-- combo · 1.00s · 8 passo(s)
	TRIPLA = {
		{ pose = "TAPA_ERGUE", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "TAPA_BATE", time = 0.08, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "TAPA_ERGUE", time = 0.1, style = "Quad", dir = "Out" },
		{ pose = "TAPA_BATE", time = 0.08, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "TAPA_ERGUE", time = 0.1, style = "Quad", dir = "Out" },
		{ pose = "TAPA_BATE", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "TAPA_BATE", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.27, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
