-- Client.lua
-- Script com RunContext = Client — Arma de Fisica  (conjunto REALITY)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. `RunContext = Client` roda em TODO cliente, e nada saiu de dentro
-- da Tool. É por isso que o efeito aparece para o servidor inteiro.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica.
--
-- SEM BOTÃO DE CELULAR, E SEM TECLA
--
--   Este conjunto tem UMA habilidade por Tool, e ela é no clique. O toque na
--   tela já dispara `Tool.Activated` sozinho — botão extra para a mesma ação
--   seria um segundo jeito de fazer a mesma coisa, que foi exatamente a
--   reclamação levantada nas Tools de escudo.
--
-- Gerado por FERRAMENTAS/gerar_servers_reality_v2.py.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local VFX       = require(Tool:WaitForChild("VFXModule"))

local ALCANCE_MIRA = 90

local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" or tipo == "PARAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {})
end)

--══════════════════════════════════════════════════════════════
-- MIRA E ENTRADA — só o dono
--══════════════════════════════════════════════════════════════

local function souODono()
	local pai = Tool.Parent
	if not pai then return false end
	if not pai:FindFirstChildOfClass("Humanoid") then return false end
	return Players:GetPlayerFromCharacter(pai) == jogador
end

--- Onde o jogador aponta, limitado ao alcance.
---
--- A ORIGEM PERGUNTAVA POR `RemoteFunction` (`MouseLoc:InvokeClient`), de
--- dentro do `Tool.Activated` do servidor. O servidor ficava PARADO esperando
--- a resposta do cliente — e cliente que não responde trava aquela thread até
--- o timeout. Aqui a mira viaja junto do pedido, num sentido só.
local function mira()
	local personagem = jogador.Character
	local origem = personagem and personagem:FindFirstChild("HumanoidRootPart")
	rato = rato or jogador:GetMouse()
	local alvo = rato and rato.Hit and rato.Hit.Position
	if not origem then return alvo or Vector3.new() end
	if not alvo then return origem.Position + origem.CFrame.LookVector * 20 end
	local delta = alvo - origem.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return origem.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end

--══════════════════════════════════════════════════════════════
-- A GARRA — o botão DESCENDO, o botão SEGURADO, e o botão SUBINDO
--
-- Continua sendo só o clique: `Activated` é o botão descendo e `Deactivated`
-- é o MESMO botão subindo. Nenhuma tecla, nenhum botão de tela.
--
-- Enquanto segura, a mira precisa CHEGAR ao servidor — é ela que diz onde a
-- peça deve flutuar. Isso é o único tráfego contínuo do conjunto inteiro, e
-- por isso é limitado a 20 Hz: por quadro seriam 60 pacotes por segundo por
-- jogador, e a garra não fica mais precisa por isso.
--══════════════════════════════════════════════════════════════

local segurando = false
local desdeUltimo = 0
local INTERVALO = 1 / 20

local function soltar()
	if not segurando then return end
	segurando = false
	VFXRemote:FireServer(mira(), "SOLTA")
end

Tool.Activated:Connect(function()
	if not souODono() then return end
	segurando = true
	desdeUltimo = 0
	VFXRemote:FireServer(mira(), "PEGA")
end)

Tool.Deactivated:Connect(soltar)
Tool.Unequipped:Connect(soltar)

RunService.Heartbeat:Connect(function(dt)
	if not segurando then return end
	if not souODono() then
		segurando = false
		return
	end
	desdeUltimo = desdeUltimo + dt
	if desdeUltimo < INTERVALO then return end
	desdeUltimo = 0
	VFXRemote:FireServer(mira(), "MIRA")
end)

