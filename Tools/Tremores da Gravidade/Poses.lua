-- Poses.lua
-- ModuleScript "Poses" — Tremores da Gravidade  (conjunto GRAVIDADE)
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
--   TREMOR         conjuração rápida  0.90s · 5 passo(s), 2 segurado(s)
--   SUSTENTO       sustentada         1.60s · 5 passo(s), 3 segurado(s)
--   FALHA          conjuração rápida  0.90s · 5 passo(s), 2 segurado(s)
--   REPLICA        sustentada         1.60s · 5 passo(s), 2 segurado(s)
--
-- O VOCABULÁRIO É COMPARTILHADO. As sete Tools do conjunto dividem as
-- mesmas poses de base (ABRE_MAO, SUSTENTA, FECHA, PUXA, ESMAGA…) porque
-- têm de LER como o mesmo poder. O que muda entre elas é o que vem depois
-- do gesto, e o tempo de cada passo.
--
-- Gerado por FERRAMENTAS/gerar_poses_gravidade.py.

local P = {}


P.BATE_CHAO = {
	RightArm = CFrame.new(1.5, -0.34, -0.9) * CFrame.Angles(math.rad(24), math.rad(-5), math.rad(-9)),
	LeftArm = CFrame.new(-1.5, -0.32, -0.86) * CFrame.Angles(math.rad(22), math.rad(5), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	HRP = CFrame.new(0, -0.38, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	RightLeg = CFrame.new(0.6, -1.74, -0.4) * CFrame.Angles(math.rad(-25), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
}

P.ERGUE = {
	RightArm = CFrame.new(1.4, 0.92, 0.14) * CFrame.Angles(math.rad(168), math.rad(8), math.rad(14)),
	LeftArm = CFrame.new(-1.4, 0.88, 0.12) * CFrame.Angles(math.rad(164), math.rad(-8), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), math.rad(0), 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-13), math.rad(0), 0),
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

	-- conjuração rápida · 0.90s · 5 passo(s), 2 segurado(s)
	TREMOR = {
		{ pose = "ERGUE", time = 0.2, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ERGUE", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.03, freq = 21 },
		{ pose = "BATE_CHAO", time = 0.1, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "BATE_CHAO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- sustentada · 1.60s · 5 passo(s), 3 segurado(s)
	SUSTENTO = {
		{ pose = "SUSTENTA", time = 0.24, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "SUSTENTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.04, freq = 18, marca = "PULSO" },
		{ pose = "SUSTENTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.05, freq = 24, marca = "PULSO" },
		{ pose = "SUSTENTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.06, freq = 29, marca = "PULSO" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração rápida · 0.90s · 5 passo(s), 2 segurado(s)
	FALHA = {
		{ pose = "ERGUE", time = 0.2, style = "Back", dir = "In", marca = "ABRE" },
		{ pose = "ERGUE", time = 0.24, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "BATE_CHAO", time = 0.12, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "BATE_CHAO", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.60s · 5 passo(s), 2 segurado(s)
	REPLICA = {
		{ pose = "SUSTENTA", time = 0.24, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "SUSTENTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.04, freq = 19, marca = "ANEL" },
		{ pose = "SUSTENTA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.05, freq = 25, marca = "ANEL" },
		{ pose = "BATE_CHAO", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.06, freq = 30, marca = "ANEL" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
