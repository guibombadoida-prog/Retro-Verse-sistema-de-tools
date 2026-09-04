-- Poses.lua
-- ModuleScript "Poses" — Taco de Baseball  (conjunto GUEST)
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
-- JUNTA QUE LIDERA: **HRP**.
--
--   GOLPE_A      golpe rápido     0.78s · 5 passo(s)
--   GOLPE_B      golpe rápido     0.84s · 5 passo(s)
--   REBATER      sustentada       1.56s · 6 passo(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_guest_originais.py.

local P = {}


P.BATE_A = {
	RightArm = CFrame.new(1.5, 0.32899, -0.469845, 1, 2.98023e-08, -2.98023e-08, 7.45058e-09, 0.34202, -0.939692, 0, 0.939692, 0.34202),
	LeftArm = CFrame.new(0.314659, 0.191041, -1.22734, 0.344305, -0.926735, -0.150384, 0.0301537, 0.17101, -0.984808, 0.938374, 0.334539, 0.086824),
	Head = CFrame.new(0, 1.5, 1.90735e-06, 0.642788, 7.45058e-09, 0.766044, -1.04774e-09, 1, 1.49012e-08, -0.766044, 0, 0.642788),
	HRP = CFrame.new(0, 0, 0, 0.633022, -0.111619, -0.766044, 0.173648, 0.984808, 0, 0.754406, -0.133022, 0.642788),
	RightLeg = CFrame.new(0.681245, -2.07163, 0, 0.984808, -0.173648, -2.98023e-08, 0.173648, 0.984808, 7.45058e-09, -2.98023e-08, 1.1415e-08, 1),
	LeftLeg = CFrame.new(-0.499999, -1.4, -0.4, 1, -7.45058e-09, -2.98023e-08, 1.49012e-08, 1, 7.45058e-09, -2.98023e-08, 0, 1),
}

P.BATE_B = {
	RightArm = CFrame.new(0.569937, 0.318357, -1.03015, 0.939692, 0.34202, 1.49012e-08, -0.0593912, 0.163176, -0.984808, -0.336824, 0.925416, 0.173648),
	LeftArm = CFrame.new(-0.429024, 0.324181, -0.997121, 0.984808, -0.173648, 1.49012e-08, 0.0301537, 0.17101, -0.984808, 0.17101, 0.969846, 0.173648),
	Head = CFrame.new(-1.90735e-06, 1.5, 0, 0.984808, -7.45058e-09, -0.173648, -1.49012e-08, 1, 0, 0.173648, -2.98023e-08, 0.984808),
	HRP = CFrame.new(0, -1.2, 0, 0.950535, -0.0556329, 0.305593, -0.0479752, 0.945729, 0.321394, -0.306889, -0.320157, 0.89628),
	RightLeg = CFrame.new(0.5, -2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	LeftLeg = CFrame.new(-0.5, -2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
}

P.CARGA_A = {
	RightArm = CFrame.new(0.272449, 0.123778, -0.74103, 0.642787, 0.719846, 0.262003, 1.49012e-08, 0.34202, -0.939692, -0.766044, 0.604023, 0.219846),
	LeftArm = CFrame.new(-0.993066, 0.092876, -0.543261, 0.981226, -0.183489, 0.0593912, 0.116978, 0.321394, -0.939692, 0.153335, 0.928998, 0.336824),
	Head = CFrame.new(9.53674e-07, 1.5, 9.53674e-07, 0.5, -1.49012e-08, -0.866025, -3.14321e-09, 1, -1.49012e-08, 0.866025, -7.45058e-09, 0.5),
	HRP = CFrame.new(0, 0, 0, 0.492404, 0.0868241, 0.866025, -0.173648, 0.984808, 0, -0.852869, -0.150384, 0.5),
}

P.CARGA_B = {
	RightArm = CFrame.new(1.57791, 0.75, 0.321749, 0.34202, -0.813798, 0.469846, -1.49012e-08, -0.5, -0.866025, 0.939693, 0.296198, -0.17101),
	LeftArm = CFrame.new(1.41172, 0.678531, -0.785639, -0.46849, -0.766294, 0.43967, -0.134425, -0.43004, -0.892746, 0.873182, -0.477345, 0.09846),
	Head = CFrame.new(-0.131, 1.46985, -0.109922, 0.642787, -0.262003, 0.719846, 0, 0.939692, 0.34202, -0.766045, -0.219846, 0.604023),
	HRP = CFrame.new(0, 0, 0, 0.633022, 0.111619, -0.766045, -0.173648, 0.984808, 0, 0.754407, 0.133022, 0.642787),
	RightLeg = CFrame.new(0.499998, -1.5, 0.866026, 1, -2.98023e-08, -3.72529e-09, -7.45058e-09, 0.5, 0.866025, 0, -0.866025, 0.5),
	LeftLeg = CFrame.new(-0.500002, -0.739692, -0.65798, 1, 0, 2.98023e-08, -7.45058e-09, 0.939692, 0.34202, 0, -0.34202, 0.939693),
}

P.ERGUE = {
	RightArm = CFrame.new(1.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	LeftArm = CFrame.new(-1.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	HRP = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0, 0),
	LeftArm = CFrame.new(-1.5, 0, 0),
	Head = CFrame.new(0, 1.5, 0),
	HRP = CFrame.new(0, 0, 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.78s · 5 passo(s)
	GOLPE_A = {
		{ pose = "CARGA_A", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_A", time = 0.12, style = "Sine", dir = "InOut" },
		{ pose = "BATE_A", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_A", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- golpe rápido · 0.84s · 5 passo(s)
	GOLPE_B = {
		{ pose = "CARGA_B", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CARGA_B", time = 0.14, style = "Sine", dir = "InOut" },
		{ pose = "BATE_B", time = 0.1, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_B", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada · 1.56s · 6 passo(s)
	REBATER = {
		{ pose = "ERGUE", time = 0.18, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "ERGUE", time = 0.44, style = "Sine", dir = "InOut", tremor = 0.03, freq = 20, marca = "SEGURA" },
		{ pose = "ERGUE", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.04, freq = 24, marca = "SEGURA" },
		{ pose = "BATE_B", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_B", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
