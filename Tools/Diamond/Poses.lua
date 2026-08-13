-- Poses.lua
-- ModuleScript "Poses" — Diamond  (conjunto GUEST)
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
--   TAPA         golpe rápido   0.62s · 5 passo(s), 2 segurado(s)
--   PEDRA        transformação  2.00s · 5 passo(s), 2 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.24) * CFrame.Angles(math.rad(24), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.5, 0, -0.04) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(5), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.PEDRA_ABRE = {
	RightArm = CFrame.new(1.46, 0.4, -0.62) * CFrame.Angles(math.rad(96), math.rad(-14), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.4, -0.62) * CFrame.Angles(math.rad(96), math.rad(14), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-10), math.rad(0), 0),
}

P.PEDRA_FECHA = {
	RightArm = CFrame.new(1.36, -0.2, -0.5) * CFrame.Angles(math.rad(42), math.rad(0), math.rad(26)),
	LeftArm = CFrame.new(-1.36, -0.2, -0.5) * CFrame.Angles(math.rad(42), math.rad(0), math.rad(-26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(18), math.rad(0), 0),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(12), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.94, -0.1) * CFrame.Angles(math.rad(-5), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.94, -0.1) * CFrame.Angles(math.rad(-5), math.rad(0), 0),
}

P.TAPA_BATE = {
	RightArm = CFrame.new(1.52, 0.12, -1.16) * CFrame.Angles(math.rad(78), math.rad(-36), math.rad(-18)),
	LeftArm = CFrame.new(-1.42, 0.04, -0.6) * CFrame.Angles(math.rad(30), math.rad(20), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-28), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(7), math.rad(38), 0),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.TAPA_CARGA = {
	RightArm = CFrame.new(1.24, 0.68, 0.18) * CFrame.Angles(math.rad(146), math.rad(30), math.rad(34)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.3) * CFrame.Angles(math.rad(34), math.rad(-10), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(26), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-5), math.rad(-34), 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.62s · 5 passo(s), 2 segurado(s)
	TAPA = {
		{ pose = "TAPA_CARGA", time = 0.13, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "TAPA_CARGA", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "TAPA_BATE", time = 0.08, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "TAPA_BATE", time = 0.09, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.14, style = "Quad", dir = "Out" },
	},

	-- transformação · 2.00s · 5 passo(s), 2 segurado(s)
	PEDRA = {
		{ pose = "PEDRA_FECHA", time = 0.05, style = "Quint", dir = "Out", marca = "FECHA" },
		{ pose = "PEDRA_FECHA", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.02, freq = 15 },
		{ pose = "PEDRA_FECHA", time = 0.75, style = "Sine", dir = "InOut", tremor = 0.03, freq = 19, marca = "SUSTENTA" },
		{ pose = "PEDRA_ABRE", time = 0.2, style = "Back", dir = "Out", marca = "ABRE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
