-- Poses.lua
-- ModuleScript "Poses" — TryHard  (conjunto DRAMA)
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
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   COMBO_1        combo            0.60s · 5 passo(s), 2 segurado(s)
--   COMBO_2        combo            0.40s · 3 passo(s), 1 segurado(s)
--   COMBO_3        combo            0.42s · 3 passo(s), 1 segurado(s)
--   COMBO_4        combo            0.76s · 4 passo(s), 1 segurado(s)
--   FINALIZADOR    ultimate         7.60s · 10 passo(s), 5 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.CHUTE_CARGA = {
	RightArm = CFrame.new(1.5, 0.3, -0.4) * CFrame.Angles(math.rad(62), math.rad(-14), math.rad(-12)),
	LeftArm = CFrame.new(-1.5, 0.3, -0.4) * CFrame.Angles(math.rad(62), math.rad(14), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(24), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-40), 0),
	RightLeg = CFrame.new(0.5, -1.7, -0.5) * CFrame.Angles(math.rad(-34), math.rad(0), 0),
}

P.CHUTE_GIRA = {
	RightArm = CFrame.new(1.56, 0.2, 0.3) * CFrame.Angles(math.rad(-14), math.rad(-20), math.rad(-46)),
	LeftArm = CFrame.new(-1.56, 0.2, 0.3) * CFrame.Angles(math.rad(-14), math.rad(20), math.rad(46)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(-30), 0),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(5), math.rad(150), 0),
	RightLeg = CFrame.new(0.66, -1.5, -0.9) * CFrame.Angles(math.rad(-78), math.rad(0), math.rad(-14)),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), 0),
}

P.ESTOCADA = {
	RightArm = CFrame.new(1.5, 0.42, -1.3) * CFrame.Angles(math.rad(96), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.5, 0.1, -0.3) * CFrame.Angles(math.rad(30), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(16), math.rad(12), 0),
	RightLeg = CFrame.new(0.5, -1.82, -0.44) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.28) * CFrame.Angles(math.rad(16), math.rad(0), 0),
}

P.GANCHO = {
	RightArm = CFrame.new(1.44, -0.08, -0.96) * CFrame.Angles(math.rad(54), math.rad(-26), math.rad(-16)),
	LeftArm = CFrame.new(-1.32, 0.44, -0.5) * CFrame.Angles(math.rad(92), math.rad(16), math.rad(24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(-18), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(34), 0),
	RightLeg = CFrame.new(0.52, -1.86, -0.3) * CFrame.Angles(math.rad(-16), math.rad(0), 0),
}

P.GUARDA = {
	RightArm = CFrame.new(1.34, 0.46, -0.66) * CFrame.Angles(math.rad(96), math.rad(-12), math.rad(-24)),
	LeftArm = CFrame.new(-1.3, 0.52, -0.7) * CFrame.Angles(math.rad(102), math.rad(14), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(10), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(-18), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(5), math.rad(5)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(-5), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.LAMINA_CORTA = {
	RightArm = CFrame.new(1.52, 0.02, -1.14) * CFrame.Angles(math.rad(74), math.rad(-34), math.rad(-18)),
	LeftArm = CFrame.new(-1.42, -0.02, -0.66) * CFrame.Angles(math.rad(38), math.rad(24), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-26), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(7), math.rad(38), 0),
	RightLeg = CFrame.new(0.5, -1.9, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), 0),
}

P.LAMINA_ERGUE = {
	RightArm = CFrame.new(1.36, 0.78, -0.2) * CFrame.Angles(math.rad(142), math.rad(16), math.rad(18)),
	LeftArm = CFrame.new(-1.44, 0.2, -0.42) * CFrame.Angles(math.rad(46), math.rad(-12), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(22), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(-32), 0),
}

P.SOCO_DIR = {
	RightArm = CFrame.new(1.5, 0.4, -1.16) * CFrame.Angles(math.rad(92), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.28, 0.5, -0.6) * CFrame.Angles(math.rad(104), math.rad(18), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-14), 0),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(3), math.rad(26), 0),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.SOCO_ESQ = {
	RightArm = CFrame.new(1.28, 0.5, -0.6) * CFrame.Angles(math.rad(104), math.rad(-18), math.rad(-30)),
	LeftArm = CFrame.new(-1.5, 0.4, -1.16) * CFrame.Angles(math.rad(92), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(14), 0),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(3), math.rad(-26), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- combo · 0.60s · 5 passo(s), 2 segurado(s)
	COMBO_1 = {
		{ pose = "GUARDA", time = 0.14, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.1, style = "Sine", dir = "InOut" },
		{ pose = "SOCO_DIR", time = 0.08, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "SOCO_DIR", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA", time = 0.16, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.40s · 3 passo(s), 1 segurado(s)
	COMBO_2 = {
		{ pose = "SOCO_ESQ", time = 0.1, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "SOCO_ESQ", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA", time = 0.16, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.42s · 3 passo(s), 1 segurado(s)
	COMBO_3 = {
		{ pose = "GANCHO", time = 0.11, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "GANCHO", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA", time = 0.16, style = "Quad", dir = "Out", marca = "ABRE_JANELA" },
	},

	-- combo · 0.76s · 4 passo(s), 1 segurado(s)
	COMBO_4 = {
		{ pose = "CHUTE_CARGA", time = 0.14, style = "Back", dir = "In" },
		{ pose = "CHUTE_GIRA", time = 0.12, style = "Quint", dir = "Out", marca = "BATE_FORTE" },
		{ pose = "CHUTE_GIRA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- ultimate · 7.60s · 10 passo(s), 5 segurado(s)
	FINALIZADOR = {
		{ pose = "GUARDA", time = 0.45, style = "Back", dir = "In", tremor = 0.02, freq = 15, marca = "CAMERA" },
		{ pose = "LAMINA_ERGUE", time = 0.75, style = "Quad", dir = "InOut", tremor = 0.03, freq = 19, marca = "ERGUE" },
		{ pose = "LAMINA_ERGUE", time = 1.0, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23, marca = "CARGA" },
		{ pose = "LAMINA_ERGUE", time = 1.1, style = "Sine", dir = "InOut", tremor = 0.055, freq = 28 },
		{ pose = "ESTOCADA", time = 0.4, style = "Quint", dir = "In", marca = "AVANCA" },
		{ pose = "ESTOCADA", time = 1.0, style = "Sine", dir = "InOut", tremor = 0.075, freq = 33, marca = "SEGURA" },
		{ pose = "ESTOCADA", time = 1.05, style = "Sine", dir = "InOut", tremor = 0.09, freq = 37 },
		{ pose = "LAMINA_CORTA", time = 0.2, style = "Quint", dir = "Out", marca = "EXECUTA" },
		{ pose = "LAMINA_CORTA", time = 0.75, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.9, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
