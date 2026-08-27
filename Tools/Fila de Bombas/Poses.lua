-- Poses_Bomba_V1.lua
-- ModuleScript "Poses" — Fila de Bombas  (conjunto PODERES DE BOMBA)
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

P.AGACHA = {
	RightArm = CFrame.new(1.42, -0.62, -0.5) * CFrame.Angles(math.rad(8), math.rad(-6), math.rad(10)),
	LeftArm = CFrame.new(-1.44, -0.3, -0.34) * CFrame.Angles(math.rad(20), math.rad(8), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.78, 0) * CFrame.Angles(math.rad(26), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.44, -0.5) * CFrame.Angles(math.rad(-54), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.7, -0.26) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
}

P.RECUA = {
	RightArm = CFrame.new(1.5, 0.24, 0.4) * CFrame.Angles(math.rad(-26), math.rad(-10), math.rad(14)),
	LeftArm = CFrame.new(-1.5, 0.24, 0.4) * CFrame.Angles(math.rad(-26), math.rad(10), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.82, 0.42) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.78, -0.4) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.18) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.49, 0.02, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.PRESSIONA = {
	RightArm = CFrame.new(1.36, 0.02, -0.68) * CFrame.Angles(math.rad(62), math.rad(-20), math.rad(-26)),
	LeftArm = CFrame.new(-1.36, 0.02, -0.68) * CFrame.Angles(math.rad(62), math.rad(20), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- plantar — 0.97 s
	PLANTAR = {
		{ pose = "AGACHA", time = 0.2, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "AGACHA", time = 0.17, style = "Sine", dir = "InOut", marca = "PLANTA" },
		{ pose = "RECUA", time = 0.34, style = "Quint", dir = "Out", marca = "RECUA" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- apertar — 0.55 s
	DETONAR = {
		{ pose = "PRESSIONA", time = 0.14, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "PRESSIONA", time = 0.09, style = "Quint", dir = "Out", marca = "ESTOURA" },
		{ pose = "IDLE", time = 0.32, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
