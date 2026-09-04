-- Poses.lua
-- ModuleScript "Poses" — Faker Entity  (conjunto FAKER)
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
--   INVOCA         ultimate         7.10s · 8 passo(s), 4 segurado(s)
--   ENVIA          conjuração       1.30s · 5 passo(s), 2 segurado(s)
--
-- O vocabulário é de MÃO ABERTA, não de punho: CUBO_FORMA, PALMA_DIR,
-- ABRE_BRACOS, FECHA_PUNHOS. Quem bate no conjunto FAKER é o cubo, o poço e
-- a entidade — o portador conjura.
--
-- Gerado por FERRAMENTAS/gerar_poses_faker.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.5, 0.34, -1.18) * CFrame.Angles(math.rad(92), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.26) * CFrame.Angles(math.rad(24), math.rad(6), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-2), math.rad(8), math.rad(0)),
}

P.CHAMA_ENTIDADE = {
	RightArm = CFrame.new(1.5, 0.72, -0.1) * CFrame.Angles(math.rad(150), math.rad(-14), math.rad(-30)),
	LeftArm = CFrame.new(-1.5, 0.72, -0.1) * CFrame.Angles(math.rad(150), math.rad(14), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.CUBO_FORMA = {
	RightArm = CFrame.new(1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(-14), math.rad(-34)),
	LeftArm = CFrame.new(-1.3, 0.22, -0.88) * CFrame.Angles(math.rad(78), math.rad(14), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(-5), math.rad(0), math.rad(0)),
}

P.ENTIDADE_MANDA = {
	RightArm = CFrame.new(1.48, 0.38, -1.2) * CFrame.Angles(math.rad(92), math.rad(-6), math.rad(-6)),
	LeftArm = CFrame.new(-1.48, 0.38, -1.2) * CFrame.Angles(math.rad(92), math.rad(6), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, -0.3) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-4), math.rad(0)),
}

P.SEQUENCIAS = {

	-- ultimate · 7.10s · 8 passo(s), 4 segurado(s)
	INVOCA = {
		{ pose = "CUBO_FORMA", time = 0.45, style = "Back", dir = "In", tremor = 0.02, freq = 16, marca = "CAMERA" },
		{ pose = "CHAMA_ENTIDADE", time = 0.8, style = "Quad", dir = "InOut", tremor = 0.03, freq = 20, marca = "CHAMA" },
		{ pose = "CHAMA_ENTIDADE", time = 1.1, style = "Sine", dir = "InOut", tremor = 0.045, freq = 25, marca = "CARGA" },
		{ pose = "CHAMA_ENTIDADE", time = 1.2, style = "Sine", dir = "InOut", tremor = 0.06, freq = 30 },
		{ pose = "CHAMA_ENTIDADE", time = 1.25, style = "Sine", dir = "InOut", tremor = 0.075, freq = 35, marca = "SEGURA" },
		{ pose = "ENTIDADE_MANDA", time = 0.3, style = "Quint", dir = "Out", marca = "NASCE" },
		{ pose = "ENTIDADE_MANDA", time = 0.85, style = "Sine", dir = "InOut", tremor = 0.05, freq = 27 },
		{ pose = "IDLE", time = 1.15, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.30s · 5 passo(s), 2 segurado(s)
	ENVIA = {
		{ pose = "APONTA", time = 0.22, style = "Back", dir = "In", marca = "MIRA" },
		{ pose = "APONTA", time = 0.32, style = "Sine", dir = "InOut", tremor = 0.035, freq = 22 },
		{ pose = "ENTIDADE_MANDA", time = 0.13, style = "Quint", dir = "Out", marca = "ENVIA" },
		{ pose = "ENTIDADE_MANDA", time = 0.28, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.35, style = "Quad", dir = "Out" },
	},

}

return P
