-- Poses.lua
-- ModuleScript "Poses" — Xester Eclipse Deck  (Xester, Forma 1)
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
--   ECLIPSE          golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--   TRANSFORMAR      cutscene    3.00s · MAO NAIPES CORINGA CONGELA RASGA TITULO
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.APONTA_CEU = {
	RightArm = CFrame.new(1.44, 0.88, 0.06) * CFrame.Angles(math.rad(176), math.rad(-6), math.rad(-10)),
	LeftArm = CFrame.new(-1.46, 0.12, -0.3) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
}

P.CENA_MAO = {
	RightArm = CFrame.new(1.46, 0.42, -0.98) * CFrame.Angles(math.rad(112), math.rad(-18), math.rad(-10)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.32) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(10), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-6), math.rad(-8), math.rad(0)),
}

P.CENA_QUEIMA = {
	RightArm = CFrame.new(1.44, 0.56, -0.9) * CFrame.Angles(math.rad(126), math.rad(-14), math.rad(-12)),
	LeftArm = CFrame.new(-1.4, 0.24, -0.46) * CFrame.Angles(math.rad(52), math.rad(16), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-24), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-12), math.rad(-4), math.rad(0)),
}

P.CENA_RASGA = {
	RightArm = CFrame.new(1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(-38), math.rad(-44)),
	LeftArm = CFrame.new(-1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(38), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.24) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.CENA_TITULO = {
	RightArm = CFrame.new(1.58, 0.34, 0.36) * CFrame.Angles(math.rad(24), math.rad(-34), math.rad(-68)),
	LeftArm = CFrame.new(-1.58, 0.34, 0.36) * CFrame.Angles(math.rad(24), math.rad(34), math.rad(68)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PUNHO_FECHA = {
	RightArm = CFrame.new(1.3, 0.44, -0.5) * CFrame.Angles(math.rad(104), math.rad(-40), math.rad(-46)),
	LeftArm = CFrame.new(-1.42, 0.2, -0.44) * CFrame.Angles(math.rad(46), math.rad(18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.34s · 4 passo(s)
	ECLIPSE = {
		{ pose = "APONTA_CEU", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_CEU", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.055, freq = 27, marca = "SEGURA" },
		{ pose = "PUNHO_FECHA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- cutscene · 3.00s · 6 passo(s)
	TRANSFORMAR = {
		{ pose = "CENA_MAO", time = 0.55, style = "Sine", dir = "InOut", marca = "MAO" },
		{ pose = "CENA_MAO", time = 0.45, style = "Sine", dir = "InOut", marca = "NAIPES" },
		{ pose = "CENA_QUEIMA", time = 0.5, style = "Sine", dir = "InOut", marca = "CORINGA" },
		{ pose = "CENA_QUEIMA", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.02, freq = 21, marca = "CONGELA" },
		{ pose = "CENA_RASGA", time = 0.45, style = "Sine", dir = "InOut", marca = "RASGA" },
		{ pose = "CENA_TITULO", time = 0.55, style = "Quad", dir = "Out", marca = "TITULO" },
	},

}

return P
