-- Poses.lua
-- ModuleScript "Poses" — Chinelo Voador  (conjunto JODRO)
--
-- AUTORAL, pela GRAMATICA_R6.md. Não há modelo de origem: ninguém
-- mandou animação de meme, então tudo aqui é escrito.
--
-- Meme não é desculpa para animação frouxa. A leitura cômica vem do
-- ENQUADRAMENTO da pose — o martelo alto demais, o dedo apontado
-- parado — e isso exige a mesma pausa que um golpe sério. Regra 7:
-- estas sequências são 40–90% PARADAS.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
--   CHINELADA    golpe rápido     0.78s · 5 passo(s)
--   TELEGUIADO   conjuração       0.64s · 3 passo(s)
--   BRAVA        sustentada       1.50s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.

local P = {}


P.BRAVA = {
	RightArm = CFrame.new(1.34, -0.05, 0.2) * CFrame.Angles(math.rad(8), math.rad(-14), math.rad(-46)),
	LeftArm = CFrame.new(-1.34, -0.05, 0.2) * CFrame.Angles(math.rad(8), math.rad(14), math.rad(46)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

P.CHINELO_BATE = {
	RightArm = CFrame.new(1.5, 0.14, -1.02) * CFrame.Angles(math.rad(62), math.rad(-36), math.rad(-12)),
	LeftArm = CFrame.new(-1.42, 0.02, -0.4) * CFrame.Angles(math.rad(34), math.rad(16), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(-32), math.rad(0)),
	HRP = CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(6), math.rad(42), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.CHINELO_ERGUE = {
	RightArm = CFrame.new(1.4, 0.62, -0.34) * CFrame.Angles(math.rad(132), math.rad(-22), math.rad(-32)),
	LeftArm = CFrame.new(-1.44, 0.08, -0.3) * CFrame.Angles(math.rad(28), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(24), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(-28), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.78s · 5 passo(s)
	CHINELADA = {
		{ pose = "CHINELO_ERGUE", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHINELO_ERGUE", time = 0.13, style = "Sine", dir = "InOut" },
		{ pose = "CHINELO_BATE", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CHINELO_BATE", time = 0.15, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.23, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 0.64s · 3 passo(s)
	TELEGUIADO = {
		{ pose = "CHINELO_ERGUE", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHINELO_BATE", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.50s · 4 passo(s)
	BRAVA = {
		{ pose = "BRAVA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BRAVA", time = 0.62, style = "Sine", dir = "InOut", tremor = 0.04, freq = 20, marca = "SEGURA" },
		{ pose = "BRAVA", time = 0.24, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
