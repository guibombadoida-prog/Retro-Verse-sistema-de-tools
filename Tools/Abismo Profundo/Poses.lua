-- Poses.lua
-- ModuleScript "Poses" — Abismo Profundo  (conjunto FAKER)
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
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   ABRE_POCO      golpe pesado     1.50s · 5 passo(s), 2 segurado(s)
--   PUXA           sustentada       1.80s · 6 passo(s), 2 segurado(s)
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

P.BAIXA_SOLO = {
	RightArm = CFrame.new(1.38, -0.34, -0.5) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(22)),
	LeftArm = CFrame.new(-1.38, -0.34, -0.5) * CFrame.Angles(math.rad(34), math.rad(-14), math.rad(-22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.56) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.6, -0.56) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
}

P.CUBO_FORMA = {
	RightArm = CFrame.new(1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(-14), math.rad(-34)),
	LeftArm = CFrame.new(-1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(14), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(-5), math.rad(0), math.rad(0)),
}

P.ERGUE_ALTO = {
	RightArm = CFrame.new(1.4, 0.86, 0.02) * CFrame.Angles(math.rad(168), math.rad(10), math.rad(12)),
	LeftArm = CFrame.new(-1.44, 0.14, -0.34) * CFrame.Angles(math.rad(38), math.rad(-10), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-28), math.rad(12), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(0)),
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

	-- golpe pesado · 1.50s · 5 passo(s), 2 segurado(s)
	ABRE_POCO = {
		{ pose = "ERGUE_ALTO", time = 0.26, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ERGUE_ALTO", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23 },
		{ pose = "BAIXA_SOLO", time = 0.16, style = "Quint", dir = "Out", marca = "ABRE" },
		{ pose = "BAIXA_SOLO", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.05, freq = 28, marca = "SEGURA" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

	-- sustentada · 1.80s · 6 passo(s), 2 segurado(s)
	PUXA = {
		{ pose = "ABRE_BRACOS", time = 0.24, style = "Back", dir = "In", marca = "ABRE" },
		{ pose = "FECHA_PUNHOS", time = 0.16, style = "Quint", dir = "Out", marca = "PUXA" },
		{ pose = "FECHA_PUNHOS", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.04, freq = 26, marca = "SEGURA" },
		{ pose = "FECHA_PUNHOS", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.05, freq = 30, marca = "SEGURA" },
		{ pose = "CUBO_FORMA", time = 0.2, style = "Quad", dir = "InOut", marca = "SOLTA" },
		{ pose = "IDLE", time = 0.36, style = "Quad", dir = "Out" },
	},

}

return P
