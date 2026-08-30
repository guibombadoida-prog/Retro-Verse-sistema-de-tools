-- Client.lua
-- Script com RunContext = Client — Taco de Baseball  (conjunto GUEST)
--
-- POR QUE NÃO É LocalScript, E POR QUE ISSO IMPORTA
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
--   mundo — mas o único ouvinte que existe é o de quem está segurando. Era
--   por isso que, dos Escudos até aqui, o efeito aparecia só para o portador.
--
--   `Script` com `RunContext = Client` roda em TODO cliente, onde quer que
--   esteja na árvore, inclusive dentro da Tool de outro jogador. Nada saiu de
--   dentro da Tool, então a Regra nº 1 continua de pé.
--
-- O QUE É DE TODO MUNDO, E O QUE É SÓ DO DONO
--
--   De todo mundo: desenhar o VFX. É o ponto.
--   Só do dono:    mandar a mira e apertar botão.
--
--   A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
--   cliente não replica e os outros jogadores viam o portador parado.
--
-- MOBILE
--
--   `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...teclas)`.
--   O terceiro argumento é o que resolve o celular: o Roblox desenha o botão
--   sozinho, no tamanho e na área de acerto que o jogador espera.
--
--   O `Diamond` original tentava resolver isso com uma GUI própria — e
--   esperava por ela com `tool:WaitForChild("AbilityActivateButton")`. Essa
--   GUI **não existe no modelo**: `WaitForChild` sem timeout trava para
--   sempre, e o script inteiro morria na linha 10. `ContextActionService` não
--   tem esse problema, e não põe `ScreenGui` dentro da Tool.
--
-- Gerado por FERRAMENTAS/gerar_servers_guest.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO = "Guest_GuestTaco_R"
local ALCANCE_MIRA = 40

local equipado = false
local rato = nil

--═══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--═══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "PARAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {})
end)

--═══════════════════════════════════════════════════════════════
-- MIRA E ENTRADA — só o dono
--═══════════════════════════════════════════════════════════════

local function souODono()
	local pai = Tool.Parent
	if not pai then return false end
	if not pai:FindFirstChildOfClass("Humanoid") then return false end
	return Players:GetPlayerFromCharacter(pai) == jogador
end

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

local function ligarEntrada()
	ContextActionService:BindAction(ACAO, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("R", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)

	ContextActionService:SetTitle(ACAO, "Rebater")
	-- Em escala, não em pixel: celular pequeno e tablet dividem a mesma conta.
	ContextActionService:SetPosition(ACAO, UDim2.new(1, -140, 1, -180))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO)
end

--═══════════════════════════════════════════════════════════════
-- CICLO
--═══════════════════════════════════════════════════════════════

Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira())
end)

Tool.Equipped:Connect(function()
	if not souODono() then return end
	equipado = true
	ligarEntrada()
end)

local function aoGuardar()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end

Tool.Unequipped:Connect(aoGuardar)
Tool.Destroying:Connect(aoGuardar)


