#!/usr/bin/env python3
"""
gerar_servers_gravidade.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule` e o `R6CFrameAnimator` das 7
Tools do conjunto GRAVIDADE.

    python3 FERRAMENTAS/gerar_servers_gravidade.py

A REGRA QUE MANDA NESTE CONJUNTO: NINGUÉM TOCA EM `workspace.Gravity`

    O `Gravitron 1000` do modelo de origem ciclava `workspace.Gravity` entre
    21.2, 471.2 e 196.2 — e o `Unequipped` dele parava dois sons, apagava um
    rótulo, e NÃO devolvia a gravidade. Não havia `Tool.Destroying`. Equipar,
    clicar uma vez e guardar deixava o servidor inteiro em gravidade 21.2, para
    sempre.

    Gravidade é propriedade GLOBAL. A Regra nº 1 vale nos dois sentidos: a Tool
    não lê de fora, e não sequestra o que é de fora. Aqui todo efeito de
    gravidade é POR ALVO — `BodyVelocity` e `BodyPosition` com prazo no
    `Debris`, num `HumanoidRootPart` por vez. O visual é o mesmo; o estrago
    quando algo dá errado é zero.

    `TESTES/verificar_autocontencao.sh` passou a cobrar isso por nome.

O QUE MAIS SAIU DOS ORIGINAIS

    `IsTeamMate` dentro do `GravityHammer`  regra de combate só no Núcleo
    5 `ScreenGui` (Gravitron, Quake)        proibida — efeito só no mundo 3D
    UI clonada no PlayerGui de todos        depósito fora da Tool. E o clone era
                                            UM só, reparentado num laço: só o
                                            último jogador da lista recebia
    6 `Animation` + 4 `LoadAnimation`       pose CFrame sob R6CFrameAnimator
    `BreakJoints`                           destruição permanente não é dano
    35 `wait` · 18 `math.random` · 9 `:Destroy` · 5 `spawn`

    A favor da origem: as cinco já usavam `TakeDamage`. Isso ficou.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_GRAV = os.path.join(DADOS, "VFXModule_Gravidade.lua")


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto GRAVIDADE)
--
-- Sai das 5 Tools do `calebe_tools.rbxmx`: o **Handle é da origem**, a
-- habilidade é escrita aqui. Duas do conjunto clonam o Handle de uma irmã —
-- ver `FERRAMENTAS/preparar_gravidade.py`.
--
--   M1   {rotulo_primaria}
--   {tecla}    {rotulo_extra}   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- ⚠️ ESTA TOOL NÃO ESCREVE `workspace.Gravity`, E NENHUMA DAS SETE ESCREVE.
--    Gravidade é propriedade global do servidor; o original a trocava e não
--    devolvia. Aqui o efeito é sempre por ALVO, com prazo no `Debris`.
--
-- Gerado por FERRAMENTAS/gerar_servers_gravidade.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))

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

--- Jitter determinístico em [-1,1]. No lugar dos 18 `math.random` da origem:
--- mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice — dispersão que não repete e não sorteia.
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

--- Versão presa ao Handle — só para som que acompanha a mão.
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
--- string nunca dá verdadeiro, e o efeito é silencioso: a animação roda inteira
--- e o dano, o VFX e o som do beat simplesmente não acontecem.
---
--- Foi o bug relatado como "o dano não está funcionando em npcs e jogadores".
local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL. A Tool sozinha num place vazio funciona
-- por inteiro — é o teste que decide a Regra nº 1.
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	local marca = alvoHum:FindFirstChild("creator")
	if marca then marca.Parent = nil end
	marca = Instance.new("ObjectValue")
	marca.Name = "creator"
	marca.Value = jogador
	marca.Parent = alvoHum
	Debris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local final = bruto
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--- Alvos num raio. O filtro de time é do Núcleo — o `IsTeamMate` que o
--- `GravityHammer` original tinha dentro de si não veio junto.
local function alvosEm(posicao, raio, limite)

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

--═══════════════════════════════════════════════════════════════
-- GRAVIDADE POR ALVO
--
-- ISTO É O CORAÇÃO DO CONJUNTO, E O MOTIVO DE ELE EXISTIR ASSIM.
--
-- O modelo de origem trocava `workspace.Gravity`. Aqui cada alvo ganha o SEU
-- corpo de força, com prazo no `Debris` — e o `Debris` limpa mesmo se o script
-- morrer no meio. Não há estado global para vazar.
--═══════════════════════════════════════════════════════════════

--- Empurra um alvo numa direção, por um prazo.
local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Suspende um alvo no ar. É a "gravidade invertida" sem tocar em nada global:
--- um `BodyPosition` mira acima da posição atual e o `Debris` desfaz.
local function suspender(alvoHum, altura, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 12000
	prender.D = 900
	prender.Position = alvoRaiz.Position + Vector3.new(0, altura, 0)
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
end

--- Puxa um alvo PARA um ponto.
local function atrair(alvoHum, ponto, tempo, rigidez)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return nil end
	local prender = Instance.new("BodyPosition")
	prender.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	prender.P = rigidez or 9000
	prender.D = 1100
	prender.Position = ponto
	prender.Parent = alvoRaiz
	Debris:AddItem(prender, tempo)
	return prender
end

--- Tombo com prazo, sem ragdoll de fora.
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


RODAPE = '''
--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--
-- Recarga por TIMESTAMP: sobrevive a desequipar/equipar, e por isso não dá
-- para zerar a recarga guardando e sacando a Tool.
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
--- de uma sequência — e foi assim que o `Gravitron 1000` original deixava a
--- gravidade do servidor trocada para sempre.
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
-- Script com RunContext = Client — {tool}  (conjunto GRAVIDADE)
--
-- POR QUE NÃO É LocalScript
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
--   mundo — mas o único ouvinte que existe é o de quem está segurando.
--
--   `Script` com `RunContext = Client` roda em TODO cliente, onde quer que
--   esteja na árvore, inclusive dentro da Tool de outro jogador. Nada saiu de
--   dentro da Tool, então a Regra nº 1 continua de pé.
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
--   O modelo de origem resolvia isso com **cinco `ScreenGui`** dentro das
--   Tools, e o `Gravitron 1000` ainda clonava a dele para o `PlayerGui` de
--   todo mundo. `ScreenGui` dentro de Tool é proibida, e `PlayerGui` alheio é
--   depósito fora da Tool. `ContextActionService` é serviço de comportamento:
--   não traz asset de fora e some sozinho no `Unbind`.
--
-- Gerado por FERRAMENTAS/gerar_servers_gravidade.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO = "Gravidade_{sufixo}_{tecla}"
local ALCANCE_MIRA = {alcance_mira}

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
	VFX.Executar(tipo, dados or {{}})
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
		AcaoRemote:FireServer("{tecla}", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.{tecla}, Enum.KeyCode.{botao})

	ContextActionService:SetTitle(ACAO, "{rotulo_extra}")
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
'''


# ═══════════════════════════════════════════════════════════════
# AS 7 TOOLS
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {}


CONJUNTO["Tremores da Gravidade"] = dict(
    objeto="TremoresdaGravidade_Server_V1", sufixo="GravTremores",
    arquetipo="GRAVIDADE", tecla="R", botao="ButtonR1", alcance_mira=60,
    rotulo_primaria="onda de tremor que corre pelo chão",
    rotulo_extra="Sustentar",
    cfg="""	ALCANCE       = 8,
	RAIO_ONDA     = 22,
	DANO          = 18,
	EMPURRAO      = 42,
	SUBIDA        = 14,
	RECARGA       = 4,

	RECARGA_EXTRA = 14,
	PULSOS        = 3,
	RAIO_PULSO    = 16,
	DANO_PULSO    = 11,
	TOMBO         = 1.4,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a onda
--
-- O `Quake Hammer` original varria `workspace:GetDescendants()` para achar
-- alvo. Aqui é consulta espacial num raio, e quem filtra time é o Núcleo.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	tocar("Swing", 1 + jitter(0.4) * 0.08)
	rig:PlaySequence("TREMOR", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "BATE" then return end
		local chao = raiz.Position - Vector3.new(0, 2.6, 0)
		vfx("ONDA", { posicao = chao, escala = 1.2 })
		tocarEm("Hit", chao, 0.9 + jitter(1.1) * 0.08)

		for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_ONDA, 12)) do
			aplicarDano(alvo, CFG.DANO)
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - chao)
					+ Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),
					CFG.EMPURRAO, 0.24)
			end
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o tremor sustentado
--
-- Três pulsos, um por beat do animator. Quem encadeia é o animator, não
-- `task.wait(passo.duracao)` — é a regra que existe porque o oposto já
-- dessincronizou animação e dano neste repositório.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("SUSTENTO", despachar({
		ABRE = { faz = function()
			tocar("Press", 0.8)
		end },
		PULSO = { faz = function()
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("PULSO", { posicao = chao, escala = 1 })
			tocarEm("Hit", chao, 1.15 + jitter(0.6) * 0.1)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_PULSO, 12)) do
				aplicarDano(alvo, CFG.DANO_PULSO)
				tombar(alvo, CFG.TOMBO)
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="",
)


CONJUNTO["Controlador da Gravidade"] = dict(
    objeto="ControladordaGravidade_Server_V1", sufixo="GravControlador",
    arquetipo="GRAVIDADE", tecla="R", botao="ButtonR1", alcance_mira=90,
    rotulo_primaria="campo de gravidade invertida no ponto mirado",
    rotulo_extra="Esmagar",
    cfg="""	ALCANCE       = 8,
	RAIO_CAMPO    = 16,
	ALTURA_CAMPO  = 22,
	DURACAO_CAMPO = 3.5,
	DANO_CAMPO    = 8,
	RECARGA       = 9,

	RECARGA_EXTRA = 13,
	RAIO_ESMAGA   = 18,
	DANO_ESMAGA   = 38,
	FORCA_ESMAGA  = 140,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — gravidade invertida no ponto
--
-- ⚠️ O ORIGINAL FAZIA `game.Workspace.Gravity = 21.2` E NÃO DEVOLVIA.
--
-- Aqui ninguém toca em `workspace.Gravity`. Cada alvo dentro do campo ganha um
-- `BodyPosition` próprio mirando acima de si, com prazo no `Debris` — e o
-- `Debris` limpa mesmo se este script morrer no meio. Não existe estado global
-- para vazar.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("INVERTE", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "SOLTA" then return end
		local id = novoId("CAMPO")
		tocarEm("Shift", mira, 1.1)
		vfx("CAMPO_INVERSO", { posicao = mira, escala = 1.2,
			raio = CFG.RAIO_CAMPO, duracao = CFG.DURACAO_CAMPO, id = id })

		for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_CAMPO, 12)) do
			aplicarDano(alvo, CFG.DANO_CAMPO)
			suspender(alvo, CFG.ALTURA_CAMPO, CFG.DURACAO_CAMPO, 9000)
		end

		task.delay(CFG.DURACAO_CAMPO, function()
			vfx("PARAR", { id = id })
		end)
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — esmagar
--
-- O oposto visual e mecânico da primária: mesma bolha, força para baixo. É o
-- que faz as duas lerem como a mesma Tool.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	rig:PlaySequence("ESMAGAR", despachar({
		ERGUE = { faz = function()
			tocar("Shift", 0.7)
		end },
		ESMAGA = { faz = function()
			vfx("ESMAGA", { posicao = mira, escala = 1.3 })
			tocarEm("Beep", mira, 0.72)
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_ESMAGA, 12)) do
				aplicarDano(alvo, CFG.DANO_ESMAGA)
				empurrar(alvo, Vector3.new(0, -1, 0), CFG.FORCA_ESMAGA, 0.3)
				tombar(alvo, 1.6)
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="",
)


CONJUNTO["Telecinese Levitacao"] = dict(
    objeto="TelecineseLevitacao_Server_V1", sufixo="GravLevitacao",
    arquetipo="TELECINESE", tecla="R", botao="ButtonR1", alcance_mira=80,
    rotulo_primaria="ergue o alvo mirado e o deixa indefeso",
    rotulo_extra="Levitar",
    cfg="""	ALCANCE       = 8,
	RAIO_ALVO     = 9,
	ALTURA        = 16,
	DURACAO       = 3,
	DANO          = 14,
	DANO_QUEDA    = 22,
	RECARGA       = 8,

	RECARGA_EXTRA = 10,
	ALTURA_PROPRIA = 26,
	DURACAO_PROPRIA = 4,""",
    estado="local presoProprio = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — erguer o alvo
--
-- Uma vítima por vez, a mais perto do ponto mirado. Levitar a sala inteira é o
-- que a Extra do `Controlador` faz; esta é cirúrgica, e por isso pesa mais.
--═══════════════════════════════════════════════════════════════

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

function primaria(mira)
	ocupado = true
	rig:PlaySequence("ERGUER", despachar({
		ALCANCA = { faz = function()
			tocar("ScifiLiftSound", 1)
			vfx("AGARRA", { origem = Handle.Position, destino = mira })
		end },
		ERGUE = { faz = function()
			local alvo = maisPerto(mira, CFG.RAIO_ALVO)
			if not alvo then return end
			local alvoRaiz = raizDe(alvo)
			if not alvoRaiz then return end
			local id = novoId("LEVITA")
			aplicarDano(alvo, CFG.DANO)
			suspender(alvo, CFG.ALTURA, CFG.DURACAO, 14000)
			tombar(alvo, CFG.DURACAO + 0.6)
			vfx("LEVITA", { posicao = alvoRaiz.Position + Vector3.new(0, CFG.ALTURA, 0),
				escala = 1, duracao = CFG.DURACAO, id = id })
			-- a queda cobra o resto: quem foi erguido volta com o chão
			task.delay(CFG.DURACAO, function()
				vfx("PARAR", { id = id })
				if alvo and alvo.Parent and alvo.Health > 0 then
					aplicarDano(alvo, CFG.DANO_QUEDA)
					local ondeCaiu = raizDe(alvo)
					if ondeCaiu then
						vfx("ONDA", { posicao = ondeCaiu.Position
							- Vector3.new(0, 2.6, 0), escala = 0.8 })
					end
				end
			end)
		end },
		SOLTA = { faz = function()
			tocar("ScifiBlastSound", 1.1)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — levitar a si mesmo
--
-- O `BodyPosition` do próprio portador é o único estado desta Tool que
-- sobreviveria a um desequipar no meio. Por isso ele fica guardado e
-- `desmontar()` o desfaz — nas duas portas.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("SUBIR", despachar({
		SOBE = { faz = function()
			tocar("ScifiLiftSound", 1.25)
			if presoProprio then presoProprio.Parent = nil end
			presoProprio = Instance.new("BodyPosition")
			presoProprio.MaxForce = Vector3.new(0, 1e5, 0)
			presoProprio.P = 9000
			presoProprio.D = 1400
			presoProprio.Position = raiz.Position
				+ Vector3.new(0, CFG.ALTURA_PROPRIA, 0)
			presoProprio.Parent = raiz
			Debris:AddItem(presoProprio, CFG.DURACAO_PROPRIA)
			vfx("FLUTUA", { posicao = raiz.Position, escala = 1 })
		end },
		DESCE = { faz = function()
			tocar("Bam", 0.9)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="""	if presoProprio then
		presoProprio.Parent = nil
		presoProprio = nil
	end
""",
)


CONJUNTO["Lancador de Objetos"] = dict(
    objeto="LancadordeObjetos_Server_V1", sufixo="GravLancador",
    arquetipo="TELECINESE", tecla="R", botao="ButtonR1", alcance_mira=140,
    rotulo_primaria="agarra um destroço e arremessa",
    rotulo_extra="Rajada",
    cfg="""	ALCANCE       = 8,
	DANO          = 26,
	RAIO_IMPACTO  = 7,
	VELOCIDADE    = 190,
	VIDA_DESTROCO = 5,
	TAMANHO       = 2.6,
	RECARGA       = 3,

	RECARGA_EXTRA = 11,
	QUANTOS       = 5,
	DANO_RAJADA   = 15,
	ESPALHAMENTO  = 7,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- O DESTROÇO
--
-- Peça NOVA, criada pela Tool, e não uma peça do mapa arrancada. O `detainer`
-- original agarrava geometria do mundo — que é ler o mundo, e pior, deixa
-- buraco permanente no cenário quando a peça não volta.
--
-- Peça NÃO ancorada, movida por física: peça ancorada movida por script de
-- servidor replica a ~20 Hz picotado; física replica com interpolação.
--═══════════════════════════════════════════════════════════════

local function novoDestroco(posicao, tamanho)
	local peca = Instance.new("Part")
	peca.Name = "Destroco"
	peca.Size = Vector3.new(tamanho, tamanho * 0.85, tamanho)
	peca.Color = Color3.fromRGB(138, 128, 116)
	peca.Material = Enum.Material.Slate
	peca.CanCollide = true
	peca.CFrame = CFrame.new(posicao)
		* CFrame.Angles(jitter(0.3) * 3, jitter(1.7) * 3, jitter(2.4) * 3)
	peca.Parent = workspace
	pcall(function() peca:SetNetworkOwner(nil) end)
	Debris:AddItem(peca, CFG.VIDA_DESTROCO)

	local halo = Instance.new("SelectionBox")
	halo.Adornee = peca
	halo.Color3 = Color3.fromRGB(168, 118, 255)
	halo.LineThickness = 0.04
	halo.Transparency = 0.35
	halo.Parent = peca
	return peca
end

local function lancar(peca, destino, dano)
	local origem = peca.Position
	local direcao = destino - origem
	if direcao.Magnitude < 0.01 then direcao = raiz.CFrame.LookVector end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = direcao.Unit * CFG.VELOCIDADE
	impulso.Parent = peca
	Debris:AddItem(impulso, 0.6)

	local bateu = false
	guardar(peca.Touched:Connect(function(atingido)
		if bateu then return end
		local corpo = atingido and atingido.Parent
		if not corpo or corpo == personagem then return end
		local hum = corpo:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.Health > 0) then return end
		bateu = true
		local onde = peca.Position
		vfx("DESTROCO", { posicao = onde, escala = 1 })
		tocarEm("Launch1", onde, 1.3)
		for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_IMPACTO, 6)) do
			aplicarDano(alvo, dano)
			empurrar(alvo, direcao, 45, 0.2)
		end
		peca.Transparency = 1
		peca.CanCollide = false
		peca.CanTouch = false
		Debris:AddItem(peca, 0.15)
	end))
end

--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — agarra e arremessa
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("ARREMESSO", despachar({
		AGARRA = { faz = function()
			tocar("ClawsClose", 1)
			vfx("AGARRA", { origem = Handle.Position,
				destino = frente(CFG.ALCANCE) })
		end },
		SOLTA = { faz = function()
			tocar("Launch2", 1)
			local origem = Handle.Position + raiz.CFrame.LookVector * 2.5
				+ Vector3.new(0, 1.5, 0)
			lancar(novoDestroco(origem, CFG.TAMANHO), mira, CFG.DANO)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a rajada
--
-- Cinco destroços em ângulo áureo em volta do portador, e todos partem para a
-- mira. Dispersão por índice sequencial, nunca `math.random`.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	rig:PlaySequence("RAJADA", despachar({
		REUNE = { faz = function()
			tocar("Pull", 0.85)
			vfx("CACOS", { posicao = raiz.Position + Vector3.new(0, 3, 0),
				escala = 1.2, quantos = CFG.QUANTOS, duracao = 0.9 })
		end },
		SEGURA = { faz = function()
			tocar("Holding", 1)
		end },
		SALVA = { faz = function()
			for i = 1, CFG.QUANTOS do
				local a = angulo(i)
				local origem = raiz.Position + Vector3.new(0, 3, 0)
					+ Vector3.new(math.cos(a) * CFG.ESPALHAMENTO, 0,
						math.sin(a) * CFG.ESPALHAMENTO)
				lancar(novoDestroco(origem, CFG.TAMANHO * 0.75),
					mira, CFG.DANO_RAJADA)
			end
			tocarEm("Launch3", raiz.Position, 1)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="\ttocar(\"equip\", 1)\n",
    ao_guardar="\ttocar(\"unequip\", 1)\n",
)


CONJUNTO["Asas Telecineticas"] = dict(
    objeto="AsasTelecineticas_Server_V1", sufixo="GravAsas",
    arquetipo="TELECINESE", tecla="R", botao="ButtonR1", alcance_mira=60,
    rotulo_primaria="bate as asas: sobe e empurra quem estiver perto",
    rotulo_extra="Mergulho",
    cfg="""	ALCANCE       = 8,
	IMPULSO_CIMA  = 78,
	IMPULSO_FRENTE = 46,
	RAIO_SOPRO    = 14,
	DANO_SOPRO    = 12,
	EMPURRAO      = 62,
	RECARGA       = 5,

	RECARGA_EXTRA = 12,
	ALTURA_SUBIDA = 34,
	FORCA_MERGULHO = 190,
	RAIO_MERGULHO = 17,
	DANO_MERGULHO = 42,""",
    estado="local impulsoAtivo = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a batida de asa
--
-- Sobe o portador e empurra quem está perto. O impulso do PRÓPRIO portador é
-- guardado: se a Tool sumir no meio, `desmontar()` o tira — corpo de força
-- pendurado num personagem é estado que vaza.
--═══════════════════════════════════════════════════════════════

local function impulsionar(direcao, forca, tempo)
	if impulsoAtivo then impulsoAtivo.Parent = nil end
	impulsoAtivo = Instance.new("BodyVelocity")
	impulsoAtivo.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulsoAtivo.Velocity = direcao.Unit * forca
	impulsoAtivo.Parent = raiz
	Debris:AddItem(impulsoAtivo, tempo)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BATIDA", despachar({
		ABRE = { faz = function()
			tocar("ScifiLiftSound", 1.2)
		end },
		BATE = { faz = function()
			tocar("ScifiBlastSound", 1.05)
			impulsionar(Vector3.new(0, CFG.IMPULSO_CIMA, 0)
				+ raiz.CFrame.LookVector * CFG.IMPULSO_FRENTE, 1, 0.3)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1.2 })
			for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SOPRO, 10)) do
				aplicarDano(alvo, CFG.DANO_SOPRO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.22)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o mergulho
--
-- Sobe, segura, e desce com peso. É a sequência com mais quadro segurado do
-- conjunto depois do ultimate — a regra 7 vale para o alto também: o instante
-- parado no ar é o que vende a queda.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("MERGULHO", despachar({
		ERGUE = { faz = function()
			tocar("ScifiLiftSound", 0.85)
			impulsionar(Vector3.new(0, CFG.ALTURA_SUBIDA, 0), 1, 0.45)
			vfx("ASA", { cframe = raiz.CFrame, escala = 1 })
		end },
		DESCE = { faz = function()
			tocar("ScifiBlastSound", 0.75)
			impulsionar(Vector3.new(0, -1, 0), CFG.FORCA_MERGULHO, 0.35)
		end },
		IMPACTO = { faz = function()
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("MERGULHO", { posicao = chao, escala = 1.4 })
			tocarEm("Bam", chao, 0.8)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_MERGULHO, 12)) do
				aplicarDano(alvo, CFG.DANO_MERGULHO)
				tombar(alvo, 1.6)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - chao)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO * 1.4, 0.28)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="""	if impulsoAtivo then
		impulsoAtivo.Parent = nil
		impulsoAtivo = nil
	end
""",
)


CONJUNTO["Terremoto"] = dict(
    objeto="Terremoto_Server_V1", sufixo="GravTerremoto",
    arquetipo="GRAVIDADE", tecla="R", botao="ButtonR1", alcance_mira=70,
    rotulo_primaria="rachadura que corre à frente",
    rotulo_extra="Colapso",
    cfg="""	ALCANCE       = 8,
	PASSOS        = 6,
	AVANCO        = 5,
	RAIO_PASSO    = 7,
	DANO          = 20,
	SUBIDA        = 34,
	RECARGA       = 7,

	RECARGA_EXTRA = 42,
	RAIO_COLAPSO  = 44,
	DANO_COLAPSO  = 78,
	EMPURRAO_COLAPSO = 110,
	CARGA         = 4.4,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a rachadura
--
-- Ela CORRE: seis paradas à frente, uma a cada beat de tempo, cada uma com o
-- seu raio. Bater tudo de uma vez no mesmo instante seria uma explosão, não um
-- terremoto — e a diferença entre os dois é justamente a propagação.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("RACHADURA", function(passo)
		local marca = marcaDe(passo)
		if marca == "ERGUE" then
			tocar("Swing", 0.85)
		elseif marca ~= "BATE" then
			return
		else
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			local direcao = raiz.CFrame.LookVector
			tocarEm("Hit", chao, 0.8)
			vfx("RACHADURA", { posicao = chao, direcao = direcao,
				escala = 1.2, passos = CFG.PASSOS })

			for i = 1, CFG.PASSOS do
				local onde = chao + direcao * (i * CFG.AVANCO)
				task.delay((i - 1) * 0.05, function()
					if not personagem then return end
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_PASSO, 6)) do
						aplicarDano(alvo, CFG.DANO)
						empurrar(alvo, Vector3.new(0, 1, 0), CFG.SUBIDA, 0.24)
					end
				end)
			end
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o colapso
--
-- ULTIMATE. 7.20 s, 71% de preparação — dentro da faixa da regra 5, que mede
-- ultimate em 7–9 s. É a única sequência do conjunto com beat de câmera, e é a
-- própria regra que exige: ultimate longo sem enquadramento vira tempo morto.
--
-- O beat "CAMERA" viaja pelo VFXRemote como qualquer outro. Quem enquadra é o
-- cliente — servidor não toca em `Camera`, nunca.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:LockCharacter(true)
	local id = novoId("COLAPSO")

	rig:PlaySequence("COLAPSO", despachar({
		CAMERA = { faz = function()
			tocar("Swing", 0.55)
			vfx("COLAPSO_CARGA", { posicao = raiz.Position, escala = 1.4,
				raio = CFG.RAIO_COLAPSO, duracao = CFG.CARGA, id = id })
		end },
		CARGA = { faz = function()
			tocarEm("Press", raiz.Position, 0.7)
		end },
		AUGE = { faz = function()
			tocarEm("Press", raiz.Position, 1.4)
		end },
		COLAPSO = { faz = function()
			local chao = raiz.Position - Vector3.new(0, 2.6, 0)
			vfx("PARAR", { id = id })
			vfx("COLAPSO", { posicao = chao, escala = 1.8 })
			tocarEm("Hit", chao, 0.55)
			for _, alvo in ipairs(alvosEm(chao, CFG.RAIO_COLAPSO, 20)) do
				aplicarDano(alvo, CFG.DANO_COLAPSO)
				tombar(alvo, 2.6)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - chao)
						+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO_COLAPSO, 0.4)
				end
			end
		end },
	}), function()
		rig:LockCharacter(false)
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="",
)


CONJUNTO["Telecinese Gravitacional"] = dict(
    objeto="TelecineseGravitacional_Server_V1", sufixo="GravGravitacional",
    arquetipo="TELECINESE", tecla="R", botao="ButtonR1", alcance_mira=110,
    rotulo_primaria="puxa todos para o ponto mirado",
    rotulo_extra="Singularidade",
    cfg="""	ALCANCE       = 8,
	RAIO_PUXAO    = 30,
	DANO_PUXAO    = 16,
	TEMPO_PUXAO   = 0.8,
	RECARGA       = 12,

	RECARGA_EXTRA = 26,
	RAIO_SING     = 26,
	DANO_SING     = 30,
	DANO_ESTOURO  = 55,
	TEMPO_SING    = 1.1,
	EMPURRAO_SING = 95,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o puxão
--
-- Todo mundo no raio vem PARA o ponto. É o inverso de toda explosão do
-- repositório, e é a leitura que define telecinese: as coisas vão para onde a
-- física não mandaria.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	rig:PlaySequence("PUXAO", despachar({
		ALCANCA = { faz = function()
			tocar("SendOut", 1.1)
			vfx("AGARRA", { origem = Handle.Position, destino = mira })
		end },
		PUXA = { faz = function()
			tocarEm("InitialHit", mira, 0.9)
			vfx("PUXAO", { posicao = mira, escala = 1.3, raio = CFG.RAIO_PUXAO })
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_PUXAO, 14)) do
				aplicarDano(alvo, CFG.DANO_PUXAO)
				atrair(alvo, mira, CFG.TEMPO_PUXAO, 11000)
			end
		end },
		SEGURA = { faz = function()
			tocar("Whack", 0.8)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a singularidade
--
-- Junta, segura, e estoura. O dano vem em dois tempos, e o segundo é maior:
-- quem ficou preso paga mais caro que quem escapou da atração.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	local id = novoId("SING")

	rig:PlaySequence("SINGULARIDADE", despachar({
		ABRE = { faz = function()
			tocar("SendOut", 0.8)
		end },
		REUNE = { faz = function()
			tocarEm("InitialHit", mira, 0.75)
			vfx("SINGULARIDADE", { posicao = mira, escala = 1.4,
				duracao = CFG.TEMPO_SING, id = id })
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING, 16)) do
				aplicarDano(alvo, CFG.DANO_SING)
				atrair(alvo, mira, CFG.TEMPO_SING, 14000)
			end
		end },
		SEGURA = { faz = function()
			tocarEm("Whack", mira, 0.6)
		end },
		COLAPSA = { faz = function()
			vfx("PARAR", { id = id })
			vfx("COLAPSO", { posicao = mira, escala = 1.2 })
			tocarEm("Hit", mira, 0.7)
			-- quem ficou preso paga o dobro do que pagou na atração
			for _, alvo in ipairs(alvosEm(mira, CFG.RAIO_SING * 0.6, 16)) do
				aplicarDano(alvo, CFG.DANO_ESTOURO)
				tombar(alvo, 2)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - mira)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SING, 0.32)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="",
)


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    servidor = (PREAMBULO.format(tool=tool, **d) + d["corpo"] + RODAPE.format(**d))
    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_GRAV, os.path.join(pasta, "VFXModule.lua"))

    print("%-26s %5d linhas de Server · Client · animator · VFXModule"
          % (tool, servidor.count("\n") + 1))
    return True


def main():
    for caminho in (ANIMATOR, VFX_GRAV):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
