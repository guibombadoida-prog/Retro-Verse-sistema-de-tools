-- FIXTURE — este arquivo TEM o defeito, de propósito.
-- `verificar_autocontencao.sh --autoteste` falha se ele NÃO for acusado.
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(dt)
	passado = passado + dt
	peca.CFrame = caminho[i]
end)
