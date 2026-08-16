-- Poses.lua
-- ModuleScript "Poses" — Canhao Satelite  (conjunto REALITY GUI)
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


P.ORBITA_0 = {
	RightArm = CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,-math.rad(45)) * CFrame.new(0,-0.6,0),
	Head = CFrame.new(0,1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0,0.5,0),
}

P.ORBITA_1 = {
	RightArm = CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,-math.rad(45)) * CFrame.new(0,-0.6,0),
	Head = CFrame.new(0,1,0) * CFrame.Angles(math.rad(-10),0,0) * CFrame.new(0,0.5,0),
}

P.ORBITA_2 = {
	RightArm = CFrame.new(1.5,0.25,0) * CFrame.Angles(math.pi/2+math.rad(40),0,-math.rad(20)) * CFrame.new(0,-0.5,0),
	Head = CFrame.new(0,1,0) * CFrame.Angles(math.rad(-15),math.rad(15),0) * CFrame.new(0,0.5,0),
}

P.ORBITA_3 = {
	RightArm = CFrame.new(1.5,0.25,0) * CFrame.Angles(math.pi/2+math.rad(40),0,-math.rad(20)) * CFrame.new(0,-0.5,0),
	Head = CFrame.new(0,1,0) * CFrame.Angles(math.rad(-15),math.rad(15),0) * CFrame.new(0,0.5,0),
}

P.ORBITA_4 = {
	RightArm = CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,0) * CFrame.new(0,-0.5,0),
	Head = CFrame.new(0,1.5,0),
}

P.REPOUSO = {
	RightArm = CFrame.new(1.5,0.5,0) * CFrame.Angles(math.pi/2,0,0) * CFrame.new(0,-0.5,0),
	Head = CFrame.new(0,1.5,0),
}

P.SEQUENCIAS = {

	-- ultimate · 6.95s · 6 passo(s), da origem
	ORBITA = {
		{ pose = "ORBITA_0", time = 0.683, style = "Sine", dir = "InOut", marca = "CAMERA" },
		{ pose = "ORBITA_1", time = 2.5, style = "Sine", dir = "InOut", marca = "CARGA" },
		{ pose = "ORBITA_2", time = 0.683, style = "Sine", dir = "InOut", marca = "SEGURA" },
		{ pose = "ORBITA_3", time = 1.5, style = "Sine", dir = "InOut", marca = "DESCE" },
		{ pose = "ORBITA_4", time = 0.683, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "REPOUSO", time = 0.9, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
