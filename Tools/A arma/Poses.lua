-- Poses.lua
-- ModuleScript "Poses" — A arma  (conjunto GUEST)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — e é exatamente o bug que o `Taco de Baseball` original tinha:
-- ele soldava as duas pernas no finalizador e o `Unequipped` não as soltava.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   TIRO         reação         0.34s · 3 passo(s), 1 segurado(s)
--   APONTAR      guarda         0.22s · 1 passo(s), 0 segurado(s)
--   RECARGA      manejo         1.40s · 6 passo(s), 2 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.ABRE_TAMBOR = {
	RightArm = CFrame.new(1.3, 0.3, -0.86) * CFrame.Angles(math.rad(78), math.rad(14), math.rad(22)),
	LeftArm = CFrame.new(-1.24, 0.34, -0.82) * CFrame.Angles(math.rad(84), math.rad(-12), math.rad(-20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-20), math.rad(8), 0),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(-5), math.rad(8), 0),
}

P.COICE = {
	RightArm = CFrame.new(1.42, 0.62, -0.8) * CFrame.Angles(math.rad(112), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.16, 0.54, -0.8) * CFrame.Angles(math.rad(104), math.rad(20), math.rad(24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(-6), 0),
	HRP = CFrame.new(0, 0.03, 0) * CFrame.Angles(math.rad(-6), math.rad(14), 0),
}

P.FECHA_TAMBOR = {
	RightArm = CFrame.new(1.4, 0.42, -0.9) * CFrame.Angles(math.rad(88), math.rad(4), math.rad(10)),
	LeftArm = CFrame.new(-1.4, 0.1, -0.34) * CFrame.Angles(math.rad(34), math.rad(-8), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-2), math.rad(6), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.3) * CFrame.Angles(math.rad(30), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.5, 0, -0.02) * CFrame.Angles(math.rad(5), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), 0),
}

P.MIRA = {
	RightArm = CFrame.new(1.44, 0.44, -1.0) * CFrame.Angles(math.rad(92), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.14, 0.4, -0.96) * CFrame.Angles(math.rad(88), math.rad(22), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-6), 0),
	HRP = CFrame.new(0, 0.01, 0) * CFrame.Angles(math.rad(-2), math.rad(16), 0),
}

P.SEQUENCIAS = {

	-- reação · 0.34s · 3 passo(s), 1 segurado(s)
	TIRO = {
		{ pose = "COICE", time = 0.05, style = "Quint", dir = "Out", marca = "DISPARA" },
		{ pose = "COICE", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "MIRA", time = 0.21, style = "Quad", dir = "Out" },
	},

	-- guarda · 0.22s · 1 passo(s), 0 segurado(s)
	APONTAR = {
		{ pose = "MIRA", time = 0.22, style = "Quad", dir = "Out", marca = "APONTA" },
	},

	-- manejo · 1.40s · 6 passo(s), 2 segurado(s)
	RECARGA = {
		{ pose = "ABRE_TAMBOR", time = 0.22, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "ABRE_TAMBOR", time = 0.3, style = "Sine", dir = "InOut", marca = "EJETA" },
		{ pose = "ABRE_TAMBOR", time = 0.38, style = "Sine", dir = "InOut", marca = "ENCHE" },
		{ pose = "FECHA_TAMBOR", time = 0.16, style = "Quint", dir = "Out", marca = "FECHA" },
		{ pose = "MIRA", time = 0.16, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.18, style = "Quad", dir = "Out", marca = "PRONTO" },
	},

}

return P
