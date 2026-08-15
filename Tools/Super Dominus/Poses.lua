-- Poses.lua
-- ModuleScript "Poses" — Super Dominus  (conjunto NOOB)
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
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   COROA        ultimate         7.85s · 9 passo(s), 5 segurado(s)
--
-- O vocabulário é de PALMA PARA CIMA: ABRE_PALMA, ERGUE_DUAS, PUXA_PEITO.
-- O Noob conjura do vazio; nenhuma destas poses soca. O único golpe de
-- contato do conjunto é o `Colar das Trevas`, e ele agarra.
--
-- Gerado por FERRAMENTAS/gerar_poses_noob.py.

local P = {}


P.CAI_JOELHO = {
	RightArm = CFrame.new(1.34, -0.2, -0.56) * CFrame.Angles(math.rad(42), math.rad(14), math.rad(20)),
	LeftArm = CFrame.new(-1.34, -0.2, -0.56) * CFrame.Angles(math.rad(42), math.rad(-14), math.rad(-20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.78, 0) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.4, -0.72) * CFrame.Angles(math.rad(-62), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.66, 0.36) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
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

P.RECEBE_COROA = {
	RightArm = CFrame.new(1.56, 0.2, 0.32) * CFrame.Angles(math.rad(-20), math.rad(-12), math.rad(-52)),
	LeftArm = CFrame.new(-1.56, 0.2, 0.32) * CFrame.Angles(math.rad(-20), math.rad(12), math.rad(52)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, 0.2) * CFrame.Angles(math.rad(11), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.2) * CFrame.Angles(math.rad(11), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- ultimate · 7.85s · 9 passo(s), 5 segurado(s)
	COROA = {
		{ pose = "PUXA_PEITO", time = 0.45, style = "Back", dir = "In", tremor = 0.02, freq = 16, marca = "CAMERA" },
		{ pose = "RECEBE_COROA", time = 0.9, style = "Quad", dir = "InOut", tremor = 0.03, freq = 20, marca = "CARGA" },
		{ pose = "RECEBE_COROA", time = 1.15, style = "Sine", dir = "InOut", tremor = 0.045, freq = 25 },
		{ pose = "RECEBE_COROA", time = 1.25, style = "Sine", dir = "InOut", tremor = 0.06, freq = 30, marca = "SEGURA" },
		{ pose = "RECEBE_COROA", time = 1.2, style = "Sine", dir = "InOut", tremor = 0.075, freq = 35 },
		{ pose = "CAI_JOELHO", time = 0.35, style = "Quint", dir = "In", marca = "DESCE" },
		{ pose = "CAI_JOELHO", time = 0.3, style = "Sine", dir = "InOut", marca = "GOLPE" },
		{ pose = "CAI_JOELHO", time = 0.95, style = "Sine", dir = "InOut", tremor = 0.06, freq = 32 },
		{ pose = "IDLE", time = 1.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
