-- Poses_Bombas_V1.lua
-- ModuleScript "Poses" — conjunto BOMBAS
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama ReleaseLegs
-- ao fim de toda sequência. Perna soldada permanentemente trava a caminhada.
--
-- O modelo original não trazia animação nenhuma — nem `Animation`, nem pose.
-- Estas silhuetas são AUTORAIS: arremesso por cima do ombro, que é o gesto que
-- lê como "bomba" e não como "espada".

local P = {}

--═══════════════════════════════════════════════════════════════
-- BASE
--═══════════════════════════════════════════════════════════════

-- Guarda: bomba na mão direita, junto ao corpo.
P.IDLE = {
	RightArm = CFrame.new(1.46, 0.1, -0.28) * CFrame.Angles(math.rad(34), math.rad(4), math.rad(7)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-8), 0),
}

--═══════════════════════════════════════════════════════════════
-- ARREMESSO — por cima do ombro
--═══════════════════════════════════════════════════════════════

-- Braço para trás, tronco carregando o giro.
P.ARREMESSO_CARGA = {
	RightArm = CFrame.new(1.3, 0.68, 0.46) * CFrame.Angles(math.rad(152), math.rad(-16), math.rad(34)),
	LeftArm = CFrame.new(-1.44, 0.14, -0.3) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(-24), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-36), math.rad(-5)),
}

-- Solta: o braço passa a linha do ombro e o tronco vira junto.
P.ARREMESSO_SOLTA = {
	RightArm = CFrame.new(1.58, 0.04, -1.24) * CFrame.Angles(math.rad(84), math.rad(14), math.rad(-34)),
	LeftArm = CFrame.new(-1.5, -0.12, 0.28) * CFrame.Angles(math.rad(-16), math.rad(-14), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(22), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-7), math.rad(32), math.rad(5)),
}

P.ARREMESSO_RECUO = {
	RightArm = CFrame.new(1.48, 0.02, -0.4) * CFrame.Angles(math.rad(44), math.rad(6), math.rad(-8)),
	LeftArm = CFrame.new(-1.49, 0, 0.06) * CFrame.Angles(math.rad(2), 0, math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-1), math.rad(8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(10), 0),
}

--═══════════════════════════════════════════════════════════════
-- CHAMADO — meteoro e nuke: mão para o céu, peso nas pernas
--═══════════════════════════════════════════════════════════════

P.CHAMA_ERGUE = {
	RightArm = CFrame.new(1.5, 0.82, 0.08) * CFrame.Angles(math.rad(172), math.rad(-4), math.rad(11)),
	LeftArm = CFrame.new(-1.5, 0.78, 0.06) * CFrame.Angles(math.rad(168), math.rad(4), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), 0, 0),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-10), 0, 0),
}

P.CHAMA_BAIXA = {
	RightArm = CFrame.new(1.44, -0.16, -0.5) * CFrame.Angles(math.rad(46), math.rad(-8), math.rad(-18)),
	LeftArm = CFrame.new(-1.44, -0.18, -0.48) * CFrame.Angles(math.rad(44), math.rad(8), math.rad(17)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(15), 0, 0),
	HRP = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(14), 0, 0),
	RightLeg = CFrame.new(0.5, -1.8, -0.34) * CFrame.Angles(math.rad(-19), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.8, -0.32) * CFrame.Angles(math.rad(-18), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SOLTAR — bomba doida: as duas mãos abrem para baixo
--═══════════════════════════════════════════════════════════════

P.SOLTAR = {
	RightArm = CFrame.new(1.62, -0.1, -0.62) * CFrame.Angles(math.rad(58), math.rad(26), math.rad(-30)),
	LeftArm = CFrame.new(-1.62, -0.12, -0.6) * CFrame.Angles(math.rad(56), math.rad(-26), math.rad(29)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(11), 0, 0),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(9), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- O arremesso padrão: 4 beats, o segundo é onde a bomba sai
	ARREMESSO = {
		{ pose = "ARREMESSO_CARGA", time = 0.13, style = "Back",  dir = "In",  marca = "CARGA" },
		{ pose = "ARREMESSO_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO", time = 0.15, style = "Quad",  dir = "Out" },
		{ pose = "IDLE",            time = 0.2,  style = "Quad",  dir = "Out" },
	},

	-- Nuke e meteoro: mais lento, com tremor — é o peso da coisa
	CHAMADO = {
		{ pose = "CHAMA_ERGUE", time = 0.4, style = "Quad", dir = "InOut", tremor = 0.03, freq = 20, marca = "ERGUE" },
		{ pose = "CHAMA_BAIXA", time = 0.14, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE",        time = 0.32, style = "Quad", dir = "Out" },
	},

	-- Bomba doida: as duas mãos abrem e soltam os NPCs
	SOLTAR = {
		{ pose = "SOLTAR", time = 0.16, style = "Back",  dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE",   time = 0.24, style = "Quad",  dir = "Out" },
	},
}

return P
