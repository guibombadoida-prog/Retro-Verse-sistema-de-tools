-- Poses.lua
-- ModuleScript "Poses" — Cano De Rua  (conjunto GUEST)
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
--   GOLPE_A      combo          0.50s · 5 passo(s), 2 segurado(s)
--   GOLPE_B      combo          0.50s · 5 passo(s), 2 segurado(s)
--   CONCUSSAO    golpe pesado   1.10s · 5 passo(s), 2 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.BATE_A = {
	RightArm = CFrame.new(1.54, 0.06, -1.14) * CFrame.Angles(math.rad(88), math.rad(-30), math.rad(-16)),
	LeftArm = CFrame.new(-1.4, 0.02, -0.72) * CFrame.Angles(math.rad(44), math.rad(22), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-22), 0),
	HRP = CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(6), math.rad(36), 0),
	RightLeg = CFrame.new(0.5, -1.9, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), 0),
}

P.BATE_B = {
	RightArm = CFrame.new(1.5, -0.16, -1.02) * CFrame.Angles(math.rad(44), math.rad(12), math.rad(8)),
	LeftArm = CFrame.new(-1.46, -0.1, -0.66) * CFrame.Angles(math.rad(34), math.rad(-16), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(12), 0),
	HRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(14), math.rad(-20), 0),
	LeftLeg = CFrame.new(-0.5, -1.86, -0.32) * CFrame.Angles(math.rad(-17), math.rad(0), 0),
}

P.CARGA_A = {
	RightArm = CFrame.new(1.26, 0.7, -0.3) * CFrame.Angles(math.rad(132), math.rad(34), math.rad(26)),
	LeftArm = CFrame.new(-1.44, 0.2, -0.44) * CFrame.Angles(math.rad(52), math.rad(-14), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(30), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-5), math.rad(-40), 0),
}

P.CARGA_B = {
	RightArm = CFrame.new(1.44, 0.74, -0.16) * CFrame.Angles(math.rad(148), math.rad(-22), math.rad(-18)),
	LeftArm = CFrame.new(-1.3, 0.3, -0.4) * CFrame.Angles(math.rad(62), math.rad(18), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-24), 0),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-6), math.rad(36), 0),
}

P.CONC_BATE = {
	RightArm = CFrame.new(1.5, -0.36, -0.88) * CFrame.Angles(math.rad(22), math.rad(-4), math.rad(-8)),
	LeftArm = CFrame.new(-1.5, -0.34, -0.84) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(7)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	HRP = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	RightLeg = CFrame.new(0.58, -1.76, -0.38) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.92, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), 0),
}

P.CONC_CARGA = {
	RightArm = CFrame.new(1.38, 0.86, 0.06) * CFrame.Angles(math.rad(158), math.rad(14), math.rad(20)),
	LeftArm = CFrame.new(-1.38, 0.82, 0.04) * CFrame.Angles(math.rad(154), math.rad(-12), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), 0),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-10), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.02, -0.2) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.5, 0, -0.08) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-10), 0),
}

P.SEQUENCIAS = {

	-- combo · 0.50s · 5 passo(s), 2 segurado(s)
	GOLPE_A = {
		{ pose = "CARGA_A", time = 0.09, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_A", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "BATE_A", time = 0.07, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "BATE_A", time = 0.1, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- combo · 0.50s · 5 passo(s), 2 segurado(s)
	GOLPE_B = {
		{ pose = "CARGA_B", time = 0.09, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_B", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "BATE_B", time = 0.07, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "BATE_B", time = 0.1, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.16, style = "Quad", dir = "Out" },
	},

	-- golpe pesado · 1.10s · 5 passo(s), 2 segurado(s)
	CONCUSSAO = {
		{ pose = "CONC_CARGA", time = 0.26, style = "Back", dir = "In", tremor = 0.025, freq = 19, marca = "ERGUE" },
		{ pose = "CONC_CARGA", time = 0.39, style = "Sine", dir = "InOut", tremor = 0.04, freq = 25, marca = "SEGURA" },
		{ pose = "CONC_BATE", time = 0.11, style = "Quint", dir = "Out", marca = "IMPACTO" },
		{ pose = "CONC_BATE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

}

return P
