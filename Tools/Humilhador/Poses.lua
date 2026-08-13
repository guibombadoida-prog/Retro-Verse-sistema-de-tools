-- Poses.lua
-- ModuleScript "Poses" — Humilhador  (conjunto GUEST)
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
--   PROVOCA      provocação     1.25s · 6 passo(s), 1 segurado(s)
--   RODA         provocação     1.60s · 5 passo(s), 1 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.46, 0.34, -0.94) * CFrame.Angles(math.rad(88), math.rad(-12), math.rad(-6)),
	LeftArm = CFrame.new(-1.42, -0.06, 0.22) * CFrame.Angles(math.rad(-16), math.rad(8), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-10), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(14), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(3)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0),
	HRP = CFrame.new(0, 0, 0),
}

P.RI = {
	RightArm = CFrame.new(1.4, 0.5, -0.72) * CFrame.Angles(math.rad(106), math.rad(-16), math.rad(-12)),
	LeftArm = CFrame.new(-1.36, 0.24, -0.3) * CFrame.Angles(math.rad(54), math.rad(12), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(-6), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-13), math.rad(10), 0),
}

P.RODA_ABRE = {
	RightArm = CFrame.new(1.42, 0.66, 0.3) * CFrame.Angles(math.rad(150), math.rad(-20), math.rad(-22)),
	LeftArm = CFrame.new(-1.42, 0.66, 0.3) * CFrame.Angles(math.rad(150), math.rad(20), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), 0),
	HRP = CFrame.new(0, 0.07, 0) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.RODA_GIRA = {
	RightArm = CFrame.new(1.44, 0.58, 0.16) * CFrame.Angles(math.rad(138), math.rad(-26), math.rad(-28)),
	LeftArm = CFrame.new(-1.44, 0.58, 0.16) * CFrame.Angles(math.rad(138), math.rad(26), math.rad(28)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-9), math.rad(180), 0),
}

P.SEQUENCIAS = {

	-- provocação · 1.25s · 6 passo(s), 1 segurado(s)
	PROVOCA = {
		{ pose = "APONTA", time = 0.2, style = "Back", dir = "Out", marca = "APONTA" },
		{ pose = "RI", time = 0.16, style = "Quad", dir = "Out", marca = "SPRITE" },
		{ pose = "APONTA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "RI", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "RI", time = 0.35, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- provocação · 1.60s · 5 passo(s), 1 segurado(s)
	RODA = {
		{ pose = "RODA_ABRE", time = 0.22, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "RODA_GIRA", time = 0.34, style = "Sine", dir = "InOut", marca = "GIRA" },
		{ pose = "RODA_GIRA", time = 0.44, style = "Sine", dir = "InOut" },
		{ pose = "RODA_ABRE", time = 0.3, style = "Sine", dir = "InOut", marca = "PULSO" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
