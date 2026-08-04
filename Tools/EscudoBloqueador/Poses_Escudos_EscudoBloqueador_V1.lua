--[[
	Poses_Escudos_EscudoBloqueador_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 — pose, ritmo e dramaturgia são AUTORAIS

	Formato do R6CFrameAnimator V2 canônico do projeto.

	Cada pose é o C0 de um Weld que o animator cria:

		RightArm   Torso → Right Arm          base CFrame.new( 1.5,  0,   0)
		LeftArm    Torso → Left Arm           base CFrame.new(-1.5,  0,   0)
		Head       Torso → Head               base CFrame.new( 0,    1.5, 0)
		HRP        HumanoidRootPart → Torso   base CFrame.new()
		RightLeg   Torso → Right Leg          base CFrame.new( 0.5, -2,   0)   sob demanda
		LeftLeg    Torso → Left Leg           base CFrame.new(-0.5, -2,   0)   sob demanda

	⚠️ NÃO escreva em Motor6D. O script `Animate` padrão do Roblox escreve nessas
	mesmas juntas todo frame — os dois brigam e a animação treme.

	PERNA É SOB DEMANDA e é solta no fim (ReleaseLegs). Perna soldada
	permanentemente TRAVA A CAMINHADA.

	DRAMATURGIA — o bloqueador não ataca. Ele PLANTA. O braço do escudo sobe e
	trava, o tronco gira para pôr o escudo entre o corpo e a ameaça, e o peso
	desce para a perna de trás. É postura de quem vai aguentar, não de quem vai
	revidar.

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
local BASE_PERNA_D = CFrame.new(0.5, -2, 0)
local BASE_PERNA_E = CFrame.new(-0.5, -2, 0)

--==============================================================================
-- POSES
--==============================================================================

Poses.POSES = {
	-- Repouso: escudo baixo, ao lado do corpo. Não é a base pura — o braço do
	-- escudo já fica um pouco à frente, senão a Tool some atrás do personagem.
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-18, 0, -6),
		LeftArm  = BASE_BRACO_E * graus(-8, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Erguer: o braço sobe rápido e o tronco gira para trazer o escudo à frente
	GUARDA_1 = {
		RightArm = BASE_BRACO_D * graus(-88, 0, 34),
		LeftArm  = BASE_BRACO_E * graus(-42, 0, 22),
		Head     = BASE_CABECA * graus(6, 26, 0),
		HRP      = BASE_TRONCO * graus(0, -30, 0),
	},

	-- 2. Travar: o escudo assenta e o peso desce. É o quadro que segura — a
	--    redução do Núcleo entra aqui, não no fim.
	GUARDA_2 = {
		RightArm = BASE_BRACO_D * graus(-80, 0, 26),
		LeftArm  = BASE_BRACO_E * graus(-38, 0, 16),
		Head     = BASE_CABECA * graus(10, 20, 0),
		HRP      = BASE_TRONCO * graus(8, -24, 0),
	},

	-- Extra 1: os dois braços sobem, o escudo vai ao alto
	BARREIRA_1 = {
		RightArm = BASE_BRACO_D * graus(-160, 0, 20),
		LeftArm  = BASE_BRACO_E * graus(-155, 0, -18),
		Head     = BASE_CABECA * graus(-22, 0, 0),
		HRP      = BASE_TRONCO * graus(-14, 0, 0),
	},

	-- Extra 2: crava no chão. É o quadro de impacto da cúpula.
	BARREIRA_2 = {
		RightArm = BASE_BRACO_D * graus(-14, 0, 8),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, -8),
		Head     = BASE_CABECA * graus(16, 0, 0),
		HRP      = BASE_TRONCO * graus(24, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-24, 0, 4),
		LeftLeg  = BASE_PERNA_E * graus(10, 0, -4),
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
	REPOUSO = {
		{ pose = "REPOUSO", time = 0.22, style = "Quad", dir = "Out" },
	},
	GUARDA = {
		{ pose = "GUARDA_1", time = 0.10, style = "Back",  dir = "Out" },
		{ pose = "GUARDA_2", time = 0.16, style = "Quint", dir = "Out" },
	},
	BARREIRA = {
		{ pose = "BARREIRA_1", time = 0.24, style = "Back",  dir = "In" },
		{ pose = "BARREIRA_2", time = 0.12, style = "Quint", dir = "Out", tremor = 0.05 },
		{ pose = "REPOUSO",    time = 0.30, style = "Quad",  dir = "Out" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "GUARDA"
end

function Poses.extra()
	return "BARREIRA"
end

return Poses
