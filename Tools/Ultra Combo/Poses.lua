-- Poses.lua
-- ModuleScript "Poses" — Ultra Combo  (conjunto FAKER)
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
--   COMBO_1        combo            0.62s · 5 passo(s), 2 segurado(s)
--   COMBO_2        combo            0.42s · 3 passo(s), 1 segurado(s)
--   COMBO_3        combo            0.44s · 3 passo(s), 1 segurado(s)
--   COMBO_4        combo            0.75s · 4 passo(s), 1 segurado(s)
--   SELO           golpe pesado     1.30s · 5 passo(s), 2 segurado(s)
--
-- O vocabulário é de MÃO ABERTA, não de punho: CUBO_FORMA, PALMA_DIR,
-- ABRE_BRACOS, FECHA_PUNHOS. Quem bate no conjunto FAKER é o cubo, o poço e
-- a entidade — o portador conjura.
--
-- Gerado por FERRAMENTAS/gerar_poses_faker.py.

local P = {}


P.BAIXA_SOLO = {
	RightArm = CFrame.new(1.38, -0.34, -0.5) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(22)),
	LeftArm = CFrame.new(-1.38, -0.34, -0.5) * CFrame.Angles(math.rad(34), math.rad(-14), math.rad(-22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.56) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.6, -0.56) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
}

P.COTOVELO = {
	RightArm = CFrame.new(1.22, 0.4, -0.5) * CFrame.Angles(math.rad(108), math.rad(-34), math.rad(-46)),
	LeftArm = CFrame.new(-1.34, 0.26, -0.5) * CFrame.Angles(math.rad(70), math.rad(18), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-20), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-2), math.rad(30), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), math.rad(0)),
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

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-4), math.rad(0)),
}

P.PALMA_DIR = {
	RightArm = CFrame.new(1.52, 0.36, -1.24) * CFrame.Angles(math.rad(94), math.rad(-6), math.rad(-3)),
	LeftArm = CFrame.new(-1.28, 0.3, -0.6) * CFrame.Angles(math.rad(84), math.rad(16), math.rad(28)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-12), math.rad(0)),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(2), math.rad(22), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.22) * CFrame.Angles(math.rad(-11), math.rad(0), math.rad(0)),
}

P.PALMA_ESQ = {
	RightArm = CFrame.new(1.28, 0.3, -0.6) * CFrame.Angles(math.rad(84), math.rad(-16), math.rad(-28)),
	LeftArm = CFrame.new(-1.52, 0.36, -1.24) * CFrame.Angles(math.rad(94), math.rad(6), math.rad(3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(12), math.rad(0)),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(2), math.rad(-22), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, -0.22) * CFrame.Angles(math.rad(-11), math.rad(0), math.rad(0)),
}

P.ROTACAO = {
	RightArm = CFrame.new(1.58, 0.14, 0.2) * CFrame.Angles(math.rad(-8), math.rad(-16), math.rad(-62)),
	LeftArm = CFrame.new(-1.58, 0.14, 0.2) * CFrame.Angles(math.rad(-8), math.rad(16), math.rad(62)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(4), math.rad(165), math.rad(0)),
	RightLeg = CFrame.new(0.56, -1.8, -0.44) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(-8)),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.12) * CFrame.Angles(math.rad(7), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- combo · 0.62s · 5 passo(s), 2 segurado(s)
	COMBO_1 = {
		{ pose = "CUBO_FORMA", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CUBO_FORMA", time = 0.06, style = "Sine", dir = "InOut" },
		{ pose = "PALMA_DIR", time = 0.07, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "PALMA_DIR", time = 0.13, style = "Sine", dir = "InOut" },
		{ pose = "CUBO_FORMA", time = 0.26, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.42s · 3 passo(s), 1 segurado(s)
	COMBO_2 = {
		{ pose = "PALMA_ESQ", time = 0.08, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "PALMA_ESQ", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "CUBO_FORMA", time = 0.22, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.44s · 3 passo(s), 1 segurado(s)
	COMBO_3 = {
		{ pose = "COTOVELO", time = 0.09, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "COTOVELO", time = 0.13, style = "Sine", dir = "InOut" },
		{ pose = "CUBO_FORMA", time = 0.22, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.75s · 4 passo(s), 1 segurado(s)
	COMBO_4 = {
		{ pose = "CUBO_FORMA", time = 0.12, style = "Back", dir = "In" },
		{ pose = "ROTACAO", time = 0.11, style = "Quint", dir = "Out", marca = "BATE_FORTE" },
		{ pose = "ROTACAO", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.30s · 5 passo(s), 2 segurado(s)
	SELO = {
		{ pose = "ERGUE_ALTO", time = 0.24, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "ERGUE_ALTO", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23, marca = "SEGURA" },
		{ pose = "BAIXA_SOLO", time = 0.13, style = "Quint", dir = "Out", marca = "FECHA" },
		{ pose = "BAIXA_SOLO", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.25, style = "Quad", dir = "Out" },
	},

}

return P
