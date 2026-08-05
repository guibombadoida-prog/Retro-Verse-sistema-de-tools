-- Poses_Escudos_V1.lua
-- ModuleScript "Poses" — família ESCUDOS (Salvador, Proteção, Skate,
-- Bumerangue, Bloqueador, Cyclone, Partido)
--
-- ORIGEM DAS POSES (§12.12 / §12.16)
--   Material: SaitamaAnimacoes_Originais_V1 (pack de referência R6 CFrame).
--   Passe de conformidade: keyframes lidos como DADO, convertidos em poses
--   estáticas para R6CFrameAnimator. Zero LoadAnimation, zero Animation asset,
--   zero lógica de combate importada. Só silhueta e timing.
--
--   Mapa keyframe -> pose:
--     NORMAL_SHOVE        [12][23][30]  -> ARREMESSO_CARGA / SOLTA / RECUO
--     NORMAL_UPPERCUT     [27][34]      -> SACRIFICIO_CARGA / SACRIFICIO_ALTO
--     CONSECUTIVE_PUNCHES [8][24][31][44][57][70] -> CORTE_A..CORTE_F
--     SERIOUS_MODE        [20][35][60]  -> CICLONE_CARGA / ABERTO / GIRO
--     DEATH_COUNTER       [120][359]    -> GUARDA_FIRME / CONTRA_GOLPE
--     TABLE_FLIP          [207][365]    -> PUXAO_CARGA / PUXAO_SOLTA
--     SERIOUS_PUNCH       [85][180][260][298][349] -> EXEC_*
--     SERIOUS_PUNCH_CAMERA (amostrado)  -> CAMERA_EXECUCAO
--
-- Base de Weld idêntica à do R6CFrameAnimator (V1/V2):
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP identidade
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)

local P = {}

--═══════════════════════════════════════════════════════════════
-- 1. POSES BASE — comuns a toda a família
--═══════════════════════════════════════════════════════════════

-- IDLE original dos escudos (corpo virado ~10°, escudo à frente).
-- Valores preservados do ServerScript_EscudoBloqueador_V5.
P.IDLE = {
	RightArm = CFrame.new(
		1.40557981, 0.499999762, -0.579227924,
		0.98480767, 0.173648134, 0,
		0, 0, -0.999999821,
		-0.173648134, 0.98480767, 0
	),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(6), 0, math.rad(6)),
	Head = CFrame.new(
		0, 1.49999976, 0,
		0.173648208, 0, -0.98480767,
		0, 0.999999881, 0,
		0.98480767, 0, 0.173648208
	),
	HRP = CFrame.new(
		0, 0, 0,
		0.173648134, 0, 0.98480773,
		0, 0.99999994, 0,
		-0.98480773, 0, 0.173648134
	),
}

-- Guarda firme — DEATH_COUNTER [120]: peso no tronco, escudo colado à frente.
P.GUARDA_FIRME = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-18.28), math.rad(-39.56), math.rad(-11.01)),
	RightArm = CFrame.new(1.564, 0.422, -0.017) * CFrame.Angles(math.rad(72.6), math.rad(4.68), math.rad(22.04)),
	LeftArm = CFrame.new(-1.566, 0.077, -0.035) * CFrame.Angles(math.rad(3.89), math.rad(-0.68), math.rad(-8.11)),
	Head = CFrame.new(0, 1.466, -0.182) * CFrame.Angles(math.rad(-21.4), math.rad(-0.85), math.rad(0.03)),
}

-- Contra-golpe — DEATH_COUNTER [359]: rotação de tronco que vende a força.
P.CONTRA_GOLPE = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-20.13), math.rad(37.64), math.rad(16.46)),
	RightArm = CFrame.new(1.443, 0.234, 0.652) * CFrame.Angles(math.rad(99.58), math.rad(-2.93), math.rad(65.63)),
	LeftArm = CFrame.new(-1.659, 0.316, 0.178) * CFrame.Angles(math.rad(12.43), math.rad(17.95), math.rad(-33.49)),
	Head = CFrame.new(0.058, 1.496, -0.013) * CFrame.Angles(math.rad(-4.57), math.rad(-24.32), math.rad(-7.31)),
}

--═══════════════════════════════════════════════════════════════
-- 2. ARREMESSO — NORMAL_SHOVE (Bumerangue / Partido)
--═══════════════════════════════════════════════════════════════

P.ARREMESSO_CARGA = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-180), math.rad(75.6), math.rad(180)),
	RightArm = CFrame.new(0.95, 0.482, -0.945) * CFrame.Angles(math.rad(90.19), math.rad(2.32), math.rad(-46.57)),
	LeftArm = CFrame.new(-1.31, -0.135, 0.036) * CFrame.Angles(math.rad(-1.36), math.rad(3.89), math.rad(18.95)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-77.85), math.rad(0)),
}

-- Frame de impacto do pack (índice 23). É aqui que o projétil sai.
P.ARREMESSO_SOLTA = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-180), math.rad(69.16), math.rad(180)),
	RightArm = CFrame.new(0.756, 0.649, -1.012) * CFrame.Angles(math.rad(98.73), math.rad(-5.51), math.rad(-65.76)),
	LeftArm = CFrame.new(-1.323, -0.122, 0.092) * CFrame.Angles(math.rad(-3.39), math.rad(9.68), math.rad(17.38)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-82.49), math.rad(0)),
}

P.ARREMESSO_RECUO = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(78.95), math.rad(0)),
	RightArm = CFrame.new(1.807, 0.563, -0.447) * CFrame.Angles(math.rad(96.02), math.rad(-0.36), math.rad(13.17)),
	LeftArm = CFrame.new(-1.546, 0.051, -0.01) * CFrame.Angles(math.rad(-0.07), math.rad(-1.11), math.rad(-5.6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-65.52), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- 3. SACRIFÍCIO — NORMAL_UPPERCUT (Salvador)
--═══════════════════════════════════════════════════════════════

P.SACRIFICIO_CARGA = {
	HRP = CFrame.new(0.012, -0.038, 0.048) * CFrame.Angles(math.rad(-39.13), math.rad(-31.46), math.rad(-14.97)),
	RightArm = CFrame.new(1.73, 0.007, -0.191) * CFrame.Angles(math.rad(20.45), math.rad(4.51), math.rad(31.9)),
	LeftArm = CFrame.new(-1.52, -0.154, 0.317) * CFrame.Angles(math.rad(26.35), math.rad(12.04), math.rad(-8.3)),
	Head = CFrame.new(0.036, 1.457, 0.199) * CFrame.Angles(math.rad(26.7), math.rad(38), math.rad(-5.2)),
}

P.SACRIFICIO_ALTO = {
	HRP = CFrame.new(0.085, 0.336, -0.174) * CFrame.Angles(math.rad(102.99), math.rad(62.95), math.rad(-91.13)),
	RightArm = CFrame.new(1.774, 1.715, -0.269) * CFrame.Angles(math.rad(-30.91), math.rad(-37.17), math.rad(164.04)),
	LeftArm = CFrame.new(-1.648, 0.092, 0.41) * CFrame.Angles(math.rad(38.8), math.rad(10.33), math.rad(-33.88)),
	Head = CFrame.new(0.097, 1.453, -0.188) * CFrame.Angles(math.rad(-60.03), math.rad(-72.08), math.rad(-38.9)),
}

--═══════════════════════════════════════════════════════════════
-- 4. CORTES — CONSECUTIVE_PUNCHES (Partido, melee)
--═══════════════════════════════════════════════════════════════

P.CORTE_A = { -- [8] carga curta
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-6.97), math.rad(1.72), math.rad(2.47)),
	RightArm = CFrame.new(1.648, 0.353, -0.45) * CFrame.Angles(math.rad(85.81), math.rad(11.16), math.rad(-2.5)),
	LeftArm = CFrame.new(-1.591, 0.359, 0.528) * CFrame.Angles(math.rad(52.74), math.rad(-1.49), math.rad(-51.85)),
	Head = CFrame.new(0.026, 1.499, -0.001) * CFrame.Angles(math.rad(-0.03), math.rad(1.3), math.rad(-2.94)),
}

P.CORTE_B = { -- [24] corte descendente
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-25.94), math.rad(-34.21), math.rad(-11.18)),
	RightArm = CFrame.new(1.412, 0.635, -0.466) * CFrame.Angles(math.rad(120.14), math.rad(17.49), math.rad(0.43)),
	LeftArm = CFrame.new(-1.52, 0.803, -1.489) * CFrame.Angles(math.rad(107.06), math.rad(-3.02), math.rad(-28.56)),
	Head = CFrame.new(-0.011, 1.495, 0.072) * CFrame.Angles(math.rad(7.57), math.rad(28.91), math.rad(1.39)),
}

P.CORTE_C = { -- [31] corte alto
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-32.63), math.rad(-7.69), math.rad(-8.35)),
	RightArm = CFrame.new(1.38, 1.053, -0.632) * CFrame.Angles(math.rad(136.61), math.rad(19.06), math.rad(-2.27)),
	LeftArm = CFrame.new(-1.813, 0.573, -1.182) * CFrame.Angles(math.rad(113.48), math.rad(-5.17), math.rad(-14.42)),
	Head = CFrame.new(0.012, 1.49, 0.097) * CFrame.Angles(math.rad(11.47), math.rad(12.46), math.rad(-1.41)),
}

P.CORTE_D = { -- [44] transversal
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.19), math.rad(-30.08), math.rad(-13.12)),
	RightArm = CFrame.new(1.159, 0.819, -0.625) * CFrame.Angles(math.rad(134.11), math.rad(16.88), math.rad(-14.85)),
	LeftArm = CFrame.new(-1.875, 0.744, -1.164) * CFrame.Angles(math.rad(119.59), math.rad(-9.75), math.rad(-32.31)),
	Head = CFrame.new(0.005, 1.498, 0.047) * CFrame.Angles(math.rad(5.8), math.rad(31.66), math.rad(-0.68)),
}

P.CORTE_E = { -- [57] retorno
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-25.02), math.rad(-34.36), math.rad(-10.66)),
	RightArm = CFrame.new(1.254, 0.655, -0.599) * CFrame.Angles(math.rad(120.14), math.rad(17.49), math.rad(-16.44)),
	LeftArm = CFrame.new(-1.772, 0.912, -1.177) * CFrame.Angles(math.rad(134.81), math.rad(-16.72), math.rad(-26.54)),
	Head = CFrame.new(-0.037, 1.498, 0.024) * CFrame.Angles(math.rad(-0.12), math.rad(33.98), math.rad(5.11)),
}

P.CORTE_F = { -- [70] abertura reversa
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-24.83), math.rad(43.09), math.rad(15.3)),
	RightArm = CFrame.new(1.883, 0.722, -0.885) * CFrame.Angles(math.rad(91.4), math.rad(19.63), math.rad(33.13)),
	LeftArm = CFrame.new(-1.729, 0.313, -0.144) * CFrame.Angles(math.rad(60.51), math.rad(-2.69), math.rad(-26.59)),
	Head = CFrame.new(0.035, 1.493, 0.075) * CFrame.Angles(math.rad(5.82), math.rad(-34.64), math.rad(-4.93)),
}

--═══════════════════════════════════════════════════════════════
-- 5. CICLONE — SERIOUS_MODE (Cyclone)
--═══════════════════════════════════════════════════════════════

P.CICLONE_CARGA = { -- [20] braços fecham à frente
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2.99), math.rad(0), math.rad(0)),
	RightArm = CFrame.new(1.366, 0.175, -0.67) * CFrame.Angles(math.rad(80.4), math.rad(9.91), math.rad(-57.22)),
	LeftArm = CFrame.new(-1.37, 0.281, -0.738) * CFrame.Angles(math.rad(75.31), math.rad(10.7), math.rad(12.82)),
	Head = CFrame.new(0, 1.494, -0.075) * CFrame.Angles(math.rad(-8.61), math.rad(0), math.rad(0)),
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

--═══════════════════════════════════════════════════════════════
-- 6. PUXÃO — TABLE_FLIP (Cyclone, tração dos alvos)
--═══════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════
-- 7. EXECUÇÃO — SERIOUS_PUNCH (Partido, cutscene)
--    Usa pernas: o Animator cria os Welds sob demanda e libera no fim.
--═══════════════════════════════════════════════════════════════

P.EXEC_POSTURA = { -- [85] postura baixa, peso no pé de trás
	HRP = CFrame.new(0.087, -0.246, 0.013) * CFrame.Angles(math.rad(-0.51), math.rad(-8.57), math.rad(-0.43)),
	RightArm = CFrame.new(1.012, 0.09, -0.47) * CFrame.Angles(math.rad(97.98), math.rad(-44.97), math.rad(-38.22)),
	LeftArm = CFrame.new(-1.529, 0, 0.14) * CFrame.Angles(math.rad(0.34), math.rad(25.29), math.rad(-4.26)),
	RightLeg = CFrame.new(0.718, -1.988, 0.092) * CFrame.Angles(math.rad(-20.97), math.rad(-14.02), math.rad(10.14)),
	LeftLeg = CFrame.new(-0.56, -1.815, -0.323) * CFrame.Angles(math.rad(3.1), math.rad(5.2), math.rad(-3.91)),
	Head = CFrame.new(-0.102, 1.477, -0.112) * CFrame.Angles(math.rad(-16.48), math.rad(15.39), math.rad(12.21)),
}

P.EXEC_AVANCO = { -- [180] arranque
	HRP = CFrame.new(0.112, -0.539, 1.312) * CFrame.Angles(math.rad(-46.14), math.rad(-57.57), math.rad(-31.86)),
	RightArm = CFrame.new(1.35, 0.488, -0.194) * CFrame.Angles(math.rad(102.27), math.rad(20.9), math.rad(5.59)),
	LeftArm = CFrame.new(-1.708, 0.402, -0.657) * CFrame.Angles(math.rad(75.16), math.rad(-24.42), math.rad(-20.3)),
	RightLeg = CFrame.new(0.747, -1.747, -0.442) * CFrame.Angles(math.rad(5.87), math.rad(-24.24), math.rad(16.57)),
	LeftLeg = CFrame.new(-0.899, -1.149, -1.12) * CFrame.Angles(math.rad(39.07), math.rad(15.89), math.rad(-21)),
	Head = CFrame.new(-0.145, 1.478, -0.021) * CFrame.Angles(math.rad(-13.58), math.rad(32.34), math.rad(20.08)),
}

P.EXEC_CORTE1 = { -- [260] primeiro corte (tronco a -147°)
	HRP = CFrame.new(-0.024, -0.822, 1.275) * CFrame.Angles(math.rad(-147.03), math.rad(-50.21), math.rad(-131.38)),
	RightArm = CFrame.new(1.373, 0.272, 0.673) * CFrame.Angles(math.rad(99.93), math.rad(-2.37), math.rad(62.7)),
	LeftArm = CFrame.new(-1.254, 0.531, -0.737) * CFrame.Angles(math.rad(121.9), math.rad(-44.4), math.rad(4.03)),
	RightLeg = CFrame.new(0.653, -1.385, -1.125) * CFrame.Angles(math.rad(34.35), math.rad(-20.96), math.rad(4.44)),
	LeftLeg = CFrame.new(-1.443, -0.935, -0.603) * CFrame.Angles(math.rad(9.38), math.rad(39.82), math.rad(-39.23)),
	Head = CFrame.new(-0.166, 1.47, -0.038) * CFrame.Angles(math.rad(-20.39), math.rad(37.85), math.rad(24.81)),
}

P.EXEC_CORTE2 = { -- [298] segundo corte
	HRP = CFrame.new(0.116, -0.9, 0.666) * CFrame.Angles(math.rad(-75.56), math.rad(-50.75), math.rad(-55.57)),
	RightArm = CFrame.new(1.118, 0.066, 0.519) * CFrame.Angles(math.rad(134.62), math.rad(-19.51), math.rad(70.72)),
	LeftArm = CFrame.new(-1.228, 0.402, -0.595) * CFrame.Angles(math.rad(109.85), math.rad(-5.86), math.rad(33.48)),
	RightLeg = CFrame.new(1.114, -1.901, -0.595) * CFrame.Angles(math.rad(4.43), math.rad(-4.87), math.rad(23.74)),
	LeftLeg = CFrame.new(-0.576, -0.485, -1.173) * CFrame.Angles(math.rad(19.27), math.rad(33.17), math.rad(-5.14)),
	Head = CFrame.new(-0.158, 1.474, -0.007) * CFrame.Angles(math.rad(-6.12), math.rad(15.61), math.rad(19.18)),
}

P.EXEC_FINAL = { -- [349] pose de saída, costas para o alvo
	HRP = CFrame.new(0.128, -0.78, 0.544) * CFrame.Angles(math.rad(-33.55), math.rad(41.54), math.rad(22.64)),
	RightArm = CFrame.new(1.857, 1.006, -0.642) * CFrame.Angles(math.rad(96.52), math.rad(20.99), math.rad(50.91)),
	LeftArm = CFrame.new(-1.127, -0.11, 0.528) * CFrame.Angles(math.rad(143.16), math.rad(41.29), math.rad(-82.69)),
	RightLeg = CFrame.new(0.147, -1.818, 0.438) * CFrame.Angles(math.rad(-45.22), math.rad(-17.42), math.rad(-34.66)),
	LeftLeg = CFrame.new(-0.377, -0.935, -1.284) * CFrame.Angles(math.rad(33.47), math.rad(-20.96), math.rad(-0.25)),
	Head = CFrame.new(0.083, 1.493, 0) * CFrame.Angles(math.rad(-7.04), math.rad(-35.79), math.rad(-11.83)),
}

--═══════════════════════════════════════════════════════════════
-- 8. POSES AUTORAIS DE APOIO
--═══════════════════════════════════════════════════════════════

P.GUARDA = { -- barreira defensiva (Proteção)
	RightArm = CFrame.new(1.4, 0.45, -0.75) * CFrame.Angles(math.rad(70), 0, math.rad(-12)),
	LeftArm = CFrame.new(-1.45, 0.2, -0.4) * CFrame.Angles(math.rad(40), 0, math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), 0, 0),
	HRP = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(6), math.rad(8), 0),
}

P.SKATE = { -- corpo aerodinâmico, braço atrás (Skate)
	RightArm = CFrame.new(1.5, 0.15, 0.55) * CFrame.Angles(math.rad(-28), 0, math.rad(10)),
	LeftArm = CFrame.new(-1.55, 0.35, -0.5) * CFrame.Angles(math.rad(46), 0, math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
	HRP = CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(15), 0, 0),
}

P.INVOCAR = { -- braços abertos, chamada dos escudos (Cyclone)
	RightArm = CFrame.new(1.55, 0.7, -0.2) * CFrame.Angles(math.rad(28), 0, math.rad(-48)),
	LeftArm = CFrame.new(-1.55, 0.7, -0.2) * CFrame.Angles(math.rad(28), 0, math.rad(48)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), 0, 0),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-8), 0, 0),
}


--═══════════════════════════════════════════════════════════════
-- 8.5 DOMÍNIO — importado de "Domain Expansion(Elemental)" (§12.12)
--
--   Origem: KeyframeSequences "domaint1" (8 kf) e "domaint2" (1 kf).
--   Passe: as Poses eram Motor6D-relativas; convertidas para Weld.C0 pela
--   fórmula C0 = Motor.C0 * Pose.CFrame * Motor.C1:Inverse(). O keyframe de
--   repouso sai exatamente em (1.5,0,0)/(-1.5,0,0)/(0,1.5,0)/(0.5,-2,0),
--   o que confirma a conversão contra a base do R6CFrameAnimator.
--   Descartado: a inversão de tronco de 178° do domaint2 (artefato de
--   autoria do pack — girava o personagem de costas no meio do gesto).
--   Zero Animation/AnimationTrack: só a tabela de CFrames entrou.
--═══════════════════════════════════════════════════════════════

P.DOMINIO_CARGA = { -- domaint1 t=0.0333: braço direito sobe, pernas travam
	HRP = CFrame.new(0, 0, 0),
	RightArm = CFrame.new(1.500, 0.275, -0.447) * CFrame.Angles(math.rad(63.27), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.500, 0.132, -0.338) * CFrame.Angles(math.rad(42.60), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.556, -2.026, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(3.14)),
	LeftLeg = CFrame.new(-0.560, -2.028, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-3.41)),
	Head = CFrame.new(0, 1.498, -0.044) * CFrame.Angles(math.rad(-5.08), math.rad(0), math.rad(0)),
}

P.DOMINIO_MEIO = { -- domaint1 t=0.2000: braços começam a abrir
	HRP = CFrame.new(0, 0, 0),
	RightArm = CFrame.new(0.978, 0.374, -0.695) * CFrame.Angles(math.rad(75.35), math.rad(44.15), math.rad(-19.69)),
	LeftArm = CFrame.new(-1.236, 0.398, -0.659) * CFrame.Angles(math.rad(85.56), math.rad(-24.00), math.rad(14.68)),
	Head = CFrame.new(0, 1.498, -0.044) * CFrame.Angles(math.rad(-5.08), math.rad(0), math.rad(0)),
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

--═══════════════════════════════════════════════════════════════
-- 9. SEQUÊNCIAS (timelines para rig:PlaySequence)
--    { pose, time, style, dir, tremor, freq, marca }
--    'marca' é lida pelo onBeat do servidor para disparar VFX/SFX/dano.
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- Bumerangue / Partido: arremesso simples
	ARREMESSO = {
		{ pose = "ARREMESSO_CARGA",  time = 0.16, style = "Back",  dir = "In",  marca = "CARGA" },
		{ pose = "ARREMESSO_SOLTA",  time = 0.10, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO",  time = 0.18, style = "Quad",  dir = "Out" },
		{ pose = "IDLE",             time = 0.22, style = "Quad",  dir = "Out" },
	},

	-- Bumerangue: arremesso carregado (mesma silhueta, mais peso e tremor)
	ARREMESSO_CARREGADO = {
		{ pose = "ARREMESSO_CARGA",  time = 0.34, style = "Back",  dir = "In",  tremor = 0.035, freq = 26, marca = "CARGA" },
		{ pose = "ARREMESSO_SOLTA",  time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO",  time = 0.22, style = "Quad",  dir = "Out" },
		{ pose = "IDLE",             time = 0.26, style = "Quad",  dir = "Out" },
	},

	-- Salvador: oferta do escudo ao aliado
	SACRIFICIO = {
		{ pose = "SACRIFICIO_CARGA", time = 0.22, style = "Back",  dir = "In",  marca = "CARGA" },
		{ pose = "SACRIFICIO_ALTO",  time = 0.14, style = "Quint", dir = "Out", tremor = 0.03, freq = 20, marca = "VINCULO" },
		{ pose = "GUARDA_FIRME",     time = 0.30, style = "Quad",  dir = "Out" },
	},

	-- Proteção: fechar a barreira
	BARREIRA = {
		{ pose = "GUARDA",           time = 0.18, style = "Back",  dir = "In",  marca = "CARGA" },
		{ pose = "GUARDA_FIRME",     time = 0.12, style = "Quint", dir = "Out", marca = "ABRIR" },
	},

	-- Bloqueador: proteção de aliado (teleporte + contra-golpe)
	PROTEGER = {
		{ pose = "GUARDA_FIRME",     time = 0.14, style = "Back",  dir = "In",  marca = "SAIDA" },
		{ pose = "CONTRA_GOLPE",     time = 0.12, style = "Quint", dir = "Out", tremor = 0.04, freq = 24, marca = "CHEGADA" },
		{ pose = "CORTE_F",          time = 0.16, style = "Quint", dir = "Out", marca = "REPULSAO" },
		{ pose = "IDLE",             time = 0.26, style = "Quad",  dir = "Out" },
	},

	-- Cyclone: invocação dos 5 escudos orbitais
	CICLONE_INVOCA = {
		{ pose = "CICLONE_CARGA",    time = 0.24, style = "Back",  dir = "In",  marca = "CARGA" },
		{ pose = "INVOCAR",          time = 0.16, style = "Quint", dir = "Out", tremor = 0.045, freq = 28, marca = "INVOCAR" },
		{ pose = "CICLONE_ABERTO",   time = 0.20, style = "Quad",  dir = "Out", marca = "ABRIR" },
		{ pose = "CICLONE_GIRO",     time = 0.30, style = "Sine",  dir = "InOut" },
	},

	-- Cyclone: abertura do domínio (poses do Domain Expansion)
	DOMINIO = {
		{ pose = "DOMINIO_CARGA",    time = 0.30, style = "Back",  dir = "In",  tremor = 0.03, freq = 18, marca = "GONGO" },
		{ pose = "DOMINIO_MEIO",     time = 0.22, style = "Quad",  dir = "Out" },
		{ pose = "DOMINIO_ABERTO",   time = 0.16, style = "Quint", dir = "Out", marca = "EXPANDIR" },
		{ pose = "DOMINIO_SUSTENTA", time = 0.40, style = "Sine",  dir = "InOut", marca = "SUSTENTAR" },
	},

	-- Cyclone: pulso de tração
	CICLONE_PUXA = {
		{ pose = "PUXAO_CARGA",      time = 0.14, style = "Back",  dir = "In" },
		{ pose = "PUXAO_SOLTA",      time = 0.10, style = "Quint", dir = "Out", marca = "PUXAR" },
		{ pose = "CICLONE_GIRO",     time = 0.20, style = "Quad",  dir = "Out" },
	},

	-- Partido: combo melee de cortes (3 golpes)
	CORTE_COMBO = {
		{ pose = "CORTE_A",          time = 0.10, style = "Back",  dir = "In" },
		{ pose = "CORTE_B",          time = 0.09, style = "Quint", dir = "Out", marca = "CORTE1" },
		{ pose = "CORTE_C",          time = 0.10, style = "Back",  dir = "In" },
		{ pose = "CORTE_D",          time = 0.09, style = "Quint", dir = "Out", marca = "CORTE2" },
		{ pose = "CORTE_E",          time = 0.10, style = "Back",  dir = "In" },
		{ pose = "CORTE_F",          time = 0.09, style = "Quint", dir = "Out", marca = "CORTE3" },
		{ pose = "IDLE",             time = 0.24, style = "Quad",  dir = "Out" },
	},

	-- Partido: cutscene de execução.
	-- Coreografia herdada de "Judgement Cut End": postura -> tempo parado ->
	-- grade de cortes suspensa -> rajada de cortes -> colapso + golpe mortal.
	EXECUCAO = {
		{ pose = "EXEC_POSTURA",     time = 0.45, style = "Back",  dir = "In",  tremor = 0.02, freq = 18, marca = "POSTURA" },
		{ pose = "EXEC_AVANCO",      time = 0.22, style = "Quint", dir = "Out", marca = "TEMPO" },
		{ pose = "EXEC_CORTE1",      time = 0.16, style = "Quint", dir = "Out", tremor = 0.05, freq = 30, marca = "GRADE" },
		{ pose = "EXEC_CORTE2",      time = 0.13, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE1",      time = 0.12, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE2",      time = 0.12, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE1",      time = 0.11, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_CORTE2",      time = 0.11, style = "Quint", dir = "Out", marca = "CORTE" },
		{ pose = "EXEC_FINAL",       time = 0.30, style = "Back",  dir = "Out", marca = "MORTAL" },
		{ pose = "IDLE",             time = 0.50, style = "Quad",  dir = "Out", marca = "FIM" },
	},
}

--═══════════════════════════════════════════════════════════════
-- 10. CÂMERA DA CUTSCENE — SERIOUS_PUNCH_CAMERA (amostrado)
--     CFrame RELATIVO ao HumanoidRootPart do portador.
--     Consumido pelo LocalScript: cam.CFrame = hrp.CFrame * cf
--═══════════════════════════════════════════════════════════════

P.CAMERA_EXECUCAO = {
	{ t = 0.00, cf = CFrame.new(1.042, 1.045, -2.163) * CFrame.Angles(math.rad(-153.67), math.rad(27.45), math.rad(169.74)) },
	{ t = 0.45, cf = CFrame.new(2.081, 1.996, -3.803) * CFrame.Angles(math.rad(-151.14), math.rad(26.83), math.rad(163.80)) },
	{ t = 0.70, cf = CFrame.new(2.792, 2.024, -3.831) * CFrame.Angles(math.rad(-137.97), math.rad(-6.23), math.rad(-159.19)) },
	{ t = 0.95, cf = CFrame.new(-3.658, 3.454, -5.347) * CFrame.Angles(math.rad(-153.86), math.rad(-21.99), math.rad(-158.36)) },
	{ t = 1.25, cf = CFrame.new(2.819, 0.310, -1.877) * CFrame.Angles(math.rad(-152.79), math.rad(27.46), math.rad(165.08)) },
	{ t = 1.55, cf = CFrame.new(3.027, 0.019, -1.065) * CFrame.Angles(math.rad(-151.65), math.rad(40.88), math.rad(155.28)) },
	{ t = 1.85, cf = CFrame.new(3.023, -0.245, 0.322) * CFrame.Angles(math.rad(-130.92), math.rad(67.71), math.rad(123.45)) },
	{ t = 2.30, cf = CFrame.new(1.822, 1.700, 5.456) * CFrame.Angles(math.rad(-6.48), math.rad(2.20), math.rad(3.20)) },
	{ t = 2.90, cf = CFrame.new(1.707, 1.764, 6.039) * CFrame.Angles(math.rad(-1.96), math.rad(2.44), math.rad(3.02)) },
}

return P
