-- Poses_Fogo_V1.lua
-- ModuleScript "Poses" — Lanca Chamas  (conjunto PODER DE FOGO)
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
-- ESTA TOOL LIDERA POR `RightArm`.
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
--   O quadro de 0.54 s É o jato — ele dura enquanto o corpo segura, e o tremor rápido (24 Hz) é o do bico.
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

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.08) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.JATO_MIRA = {
	RightArm = CFrame.new(1.5, 0.02, -1.02) * CFrame.Angles(math.rad(4), math.rad(-10), math.rad(-4)),
	LeftArm = CFrame.new(-1.3, -0.06, -0.8) * CFrame.Angles(math.rad(30), math.rad(40), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(2), math.rad(-14), math.rad(0)),
}

P.JATO_SEGURA = {
	RightArm = CFrame.new(1.52, -0.02, -1.06) * CFrame.Angles(math.rad(8), math.rad(-8), math.rad(-6)),
	LeftArm = CFrame.new(-1.28, -0.1, -0.84) * CFrame.Angles(math.rad(34), math.rad(44), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-12), math.rad(-18), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(6), math.rad(-16), math.rad(0)),
	RightLeg = CFrame.new(0.52, -1.78, -0.34) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.82, 0.26) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
}

P.RECUO_BAIXO = {
	RightArm = CFrame.new(1.34, -0.2, -0.44) * CFrame.Angles(math.rad(46), math.rad(-18), math.rad(-28)),
	LeftArm = CFrame.new(-1.36, -0.16, -0.36) * CFrame.Angles(math.rad(40), math.rad(16), math.rad(24)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), math.rad(12), math.rad(0)),
	HRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.52, -1.68, -0.4) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.74, 0.28) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.96 s
	PRIMARIA = {
		{ pose = "JATO_MIRA", time = 0.16, style = "Quad", dir = "Out", marca = "JATO", quando = 0.6 },
		{ pose = "JATO_SEGURA", time = 0.54, style = "Linear", dir = "Out", tremor = 0.022, freq = 24 },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

	-- 0.96 s
	EXTRA_R = {
		{ pose = "JATO_MIRA", time = 0.24, style = "Quad", dir = "Out", marca = "CARREGA", quando = 0.65 },
		{ pose = "JATO_SEGURA", time = 0.14, style = "Quint", dir = "Out", marca = "COMBUSTAO", quando = 0.3 },
		{ pose = "RECUO_BAIXO", time = 0.3, style = "Quad", dir = "Out", tremor = 0.042, freq = 18 },
		{ pose = "IDLE", time = 0.28, style = "Quad", dir = "InOut" },
	},

}

return P
