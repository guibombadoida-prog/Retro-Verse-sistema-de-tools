--[[
	Poses_Escudos_EscudoBumerangue_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — arremessar um escudo não é arremessar uma pedra. O braço abre
	PARA TRÁS carregando o peso, o tronco gira junto, e o disco sai no giro do
	tronco — não do cotovelo. O braço fica estendido esperando o retorno, que é
	o que diferencia esta Tool do Escudo Partido: aqui a mão sabe que volta.

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
	-- Repouso: escudo baixo, pronto para carregar
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-6, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Carregar: o braço vai para trás e o tronco gira contra
	ARREMESSO_1 = {
		RightArm = BASE_BRACO_D * graus(-52, 0, 74),
		LeftArm  = BASE_BRACO_E * graus(-26, 0, -30),
		Head     = BASE_CABECA * graus(0, -32, 0),
		HRP      = BASE_TRONCO * graus(0, 40, 0),
	},

	-- 2. Soltar: o giro do tronco joga o disco. Quadro de impacto —
	--    a lâmina nasce aqui, não no fim da sequência
	ARREMESSO_2 = {
		RightArm = BASE_BRACO_D * graus(-96, 0, -46),
		LeftArm  = BASE_BRACO_E * graus(-14, 0, 16),
		Head     = BASE_CABECA * graus(0, 26, 0),
		HRP      = BASE_TRONCO * graus(0, -38, 0),
	},

	-- 3. Esperar: braço estendido, mão aberta. O escudo volta para cá
	ARREMESSO_3 = {
		RightArm = BASE_BRACO_D * graus(-78, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, 8),
		Head     = BASE_CABECA * graus(0, 8, 0),
		HRP      = BASE_TRONCO * graus(0, -10, 0),
	},

	-- Extra 1: os dois braços recolhem — vão sair três de uma vez
	TRINCA_1 = {
		RightArm = BASE_BRACO_D * graus(-40, 0, 62),
		LeftArm  = BASE_BRACO_E * graus(-40, 0, -62),
		Head     = BASE_CABECA * graus(-10, 0, 0),
		HRP      = BASE_TRONCO * graus(-8, 0, 0),
	},

	-- Extra 2: abre em leque, os três saem juntos
	TRINCA_2 = {
		RightArm = BASE_BRACO_D * graus(-92, 0, -34),
		LeftArm  = BASE_BRACO_E * graus(-86, 0, 34),
		Head     = BASE_CABECA * graus(6, 0, 0),
		HRP      = BASE_TRONCO * graus(10, 0, 0),
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
	ARREMESSO = {
		{ pose = "ARREMESSO_1", time = 0.14, style = "Back", dir = "In" },
		{ pose = "ARREMESSO_2", time = 0.09, style = "Quint", dir = "Out" },
		{ pose = "ARREMESSO_3", time = 0.18, style = "Quad", dir = "Out" },
		{ pose = "REPOUSO", time = 0.24, style = "Quad", dir = "InOut" },
	},
	TRINCA = {
		{ pose = "TRINCA_1", time = 0.18, style = "Back", dir = "In", tremor = 0.03 },
		{ pose = "TRINCA_2", time = 0.10, style = "Quint", dir = "Out" },
		{ pose = "REPOUSO", time = 0.28, style = "Quad", dir = "Out" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "ARREMESSO"
end

function Poses.extra()
	return "TRINCA"
end

return Poses
