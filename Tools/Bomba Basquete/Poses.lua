-- Poses.lua
-- ModuleScript "Poses" — Bomba Basquete
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
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, as seis bombas dividiam o mesmo
-- arquivo — este traz só o que esta Tool usa, com o tempo dela.
--
-- As SILHUETAS não mudaram: é a mesma habilidade do mesmo modelo. O que mudou
-- foi o TEMPO, pela gramática medida em ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md.
--
--   ARREMESSO   golpe rápido         0.90s · impacto 48% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_bombas.py.

local P = {}


P.ARREMESSO_CARGA = {
	RightArm = CFrame.new(1.3, 0.68, 0.46) * CFrame.Angles(math.rad(152), math.rad(-16), math.rad(34)),
	LeftArm = CFrame.new(-1.44, 0.14, -0.3) * CFrame.Angles(math.rad(30), math.rad(12), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(-24), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-36), math.rad(-5)),
}

P.ARREMESSO_SOLTA = {
	RightArm = CFrame.new(1.58, 0.04, -1.24) * CFrame.Angles(math.rad(84), math.rad(14), math.rad(-34)),
	LeftArm = CFrame.new(-1.5, -0.12, 0.28) * CFrame.Angles(math.rad(-16), math.rad(-14), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(22), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-7), math.rad(32), math.rad(5)),
}

P.ARREMESSO_RECUO = {
	RightArm = CFrame.new(1.48, 0.02, -0.4) * CFrame.Angles(math.rad(44), math.rad(6), math.rad(-8)),
	LeftArm = CFrame.new(-1.49, 0, 0.06) * CFrame.Angles(math.rad(2), 0, math.rad(9)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-1), math.rad(8), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(10), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.1, -0.28) * CFrame.Angles(math.rad(34), math.rad(4), math.rad(7)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.90s · 5 passo(s), 1 segurado(s)
	ARREMESSO = {
		{ pose = "ARREMESSO_CARGA", time = 0.16, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ARREMESSO_CARGA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "ARREMESSO_SOLTA", time = 0.07, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "ARREMESSO_RECUO", time = 0.19, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
