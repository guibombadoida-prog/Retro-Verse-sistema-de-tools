-- Client.lua
-- Script com RunContext = Client — Xester Portal do Cajado
--
-- POR QUE NÃO É LocalScript
--   LocalScript dentro de Tool só roda para o jogador cujo Character a contém.
--   O servidor manda o beat com `FireAllClients` e ele CHEGA em todo mundo, mas
--   o único ouvinte era o de quem segurava. Era por isso que o VFX das 14
--   aparecia só para o portador.
--
--   `Script` com `RunContext = Client` roda em TODO cliente, inclusive dentro
--   da Tool de outro jogador. Nada saiu de dentro da Tool: Regra nº 1 de pé.
--
-- O QUE É DE TODOS, E O QUE É SÓ DO DONO
--   De todos: desenhar o VFX e tocar o SFX. É o ponto.
--   Só do dono: mandar a mira e disparar a habilidade Extra.
--
--   A animação NÃO está aqui: o rig é do servidor, porque Weld criado no
--   cliente não replica e os outros viam o portador parado.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local VFX       = require(Tool:WaitForChild("VFXModule"))
local MiraRemote = nil

local ALCANCE_MIRA = 60
local RITMO_MIRA = 0.1

local portador = nil
local mandandoMira = false
local rato = nil

local function donoDaTool()
	local pai = Tool.Parent
	if not pai then return nil end
	if not pai:FindFirstChildOfClass("Humanoid") then return nil end
	return pai
end

local function souODono()
	local corpo = donoDaTool()
	if not corpo then return false end
	return Players:GetPlayerFromCharacter(corpo) == jogador
end

--══════════════════════════════════════════════════════════════
-- DESENHO — roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	local corpo = portador or donoDaTool()
	if tipo == "BEAT" then
		VFX.beat(dados and dados.marca, corpo)
		return
	end
	VFX.desenhar(tipo, dados or {}, Moldes, corpo)
end)

--══════════════════════════════════════════════════════════════
-- MIRA E EXTRA — só o dono
--══════════════════════════════════════════════════════════════

local function pontoMirado()
	local corpo = portador
	local raiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not raiz then return nil end
	if not rato then return raiz.Position + raiz.CFrame.LookVector * 20 end
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

local function aoEquipar()
	portador = donoDaTool()
	if not souODono() then return end
	rato = rato or (jogador and jogador:GetMouse())
	comecarMira()
end

local function aoGuardar()
	mandandoMira = false
	portador = nil
	VFX.limpar()
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)

-- `Tool.Equipped` não dispara nos clientes que NÃO são o dono: para eles a
-- Tool só aparece dentro de um Character já montado. Por isso o portador é
-- resolvido na entrada e a cada troca de Parent.
portador = donoDaTool()
Tool:GetPropertyChangedSignal("Parent"):Connect(function()
	portador = donoDaTool()
	if portador and souODono() then
		rato = rato or (jogador and jogador:GetMouse())
		comecarMira()
	end
end)

Tool.Destroying:Connect(aoGuardar)
