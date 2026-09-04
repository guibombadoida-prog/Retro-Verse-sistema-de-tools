-- Poses.lua
-- ModuleScript "Poses" — Olhos Laser  (conjunto DRAMA)
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
-- JUNTA QUE LIDERA: **Head** (regra 6 da gramática).
--
--   FEIXE_ABRE     conjuração       0.30s · 2 passo(s), 0 segurado(s)
--   FEIXE_FECHA    reação           0.40s · 2 passo(s), 0 segurado(s)
--   SOBRECARGA     sustentada       1.76s · 7 passo(s), 2 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.FEIXE_OLHOS = {
	RightArm = CFrame.new(1.54, -0.06, 0.16) * CFrame.Angles(math.rad(-12), math.rad(-6), math.rad(-18)),
	LeftArm = CFrame.new(-1.54, -0.06, 0.16) * CFrame.Angles(math.rad(-12), math.rad(6), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(5), math.rad(5)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(-5), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.MIRA_OLHOS = {
	RightArm = CFrame.new(1.5, 0.06, -0.24) * CFrame.Angles(math.rad(22), math.rad(-4), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, 0.06, -0.24) * CFrame.Angles(math.rad(22), math.rad(4), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(0), 0),
}

P.VARRE_OLHOS = {
	RightArm = CFrame.new(1.54, -0.06, 0.16) * CFrame.Angles(math.rad(-12), math.rad(-6), math.rad(-18)),
	LeftArm = CFrame.new(-1.54, -0.06, 0.16) * CFrame.Angles(math.rad(-12), math.rad(6), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(44), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-10), math.rad(12), 0),
	RightLeg = CFrame.new(0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- conjuração · 0.30s · 2 passo(s), 0 segurado(s)
	FEIXE_ABRE = {
		{ pose = "MIRA_OLHOS", time = 0.18, style = "Quad", dir = "Out", marca = "MIRA" },
		{ pose = "FEIXE_OLHOS", time = 0.12, style = "Back", dir = "Out", marca = "ATIRA" },
	},

	-- reação · 0.40s · 2 passo(s), 0 segurado(s)
	FEIXE_FECHA = {
		{ pose = "MIRA_OLHOS", time = 0.16, style = "Quad", dir = "Out", marca = "CORTA" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.76s · 7 passo(s), 2 segurado(s)
	SOBRECARGA = {
		{ pose = "MIRA_OLHOS", time = 0.2, style = "Back", dir = "Out", marca = "MIRA" },
		{ pose = "FEIXE_OLHOS", time = 0.14, style = "Quint", dir = "Out", marca = "ABRE" },
		{ pose = "VARRE_OLHOS", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.04, freq = 30, marca = "CARREGA" },
		{ pose = "VARRE_OLHOS", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.055, freq = 34 },
		{ pose = "FEIXE_OLHOS", time = 0.12, style = "Quint", dir = "Out", marca = "ESTOURA" },
		{ pose = "FEIXE_OLHOS", time = 0.24, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
