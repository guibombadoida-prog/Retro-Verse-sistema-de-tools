-- Poses.lua
-- ModuleScript "Poses" — Escudo Skate
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
-- ANIMAÇÃO PERSONALIZADA DESTA TOOL. Antes, os sete escudos dividiam o mesmo
-- arquivo de 440 linhas — este traz só o que esta Tool usa.
--
-- As SILHUETAS são as da remasterização e não mudaram: é a mesma habilidade,
-- do mesmo modelo. O que mudou foi o TEMPO, re-cronometrado pela gramática
-- medida no pack de referência (ACERVO/_AUTORAL_RetroVerse/R6_CFRAME/
-- GRAMATICA_R6.md).
--
-- O que a gramática impôs aqui:
--   SKATE_IMPULSO        estado (2:98)          0.90s · impacto 7% · 1 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.SKATE = { -- corpo aerodinâmico, braço atrás (Skate)
	RightArm = CFrame.new(1.5, 0.15, 0.55) * CFrame.Angles(math.rad(-28), 0, math.rad(10)),
	LeftArm = CFrame.new(-1.55, 0.35, -0.5) * CFrame.Angles(math.rad(46), 0, math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
	HRP = CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(15), 0, 0),
}

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

P.SEQUENCIAS = {

	-- estado (2:98) · 0.90s · 3 passo(s), 1 segurado(s)
	SKATE_IMPULSO = {
		{ pose = "SKATE", time = 0.06, style = "Quint", dir = "Out", marca = "IMPULSO" },
		{ pose = "SKATE", time = 0.6, style = "Sine", dir = "InOut", marca = "DESLIZA" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
