-- Poses_Titan_V1.lua
-- ModuleScript "Poses" — Titan Antena  (conjunto TITAN)
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

P.ANTENA_ALTA = {
	RightArm = CFrame.new(1.5, 0.9, 0.06) * CFrame.Angles(math.rad(-172), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.48, 0.08, -0.14) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(-6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.CHICOTE = {
	RightArm = CFrame.new(1.56, 0.34, -0.9) * CFrame.Angles(math.rad(74), math.rad(-46), math.rad(-22)),
	LeftArm = CFrame.new(-1.46, 0.1, -0.2) * CFrame.Angles(math.rad(18), math.rad(12), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(38), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(0), math.rad(-44), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(3)),
	LeftArm = CFrame.new(-1.5, 0.02, -0.06) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(-3)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
}

P.CRAVA = {
	RightArm = CFrame.new(1.48, -0.42, -0.36) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(6)),
	LeftArm = CFrame.new(-1.44, -0.16, -0.4) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.42, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.64, -0.48) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.86, 0.24) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.MAOS_NA_TELA = {
	RightArm = CFrame.new(1.28, 0.72, -0.34) * CFrame.Angles(math.rad(140), math.rad(-22), math.rad(-34)),
	LeftArm = CFrame.new(-1.28, 0.72, -0.34) * CFrame.Angles(math.rad(140), math.rad(22), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- mecânico — 0.75 s
	CHICOTE = {
		{ pose = "ANTENA_ALTA", time = 0.12, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CHICOTE", time = 0.09, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CHICOTE", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- servo — 1.15 s
	TORRE = {
		{ pose = "ANTENA_ALTA", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ANTENA_ALTA", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.032, freq = 25, marca = "SEGURA" },
		{ pose = "CRAVA", time = 0.11, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "CRAVA", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.38, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- varredura — 1.45 s
	INTERFERENCIA = {
		{ pose = "MAOS_NA_TELA", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "MAOS_NA_TELA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.024, freq = 31, marca = "SEGURA" },
		{ pose = "MAOS_NA_TELA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.024, freq = 31 },
		{ pose = "MAOS_NA_TELA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
