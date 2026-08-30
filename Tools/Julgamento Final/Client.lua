-- Client.lua
-- Script com RunContext = Client — Julgamento Final (conjunto COLLECTOR)
--
-- POR QUE NÃO É LocalScript, E POR QUE ISSO IMPORTA
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
--   mundo — mas o único ouvinte que existe é o de quem está segurando. Foi por
--   isso que, dos Escudos até aqui, o efeito aparecia só para o portador.
--
--   `Script` com `RunContext = Client` roda em TODO cliente, onde quer que
--   esteja na árvore, inclusive dentro da Tool de outro jogador. Cada cliente
--   desenha o mesmo efeito, a 60 Hz, com custo de rede zero — e nada saiu de
--   dentro da Tool, então a Regra nº 1 continua de pé.
--
-- O QUE É DE TODO MUNDO, E O QUE É SÓ DO DONO
--
--   De todo mundo: desenhar o VFX. É o ponto.
--   Só do dono:    mandar a mira. Sem esta trava, os cinco clientes da sala
--                  mandariam a mira DELES para a Tool alheia.
--
--   A animação NÃO está aqui: o rig é do servidor, porque Weld criado no
--   cliente não replica e os outros jogadores viam o portador parado.
--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py.

local Players = game:GetService("Players")

local jogador = Players.LocalPlayer

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local VFX       = require(Tool:WaitForChild("VFXModule"))
local MiraRemote = Tool:WaitForChild("MiraRemote")

local ALCANCE_MIRA = 90
local RITMO_MIRA = 0.1

local portador = nil
local mandandoMira = false

--- Quem está com a Tool na mão. É `Tool.Parent` quando equipada, e nil quando
--- ela está na mochila.
local function donoDaTool()
	local pai = Tool.Parent
	if not pai then return nil end
	local humano = pai:FindFirstChildOfClass("Humanoid")
	if not humano then return nil end
	return pai
end

local function souODono()
	local corpo = donoDaTool()
	if not corpo then return false end
	return Players:GetPlayerFromCharacter(corpo) == jogador
end

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "BEAT" then
		VFX.beat(dados and dados.marca, portador or donoDaTool())
		return
	end
	VFX.desenhar(tipo, dados or {}, Moldes, portador or donoDaTool())
end)

--══════════════════════════════════════════════════════════════
-- MIRA — só o dono manda
--══════════════════════════════════════════════════════════════

local rato = nil

local function pontoMirado()
	local corpo = portador
	local raiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not (raiz and rato) then return nil end
	local alvo = rato.Hit and rato.Hit.Position
	if not alvo then return raiz.Position + raiz.CFrame.LookVector * 20 end
	local delta = alvo - raiz.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return raiz.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end

local function comecarMira()
	if mandandoMira or not MiraRemote then return end
	mandandoMira = true
	rato = rato or (jogador and jogador:GetMouse())
	task.spawn(function()
		while mandandoMira do
			local ponto = pontoMirado()
			if ponto then MiraRemote:FireServer(ponto) end
			task.wait(RITMO_MIRA)
		end
	end)
end

--══════════════════════════════════════════════════════════════
-- CICLO
--══════════════════════════════════════════════════════════════

local function aoEquipar()
	portador = donoDaTool()
	if souODono() then comecarMira() end
end

local function aoGuardar()
	mandandoMira = false
	portador = nil
	VFX.limpar()
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)

-- `Tool.Equipped` não dispara nos clientes que NÃO são o dono: para eles a
-- Tool simplesmente aparece dentro de um Character já montado. Por isso o
-- portador também é resolvido na entrada, e a cada troca de pai.
portador = donoDaTool()
Tool.AncestryChanged:Connect(function()
	portador = donoDaTool()
	if portador and souODono() then comecarMira() end
end)

Tool.Destroying:Connect(aoGuardar)

