#!/usr/bin/env python3
"""
gerar_servers_faker.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule`, o `R6CFrameAnimator` e — nas
duas que têm cena — a `CutsceneCam` das 7 Tools do conjunto FAKER.

    python3 FERRAMENTAS/gerar_servers_faker.py

O PEDIDO DESTE CONJUNTO, LITERAL: "FAÇA COM QUE OS EFEITOS APAREÇA PARA TODOS"

    É o conserto, e não uma preferência de estilo. O `faker_tools.rbxmx` tem
    **796 linhas de habilidade em dois LocalScript** (`Client` 431 e
    `AbbilityClient` 365) e um `Shoot` de servidor com **40 linhas**.

    LocalScript dentro de Tool só roda para o jogador cujo Character a contém.
    O resultado prático da origem:

      · o VFX acontecia SÓ na tela de quem segurava a Tool;
      · o servidor não aplicava dano nenhum — zero `TakeDamage`, zero escrita
        em `Health` no modelo inteiro.

    Aqui:

      · o `Client` é `Script` com `RunContext = Client`, que roda em TODO
        cliente — inclusive dentro da Tool de outro jogador;
      · quem manda desenhar é o SERVIDOR, por `VFXRemote:FireAllClients`;
      · quem aplica dano é o servidor, por `TakeDamage` através do Núcleo.

    Nada saiu de dentro da Tool para isso acontecer. É a Regra nº 1 intacta.

O BEAT VEM COMO KEYFRAME

    `onBeat(kf, indice)`, e a marca está em `kf.marca`. Comparar o keyframe com
    string nunca dá verdadeiro e falha em SILÊNCIO: a animação roda inteira e o
    dano não acontece. Custou 14 Tools de dois conjuntos, e
    `TESTES/verificar_rbxmx.py` passou a cobrar isso por nome. Aqui o helper
    `marcaDe` está escrito desde a primeira linha.

O SERVIDOR NÃO MOVE GEOMETRIA POR QUADRO

    A entidade do `Faker Entity` e o poço do `Abismo Profundo` duram segundos, e
    a tentação é um `RenderStepped` de servidor arrastando peça. Não há nenhum:
    o servidor manda o efeito UMA vez com a duração dentro do payload, e quem
    anima é o `TweenService` do cliente. O servidor só volta a falar nos TICKS
    de dano, que são a cada 0.8–1.0 s.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_FAKER = os.path.join(DADOS, "VFXModule_Faker.lua")
CAM_FAKER = os.path.join(DADOS, "CutsceneCam_Faker.lua")


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto FAKER)
--
-- Sai da ÚNICA Tool do `faker_tools.rbxmx`, que é o His Cube original. Handle e
-- malhas vêm de lá; a habilidade é escrita aqui. Ver
-- `FERRAMENTAS/preparar_faker.py` para o mapa das sete malhas.
--
--   M1   {rotulo_primaria}
--   {tecla}    {rotulo_extra}   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
-- A origem punha tudo em LocalScript, e por isso a habilidade dela era
-- invisível para o resto do servidor.
--
-- Gerado por FERRAMENTAS/gerar_servers_faker.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
{extra_require}
--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "{arquetipo}"

local CFG = {{
{cfg}
}}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoExtra = 0, 0
local ocupado = false
local ativos = {{}}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extra
{estado}

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 67 `math.random` da origem —
--- e neste conjunto isso pesa mais que nos outros, porque TODOS os clientes
--- desenham. Um sorteio faria cada um ver uma cena diferente, o que lê como
--- lag, não como efeito.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function angulo(i)
	return i * 2.399963
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Toca um som numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
--- some no quadro seguinte mata o som no quadro em que ele nasce.
local function tocarEm(nome, posicao, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function tocar(nome, pitch, corte)
	local base = Handle:FindFirstChild(nome)
	if not base or not base:IsA("Sound") then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- O beat vem como KEYFRAME, não como string.
---
--- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
--- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
--- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
--- dano não acontece. Custou os 14 Tools de dois conjuntos.
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL. A Tool sozinha num place vazio funciona
-- por inteiro — é o teste que decide a Regra nº 1.
--
-- A ORIGEM NÃO TINHA DANO NENHUM. Zero `TakeDamage` e zero escrita em `Health`
-- nas 796 linhas dela: era casca de VFX privada. Este bloco é o que faz as sete
-- serem Tools de combate e não fogos de artifício.
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	if _G.Combate and _G.Combate.registrarAtaque then
		_G.Combate.registrarAtaque(jogador, Tool, ARQUETIPO)
	else
		local marca = alvoHum:FindFirstChild("creator")
		if marca then marca.Parent = nil end
		marca = Instance.new("ObjectValue")
		marca.Name = "creator"
		marca.Value = jogador
		marca.Parent = alvoHum
		Debris:AddItem(marca, 3)
	end
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local final = (_G.Combate and _G.Combate.calcular
		and _G.Combate.calcular(jogador, alvoHum, bruto)) or bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
local function alvosEm(posicao, raio, limite)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(
			posicao, raio, personagem, jogador, humanoide, limite or 10) or {{}}
	end

	local achados, vistos = {{}}, {{}}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not vistos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE)
end

--- O alvo mais perto de um ponto.
local function maisPerto(ponto, raio)
	local melhor, dist = nil, math.huge
	for _, alvo in ipairs(alvosEm(ponto, raio, 12)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local d = (alvoRaiz.Position - ponto).Magnitude
			if d < dist then melhor, dist = alvo, d end
		end
	end
	return melhor
end

local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Puxar é empurrar com o sinal trocado, e é o verbo deste conjunto: o poço, a
--- prisão e a implosão puxam. Sai por prazo no `Debris`, como tudo aqui.
local function puxar(alvoHum, centro, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end
	local delta = centro - alvoRaiz.Position
	if delta.Magnitude < 0.5 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.3)
end

--- Prender no lugar com prazo. `BodyPosition` no ponto onde o alvo já está —
--- não é teleporte, é âncora.
local function prender(alvoHum, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local ancora = Instance.new("BodyPosition")
	ancora.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	ancora.P = 12000
	ancora.D = 900
	ancora.Position = alvoRaiz.Position
	ancora.Parent = alvoRaiz
	Debris:AddItem(ancora, tempo or 3)
	return ancora
end

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta garantida. Guarda a velocidade ANTES de mexer, e devolve
--- essa — nunca um número fixo, porque o alvo pode ter velocidade própria.
local function afrouxar(alvoHum, fator, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	local antes = alvoHum.WalkSpeed
	alvoHum.WalkSpeed = antes * (fator or 0.5)
	task.delay(tempo or 3, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = antes
		end
	end)
end

'''

# só nas duas com cutscene
CUTSCENE = '''
--═══════════════════════════════════════════════════════════════
-- A CUTSCENE — um `FireClient` POR ESPECTADOR
--
-- `GRAMATICA_CUTSCENE.md` regra 2: enquadramento por espectador.
--
--   quem invoca  ->  vê o evento de fora e de baixo
--   quem está no raio  ->  vê a coisa vindo em cima DELE
--
-- A diferença para o conjunto DRAMA: lá a cena é entre DOIS, porque é execução
-- de um alvo. Aqui é evento de área, então a plateia é toda a gente dentro do
-- raio — cada um recebendo o papel `ALVO`, e o `INVOCADOR` só um. Quem está
-- fora do raio não perde a câmera, que é o ponto da regra.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(plateia, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	-- o primeiro da plateia é a referência de enquadramento do invocador
	local primeiro = plateia and plateia[1]
	local corpoPrimeiro = primeiro and primeiro.Parent
	local nomeAlvo = corpoPrimeiro and corpoPrimeiro.Name or nil

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, alvoNome = nomeAlvo,
	})

	for _, alvoHum in ipairs(plateia or {}) do
		local corpo = alvoHum and alvoHum.Parent
		local jogadorAlvo = corpo and Players:GetPlayerFromCharacter(corpo)
		if jogadorAlvo and jogadorAlvo ~= jogador then
			CutsceneRemote:FireClient(jogadorAlvo, "INICIO", {
				papel = "ALVO", nome = nomeBeat,
				portador = personagem.Name, alvoNome = corpo.Name,
			})
		end
	end
end

local function beatCena(nome)
	if not emCena then return end
	CutsceneRemote:FireAllClients("BEAT", { nome = nome })
end

--- Fechar a cena é caminho que não pode falhar: ele roda no fim da sequência,
--- no `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end

'''


RODAPE = '''
--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if tecla ~= "{tecla}" then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	extra(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "{sufixo}", Poses, Poses.SEQUENCIAS)
{ao_equipar}end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
{ao_guardar}	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
'''


DESPACHANTE = '''
--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT
--
-- ⚠️ ESTE BLOCO ESTAVA FALTANDO. O gerador emitia `despachar({...})` em toda
--    habilidade e NUNCA emitia a definição: `attempt to call a nil value` na
--    primeira linha de cada `primaria`/`extra`. Sem dano, sem VFX, sem som —
--    28 Tools de quatro conjuntos, mortas.
--
--    A conversão de `if marca == "X"` para tabela de keyframe trocou o corpo
--    das habilidades nos GERADORES, mas só três dos sete ganharam a definição
--    junto. Os arquivos `.lua` já gerados continuaram certos até alguém
--    regerar — e aí a Tool inteira parava.
--
-- Cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { cam = true, sfx = { "IMPACTO", 0.9 }, faz = bater }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe
--   `sfx`  toca um som: `{ nome, pitch }`
--   `faz`  o trabalho que não cabe em dado
--
-- `beatCena` só existe nas Tools com cutscene. Nas outras ele é nil, e a
-- guarda `kf.cam and beatCena` resolve — ler global inexistente devolve nil,
-- não estoura.
--═══════════════════════════════════════════════════════════════

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam and beatCena then beatCena(marca) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

'''


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (conjunto FAKER)
--
-- ESTE ARQUIVO É O CONSERTO DO CONJUNTO.
--
-- O `faker_tools.rbxmx` tinha 796 linhas de habilidade em dois **LocalScript**.
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém: o servidor mandava o aviso com `FireAllClients` e ele CHEGAVA em todo
-- mundo, mas o único ouvinte era o de quem estava segurando a Tool. O efeito
-- acontecia só na tela do portador.
--
-- `RunContext = Client` roda em TODO cliente — inclusive neste arquivo, que
-- está dentro da Tool de outro jogador. Nada saiu de dentro da Tool para isso.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica e os outros jogadores viam o portador parado.
--
-- MOBILE: `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...)`.
-- O terceiro argumento faz o Roblox desenhar o botão de toque sozinho. A origem
-- montava a própria UI de habilidade com `SetTitle`; `ScreenGui` dentro de Tool
-- é proibida, e o botão do CAS faz o mesmo trabalho sem sair da Tool.
--
-- Gerado por FERRAMENTAS/gerar_servers_faker.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO = "Faker_{sufixo}_{tecla}"
local ALCANCE_MIRA = {alcance_mira}

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
	VFX.Executar(tipo, dados or {{}})
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
		AcaoRemote:FireServer("{tecla}", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.{tecla}, Enum.KeyCode.{botao})

	ContextActionService:SetTitle(ACAO, "{rotulo_extra}")
	ContextActionService:SetPosition(ACAO, UDim2.new(1, -140, 1, -180))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO)
end

--══════════════════════════════════════════════════════════════
-- CICLO
--══════════════════════════════════════════════════════════════

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
'''


# ═══════════════════════════════════════════════════════════════
# AS 7 TOOLS
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {}


CONJUNTO["Ultra Combo"] = dict(
    objeto="UltraCombo_Server_V1", sufixo="FakerUltraCombo",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="combo de quatro que encadeiam, de palma",
    rotulo_extra="Selo",
    cfg="""	ALCANCE        = 6,
	RAIO_GOLPE     = 6.5,
	DANO_1         = 10,
	DANO_2         = 11,
	DANO_3         = 14,
	DANO_4         = 26,
	EMPURRAO       = 24,
	EMPURRAO_4     = 70,
	RECARGA        = 0.32,
	JANELA_COMBO   = 1.3,
	TOMBO          = 1.4,

	RECARGA_EXTRA  = 12,
	RAIO_SELO      = 14,
	DANO_SELO      = 34,
	EMPURRAO_SELO  = 46,
	LENTIDAO_SELO  = 0.55,
	TEMPO_SELO     = 2.5,""",
    estado="local passoCombo = 0\nlocal ultimoGolpe = 0\n"
           "local ORDEM_COMBO = { \"COMBO_1\", \"COMBO_2\", \"COMBO_3\", \"COMBO_4\" }",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o combo de quatro
--
-- `Ultra Combo` é o nome que o PRÓPRIO modelo dá à habilidade Q dele:
-- `Services.Input:SetTitle("Primary", "Ultra Combo")`. Não foi inventado aqui.
--
-- O passo avança só se o golpe anterior caiu dentro da janela. Passou do prazo,
-- volta ao primeiro: é o que faz combo ser combo e não uma fila de golpes
-- independentes.
--
-- Bate de PALMA, não de punho. O punho é o vocabulário do conjunto DRAMA; aqui
-- quem bate de verdade é o disco.
--═══════════════════════════════════════════════════════════════

local function bater(dano, forca, escala)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
		aplicarDano(alvo, dano)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), forca, 0.18)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = escala or 1 })
		end
		achou = true
	end
	if achou then
		tocarEm("DISPARO", ponto, 1 + jitter(0.4) * 0.1)
	end
	return achou
end

function primaria(_mira)
	ocupado = true

	if os.clock() - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo % 4 + 1
	ultimoGolpe = os.clock()

	local dano = ({ CFG.DANO_1, CFG.DANO_2, CFG.DANO_3, CFG.DANO_4 })[passoCombo]

	rig:PlaySequence(ORDEM_COMBO[passoCombo], despachar({
		BATE = { faz = function()
			bater(dano, CFG.EMPURRAO, 0.9)
		end },
		BATE_FORTE = { faz = function()
			-- o quarto é o giro: pega em volta, não só à frente
			local ponto = raiz.Position
			tocarEm("AGUDO", ponto, 0.8)
			vfx("IMPACTO", { posicao = ponto, escala = 1.6 })
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE * 1.4, 8)) do
				aplicarDano(alvo, CFG.DANO_4)
				tombar(alvo, CFG.TOMBO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - ponto)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_4, 0.3)
				end
			end
		end },
		FIM = { faz = function()
			passoCombo = 0
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o selo
--
-- O disco `E` do próprio modelo, deitado no chão e aberto até 14 studs. É a
-- única das sete malhas que o `Ultra Combo` carrega, e ela é chata (9.9 × 1.0
-- × 9.9) — feita para ficar no piso.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	passoCombo = 0
	rig:PlaySequence("SELO", despachar({
		ERGUE = { sfx = { "AGUDO", 0.7 } },
		FECHA = { faz = function()
			local centro = raiz.Position - Vector3.new(0, 2.4, 0)
			vfx("IMPACTO", { posicao = centro, escala = 2.8 })
			tocarEm("DISPARO", centro, 0.55)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_SELO, 12)) do
				aplicarDano(alvo, CFG.DANO_SELO)
				afrouxar(alvo, CFG.LENTIDAO_SELO, CFG.TEMPO_SELO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_SELO, 0.28)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tpassoCombo = 0\n",
)


CONJUNTO["Era Do Fim"] = dict(
    objeto="EraDoFim_Server_V1", sufixo="FakerEraDoFim",
    arquetipo="EXPLOSIVO", tecla="R", botao="ButtonR1", alcance_mira=60,
    cutscene=True,
    rotulo_primaria="o cogumelo — ultimate com cutscene",
    rotulo_extra="Onda",
    cfg="""	ALCANCE        = 10,
	RECARGA        = 40,
	RAIO_CENA      = 70,
	RAIO_FIM       = 58,
	RAIO_NUCLEO    = 22,
	DANO_FIM       = 120,
	DANO_BORDA     = 55,
	EMPURRAO_FIM   = 130,
	TOMBO_FIM      = 3,

	RECARGA_EXTRA  = 14,
	RAIO_ONDA      = 88,
	DANO_ONDA      = 34,
	EMPURRAO_ONDA  = 92,
	DURACAO_ONDA   = 1.1,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o fim de uma era, COM CUTSCENE
--
-- "An end of an Era" é o nome que o PRÓPRIO modelo dá à habilidade E dele:
-- `Services.Input:SetTitle("Secondary", "An end of an Era")`.
--
-- ULTIMATE: 7.20 s com 74% de preparação, dentro da faixa da regra 5. A malha é
-- o `Mushroom` de **522 × 543 × 522 studs** — a maior coisa que já entrou neste
-- repositório por duas ordens de grandeza.
--
-- A plateia da cena é toda a gente no raio, não um alvo só. É evento de área, e
-- a regra 2 vale igual: cada um recebe o papel dele.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 16), "CAMERA")

	rig:PlaySequence("FIM_DA_ERA", despachar({
		CAMERA = { sfx = { "GRAVE", 0.5 } },
		ERGUE = { cam = true, sfx = { "AGUDO", 0.6 } },
		CARGA = { cam = true, sfx = { "GRAVE", 0.4 } },
		SEGURA = { cam = true },
		DESCE = { cam = true, sfx = { "DISPARO", 0.7 } },
		DETONA = { cam = true, faz = function()
			local onde = raiz and raiz.Position or centro
			vfx("COGUMELO", { posicao = onde, escala = 1 })
			vfx("ANEL", { posicao = onde, escala = 1.4, duracao = 1.6 })
			tocarEm("GRAVE", onde, 0.35)
			tocarEm("DISPARO", onde, 0.45)
			-- quem está no núcleo paga o cheio; quem está na borda paga menos.
			-- Dois raios, não um: uma explosão de 58 studs com dano chapado
			-- mataria meio servidor por estar por perto.
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_FIM, 20)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude or CFG.RAIO_FIM
				if d <= CFG.RAIO_NUCLEO then
					aplicarDano(alvo, CFG.DANO_FIM)
					tombar(alvo, CFG.TOMBO_FIM)
				else
					aplicarDano(alvo, CFG.DANO_BORDA)
					tombar(alvo, CFG.TOMBO_FIM * 0.5)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - onde)
						+ Vector3.new(0, 0.8, 0), CFG.EMPURRAO_FIM, 0.4)
				end
			end
		end },
		FIM = { faz = function()
			fecharCena()
		end },
	}), function()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a onda
--
-- O `Ring` de 500 studs, rasteiro. Dano baixo e alcance enorme: é limpeza de
-- espaço, não execução.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("ONDA", despachar({
		ABRE = { sfx = { "AGUDO", 0.75 } },
		SOLTA = { faz = function()
			local centro = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("ANEL", { posicao = centro, escala = 1,
				duracao = CFG.DURACAO_ONDA })
			tocarEm("GRAVE", centro, 0.6)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ONDA, 20)) do
				aplicarDano(alvo, CFG.DANO_ONDA)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_ONDA, 0.34)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tfecharCena()\n",
)


CONJUNTO["Sala Do Abismo"] = dict(
    objeto="SalaDoAbismo_Server_V1", sufixo="FakerSalaAbismo",
    arquetipo="ESPECTRAL", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="fecha a sala em volta de voce",
    rotulo_extra="Implosao",
    cfg="""	ALCANCE        = 8,
	RECARGA        = 24,
	RAIO_SALA      = 26,
	DURACAO_SALA   = 8,
	DANO_TICK      = 6,
	INTERVALO_TICK = 1,
	LENTIDAO_SALA  = 0.6,

	RECARGA_EXTRA  = 10,
	DANO_IMPLODE   = 45,
	FORCA_IMPLODE  = 96,
	TOMBO_IMPLODE  = 1.6,""",
    estado="local salaId = nil\nlocal salaCentro = nil\nlocal geracaoSala = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — fechar a sala
--
-- TRANSFORMAÇÃO pela regra 4: 2.00 s em 3 : 97. A sala fecha no PRIMEIRO
-- quadro e o resto da sequência é sustentar — quem espera a animação acabar
-- para ver o efeito não vê transformação, vê carregamento.
--
-- A sala VIVE depois da sequência: 8 s, com dano por tick. Quem move a geometria
-- é o cliente, por tween; o servidor só volta a falar nos ticks de 1 s. Servidor
-- arrastando peça por quadro é o defeito que este repositório já anotou em
-- quatro Tools.
--═══════════════════════════════════════════════════════════════

local function fecharSala()
	geracaoSala = geracaoSala + 1
	if salaId then
		vfx("PARAR", { id = salaId })
		vfx("SALA_FIM", { posicao = salaCentro or (raiz and raiz.Position)
			or Vector3.new(), escala = 1 })
		salaId = nil
	end
	salaCentro = nil
end

local function manterSala(centro, id)
	geracaoSala = geracaoSala + 1
	local minha = geracaoSala
	local ate = os.clock() + CFG.DURACAO_SALA

	task.spawn(function()
		while minha == geracaoSala and os.clock() < ate do
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_SALA, 14)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				afrouxar(alvo, CFG.LENTIDAO_SALA, CFG.INTERVALO_TICK * 1.2)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracaoSala then
			vfx("PARAR", { id = id })
			salaId = nil
			salaCentro = nil
		end
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("FECHA_SALA", despachar({
		FECHA = { faz = function()
			fecharSala()
			local centro = raiz.Position
			salaCentro = centro
			salaId = novoId("SALA")
			vfx("SALA", { posicao = centro, escala = 1,
				raio = CFG.RAIO_SALA, duracao = CFG.DURACAO_SALA,
				id = salaId })
			tocarEm("GRAVE", centro, 0.5)
			manterSala(centro, salaId)
		end },
		SUSTENTA = { sfx = { "AGUDO", 0.8 } },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — implodir a sala
--
-- Sem sala aberta ela não faz nada de graça: a implosão consome a sala. É o que
-- impede a Extra de virar um segundo golpe de área independente.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	local centro = salaCentro
	rig:PlaySequence("IMPLODE", despachar({
		ERGUE = { sfx = { "AGUDO", 0.7 } },
		IMPLODE = { faz = function()
			local onde = centro or raiz.Position
			fecharSala()
			vfx("SALA_FIM", { posicao = onde, escala = centro and 1.6 or 0.9 })
			tocarEm("GRAVE", onde, 0.4)
			if centro then
				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_SALA, 14)) do
					aplicarDano(alvo, CFG.DANO_IMPLODE)
					tombar(alvo, CFG.TOMBO_IMPLODE)
					puxar(alvo, onde, CFG.FORCA_IMPLODE, 0.32)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tfecharSala()\n",
)


CONJUNTO["Ilusao da Alucinacao"] = dict(
    objeto="IlusaodaAlucinacao_Server_V1", sufixo="FakerIlusao",
    arquetipo="ESPECTRAL", tecla="R", botao="ButtonR1", alcance_mira=55,
    cutscene=False,
    rotulo_primaria="espiral que confunde quem olha",
    rotulo_extra="Troca",
    cfg="""	ALCANCE        = 12,
	RECARGA        = 14,
	RAIO_ESPIRAL   = 16,
	DANO_ESPIRAL   = 22,
	LENTIDAO       = 0.4,
	TEMPO_LENTO    = 3.5,
	DURACAO_GIRO   = 1.8,

	RECARGA_EXTRA  = 10,
	RAIO_TROCA     = 42,
	DANO_TROCA     = 14,
	LENTIDAO_TROCA = 0.55,
	TEMPO_TROCA    = 2,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a espiral
--
-- A malha `Spiral` (33 × 17 × 40) é uma das cinco que o código de origem NUNCA
-- ligou. Ela existia no `AbbilityClient`, paga e desligada.
--
-- Confundir aqui é LENTIDÃO, não inversão de controle. Inverter o comando de
-- outro jogador é o tipo de efeito que faz a pessoa achar que travou; a
-- lentidão comunica a mesma coisa e continua jogável.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ESPIRAL", despachar({
		GIRA = { sfx = { "AGUDO", 1.3 } },
		SOLTA = { faz = function()
			local onde = destino or frente(CFG.ALCANCE)
			vfx("ESPIRAL", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO_GIRO })
			tocarEm("GRAVE", onde, 0.9)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ESPIRAL, 12)) do
				aplicarDano(alvo, CFG.DANO_ESPIRAL)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a troca de lugar
--
-- 0.70 s, abaixo da faixa da regra 1 e de propósito: é reação, não golpe.
--
-- Escrever `CFrame` de outro personagem é escrever no MUNDO, que é saída
-- permitida — ler o mundo é que seria dependência. E os dois trocam ao mesmo
-- tempo, com a mesma altura: sem isso um dos dois cai dentro do chão.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_TROCA)
		or maisPerto(frente(CFG.ALCANCE), CFG.RAIO_TROCA)
	if not alvo then
		tocar("AGUDO", 0.5)
		return
	end

	ocupado = true
	rig:PlaySequence("TROCA", despachar({
		SOME = { faz = function()
			vfx("ESPIRAL", { posicao = raiz.Position, escala = 0.5,
				duracao = 0.5 })
			tocarEm("AGUDO", raiz.Position, 1.6)
		end },
		TROCA = { faz = function()
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				local meu = raiz.CFrame
				local dele = alvoRaiz.CFrame
				vfx("ESPIRAL", { posicao = alvoRaiz.Position, escala = 0.6,
					duracao = 0.5 })
				raiz.CFrame = CFrame.new(dele.Position) * (meu - meu.Position)
				alvoRaiz.CFrame = CFrame.new(meu.Position) * (dele - dele.Position)
				aplicarDano(alvo, CFG.DANO_TROCA)
				afrouxar(alvo, CFG.LENTIDAO_TROCA, CFG.TEMPO_TROCA)
				tocarEm("GRAVE", meu.Position, 1.1)
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["Prisao Cubica"] = dict(
    objeto="PrisaoCubica_Server_V1", sufixo="FakerPrisao",
    arquetipo="ESPECTRAL", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=False,
    rotulo_primaria="prende o alvo num cubo",
    rotulo_extra="Estilhaco",
    cfg="""	ALCANCE        = 10,
	RECARGA        = 18,
	RAIO_ALVO      = 30,
	RAIO_PRISAO    = 4.5,
	DURACAO_PRISAO = 4,
	DANO_PRISAO    = 18,

	RECARGA_EXTRA  = 8,
	DANO_ESTILHACO = 55,
	RAIO_ESTILHACO = 12,
	EMPURRAO_ESTIL = 78,
	TOMBO_ESTIL    = 1.8,""",
    estado="local presoId = nil\nlocal presoCentro = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — prender
--
-- Quatro paredes `Erlo` (o bloco 5³) em volta do alvo, e o núcleo `Sphere` (4³)
-- no meio. As duas malhas são do próprio modelo, e `Erlo` é outra das cinco que
-- o código de origem nunca ligou.
--
-- Prender é `BodyPosition` no ponto onde o alvo JÁ ESTÁ, com prazo no `Debris`.
-- Não é teleporte e não é `Anchored`: se a prisão sumir sem aviso, o alvo volta
-- a andar sozinho.
--═══════════════════════════════════════════════════════════════

local function soltarPrisao()
	if presoId then
		vfx("PARAR", { id = presoId })
		presoId = nil
	end
	presoCentro = nil
end

function primaria(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.ALCANCE), CFG.RAIO_ALVO)
	if not alvo then
		tocar("AGUDO", 0.6)
		return
	end

	ocupado = true
	rig:PlaySequence("PRENDE", despachar({
		FORMA = { sfx = { "AGUDO", 1.2 } },
		PRENDE = { faz = function()
			local alvoRaiz = raizDe(alvo)
			if not alvoRaiz then return end
			soltarPrisao()
			presoCentro = alvoRaiz.Position
			presoId = novoId("PRISAO")
			vfx("PRISAO", { posicao = presoCentro, escala = 1,
				raio = CFG.RAIO_PRISAO, duracao = CFG.DURACAO_PRISAO,
				id = presoId })
			tocarEm("DISPARO", presoCentro, 0.7)
			aplicarDano(alvo, CFG.DANO_PRISAO)
			prender(alvo, CFG.DURACAO_PRISAO)
			local meu = presoId
			task.delay(CFG.DURACAO_PRISAO, function()
				if presoId == meu then soltarPrisao() end
			end)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — estilhaçar
--
-- Vale o dobro se houver prisão de pé: é o par da primária, não um golpe solto.
-- Sem prisão ela ainda sai, com o raio e o dano de um golpe comum — a Tool
-- nunca fica inerte, mas o jeito certo de jogar rende mais.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	local centro = presoCentro
	rig:PlaySequence("ESTILHACA", despachar({
		APERTA = { sfx = { "AGUDO", 0.85 } },
		ESTILHACA = { faz = function()
			local onde = centro or frente(CFG.ALCANCE)
			local cheio = centro ~= nil
			soltarPrisao()
			vfx("PRISAO_FIM", { posicao = onde, escala = cheio and 1.5 or 0.9 })
			tocarEm("DISPARO", onde, 0.5)
			local dano = cheio and CFG.DANO_ESTILHACO or CFG.DANO_ESTILHACO * 0.5
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ESTILHACO, 10)) do
				aplicarDano(alvo, dano)
				if cheio then tombar(alvo, CFG.TOMBO_ESTIL) end
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - onde)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_ESTIL, 0.3)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tsoltarPrisao()\n",
)


CONJUNTO["Faker Entity"] = dict(
    objeto="FakerEntity_Server_V1", sufixo="FakerEntity",
    arquetipo="ESPECTRAL", tecla="R", botao="ButtonR1", alcance_mira=55,
    cutscene=True,
    rotulo_primaria="invoca a entidade — ultimate com cutscene",
    rotulo_extra="Enviar",
    cfg="""	ALCANCE        = 10,
	RECARGA        = 30,
	RAIO_CENA      = 40,
	DURACAO_ENT    = 10,
	RAIO_ENT       = 18,
	DANO_TICK      = 9,
	INTERVALO_TICK = 0.8,
	LENTIDAO_ENT   = 0.75,

	RECARGA_EXTRA  = 8,
	RAIO_ENVIO     = 45,
	DANO_ENVIO     = 48,
	RAIO_SALTO     = 14,
	EMPURRAO_ENVIO = 74,""",
    estado="local entidadeId = nil\nlocal entidadeOnde = nil\nlocal geracaoEnt = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — invocar a entidade, COM CUTSCENE
--
-- ULTIMATE: 7.10 s com 72% de preparação, dentro da faixa da regra 5.
--
-- A entidade é o núcleo `Sphere` com o disco `E` girando em volta — as duas
-- malhas que a Tool carrega. Ela FICA onde nasceu e bate em quem chega perto,
-- por tick de 0.8 s.
--
-- ELA NÃO PERSEGUE, e é decisão declarada. Perseguir exigiria o servidor mover
-- geometria por quadro, que é o defeito já anotado em quatro Tools deste
-- repositório. Quem quer a entidade em cima do alvo usa a Extra.
--═══════════════════════════════════════════════════════════════

local function dispensarEntidade()
	geracaoEnt = geracaoEnt + 1
	if entidadeId then
		vfx("PARAR", { id = entidadeId })
		entidadeId = nil
	end
	entidadeOnde = nil
end

local function manterEntidade(onde, id)
	geracaoEnt = geracaoEnt + 1
	local minha = geracaoEnt
	local ate = os.clock() + CFG.DURACAO_ENT

	task.spawn(function()
		while minha == geracaoEnt and os.clock() < ate do
			local centro = entidadeOnde or onde
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ENT, 10)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				afrouxar(alvo, CFG.LENTIDAO_ENT, CFG.INTERVALO_TICK * 1.2)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracaoEnt then
			vfx("PARAR", { id = id })
			entidadeId = nil
			entidadeOnde = nil
		end
	end)
end

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 12), "CAMERA")

	rig:PlaySequence("INVOCA", despachar({
		CAMERA = { sfx = { "GRAVE", 0.55 } },
		CHAMA = { cam = true, sfx = { "AGUDO", 0.7 } },
		CARGA = { cam = true, sfx = { "GRAVE", 0.45 } },
		SEGURA = { cam = true },
		NASCE = { cam = true, faz = function()
			dispensarEntidade()
			local onde = frente(CFG.ALCANCE) + Vector3.new(0, 3, 0)
			entidadeOnde = onde
			entidadeId = novoId("ENTIDADE")
			vfx("ENTIDADE", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO_ENT, id = entidadeId })
			tocarEm("DISPARO", onde, 0.6)
			tocarEm("GRAVE", onde, 0.4)
			manterEntidade(onde, entidadeId)
		end },
		FIM = { faz = function()
			fecharCena()
		end },
	}), function()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — mandar a entidade
--
-- Ela SALTA para o alvo: o servidor manda um `ENTIDADE` novo na posição de
-- destino e move o centro dos ticks. Um salto, não um arraste — o servidor
-- fala uma vez, e quem anima o percurso é o cliente.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	if not entidadeId then
		tocar("AGUDO", 0.5)
		return
	end

	ocupado = true
	rig:PlaySequence("ENVIA", despachar({
		MIRA = { sfx = { "AGUDO", 1.1 } },
		ENVIA = { faz = function()
			local alvo = maisPerto(mira, CFG.RAIO_ENVIO)
			local alvoRaiz = alvo and raizDe(alvo)
			local onde = (alvoRaiz and alvoRaiz.Position) or mira
				or frente(CFG.ALCANCE)
			local partiu = entidadeOnde
			entidadeOnde = onde
			if partiu then
				vfx("FEIXE", { origem = partiu, destino = onde,
					grossura = 2.2, escala = 1.2 })
			end
			vfx("ENTIDADE", { posicao = onde, escala = 1.2, duracao = 2.4 })
			tocarEm("DISPARO", onde, 0.75)
			for _, perto in ipairs(alvosEm(onde, CFG.RAIO_SALTO, 10)) do
				aplicarDano(perto, CFG.DANO_ENVIO)
				local pertoRaiz = raizDe(perto)
				if pertoRaiz then
					empurrar(perto, (pertoRaiz.Position - onde)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_ENVIO, 0.28)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tdispensarEntidade()\n\tfecharCena()\n",
)


CONJUNTO["Abismo Profundo"] = dict(
    objeto="AbismoProfundo_Server_V1", sufixo="FakerAbismo",
    arquetipo="ESPECTRAL", tecla="R", botao="ButtonR1", alcance_mira=55,
    cutscene=False,
    rotulo_primaria="abre o poco no chao",
    rotulo_extra="Puxao",
    cfg="""	ALCANCE        = 12,
	RECARGA        = 26,
	RAIO_POCO      = 22,
	DURACAO_POCO   = 6,
	DANO_TICK      = 7,
	INTERVALO_TICK = 1,
	SUGA           = 26,

	RECARGA_EXTRA  = 10,
	FORCA_PUXAO    = 96,
	DANO_PUXAO     = 30,
	TOMBO_PUXAO    = 1.8,
	DURACAO_ANEL   = 0.9,""",
    estado="local pocoId = nil\nlocal pocoOnde = nil\nlocal geracaoPoco = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — abrir o poço
--
-- `Ring` deitado como boca e `Spiral` como funil, as duas malhas do próprio
-- modelo. O poço não é buraco de verdade — mexer no `Terrain` seria escrever no
-- mapa de todo mundo sem volta, que é a mesma família do `workspace.Gravity`
-- que este repositório já proibiu.
--
-- Ele SUGA: um puxão fraco e contínuo por tick, não um teleporte. Quem quiser
-- sair, sai andando — o puxão forte é a Extra.
--═══════════════════════════════════════════════════════════════

local function fecharPoco()
	geracaoPoco = geracaoPoco + 1
	if pocoId then
		vfx("PARAR", { id = pocoId })
		pocoId = nil
	end
	pocoOnde = nil
end

local function manterPoco(onde, id)
	geracaoPoco = geracaoPoco + 1
	local minha = geracaoPoco
	local ate = os.clock() + CFG.DURACAO_POCO

	task.spawn(function()
		while minha == geracaoPoco and os.clock() < ate do
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_POCO, 14)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				puxar(alvo, onde, CFG.SUGA, CFG.INTERVALO_TICK * 0.8)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracaoPoco then
			vfx("PARAR", { id = id })
			pocoId = nil
			pocoOnde = nil
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ABRE_POCO", despachar({
		ERGUE = { sfx = { "GRAVE", 0.6 } },
		ABRE = { faz = function()
			fecharPoco()
			local onde = (destino or frente(CFG.ALCANCE)) - Vector3.new(0, 1.6, 0)
			pocoOnde = onde
			pocoId = novoId("POCO")
			vfx("POCO", { posicao = onde, escala = 1, raio = CFG.RAIO_POCO,
				duracao = CFG.DURACAO_POCO, id = pocoId })
			tocarEm("GRAVE", onde, 0.4)
			tocarEm("DISPARO", onde, 0.55)
			manterPoco(onde, pocoId)
		end },
		SEGURA = { sfx = { "DISPARO", 0.9 } },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o puxão
--
-- Sem poço aberto ela puxa para a frente do portador, com metade do dano. A
-- Tool nunca fica inerte, mas o par certo — abrir e depois puxar — rende mais.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	local onde = pocoOnde
	rig:PlaySequence("PUXA", despachar({
		ABRE = { sfx = { "DISPARO", 1.2 } },
		PUXA = { faz = function()
			local centro = onde or frente(CFG.ALCANCE)
			local cheio = onde ~= nil
			vfx("ANEL", { posicao = centro, escala = cheio and 1.1 or 0.7,
				duracao = CFG.DURACAO_ANEL })
			tocarEm("GRAVE", centro, 0.45)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_POCO, 14)) do
				aplicarDano(alvo, cheio and CFG.DANO_PUXAO
					or CFG.DANO_PUXAO * 0.5)
				puxar(alvo, centro, CFG.FORCA_PUXAO, 0.34)
				if cheio then tombar(alvo, CFG.TOMBO_PUXAO) end
			end
		end },
		SOLTA = { faz = function()
			local centro = onde or frente(CFG.ALCANCE)
			vfx("POCO", { posicao = centro, escala = 0.6, raio = 10,
				duracao = 1.2 })
			tocarEm("DISPARO", centro, 0.7)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tfecharPoco()\n",
)


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    d = dict(d)
    d["extra_require"] = ("local CutsceneRemote = Tool:WaitForChild(\"CutsceneRemote\")\n"
                          if d["cutscene"] else "")
    corpo = (CUTSCENE if d["cutscene"] else "") + DESPACHANTE + d["corpo"]
    servidor = PREAMBULO.format(tool=tool, **d) + corpo + RODAPE.format(**d)

    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_FAKER, os.path.join(pasta, "VFXModule.lua"))
    if d["cutscene"]:
        shutil.copyfile(CAM_FAKER, os.path.join(pasta, "CutsceneCam.lua"))

    print("%-22s %5d linhas de Server%s"
          % (tool, servidor.count("\n") + 1,
             " · CutsceneCam" if d["cutscene"] else ""))
    return True


def main():
    for caminho in (ANIMATOR, VFX_FAKER, CAM_FAKER):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
