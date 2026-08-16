-- Poses.lua
-- ModuleScript "Poses" — Arvore Maligna  (conjunto REALITY GUI)
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
--   PLANTAR      golpe pesado     1.50s · 5 passo(s)

local P = {}


P.CRESCE = {
	RightArm = CFrame.new(1.5, 0.6, -0.34) * CFrame.Angles(math.rad(122), math.rad(-16), math.rad(-26)),
	LeftArm = CFrame.new(-1.5, 0.6, -0.34) * CFrame.Angles(math.rad(122), math.rad(16), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-28), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PLANTA = {
	RightArm = CFrame.new(1.38, -0.3, -0.5) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(22)),
	LeftArm = CFrame.new(-1.38, -0.3, -0.5) * CFrame.Angles(math.rad(34), math.rad(-14), math.rad(-22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.42, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.64, -0.52) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.64, -0.52) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.50s · 5 passo(s)
	PLANTAR = {
		{ pose = "PLANTA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PLANTA", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23 },
		{ pose = "CRESCE", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CRESCE", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.05, freq = 27 },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
