--[[
	Poses_GuardiaoDoTempo_ArmadilhaTemporal_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 · §12.12.1 (pose R6 CFrame de terceiro, permitida)

	Armadilha temporal plantada no chão

	Origem da primária: `TemporalTrap` do Convert — 2 quadro(s) extraído(s)
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
			["RootJoint"] = CFrame.new(0, 0.05, 3.06162e-18, -0.906308, 0.422618, 0, -2.58779e-17, -5.54953e-17, 1, 0.422618, 0.906308, 6.12323e-17),
			["Neck"] = CFrame.new(0, 1, 0, -0.905445, -0.422216, 0.0436194, 0.0762158, -0.0606257, 0.995247, -0.417565, 0.904466, 0.0870728),
			["Right Shoulder"] = CFrame.new(1.00417, 0.965966, 0.289416, 0.707107, -0.147016, 0.691655, 0.241845, -0.868876, -0.431933, 0.664463, 0.472696, -0.578833),
			["Left Shoulder"] = CFrame.new(-0.750761, 0.384865, 0.101218, -0.0348663, -0.999391, 0.00152229, 0.996956, -0.0348875, -0.0697299, 0.0697405, -0.000913562, 0.997565),
			["Right Hip"] = CFrame.new(1, -1.05, 0, 0.422618, -0.0316297, 0.905756, 0, 0.999391, 0.0348995, -0.906308, -0.0147492, 0.422361),
			["Left Hip"] = CFrame.new(-1, -1.05, 0, -0.173648, 0.0858317, -0.98106, 0, 0.996195, 0.0871557, 0.984808, 0.0151344, -0.172987),
		},
	},
	{
		duracao = 0.5,
		easing = "quadInOut",
		absoluto = true,
		juntas = {
			["RootJoint"] = CFrame.new(0, 0.05, 3.06162e-18, -0.902859, 0.42101, -0.0871557, -0.0789899, 0.0368336, 0.996195, 0.422618, 0.906308, 5.03258e-17),
			["Neck"] = CFrame.new(0, 1, 0, -0.905445, -0.422216, 0.0436194, 0.112319, -0.139224, 0.98387, -0.409333, 0.89574, 0.173483),
			["Right Shoulder"] = CFrame.new(0.842668, 1.101, 0.271808, 0.573576, -0.0856247, 0.814665, 0.142244, -0.969002, -0.201995, 0.806707, 0.231741, -0.543617),
			["Left Shoulder"] = CFrame.new(-0.750761, 0.384865, 0.101218, -0.0348663, -0.999391, 0.00152229, 0.996956, -0.0348875, -0.0697299, 0.0697405, -0.000913562, 0.997565),
			["Right Hip"] = CFrame.new(1, -0.85, -0.4, 0.400032, 0.139934, 0.905756, -0.258661, 0.965337, -0.0348995, -0.879243, -0.220323, 0.422361),
			["Left Hip"] = CFrame.new(-1.03, -1.02, 0, -0.173648, 0.137059, -0.975224, 0, 0.990268, 0.139173, 0.984808, 0.0241672, -0.171958),
		},
	},
}

function Poses.primaria()
	return PRIMARIA
end

return Poses
