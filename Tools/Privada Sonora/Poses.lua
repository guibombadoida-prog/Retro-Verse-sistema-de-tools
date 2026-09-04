-- Poses.lua
-- ModuleScript "Poses" — Privada Sonora  (conjunto JODRO)
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
--   JATO         golpe pesado     1.02s · 4 passo(s)
--   DESCARGA     golpe pesado     1.20s · 4 passo(s)
--   CORO         conjuração       1.22s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
}

P.APONTA_CEU = {
	RightArm = CFrame.new(1.44, 0.84, -0.04) * CFrame.Angles(math.rad(168), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.46, 0.08, -0.28) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-15), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PRIVADA_GIRA = {
	RightArm = CFrame.new(1.44, 0.3, -0.7) * CFrame.Angles(math.rad(86), math.rad(-34), math.rad(-26)),
	LeftArm = CFrame.new(-1.44, 0.3, -0.7) * CFrame.Angles(math.rad(86), math.rad(34), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(34), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(6), math.rad(-46), math.rad(0)),
}

P.PRIVADA_MIRA = {
	RightArm = CFrame.new(1.48, 0.44, -1.0) * CFrame.Angles(math.rad(96), math.rad(-12), math.rad(-10)),
	LeftArm = CFrame.new(-1.42, 0.3, -0.6) * CFrame.Angles(math.rad(70), math.rad(16), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(10), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.02s · 4 passo(s)
	JATO = {
		{ pose = "PRIVADA_MIRA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PRIVADA_MIRA", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.035, freq = 25 },
		{ pose = "PRIVADA_MIRA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.20s · 4 passo(s)
	DESCARGA = {
		{ pose = "PRIVADA_GIRA", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PRIVADA_GIRA", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.05, freq = 27, marca = "SEGURA" },
		{ pose = "PRIVADA_GIRA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.22s · 4 passo(s)
	CORO = {
		{ pose = "APONTA_CEU", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_CEU", time = 0.46, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23 },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
