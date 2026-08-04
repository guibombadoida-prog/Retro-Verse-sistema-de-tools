--[[
	Poses_GravidadeTelecinese_MarionetePsi_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 — pose, ritmo e dramaturgia são AUTORAIS

	Formato do R6CFrameAnimator V2 canônico do projeto.

	Cada pose é o C0 de um Weld que o animator cria:

		RightArm   Torso → Right Arm          base CFrame.new( 1.5,  0,   0)
		LeftArm    Torso → Left Arm           base CFrame.new(-1.5,  0,   0)
		Head       Torso → Head               base CFrame.new( 0,    1.5, 0)
		HRP        HumanoidRootPart → Torso   base CFrame.new()
		RightLeg   Torso → Right Leg          base CFrame.new( 0.5, -2,   0)   sob demanda
		LeftLeg    Torso → Left Leg           base CFrame.new(-0.5, -2,   0)   sob demanda

	⚠️ NÃO escreva em Motor6D ("Right Shoulder", "Neck"…). O script `Animate`
	padrão do Roblox escreve nesses mesmos Motor6D todo frame — os dois brigam
	pela mesma junta, e a animação treme e volta sozinha. O animator canônico
	existe justamente para não cair nisso: ele solda juntas próprias.

	PERNA É SOB DEMANDA. O Weld só nasce quando uma pose cita RightLeg/LeftLeg,
	e o animator o solta no fim da sequência (ReleaseLegs). Perna soldada
	permanentemente TRAVA A CAMINHADA: o Humanoid deixa de mandar nela. Se você
	tocar pose de perna por PlayPose avulso, chame rig:ReleaseLegs() você mesmo.

	Junta com nome fora dessa lista é erro silencioso — a pose simplesmente
	não sai. Pose cita SÓ as juntas que mexem; junta ausente fica onde estava.

	Variação entre golpes vem de ÍNDICE SEQUENCIAL, nunca de math.random (§10).

	Ver DIRETRIZES/REGRA_ANIMACAO_R6.md.
--]]

local Poses = {}

local function graus(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local BASE_BRACO_D = CFrame.new(1.5, 0, 0)
local BASE_BRACO_E = CFrame.new(-1.5, 0, 0)
local BASE_CABECA  = CFrame.new(0, 1.5, 0)
local BASE_TRONCO  = CFrame.new()

--==============================================================================
-- POSES
--==============================================================================

Poses.POSES = {
	NEUTRO = {
		RightArm = BASE_BRACO_D,
		LeftArm  = BASE_BRACO_E,
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- Golpe A: braço direito sobe e desce
	GOLPE_A_1 = {
		RightArm = BASE_BRACO_D * graus(-150, 0, 25),
		LeftArm  = BASE_BRACO_E * graus(-25, 0, -20),
		HRP      = BASE_TRONCO * graus(0, -12, 0),
	},
	GOLPE_A_2 = {
		RightArm = BASE_BRACO_D * graus(-35, 0, -10),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, -15),
		HRP      = BASE_TRONCO * graus(0, 18, 0),
	},

	-- Golpe B: corte lateral
	GOLPE_B_1 = {
		RightArm = BASE_BRACO_D * graus(-40, 0, 80),
		LeftArm  = BASE_BRACO_E * graus(-20, 0, -30),
		HRP      = BASE_TRONCO * graus(0, 15, 0),
	},
	GOLPE_B_2 = {
		RightArm = BASE_BRACO_D * graus(-60, 0, -55),
		LeftArm  = BASE_BRACO_E * graus(-15, 0, -10),
		HRP      = BASE_TRONCO * graus(0, -20, 0),
	},

	-- Habilidade Extra: os dois braços ao alto, depois abrindo
	EXTRA_1 = {
		RightArm = BASE_BRACO_D * graus(-175, 0, 15),
		LeftArm  = BASE_BRACO_E * graus(-175, 0, -15),
		Head     = BASE_CABECA * graus(-15, 0, 0),
		HRP      = BASE_TRONCO * graus(-12, 0, 0),
	},
	EXTRA_2 = {
		RightArm = BASE_BRACO_D * graus(-20, 0, 45),
		LeftArm  = BASE_BRACO_E * graus(-20, 0, -45),
		Head     = BASE_CABECA * graus(10, 0, 0),
		HRP      = BASE_TRONCO * graus(20, 0, 0),
	},
}

--==============================================================================
-- SEQUÊNCIAS — timeline do V2: o animator encadeia por Tween.Completed.
--
-- `time` é a duração do beat; `style`/`dir` são o easing. Encadear com
-- task.wait(duracao) some ~1 frame por beat e é proibido pela
-- DIRETRIZES/REGRA_ANIMACAO_R6.md — quem encadeia é o animator.
--==============================================================================

Poses.SEQUENCIAS = {
	-- Back/In na carga, Quint/Out no golpe: é o easing que vende o peso.
	GOLPE_A = {
		{ pose = "GOLPE_A_1", time = 0.10, style = "Back",  dir = "In"  },
		{ pose = "GOLPE_A_2", time = 0.16, style = "Quint", dir = "Out" },
		{ pose = "NEUTRO",    time = 0.18, style = "Quad",  dir = "Out" },
	},
	GOLPE_B = {
		{ pose = "GOLPE_B_1", time = 0.10, style = "Back",  dir = "In"  },
		{ pose = "GOLPE_B_2", time = 0.16, style = "Quint", dir = "Out" },
		{ pose = "NEUTRO",    time = 0.18, style = "Quad",  dir = "Out" },
	},
	EXTRA = {
		{ pose = "EXTRA_1", time = 0.22, style = "Back",  dir = "In", tremor = 0.03 },
		{ pose = "EXTRA_2", time = 0.14, style = "Quint", dir = "Out" },
		{ pose = "NEUTRO",  time = 0.26, style = "Quad",  dir = "Out" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

local CICLO = { "GOLPE_A", "GOLPE_B" }

-- `contador` é o índice sequencial do golpe, vindo do Server Script.
-- É isto que substitui math.random: a variação é determinística.
function Poses.golpe(contador)
	local indice = ((contador - 1) % #CICLO) + 1
	return CICLO[indice]
end

function Poses.extra()
	return "EXTRA"
end

return Poses
