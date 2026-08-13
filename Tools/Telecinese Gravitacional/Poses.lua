-- Poses.lua
-- ModuleScript "Poses" — Telecinese Gravitacional  (conjunto GRAVIDADE)
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
--   PUXAO          conjuração pesada  1.20s · 5 passo(s), 2 segurado(s)
--   SINGULARIDADE  sustentada         1.60s · 7 passo(s), 3 segurado(s)
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

P.FECHA = {
	RightArm = CFrame.new(1.5, 0.2, -0.68) * CFrame.Angles(math.rad(66), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.5, 0.16, -0.6) * CFrame.Angles(math.rad(60), math.rad(6), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(0), 0),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(7), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.08, -0.36) * CFrame.Angles(math.rad(32), math.rad(6), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.02, -0.16) * CFrame.Angles(math.rad(14), math.rad(-4), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.PUXA = {
	RightArm = CFrame.new(1.24, 0.42, -0.34) * CFrame.Angles(math.rad(84), math.rad(26), math.rad(34)),
	LeftArm = CFrame.new(-1.24, 0.4, -0.32) * CFrame.Angles(math.rad(82), math.rad(-26), math.rad(-33)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(0), 0),
}

P.SUSTENTA = {
	RightArm = CFrame.new(1.4, 0.7, -0.78) * CFrame.Angles(math.rad(124), math.rad(-14), math.rad(-10)),
	LeftArm = CFrame.new(-1.4, 0.7, -0.78) * CFrame.Angles(math.rad(124), math.rad(14), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-9), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- conjuração pesada · 1.20s · 5 passo(s), 2 segurado(s)
	PUXAO = {
		{ pose = "ABRE_MAO", time = 0.2, style = "Back", dir = "Out", marca = "ALCANCA" },
		{ pose = "ABRE_MAO", time = 0.28, style = "Sine", dir = "InOut" },
		{ pose = "PUXA", time = 0.18, style = "Quint", dir = "Out", marca = "PUXA" },
		{ pose = "PUXA", time = 0.32, style = "Sine", dir = "InOut", tremor = 0.03, freq = 21, marca = "SEGURA" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- sustentada · 1.60s · 7 passo(s), 3 segurado(s)
	SINGULARIDADE = {
		{ pose = "SUSTENTA", time = 0.22, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "PUXA", time = 0.24, style = "Quad", dir = "InOut", marca = "REUNE" },
		{ pose = "PUXA", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.03, freq = 19 },
		{ pose = "PUXA", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.05, freq = 25, marca = "SEGURA" },
		{ pose = "FECHA", time = 0.12, style = "Quint", dir = "Out", marca = "COLAPSA" },
		{ pose = "FECHA", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
