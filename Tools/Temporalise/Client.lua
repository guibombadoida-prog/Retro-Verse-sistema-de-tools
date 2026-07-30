--[[
	Client — Temporalise
	LocalScript, filho direto da Tool
	Retro-Verse / Studios  ·  §9 · §12.10 · §12.11 · Regra nº 1

	Responsabilidade:
		RECEPÇÃO de VFX → VFXRemote.OnClientEvent → VFXModule.executar
		Esta Tool não tem Extra — a primária é Tool.Activated, no servidor (§9).

	Proibido ScreenGui: o efeito vive só no mundo 3D (§12.12.4).
	Regra nº 1: todo require aponta para ModuleScript da própria Tool.
--]]

local tool = script.Parent
local VFXModule = require(tool:WaitForChild("VFXModule"))
local VFXRemote = tool:WaitForChild("VFXRemote")

--==============================================================================
-- RECEPÇÃO DE VFX — unidirecional: o cliente só escuta (§12.14)
--==============================================================================

VFXRemote.OnClientEvent:Connect(function(tipo, payload)
	VFXModule.executar(tipo, payload)
end)

-- Esta Tool não tem habilidade Extra: o Client só recebe VFX.
