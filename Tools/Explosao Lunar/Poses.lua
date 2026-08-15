-- Poses.lua
-- ModuleScript "Poses" — Explosao Lunar  (conjunto NOOB)
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
-- JUNTA QUE LIDERA: **Head** (regra 6 da gramática).
--
--   LUA          conjuração       1.30s · 5 passo(s), 2 segurado(s)
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

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.OLHA_CIMA = {
	RightArm = CFrame.new(1.54, 0.3, -0.36) * CFrame.Angles(math.rad(44), math.rad(-10), math.rad(-30)),
	LeftArm = CFrame.new(-1.54, 0.3, -0.36) * CFrame.Angles(math.rad(44), math.rad(10), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.16) * CFrame.Angles(math.rad(9), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.30s · 5 passo(s), 2 segurado(s)
	LUA = {
		{ pose = "OLHA_CIMA", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "OLHA_CIMA", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.035, freq = 22 },
		{ pose = "ABRE_PALMA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "ABRE_PALMA", time = 0.22, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

}

return P
