-- Poses.lua
-- ModuleScript "Poses" — Ilusao da Alucinacao  (conjunto FAKER)
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
--   ESPIRAL        conjuração       1.20s · 5 passo(s), 2 segurado(s)
--   TROCA          reação           0.70s · 4 passo(s), 1 segurado(s)
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

P.ESPIRAL_GIRA = {
	RightArm = CFrame.new(1.54, 0.5, -0.36) * CFrame.Angles(math.rad(118), math.rad(-30), math.rad(-28)),
	LeftArm = CFrame.new(-1.4, -0.06, -0.4) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-26), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(22), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-4), math.rad(0)),
}

P.SOME = {
	RightArm = CFrame.new(1.2, 0.06, -0.66) * CFrame.Angles(math.rad(84), math.rad(28), math.rad(52)),
	LeftArm = CFrame.new(-1.2, 0.06, -0.66) * CFrame.Angles(math.rad(84), math.rad(-28), math.rad(-52)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.72, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.44, -0.66) * CFrame.Angles(math.rad(-54), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.5, 0.4) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.20s · 5 passo(s), 2 segurado(s)
	ESPIRAL = {
		{ pose = "ESPIRAL_GIRA", time = 0.2, style = "Back", dir = "In", marca = "GIRA" },
		{ pose = "ESPIRAL_GIRA", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.03, freq = 21 },
		{ pose = "APONTA", time = 0.12, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "APONTA", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.36, style = "Quad", dir = "Out" },
	},

	-- reação · 0.70s · 4 passo(s), 1 segurado(s)
	TROCA = {
		{ pose = "SOME", time = 0.14, style = "Quint", dir = "In", marca = "SOME" },
		{ pose = "SOME", time = 0.22, style = "Sine", dir = "InOut", marca = "TROCA" },
		{ pose = "APONTA", time = 0.12, style = "Back", dir = "Out", marca = "VOLTA" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

}

return P
