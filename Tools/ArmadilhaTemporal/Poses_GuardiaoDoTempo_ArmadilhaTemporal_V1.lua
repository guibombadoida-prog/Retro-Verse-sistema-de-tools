--[[
	Poses_GuardiaoDoTempo_ArmadilhaTemporal_V1  —  ModuleScript "Poses", filho direto da Tool
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

	⚠️ 2 canal(is) de perna (Right Hip / Left Hip) do modelo foram DESCARTADOS
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
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.906308, -2.58779e-17, 0.422618, 2.58779e-17, 1, 5.73704e-18, -0.422618, 5.73694e-18, 0.906308),
		Head     = CFrame.new(0.0218097, 1.49762, 0.0435364, 0.905445, 0.0436194, -0.422216, -0.0762158, 0.995247, -0.0606257, 0.417565, 0.0870728, 0.904466),
		RightArm = CFrame.new(1.42351, 1.18444, -0.236348, 0.691655, -0.147016, -0.707107, -0.431933, -0.868876, -0.241845, -0.578833, 0.472696, -0.664463),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_2 = {
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.902859, -0.0871557, 0.42101, 0.0789899, 0.996195, 0.0368336, -0.422618, -5.16956e-18, 0.906308),
		Head     = CFrame.new(0.0218097, 1.49194, 0.0867415, 0.905445, 0.0436194, -0.422216, -0.112319, 0.98387, -0.139224, 0.409333, 0.173483, 0.89574),
		RightArm = CFrame.new(1.29281, 1.4845, -0.115871, 0.814665, -0.0856247, -0.573576, -0.201995, -0.969002, -0.142244, -0.543617, 0.231741, -0.806707),
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
		{ pose = "PRIMARIA_1", time = 0.5, style = "Quad", dir = "Out" },
		{ pose = "PRIMARIA_2", time = 0.5, style = "Quad", dir = "InOut" },
	},
}

-- Os acessores devolvem o NOME da sequência — é o que PlaySequence recebe.
function Poses.primaria()
	return "PRIMARIA"
end

return Poses
