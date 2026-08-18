-- Poses.lua
-- ModuleScript "Poses" — Deu Ruim  (conjunto JODRO)
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
--   DEDO         golpe rápido     0.72s · 4 passo(s)
--   STONKS       sustentada       1.48s · 4 passo(s)
--   NOT          golpe pesado     1.24s · 4 passo(s)
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

P.NOT_STONKS = {
	RightArm = CFrame.new(1.3, -0.42, -0.2) * CFrame.Angles(math.rad(12), math.rad(16), math.rad(30)),
	LeftArm = CFrame.new(-1.3, -0.42, -0.2) * CFrame.Angles(math.rad(12), math.rad(-16), math.rad(-30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
}

P.STONKS = {
	RightArm = CFrame.new(1.42, 0.8, -0.16) * CFrame.Angles(math.rad(158), math.rad(-10), math.rad(-18)),
	LeftArm = CFrame.new(-1.42, 0.8, -0.16) * CFrame.Angles(math.rad(158), math.rad(10), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.72s · 4 passo(s)
	DEDO = {
		{ pose = "APONTA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "APONTA", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.48s · 4 passo(s)
	STONKS = {
		{ pose = "STONKS", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "STONKS", time = 0.66, style = "Sine", dir = "InOut", tremor = 0.045, freq = 22, marca = "SEGURA" },
		{ pose = "STONKS", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.24s · 4 passo(s)
	NOT = {
		{ pose = "NOT_STONKS", time = 0.28, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "NOT_STONKS", time = 0.48, style = "Sine", dir = "InOut", tremor = 0.05, freq = 24, marca = "SEGURA" },
		{ pose = "NOT_STONKS", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
