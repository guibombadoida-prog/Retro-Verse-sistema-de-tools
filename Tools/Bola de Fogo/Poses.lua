-- Poses_Fogo_V1.lua
-- ModuleScript "Poses" — Bola de Fogo  (conjunto PODER DE FOGO)
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
--   Arremesso por cima, com a esquerda de contrapeso. O braço continua depois de a bola sair.
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

P.ARREMESSO_ALTO = {
	RightArm = CFrame.new(1.3, 0.66, 0.32) * CFrame.Angles(math.rad(-148), math.rad(-26), math.rad(34)),
	LeftArm = CFrame.new(-1.42, 0.2, -0.44) * CFrame.Angles(math.rad(40), math.rad(18), math.rad(-18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-20), math.rad(-18), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(-26), math.rad(0)),
}

P.ARREMESSO_SOLTA = {
	RightArm = CFrame.new(1.46, -0.08, -1.0) * CFrame.Angles(math.rad(44), math.rad(32), math.rad(-16)),
	LeftArm = CFrame.new(-1.36, -0.02, 0.24) * CFrame.Angles(math.rad(-14), math.rad(-16), math.rad(16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(10), math.rad(26), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(14), math.rad(30), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.84, -0.32) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.88, 0.24) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
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

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.66 s
	PRIMARIA = {
		{ pose = "ARREMESSO_ALTO", time = 0.18, style = "Back", dir = "Out" },
		{ pose = "ARREMESSO_SOLTA", time = 0.1, style = "Quint", dir = "Out", marca = "LANCA", quando = 0.25 },
		{ pose = "ARREMESSO_SOLTA", time = 0.14, style = "Linear", dir = "Out" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "InOut" },
	},

	-- 0.88 s
	EXTRA_R = {
		{ pose = "ARREMESSO_ALTO", time = 0.26, style = "Quad", dir = "Out", marca = "CARREGA", quando = 0.7 },
		{ pose = "ARREMESSO_SOLTA", time = 0.12, style = "Quint", dir = "Out", marca = "ESTILHACO", quando = 0.3 },
		{ pose = "RECUO_BAIXO", time = 0.24, style = "Quad", dir = "Out" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

}

return P
