--[[
	Poses_Template_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 — pose, ritmo e dramaturgia são AUTORAIS

	Tabela de poses R6 em CFrame, consumida pelo R6CFrameAnimator.
	Cada `juntas` é um OFFSET aplicado sobre a base da junta — não a C0 absoluta.

	Variação entre golpes vem de ÍNDICE SEQUENCIAL, nunca de math.random (§10).

	Ao finalizar a Tool, este arquivo é depositado no Acervo:
		ACERVO_RETROVERSE/[Modelo_De_Origem]/R6_CFRAME/Poses_[Modelo]_V1.lua
--]]

local Poses = {}

local function graus(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

--==============================================================================
-- GOLPES — alternados por contador sequencial
--==============================================================================

local GOLPE_A = {
	{
		duracao = 0.10,
		easing = "quadOut",
		juntas = {
			["Right Shoulder"] = graus(-150, 0, 25),
			["Left Shoulder"] = graus(-25, 0, -20),
			["RootJoint"] = graus(0, -12, 0),
		},
	},
	{
		duracao = 0.16,
		easing = "backOut",
		juntas = {
			["Right Shoulder"] = graus(-35, 0, -10),
			["Left Shoulder"] = graus(-10, 0, -15),
			["RootJoint"] = graus(0, 18, 0),
		},
	},
	{
		duracao = 0.18,
		easing = "quadInOut",
		juntas = {
			["Right Shoulder"] = graus(0, 0, 0),
			["Left Shoulder"] = graus(0, 0, 0),
			["RootJoint"] = graus(0, 0, 0),
		},
	},
}

local GOLPE_B = {
	{
		duracao = 0.10,
		easing = "quadOut",
		juntas = {
			["Right Shoulder"] = graus(-40, 0, 80),
			["Left Shoulder"] = graus(-20, 0, -30),
			["RootJoint"] = graus(0, 15, 0),
		},
	},
	{
		duracao = 0.16,
		easing = "backOut",
		juntas = {
			["Right Shoulder"] = graus(-60, 0, -55),
			["Left Shoulder"] = graus(-15, 0, -10),
			["RootJoint"] = graus(0, -20, 0),
		},
	},
	{
		duracao = 0.18,
		easing = "quadInOut",
		juntas = {
			["Right Shoulder"] = graus(0, 0, 0),
			["Left Shoulder"] = graus(0, 0, 0),
			["RootJoint"] = graus(0, 0, 0),
		},
	},
}

local CICLO = { GOLPE_A, GOLPE_B }

-- `contador` é o índice sequencial do golpe, vindo do Server Script.
function Poses.golpe(contador)
	local indice = ((contador - 1) % #CICLO) + 1
	return CICLO[indice]
end

--==============================================================================
-- HABILIDADE EXTRA
--==============================================================================

local EXTRA = {
	{
		duracao = 0.22,
		easing = "quadOut",
		juntas = {
			["Right Shoulder"] = graus(-175, 0, 15),
			["Left Shoulder"] = graus(-175, 0, -15),
			["RootJoint"] = graus(-12, 0, 0),
			["Neck"] = graus(-15, 0, 0),
		},
	},
	{
		duracao = 0.14,
		easing = "backOut",
		juntas = {
			["Right Shoulder"] = graus(-20, 0, 45),
			["Left Shoulder"] = graus(-20, 0, -45),
			["RootJoint"] = graus(20, 0, 0),
			["Neck"] = graus(10, 0, 0),
		},
	},
	{
		duracao = 0.26,
		easing = "quadInOut",
		juntas = {
			["Right Shoulder"] = graus(0, 0, 0),
			["Left Shoulder"] = graus(0, 0, 0),
			["RootJoint"] = graus(0, 0, 0),
			["Neck"] = graus(0, 0, 0),
		},
	},
}

function Poses.extra()
	return EXTRA
end

return Poses
