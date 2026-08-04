--[[
	Poses_GuardiaoDoTempo_CanhaoCronos_V1  —  ModuleScript "Poses", filho direto da Tool
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
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.707107, -2.2032e-17, 0.707107, -0.122788, 0.984808, 0.122788, -0.696364, -0.173648, 0.696364),
		Head     = CFrame.new(1.63122e-17, 1.4981, 0.0435778, 0.707107, 3.26243e-17, -0.707107, -0.0616284, 0.996195, -0.0616284, 0.704416, 0.0871557, 0.704416),
		RightArm = CFrame.new(1.70355, 0.561394, -0.848182, 0.707107, -0.707107, 1.62102e-23, -0.122788, -0.122788, -0.984808, 0.696364, 0.696364, -0.173648),
		LeftArm  = CFrame.new(-0.250304, 0.367444, 0.600457, -0.00152229, -0.999391, -0.0348663, 0.0697299, -0.0348875, 0.996956, -0.997565, -0.000913562, 0.0697405),
	},
	PRIMARIA_2 = {
		HRP      = CFrame.new(0, 0.05, 3.06162e-18, 0.707107, 6.45636e-17, -0.707107, 0.122788, 0.984808, 0.122788, 0.696364, -0.173648, 0.696364),
		Head     = CFrame.new(-2.69857e-17, 1.4981, 0.0435778, 0.707107, -5.39713e-17, 0.707107, 0.0616284, 0.996195, -0.0616284, -0.704416, 0.0871557, 0.704416),
		RightArm = CFrame.new(0.996447, 0.561394, -0.848182, 0.707107, 0.707107, 1.62102e-23, 0.122788, -0.122788, -0.984808, -0.696364, 0.696364, -0.173648),
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
