-- Poses.lua
-- ModuleScript "Poses" — Asas Telecineticas  (conjunto GRAVIDADE)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência.
--
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   BATIDA         conjuração rápida  0.90s · 5 passo(s), 2 segurado(s)
--   MERGULHO       conjuração pesada  1.20s · 6 passo(s), 2 segurado(s)
--   PLANAR         sustentada         1.60s · 5 passo(s), 2 segurado(s)
--   VENDAVAL       conjuração pesada  1.20s · 5 passo(s), 2 segurado(s)
--
-- O VOCABULÁRIO É COMPARTILHADO. As sete Tools do conjunto dividem as
-- mesmas poses de base (ABRE_MAO, SUSTENTA, FECHA, PUXA, ESMAGA…) porque
-- têm de LER como o mesmo poder. O que muda entre elas é o que vem depois
-- do gesto, e o tempo de cada passo.
--
-- Gerado por FERRAMENTAS/gerar_poses_gravidade.py.

local P = {}


P.ASA_ABRE = {
	RightArm = CFrame.new(1.62, 0.34, 0.42) * CFrame.Angles(math.rad(-22), math.rad(-18), math.rad(-62)),
	LeftArm = CFrame.new(-1.62, 0.34, 0.42) * CFrame.Angles(math.rad(-22), math.rad(18), math.rad(62)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(0), 0),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.84, 0.3) * CFrame.Angles(math.rad(16), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.84, 0.3) * CFrame.Angles(math.rad(16), math.rad(0), 0),
}

P.ASA_BATE = {
	RightArm = CFrame.new(1.3, -0.28, -0.5) * CFrame.Angles(math.rad(40), math.rad(16), math.rad(46)),
	LeftArm = CFrame.new(-1.3, -0.28, -0.5) * CFrame.Angles(math.rad(40), math.rad(-16), math.rad(-46)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(10), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.96, -0.14) * CFrame.Angles(math.rad(-8), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.96, -0.14) * CFrame.Angles(math.rad(-8), math.rad(0), 0),
}

P.BATE_CHAO = {
	RightArm = CFrame.new(1.5, -0.34, -0.9) * CFrame.Angles(math.rad(24), math.rad(-5), math.rad(-9)),
	LeftArm = CFrame.new(-1.5, -0.32, -0.86) * CFrame.Angles(math.rad(22), math.rad(5), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	HRP = CFrame.new(0, -0.38, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	RightLeg = CFrame.new(0.6, -1.74, -0.4) * CFrame.Angles(math.rad(-25), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
}

P.FLUTUA = {
	RightArm = CFrame.new(1.52, 0.18, 0.22) * CFrame.Angles(math.rad(-12), math.rad(-8), math.rad(-22)),
	LeftArm = CFrame.new(-1.52, 0.18, 0.22) * CFrame.Angles(math.rad(-12), math.rad(8), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
	HRP = CFrame.new(0, 0.2, 0) * CFrame.Angles(math.rad(-6), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.82, 0.22) * CFrame.Angles(math.rad(14), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.86, 0.1) * CFrame.Angles(math.rad(8), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.08, -0.36) * CFrame.Angles(math.rad(32), math.rad(6), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.02, -0.16) * CFrame.Angles(math.rad(14), math.rad(-4), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.MERGULHA = {
	RightArm = CFrame.new(1.5, 0.5, 0.5) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(-14)),
	LeftArm = CFrame.new(-1.5, 0.5, 0.5) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(34), math.rad(0), 0),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(46), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.9, 0.34) * CFrame.Angles(math.rad(20), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.34) * CFrame.Angles(math.rad(20), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- conjuração rápida · 0.90s · 5 passo(s), 2 segurado(s)
	BATIDA = {
		{ pose = "ASA_ABRE", time = 0.22, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "ASA_ABRE", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "ASA_BATE", time = 0.12, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "ASA_BATE", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- conjuração pesada · 1.20s · 6 passo(s), 2 segurado(s)
	MERGULHO = {
		{ pose = "ASA_ABRE", time = 0.22, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ASA_ABRE", time = 0.28, style = "Sine", dir = "InOut", marca = "SEGURA" },
		{ pose = "MERGULHA", time = 0.2, style = "Quint", dir = "In", marca = "DESCE" },
		{ pose = "BATE_CHAO", time = 0.12, style = "Quint", dir = "Out", marca = "IMPACTO" },
		{ pose = "BATE_CHAO", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- sustentada · 1.60s · 5 passo(s), 2 segurado(s)
	PLANAR = {
		{ pose = "ASA_ABRE", time = 0.26, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "ASA_ABRE", time = 0.38, style = "Sine", dir = "InOut", tremor = 0.02, freq = 15, marca = "PLANA" },
		{ pose = "FLUTUA", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.02, freq = 19 },
		{ pose = "FLUTUA", time = 0.3, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração pesada · 1.20s · 5 passo(s), 2 segurado(s)
	VENDAVAL = {
		{ pose = "ASA_ABRE", time = 0.24, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ASA_ABRE", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.04, freq = 22, marca = "SEGURA" },
		{ pose = "ASA_BATE", time = 0.12, style = "Quint", dir = "Out", marca = "SOPRA" },
		{ pose = "ASA_BATE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
