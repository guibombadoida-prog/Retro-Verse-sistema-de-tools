--[[
	Poses_GuardiaoDoTempo_Temporalise_V1  —  ModuleScript "Poses", filho direto da Tool
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
	não solda pernas. 1 canal(is) de perna descartado(s) nesta Tool.
--]]

local Poses = {}

--==============================================================================
-- POSES — C0 de Weld, no formato que o Animator canônico consome
--==============================================================================

Poses.POSES = {
	PRIMARIA_1 = {
		HRP      = CFrame.new(0, 0.1, 6.12323e-18, 1, 1.06735e-17, 4.6568e-19, -1.06735e-17, 0.996195, 0.0871557, 4.66298e-19, -0.0871557, 0.996195),
		Head     = CFrame.new(-2.58779e-17, 1.45315, 0.211309, 1, -5.17558e-17, 1.14737e-17, 5.17558e-17, 0.906308, -0.422618, 1.14743e-17, 0.422618, 0.906308),
		RightArm = CFrame.new(1.78678, 0.884875, -0.140083, 0.819152, -0.573576, -6.25924e-24, -0.538986, -0.769751, -0.34202, 0.196175, 0.280166, -0.939693),
		LeftArm  = CFrame.new(-1.78678, 0.884875, -0.140083, 0.819152, 0.573576, 6.25924e-24, 0.538986, -0.769751, -0.34202, -0.196175, 0.280166, -0.939693),
	},
}

--==============================================================================
-- SEQUÊNCIAS — o Server toca uma pose por vez, com PlayPose(nome, duracao)
--==============================================================================

local PRIMARIA = {
	{ pose = "PRIMARIA_1", duracao = 0.35, easing = "quadOut" },
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
