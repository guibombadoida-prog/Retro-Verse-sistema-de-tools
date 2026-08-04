--[[
	Poses_Escudos_EscudoSkate_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — o escudo vai para o CHÃO e o corpo vai para cima dele. A pose é
	de surfista: joelhos dobrados, tronco baixo e inclinado para a frente, braços
	abertos para equilibrar. É a única Tool do conjunto que usa perna de verdade —
	sem a dobra do joelho ninguém acredita que está montado em alguma coisa.

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
	-- Repouso: escudo ao lado, postura normal
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-6, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Jogar o escudo no chão e pisar em cima
	MONTAR_1 = {
		RightArm = BASE_BRACO_D * graus(-30, 0, 44),
		LeftArm  = BASE_BRACO_E * graus(-20, 0, -20),
		Head     = BASE_CABECA * graus(18, 0, 0),
		HRP      = BASE_TRONCO * graus(20, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-18, 0, 0),
		LeftLeg  = BASE_PERNA_E * graus(6, 0, 0),
	},

	-- 2. Andar: tronco baixo, joelhos dobrados, braços abertos.
	--    É esta pose que segura os 5 s de corrida
	MONTAR_2 = {
		RightArm = BASE_BRACO_D * graus(-64, 0, 58),
		LeftArm  = BASE_BRACO_E * graus(-58, 0, -56),
		Head     = BASE_CABECA * graus(-6, 0, 0),
		HRP      = BASE_TRONCO * graus(26, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-32, 0, 6),
		LeftLeg  = BASE_PERNA_E * graus(14, 0, -4),
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
	MONTAR = {
		{ pose = "MONTAR_1", time = 0.14, style = "Back", dir = "Out" },
		{ pose = "MONTAR_2", time = 0.20, style = "Quad", dir = "InOut" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "MONTAR"
end

return Poses
