-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Arvore Maligna  (conjunto REALITY)
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
-- A GRAMÁTICA: TODO GESTO TEM CONTRAGOLPE
--
--   Empurrar coisa pesada empurra você de volta. Num conjunto de física isso
--   não é enfeite: é a única coisa que o jogador sente sem que ninguém
--   explique. Por isso a sequência não acaba no beat — depois dele vem um
--   quadro de RECUO ou de ESCORA, proporcional à força que saiu.
--
--   Escora agachada: a raiz puxa o corpo para baixo, e ele não volta a subir até o fim.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.ESCORA_BAIXA = {
	RightArm = CFrame.new(1.38, -0.28, -0.6) * CFrame.Angles(math.rad(62), math.rad(-18), math.rad(-20)),
	LeftArm = CFrame.new(-1.4, -0.2, -0.4) * CFrame.Angles(math.rad(48), math.rad(14), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.44, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.52, -1.56, -0.48) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.66, 0.28) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PLANTA_MAO = {
	RightArm = CFrame.new(1.4, -0.5, -0.42) * CFrame.Angles(math.rad(78), math.rad(-14), math.rad(-14)),
	LeftArm = CFrame.new(-1.42, -0.3, -0.2) * CFrame.Angles(math.rad(40), math.rad(12), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(30), math.rad(6), math.rad(0)),
	HRP = CFrame.new(0, -0.62, 0) * CFrame.Angles(math.rad(28), math.rad(8), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.44, -0.56) * CFrame.Angles(math.rad(-44), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.58, 0.34) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 1.40 s
	PRIMARIA = {
		{ pose = "PLANTA_MAO", time = 0.3, style = "Quad", dir = "Out", marca = "PLANTA" },
		{ pose = "ESCORA_BAIXA", time = 0.42, style = "Quad", dir = "Out", tremor = 0.034, freq = 16, marca = "RAIZ" },
		{ pose = "ESCORA_BAIXA", time = 0.34, style = "Linear", dir = "Out" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "InOut" },
	},

}

return P
