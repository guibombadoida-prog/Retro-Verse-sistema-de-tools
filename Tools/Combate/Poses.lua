-- Poses.lua
-- ModuleScript "Poses" — Combate  (conjunto DRAMA)
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
--   SOCO_A         combo            1.00s · 5 passo(s), 2 segurado(s)
--   SOCO_B         combo            1.00s · 5 passo(s), 2 segurado(s)
--   SOCO_C         combo            1.10s · 5 passo(s), 2 segurado(s)
--   CONTRA         reação           1.26s · 4 passo(s), 2 segurado(s)
--   DEVOLVER       reação           0.56s · 3 passo(s), 1 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.CONTRA_PEGA = {
	RightArm = CFrame.new(1.38, 0.6, -0.5) * CFrame.Angles(math.rad(118), math.rad(-20), math.rad(-30)),
	LeftArm = CFrame.new(-1.3, 0.3, -0.72) * CFrame.Angles(math.rad(78), math.rad(22), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-16), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-6), math.rad(-30), 0),
	RightLeg = CFrame.new(0.5, -1.88, 0.24) * CFrame.Angles(math.rad(14), math.rad(0), 0),
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

	-- combo · 1.00s · 5 passo(s), 2 segurado(s)
	SOCO_A = {
		{ pose = "GUARDA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "SOCO_DIR", time = 0.1, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "SOCO_DIR", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA", time = 0.35, style = "Quad", dir = "Out" },
	},

	-- combo · 1.00s · 5 passo(s), 2 segurado(s)
	SOCO_B = {
		{ pose = "GUARDA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "SOCO_ESQ", time = 0.1, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "SOCO_ESQ", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA", time = 0.35, style = "Quad", dir = "Out" },
	},

	-- combo · 1.10s · 5 passo(s), 2 segurado(s)
	SOCO_C = {
		{ pose = "GUARDA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "GANCHO", time = 0.12, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "GANCHO", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.38, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- reação · 1.26s · 4 passo(s), 2 segurado(s)
	CONTRA = {
		{ pose = "CONTRA_PEGA", time = 0.14, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "CONTRA_PEGA", time = 0.52, style = "Sine", dir = "InOut", tremor = 0.02, freq = 18, marca = "ESPERA" },
		{ pose = "CONTRA_PEGA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.03, freq = 24 },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FECHA" },
	},

	-- reação · 0.56s · 3 passo(s), 1 segurado(s)
	DEVOLVER = {
		{ pose = "GANCHO", time = 0.1, style = "Quint", dir = "Out", marca = "DEVOLVE" },
		{ pose = "GANCHO", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
