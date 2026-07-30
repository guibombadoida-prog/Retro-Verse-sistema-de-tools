--[[
	Poses_GuardiaoDoTempo_Temporalise_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1 (pose R6 CFrame de terceiro, permitida)

	Parada do tempo em área

	Origem da primária: `Temporalysis` do Convert — 1 quadro(s) extraído(s)
	Extração: as chamadas `Clerp(<junta>.C0, <alvo>, ...)` foram avaliadas numericamente com
	SINE = 0, o que CONGELA a oscilação do Idle numa fase fixa (COS(0) = 1, SIN(0) = 0) e
	transforma cada laço de animação num quadro estático. O resultado é a C0 ABSOLUTA, emitida
	como matriz completa — por isso todo quadro extraído traz `absoluto = true` (Animator V2).

	Depositado em ACERVO_RETROVERSE/Guardiao_Do_Tempo/R6_CFRAME/
--]]

local Poses = {}

--==============================================================================
-- PRIMÁRIA
--==============================================================================

local PRIMARIA = {
	{
		duracao = 0.35,
		easing = "quadOut",
		absoluto = true,
		juntas = {
			["RootJoint"] = CFrame.new(0, 0.1, 6.12323e-18, -1, -1.21999e-16, 1.06735e-17, 7.4988e-33, 0.0871557, 0.996195, -1.22465e-16, 0.996195, -0.0871557),
			["Neck"] = CFrame.new(0, 1, 0, -1, -1.10991e-16, -5.17558e-17, 7.4988e-33, -0.422618, 0.906308, -1.22465e-16, 0.906308, 0.422618),
			["Right Shoulder"] = CFrame.new(1.09042, 0.769493, -0.0980873, 5.01586e-17, -0.573576, 0.819152, 0.34202, -0.769751, -0.538986, 0.939693, 0.280166, 0.196175),
			["Left Shoulder"] = CFrame.new(-1.09042, 0.769493, -0.0980873, 5.01586e-17, 0.573576, -0.819152, -0.34202, -0.769751, -0.538986, -0.939693, 0.280166, 0.196175),
			["Right Hip"] = CFrame.new(1, -1, 0, 0.364214, -0.0378024, 0.930548, -0.2563, 0.956526, 0.139173, -0.895354, -0.289188, 0.338692),
			["Left Hip"] = CFrame.new(-1, -1, 0, 0.364214, 0.0378024, -0.930548, 0.2563, 0.956526, 0.139173, 0.895354, -0.289188, 0.338692),
		},
	},
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
