-- Poses.lua
-- ModuleScript "Poses" — Pombo Correio  (conjunto JODRO)
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
--   BICADA       golpe rápido     0.61s · 4 passo(s)
--   REVOADA      conjuração       1.13s · 4 passo(s)
--   ENCOMENDA    golpe pesado     1.30s · 4 passo(s)
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

P.FACA_CRAVA = {
	RightArm = CFrame.new(1.5, 0.2, -1.12) * CFrame.Angles(math.rad(84), math.rad(-16), math.rad(-6)),
	LeftArm = CFrame.new(-1.4, 0.02, -0.42) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(7), math.rad(22), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.26) * CFrame.Angles(math.rad(-13), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.POMBO_BICA = {
	RightArm = CFrame.new(1.5, 0.3, -1.06) * CFrame.Angles(math.rad(88), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.03, 0) * CFrame.Angles(math.rad(10), math.rad(6), math.rad(0)),
}

P.POMBO_SOLTA = {
	RightArm = CFrame.new(1.4, 0.7, -0.4) * CFrame.Angles(math.rad(140), math.rad(-14), math.rad(-22)),
	LeftArm = CFrame.new(-1.4, 0.7, -0.4) * CFrame.Angles(math.rad(140), math.rad(14), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.61s · 4 passo(s)
	BICADA = {
		{ pose = "POMBO_BICA", time = 0.16, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "POMBO_BICA", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "FACA_CRAVA", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 1.13s · 4 passo(s)
	REVOADA = {
		{ pose = "POMBO_SOLTA", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "POMBO_SOLTA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.035, freq = 26 },
		{ pose = "POMBO_SOLTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.30s · 4 passo(s)
	ENCOMENDA = {
		{ pose = "APONTA_CEU", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_CEU", time = 0.52, style = "Sine", dir = "InOut", tremor = 0.05, freq = 25, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
