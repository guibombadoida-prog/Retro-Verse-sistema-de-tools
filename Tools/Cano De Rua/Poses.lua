-- Poses.lua
-- ModuleScript "Poses" — Cano De Rua  (conjunto GUEST)
--
-- ⚠️ ESTAS POSES SÃO DO MODELO DE ORIGEM, NÃO AUTORAIS.
--
-- Foram extraídas do `guest_tools.rbxmx` pelo
-- FERRAMENTAS/extrair_poses_guest.py, a pedido: a animação original
-- destas duas Tools volta, e as outras cinco do conjunto seguem autorais.
--
-- Elas PODEM voltar sem perda porque o laço de origem varre o alpha de 0
-- a 1 — `lerp(alvo, 1)` é o próprio alvo, então a pose escrita no código é
-- a pose alcançada. No Xester o alpha era constante e foi preciso simular.
--
-- A convenção já era a nossa: o original solda Weld do Torso para o
-- membro, com os nomes RightArmWelde/LeftArmWelde/HeadWelde. Zero conversão.
--
-- FORA: `CFrame.fromEulerAnglesXYZ(0, math.rad(swingrand), 0)` no braço
-- direito. `swingrand` é math.random(-50,50) por golpe, e sorteio em
-- gameplay é proibido — a variação volta como jitter no Server.
--
-- JUNTA QUE LIDERA: **RightArm**.
--
--   GOLPE_A      golpe rápido     0.76s · 5 passo(s)
--   GOLPE_B      golpe rápido     0.80s · 5 passo(s)
--   CEGAR        golpe pesado     1.30s · 5 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_guest_originais.py.

local P = {}


P.BATE_A = {
	RightArm = CFrame.new(1.88294, 0.63335, -0.133141, 0.859447, -0.503111, -0.0907214, 0.308428, 0.651808, -0.692833, 0.407705, 0.567473, 0.715368),
	LeftArm = CFrame.new(-1.46153, 0.631954, 0, 0.766044, 0.642788, -2.98023e-08, -0.642788, 0.766044, 0, -2.98023e-08, 1.49012e-08, 1),
	Head = CFrame.new(-0.0406685, 0.997953, 0.0197182, 0.649182, -0.0813359, -0.756272, 0.0229108, 0.995906, -0.0874415, 0.760288, 0.0394387, 0.648388),
	HRP = CFrame.new(0, 0, 0, 0.645386, -0.0593912, 0.761544, -0.0868241, 0.984808, 0.150384, -0.758906, -0.163176, 0.630424),
}

P.BATE_B = {
	RightArm = CFrame.new(1.94078, 1.12005, -0.439268, 0.133022, -0.718527, 0.682659, 0.991084, 0.0912357, -0.0970924, 0.00748063, 0.689489, 0.724258),
	LeftArm = CFrame.new(-1.35798, 0.156599, 9.53674e-07, 0.5, 0.866025, -5.96046e-08, -0.866025, 0.5, -1.11759e-08, -4.47035e-08, -8.9407e-08, 1),
	Head = CFrame.new(0, 0.999999, 0, 0.34202, -6.70552e-08, 0.939693, -1.10595e-08, 1, -6.70552e-08, -0.939693, -1.11759e-08, 0.34202),
	HRP = CFrame.new(0, 0, 0, 0.356122, 0.102899, -0.928757, 0.061087, 0.989229, 0.133022, 0.932441, -0.104107, 0.346),
}

P.CARGA_A = {
	RightArm = CFrame.new(1.43301, 0.784341, -0.405934, 0.866025, 7.45058e-09, -0.5, -0.17101, -0.939692, -0.296198, -0.469846, 0.34202, -0.813798),
	LeftArm = CFrame.new(-1.46153, 0.631954, 0, 0.766044, 0.642788, -2.98023e-08, -0.642788, 0.766044, 0, -2.98023e-08, 1.49012e-08, 1),
	Head = CFrame.new(-0.0815878, 0.992404, -0.0296965, 0.34202, -0.163176, 0.925416, -1.45519e-09, 0.984808, 0.173648, -0.939693, -0.0593911, 0.336824),
	HRP = CFrame.new(0, 0, 0, 0.336824, 0.0593912, -0.939693, -0.173648, 0.984808, 0, 0.925417, 0.163176, 0.34202),
}

P.CARGA_B = {
	RightArm = CFrame.new(1.11058, 0.534517, -0.642426, 0.133022, 0.395739, 0.908678, 0.991085, -0.0600326, -0.118941, 0.00748065, 0.916399, -0.400197),
	LeftArm = CFrame.new(-1.46153, 0.631954, 0, 0.766044, 0.642788, -2.98023e-08, -0.642788, 0.766044, 0, -2.98023e-08, 1.49012e-08, 1),
	Head = CFrame.new(-2.38419e-07, 1, 9.53674e-07, 0.5, 2.6077e-08, -0.866025, -1.02445e-08, 1, -3.35276e-08, 0.866026, -1.49012e-08, 0.5),
	HRP = CFrame.new(0, 0, 0, 0.34202, 0.163176, 0.925417, 4.47035e-08, 0.984808, -0.173648, -0.939693, 0.0593911, 0.336824),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0, 0),
	LeftArm = CFrame.new(-1.5, 0, 0),
	Head = CFrame.new(0, 1.5, 0),
	HRP = CFrame.new(0, 0, 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.76s · 5 passo(s)
	GOLPE_A = {
		{ pose = "CARGA_A", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_A", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "BATE_A", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_A", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- golpe rápido · 0.80s · 5 passo(s)
	GOLPE_B = {
		{ pose = "CARGA_B", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_B", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "BATE_B", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_B", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.30s · 5 passo(s)
	CEGAR = {
		{ pose = "CARGA_B", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_B", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.035, freq = 22 },
		{ pose = "BATE_B", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_B", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26, marca = "SEGURA" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out" },
	},

}

return P
