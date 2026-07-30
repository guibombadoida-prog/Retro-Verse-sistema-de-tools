--[[
	Client — AvancoRapido
	LocalScript, filho direto da Tool
	Retro-Verse / Studios  ·  §9 · §12.10 · §12.11 · Regra nº 1

	Responsabilidade:
		1. INPUT da habilidade Extra (Aceleracao, tecla M) → AcaoRemote
		2. RECEPÇÃO de VFX → VFXRemote.OnClientEvent → VFXModule.executar

	Proibido ScreenGui: o efeito vive só no mundo 3D (§12.12.4).
	Regra nº 1: todo require aponta para ModuleScript da própria Tool.
--]]

local ContextActionService = game:GetService("ContextActionService")

local tool = script.Parent
local VFXModule = require(tool:WaitForChild("VFXModule"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:FindFirstChild("AcaoRemote")

local CFG = {
	ACAO_EXTRA  = "AvancoRapido_Aceleracao",
	TECLA_EXTRA = Enum.KeyCode.M,
	BOTAO_MOVEL = true,      -- botão na tela é permitido SÓ para Extra (§9)
}

--==============================================================================
-- RECEPÇÃO DE VFX — unidirecional: o cliente só escuta (§12.14)
--==============================================================================

VFXRemote.OnClientEvent:Connect(function(tipo, payload)
	VFXModule.executar(tipo, payload)
end)

--==============================================================================
-- INPUT DA HABILIDADE EXTRA — Aceleracao
--==============================================================================

local function aoAgir(_, estado)
	if estado ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if acaoRemote then
		acaoRemote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

tool.Equipped:Connect(function()
	ContextActionService:BindAction(CFG.ACAO_EXTRA, aoAgir, CFG.BOTAO_MOVEL, CFG.TECLA_EXTRA)
end)

tool.Unequipped:Connect(function()
	ContextActionService:UnbindAction(CFG.ACAO_EXTRA)
end)

tool.Destroying:Connect(function()
	ContextActionService:UnbindAction(CFG.ACAO_EXTRA)
end)
