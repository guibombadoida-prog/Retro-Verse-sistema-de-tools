-- Poses.lua
-- ModuleScript "Poses" — Gato Ajudante Boss  (conjunto REALITY GUI)
--
-- AUTORAL — e aqui isso não é escolha, é falta de original.
--
-- A origem NÃO ANIMA O PERSONAGEM nesta Tool. Ver o topo do gerador:
-- o `Animation` da `SLAP` tem `AnimationId` vazio, e na `tre` e no
-- `gravity cat` quem se mexe é o modelo invocado, não quem invoca.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda.
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
-- Gerado por FERRAMENTAS/gerar_poses_reality.py.
--   CHAMAR       conjuração       1.30s · 5 passo(s)

local P = {}


P.APONTA_ALVO = {
	RightArm = CFrame.new(1.52, 0.36, -1.18) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.28) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(12), math.rad(0)),
}

P.ASSOBIA = {
	RightArm = CFrame.new(1.36, 0.5, -0.7) * CFrame.Angles(math.rad(112), math.rad(-22), math.rad(-26)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.26) * CFrame.Angles(math.rad(24), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(10), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(-12), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.30s · 5 passo(s)
	CHAMAR = {
		{ pose = "ASSOBIA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ASSOBIA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "APONTA_ALVO", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "APONTA_ALVO", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
