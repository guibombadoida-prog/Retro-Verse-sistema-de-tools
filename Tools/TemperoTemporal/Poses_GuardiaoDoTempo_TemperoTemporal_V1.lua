--[[
	Poses_GuardiaoDoTempo_TemperoTemporal_V1  —  ModuleScript "Poses", filho direto da Tool
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
		HRP      = CFrame.new(-2.44929e-17, -0.05, 0.2, 0.819152, 3.4252e-18, -0.573576, -0.148453, 0.965926, -0.212012, 0.554032, 0.258819, 0.79124),
		Head     = CFrame.new(-1.7126e-18, 1.48296, -0.12941, 0.819152, -3.4252e-18, 0.573576, -0.148453, 0.965926, 0.212012, -0.554032, -0.258819, 0.79124),
		RightArm = CFrame.new(1.2887, 0.5, -0.453154, 0.906308, 0.422618, 5.95621e-23, -2.58779e-17, 5.54953e-17, -1, -0.422618, 0.906308, 6.12323e-17),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_2 = {
		HRP      = CFrame.new(-2.44929e-17, -0.05, 0.2, 0.819152, 3.4252e-18, -0.573576, -0.148453, 0.965926, -0.212012, 0.554032, 0.258819, 0.79124),
		Head     = CFrame.new(-1.7126e-18, 1.48296, -0.12941, 0.819152, -3.4252e-18, 0.573576, -0.148453, 0.965926, 0.212012, -0.554032, -0.258819, 0.79124),
		RightArm = CFrame.new(1.2887, 0.5, -0.053154, 0.906308, 0.422618, 5.95621e-23, -2.58779e-17, 5.54953e-17, -1, -0.422618, 0.906308, 6.12323e-17),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_3 = {
		HRP      = CFrame.new(7.9602e-17, -0.3, -0.65, 1, 1.06058e-16, 6.12324e-17, -1.06057e-16, 0.5, 0.866025, 6.12327e-17, -0.866025, 0.5),
		Head     = CFrame.new(9.79978e-39, 1.5, -1.99787e-23, 1, 1.95996e-38, -3.20085e-22, -5.98006e-39, 1, 3.99574e-23, 3.20085e-22, -3.99574e-23, 1),
		RightArm = CFrame.new(1.5, 0.288691, -0.053154, 1, 0, 3.99574e-23, 5.95621e-23, 0.422618, -0.906308, 1.09519e-23, 0.906308, 0.422618),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_4 = {
		HRP      = CFrame.new(3.79641e-17, -0.45, -0.31, 1, 1.06058e-16, 6.12324e-17, -1.06057e-16, 0.5, 0.866025, 6.12327e-17, -0.866025, 0.5),
		Head     = CFrame.new(9.79978e-39, 1.5, -1.99787e-23, 1, 1.95996e-38, -3.20085e-22, -5.98006e-39, 1, 3.99574e-23, 3.20085e-22, -3.99574e-23, 1),
		RightArm = CFrame.new(1.22059, 0.295891, -1.43771, 0.965926, 0.258819, 9.20566e-24, -0.109382, 0.408218, -0.906308, -0.23457, 0.875426, 0.422618),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_5 = {
		HRP      = CFrame.new(3.79641e-17, -0.45, -0.31, 1, 1.06058e-16, 6.12324e-17, -1.06057e-16, 0.5, 0.866025, 6.12327e-17, -0.866025, 0.5),
		Head     = CFrame.new(9.79978e-39, 1.5, -1.99787e-23, 1, 1.95996e-38, -3.20085e-22, -5.98006e-39, 1, 3.99574e-23, 3.20085e-22, -3.99574e-23, 1),
		RightArm = CFrame.new(1.06321, 0.326906, -1.3712, 0.819152, 0.573576, -6.25924e-24, -0.242404, 0.346189, -0.906308, -0.519837, 0.742404, 0.422618),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
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
		{ pose = "PRIMARIA_1", time = 0.08, style = "Quad", dir = "Out" },
		{ pose = "PRIMARIA_2", time = 0.15, style = "Quad", dir = "InOut" },
		{ pose = "PRIMARIA_3", time = 0.08, style = "Back", dir = "Out" },
		{ pose = "PRIMARIA_4", time = 0.08, style = "Cubic", dir = "Out" },
		{ pose = "PRIMARIA_5", time = 0.25, style = "Quad", dir = "Out" },
	},
}

-- Os acessores devolvem o NOME da sequência — é o que PlaySequence recebe.
function Poses.primaria()
	return "PRIMARIA"
end

return Poses
