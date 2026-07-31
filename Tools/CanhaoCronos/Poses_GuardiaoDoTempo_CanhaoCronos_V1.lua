--[[
	Poses_GuardiaoDoTempo_CanhaoCronos_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1

	V2 — REESCRITO PARA O R6CFrameAnimator V1 CANÔNICO DO PROJETO.

	A versão anterior guardava C0 ABSOLUTA de Motor6D ("Right Shoulder", "Neck"…),
	porque o animator que eu havia escrito mexia nos Motor6D direto. Isso BUGAVA:
	o script `Animate` padrão do Roblox escreve nesses mesmos Motor6D todo frame,
	e os dois brigavam pela mesma junta.

	O animator canônico cria Welds PRÓPRIOS (Torso→Right Arm, Torso→Head,
	HumanoidRootPart→Torso). Ninguém mais toca neles. As poses abaixo são o C0
	desses Welds, convertidas por:

		WeldC0 = MotorC0 * MotorC1⁻¹

	Conferido contra as bases do animator: a pose neutra devolve exatamente
	CFrame.new(1.5, 0, 0), CFrame.new(-1.5, 0, 0), CFrame.new(0, 1.5, 0) e CFrame.new().

	Juntas: RightArm · LeftArm · Head · HRP.
	⚠️ Right Hip e Left Hip do modelo NÃO têm equivalente — o animator canônico
	não solda pernas. 2 canal(is) de perna descartado(s) nesta Tool.
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
-- SEQUÊNCIAS — o Server toca uma pose por vez, com PlayPose(nome, duracao)
--==============================================================================

local PRIMARIA = {
	{ pose = "PRIMARIA_1", duracao = 0.5, easing = "quadOut" },
	{ pose = "PRIMARIA_2", duracao = 0.5, easing = "quadInOut" },
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
