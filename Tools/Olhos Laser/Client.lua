-- Client.lua
-- Script com RunContext = Client — Olhos Laser  (conjunto DRAMA)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
-- mundo — mas o único ouvinte seria o de quem está segurando. `RunContext =
-- Client` roda em TODO cliente, e nada saiu de dentro da Tool.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica e os outros jogadores viam o portador parado.
--
-- MOBILE: `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...)`.
-- O terceiro argumento faz o Roblox desenhar o botão de toque sozinho. O modelo
-- de origem tinha duas `ScreenGui` (`fistgui` com as barras de combo e
-- `FlashScreen`), e as duas saíram: `ScreenGui` dentro de Tool é proibida.
--
-- Gerado por FERRAMENTAS/gerar_servers_drama.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO = "Drama_DramaOlhos_R"
local ALCANCE_MIRA = 220

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "PARAR" then
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

	ContextActionService:SetTitle(ACAO, "Sobrecarga")
	ContextActionService:SetPosition(ACAO, UDim2.new(1, -140, 1, -180))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO)
end

--══════════════════════════════════════════════════════════════
-- CICLO
--══════════════════════════════════════════════════════════════


--══════════════════════════════════════════════════════════════
-- O FEIXE É SEGURADO
--
-- `Tool.Activated` abre e `Tool.Deactivated` fecha — o par que o Roblox já dá
-- para clique mantido. Entre os dois, a mira sobe a `PASSO_MIRA`, e é isso que
-- faz o feixe VARRER em vez de apontar para onde estava quando saiu.
--
-- 12 pacotes por segundo. Um `RenderStepped` mandaria 60 por um ponto que o
-- mouse move devagar, e o desenho do feixe já interpola o meio do caminho.
--══════════════════════════════════════════════════════════════

local PASSO_MIRA = 0.08
local LIMITE_FEIXE = 6
local segurando = false

Tool.Activated:Connect(function()
	if not souODono() or segurando then return end
	segurando = true
	VFXRemote:FireServer(mira(), "ABRE")
	task.spawn(function()
		local ate = os.clock() + LIMITE_FEIXE
		while segurando and equipado and os.clock() < ate do
			VFXRemote:FireServer(mira(), "MIRA")
			task.wait(PASSO_MIRA)
		end
		-- o teto de tempo também fecha: soltar o clique é o caminho normal, e
		-- ele não pode ser o ÚNICO, ou um alt-tab deixaria o feixe ligado.
		if segurando then
			segurando = false
			VFXRemote:FireServer(mira(), "FECHA")
		end
	end)
end)

Tool.Deactivated:Connect(function()
	if not souODono() or not segurando then return end
	segurando = false
	VFXRemote:FireServer(mira(), "FECHA")
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
