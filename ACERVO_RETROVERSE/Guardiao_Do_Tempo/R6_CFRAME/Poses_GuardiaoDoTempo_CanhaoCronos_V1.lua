--[[
	Poses_GuardiaoDoTempo_CanhaoCronos_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1 (pose R6 CFrame de terceiro, permitida)

	Carga e disparo concentrado

	Origem da primária: `ChronosCannon` do Convert — 2 quadro(s) extraído(s)
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
		duracao = 0.5,
		easing = "quadOut",
		absoluto = true,
		juntas = {
			["RootJoint"] = CFrame.new(0, 0.05, 3.06162e-18, -0.707107, 0.707107, 2.12658e-17, 0.122788, 0.122788, 0.984808, 0.696364, 0.696364, -0.173648),
			["Neck"] = CFrame.new(0, 1, 0, -0.707107, -0.707107, -1.06735e-17, 0.0616284, -0.0616284, 0.996195, -0.704416, 0.704416, 0.0871557),
			["Right Shoulder"] = CFrame.new(0.996447, 0.561394, -0.848182, 4.32978e-17, -0.707107, 0.707107, 0.984808, -0.122788, -0.122788, 0.173648, 0.696364, 0.696364),
			["Left Shoulder"] = CFrame.new(-0.750761, 0.384865, 0.101218, -0.0348663, -0.999391, 0.00152229, 0.996956, -0.0348875, -0.0697299, 0.0697405, -0.000913562, 0.997565),
			["Right Hip"] = CFrame.new(1, -1.05, -0.01, 6.12323e-17, 0, 1, 0, 1, 0, -1, 0, 6.12323e-17),
			["Left Hip"] = CFrame.new(-1, -1.05, -0.01, 6.12323e-17, 0, -1, 0, 1, 0, 1, 0, 6.12323e-17),
		},
	},
	{
		duracao = 0.5,
		easing = "quadInOut",
		absoluto = true,
		juntas = {
			["RootJoint"] = CFrame.new(0, 0.05, 3.06162e-18, -0.707107, -0.707107, 2.12658e-17, -0.122788, 0.122788, 0.984808, -0.696364, 0.696364, -0.173648),
			["Neck"] = CFrame.new(0, 1, 0, -0.707107, 0.707107, -1.06735e-17, -0.0616284, -0.0616284, 0.996195, 0.704416, 0.704416, 0.0871557),
			["Right Shoulder"] = CFrame.new(0.996447, 0.438606, -0.151818, 4.32978e-17, 0.707107, 0.707107, 0.984808, -0.122788, 0.122788, 0.173648, 0.696364, -0.696364),
			["Left Shoulder"] = CFrame.new(-0.750761, 0.384865, 0.101218, -0.0348663, -0.999391, 0.00152229, 0.996956, -0.0348875, -0.0697299, 0.0697405, -0.000913562, 0.997565),
			["Right Hip"] = CFrame.new(1, -1.05, -0.01, 6.12323e-17, 0, 1, 0, 1, 0, -1, 0, 6.12323e-17),
			["Left Hip"] = CFrame.new(-1, -1.05, -0.01, 6.12323e-17, 0, -1, 0, 1, 0, 1, 0, 6.12323e-17),
		},
	},
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
