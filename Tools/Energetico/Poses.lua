-- Poses.lua
-- ModuleScript "Poses" — Energetico  (conjunto GUEST)
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
--   BEBER        consumo        1.30s · 5 passo(s), 2 segurado(s)
--   LATA         golpe rápido   0.70s · 5 passo(s), 2 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.AMASSA = {
	RightArm = CFrame.new(1.32, 0.3, -0.6) * CFrame.Angles(math.rad(74), math.rad(18), math.rad(26)),
	LeftArm = CFrame.new(-1.34, 0.28, -0.56) * CFrame.Angles(math.rad(70), math.rad(-16), math.rad(-24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(0), 0),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(8), math.rad(0), 0),
}

P.ERGUE_LATA = {
	RightArm = CFrame.new(1.1, 0.78, -0.44) * CFrame.Angles(math.rad(138), math.rad(26), math.rad(46)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.04) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), math.rad(-6), 0),
	HRP = CFrame.new(0, 0.03, 0) * CFrame.Angles(math.rad(-8), math.rad(6), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.2) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), 0),
}

P.JOGA = {
	RightArm = CFrame.new(1.48, 0.12, -1.04) * CFrame.Angles(math.rad(52), math.rad(-16), math.rad(-12)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.46) * CFrame.Angles(math.rad(24), math.rad(12), math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-10), 0),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(7), math.rad(20), 0),
}

P.VIRA = {
	RightArm = CFrame.new(1.04, 0.86, -0.36) * CFrame.Angles(math.rad(152), math.rad(22), math.rad(52)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.04) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-44), math.rad(-4), 0),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-13), math.rad(4), 0),
}

P.SEQUENCIAS = {

	-- consumo · 1.30s · 5 passo(s), 2 segurado(s)
	BEBER = {
		{ pose = "ERGUE_LATA", time = 0.26, style = "Back", dir = "Out", marca = "ERGUE" },
		{ pose = "VIRA", time = 0.18, style = "Quad", dir = "InOut", marca = "VIRA" },
		{ pose = "VIRA", time = 0.34, style = "Sine", dir = "InOut" },
		{ pose = "VIRA", time = 0.26, style = "Sine", dir = "InOut", marca = "ULTIMO_GOLE" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "CURA" },
	},

	-- golpe rápido · 0.70s · 5 passo(s), 2 segurado(s)
	LATA = {
		{ pose = "AMASSA", time = 0.16, style = "Back", dir = "In", marca = "AMASSA" },
		{ pose = "AMASSA", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "JOGA", time = 0.09, style = "Quint", dir = "Out", marca = "JOGA" },
		{ pose = "JOGA", time = 0.09, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.14, style = "Quad", dir = "Out" },
	},

}

return P
