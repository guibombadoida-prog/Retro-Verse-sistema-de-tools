--[[
	Poses_GuardiaoDoTempo_AvoDoTempo_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1

	V3 — MIGRADO PARA O R6CFrameAnimator V2 CANÔNICO DO PROJETO.

	A versão anterior guardava C0 ABSOLUTA de Motor6D ("Right Shoulder", "Neck"…),
	porque o animator que eu havia escrito mexia nos Motor6D direto. Isso BUGAVA:
	o script `Animate` padrão do Roblox escreve nesses mesmos Motor6D todo frame,
	e os dois brigavam pela mesma junta.

	O animator canônico cria Welds PRÓPRIOS (Torso→Right Arm, Torso→Head,
	HumanoidRootPart→Torso, e Torso→pernas sob demanda). Ninguém mais toca
	neles. As poses abaixo são o C0 desses Welds, convertidas por:

		WeldC0 = MotorC0 * MotorC1⁻¹

	Conferido contra as bases do animator: a pose neutra devolve exatamente
	CFrame.new(1.5, 0, 0), CFrame.new(-1.5, 0, 0), CFrame.new(0, 1.5, 0) e CFrame.new().

	Juntas em uso: RightArm · LeftArm · Head · HRP.

	⚠️ 5 canal(is) de perna (Right Hip / Left Hip) do modelo foram DESCARTADOS
	na conversão original, quando o animator do projeto era o V1 e soldava só
	quatro juntas. O V2 solda RightLeg e LeftLeg sob demanda — ou seja, o limite
	que justificou o descarte NÃO EXISTE MAIS. Reautorar esses canais é trabalho
	disponível, e sai desta Tool como V2 do arquivo de poses.

	Se reautorar: perna é sob demanda e tem de ser SOLTA no fim (ReleaseLegs),
	senão a caminhada trava. PlaySequence solta sozinho; PlayPose avulso, não.
	Ver DIRETRIZES/REGRA_ANIMACAO_R6.md.
--]]

local Poses = {}

--==============================================================================
-- POSES — C0 de Weld, no formato que o Animator canônico consome
--==============================================================================

Poses.POSES = {
	PRIMARIA_1 = {
		HRP      = CFrame.new(0, 0, 0, 0.819152, 1.35438e-16, -0.573576, 0.469846, 0.573576, 0.67101, 0.32899, -0.819152, 0.469846),
		Head     = CFrame.new(-1.7126e-18, 1.48296, -0.12941, 0.819152, -3.4252e-18, 0.573576, -0.148453, 0.965926, 0.212012, -0.554032, -0.258819, 0.79124),
		RightArm = CFrame.new(1.40642, 0.51, 0.101903, 0.996195, 0.0871557, 5.09038e-23, -5.33676e-18, 6.09993e-17, -1, -0.0871557, 0.996195, 6.12324e-17),
		LeftArm  = CFrame.new(-1.90957, 0.254175, -0.147707, 0.573576, 0.819152, -6.23387e-25, -0.70215, 0.491651, -0.515038, -0.421894, 0.295414, 0.857167),
	},
	PRIMARIA_2 = {
		HRP      = CFrame.new(0, 0, 0, 0.422618, 5.54956e-17, 0.906308, -0.821394, 0.422618, 0.383022, -0.383022, -0.906308, 0.178606),
		Head     = CFrame.new(4.35958e-17, 1.48296, -0.12941, 0.422618, 8.71916e-17, -0.906308, 0.23457, 0.965926, 0.109382, 0.875426, -0.258819, 0.408218),
		RightArm = CFrame.new(1.90315, 0.51, -0.711309, 0.422618, -0.906308, -1.09519e-23, 5.54953e-17, 2.58779e-17, -1, 0.906308, 0.422618, 6.12323e-17),
		LeftArm  = CFrame.new(-1.90957, 0.254175, -0.147707, 0.573576, 0.819152, -6.23387e-25, -0.70215, 0.491651, -0.515038, -0.421894, 0.295414, 0.857167),
	},
	PRIMARIA_3 = {
		HRP      = CFrame.new(0, 0, 0, 0.422618, 5.54956e-17, 0.906308, -0.821394, 0.422618, 0.383022, -0.383022, -0.906308, 0.178606),
		Head     = CFrame.new(4.35958e-17, 1.48296, -0.12941, 0.422618, 8.71916e-17, -0.906308, 0.23457, 0.965926, 0.109382, 0.875426, -0.258819, 0.408218),
		RightArm = CFrame.new(1.90315, 0.51, -0.711309, 0.422618, -0.906308, -1.09519e-23, 5.54953e-17, 2.58779e-17, -1, 0.906308, 0.422618, 6.12323e-17),
		LeftArm  = CFrame.new(-1.90957, 0.254175, -0.147707, 0.573576, 0.819152, -6.23387e-25, -0.70215, 0.491651, -0.515038, -0.421894, 0.295414, 0.857167),
	},
	EXTRA_1 = {
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.906308, -2.58779e-17, 0.422618, 2.58779e-17, 1, 5.73704e-18, -0.422618, 5.73694e-18, 0.906308),
		Head     = CFrame.new(0.0218097, 1.4825, -0.129287, 0.905445, 0.0436194, -0.422216, 0.0711961, 0.965006, 0.252376, 0.41845, -0.258573, 0.870655),
		RightArm = CFrame.new(1.77139, 0.730924, 0.0900367, -0.766044, -0.642788, 3.33697e-23, 0.639266, -0.761848, -0.104528, 0.0671896, -0.0800734, 0.994522),
		LeftArm  = CFrame.new(-1.77139, 0.730924, 0.0900367, -0.766044, 0.642788, -3.33697e-23, -0.639266, -0.761848, -0.104528, -0.0671896, -0.0800734, 0.994522),
	},
	EXTRA_2 = {
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.906308, -2.58779e-17, 0.422618, 2.58779e-17, 1, 5.73704e-18, -0.422618, 5.73694e-18, 0.906308),
		Head     = CFrame.new(-0.0435778, 1.38112, -0.128917, 0.936117, -0.0871557, -0.340719, 0.16763, 0.96225, 0.214417, 0.309169, -0.257834, 0.915389),
		RightArm = CFrame.new(1.77139, 0.830924, 0.0900367, -0.766044, -0.642788, 3.33697e-23, 0.639266, -0.761848, -0.104528, 0.0671896, -0.0800734, 0.994522),
		LeftArm  = CFrame.new(-1.77139, 0.830924, 0.0900367, -0.766044, 0.642788, -3.33697e-23, -0.639266, -0.761848, -0.104528, -0.0671896, -0.0800734, 0.994522),
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
		{ pose = "PRIMARIA_1", time = 0.5, style = "Quad", dir = "Out" },
		{ pose = "PRIMARIA_2", time = 0.1, style = "Quad", dir = "InOut" },
		{ pose = "PRIMARIA_3", time = 0.15, style = "Back", dir = "Out" },
	},
	EXTRA = {
		{ pose = "EXTRA_1", time = 0.08, style = "Quad", dir = "Out" },
		{ pose = "EXTRA_2", time = 0.5, style = "Quad", dir = "InOut" },
	},
}

-- Os acessores devolvem o NOME da sequência — é o que PlaySequence recebe.
function Poses.primaria()
	return "PRIMARIA"
end

function Poses.extra()
	return "EXTRA"
end

return Poses
