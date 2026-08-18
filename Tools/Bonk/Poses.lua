-- Poses.lua
-- ModuleScript "Poses" — Bonk  (conjunto JODRO)
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
--   BONK         golpe rápido     0.96s · 5 passo(s)
--   MEGA         golpe pesado     1.58s · 5 passo(s)
--   CADEIA       conjuração       1.10s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.MARTELO_BATE = {
	RightArm = CFrame.new(1.46, -0.12, -0.96) * CFrame.Angles(math.rad(40), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.4, 0, -0.42) * CFrame.Angles(math.rad(38), math.rad(14), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(20), math.rad(6), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, -0.3) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
}

P.MARTELO_ERGUE = {
	RightArm = CFrame.new(1.44, 0.72, -0.1) * CFrame.Angles(math.rad(168), math.rad(-8), math.rad(-18)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-9), math.rad(-8), math.rad(0)),
}

P.MARTELO_MEGA = {
	RightArm = CFrame.new(1.4, 0.86, 0.04) * CFrame.Angles(math.rad(176), math.rad(-6), math.rad(-14)),
	LeftArm = CFrame.new(-1.4, 0.86, 0.04) * CFrame.Angles(math.rad(176), math.rad(6), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.14) * CFrame.Angles(math.rad(9), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.14) * CFrame.Angles(math.rad(9), math.rad(0), math.rad(0)),
}

P.MARTELO_QUEDA = {
	RightArm = CFrame.new(1.42, -0.3, -0.8) * CFrame.Angles(math.rad(22), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.42, -0.3, -0.8) * CFrame.Angles(math.rad(22), math.rad(6), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.6, -0.5) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.6, -0.5) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.96s · 5 passo(s)
	BONK = {
		{ pose = "MARTELO_ERGUE", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MARTELO_ERGUE", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "MARTELO_BATE", time = 0.11, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "MARTELO_BATE", time = 0.17, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.58s · 5 passo(s)
	MEGA = {
		{ pose = "MARTELO_MEGA", time = 0.34, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "MARTELO_MEGA", time = 0.52, style = "Sine", dir = "InOut", tremor = 0.05, freq = 26, marca = "SEGURA" },
		{ pose = "MARTELO_QUEDA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "MARTELO_QUEDA", time = 0.26, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.10s · 4 passo(s)
	CADEIA = {
		{ pose = "APONTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "APONTA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
