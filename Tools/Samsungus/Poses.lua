-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Samsungus  (conjunto REALITY)
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
--   Recuo de arremesso: o braço continua depois de o aparelho sair.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.ARREMESSO_ALTO = {
	RightArm = CFrame.new(1.3, 0.66, 0.34) * CFrame.Angles(math.rad(-150), math.rad(-26), math.rad(34)),
	LeftArm = CFrame.new(-1.42, 0.18, -0.44) * CFrame.Angles(math.rad(40), math.rad(18), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-24), math.rad(-18), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(-26), math.rad(0)),
}

P.ARREMESSO_SOLTA = {
	RightArm = CFrame.new(1.42, -0.1, -0.92) * CFrame.Angles(math.rad(46), math.rad(30), math.rad(-18)),
	LeftArm = CFrame.new(-1.38, -0.04, 0.22) * CFrame.Angles(math.rad(-14), math.rad(-14), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(22), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(12), math.rad(26), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.84, -0.32) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.88, 0.22) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
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

	-- 0.72 s
	PRIMARIA = {
		{ pose = "ARREMESSO_ALTO", time = 0.2, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "ARREMESSO_SOLTA", time = 0.1, style = "Quint", dir = "Out", marca = "ARREMESSA" },
		{ pose = "ARREMESSO_SOLTA", time = 0.16, style = "Linear", dir = "Out" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

}

return P
