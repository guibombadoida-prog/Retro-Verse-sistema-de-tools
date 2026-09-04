-- Poses_Bomba_V1.lua
-- ModuleScript "Poses" — Coca Explosiva  (conjunto PODERES DE BOMBA)
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
-- A GRAMÁTICA: O PESO SAI DA MÃO
--
--   Nos conjuntos anteriores o braço CARREGA alguma coisa e a solta. Aqui o
--   corpo larga o peso e depois RECUA dele — e por isso o quadro mais longo
--   não é a carga, é o recuo. Bomba plantada sem recuo lê como objeto
--   largado.
--
-- Gerado por FERRAMENTAS/gerar_poses_bombas7.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local P = {}

P.CHACOALHA = {
	RightArm = CFrame.new(1.4, 0.44, -0.52) * CFrame.Angles(math.rad(96), math.rad(-18), math.rad(-18)),
	LeftArm = CFrame.new(-1.4, 0.44, -0.52) * CFrame.Angles(math.rad(96), math.rad(18), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
}

P.LANCA = {
	RightArm = CFrame.new(1.5, 0.2, -1.24) * CFrame.Angles(math.rad(88), math.rad(8), math.rad(-10)),
	LeftArm = CFrame.new(-1.42, -0.08, 0.28) * CFrame.Angles(math.rad(-14), math.rad(-12), math.rad(20)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(18), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(6), math.rad(30), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.76, 0.44) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.49, 0.02, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.APONTA = {
	RightArm = CFrame.new(1.52, 0.24, -1.22) * CFrame.Angles(math.rad(88), math.rad(-6), math.rad(-4)),
	LeftArm = CFrame.new(-1.45, 0.06, -0.24) * CFrame.Angles(math.rad(22), math.rad(10), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-8), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(2), math.rad(12), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- chacoalhar — 0.75 s
	GARRAFA = {
		{ pose = "CHACOALHA", time = 0.3, style = "Sine", dir = "InOut", tremor = 0.07, freq = 34, marca = "CARGA" },
		{ pose = "LANCA", time = 0.11, style = "Quint", dir = "Out", marca = "LANCA" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- apontar — 0.60 s
	JATO = {
		{ pose = "APONTA", time = 0.16, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "APONTA", time = 0.12, style = "Quint", dir = "Out", marca = "MANDA" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
