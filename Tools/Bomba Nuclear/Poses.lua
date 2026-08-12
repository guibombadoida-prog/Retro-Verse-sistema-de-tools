-- Poses.lua
-- ModuleScript "Poses" — Bomba Nuclear
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
--   CHAMADO     conjuração pesada    1.60s · impacto 70% · 2 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_bombas.py.

local P = {}


P.CHAMA_ERGUE = {
	RightArm = CFrame.new(1.5, 0.82, 0.08) * CFrame.Angles(math.rad(172), math.rad(-4), math.rad(11)),
	LeftArm = CFrame.new(-1.5, 0.78, 0.06) * CFrame.Angles(math.rad(168), math.rad(4), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), 0, 0),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-10), 0, 0),
}

P.CHAMA_BAIXA = {
	RightArm = CFrame.new(1.44, -0.16, -0.5) * CFrame.Angles(math.rad(46), math.rad(-8), math.rad(-18)),
	LeftArm = CFrame.new(-1.44, -0.18, -0.48) * CFrame.Angles(math.rad(44), math.rad(8), math.rad(17)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(15), 0, 0),
	HRP = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(14), 0, 0),
	RightLeg = CFrame.new(0.5, -1.8, -0.34) * CFrame.Angles(math.rad(-19), 0, 0),
	LeftLeg = CFrame.new(-0.5, -1.8, -0.32) * CFrame.Angles(math.rad(-18), 0, 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.1, -0.28) * CFrame.Angles(math.rad(34), math.rad(4), math.rad(7)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(4), 0, math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- conjuração pesada · 1.60s · 5 passo(s), 2 segurado(s)
	CHAMADO = {
		{ pose = "CHAMA_ERGUE", time = 0.4, style = "Back", dir = "In", tremor = 0.03, freq = 20, marca = "ERGUE" },
		{ pose = "CHAMA_ERGUE", time = 0.6, style = "Sine", dir = "InOut", tremor = 0.04, freq = 24 },
		{ pose = "CHAMA_BAIXA", time = 0.12, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "CHAMA_BAIXA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
