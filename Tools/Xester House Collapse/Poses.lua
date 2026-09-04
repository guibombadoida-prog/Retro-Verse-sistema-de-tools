-- Poses.lua
-- ModuleScript "Poses" — Xester House Collapse  (Xester, Forma 1)
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
-- ESTA TOOL TOCA 2 SEQUÊNCIA(S), e só elas estão aqui. O vocabulário
-- completo do Xester é maior; mandar tudo em todas as treze seria asset
-- depositado e mudo em doze delas.
--

-- AS SEQUÊNCIAS
--
--   CASTELO          golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   DESABA           golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


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

P.SEQUENCIAS = {

	-- golpe pesado · 1.34s · 4 passo(s)
	CASTELO = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "SEGURA" },
		{ pose = "EMPILHA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	DESABA = {
		{ pose = "EMPILHA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPILHA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.06, freq = 29, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
