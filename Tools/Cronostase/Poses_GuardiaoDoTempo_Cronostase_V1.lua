--[[
	Poses_GuardiaoDoTempo_Cronostase_V1  —  ModuleScript "Poses", filho direto da Tool
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
	não solda pernas. 0 canal(is) de perna descartado(s) nesta Tool.
--]]

local Poses = {}

--==============================================================================
-- POSES — C0 de Weld, no formato que o Animator canônico consome
--==============================================================================

Poses.POSES = {
	PRIMARIA_1 = {
		HRP      = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		RightArm = CFrame.new(1.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
	PRIMARIA_2 = {
		HRP      = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		RightArm = CFrame.new(1.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
	PRIMARIA_3 = {
		HRP      = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		RightArm = CFrame.new(1.5, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
}

--==============================================================================
-- SEQUÊNCIAS — o Server toca uma pose por vez, com PlayPose(nome, duracao)
--==============================================================================

local PRIMARIA = {
	{ pose = "PRIMARIA_1", duracao = 0.16, easing = "quadOut" },
	{ pose = "PRIMARIA_2", duracao = 0.22, easing = "backOut" },
	{ pose = "PRIMARIA_3", duracao = 0.2, easing = "quadInOut" },
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
