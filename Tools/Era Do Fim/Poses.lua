-- Poses.lua
-- ModuleScript "Poses" — Era Do Fim  (conjunto FAKER)
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
--   FIM_DA_ERA     ultimate         7.20s · 9 passo(s), 5 segurado(s)
--   ONDA           golpe pesado     1.60s · 5 passo(s), 2 segurado(s)
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

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-4), math.rad(0)),
}

P.SEQUENCIAS = {

	-- ultimate · 7.20s · 9 passo(s), 5 segurado(s)
	FIM_DA_ERA = {
		{ pose = "CUBO_FORMA", time = 0.5, style = "Back", dir = "In", tremor = 0.02, freq = 15, marca = "CAMERA" },
		{ pose = "ERGUE_ALTO", time = 0.8, style = "Quad", dir = "InOut", tremor = 0.03, freq = 19, marca = "ERGUE" },
		{ pose = "ERGUE_ALTO", time = 1.05, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "CARGA" },
		{ pose = "ERGUE_ALTO", time = 1.15, style = "Sine", dir = "InOut", tremor = 0.06, freq = 29 },
		{ pose = "ERGUE_ALTO", time = 1.2, style = "Sine", dir = "InOut", tremor = 0.08, freq = 34, marca = "SEGURA" },
		{ pose = "BAIXA_SOLO", time = 0.35, style = "Quint", dir = "In", marca = "DESCE" },
		{ pose = "BAIXA_SOLO", time = 0.25, style = "Sine", dir = "InOut", marca = "DETONA" },
		{ pose = "BAIXA_SOLO", time = 0.85, style = "Sine", dir = "InOut", tremor = 0.07, freq = 31 },
		{ pose = "IDLE", time = 1.05, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.60s · 5 passo(s), 2 segurado(s)
	ONDA = {
		{ pose = "ABRE_BRACOS", time = 0.3, style = "Back", dir = "In", marca = "ABRE" },
		{ pose = "ABRE_BRACOS", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.04, freq = 22 },
		{ pose = "BAIXA_SOLO", time = 0.14, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "BAIXA_SOLO", time = 0.3, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.44, style = "Quad", dir = "Out" },
	},

}

return P
