--[[
	Poses_GuardiaoDoTempo_Cronostase_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1

	V3 — POSES AUTORAIS DE VERDADE, no formato do R6CFrameAnimator V2.

	A V2 deste arquivo declarava as poses como "autorais" mas emitia as três
	iguais à BASE dos Welds — ou seja, a sequência inteira não movia nada. O
	modelo de origem não anima Chronostasis, então não havia o que converter, e
	o conversor devolveu as bases. Isso não é pose autoral, é buraco. Agora tem
	coreografia escrita à mão.

	Cada pose é o C0 de um Weld que o animator cria:

		RightArm   Torso → Right Arm          base CFrame.new( 1.5,  0,   0)
		LeftArm    Torso → Left Arm           base CFrame.new(-1.5,  0,   0)
		Head       Torso → Head               base CFrame.new( 0,    1.5, 0)
		HRP        HumanoidRootPart → Torso   base CFrame.new()

	⚠️ NÃO escreva em Motor6D. O script `Animate` padrão do Roblox escreve nessas
	mesmas juntas todo frame — os dois brigam e a animação treme.

	Ver DIRETRIZES/REGRA_ANIMACAO_R6.md.

	DRAMATURGIA — Chronostasis marca um ponto no tempo e depois devolve você a
	ele. A leitura é de ANCORAGEM: o braço desce e "crava" a marca no chão do
	tempo, o tronco recua com o impacto da marca, e o corpo assenta.
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
-- POSES — C0 de Weld, no formato que o Animator canônico consome
--==============================================================================

Poses.POSES = {
	-- 1. Armar: o relógio sobe à altura do olho, o tronco gira para acompanhar
	PRIMARIA_1 = {
		RightArm = BASE_BRACO_D * graus(-105, 0, 18),
		LeftArm  = BASE_BRACO_E * graus(-18, 0, -14),
		Head     = BASE_CABECA * graus(-12, 22, 0),
		HRP      = BASE_TRONCO * graus(0, -20, 0),
	},

	-- 2. Cravar: o braço desce firme e a marca assenta. É o quadro de impacto —
	--    é aqui que o CFrame do jogador é guardado, não no fim da sequência.
	PRIMARIA_2 = {
		RightArm = BASE_BRACO_D * graus(-32, 0, -8),
		LeftArm  = BASE_BRACO_E * graus(-8, 0, -22),
		Head     = BASE_CABECA * graus(8, -6, 0),
		HRP      = BASE_TRONCO * graus(6, 14, 0),
	},

	-- 3. Assentar: volta ao repouso, sem voltar à base exata — sobra um resíduo
	--    de peso no tronco, que lê como "alguma coisa ficou marcada ali"
	PRIMARIA_3 = {
		RightArm = BASE_BRACO_D * graus(-6, 0, 3),
		LeftArm  = BASE_BRACO_E * graus(-4, 0, -5),
		Head     = BASE_CABECA,
		HRP      = BASE_TRONCO * graus(0, 4, 0),
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
	PRIMARIA = {
		{ pose = "PRIMARIA_1", time = 0.16, style = "Back",  dir = "Out" },
		{ pose = "PRIMARIA_2", time = 0.22, style = "Quint", dir = "Out", tremor = 0.02 },
		{ pose = "PRIMARIA_3", time = 0.2,  style = "Quad",  dir = "InOut" },
	},
}

-- Os acessores devolvem o NOME da sequência — é o que PlaySequence recebe.
function Poses.primaria()
	return "PRIMARIA"
end

return Poses
