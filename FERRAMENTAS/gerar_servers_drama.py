#!/usr/bin/env python3
"""
gerar_servers_drama.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule`, o `R6CFrameAnimator` e — nas
duas que têm cena — a `CutsceneCam` das 7 Tools do conjunto DRAMA.

    python3 FERRAMENTAS/gerar_servers_drama.py

O QUE SAIU DO `drama.rbxmx`

    O `Fists` tem 2078 linhas e **um único `TakeDamage`** no modelo inteiro,
    contra 9 escritas diretas em `Health` e 4 `BreakJoints`. `Health = Health -
    x` ignora `ForceField`, e `BreakJoints` desmonta personagem sem volta.

    Mais: 39 `math.random`, **31 `tick()`**, 18 `:Destroy()`, 9 `wait()`,
    3 `delay()`, 3 `workspace:GetDescendants()`, 2 `ScreenGui`, 2
    `LoadAnimation` com 5 `Animation`.

    Os 31 `tick()` são o número que salta: `tick()` alimentando geometria foi o
    que picotou a animação das bombas neste repositório.

    Do `dodge` (por Rufus14, o mesmo de `A arma`) saíram dois
    `workspace.DescendantAdded`/`DescendantRemoving` globais que mantinham uma
    tabela de TODO `Humanoid` do jogo, ligados para sempre. É pior que
    `GetDescendants()`, porque aquele ao menos termina. O Núcleo resolve com
    `detectarHumanoides`, que é consulta espacial sob demanda.

    O que veio do `dodge`, e é dele: `dhtime = 0.65` — a duração da esquiva.

O BEAT VEM COMO KEYFRAME

    `onBeat(kf, indice)`, e a marca está em `kf.marca`. Comparar o keyframe com
    string nunca dá verdadeiro e falha em SILÊNCIO: a animação roda inteira e o
    dano não acontece. Custou os 14 Tools dos conjuntos GUEST e GRAVIDADE, e
    `TESTES/verificar_rbxmx.py` passou a cobrar isso por nome.

A CUTSCENE MANDA UM `FireClient` POR ESPECTADOR

    `GRAMATICA_CUTSCENE.md` regra 2: enquadramento POR ESPECTADOR. O servidor
    sabe quem invocou e quem é o alvo; manda o papel de cada um no payload, e o
    cliente só desenha o que lhe cabe. Servidor não toca em `Camera`, nunca.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_DRAMA = os.path.join(DADOS, "VFXModule_Drama.lua")
CAM_DRAMA = os.path.join(DADOS, "CutsceneCam_Drama.lua")


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto DRAMA)
--
-- Sai das 3 Tools do `drama.rbxmx`. Handle e som vêm da origem; a habilidade é
-- escrita aqui. Ver `FERRAMENTAS/preparar_drama.py` para o mapa dos Handles.
--
--   M1   {rotulo_primaria}
--   {tecla}    {rotulo_extra}   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- Gerado por FERRAMENTAS/gerar_servers_drama.py. Editar aqui à mão faz as sete
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

--- Jitter determinístico em [-1,1]. No lugar dos 39 `math.random` da origem:
--- mesma variedade, e os dois clientes veem a mesma coisa.
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
-- O `Fists` de origem tinha NOVE `Health = Health - x` e UM `TakeDamage`.
-- `Health` direto ignora `ForceField`; `TakeDamage` não.
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

--- Alvos num raio. O `Fists` varria `workspace:GetDescendants()` e o `dodge`
--- mantinha uma tabela viva de TODO Humanoid do jogo por
--- `workspace.DescendantAdded`. Aqui é consulta espacial sob demanda, e quem
--- filtra time é o Núcleo.
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

--- O alvo mais perto de um ponto. É quem a cutscene enquadra.
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

--- Tombo com prazo. O `Fists` usava `BreakJoints`, que desmonta sem volta.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
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
--   quem invoca  ->  vê o golpe de fora, com o alvo no quadro
--   quem é alvo  ->  vê a SI MESMO sendo alcançado
--
-- Uma cena que mostra a mesma coisa para o algoz e para a vítima desperdiça
-- metade dela. O servidor sabe quem é quem, e é aqui que ele diz.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

--- Quem assiste: SÓ o portador e o alvo, cada um com o papel dele.
---
--- Não é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
--- câmera por causa de uma briga alheia — e uma cutscene que toma a câmera de
--- quem não está envolvido é a definição de tempo morto.
local function abrirCena(alvoHum, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true
	local corpoAlvo = alvoHum and alvoHum.Parent
	local nomeAlvo = corpoAlvo and corpoAlvo.Name or nil

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, alvoNome = nomeAlvo,
	})

	-- a outra metade da regra 2: o alvo recebe a cena DELE
	local jogadorAlvo = corpoAlvo and Players:GetPlayerFromCharacter(corpoAlvo)
	if jogadorAlvo and jogadorAlvo ~= jogador then
		CutsceneRemote:FireClient(jogadorAlvo, "INICIO", {
			papel = "ALVO", nome = nomeBeat,
			portador = personagem.Name, alvoNome = nomeAlvo,
		})
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


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (conjunto DRAMA)
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

local ACAO = "Drama_{sufixo}_{tecla}"
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


CONJUNTO["Combate"] = dict(
    objeto="Combate_Server_V1", sufixo="DramaCombate",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="combo de tres golpes que encadeiam",
    rotulo_extra="Chute Rodado",
    cfg="""	ALCANCE       = 6,
	RAIO_GOLPE    = 6.5,
	DANO_A        = 12,
	DANO_B        = 12,
	DANO_C        = 22,
	EMPURRAO      = 26,
	RECARGA       = 0.4,
	JANELA_COMBO  = 1.4,

	RECARGA_EXTRA = 8,
	DANO_CHUTE    = 32,
	RAIO_CHUTE    = 10,
	EMPURRAO_CHUTE = 78,
	TOMBO         = 1.5,""",
    estado="local passoCombo = 0\nlocal ultimoGolpe = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — combo de três
--
-- O passo avança só se o golpe anterior caiu dentro da janela. Passou do
-- prazo, volta ao primeiro: é o que faz combo ser combo e não uma fila de
-- socos independentes.
--
-- Os três alternam por CONTADOR, não por sorteio — a regra manda índice
-- sequencial no lugar de `math.random`.
--═══════════════════════════════════════════════════════════════

local function bater(dano, tipo, forca)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), forca or CFG.EMPURRAO, 0.18)
			vfx(tipo, { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end
	if achou then
		tocarEm("IMPACTO", ponto, 1 + jitter(0.4) * 0.1)
	end
	return achou
end

function primaria(_mira)
	ocupado = true

	if os.clock() - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo % 3 + 1
	ultimoGolpe = os.clock()

	local seq = ({ "SOCO_A", "SOCO_B", "SOCO_C" })[passoCombo]
	local dano = ({ CFG.DANO_A, CFG.DANO_B, CFG.DANO_C })[passoCombo]
	tocar("GOLPE", 1 + passoCombo * 0.06)

	rig:PlaySequence(seq, despachar({
		BATE = { faz = function()
			bater(dano, passoCombo == 3 and "GANCHO" or "SOCO",
				passoCombo == 3 and CFG.EMPURRAO * 2 or CFG.EMPURRAO)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — chute rodado
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	passoCombo = 0
	rig:PlaySequence("CHUTE", despachar({
		GIRA = { sfx = { "PREPARA", 0.9 } },
		CHUTA = { faz = function()
			local ponto = frente(CFG.ALCANCE * 0.8)
			vfx("CHUTE", { cframe = raiz.CFrame
				* CFrame.new(0, -0.4, -CFG.ALCANCE * 0.5), escala = 1.2 })
			tocarEm("IMPACTO", ponto, 0.8)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CHUTE, 8)) do
				aplicarDano(alvo, CFG.DANO_CHUTE)
				tombar(alvo, CFG.TOMBO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_CHUTE, 0.3)
					vfx("SOCO", { posicao = alvoRaiz.Position, escala = 1.3 })
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


CONJUNTO["Desviar e Empurrar"] = dict(
    objeto="DesviareEmpurrar_Server_V1", sufixo="DramaDesviar",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="empurrao em cone a frente",
    rotulo_extra="Esquiva",
    cfg="""	ALCANCE       = 7,
	RAIO_CONE     = 11,
	DANO          = 9,
	EMPURRAO      = 92,
	SUBIDA        = 16,
	RECARGA       = 4,

	RECARGA_EXTRA = 6,
	DISTANCIA_ESQ = 34,
	TEMPO_IMUNE   = 0.42,
	TEMPO_ESQ     = 0.28,""",
    estado="local impulsoEsq = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o empurrão
--
-- Não é golpe: é deslocamento. Dano baixo e empurrão alto, de propósito — a
-- Tool existe para tirar gente de cima de você, não para matar.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("EMPURRAO", despachar({
		CARGA = { sfx = { "PREPARA", 1.1 } },
		EMPURRA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			vfx("EMPURRAO", { cframe = raiz.CFrame, escala = 1.2 })
			tocarEm("GOLPE", ponto, 0.85)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CONE, 10)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),
						CFG.EMPURRAO, 0.3)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a esquiva
--
-- 0.62 s de sequência, e a janela de imunidade é MENOR que ela: 0.42 s. Se
-- fosse igual, esquivar seria sempre certo; assim ainda dá para errar o tempo.
--
-- A imunidade é `ForceField` com prazo no `Debris` — o mesmo objeto que o
-- Núcleo já respeita em `TakeDamage`. Não há bandeira nova para vazar.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("ESQUIVA", despachar({
		ENTRA = { sfx = { "PREPARA", 1.5 }, faz = function()
			vfx("ESQUIVA", { posicao = raiz.Position, cframe = raiz.CFrame,
				escala = 1 })
			if impulsoEsq then impulsoEsq.Parent = nil end
			impulsoEsq = Instance.new("BodyVelocity")
			impulsoEsq.MaxForce = Vector3.new(1e5, 0, 1e5)
			impulsoEsq.Velocity = -raiz.CFrame.LookVector * CFG.DISTANCIA_ESQ
			impulsoEsq.Parent = raiz
			Debris:AddItem(impulsoEsq, CFG.TEMPO_ESQ)
		end },
		IMUNE = { faz = function()
			local escudo = Instance.new("ForceField")
			escudo.Visible = false
			escudo.Parent = personagem
			Debris:AddItem(escudo, CFG.TEMPO_IMUNE)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="""	if impulsoEsq then
		impulsoEsq.Parent = nil
		impulsoEsq = nil
	end
""",
)


CONJUNTO["Corte Frio"] = dict(
    objeto="CorteFrio_Server_V1", sufixo="DramaCorteFrio",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=True,
    rotulo_primaria="corte de lamina",
    rotulo_extra="Execucao",
    cfg="""	ALCANCE       = 7,
	RAIO_CORTE    = 7.5,
	DANO          = 26,
	EMPURRAO      = 24,
	RECARGA       = 0.9,

	RECARGA_EXTRA = 20,
	RAIO_ALVO     = 12,
	DANO_EXECUCAO = 85,
	DURACAO_GELO  = 2.6,
	LENTIDAO      = 0.35,
	TEMPO_LENTO   = 3,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o corte
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CORTE", despachar({
		ERGUE = { sfx = { "PREPARA", 1 } },
		CORTA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			tocar("GOLPE", 1 + jitter(0.7) * 0.08)
			vfx("CORTE", { cframe = raiz.CFrame
				* CFrame.new(0, 0.4, -CFG.ALCANCE * 0.55), escala = 1.1 })
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CORTE, 5)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, raiz.CFrame.LookVector, CFG.EMPURRAO, 0.16)
					vfx("CORTE", { posicao = alvoRaiz.Position, escala = 0.7 })
				end
				tocarEm("IMPACTO", alvoRaiz and alvoRaiz.Position or ponto, 1.2)
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a execução, COM CUTSCENE
--
-- Um alvo, o mais perto. Sem alvo não há cena: abrir cutscene para o vazio é o
-- jeito mais rápido de tirar a câmera de alguém sem motivo.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO) or maisPerto(frente(), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.6)
		return
	end

	ocupado = true
	local id = novoId("GELO")
	rig:LockCharacter(true)
	abrirCena(alvo, "CAMERA")

	rig:PlaySequence("EXECUCAO", despachar({
		CAMERA = { sfx = { "CARGA", 0.85 } },
		ENCARA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				vfx("EXECUCAO", { posicao = alvoRaiz.Position, escala = 1,
					duracao = CFG.DURACAO_GELO, id = id })
			end
		end },
		AVANCA = { cam = true, sfx = { "PREPARA", 0.7 } },
		SEGURA = { cam = true, faz = function()
			-- o gelo segura: quem está sendo executado não sai andando
			if alvo.Health > 0 then
				alvo.WalkSpeed = alvo.WalkSpeed * CFG.LENTIDAO
				local antes = alvo.WalkSpeed / CFG.LENTIDAO
				task.delay(CFG.TEMPO_LENTO, function()
					if alvo and alvo.Parent then alvo.WalkSpeed = antes end
				end)
			end
		end },
		CORTA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvo)
			local onde = alvoRaiz and alvoRaiz.Position or frente()
			vfx("PARAR", { id = id })
			vfx("ESTILHACO", { posicao = onde, escala = 1.4 })
			tocarEm("IMPACTO", onde, 0.7)
			aplicarDano(alvo, CFG.DANO_EXECUCAO)
			tombar(alvo, 2)
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
''',
    ao_equipar="", ao_guardar="\tfecharCena()\n",
)


CONJUNTO["Impacto Forte"] = dict(
    objeto="ImpactoForte_Server_V1", sufixo="DramaImpacto",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="soco pesado que arremessa",
    rotulo_extra="Rachar o Chao",
    cfg="""	ALCANCE       = 6.5,
	RAIO_GOLPE    = 7,
	DANO          = 40,
	EMPURRAO      = 96,
	SUBIDA        = 34,
	TOMBO         = 1.8,
	RECARGA       = 2.2,

	RECARGA_EXTRA = 13,
	RAIO_RACHA    = 20,
	DANO_RACHA    = 52,
	EMPURRAO_RACHA = 70,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o soco pesado
--
-- Um golpe, caro e lento. 1.20 s com quadro segurado no meio (regra 7): o que
-- vende peso não é o dano, é o tempo parado antes dele.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("SOCO", despachar({
		CARGA = { sfx = { "CARGA", 1.1 } },
		SEGURA = { sfx = { "PREPARA", 0.8 } },
		BATE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			tocarEm("IMPACTO", ponto, 0.75)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, raiz.CFrame.LookVector * CFG.EMPURRAO
						+ Vector3.new(0, CFG.SUBIDA, 0), 1, 0.34)
					vfx("SOCO", { posicao = alvoRaiz.Position, escala = 1.6 })
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — rachar o chão
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("RACHA", despachar({
		ERGUE = { sfx = { "CARGA", 0.75 } },
		SEGURA = { sfx = { "PREPARA", 0.6 } },
		RACHA = { faz = function()
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("RACHA", { posicao = chao, escala = 1.5 })
			tocarEm("IMPACTO", chao, 0.55)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_RACHA, 12)) do
				aplicarDano(alvo, CFG.DANO_RACHA)
				tombar(alvo, 2)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - chao)
						+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO_RACHA, 0.32)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["Aura"] = dict(
    objeto="Aura_Server_V1", sufixo="DramaAura",
    arquetipo="SUPORTE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False,
    rotulo_primaria="liga a aura: mais velocidade enquanto ela dura",
    rotulo_extra="Pulso",
    cfg="""	ALCANCE       = 6,
	DURACAO       = 12,
	VELOCIDADE    = 26,
	PULSOS        = 4,
	INTERVALO     = 2.4,
	RAIO_AURA     = 13,
	DANO_AURA     = 7,
	RECARGA       = 16,

	RECARGA_EXTRA = 9,
	RAIO_PULSO    = 18,
	DANO_PULSO    = 34,
	EMPURRAO_PULSO = 74,""",
    estado="""local auraLigada = false
local idAura = nil
local velocidadeBase = nil""",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — ligar a aura
--
-- É o único estado PERSISTENTE do conjunto, e por isso é o único que precisa
-- de saída garantida. O `WalkSpeed` de origem é guardado, e `desmontar()` — nas
-- duas portas — devolve.
--
-- A aura fere sozinha, em pulsos espaçados. Quem encadeia é `task.delay` com
-- guarda de estado, e não um laço: se a aura for desligada no meio, o pulso
-- seguinte simplesmente não acontece.
--═══════════════════════════════════════════════════════════════

local function desligarAura()
	if not auraLigada then return end
	auraLigada = false
	if idAura then
		vfx("PARAR", { id = idAura })
		idAura = nil
	end
	if humanoide and humanoide.Parent and velocidadeBase then
		humanoide.WalkSpeed = velocidadeBase
		velocidadeBase = nil
	end
end

local function pulsarAura(restantes)
	if not (auraLigada and personagem and raiz) then return end
	if restantes <= 0 then
		desligarAura()
		return
	end
	vfx("AURA_PULSO", { posicao = raiz.Position, escala = 0.8 })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_AURA, 10)) do
		aplicarDano(alvo, CFG.DANO_AURA)
	end
	task.delay(CFG.INTERVALO, function()
		pulsarAura(restantes - 1)
	end)
end

function primaria(_mira)
	if auraLigada then
		desligarAura()
		tocar("PREPARA", 0.7)
		return
	end

	ocupado = true
	rig:PlaySequence("LIGAR", despachar({
		LIGA = { faz = function()
			auraLigada = true
			idAura = novoId("AURA")
			tocar("CARGA", 1)
			vfx("AURA", { posicao = raiz.Position, escala = 1.2,
				duracao = CFG.DURACAO, id = idAura })
			if velocidadeBase == nil then velocidadeBase = humanoide.WalkSpeed end
			humanoide.WalkSpeed = CFG.VELOCIDADE
			task.delay(CFG.INTERVALO, function()
				pulsarAura(CFG.PULSOS)
			end)
		end },
		SUSTENTA = { sfx = { "CARGA", 0.8 } },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o pulso
--
-- Com a aura ligada ele cobra mais caro, e desliga a aura: é o gasto do
-- estado, não um segundo golpe grátis.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	local reforcado = auraLigada
	rig:PlaySequence("PULSO", despachar({
		RECOLHE = { sfx = { "PREPARA", 1.2 } },
		SOLTA = { faz = function()
			local onde = raiz.Position
			local escala = reforcado and 1.6 or 1
			local dano = reforcado and CFG.DANO_PULSO * 1.6 or CFG.DANO_PULSO
			local raio = reforcado and CFG.RAIO_PULSO * 1.3 or CFG.RAIO_PULSO
			vfx("AURA_PULSO", { posicao = onde, escala = escala })
			tocarEm("IMPACTO", onde, reforcado and 0.7 or 1)
			for _, alvo in ipairs(alvosEm(onde, raio, 12)) do
				aplicarDano(alvo, dano)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - onde)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_PULSO, 0.28)
				end
			end
			if reforcado then desligarAura() end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tdesligarAura()\n",
)


CONJUNTO["Olhos Laser"] = dict(
    objeto="OlhosLaser_Server_V1", sufixo="DramaOlhos",
    arquetipo="RANGED", tecla="R", botao="ButtonR1", alcance_mira=220,
    cutscene=False,
    rotulo_primaria="feixe pelos olhos",
    rotulo_extra="Varredura",
    cfg="""	ALCANCE       = 6,
	ALCANCE_FEIXE = 220,
	DANO          = 22,
	RAIO_IMPACTO  = 4,
	RECARGA       = 1.2,

	RECARGA_EXTRA = 12,
	LEQUE         = 7,
	ABERTURA      = 46,
	DANO_LEQUE    = 13,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- DE ONDE SAI O FEIXE
--
-- Da CABEÇA, e isso não é detalhe: um feixe de olhos que nasce no Handle sai
-- da mão, e a leitura inteira se perde. A pose desta Tool lidera pela `Head`
-- pelo mesmo motivo.
--═══════════════════════════════════════════════════════════════

local function olhos()
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if cabeca then
		return cabeca.CFrame * CFrame.new(0, 0.2, -0.6)
	end
	return raiz.CFrame * CFrame.new(0, 1.6, -0.6)
end

local function tracar(origem, direcao, alcance)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }
	filtro.IgnoreWater = true
	return workspace:Raycast(origem, direcao * alcance, filtro)
end

local function disparar(origem, direcao, dano, escala)
	local acerto = tracar(origem, direcao, CFG.ALCANCE_FEIXE)
	local ponto = acerto and acerto.Position
		or (origem + direcao * CFG.ALCANCE_FEIXE)
	vfx("FEIXE", { origem = origem, destino = ponto, escala = escala or 1 })
	if not acerto then return end
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_IMPACTO, 4)) do
		aplicarDano(alvo, dano)
	end
end

--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o feixe
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("FEIXE", despachar({
		MIRA = { sfx = { "CARGA", 1.4 } },
		ATIRA = { faz = function()
			local cf = olhos()
			local direcao = (mira - cf.Position)
			if direcao.Magnitude < 0.01 then direcao = cf.LookVector end
			tocarEm("GOLPE", cf.Position, 1.5)
			disparar(cf.Position, direcao.Unit, CFG.DANO, 1)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a varredura
--
-- Sete feixes num leque, abertos por ÍNDICE — não por sorteio. O leque é
-- simétrico em volta da mira: o do meio vai onde o jogador apontou.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	rig:PlaySequence("VARREDURA", despachar({
		MIRA = { sfx = { "CARGA", 1.1 } },
		ABRE = { sfx = { "GOLPE", 1.2 } },
		VARRE = { faz = function()
			local cf = olhos()
			local base = (mira - cf.Position)
			if base.Magnitude < 0.01 then base = cf.LookVector end
			base = base.Unit
			local meio = (CFG.LEQUE + 1) / 2
			for i = 1, CFG.LEQUE do
				local passoAng = math.rad(CFG.ABERTURA) / CFG.LEQUE
				local desvio = (i - meio) * passoAng
				local direcao = (CFrame.Angles(0, desvio, 0) * base)
				disparar(cf.Position, direcao.Unit, CFG.DANO_LEQUE, 0.7)
			end
		end },
		FECHA = { faz = function()
			tocarEm("IMPACTO", olhos().Position, 1.3)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["TryHard"] = dict(
    objeto="TryHard_Server_V1", sufixo="DramaTryHard",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=True,
    rotulo_primaria="combo de quatro golpes que encadeiam",
    rotulo_extra="Finalizador",
    cfg="""	ALCANCE       = 6.5,
	RAIO_GOLPE    = 7,
	DANO_1        = 11,
	DANO_2        = 13,
	DANO_3        = 16,
	DANO_4        = 30,
	EMPURRAO      = 24,
	EMPURRAO_4    = 88,
	RECARGA       = 0.32,
	JANELA_COMBO  = 1,

	RECARGA_EXTRA = 45,
	RAIO_ALVO     = 14,
	DANO_FINAL    = 130,
	RAIO_FINAL    = 16,
	DANO_AREA     = 45,
	EMPURRAO_FINAL = 105,""",
    estado="local passoCombo = 0\nlocal ultimoGolpe = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — combo de QUATRO
--
-- A janela é curta (1 s) e o quarto golpe é o que paga: 11, 13, 16, 30. Quem
-- acerta a cadência inteira tira 70; quem só martela o botão tira 11 por vez,
-- porque o passo volta ao começo toda vez que a janela vence.
--
-- A regra 3 da gramática mede combo em 35 : 65 — o primeiro impacto cai cedo
-- porque o resto do tempo são os golpes seguintes. É por isso que `COMBO_1` tem
-- carga e os outros três entram direto no impacto.
--═══════════════════════════════════════════════════════════════

local ORDEM_COMBO = { "COMBO_1", "COMBO_2", "COMBO_3", "COMBO_4" }
local DANO_COMBO = { }

local function bater(dano, tipo, forca)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
		aplicarDano(alvo, dano)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), forca, 0.18)
			vfx(tipo, { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end
	if achou then tocarEm("IMPACTO", ponto, 1 + jitter(0.9) * 0.12) end
end

function primaria(_mira)
	ocupado = true

	if os.clock() - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo % 4 + 1
	ultimoGolpe = os.clock()

	DANO_COMBO = { CFG.DANO_1, CFG.DANO_2, CFG.DANO_3, CFG.DANO_4 }
	local dano = DANO_COMBO[passoCombo]
	local quarto = passoCombo == 4
	tocar("GOLPE", 1 + passoCombo * 0.07)

	rig:PlaySequence(ORDEM_COMBO[passoCombo], despachar({
		BATE = { faz = function()
			bater(dano, passoCombo == 3 and "GANCHO" or "SOCO", CFG.EMPURRAO)
		end },
		BATE_FORTE = { faz = function()
			bater(dano, "CHUTE", CFG.EMPURRAO_4)
			vfx("CHUTE", { cframe = raiz.CFrame
				* CFrame.new(0, -0.4, -CFG.ALCANCE * 0.5), escala = 1.3 })
		end },
		FIM = { faz = function()
			passoCombo = 0
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o finalizador, COM CUTSCENE
--
-- ULTIMATE: 7.60 s com 76% de preparação, dentro da faixa da regra 5. É a
-- sequência mais longa do repositório depois do `Colapso` do Terremoto, e a
-- única com combo antes dela.
--
-- Sem alvo não há cena. Abrir cutscene para o vazio é o jeito mais rápido de
-- tirar a câmera de alguém sem motivo.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO) or maisPerto(frente(), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.55)
		return
	end

	ocupado = true
	passoCombo = 0
	rig:LockCharacter(true)
	abrirCena(alvo, "CAMERA")

	rig:PlaySequence("FINALIZADOR", despachar({
		CAMERA = { sfx = { "CARGA", 0.7 } },
		ERGUE = { faz = function()
			beatCena("ENCARA")
			tocar("PREPARA", 0.65)
		end },
		CARGA = { faz = function()
			beatCena("ENCARA")
			tocar("CARGA", 0.9)
		end },
		AVANCA = { cam = true, sfx = { "GOLPE", 0.8 } },
		SEGURA = { cam = true },
		EXECUTA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvo)
			local onde = alvoRaiz and alvoRaiz.Position or frente()
			vfx("ESTILHACO", { posicao = onde, escala = 1.8 })
			vfx("RACHA", { posicao = onde - Vector3.new(0, 2.6, 0), escala = 1.6 })
			tocarEm("IMPACTO", onde, 0.5)
			aplicarDano(alvo, CFG.DANO_FINAL)
			tombar(alvo, 3)
			-- quem estava perto paga o respingo, mas bem menos: o golpe é DELE
			for _, perto in ipairs(alvosEm(onde, CFG.RAIO_FINAL, 12)) do
				if perto ~= alvo then
					aplicarDano(perto, CFG.DANO_AREA)
					local pertoRaiz = raizDe(perto)
					if pertoRaiz then
						empurrar(perto, (pertoRaiz.Position - onde)
							+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_FINAL, 0.34)
					end
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
''',
    ao_equipar="", ao_guardar="\tpassoCombo = 0\n\tfecharCena()\n",
)


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    d = dict(d)
    d["extra_require"] = ("local CutsceneRemote = Tool:WaitForChild(\"CutsceneRemote\")\n"
                          if d["cutscene"] else "")
    corpo = (CUTSCENE if d["cutscene"] else "") + d["corpo"]
    servidor = PREAMBULO.format(tool=tool, **d) + corpo + RODAPE.format(**d)

    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_DRAMA, os.path.join(pasta, "VFXModule.lua"))
    if d["cutscene"]:
        shutil.copyfile(CAM_DRAMA, os.path.join(pasta, "CutsceneCam.lua"))

    print("%-20s %5d linhas de Server%s"
          % (tool, servidor.count("\n") + 1,
             " · CutsceneCam" if d["cutscene"] else ""))
    return True


def main():
    for caminho in (ANIMATOR, VFX_DRAMA, CAM_DRAMA):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
