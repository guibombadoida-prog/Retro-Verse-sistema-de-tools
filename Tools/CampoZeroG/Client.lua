--[[
	Client  —  LocalScript, filho direto da Tool
	Retro-Verse / Studios  ·  §9 (botão só para Extra) + §12.10 + §12.11

	Duas responsabilidades, nenhuma a mais:
		1. INPUT da habilidade Extra  → avisa o servidor por AcaoRemote
		2. RECEPÇÃO de VFX            → VFXRemote.OnClientEvent → VFXModule.executar

	A habilidade PRIMÁRIA é Tool.Activated no servidor. Nunca botão, nunca aqui (§9).
	Proibido ScreenGui: o efeito vive só no mundo 3D (§12.12.4).
--]]

local ContextActionService = game:GetService("ContextActionService")

local tool = script.Parent
local VFXModule = require(tool:WaitForChild("VFXModule"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:FindFirstChild("AcaoRemote")

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	ACAO_EXTRA   = "CampoZeroG_Extra",
	TECLA_EXTRA  = Enum.KeyCode.X,
	BOTAO_MOVEL  = true,      -- botão na tela do celular: permitido SÓ para habilidade Extra
}

--==============================================================================
-- RECEPÇÃO DE VFX — unidirecional: o cliente só escuta (§12.14)
--==============================================================================

VFXRemote.OnClientEvent:Connect(function(tipo, payload)
	VFXModule.executar(tipo, payload)
end)

--==============================================================================
-- INPUT DA HABILIDADE EXTRA
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
