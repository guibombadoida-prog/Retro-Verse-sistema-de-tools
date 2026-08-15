-- Poses.lua
-- ModuleScript "Poses" — Canhao Satelite  (conjunto REALITY GUI)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- Sequência usa `time` / `style` / `dir` (V2).
--
-- AUTORAL, pela GRAMATICA_R6.md. Nenhum script da origem atravessou a
-- quarentena do `reality_tools.rbxmx` — só geometria, som e malha.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   ORBITA       ultimate         7.30s · 9 passo(s)
--   MIRA         conjuração       1.00s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_reality.py.

local P = {}


P.CHAMA_CEU = {
	RightArm = CFrame.new(1.42, 0.84, -0.06) * CFrame.Angles(math.rad(164), math.rad(-10), math.rad(-16)),
	LeftArm = CFrame.new(-1.42, 0.84, -0.06) * CFrame.Angles(math.rad(164), math.rad(10), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.MARCA = {
	RightArm = CFrame.new(1.52, 0.38, -1.2) * CFrame.Angles(math.rad(92), math.rad(-4), math.rad(-3)),
	LeftArm = CFrame.new(-1.44, 0.08, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(8), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.22) * CFrame.Angles(math.rad(-11), math.rad(0), math.rad(0)),
}

P.RECUA = {
	RightArm = CFrame.new(1.3, 0.16, -0.6) * CFrame.Angles(math.rad(74), math.rad(16), math.rad(32)),
	LeftArm = CFrame.new(-1.3, 0.16, -0.6) * CFrame.Angles(math.rad(74), math.rad(-16), math.rad(-32)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- ultimate · 7.30s · 9 passo(s)
	ORBITA = {
		{ pose = "MARCA", time = 0.45, style = "Back", dir = "In", tremor = 0.02, freq = 15, marca = "CAMERA" },
		{ pose = "MARCA", time = 0.9, style = "Sine", dir = "InOut", tremor = 0.03, freq = 20, marca = "MARCA" },
		{ pose = "CHAMA_CEU", time = 0.85, style = "Quad", dir = "InOut", tremor = 0.04, freq = 24, marca = "CARGA" },
		{ pose = "CHAMA_CEU", time = 1.2, style = "Sine", dir = "InOut", tremor = 0.055, freq = 29 },
		{ pose = "CHAMA_CEU", time = 1.25, style = "Sine", dir = "InOut", tremor = 0.07, freq = 34, marca = "SEGURA" },
		{ pose = "RECUA", time = 0.3, style = "Quint", dir = "In", marca = "DESCE" },
		{ pose = "RECUA", time = 0.3, style = "Sine", dir = "InOut", marca = "GOLPE" },
		{ pose = "RECUA", time = 0.85, style = "Sine", dir = "InOut", tremor = 0.06, freq = 31 },
		{ pose = "IDLE", time = 1.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.00s · 4 passo(s)
	MIRA = {
		{ pose = "MARCA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MARCA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.03, freq = 21 },
		{ pose = "MARCA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},

}

return P
