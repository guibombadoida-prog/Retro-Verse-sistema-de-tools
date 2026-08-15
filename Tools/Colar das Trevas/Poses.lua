-- Poses.lua
-- ModuleScript "Poses" — Colar das Trevas  (conjunto NOOB)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada.
--
-- AUTORAL. A origem anima em `Motor6D.C0` com `Clerp` dentro de um laço de
-- `Swait()` — proibido pela REGRA_ANIMACAO_R6, e ainda por cima o alvo do
-- lerp não é a pose alcançada. Nenhum quadro dela foi copiado; o único
-- empréstimo é o GESTO do `Shot`, que virou APONTA_LADO.
--
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   AGARRAR      golpe rápido     1.10s · 5 passo(s), 1 segurado(s)
--
-- O vocabulário é de PALMA PARA CIMA: ABRE_PALMA, ERGUE_DUAS, PUXA_PEITO.
-- O Noob conjura do vazio; nenhuma destas poses soca. O único golpe de
-- contato do conjunto é o `Colar das Trevas`, e ele agarra.
--
-- Gerado por FERRAMENTAS/gerar_poses_noob.py.

local P = {}


P.ABRE_PALMA = {
	RightArm = CFrame.new(1.5, 0.16, -0.72) * CFrame.Angles(math.rad(66), math.rad(-12), math.rad(-22)),
	LeftArm = CFrame.new(-1.44, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-5), math.rad(10), math.rad(0)),
}

P.AGARRA = {
	RightArm = CFrame.new(1.5, 0.52, -1.06) * CFrame.Angles(math.rad(104), math.rad(-8), math.rad(-10)),
	LeftArm = CFrame.new(-1.32, 0.2, -0.5) * CFrame.Angles(math.rad(58), math.rad(14), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(18), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, -0.3) * CFrame.Angles(math.rad(-15), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.PUXA_ALTO = {
	RightArm = CFrame.new(1.44, 0.8, -0.44) * CFrame.Angles(math.rad(146), math.rad(-14), math.rad(-18)),
	LeftArm = CFrame.new(-1.36, 0.24, -0.44) * CFrame.Angles(math.rad(62), math.rad(12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(-10), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-12), math.rad(14), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 1.10s · 5 passo(s), 1 segurado(s)
	AGARRAR = {
		{ pose = "ABRE_PALMA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "AGARRA", time = 0.12, style = "Quint", dir = "Out" },
		{ pose = "AGARRA", time = 0.26, style = "Sine", dir = "InOut", tremor = 0.035, freq = 24, marca = "GOLPE" },
		{ pose = "PUXA_ALTO", time = 0.24, style = "Sine", dir = "InOut", tremor = 0.04, freq = 28, marca = "SEGURA" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
