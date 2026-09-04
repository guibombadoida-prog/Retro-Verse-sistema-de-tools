-- Poses.lua
-- ModuleScript "Poses" — Telecinese Levitacao  (conjunto GRAVIDADE)
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
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   ERGUER         sustentada         1.60s · 6 passo(s), 2 segurado(s)
--   SUBIR          conjuração rápida  0.90s · 3 passo(s), 1 segurado(s)
--   CORRENTE       sustentada         1.60s · 5 passo(s), 2 segurado(s)
--   QUEDA          conjuração pesada  1.20s · 5 passo(s), 2 segurado(s)
--
-- O VOCABULÁRIO É COMPARTILHADO. As sete Tools do conjunto dividem as
-- mesmas poses de base (ABRE_MAO, SUSTENTA, FECHA, PUXA, ESMAGA…) porque
-- têm de LER como o mesmo poder. O que muda entre elas é o que vem depois
-- do gesto, e o tempo de cada passo.
--
-- Gerado por FERRAMENTAS/gerar_poses_gravidade.py.

local P = {}


P.ABRE_MAO = {
	RightArm = CFrame.new(1.44, 0.46, -1.02) * CFrame.Angles(math.rad(94), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, 0.14, -0.4) * CFrame.Angles(math.rad(38), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(-6), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(12), 0),
}

P.ERGUE = {
	RightArm = CFrame.new(1.4, 0.92, 0.14) * CFrame.Angles(math.rad(168), math.rad(8), math.rad(14)),
	LeftArm = CFrame.new(-1.4, 0.88, 0.12) * CFrame.Angles(math.rad(164), math.rad(-8), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), math.rad(0), 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-13), math.rad(0), 0),
}

P.ESMAGA = {
	RightArm = CFrame.new(1.48, -0.42, -0.62) * CFrame.Angles(math.rad(16), math.rad(-6), math.rad(-10)),
	LeftArm = CFrame.new(-1.48, -0.4, -0.6) * CFrame.Angles(math.rad(15), math.rad(6), math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(26), math.rad(0), 0),
	HRP = CFrame.new(0, -0.36, 0) * CFrame.Angles(math.rad(22), math.rad(0), 0),
	RightLeg = CFrame.new(0.56, -1.78, -0.36) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.56, -1.78, -0.36) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
}

P.FECHA = {
	RightArm = CFrame.new(1.5, 0.2, -0.68) * CFrame.Angles(math.rad(66), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.5, 0.16, -0.6) * CFrame.Angles(math.rad(60), math.rad(6), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(0), 0),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(7), math.rad(0), 0),
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

P.SUSTENTA = {
	RightArm = CFrame.new(1.4, 0.7, -0.78) * CFrame.Angles(math.rad(124), math.rad(-14), math.rad(-10)),
	LeftArm = CFrame.new(-1.4, 0.7, -0.78) * CFrame.Angles(math.rad(124), math.rad(14), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-9), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- sustentada · 1.60s · 6 passo(s), 2 segurado(s)
	ERGUER = {
		{ pose = "ABRE_MAO", time = 0.2, style = "Back", dir = "Out", marca = "ALCANCA" },
		{ pose = "SUSTENTA", time = 0.22, style = "Quint", dir = "Out", marca = "ERGUE" },
		{ pose = "SUSTENTA", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.02, freq = 15 },
		{ pose = "SUSTENTA", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.025, freq = 19, marca = "SEGURA" },
		{ pose = "FECHA", time = 0.16, style = "Quad", dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},

	-- conjuração rápida · 0.90s · 3 passo(s), 1 segurado(s)
	SUBIR = {
		{ pose = "FLUTUA", time = 0.24, style = "Back", dir = "Out", marca = "SOBE" },
		{ pose = "FLUTUA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.02, freq = 13 },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "DESCE" },
	},

	-- sustentada · 1.60s · 5 passo(s), 2 segurado(s)
	CORRENTE = {
		{ pose = "ERGUE", time = 0.26, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "SUSTENTA", time = 0.38, style = "Sine", dir = "InOut", tremor = 0.03, freq = 18, marca = "PRENDE" },
		{ pose = "SUSTENTA", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.02, freq = 23 },
		{ pose = "SUSTENTA", time = 0.3, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração pesada · 1.20s · 5 passo(s), 2 segurado(s)
	QUEDA = {
		{ pose = "SUSTENTA", time = 0.24, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "SUSTENTA", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.05, freq = 26, marca = "SEGURA" },
		{ pose = "ESMAGA", time = 0.12, style = "Quint", dir = "Out", marca = "LARGA" },
		{ pose = "ESMAGA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
