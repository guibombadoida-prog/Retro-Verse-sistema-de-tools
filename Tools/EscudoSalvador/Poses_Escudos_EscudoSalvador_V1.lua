--[[
	Poses_Escudos_EscudoSalvador_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — a Tool que MAIS custa a quem usa. O gesto é de oferecer: o escudo
	vai à frente com as duas mãos, a cabeça baixa. Depois o corpo ENCOLHE — o
	vínculo já está feito e a dor do aliado começa a chegar. O encolher é o ponto:
	sem ele a habilidade parece um buff, e não um sacrifício.

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
	-- Repouso: escudo ao lado
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-6, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Oferecer: as duas mãos levam o escudo à frente, cabeça baixa
	OFERECER_1 = {
		RightArm = BASE_BRACO_D * graus(-92, 0, -12),
		LeftArm  = BASE_BRACO_E * graus(-88, 0, 12),
		Head     = BASE_CABECA * graus(24, 0, 0),
		HRP      = BASE_TRONCO * graus(12, 0, 0),
	},

	-- 2. Encolher: o vínculo fecha e o peso vem. É o quadro que diz
	--    que isto CUSTA — sem ele a pose lê como buff
	OFERECER_2 = {
		RightArm = BASE_BRACO_D * graus(-56, 0, 26),
		LeftArm  = BASE_BRACO_E * graus(-52, 0, -26),
		Head     = BASE_CABECA * graus(32, 0, 0),
		HRP      = BASE_TRONCO * graus(22, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-14, 0, 0),
		LeftLeg  = BASE_PERNA_E * graus(-10, 0, 0),
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
		{ pose = "REPOUSO", time = 0.24, style = "Quad", dir = "Out" },
	},
	OFERECER = {
		{ pose = "OFERECER_1", time = 0.22, style = "Back", dir = "Out" },
		{ pose = "OFERECER_2", time = 0.30, style = "Quad", dir = "InOut", tremor = 0.02 },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "OFERECER"
end

return Poses
