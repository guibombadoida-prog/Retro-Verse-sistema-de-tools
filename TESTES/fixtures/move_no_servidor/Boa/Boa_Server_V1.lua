-- FIXTURE — este arquivo NÃO tem o defeito.
-- A escrita de CFrame é única e está FORA do laço.
-- `verificar_autocontencao.sh --autoteste` falha se ele FOR acusado.
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(dt)
	passado = passado + dt
	contar(dt)
end)

local function saltar(peca, caminho)
	peca.CFrame = caminho[1]
end
