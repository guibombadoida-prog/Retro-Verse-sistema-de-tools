-- Poses.lua
-- ModuleScript "Poses" — Samsungus  (conjunto REALITY GUI)
--
-- ⚠️ A ANIMAÇÃO DA ORIGEM, LIDA DO SCRIPT DELA.
--
-- Ela está escrita em laço, no idioma que o Guest já tinha ensinado:
--
--     for i = 0,1 , 0.14 do
--         weld.C0 = weld.C0:lerp(<ALVO>, i)
--         step:wait()
--     end
--
-- `i` varre até 1, então a pose ESCRITA é a pose ALCANÇADA — dá para
-- ler o alvo direto. A duração sai do laço: `ceil(1/passo)+1` voltas
-- de `Stepped`, a 1/60 s cada.
--
-- O alvo entra VERBATIM: já é Lua válido, e copiar o texto não tem
-- erro de arredondamento. Só o C1 da origem entra como sufixo
-- INVERTIDO — ver a conta em `extrair_welds_reality.py`.
--
-- A primeira versão desta Tool inventou pose. Não precisava.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6).
--
-- Gerado por FERRAMENTAS/gerar_poses_reality.py.

local P = {}


P.BATIDA_A_0 = {
	RightArm = CFrame.new(0,-0.1,0) * CFrame.new(1.43301249, 0.884340763, -0.405934334, 0.866025448, 7.4505806e-09, -0.499999762, -0.171009988, -0.939692438, -0.296198189, -0.469846129, 0.342020154, -0.813797832) * CFrame.fromEulerAnglesXYZ(0,0,0) * CFrame.new(0, -0.5, 0),
	LeftArm = CFrame.new(0.5,0.5,0) * CFrame.new(-1.96153116, 0.131953716, 0, 0.766044378, 0.642787516, -2.98023224e-08, -0.642787516, 0.766044378, 0, -2.98023224e-08, 1.49011612e-08, 0.99999994) * CFrame.new(0, -0.5, 0),
	Head = CFrame.new(0,-0.5,0) * CFrame.new(-0.0815877914, 1.49240351, -0.0296964645, 0.342020094, -0.163175687, 0.92541647, -1.45519152e-09, 0.98480773, 0.17364797, -0.939692557, -0.0593911, 0.336824089) * CFrame.new(0, 0.5, 0),
	HRP = CFrame.new(0, 0, 0, 0.33682403, 0.0593911596, -0.939692616, -0.173648149, 0.98480773, 0, 0.925416529, 0.163175896, 0.342020094),
}

P.BATIDA_A_1 = {
	RightArm = CFrame.new(0,0.4,0.3) * CFrame.new(1.88293552, 0.2333498, -0.433140755, 0.859446883, -0.503111184, -0.0907213986, 0.308427513, 0.651808023, -0.692833483, 0.407705337, 0.567472816, 0.715367913) * CFrame.fromEulerAnglesXYZ(0,0,0) * CFrame.new(0, -0.5, 0),
	LeftArm = CFrame.new(0.5,0.5,0) * CFrame.new(-1.96153116, 0.131953716, 0, 0.766044378, 0.642787516, -2.98023224e-08, -0.642787516, 0.766044378, 0, -2.98023224e-08, 1.49011612e-08, 0.99999994) * CFrame.new(0, -0.5, 0),
	Head = CFrame.new(0,-0.5,0) * CFrame.new(-0.0406684875, 1.4979527, 0.0197181702, 0.649181902, -0.0813359022, -0.756272018, 0.0229108427, 0.995905817, -0.0874414966, 0.76028806, 0.0394386649, 0.648387671) * CFrame.new(0, 0.5, 0),
	HRP = CFrame.new(0, 0, 0, 0.645385742, -0.0593911596, 0.761544466, -0.0868240744, 0.98480767, 0.150383741, -0.758906364, -0.163175881, 0.630424261),
}

P.BATIDA_B_0 = {
	RightArm = CFrame.new(0,0,0.5) * CFrame.new(1.11058283, 0.534516811, -1.14242649, 0.133022264, 0.395739019, 0.908677936, 0.991084576, -0.0600325875, -0.118940994, 0.00748064928, 0.916398764, -0.400196671) * CFrame.fromEulerAnglesXYZ(0,0,0) * CFrame.new(0, -0.5, 0),
	LeftArm = CFrame.new(0.5,0.5,0) * CFrame.new(-1.96153116, 0.131953716, 0, 0.766044378, 0.642787516, -2.98023224e-08, -0.642787516, 0.766044378, 0, -2.98023224e-08, 1.49011612e-08, 0.99999994) * CFrame.new(0, -0.5, 0),
	Head = CFrame.new(0,-0.5,0) * CFrame.new(-2.38418579e-07, 1.49999952, 9.53674316e-07, 0.49999994, 2.60770321e-08, -0.866025388, -1.02445483e-08, 0.999999821, -3.35276127e-08, 0.866025567, -1.49011612e-08, 0.49999994) * CFrame.new(0, 0.5, 0),
	HRP = CFrame.new(0, 0, 0, 0.342020303, 0.163175672, 0.925416589, 4.47034836e-08, 0.98480773, -0.17364797, -0.939692557, 0.0593911409, 0.336824268),
}

P.BATIDA_B_1 = {
	RightArm = CFrame.new(0,0.7,0.3) * CFrame.new(1.94078016, 0.420045853, -0.739268303, 0.133022189, -0.718527198, 0.682659388, 0.991084456, 0.0912356675, -0.0970924273, 0.00748063065, 0.689488888, 0.724257588) * CFrame.fromEulerAnglesXYZ(0,0,0) * CFrame.new(0, -0.5, 0),
	LeftArm = CFrame.new(0.7,0,0) * CFrame.new(-2.05798006, 0.156598568, 9.53674316e-07, 0.50000006, 0.866025329, -5.96046448e-08, -0.86602509, 0.499999821, -1.11758709e-08, -4.47034836e-08, -8.94069672e-08, 1) * CFrame.new(0, -0.5, 0),
	Head = CFrame.new(0,-0.5,0) * CFrame.new(0, 1.49999905, 0, 0.342020094, -6.70552254e-08, 0.939692616, -1.10594556e-08, 0.999999702, -6.70552254e-08, -0.939692676, -1.11758709e-08, 0.342019945) * CFrame.new(0, 0.5, 0),
	HRP = CFrame.new(0, 0, 0, 0.356122136, 0.10289897, -0.928756654, 0.0610870048, 0.989228606, 0.133022025, 0.932440579, -0.104107097, 0.346000373),
}

P.REPOUSO = {
	RightArm = CFrame.new(1.5,0.5,0) * CFrame.fromEulerAnglesXYZ(math.rad(45), math.rad(-2.5), math.rad(-10)) * CFrame.new(0, -0.5, 0),
	LeftArm = CFrame.new(-1.5,0.5,0) * CFrame.fromEulerAnglesXYZ(math.rad(55), 0, math.rad(10)) * CFrame.new(0, -0.5, 0),
	Head = CFrame.new(0,1,0) * CFrame.new(0, 0.5, 0),
	HRP = CFrame.new(0,0,0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.55s · 3 passo(s), da origem
	BATIDA_A = {
		{ pose = "BATIDA_A_0", time = 0.15, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BATIDA_A_1", time = 0.183, style = "Quint", dir = "Out", marca = "SOPRO" },
		{ pose = "REPOUSO", time = 0.22, style = "Quad", dir = "Out", marca = "GOLPE" },
	},

	-- golpe rápido · 0.55s · 3 passo(s), da origem
	BATIDA_B = {
		{ pose = "BATIDA_B_0", time = 0.15, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BATIDA_B_1", time = 0.183, style = "Quint", dir = "Out", marca = "SOPRO" },
		{ pose = "REPOUSO", time = 0.22, style = "Quad", dir = "Out", marca = "GOLPE" },
	},

}

return P
