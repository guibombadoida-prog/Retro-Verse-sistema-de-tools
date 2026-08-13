-- Poses.lua
-- ModuleScript "Poses" — Taco de Baseball  (conjunto GUEST)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — e é exatamente o bug que o `Taco de Baseball` original tinha:
-- ele soldava as duas pernas no finalizador e o `Unequipped` não as soltava.
--
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   GOLPE_A      combo          0.52s · 5 passo(s), 2 segurado(s)
--   GOLPE_B      combo          0.52s · 5 passo(s), 2 segurado(s)
--   FINALIZADOR  ultimate       1.50s · 6 passo(s), 3 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.BATE_A = {
	RightArm = CFrame.new(1.52, 0.24, -1.12) * CFrame.Angles(math.rad(74), math.rad(-34), math.rad(-12)),
	LeftArm = CFrame.new(-1.34, 0.18, -0.92) * CFrame.Angles(math.rad(66), math.rad(30), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(-26), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(6), math.rad(40), 0),
	RightLeg = CFrame.new(0.5, -1.88, -0.3) * CFrame.Angles(math.rad(-16), math.rad(0), 0),
}

P.BATE_B = {
	RightArm = CFrame.new(1.48, 0.1, -1.06) * CFrame.Angles(math.rad(82), math.rad(38), math.rad(20)),
	LeftArm = CFrame.new(-1.42, 0.06, -0.88) * CFrame.Angles(math.rad(70), math.rad(-32), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(30), 0),
	HRP = CFrame.new(0, -0.08, 0) * CFrame.Angles(math.rad(7), math.rad(-44), 0),
	LeftLeg = CFrame.new(-0.5, -1.88, -0.3) * CFrame.Angles(math.rad(-15), math.rad(0), 0),
}

P.CARGA_A = {
	RightArm = CFrame.new(1.34, 0.62, -0.72) * CFrame.Angles(math.rad(118), math.rad(26), math.rad(30)),
	LeftArm = CFrame.new(-1.28, 0.48, -0.66) * CFrame.Angles(math.rad(104), math.rad(-22), math.rad(-26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(34), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-46), 0),
}

P.CARGA_B = {
	RightArm = CFrame.new(1.3, 0.5, -0.4) * CFrame.Angles(math.rad(96), math.rad(-30), math.rad(-34)),
	LeftArm = CFrame.new(-1.36, 0.56, -0.5) * CFrame.Angles(math.rad(108), math.rad(24), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-30), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(42), 0),
}

P.DESCE = {
	RightArm = CFrame.new(1.5, -0.3, -0.96) * CFrame.Angles(math.rad(30), math.rad(-6), math.rad(-10)),
	LeftArm = CFrame.new(-1.5, -0.28, -0.9) * CFrame.Angles(math.rad(28), math.rad(6), math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), 0),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(22), math.rad(0), 0),
	RightLeg = CFrame.new(0.62, -1.72, -0.42) * CFrame.Angles(math.rad(-26), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
}

P.ERGUE = {
	RightArm = CFrame.new(1.4, 0.9, 0.12) * CFrame.Angles(math.rad(166), math.rad(8), math.rad(16)),
	LeftArm = CFrame.new(-1.4, 0.86, 0.1) * CFrame.Angles(math.rad(162), math.rad(-8), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.34) * CFrame.Angles(math.rad(28), math.rad(6), math.rad(4)),
	LeftArm = CFrame.new(-1.44, 0.02, -0.26) * CFrame.Angles(math.rad(20), math.rad(-6), math.rad(-6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-14), 0),
}

P.SEQUENCIAS = {

	-- combo · 0.52s · 5 passo(s), 2 segurado(s)
	GOLPE_A = {
		{ pose = "CARGA_A", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_A", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "BATE_A", time = 0.07, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "BATE_A", time = 0.11, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- combo · 0.52s · 5 passo(s), 2 segurado(s)
	GOLPE_B = {
		{ pose = "CARGA_B", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_B", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "BATE_B", time = 0.07, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "BATE_B", time = 0.11, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- ultimate · 1.50s · 6 passo(s), 3 segurado(s)
	FINALIZADOR = {
		{ pose = "ERGUE", time = 0.3, style = "Back", dir = "In", tremor = 0.02, freq = 18, marca = "ERGUE" },
		{ pose = "ERGUE", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.035, freq = 22 },
		{ pose = "ERGUE", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.05, freq = 27, marca = "SEGURA" },
		{ pose = "DESCE", time = 0.12, style = "Quint", dir = "Out", marca = "IMPACTO" },
		{ pose = "DESCE", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "SOLTA" },
	},

}

return P
