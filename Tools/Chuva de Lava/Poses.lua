-- Poses.lua
-- ModuleScript "Poses" — Chuva de Lava  (conjunto NOOB)
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
--   LAVA         ultimate         7.10s · 8 passo(s), 5 segurado(s)
--
-- O vocabulário é de PALMA PARA CIMA: ABRE_PALMA, ERGUE_DUAS, PUXA_PEITO.
-- O Noob conjura do vazio; nenhuma destas poses soca. O único golpe de
-- contato do conjunto é o `Colar das Trevas`, e ele agarra.
--
-- Gerado por FERRAMENTAS/gerar_poses_noob.py.

local P = {}


P.BAIXA_DUAS = {
	RightArm = CFrame.new(1.36, -0.36, -0.46) * CFrame.Angles(math.rad(30), math.rad(16), math.rad(24)),
	LeftArm = CFrame.new(-1.36, -0.36, -0.46) * CFrame.Angles(math.rad(30), math.rad(-16), math.rad(-24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.46, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.62, -0.54) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.62, -0.54) * CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
}

P.ERGUE_DUAS = {
	RightArm = CFrame.new(1.46, 0.76, -0.12) * CFrame.Angles(math.rad(152), math.rad(-12), math.rad(-26)),
	LeftArm = CFrame.new(-1.46, 0.76, -0.12) * CFrame.Angles(math.rad(152), math.rad(12), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.14) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.24) * CFrame.Angles(math.rad(20), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-5), math.rad(0)),
}

P.SEQUENCIAS = {

	-- ultimate · 7.10s · 8 passo(s), 5 segurado(s)
	LAVA = {
		{ pose = "ERGUE_DUAS", time = 0.5, style = "Back", dir = "In", tremor = 0.02, freq = 15, marca = "CAMERA" },
		{ pose = "ERGUE_DUAS", time = 1.05, style = "Sine", dir = "InOut", tremor = 0.03, freq = 20, marca = "CARGA" },
		{ pose = "ERGUE_DUAS", time = 1.3, style = "Sine", dir = "InOut", tremor = 0.045, freq = 25 },
		{ pose = "ERGUE_DUAS", time = 1.4, style = "Sine", dir = "InOut", tremor = 0.06, freq = 30, marca = "SEGURA" },
		{ pose = "BAIXA_DUAS", time = 0.45, style = "Quint", dir = "In", marca = "DESCE" },
		{ pose = "BAIXA_DUAS", time = 0.3, style = "Sine", dir = "InOut", marca = "GOLPE" },
		{ pose = "BAIXA_DUAS", time = 0.9, style = "Sine", dir = "InOut", tremor = 0.07, freq = 33 },
		{ pose = "IDLE", time = 1.2, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
