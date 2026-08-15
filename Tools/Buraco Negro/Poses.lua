-- Poses.lua
-- ModuleScript "Poses" — Buraco Negro  (conjunto NOOB)
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
--   ABRIR        golpe pesado     1.50s · 5 passo(s), 1 segurado(s)
--   COLAPSO      sustentada       1.70s · 6 passo(s), 2 segurado(s)
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

P.PUXA_ALTO = {
	RightArm = CFrame.new(1.44, 0.8, -0.44) * CFrame.Angles(math.rad(146), math.rad(-14), math.rad(-18)),
	LeftArm = CFrame.new(-1.36, 0.24, -0.44) * CFrame.Angles(math.rad(62), math.rad(12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(-10), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-12), math.rad(14), math.rad(0)),
}

P.PUXA_PEITO = {
	RightArm = CFrame.new(1.28, 0.14, -0.6) * CFrame.Angles(math.rad(78), math.rad(18), math.rad(36)),
	LeftArm = CFrame.new(-1.28, 0.14, -0.6) * CFrame.Angles(math.rad(78), math.rad(-18), math.rad(-36)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.50s · 5 passo(s), 1 segurado(s)
	ABRIR = {
		{ pose = "ABRE_PALMA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ERGUE_DUAS", time = 0.5, style = "Sine", dir = "InOut", tremor = 0.04, freq = 23 },
		{ pose = "PUXA_ALTO", time = 0.16, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "PUXA_ALTO", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.05, freq = 28, marca = "SEGURA" },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "Out" },
	},

	-- sustentada · 1.70s · 6 passo(s), 2 segurado(s)
	COLAPSO = {
		{ pose = "ERGUE_DUAS", time = 0.24, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PUXA_PEITO", time = 0.16, style = "Quint", dir = "Out" },
		{ pose = "PUXA_PEITO", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.04, freq = 26, marca = "SEGURA" },
		{ pose = "PUXA_PEITO", time = 0.34, style = "Sine", dir = "InOut", tremor = 0.055, freq = 31, marca = "GOLPE" },
		{ pose = "ABRE_PALMA", time = 0.2, style = "Quad", dir = "InOut" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out" },
	},

}

return P
