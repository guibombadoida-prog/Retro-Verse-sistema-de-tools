-- Poses_Titan_V1.lua
-- ModuleScript "Poses" — Titan Estatica  (conjunto TITAN)
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

P.TELA_FRENTE = {
	RightArm = CFrame.new(1.44, 0.46, -0.76) * CFrame.Angles(math.rad(100), math.rad(-14), math.rad(-8)),
	LeftArm = CFrame.new(-1.44, 0.46, -0.76) * CFrame.Angles(math.rad(100), math.rad(14), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
}

P.BATE_TELA = {
	RightArm = CFrame.new(1.46, -0.36, -0.5) * CFrame.Angles(math.rad(12), math.rad(-6), math.rad(-6)),
	LeftArm = CFrame.new(-1.46, -0.36, -0.5) * CFrame.Angles(math.rad(12), math.rad(6), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.7, -0.36) * CFrame.Angles(math.rad(-24), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.7, -0.36) * CFrame.Angles(math.rad(-24), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(3)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
}

P.TRAVA_PEITO = {
	RightArm = CFrame.new(1.24, 0.3, -0.4) * CFrame.Angles(math.rad(92), math.rad(-30), math.rad(-50)),
	LeftArm = CFrame.new(-1.24, 0.3, -0.4) * CFrame.Angles(math.rad(92), math.rad(30), math.rad(50)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- mecânico — 0.75 s
	GOLPE_TELA = {
		{ pose = "TELA_FRENTE", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "BATE_TELA", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "BATE_TELA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- varredura — 1.45 s
	CHUVISCO = {
		{ pose = "TELA_FRENTE", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "TELA_FRENTE", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.026, freq = 32, marca = "SEGURA" },
		{ pose = "TELA_FRENTE", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.026, freq = 32 },
		{ pose = "TELA_FRENTE", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- varredura — 1.45 s
	ESPELHO = {
		{ pose = "TRAVA_PEITO", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "TRAVA_PEITO", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.018, freq = 34, marca = "SEGURA" },
		{ pose = "TRAVA_PEITO", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.018, freq = 34 },
		{ pose = "TRAVA_PEITO", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
