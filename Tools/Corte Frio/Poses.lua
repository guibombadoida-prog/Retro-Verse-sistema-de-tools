-- Poses.lua
-- ModuleScript "Poses" — Corte Frio  (conjunto DRAMA)
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
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   CORTE          golpe rápido     1.00s · 5 passo(s), 2 segurado(s)
--   SERIE          cutscene         3.27s · 15 passo(s), 1 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.ESTOCADA = {
	RightArm = CFrame.new(1.5, 0.42, -1.3) * CFrame.Angles(math.rad(96), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.5, 0.1, -0.3) * CFrame.Angles(math.rad(30), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(16), math.rad(12), 0),
	RightLeg = CFrame.new(0.5, -1.82, -0.44) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.28) * CFrame.Angles(math.rad(16), math.rad(0), 0),
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

P.SEQUENCIAS = {

	-- golpe rápido · 1.00s · 5 passo(s), 2 segurado(s)
	CORTE = {
		{ pose = "LAMINA_ERGUE", time = 0.22, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "LAMINA_ERGUE", time = 0.3, style = "Sine", dir = "InOut" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTA" },
		{ pose = "LAMINA_CORTA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- cutscene · 3.27s · 15 passo(s), 1 segurado(s)
	SERIE = {
		{ pose = "LAMINA_ERGUE", time = 0.35, style = "Back", dir = "In", tremor = 0.02, freq = 16, marca = "CAMERA" },
		{ pose = "ESTOCADA", time = 0.22, style = "Quint", dir = "In", marca = "AVANCA" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE_1" },
		{ pose = "LAMINA_ERGUE", time = 0.12, style = "Quad", dir = "InOut" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE_2" },
		{ pose = "LAMINA_ERGUE", time = 0.12, style = "Quad", dir = "InOut" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE_3" },
		{ pose = "LAMINA_ERGUE", time = 0.12, style = "Quad", dir = "InOut" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE_4" },
		{ pose = "LAMINA_ERGUE", time = 0.14, style = "Quad", dir = "InOut" },
		{ pose = "LAMINA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "CORTE_5" },
		{ pose = "ESTOCADA", time = 0.18, style = "Back", dir = "In", tremor = 0.05, freq = 30, marca = "SEGURA" },
		{ pose = "LAMINA_CORTA", time = 0.12, style = "Quint", dir = "Out", marca = "ULTIMO" },
		{ pose = "LAMINA_CORTA", time = 0.5, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.9, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
