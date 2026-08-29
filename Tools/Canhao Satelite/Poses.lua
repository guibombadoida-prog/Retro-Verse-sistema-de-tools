-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Canhao Satelite  (conjunto REALITY)
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
-- A GRAMÁTICA: TODO GESTO TEM CONTRAGOLPE
--
--   Empurrar coisa pesada empurra você de volta. Num conjunto de física isso
--   não é enfeite: é a única coisa que o jogador sente sem que ninguém
--   explique. Por isso a sequência não acaba no beat — depois dele vem um
--   quadro de RECUO ou de ESCORA, proporcional à força que saiu.
--
--   Escora de 0.90 s — o quadro mais longo do conjunto, e ele vem DEPOIS do beat.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.ESCORA_LONGA = {
	RightArm = CFrame.new(1.4, -0.18, -0.52) * CFrame.Angles(math.rad(52), math.rad(-22), math.rad(-26)),
	LeftArm = CFrame.new(-1.4, -0.18, -0.52) * CFrame.Angles(math.rad(52), math.rad(22), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.28, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.54, -1.7, -0.42) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.56, -1.76, 0.3) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.MARCA_CEU = {
	RightArm = CFrame.new(1.36, 0.72, 0.06) * CFrame.Angles(math.rad(-166), math.rad(-12), math.rad(24)),
	LeftArm = CFrame.new(-1.46, 0.16, -0.28) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-36), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-12), math.rad(-10), math.rad(0)),
}

P.MARCA_CHAO = {
	RightArm = CFrame.new(1.44, -0.06, -0.88) * CFrame.Angles(math.rad(62), math.rad(-6), math.rad(-8)),
	LeftArm = CFrame.new(-1.44, -0.02, -0.5) * CFrame.Angles(math.rad(44), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.82, -0.28) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.86, 0.18) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 2.06 s
	PRIMARIA = {
		{ pose = "MARCA_CEU", time = 0.34, style = "Quad", dir = "Out", marca = "CHAMA" },
		{ pose = "MARCA_CHAO", time = 0.16, style = "Quint", dir = "Out", marca = "MARCA" },
		{ pose = "ESCORA_LONGA", time = 0.3, style = "Quad", dir = "Out", marca = "FEIXE" },
		{ pose = "ESCORA_LONGA", time = 0.9, style = "Linear", dir = "Out", tremor = 0.028, freq = 13 },
		{ pose = "IDLE", time = 0.36, style = "Quad", dir = "InOut" },
	},

}

return P
