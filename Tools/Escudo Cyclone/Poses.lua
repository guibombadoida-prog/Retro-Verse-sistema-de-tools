-- Poses.lua
-- ModuleScript "Poses" — Escudo Cyclone
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama ReleaseLegs
-- ao fim de toda sequência. Perna soldada permanentemente trava a caminhada.
--
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, os sete escudos dividiam o mesmo
-- arquivo de 440 linhas — este traz só o que esta Tool usa.
--
-- As SILHUETAS são as da remasterização e não mudaram: é a mesma habilidade,
-- do mesmo modelo. O que mudou foi o TEMPO, re-cronometrado pela gramática
-- medida no pack de referência (ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md).
--
-- O que a gramática impôs aqui:
--   CICLONE_INVOCA       invocação              1.05s · impacto 59% · 1 segurado(s)
--   CICLONE_PUXA         golpe rápido           0.85s · impacto 59% · 1 segurado(s)
--   DOMINIO              transformação (2:98)   1.58s · impacto 5% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.CICLONE_CARGA = { -- [20] braços fecham à frente
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2.99), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.366, 0.175, -0.67) * CFrame.Angles(math.rad(80.4), math.rad(9.91), math.rad(-57.22)),
	LeftArm = CFrame.new(-1.37, 0.281, -0.738) * CFrame.Angles(math.rad(75.31), math.rad(10.7), math.rad(12.82)),
	Head = CFrame.new(0, 1.494, -0.075) * CFrame.Angles(math.rad(-8.61), math.rad(0), math.rad(0)),
}

P.INVOCAR = { -- braços abertos, chamada dos escudos (Cyclone)
	RightArm = CFrame.new(1.55, 0.7, -0.2) * CFrame.Angles(math.rad(28), 0, math.rad(-48)),
	LeftArm = CFrame.new(-1.55, 0.7, -0.2) * CFrame.Angles(math.rad(28), 0, math.rad(48)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-8), 0, 0),
}

P.CICLONE_ABERTO = { -- [35] pico de tensão
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-5.18), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(0.639, 0.342, -1.162) * CFrame.Angles(math.rad(99.07), math.rad(0.85), math.rad(-83.96)),
	LeftArm = CFrame.new(-1.012, 0.238, -0.892) * CFrame.Angles(math.rad(86.66), math.rad(23.18), math.rad(45.14)),
	Head = CFrame.new(0, 1.5, 0.002) * CFrame.Angles(math.rad(0.26), math.rad(0), math.rad(0)),
}

P.CICLONE_GIRO = { -- [60] sustentação (loop do ciclone)
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-4.86), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(0.613, 0.304, -1.164) * CFrame.Angles(math.rad(99.79), math.rad(-0.69), math.rad(-83.96)),
	LeftArm = CFrame.new(-1.043, 0.189, -0.895) * CFrame.Angles(math.rad(85.87), math.rad(24.96), math.rad(45.01)),
	Head = CFrame.new(0, 1.5, -0.016) * CFrame.Angles(math.rad(-1.79), math.rad(0), math.rad(0)),
}

P.PUXAO_CARGA = { -- [207]
	HRP = CFrame.new(0.007, -0.11, -0.01) * CFrame.Angles(math.rad(6.62), math.rad(-20.01), math.rad(3.93)),
	RightArm = CFrame.new(1.542, 0.802, 0.402) * CFrame.Angles(math.rad(60.62), math.rad(4.82), math.rad(29.31)),
	LeftArm = CFrame.new(-1.56, 0.033, 0.23) * CFrame.Angles(math.rad(18.2), math.rad(20.13), math.rad(-18.43)),
	Head = CFrame.new(-0.017, 1.462, -0.19) * CFrame.Angles(math.rad(-22.93), math.rad(16.71), math.rad(2.06)),
}

P.PUXAO_SOLTA = { -- [365]
	HRP = CFrame.new(-0.188, -0.18, -0.261) * CFrame.Angles(math.rad(21.38), math.rad(-27.02), math.rad(10.08)),
	RightArm = CFrame.new(1.385, 0.87, -0.542) * CFrame.Angles(math.rad(98.93), math.rad(0), math.rad(-11.97)),
	LeftArm = CFrame.new(-1.553, 0.08, 0.475) * CFrame.Angles(math.rad(-6.87), math.rad(33.88), math.rad(-25.37)),
	Head = CFrame.new(0, 1.473, -0.163) * CFrame.Angles(math.rad(-18.99), math.rad(11.95), math.rad(0)),
}

P.DOMINIO_ABERTO = { -- domaint1 t=0.2667: abertura total, cabeça para cima
	HRP = CFrame.new(0, 0, 0),
	RightArm = CFrame.new(0.978, 0.374, -0.695) * CFrame.Angles(math.rad(75.35), math.rad(44.15), math.rad(-19.69)),
	LeftArm = CFrame.new(-1.004, 0.367, -0.695) * CFrame.Angles(math.rad(75.69), math.rad(-41.93), math.rad(19.58)),
	RightLeg = CFrame.new(0.585, -2.038, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(4.76)),
	LeftLeg = CFrame.new(-0.590, -2.040, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-5.06)),
	Head = CFrame.new(0, 1.492, -0.090) * CFrame.Angles(math.rad(-10.43), math.rad(0), math.rad(0)),
}

P.DOMINIO_SUSTENTA = { -- domaint2: pose de sustentação do domínio
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(0.978, 0.374, -0.695) * CFrame.Angles(math.rad(75.35), math.rad(44.15), math.rad(-19.69)),
	LeftArm = CFrame.new(-1.004, 0.367, -0.695) * CFrame.Angles(math.rad(75.69), math.rad(-41.93), math.rad(19.58)),
	RightLeg = CFrame.new(0.585, -2.038, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(4.76)),
	Head = CFrame.new(0, 1.492, -0.090) * CFrame.Angles(math.rad(-10.43), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- invocação · 1.05s · 5 passo(s), 1 segurado(s)
	CICLONE_INVOCA = {
		{ pose = "CICLONE_CARGA", time = 0.22, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CICLONE_CARGA", time = 0.28, style = "Sine", dir = "InOut" },
		{ pose = "INVOCAR", time = 0.12, style = "Quint", dir = "Out", tremor = 0.045, freq = 28, marca = "INVOCAR" },
		{ pose = "CICLONE_ABERTO", time = 0.16, style = "Quad", dir = "Out", marca = "ABRIR" },
		{ pose = "CICLONE_GIRO", time = 0.27, style = "Sine", dir = "InOut" },
	},

	-- golpe rápido · 0.85s · 4 passo(s), 1 segurado(s)
	CICLONE_PUXA = {
		{ pose = "PUXAO_CARGA", time = 0.18, style = "Back", dir = "In" },
		{ pose = "PUXAO_CARGA", time = 0.24, style = "Sine", dir = "InOut" },
		{ pose = "PUXAO_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "PUXAR" },
		{ pose = "CICLONE_GIRO", time = 0.35, style = "Quad", dir = "Out" },
	},

	-- transformação (2:98) · 1.58s · 4 passo(s), 1 segurado(s)
	DOMINIO = {
		{ pose = "DOMINIO_ABERTO", time = 0.08, style = "Quint", dir = "Out", marca = "EXPANDIR" },
		{ pose = "DOMINIO_SUSTENTA", time = 0.6, style = "Sine", dir = "InOut", tremor = 0.03, freq = 18, marca = "SUSTENTAR" },
		{ pose = "DOMINIO_SUSTENTA", time = 0.5, style = "Sine", dir = "InOut" },
		{ pose = "CICLONE_GIRO", time = 0.4, style = "Sine", dir = "InOut" },
	},

}

return P
