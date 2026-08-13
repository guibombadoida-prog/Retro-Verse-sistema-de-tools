-- Poses.lua
-- ModuleScript "Poses" — Desviar e Empurrar  (conjunto DRAMA)
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
--   EMPURRAO       golpe rápido     0.90s · 5 passo(s), 2 segurado(s)
--   ESQUIVA        reação           0.62s · 3 passo(s), 1 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.EMPURRA_CARGA = {
	RightArm = CFrame.new(1.36, 0.34, -0.44) * CFrame.Angles(math.rad(76), math.rad(-16), math.rad(-22)),
	LeftArm = CFrame.new(-1.36, 0.34, -0.44) * CFrame.Angles(math.rad(76), math.rad(16), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(0), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-10), math.rad(0), 0),
}

P.EMPURRA_SOLTA = {
	RightArm = CFrame.new(1.5, 0.36, -1.2) * CFrame.Angles(math.rad(90), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.5, 0.36, -1.2) * CFrame.Angles(math.rad(90), math.rad(4), math.rad(2)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(0), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(10), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.88, -0.3) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
}

P.ESQUIVA = {
	RightArm = CFrame.new(1.3, -0.16, -0.36) * CFrame.Angles(math.rad(44), math.rad(-20), math.rad(-34)),
	LeftArm = CFrame.new(-1.3, -0.16, -0.36) * CFrame.Angles(math.rad(44), math.rad(20), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(-28), 0),
	HRP = CFrame.new(0, -0.66, 0) * CFrame.Angles(math.rad(34), math.rad(34), 0),
	RightLeg = CFrame.new(0.5, -1.5, -0.7) * CFrame.Angles(math.rad(-50), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.62, 0.4) * CFrame.Angles(math.rad(26), math.rad(0), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(5), math.rad(5)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(-5), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.90s · 5 passo(s), 2 segurado(s)
	EMPURRAO = {
		{ pose = "EMPURRA_CARGA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "EMPURRA_CARGA", time = 0.26, style = "Sine", dir = "InOut" },
		{ pose = "EMPURRA_SOLTA", time = 0.1, style = "Quint", dir = "Out", marca = "EMPURRA" },
		{ pose = "EMPURRA_SOLTA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.2, style = "Quad", dir = "Out" },
	},

	-- reação · 0.62s · 3 passo(s), 1 segurado(s)
	ESQUIVA = {
		{ pose = "ESQUIVA", time = 0.12, style = "Quint", dir = "Out", marca = "ENTRA" },
		{ pose = "ESQUIVA", time = 0.26, style = "Sine", dir = "InOut", marca = "IMUNE" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "SAI" },
	},

}

return P
