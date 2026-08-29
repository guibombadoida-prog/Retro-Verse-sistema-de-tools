-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Lapada Seca  (conjunto REALITY)
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
--   Recuo curto e alto: o braço passa reto e SOBRA.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.RECUO_ALTO = {
	RightArm = CFrame.new(1.34, 0.34, -0.7) * CFrame.Angles(math.rad(-34), math.rad(52), math.rad(-18)),
	LeftArm = CFrame.new(-1.44, 0.14, 0.06) * CFrame.Angles(math.rad(-6), math.rad(-10), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(22), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-8), math.rad(26), math.rad(0)),
}

P.TAPA_CARREGA = {
	RightArm = CFrame.new(1.28, 0.44, 0.62) * CFrame.Angles(math.rad(-46), math.rad(-62), math.rad(36)),
	LeftArm = CFrame.new(-1.4, 0.06, -0.42) * CFrame.Angles(math.rad(34), math.rad(20), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-38), math.rad(0)),
}

P.TAPA_PASSA = {
	RightArm = CFrame.new(1.42, 0.1, -0.96) * CFrame.Angles(math.rad(8), math.rad(74), math.rad(-26)),
	LeftArm = CFrame.new(-1.36, -0.06, 0.34) * CFrame.Angles(math.rad(-22), math.rad(-18), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(40), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(6), math.rad(44), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, -0.34) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.9, 0.24) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.69 s
	PRIMARIA = {
		{ pose = "TAPA_CARREGA", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "TAPA_PASSA", time = 0.09, style = "Quint", dir = "Out", marca = "TAPA" },
		{ pose = "RECUO_ALTO", time = 0.2, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "InOut" },
	},

}

return P
