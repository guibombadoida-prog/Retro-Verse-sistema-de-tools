-- Client.lua — LocalScript "Client" do conjunto ASTRAL
--
-- Papel (§12.10): capturar entrada e EXECUTAR os VFX recebidos pelo VFXRemote.
-- Não decide dano, não decide alvo, não decide estado. Quem decide é o
-- servidor; o Núcleo é quem aplica regra de combate.
--
-- O VFXRemote é UNIDIRECIONAL: aqui só existe OnClientEvent.
-- O AcaoRemote é a saída: FireServer com o nome da habilidade e a MIRA.
--
-- Mira vai como DADO (Vector3), nunca como Instance. O original usava uma
-- RemoteFunction cliente->servidor para perguntar a posição do mouse: isso
-- pendura a thread do servidor quando o cliente não responde.

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local Tool       = script.Parent
local Jogador    = Players.LocalPlayer
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local Mouse = Jogador:GetMouse()

--═══════════════════════════════════════════════════════════════
-- ENTRADA — teclado, controle e CELULAR, pelo mesmo caminho
--
-- `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...teclas)`.
-- O terceiro argumento é o que resolve o mobile: o Roblox desenha o botão de
-- toque sozinho, com o tamanho e a área de acerto que o jogador espera.
--
-- POR QUE NÃO UMA ScreenGui COM OS BOTÕES
--   O modelo original trazia uma (`Astral_UI`, com os cooldowns de Q/E/X) e ela
--   saiu: ScreenGui dentro de Tool é proibida — efeito só no mundo 3D. E o
--   botão feito à mão teria de ser reposicionado a cada tamanho de tela.
--   `ContextActionService` já está na lista de serviços que a Regra nº 1
--   permite, porque é serviço de COMPORTAMENTO e não traz asset de fora.
--
-- QUAIS BOTÕES APARECEM
--   Sai do StringValue `Acoes` da própria Tool ("Q:Redirecionar|E:Detonar|
--   X:Pulsar"). Sem ele, a Nova mostraria três botões e dois não fariam nada —
--   no celular, botão que não responde é pior que botão nenhum.
--═══════════════════════════════════════════════════════════════

local TECLA_DE = {
	Q = Enum.KeyCode.Q,
	E = Enum.KeyCode.E,
	X = Enum.KeyCode.X,
}

-- botão do controle, para quem joga no gamepad
local BOTAO_DE = {
	Q = Enum.KeyCode.ButtonX,
	E = Enum.KeyCode.ButtonY,
	X = Enum.KeyCode.ButtonR1,
}

local equipado = false
local ligadas = {}

local function acoesDaTool()
	local declarado = Tool:FindFirstChild("Acoes")
	local bruto = (declarado and declarado.Value) or "X:Extra"
	local lista = {}
	for pedaco in string.gmatch(bruto, "[^|]+") do
		local tecla, rotulo = string.match(pedaco, "^(%w+):(.+)$")
		if tecla and TECLA_DE[tecla] then
			table.insert(lista, { tecla = tecla, rotulo = rotulo })
		end
	end
	return lista
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

local function mira()
	-- posição do mouse no mundo; se não houver alvo, um ponto à frente
	if Mouse and Mouse.Hit then return Mouse.Hit.Position end
	local personagem = Jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz then return raiz.Position + raiz.CFrame.LookVector * 30 end
	return Vector3.new()
end

local function ligarEntrada()
	if #ligadas > 0 then return end

	local lista = acoesDaTool()
	for indice, acao in ipairs(lista) do
		local nome = "Astral_" .. acao.tecla
		local tecla = acao.tecla

		ContextActionService:BindAction(nome, function(_acao, estado)
			if estado ~= Enum.UserInputState.Begin then return end
			if not equipado then return end
			AcaoRemote:FireServer(tecla, mira())
			return Enum.ContextActionResult.Sink
		end, true, TECLA_DE[tecla], BOTAO_DE[tecla])

		ContextActionService:SetTitle(nome, acao.rotulo)

		-- Empilhados acima do botão de pulo, de baixo para cima. Posição em
		-- escala, não em pixel: tela de celular pequeno e tablet dividem a
		-- mesma conta.
		ContextActionService:SetPosition(nome, UDim2.new(
			1, -140, 1, -180 - (indice - 1) * 76))

		table.insert(ligadas, nome)
	end
end

local function desligarEntrada()
	for _, nome in ipairs(ligadas) do
		ContextActionService:UnbindAction(nome)
	end
	table.clear(ligadas)
end

Tool.Equipped:Connect(function()
	equipado = true
	ligarEntrada()
end)

Tool.Unequipped:Connect(function()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end)

--═══════════════════════════════════════════════════════════════
-- RECEPÇÃO DE VFX
--═══════════════════════════════════════════════════════════════

--- Resolve nome de personagem -> BasePart. O payload traz DADO, não Instance.
local function parteDe(nome)
	if type(nome) ~= "string" or nome == "" then return nil end
	local modelo = workspace:FindFirstChild(nome)
	if not modelo then return nil end
	return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
end

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	dados = dados or {}

	if tipo == "PARAR" then
		VFX.Parar(dados.id)
		return
	end

	-- Efeito presos a um personagem: o cliente resolve o nome em parte
	if dados.alvoNome then
		local parte = parteDe(dados.alvoNome)
		if not parte then return end
		dados.posicao = parte.Position + (dados.deslocamento or Vector3.new())
	end

	VFX.Executar(tipo, dados)
end)

--═══════════════════════════════════════════════════════════════
-- LIMPEZA
--═══════════════════════════════════════════════════════════════

local function limpar()
	desligarEntrada()
	VFX.LimparTudo()
end

Tool.Destroying:Connect(limpar)

Jogador.CharacterRemoving:Connect(limpar)
