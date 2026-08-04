--[[
	Poses_Escudos_EscudoCiclone_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — invocar cinco escudos é gesto de MAESTRO, não de lutador. O braço
	sobe e roda no alto — é o giro do pulso que chama a órbita. O corpo abre,
	porque cinco discos vão passar rente a ele. No colapso o gesto inverte: o
	punho FECHA, e é o fechar que traz os cinco para o centro.

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
	-- Repouso: escudo baixo
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-6, 0, 4),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO,
	},

	-- 1. Chamar: o braço sobe ao alto, palma para cima
	INVOCAR_1 = {
		RightArm = BASE_BRACO_D * graus(-168, 0, 22),
		LeftArm  = BASE_BRACO_E * graus(-30, 0, -22),
		Head     = BASE_CABECA * graus(-28, 0, 0),
		HRP      = BASE_TRONCO * graus(-12, 0, 0),
	},

	-- 2. Rodar: o pulso gira e a órbita pega. O corpo abre para
	--    deixar os cinco discos passarem rente
	INVOCAR_2 = {
		RightArm = BASE_BRACO_D * graus(-150, 0, 62),
		LeftArm  = BASE_BRACO_E * graus(-46, 0, -58),
		Head     = BASE_CABECA * graus(-16, 0, 0),
		HRP      = BASE_TRONCO * graus(-4, 0, 0),
	},

	-- Extra 1: a mão abre no alto, pegando os cinco
	COLAPSO_1 = {
		RightArm = BASE_BRACO_D * graus(-172, 0, 8),
		LeftArm  = BASE_BRACO_E * graus(-166, 0, -8),
		Head     = BASE_CABECA * graus(-30, 0, 0),
		HRP      = BASE_TRONCO * graus(-16, 0, 0),
	},

	-- Extra 2: FECHA. O punho desce e os cinco vêm junto —
	--    é o quadro de impacto do colapso
	COLAPSO_2 = {
		RightArm = BASE_BRACO_D * graus(-18, 0, 12),
		LeftArm  = BASE_BRACO_E * graus(-14, 0, -12),
		Head     = BASE_CABECA * graus(26, 0, 0),
		HRP      = BASE_TRONCO * graus(28, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-20, 0, 4),
		LeftLeg  = BASE_PERNA_E * graus(8, 0, -4),
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
	INVOCAR = {
		{ pose = "INVOCAR_1", time = 0.20, style = "Back", dir = "Out" },
		{ pose = "INVOCAR_2", time = 0.26, style = "Quad", dir = "InOut", tremor = 0.02 },
	},
	COLAPSO = {
		{ pose = "COLAPSO_1", time = 0.20, style = "Back", dir = "In", tremor = 0.04 },
		{ pose = "COLAPSO_2", time = 0.10, style = "Quint", dir = "Out", tremor = 0.07 },
		{ pose = "REPOUSO", time = 0.30, style = "Quad", dir = "Out" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "INVOCAR"
end

function Poses.extra()
	return "COLAPSO"
end

return Poses
