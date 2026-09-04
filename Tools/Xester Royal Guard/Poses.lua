-- Poses.lua
-- ModuleScript "Poses" — Xester Royal Guard  (Xester, Forma 1)
--
-- FORMA 1, o BARALHO — gesto de mão, carta e leque. O braço direito
-- lidera e o corpo quase não sai do lugar: mágico de salão não se debate.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada trava a caminhada.
--
-- ESTA TOOL TOCA 3 SEQUÊNCIA(S), e só elas estão aqui. O vocabulário
-- completo do Xester é maior; mandar tudo em todas as treze seria asset
-- depositado e mudo em doze delas.
--

-- AS SEQUÊNCIAS
--
--   GUARDA_REAL      conjuração  1.11s · CARGA GOLPE FIM
--   REI_LANCA        golpe rápido 0.83s · CARGA GOLPE FIM
--   REI_BAQUE        golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.ATIRA_CARTA = {
	RightArm = CFrame.new(1.52, 0.3, -1.16) * CFrame.Angles(math.rad(92), math.rad(-12), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, 0.14, -0.4) * CFrame.Angles(math.rad(44), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(18), math.rad(0)),
}

P.EMPILHA = {
	RightArm = CFrame.new(1.42, 0.66, -0.5) * CFrame.Angles(math.rad(126), math.rad(-16), math.rad(-20)),
	LeftArm = CFrame.new(-1.42, 0.34, -0.7) * CFrame.Angles(math.rad(92), math.rad(18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.EMPURRA = {
	RightArm = CFrame.new(1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.84, -0.3) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.LEQUE = {
	RightArm = CFrame.new(1.44, 0.34, -0.62) * CFrame.Angles(math.rad(96), math.rad(-22), math.rad(-18)),
	LeftArm = CFrame.new(-1.4, 0.28, -0.5) * CFrame.Angles(math.rad(82), math.rad(20), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(-6), math.rad(0)),
}

P.SENTINELA = {
	RightArm = CFrame.new(1.5, 0.06, -0.5) * CFrame.Angles(math.rad(46), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, 0.06, -0.5) * CFrame.Angles(math.rad(46), math.rad(10), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.94, -0.14) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.14) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	GUARDA_REAL = {
		{ pose = "SENTINELA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "SENTINELA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "SENTINELA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 0.83s · 5 passo(s)
	REI_LANCA = {
		{ pose = "LEQUE", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "LEQUE", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "ATIRA_CARTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ATIRA_CARTA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	REI_BAQUE = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.065, freq = 30, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
