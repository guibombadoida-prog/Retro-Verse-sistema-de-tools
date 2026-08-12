-- Poses.lua
-- ModuleScript "Poses" — Bomba Doida
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
--   SOLTAR      golpe rápido         0.85s · impacto 59% · 2 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_bombas.py.

local P = {}


P.SOLTAR = {
	RightArm = CFrame.new(1.62, -0.1, -0.62) * CFrame.Angles(math.rad(58), math.rad(26), math.rad(-30)),
	LeftArm = CFrame.new(-1.62, -0.12, -0.6) * CFrame.Angles(math.rad(56), math.rad(-26), math.rad(29)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(11), 0, 0),
	HRP = CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(9), 0, 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.1, -0.28) * CFrame.Angles(math.rad(34), math.rad(4), math.rad(7)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- golpe rápido · 0.85s · 4 passo(s), 2 segurado(s)
	SOLTAR = {
		{ pose = "SOLTAR", time = 0.16, style = "Back", dir = "In" },
		{ pose = "SOLTAR", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.025, freq = 22 },
		{ pose = "SOLTAR", time = 0.08, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE", time = 0.35, style = "Quad", dir = "Out" },
	},

}

return P
