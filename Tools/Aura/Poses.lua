-- Poses.lua
-- ModuleScript "Poses" — Aura  (conjunto DRAMA)
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
--   LIGAR          transformação    2.00s · 5 passo(s), 2 segurado(s)
--   PULSO          golpe rápido     1.00s · 5 passo(s), 2 segurado(s)
--   REFLETE        reação           0.24s · 2 passo(s), 1 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.AURA_ABRE = {
	RightArm = CFrame.new(1.56, 0.16, 0.42) * CFrame.Angles(math.rad(-28), math.rad(-14), math.rad(-50)),
	LeftArm = CFrame.new(-1.56, 0.16, 0.42) * CFrame.Angles(math.rad(-28), math.rad(14), math.rad(50)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.88, 0.2) * CFrame.Angles(math.rad(12), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.2) * CFrame.Angles(math.rad(12), math.rad(0), 0),
}

P.AURA_FECHA = {
	RightArm = CFrame.new(1.4, -0.1, -0.5) * CFrame.Angles(math.rad(44), math.rad(12), math.rad(22)),
	LeftArm = CFrame.new(-1.4, -0.1, -0.5) * CFrame.Angles(math.rad(44), math.rad(-12), math.rad(-22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), 0),
	HRP = CFrame.new(0, -0.08, 0) * CFrame.Angles(math.rad(8), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(5), math.rad(5)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(-5), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- transformação · 2.00s · 5 passo(s), 2 segurado(s)
	LIGAR = {
		{ pose = "AURA_ABRE", time = 0.05, style = "Quint", dir = "Out", marca = "LIGA" },
		{ pose = "AURA_ABRE", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.025, freq = 17 },
		{ pose = "AURA_ABRE", time = 0.75, style = "Sine", dir = "InOut", tremor = 0.035, freq = 23, marca = "SUSTENTA" },
		{ pose = "AURA_FECHA", time = 0.2, style = "Back", dir = "Out", marca = "FECHA" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe rápido · 1.00s · 5 passo(s), 2 segurado(s)
	PULSO = {
		{ pose = "AURA_FECHA", time = 0.22, style = "Back", dir = "In", marca = "RECOLHE" },
		{ pose = "AURA_FECHA", time = 0.28, style = "Sine", dir = "InOut", tremor = 0.04, freq = 25 },
		{ pose = "AURA_ABRE", time = 0.12, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "AURA_ABRE", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- reação · 0.24s · 2 passo(s), 1 segurado(s)
	REFLETE = {
		{ pose = "AURA_ABRE", time = 0.08, style = "Quint", dir = "Out", marca = "DEVOLVE" },
		{ pose = "AURA_ABRE", time = 0.16, style = "Sine", dir = "InOut" },
	},

}

return P
