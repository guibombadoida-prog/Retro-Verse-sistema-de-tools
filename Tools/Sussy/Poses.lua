-- Poses.lua
-- ModuleScript "Poses" — Sussy  (conjunto JODRO)
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
--   FACADA       golpe rápido     0.83s · 5 passo(s)
--   VENT         conjuração       0.72s · 3 passo(s)
--   REUNIAO      golpe pesado     1.36s · 4 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.

local P = {}


P.AGACHA = {
	RightArm = CFrame.new(1.3, -0.34, -0.34) * CFrame.Angles(math.rad(26), math.rad(12), math.rad(26)),
	LeftArm = CFrame.new(-1.3, -0.34, -0.34) * CFrame.Angles(math.rad(26), math.rad(-12), math.rad(-26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.62, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.5, -0.6) * CFrame.Angles(math.rad(-44), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.5, -0.6) * CFrame.Angles(math.rad(-44), math.rad(0), math.rad(0)),
}

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

P.FACA_CRAVA = {
	RightArm = CFrame.new(1.5, 0.2, -1.12) * CFrame.Angles(math.rad(84), math.rad(-16), math.rad(-6)),
	LeftArm = CFrame.new(-1.4, 0.02, -0.42) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(7), math.rad(22), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), math.rad(0)),
}

P.FACA_GUARDA = {
	RightArm = CFrame.new(1.42, 0.24, -0.5) * CFrame.Angles(math.rad(74), math.rad(-30), math.rad(-20)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.34) * CFrame.Angles(math.rad(30), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(20), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-5), math.rad(-20), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.83s · 5 passo(s)
	FACADA = {
		{ pose = "FACA_GUARDA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "FACA_GUARDA", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "FACA_CRAVA", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "FACA_CRAVA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 0.72s · 3 passo(s)
	VENT = {
		{ pose = "AGACHA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "AGACHA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.36s · 4 passo(s)
	REUNIAO = {
		{ pose = "APONTA_CEU", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_CEU", time = 0.56, style = "Sine", dir = "InOut", tremor = 0.05, freq = 24, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
