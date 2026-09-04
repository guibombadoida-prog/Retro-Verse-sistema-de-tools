-- Poses_Titan_V1.lua
-- ModuleScript "Poses" — Titan Lamina  (conjunto TITAN)
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
-- ESTA TOOL LIDERA POR `HRP`.
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

P.ESPADA_ALTA = {
	RightArm = CFrame.new(1.42, 0.84, -0.04) * CFrame.Angles(math.rad(174), math.rad(-8), math.rad(-14)),
	LeftArm = CFrame.new(-1.42, 0.84, -0.04) * CFrame.Angles(math.rad(174), math.rad(8), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.ESPADA_DESCE = {
	RightArm = CFrame.new(1.44, -0.3, -0.88) * CFrame.Angles(math.rad(14), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.44, -0.3, -0.88) * CFrame.Angles(math.rad(14), math.rad(6), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.48, 0) * CFrame.Angles(math.rad(36), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.54, -0.58) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.54, -0.58) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
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

P.ESTOCA = {
	RightArm = CFrame.new(1.5, 0.16, -1.34) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.42, -0.02, -0.24) * CFrame.Angles(math.rad(16), math.rad(10), math.rad(-16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(14), math.rad(8), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.7, 0.56) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.88, -0.48) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- mecânico — 0.75 s
	CORTE = {
		{ pose = "ESPADA_ALTA", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESPADA_DESCE", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESPADA_DESCE", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- mecânico — 0.75 s
	ESTOCADA = {
		{ pose = "TRAVA_PEITO", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESTOCA", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESTOCA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- servo — 1.15 s
	DESCENDENTE = {
		{ pose = "ESPADA_ALTA", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESPADA_ALTA", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.042, freq = 26, marca = "SEGURA" },
		{ pose = "ESPADA_DESCE", time = 0.11, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ESPADA_DESCE", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.38, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
