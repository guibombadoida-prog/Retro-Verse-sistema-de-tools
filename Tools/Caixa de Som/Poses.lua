-- Poses.lua
-- ModuleScript "Poses" — Caixa de Som  (conjunto JODRO)
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
--   ONDA         golpe pesado     1.21s · 5 passo(s)
--   NUNCA        sustentada       1.52s · 4 passo(s)
--   TROCA        conjuração       0.66s · 3 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_jodro.py.

local P = {}


P.APONTA = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
}

P.CAIXA_EMPURRA = {
	RightArm = CFrame.new(1.5, 0.42, -1.2) * CFrame.Angles(math.rad(96), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.5, 0.42, -1.2) * CFrame.Angles(math.rad(96), math.rad(6), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.22) * CFrame.Angles(math.rad(-11), math.rad(0), math.rad(0)),
}

P.CAIXA_SEGURA = {
	RightArm = CFrame.new(1.42, 0.5, -0.6) * CFrame.Angles(math.rad(104), math.rad(-18), math.rad(-22)),
	LeftArm = CFrame.new(-1.42, 0.5, -0.6) * CFrame.Angles(math.rad(104), math.rad(18), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.05, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.21s · 5 passo(s)
	ONDA = {
		{ pose = "CAIXA_SEGURA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CAIXA_SEGURA", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.03, freq = 24 },
		{ pose = "CAIXA_EMPURRA", time = 0.13, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CAIXA_EMPURRA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.52s · 4 passo(s)
	NUNCA = {
		{ pose = "CAIXA_SEGURA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CAIXA_SEGURA", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.045, freq = 21, marca = "SEGURA" },
		{ pose = "CAIXA_EMPURRA", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- conjuração · 0.66s · 3 passo(s)
	TROCA = {
		{ pose = "APONTA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
