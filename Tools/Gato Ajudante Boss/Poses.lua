-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Gato Ajudante Boss  (conjunto REALITY)
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
--   Quase nenhum contragolpe — chamar não custa massa.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.APONTA_CURTO = {
	RightArm = CFrame.new(1.44, 0.12, -0.86) * CFrame.Angles(math.rad(4), math.rad(-8), math.rad(-6)),
	LeftArm = CFrame.new(-1.46, 0.04, -0.12) * CFrame.Angles(math.rad(14), math.rad(4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), math.rad(0)),
}

P.CHAMA = {
	RightArm = CFrame.new(1.3, 0.6, -0.5) * CFrame.Angles(math.rad(-104), math.rad(-22), math.rad(30)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.1) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(-6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-10), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.66 s
	PRIMARIA = {
		{ pose = "CHAMA", time = 0.22, style = "Quad", dir = "Out", marca = "ASSOBIO" },
		{ pose = "APONTA_CURTO", time = 0.18, style = "Back", dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

}

return P
