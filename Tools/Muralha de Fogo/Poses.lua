-- Poses_Fogo_V1.lua
-- ModuleScript "Poses" — Muralha de Fogo  (conjunto PODER DE FOGO)
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
--═══════════════════════════════════════════════════════════════
-- A GRAMÁTICA: A MÃO NÃO TOCA EM NADA
--═══════════════════════════════════════════════════════════════
--
--   Magnetismo é a única força deste repositório que age À DISTÂNCIA, e a
--   animação tem de dizer isso — senão a Tool vira um soco com brilho.
--
--     1. A MÃO PARA ANTES. Nenhuma pose estende o braço até o fim: o cotovelo
--        fica dobrado e a palma vira para o alvo. É gesto de COMANDO.
--     2. O CORPO RESISTE AO PRÓPRIO CAMPO. Puxar um caminhão puxa você para o
--        caminhão. Atração inclina o tronco PARA TRÁS e trava o pé de trás.
--     3. AS DUAS MÃOS TÊM PÓLOS DIFERENTES. Nas habilidades de campo as
--        palmas ficam OPOSTAS — é como se desenha um dipolo com um corpo.
--
--   A única que risca o chão E ergue: o `RISCA_CHAO` desce a 26° e o `ERGUE_ARCHOTE` sobe a -22°.
--
--═══════════════════════════════════════════════════════════════
-- `quando` — O BEAT NO MEIO DO PASSO
--═══════════════════════════════════════════════════════════════
--
--   `quando` é a FRAÇÃO do passo em que a marca dispara (0 a 1). Sem ele, a
--   marca cai no fim, como em todos os conjuntos anteriores.
--
--   Isso resolve o achado nº 4 da triagem: até aqui um som que devia tocar no
--   meio de um quadro de 0.9 s não tinha onde ser escrito, e virava um passo
--   extra só para pendurar a marca.
--
--   E o beat ANDA JUNTO com a duração: mudou o passo, a marca acompanha. Com
--   número absoluto ela ficaria para trás.
--
-- Gerado por FERRAMENTAS/gerar_poses_fogo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.ERGUE_ARCHOTE = {
	RightArm = CFrame.new(1.38, 0.6, -0.4) * CFrame.Angles(math.rad(-120), math.rad(-18), math.rad(26)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.3) * CFrame.Angles(math.rad(26), math.rad(12), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-22), math.rad(16), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-10), math.rad(12), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.08) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.RECUO_BAIXO = {
	RightArm = CFrame.new(1.34, -0.2, -0.44) * CFrame.Angles(math.rad(46), math.rad(-18), math.rad(-28)),
	LeftArm = CFrame.new(-1.36, -0.16, -0.36) * CFrame.Angles(math.rad(40), math.rad(16), math.rad(24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), math.rad(12), math.rad(0)),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.52, -1.68, -0.4) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.74, 0.28) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
}

P.RISCA_CHAO = {
	RightArm = CFrame.new(1.44, -0.5, -0.5) * CFrame.Angles(math.rad(76), math.rad(-20), math.rad(-16)),
	LeftArm = CFrame.new(-1.42, -0.2, -0.24) * CFrame.Angles(math.rad(34), math.rad(14), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(18), math.rad(0)),
	HRP = CFrame.new(0, -0.54, 0) * CFrame.Angles(math.rad(26), math.rad(14), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.46, -0.54) * CFrame.Angles(math.rad(-42), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.6, 0.32) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.66 s
	PRIMARIA = {
		{ pose = "RISCA_CHAO", time = 0.22, style = "Quad", dir = "Out", marca = "RISCO", quando = 0.7 },
		{ pose = "RECUO_BAIXO", time = 0.18, style = "Quint", dir = "Out" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

	-- 1.14 s
	EXTRA_R = {
		{ pose = "RISCA_CHAO", time = 0.24, style = "Quad", dir = "Out", marca = "CARREGA", quando = 0.6 },
		{ pose = "ERGUE_ARCHOTE", time = 0.26, style = "Back", dir = "Out", marca = "MURALHA", quando = 0.55 },
		{ pose = "ERGUE_ARCHOTE", time = 0.34, style = "Linear", dir = "Out", tremor = 0.026, freq = 14 },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "InOut" },
	},

}

return P
