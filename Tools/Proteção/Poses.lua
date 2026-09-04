-- Poses.lua
-- ModuleScript "Poses" — Proteção
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
--   BARREIRA             defensiva              0.85s · impacto 61% · 2 segurado(s)
--
-- Gerado por FERRAMENTAS/gerar_poses_escudos.py.

local P = {}


P.GUARDA = { -- barreira defensiva (Proteção)
	RightArm = CFrame.new(1.4, 0.45, -0.75) * CFrame.Angles(math.rad(70), 0, math.rad(-12)),
	LeftArm = CFrame.new(-1.45, 0.2, -0.4) * CFrame.Angles(math.rad(40), 0, math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), 0, 0),
	HRP = CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(6), math.rad(8), 0),
}

P.GUARDA_FIRME = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-18.28), math.rad(-39.56), math.rad(-11.01)),
	RightArm = CFrame.new(1.564, 0.422, -0.017) * CFrame.Angles(math.rad(72.6), math.rad(4.68), math.rad(22.04)),
	LeftArm = CFrame.new(-1.566, 0.077, -0.035) * CFrame.Angles(math.rad(3.89), math.rad(-0.68), math.rad(-8.11)),
	Head = CFrame.new(0, 1.466, -0.182) * CFrame.Angles(math.rad(-21.4), math.rad(-0.85), math.rad(0.03)),
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

	-- defensiva · 0.85s · 5 passo(s), 2 segurado(s)
	BARREIRA = {
		{ pose = "GUARDA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "GUARDA_FIRME", time = 0.1, style = "Quint", dir = "Out", marca = "ABRIR" },
		{ pose = "GUARDA_FIRME", time = 0.18, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.15, style = "Quad", dir = "Out" },
	},

}

return P
