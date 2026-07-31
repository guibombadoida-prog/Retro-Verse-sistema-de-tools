--[[
	Poses_Template_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 — pose, ritmo e dramaturgia são AUTORAIS

	Formato do R6CFrameAnimator V1 canônico do projeto.

	Cada pose é o C0 de um Weld que o animator cria:

		RightArm   Torso → Right Arm          base CFrame.new( 1.5, 0,   0)
		LeftArm    Torso → Left Arm           base CFrame.new(-1.5, 0,   0)
		Head       Torso → Head               base CFrame.new( 0,   1.5, 0)
		HRP        HumanoidRootPart → Torso   base CFrame.new()

	⚠️ NÃO escreva em Motor6D ("Right Shoulder", "Neck"…). O script `Animate`
	padrão do Roblox escreve nesses mesmos Motor6D todo frame — os dois brigam
	pela mesma junta, e a animação treme e volta sozinha. O animator canônico
	existe justamente para não cair nisso: ele solda juntas próprias.

	O animator não solda pernas. Se a pose precisar de perna, é decisão de
	estender o animator — e aí é V2 declarada, não improviso local.

	Variação entre golpes vem de ÍNDICE SEQUENCIAL, nunca de math.random (§10).
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
-- SEQUÊNCIAS — o Server toca uma pose por vez, com PlayPose(nome, duracao)
--==============================================================================

local GOLPE_A = {
	{ pose = "GOLPE_A_1", duracao = 0.10 },
	{ pose = "GOLPE_A_2", duracao = 0.16 },
	{ pose = "NEUTRO",    duracao = 0.18 },
}

local GOLPE_B = {
	{ pose = "GOLPE_B_1", duracao = 0.10 },
	{ pose = "GOLPE_B_2", duracao = 0.16 },
	{ pose = "NEUTRO",    duracao = 0.18 },
}

local CICLO = { GOLPE_A, GOLPE_B }

-- `contador` é o índice sequencial do golpe, vindo do Server Script.
function Poses.golpe(contador)
	local indice = ((contador - 1) % #CICLO) + 1
	return CICLO[indice]
end

local EXTRA = {
	{ pose = "EXTRA_1", duracao = 0.22 },
	{ pose = "EXTRA_2", duracao = 0.14 },
	{ pose = "NEUTRO",  duracao = 0.26 },
}

function Poses.extra()
	return EXTRA
end

return Poses
