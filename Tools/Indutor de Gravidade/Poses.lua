-- Poses_Reality_V1.lua
-- ModuleScript "Poses" — Indutor de Gravidade  (conjunto REALITY)
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
--   Escora com tremor: o poço puxa quem o abriu também.
--
-- Gerado por FERRAMENTAS/gerar_poses_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.ABRE_POCO = {
	RightArm = CFrame.new(1.44, 0.06, -0.78) * CFrame.Angles(math.rad(26), math.rad(-34), math.rad(-14)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.78) * CFrame.Angles(math.rad(26), math.rad(34), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PUXA_DE_VOLTA = {
	RightArm = CFrame.new(1.34, -0.08, -0.58) * CFrame.Angles(math.rad(48), math.rad(-14), math.rad(-30)),
	LeftArm = CFrame.new(-1.34, -0.08, -0.58) * CFrame.Angles(math.rad(48), math.rad(14), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.54, -1.66, -0.44) * CFrame.Angles(math.rad(-32), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.56, -1.72, 0.3) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 1.44 s
	PRIMARIA = {
		{ pose = "ABRE_POCO", time = 0.26, style = "Quad", dir = "Out", marca = "ABRE" },
		{ pose = "PUXA_DE_VOLTA", time = 0.24, style = "Quint", dir = "Out", marca = "POCO" },
		{ pose = "PUXA_DE_VOLTA", time = 0.6, style = "Linear", dir = "Out", tremor = 0.04, freq = 18 },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "InOut" },
	},

}

return P
