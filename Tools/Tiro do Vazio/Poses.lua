-- Poses.lua
-- ModuleScript "Poses" — Tiro do Vazio  (conjunto NOOB)
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
--   TIRO         golpe rápido     1.00s · 5 passo(s), 2 segurado(s)
--   DISPARO      golpe pesado     1.40s · 5 passo(s), 1 segurado(s)
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

P.APONTA_LADO = {
	RightArm = CFrame.new(1.54, 0.42, -1.08) * CFrame.Angles(math.rad(88), math.rad(-6), math.rad(-14)),
	LeftArm = CFrame.new(-1.34, 0.5, -0.42) * CFrame.Angles(math.rad(128), math.rad(16), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(52), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, -0.2) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.PUXA_PEITO = {
	RightArm = CFrame.new(1.28, 0.14, -0.6) * CFrame.Angles(math.rad(78), math.rad(18), math.rad(36)),
	LeftArm = CFrame.new(-1.28, 0.14, -0.6) * CFrame.Angles(math.rad(78), math.rad(-18), math.rad(-36)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe rápido · 1.00s · 5 passo(s), 2 segurado(s)
	TIRO = {
		{ pose = "ABRE_PALMA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "APONTA_LADO", time = 0.18, style = "Quint", dir = "Out" },
		{ pose = "APONTA_LADO", time = 0.14, style = "Sine", dir = "InOut", marca = "GOLPE" },
		{ pose = "APONTA_LADO", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

	-- golpe pesado · 1.40s · 5 passo(s), 1 segurado(s)
	DISPARO = {
		{ pose = "ABRE_PALMA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PUXA_PEITO", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24 },
		{ pose = "APONTA_LADO", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "APONTA_LADO", time = 0.28, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out" },
	},

}

return P
