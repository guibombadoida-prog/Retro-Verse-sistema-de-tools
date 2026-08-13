-- Poses.lua
-- ModuleScript "Poses" — Sala Do Abismo  (conjunto FAKER)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada.
--
-- AUTORAL POR INTEIRO. O `faker_tools.rbxmx` tem 796 linhas de habilidade e
-- NENHUMA animação de corpo — nem Animation, nem Motor6D.C0, nem Weld de
-- pose. O personagem dele fica parado enquanto o cubo trabalha.
--
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   FECHA_SALA     transformação    2.00s · 5 passo(s), 2 segurado(s)
--   IMPLODE        golpe pesado     1.40s · 5 passo(s), 2 segurado(s)
--
-- O vocabulário é de MÃO ABERTA, não de punho: CUBO_FORMA, PALMA_DIR,
-- ABRE_BRACOS, FECHA_PUNHOS. Quem bate no conjunto FAKER é o cubo, o poço e
-- a entidade — o portador conjura.
--
-- Gerado por FERRAMENTAS/gerar_poses_faker.py.

local P = {}


P.ABRE_BRACOS = {
	RightArm = CFrame.new(1.58, 0.18, 0.36) * CFrame.Angles(math.rad(-24), math.rad(-12), math.rad(-54)),
	LeftArm = CFrame.new(-1.58, 0.18, 0.36) * CFrame.Angles(math.rad(-24), math.rad(12), math.rad(54)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, 0.18) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.18) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
}

P.CUBO_FORMA = {
	RightArm = CFrame.new(1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(-14), math.rad(-34)),
	LeftArm = CFrame.new(-1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(14), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(-5), math.rad(0), math.rad(0)),
}

P.FECHA_PUNHOS = {
	RightArm = CFrame.new(1.26, 0.12, -0.62) * CFrame.Angles(math.rad(76), math.rad(20), math.rad(40)),
	LeftArm = CFrame.new(-1.26, 0.12, -0.62) * CFrame.Angles(math.rad(76), math.rad(-20), math.rad(-40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-4), math.rad(0)),
}

P.SEQUENCIAS = {

	-- transformação · 2.00s · 5 passo(s), 2 segurado(s)
	FECHA_SALA = {
		{ pose = "ABRE_BRACOS", time = 0.06, style = "Quint", dir = "Out", marca = "FECHA" },
		{ pose = "ABRE_BRACOS", time = 0.72, style = "Sine", dir = "InOut", tremor = 0.025, freq = 17 },
		{ pose = "ABRE_BRACOS", time = 0.76, style = "Sine", dir = "InOut", tremor = 0.035, freq = 23, marca = "SUSTENTA" },
		{ pose = "CUBO_FORMA", time = 0.18, style = "Back", dir = "Out", marca = "RECOLHE" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.40s · 5 passo(s), 2 segurado(s)
	IMPLODE = {
		{ pose = "ABRE_BRACOS", time = 0.26, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ABRE_BRACOS", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.045, freq = 25 },
		{ pose = "FECHA_PUNHOS", time = 0.12, style = "Quint", dir = "Out", marca = "IMPLODE" },
		{ pose = "FECHA_PUNHOS", time = 0.3, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
