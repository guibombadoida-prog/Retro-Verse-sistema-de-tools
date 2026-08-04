--[[
	Poses_GuardiaoDoTempo_Temporalise_V1  —  ModuleScript "Poses", filho direto da Tool
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

	⚠️ 1 canal(is) de perna (Right Hip / Left Hip) do modelo foram DESCARTADOS
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
		HRP      = CFrame.new(0, 0.1, 6.12323e-18, 1, 1.06735e-17, 4.6568e-19, -1.06735e-17, 0.996195, 0.0871557, 4.66298e-19, -0.0871557, 0.996195),
		Head     = CFrame.new(-2.58779e-17, 1.45315, 0.211309, 1, -5.17558e-17, 1.14737e-17, 5.17558e-17, 0.906308, -0.422618, 1.14743e-17, 0.422618, 0.906308),
		RightArm = CFrame.new(1.78678, 0.884875, -0.140083, 0.819152, -0.573576, -6.25924e-24, -0.538986, -0.769751, -0.34202, 0.196175, 0.280166, -0.939693),
		LeftArm  = CFrame.new(-1.78678, 0.884875, -0.140083, 0.819152, 0.573576, 6.25924e-24, 0.538986, -0.769751, -0.34202, -0.196175, 0.280166, -0.939693),
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
		{ pose = "PRIMARIA_1", time = 0.35, style = "Quad", dir = "Out" },
	},
}

-- Os acessores devolvem o NOME da sequência — é o que PlaySequence recebe.
function Poses.primaria()
	return "PRIMARIA"
end

return Poses
