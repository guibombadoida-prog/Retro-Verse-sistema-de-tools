--[[
	Poses_GuardiaoDoTempo_Cronostase_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1 (pose R6 CFrame de terceiro, permitida)

	Marca um ponto no tempo e retorna a ele

	Origem da primária: autoral: o modelo não anima `Chronostasis`
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
		duracao = 0.16,
		easing = "quadOut",
		juntas = {
			["RootJoint"] = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(180)) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-12)),
			["Right Shoulder"] = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)) * CFrame.Angles(math.rad(-115), math.rad(0), math.rad(0)),
			["Left Shoulder"] = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)) * CFrame.Angles(math.rad(-25), math.rad(0), math.rad(0)),
		},
	},
	{
		duracao = 0.22,
		easing = "backOut",
		juntas = {
			["RootJoint"] = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(180)) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(18)),
			["Right Shoulder"] = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)) * CFrame.Angles(math.rad(-25), math.rad(0), math.rad(0)),
			["Left Shoulder"] = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
		},
	},
	{
		duracao = 0.2,
		easing = "quadInOut",
		juntas = {
			["RootJoint"] = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(180)),
			["Right Shoulder"] = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
			["Left Shoulder"] = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
		},
	},
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
