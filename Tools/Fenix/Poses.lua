-- Poses_Fogo_V1.lua
-- ModuleScript "Poses" — Fenix  (conjunto PODER DE FOGO)
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
--   O `RENASCER` é a ÚNICA pose do conjunto que abre para o fogo e joga a cabeça para trás — ali o fogo é do personagem.
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

P.ASA_ABRE = {
	RightArm = CFrame.new(1.36, 0.4, 0.5) * CFrame.Angles(math.rad(-60), math.rad(-58), math.rad(32)),
	LeftArm = CFrame.new(-1.36, 0.4, 0.5) * CFrame.Angles(math.rad(-60), math.rad(58), math.rad(-32)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

P.ASA_CORTA = {
	RightArm = CFrame.new(1.44, -0.02, -0.94) * CFrame.Angles(math.rad(22), math.rad(40), math.rad(-22)),
	LeftArm = CFrame.new(-1.44, -0.02, -0.94) * CFrame.Angles(math.rad(22), math.rad(-40), math.rad(22)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, -0.28) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.86, 0.28) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(6)),
	LeftArm = CFrame.new(-1.49, 0.04, -0.08) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.RENASCER = {
	RightArm = CFrame.new(1.3, 0.7, 0.16) * CFrame.Angles(math.rad(-160), math.rad(-34), math.rad(40)),
	LeftArm = CFrame.new(-1.3, 0.7, 0.16) * CFrame.Angles(math.rad(-160), math.rad(34), math.rad(-40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.16, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -2.06, 0.16) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -2.06, 0.16) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- 0.54 s
	PRIMARIA = {
		{ pose = "ASA_ABRE", time = 0.18, style = "Back", dir = "Out" },
		{ pose = "ASA_CORTA", time = 0.1, style = "Quint", dir = "Out", marca = "ASA", quando = 0.3 },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "InOut" },
	},

	-- 1.38 s
	EXTRA_R = {
		{ pose = "ASA_ABRE", time = 0.24, style = "Quad", dir = "Out", marca = "CARREGA", quando = 0.6 },
		{ pose = "RENASCER", time = 0.36, style = "Back", dir = "Out", marca = "RENASCER", quando = 0.45 },
		{ pose = "RENASCER", time = 0.44, style = "Linear", dir = "Out", tremor = 0.02, freq = 10 },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "InOut" },
	},

}

return P
