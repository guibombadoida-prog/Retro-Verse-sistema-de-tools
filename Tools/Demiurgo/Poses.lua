-- Poses_Criacao_V1.lua
-- ModuleScript "Poses" — Demiurgo  (conjunto CRIAÇÃO)
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — nenhuma pose daqui deve ser aplicada fora de sequência.
--
-- ESTA TOOL LIDERA POR `HRP`.
--
-- A GRAMÁTICA: O GESTO VEM ANTES DA COISA
--
--   Os outros conjuntos animam um GOLPE — o corpo acelera até um ponto e o
--   dano acontece ali. Criar tem dois tempos, e o segundo é o que importa: o
--   gesto, e depois a PAUSA em que a coisa sobe.
--
--   Por isso o molde `erguer` tem o quadro mais longo num lugar onde nenhum
--   outro molde do repositório põe um: DEPOIS do beat. A muralha não aparece
--   no instante em que a mão sobe — ela aparece enquanto a mão fica parada lá
--   em cima.
--
-- Gerado por FERRAMENTAS/gerar_poses_criacao.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local P = {}

P.DESENHA_COMECA = {
	RightArm = CFrame.new(1.44, 0.42, -0.66) * CFrame.Angles(math.rad(92), math.rad(-48), math.rad(-20)),
	LeftArm = CFrame.new(-1.46, 0.08, -0.18) * CFrame.Angles(math.rad(18), math.rad(12), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-34), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(0), math.rad(-30), math.rad(0)),
}

P.DESENHA_TERMINA = {
	RightArm = CFrame.new(1.52, 0.38, -0.78) * CFrame.Angles(math.rad(90), math.rad(46), math.rad(-16)),
	LeftArm = CFrame.new(-1.42, 0.04, 0.14) * CFrame.Angles(math.rad(-6), math.rad(-12), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(36), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(34), math.rad(0)),
}

P.APRESENTA = {
	RightArm = CFrame.new(1.52, 0.3, -0.94) * CFrame.Angles(math.rad(84), math.rad(-6), math.rad(-18)),
	LeftArm = CFrame.new(-1.5, 0.16, -0.5) * CFrame.Angles(math.rad(52), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(-6), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-6), math.rad(8), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.08, -0.2) * CFrame.Angles(math.rad(20), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.08) * CFrame.Angles(math.rad(10), math.rad(-2), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(-5), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-7), math.rad(0)),
}

P.PALMAS_BAIXO = {
	RightArm = CFrame.new(1.44, -0.14, -0.62) * CFrame.Angles(math.rad(46), math.rad(-16), math.rad(-22)),
	LeftArm = CFrame.new(-1.44, -0.14, -0.62) * CFrame.Angles(math.rad(46), math.rad(16), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.26, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.8, -0.24) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.8, -0.24) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
}

P.ERGUE = {
	RightArm = CFrame.new(1.5, 0.7, -0.3) * CFrame.Angles(math.rad(142), math.rad(-12), math.rad(-16)),
	LeftArm = CFrame.new(-1.5, 0.7, -0.3) * CFrame.Angles(math.rad(142), math.rad(12), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.1) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.ABRE_MUNDO = {
	RightArm = CFrame.new(1.56, 0.84, -0.1) * CFrame.Angles(math.rad(166), math.rad(-14), math.rad(-34)),
	LeftArm = CFrame.new(-1.56, 0.84, -0.1) * CFrame.Angles(math.rad(166), math.rad(14), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.18, 0) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.94, 0.06) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.94, 0.06) * CFrame.Angles(math.rad(4), math.rad(0), math.rad(0)),
}

P.ASSENTA = {
	RightArm = CFrame.new(1.46, -0.2, -0.5) * CFrame.Angles(math.rad(26), math.rad(-8), math.rad(8)),
	LeftArm = CFrame.new(-1.46, -0.2, -0.5) * CFrame.Angles(math.rad(26), math.rad(8), math.rad(-8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.66, -0.42) * CFrame.Angles(math.rad(-32), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.66, -0.42) * CFrame.Angles(math.rad(-32), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- desenho — 0.90 s
	MOLDE_MUNDO = {
		{ pose = "DESENHA_COMECA", time = 0.2, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "DESENHA_TERMINA", time = 0.16, style = "Quad", dir = "InOut", marca = "TRACA" },
		{ pose = "APRESENTA", time = 0.16, style = "Quint", dir = "Out" },
		{ pose = "IDLE", time = 0.38, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- erguimento — 1.30 s
	CONTINENTE = {
		{ pose = "PALMAS_BAIXO", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PALMAS_BAIXO", time = 0.16, style = "Sine", dir = "InOut", marca = "SEGURA" },
		{ pose = "ERGUE", time = 0.14, style = "Quint", dir = "Out", marca = "ERGUE" },
		{ pose = "ERGUE", time = 0.46, style = "Sine", dir = "InOut", tremor = 0.034, freq = 16 },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- épica — 1.50 s
	CRIACAO = {
		{ pose = "ABRE_MUNDO", time = 0.34, style = "Back", dir = "Out", marca = "CENA" },
		{ pose = "ABRE_MUNDO", time = 0.48, style = "Sine", dir = "InOut", tremor = 0.05, freq = 20, marca = "CARGA" },
		{ pose = "ASSENTA", time = 0.16, style = "Quint", dir = "Out", tremor = 0.09000000000000001, freq = 32, marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.52, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
