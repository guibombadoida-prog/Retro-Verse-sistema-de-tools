-- Poses_Titan_V1.lua
-- ModuleScript "Poses" — Titan Raio Catodico  (conjunto TITAN)
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — nenhuma pose daqui deve ser aplicada fora de sequência.
--
-- ESTA TOOL LIDERA POR `RightArm`.
--
-- A GRAMÁTICA É DE MÁQUINA, NÃO DE CORPO
--
--   Carga CURTA e recuo LONGO — o oposto do conjunto JUPITER. Corpo pesado se
--   move devagar no percurso inteiro; máquina fica parada e SALTA, e o peso
--   dela está na inércia de PARAR. Os cotovelos ficam travados: onde uma pose
--   humana curva o braço, estas giram o ombro inteiro.
--
--   O tremor é CONSTANTE, não crescente: num tubo de raios catódicos ele é a
--   frequência da varredura, e varredura não cansa.
--
-- Gerado por FERRAMENTAS/gerar_poses_titan.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local P = {}

P.TRAVA_PEITO = {
	RightArm = CFrame.new(1.24, 0.3, -0.4) * CFrame.Angles(math.rad(92), math.rad(-30), math.rad(-50)),
	LeftArm = CFrame.new(-1.24, 0.3, -0.4) * CFrame.Angles(math.rad(92), math.rad(30), math.rad(50)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
}

P.APONTA = {
	RightArm = CFrame.new(1.5, 0.12, -1.3) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.5, 0.04, -0.1) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(8), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(3)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
}

P.ABRE_LEQUE = {
	RightArm = CFrame.new(1.6, 0.24, -0.5) * CFrame.Angles(math.rad(62), math.rad(0), math.rad(-54)),
	LeftArm = CFrame.new(-1.6, 0.24, -0.5) * CFrame.Angles(math.rad(62), math.rad(0), math.rad(54)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- mecânico — 0.75 s
	FAISCA = {
		{ pose = "TRAVA_PEITO", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "APONTA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- varredura — 1.45 s
	FEIXE = {
		{ pose = "APONTA", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "APONTA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.02, freq = 33, marca = "SEGURA" },
		{ pose = "APONTA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.02, freq = 33 },
		{ pose = "APONTA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- servo — 1.15 s
	LEQUE = {
		{ pose = "TRAVA_PEITO", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "TRAVA_PEITO", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.028, freq = 29, marca = "SEGURA" },
		{ pose = "ABRE_LEQUE", time = 0.11, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ABRE_LEQUE", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.38, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
