-- Client.lua
-- Script com RunContext = Client — Xester  (UMA Tool, DUAS formas)
--
--═══════════════════════════════════════════════════════════════
-- POR QUE NÃO É LocalScript
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o desenho com `FireAllClients` e ele CHEGA em
--   todo mundo — mas o único ouvinte seria o de quem está segurando, e o VFX
--   apareceria só para o portador. `RunContext = Client` roda em TODO cliente,
--   e nada saiu de dentro da Tool.
--
--   A ENTRADA continua sendo só do dono: `souODono()` confere antes de
--   qualquer bind. Rodar em todo cliente não é o mesmo que aceitar de todos.
--
-- A ANIMAÇÃO NÃO ESTÁ AQUI
--
--   O rig é do servidor, porque `Weld` criado no cliente não replica e os
--   outros jogadores viam o portador parado.
--
-- OS BINDS TROCAM COM A FORMA
--
--   Forma 1 tem OITO teclas (Q E R T Y U P F), Forma 2 tem SEIS (G H J K L F).
--   Deixar as catorze ligadas o tempo todo faria o jogador apertar `Q` na
--   forma de dragão e não acontecer nada, sem saber por quê — e encheria a
--   tela de celular com botão morto.
--
--   Quem manda a forma é o SERVIDOR, por `AcaoRemote:FireClient(jogador,
--   "FORMA", n)`. O cliente não decide em que forma está: ele é avisado. Se
--   ele decidisse, bastaria mentir para usar as duas ao mesmo tempo.
--
-- OS BOTÕES DE CELULAR, EM GRADE
--
--   `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...)` — o
--   terceiro argumento faz o Roblox desenhar o botão sozinho. São até oito, e
--   com a mesma posição eles empilham e os de baixo ficam inalcançáveis.
--   Então vão em DUAS COLUNAS de quatro, e a coluna de fora é a mais distante
--   do polegar de propósito: é lá que ficam as habilidades longas.
--═══════════════════════════════════════════════════════════════

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool           = script.Parent
local VFXRemote      = Tool:WaitForChild("VFXRemote")
local AcaoRemote     = Tool:WaitForChild("AcaoRemote")
local VFX            = require(Tool:WaitForChild("VFXModule"))

local CFG = {
	ALCANCE_MIRA = 60,
	--- de quanto em quanto tempo a mira móvel do Prisma é reenviada. Um
	--- `RenderStepped` mandaria 60 pacotes por segundo por um alvo que anda
	--- devagar; 12 por segundo é o bastante para o feixe acompanhar o mouse.
	PASSO_MIRA   = 0.08,
	COL_DIREITA  = -150,
	COL_ESQUERDA = -300,
	BASE         = -190,
	DEGRAU       = -70,
}

--- A grade dos botões: tecla, rótulo, coluna e linha.
---
--- `F` fica sozinho na linha de baixo das duas formas, e no mesmo lugar nas
--- duas: é a tecla que troca de forma, e ela não pode andar pela tela quando
--- a forma muda — o dedo já estaria a caminho.
local FORMA1 = {
	{ tecla = "Q", rotulo = "Curtain Call",  col = 1, linha = 1,
	  botao = Enum.KeyCode.ButtonR1 },
	{ tecla = "E", rotulo = "Four Suits",    col = 1, linha = 2,
	  botao = Enum.KeyCode.ButtonL1 },
	{ tecla = "R", rotulo = "Labyrinth",     col = 1, linha = 3,
	  botao = Enum.KeyCode.ButtonR2 },
	{ tecla = "T", rotulo = "Ace Gate",      col = 1, linha = 4,
	  botao = Enum.KeyCode.ButtonL2 },
	{ tecla = "Y", rotulo = "House",         col = 2, linha = 1 },
	{ tecla = "U", rotulo = "Eclipse",       col = 2, linha = 2 },
	{ tecla = "P", rotulo = "Royal Guard",   col = 2, linha = 3 },
	{ tecla = "F", rotulo = "FINAL DEAL",    col = 2, linha = 4,
	  botao = Enum.KeyCode.ButtonY },
}

local FORMA2 = {
	{ tecla = "G", rotulo = "Wyrm Sparks",   col = 1, linha = 1,
	  botao = Enum.KeyCode.ButtonR1 },
	{ tecla = "H", rotulo = "Crown",         col = 1, linha = 2,
	  botao = Enum.KeyCode.ButtonL1 },
	{ tecla = "J", rotulo = "Requiem",       col = 1, linha = 3,
	  botao = Enum.KeyCode.ButtonR2, segura = true },
	{ tecla = "K", rotulo = "Prism",         col = 1, linha = 4,
	  botao = Enum.KeyCode.ButtonL2 },
	{ tecla = "L", rotulo = "FINAL PAGE",    col = 2, linha = 1 },
	{ tecla = "F", rotulo = "REVERSAL",      col = 2, linha = 4,
	  botao = Enum.KeyCode.ButtonY },
}

--- `Enum.KeyCode` por letra. Escrever `Enum.KeyCode[tecla]` funcionaria, mas
--- falharia em SILÊNCIO num nome errado — e um bind que não nasce é uma
--- habilidade que o jogador nunca alcança.
local CODIGO = {
	Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, R = Enum.KeyCode.R,
	T = Enum.KeyCode.T, Y = Enum.KeyCode.Y, U = Enum.KeyCode.U,
	P = Enum.KeyCode.P, F = Enum.KeyCode.F, G = Enum.KeyCode.G,
	H = Enum.KeyCode.H, J = Enum.KeyCode.J, K = Enum.KeyCode.K,
	L = Enum.KeyCode.L,
}

local equipado = false
local forma = 1
local rato = nil
local ligados = {}
local prismaLigado = false

--═══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--═══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {})
end)

--═══════════════════════════════════════════════════════════════
-- MIRA — só o dono
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
	if not alvo then
		return origem.Position + origem.CFrame.LookVector * 20
	end
	local delta = alvo - origem.Position
	if delta.Magnitude > CFG.ALCANCE_MIRA then
		return origem.Position + delta.Unit * CFG.ALCANCE_MIRA
	end
	return alvo
end

--═══════════════════════════════════════════════════════════════
-- A MIRA MÓVEL DO PRISMA
--
-- `K` diz que o jogador pode mover o ponto de impacto por alguns segundos. O
-- cliente manda o ponto; quem decide se ele ainda vale é o SERVIDOR, que sabe
-- se o prisma está de pé. `K_MIRA` não é habilidade e não paga recarga.
--═══════════════════════════════════════════════════════════════

local function seguirComOPrisma()
	if prismaLigado then return end
	prismaLigado = true
	task.spawn(function()
		local ate = os.clock() + 6
		while prismaLigado and equipado and os.clock() < ate do
			AcaoRemote:FireServer("K_MIRA", mira())
			task.wait(CFG.PASSO_MIRA)
		end
		prismaLigado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- ENTRADA
--═══════════════════════════════════════════════════════════════

local function nomeDaAcao(tecla)
	return "Xester_" .. tecla
end

local function desligarEntrada()
	for _, nome in ipairs(ligados) do
		ContextActionService:UnbindAction(nome)
	end
	ligados = {}
	prismaLigado = false
end

local function ligarEntrada()
	desligarEntrada()
	local grade = (forma == 2) and FORMA2 or FORMA1

	for _, item in ipairs(grade) do
		local codigo = CODIGO[item.tecla]
		if codigo then
			local nome = nomeDaAcao(item.tecla)
			local segura = item.segura == true
			ContextActionService:BindAction(nome, function(_acao, estado)
				if not equipado then return end
				-- `Requiem` é a única que quer os DOIS lados: `Begin` começa a
				-- carga, `End` solta o sopro. As outras só querem o `Begin` —
				-- mandar o `End` delas faria a habilidade sair duas vezes.
				if segura then
					if estado == Enum.UserInputState.Begin then
						AcaoRemote:FireServer(item.tecla, mira(), "Begin")
					elseif estado == Enum.UserInputState.End
							or estado == Enum.UserInputState.Cancel then
						AcaoRemote:FireServer(item.tecla, mira(), "End")
					end
					return Enum.ContextActionResult.Sink
				end
				if estado ~= Enum.UserInputState.Begin then return end
				AcaoRemote:FireServer(item.tecla, mira())
				if item.tecla == "K" then seguirComOPrisma() end
				return Enum.ContextActionResult.Sink
			end, true, codigo, item.botao)

			ContextActionService:SetTitle(nome, item.rotulo)
			local x = (item.col == 2) and CFG.COL_ESQUERDA or CFG.COL_DIREITA
			local y = CFG.BASE + CFG.DEGRAU * (item.linha - 1)
			ContextActionService:SetPosition(nome, UDim2.new(1, x, 1, y))
			table.insert(ligados, nome)
		end
	end
end

--- O servidor avisa a forma. Nunca o contrário.
AcaoRemote.OnClientEvent:Connect(function(assunto, valor)
	if assunto ~= "FORMA" then return end
	if valor ~= 1 and valor ~= 2 then return end
	forma = valor
	prismaLigado = false
	if equipado and souODono() then
		ligarEntrada()
	end
end)

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
	prismaLigado = false
	desligarEntrada()
	VFX.LimparTudo()
end

Tool.Unequipped:Connect(aoGuardar)
Tool.Destroying:Connect(aoGuardar)
