--[[
	Poses_Escudos_EscudoPartido_V1  —  ModuleScript "Poses", filho direto da Tool
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

	DRAMATURGIA — o escudo virou lâmina, e a pose acompanha: nada de guarda, tudo de
	CORTE. O braço cruza o corpo e sai em diagonal, como quem desembainha. Na
	sentença o corpo trava — a cutscene precisa de um corpo parado no centro para
	os dois escudos girarem em volta, e personagem andando quebraria o
	enquadramento. Por isso o Server chama LockCharacter na Extra, e só nela.

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
	-- Repouso: a lâmina baixa, de lado. Postura de esgrima, não de escudo
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-20, 0, -22),
		LeftArm  = BASE_BRACO_E * graus(-8, 0, 10),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO * graus(0, 8, 0),
	},

	-- 1. Recolher: o braço cruza o peito, como quem desembainha
	CORTE_1 = {
		RightArm = BASE_BRACO_D * graus(-44, 0, 96),
		LeftArm  = BASE_BRACO_E * graus(-20, 0, -34),
		Head     = BASE_CABECA * graus(0, -26, 0),
		HRP      = BASE_TRONCO * graus(0, 34, 0),
	},

	-- 2. Cortar: sai em diagonal. Quadro de impacto — a lâmina nasce
	--    aqui, e o dano entra aqui
	CORTE_2 = {
		RightArm = BASE_BRACO_D * graus(-104, 0, -58),
		LeftArm  = BASE_BRACO_E * graus(-12, 0, 20),
		Head     = BASE_CABECA * graus(0, 30, 0),
		HRP      = BASE_TRONCO * graus(0, -42, 0),
	},

	-- 3. Sobrar: o braço passa do ponto e para. Sem retorno — o escudo
	--    partiu e não volta
	CORTE_3 = {
		RightArm = BASE_BRACO_D * graus(-62, 0, -30),
		LeftArm  = BASE_BRACO_E * graus(-8, 0, 12),
		Head     = BASE_CABECA * graus(0, 14, 0),
		HRP      = BASE_TRONCO * graus(0, -18, 0),
	},

	-- Extra 1: a lâmina sobe à altura do rosto. Aponta o alvo
	SENTENCA_1 = {
		RightArm = BASE_BRACO_D * graus(-118, 0, 16),
		LeftArm  = BASE_BRACO_E * graus(-22, 0, -14),
		Head     = BASE_CABECA * graus(-12, 12, 0),
		HRP      = BASE_TRONCO * graus(0, -10, 0),
	},

	-- Extra 2: corpo travado, lâmina firme. O Server chama LockCharacter
	--    aqui — a cutscene precisa do corpo parado
	SENTENCA_2 = {
		RightArm = BASE_BRACO_D * graus(-98, 0, 6),
		LeftArm  = BASE_BRACO_E * graus(-18, 0, -8),
		Head     = BASE_CABECA * graus(-4, 0, 0),
		HRP      = BASE_TRONCO * graus(-6, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-8, 0, 2),
		LeftLeg  = BASE_PERNA_E * graus(6, 0, -2),
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
	CORTE = {
		{ pose = "CORTE_1", time = 0.10, style = "Back", dir = "In" },
		{ pose = "CORTE_2", time = 0.07, style = "Quint", dir = "Out" },
		{ pose = "CORTE_3", time = 0.14, style = "Quad", dir = "Out" },
		{ pose = "REPOUSO", time = 0.22, style = "Quad", dir = "InOut" },
	},
	SENTENCA = {
		{ pose = "SENTENCA_1", time = 0.26, style = "Back", dir = "Out", tremor = 0.02 },
		{ pose = "SENTENCA_2", time = 0.34, style = "Quad", dir = "InOut", tremor = 0.05 },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "CORTE"
end

function Poses.extra()
	return "SENTENCA"
end

return Poses
