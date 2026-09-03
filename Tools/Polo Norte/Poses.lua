-- Poses_Magnetismo_V1.lua
-- ModuleScript "Poses" — Polo Norte  (conjunto MAGNETISMO)
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
--   A atração é o caso puro da regra 2: o `PUXA_COTOVELO` tem o tronco a -20° e o pé esquerdo cravado atrás.
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
-- Gerado por FERRAMENTAS/gerar_poses_magnetismo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.CHAMA_PALMA = {
	RightArm = CFrame.new(1.42, 0.04, -0.62) * CFrame.Angles(math.rad(44), math.rad(-22), math.rad(-34)),
	LeftArm = CFrame.new(-1.46, 0.02, -0.2) * CFrame.Angles(math.rad(20), math.rad(8), math.rad(-10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-14), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-4), math.rad(-16), math.rad(0)),
}

P.DIPOLO_ABRE = {
	RightArm = CFrame.new(1.4, 0.5, -0.3) * CFrame.Angles(math.rad(-66), math.rad(-20), math.rad(28)),
	LeftArm = CFrame.new(-1.4, -0.4, -0.3) * CFrame.Angles(math.rad(62), math.rad(20), math.rad(-28)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
}

P.DIPOLO_FECHA = {
	RightArm = CFrame.new(1.28, 0.06, -0.66) * CFrame.Angles(math.rad(46), math.rad(-40), math.rad(-50)),
	LeftArm = CFrame.new(-1.28, 0.06, -0.66) * CFrame.Angles(math.rad(46), math.rad(40), math.rad(50)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.24, 0) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.52, -1.72, -0.34) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.54, -1.76, 0.26) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
}

P.DIPOLO_GIRA = {
	RightArm = CFrame.new(1.34, 0.44, -0.5) * CFrame.Angles(math.rad(-54), math.rad(-46), math.rad(34)),
	LeftArm = CFrame.new(-1.34, -0.34, -0.5) * CFrame.Angles(math.rad(52), math.rad(46), math.rad(-34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-18), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-22), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.2) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.08) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PUXA_COTOVELO = {
	RightArm = CFrame.new(1.3, -0.12, -0.32) * CFrame.Angles(math.rad(70), math.rad(-34), math.rad(-52)),
	LeftArm = CFrame.new(-1.42, -0.06, -0.14) * CFrame.Angles(math.rad(28), math.rad(12), math.rad(-6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-20), math.rad(-8), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.92, 0.24) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.8, -0.36) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.76 s
	PRIMARIA = {
		{ pose = "CHAMA_PALMA", time = 0.2, style = "Quad", dir = "Out" },
		{ pose = "PUXA_COTOVELO", time = 0.26, style = "Quint", dir = "Out", marca = "PUXAR", quando = 0.55 },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "InOut" },
	},

	-- 1.42 s
	EXTRA_R = {
		{ pose = "DIPOLO_ABRE", time = 0.26, style = "Quad", dir = "Out", marca = "ABRE", quando = 0.7 },
		{ pose = "DIPOLO_GIRA", time = 0.34, style = "Sine", dir = "InOut", marca = "CUPULA" },
		{ pose = "DIPOLO_GIRA", time = 0.5, style = "Linear", dir = "Out", tremor = 0.024, freq = 12 },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "InOut" },
	},

	-- 1.28 s
	EXTRA_T = {
		{ pose = "DIPOLO_ABRE", time = 0.3, style = "Back", dir = "Out", marca = "CARREGA", quando = 0.6 },
		{ pose = "DIPOLO_FECHA", time = 0.2, style = "Quint", dir = "In", marca = "IMPLOSAO", quando = 0.85 },
		{ pose = "DIPOLO_FECHA", time = 0.44, style = "Linear", dir = "Out", tremor = 0.042, freq = 19 },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "InOut" },
	},

}

return P
