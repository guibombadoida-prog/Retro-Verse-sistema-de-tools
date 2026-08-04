--[[
	Poses_Escudos_EscudoProtecao_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — não é bloqueio, é ÓRBITA. O portador SOLTA o escudo e ele passa
	a girar sozinho. A pose é de quem entregou o objeto ao ar: a mão abre e sobe,
	o olhar acompanha o disco, e o corpo relaxa — quem já está protegido não
	precisa ficar tenso.

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
	-- Repouso: escudo na mão, baixo
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-6, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Erguer: o escudo sobe à altura do peito
	SOLTAR_1 = {
		RightArm = BASE_BRACO_D * graus(-76, 0, 28),
		LeftArm  = BASE_BRACO_E * graus(-30, 0, -12),
		Head     = BASE_CABECA * graus(-14, 0, 0),
		HRP      = BASE_TRONCO * graus(-6, 0, 0),
	},

	-- 2. Soltar: a mão abre e o disco vai. O olhar segue
	SOLTAR_2 = {
		RightArm = BASE_BRACO_D * graus(-128, 0, 14),
		LeftArm  = BASE_BRACO_E * graus(-24, 0, -8),
		Head     = BASE_CABECA * graus(-26, 0, 0),
		HRP      = BASE_TRONCO * graus(-10, 0, 0),
	},

	-- 3. Relaxar: o corpo desce, a órbita se sustenta sozinha
	SOLTAR_3 = {
		RightArm = BASE_BRACO_D * graus(-22, 0, 10),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, -6),
		Head     = BASE_CABECA * graus(-6, 0, 0),
		HRP      = BASE_TRONCO,
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
	SOLTAR = {
		{ pose = "SOLTAR_1", time = 0.14, style = "Back", dir = "In" },
		{ pose = "SOLTAR_2", time = 0.12, style = "Quint", dir = "Out" },
		{ pose = "SOLTAR_3", time = 0.26, style = "Quad", dir = "InOut" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "SOLTAR"
end

return Poses
