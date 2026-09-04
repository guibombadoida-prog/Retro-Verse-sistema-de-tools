-- Poses.lua
-- ModuleScript "Poses" — Abacate (roubado) do mexico  (conjunto GUEST)
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
--   COMER        consumo        1.20s · 6 passo(s), 1 segurado(s)
--   ARREMESSO    golpe rápido   0.62s · 5 passo(s), 2 segurado(s)
--
-- NENHUMA POSE FOI COPIADA da origem. O que veio dela foi proporção e
-- duração; a silhueta é escrita aqui.
--
-- Gerado por FERRAMENTAS/gerar_poses_guest.py.

local P = {}


P.ARREMESSO_CARGA = {
	RightArm = CFrame.new(1.3, 0.72, 0.26) * CFrame.Angles(math.rad(154), math.rad(18), math.rad(24)),
	LeftArm = CFrame.new(-1.44, 0.12, -0.34) * CFrame.Angles(math.rad(38), math.rad(-10), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(12), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-7), math.rad(-20), 0),
}

P.ARREMESSO_SOLTA = {
	RightArm = CFrame.new(1.46, 0.16, -1.02) * CFrame.Angles(math.rad(56), math.rad(-14), math.rad(-10)),
	LeftArm = CFrame.new(-1.48, 0.04, -0.5) * CFrame.Angles(math.rad(26), math.rad(10), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-8), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(8), math.rad(18), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.04, -0.22) * CFrame.Angles(math.rad(22), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), 0),
}

P.LEVA_BOCA = {
	RightArm = CFrame.new(1.16, 0.66, -0.62) * CFrame.Angles(math.rad(116), math.rad(30), math.rad(42)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.06) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-8), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(8), 0),
}

P.MASTIGA = {
	RightArm = CFrame.new(1.14, 0.6, -0.58) * CFrame.Angles(math.rad(110), math.rad(28), math.rad(40)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.06) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-10), 0),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(2), math.rad(8), 0),
}

P.SEQUENCIAS = {

	-- consumo · 1.20s · 6 passo(s), 1 segurado(s)
	COMER = {
		{ pose = "LEVA_BOCA", time = 0.24, style = "Back", dir = "Out", marca = "LEVA" },
		{ pose = "MASTIGA", time = 0.18, style = "Sine", dir = "InOut", marca = "MORDE" },
		{ pose = "LEVA_BOCA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "MASTIGA", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "MASTIGA", time = 0.2, style = "Sine", dir = "InOut", marca = "ENGOLE" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "CURA" },
	},

	-- golpe rápido · 0.62s · 5 passo(s), 2 segurado(s)
	ARREMESSO = {
		{ pose = "ARREMESSO_CARGA", time = 0.14, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ARREMESSO_CARGA", time = 0.17, style = "Sine", dir = "InOut" },
		{ pose = "ARREMESSO_SOLTA", time = 0.09, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_SOLTA", time = 0.08, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.14, style = "Quad", dir = "Out" },
	},

}

return P
