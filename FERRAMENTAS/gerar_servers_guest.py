#!/usr/bin/env python3
"""
gerar_servers_guest.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule` e o `R6CFrameAnimator` das 7
Tools do conjunto GUEST.

    python3 FERRAMENTAS/gerar_servers_guest.py

O QUE SAIU DOS ORIGINAIS, E POR QUÊ

    `require(ReplicatedFirst.Ragdoll)` (Diamond)
        Regra nº 1. E pior: `ReplicatedFirst.Ragdoll` não existe num place
        vazio, então a Tool erra na primeira ativação. O tombo agora é
        `PlatformStand` com prazo, dentro da Tool.

    `WaitForChild("AbilityActivateButton")` (Diamond)
        A GUI que essa linha espera NÃO EXISTE no modelo. `WaitForChild` sem
        timeout trava para sempre: o CLIENT do Diamond nunca passava da linha
        10, e a Tool inteira era inerte. O botão agora é
        `ContextActionService`, que desenha o toque sozinho.

    `Touched` decidindo acerto no CLIENTE (Diamond)
        Quem decide dano é o servidor. Sempre.

    `isAlly()` dentro da Tool (Taco)
        Invariante: regra de combate tem uma porta só, o `NucleoCombate`.

    `Health = Health - math.random(10,15)` (Cano)
        `TakeDamage`, que respeita `ForceField`.

    `ScreenGui` (A arma) · `Animation`/`LoadAnimation` (Diamond)
        Proibidos dentro de Tool.

    `workspace:GetDescendants()` (Taco) · `BreakJoints` (Taco)
        Varrer o mundo é dependência; quebrar junta é destruição permanente.

    `wait` · `spawn` · `delay` · `tick` · `:Destroy()` · `math.random`
        47 · 11 · 1 · 12 · 2 · 41 ocorrências, todas trocadas.

O BUG DAS PERNAS — o motivo de o animator soldar, e não o Server

    O `Taco` original soldava `RightLegWeldbat` e `LeftLegWeldbat` e zerava
    `WalkSpeed` no finalizador. O `Unequipped` dele soltava braço, cabeça e
    raiz — e NÃO as pernas, nem devolvia o `WalkSpeed`. Não havia
    `Tool.Destroying`. Desequipar durante o golpe deixava o personagem soldado
    e parado, sem volta.

    Aqui ninguém solda perna à mão: quem solda é o `R6CFrameAnimator`, sob
    demanda, e é ele quem chama `ReleaseLegs` ao fim de toda sequência. O
    `desmontar()` do Server está ligado em `Unequipped` **e** `Destroying`, que
    são as duas portas.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

# o animator canônico: o das 31 Tools novas, não o das 7 antigas dos escudos
ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_GUEST = os.path.join(DADOS, "VFXModule_Guest.lua")


# ═══════════════════════════════════════════════════════════════
# PREÂMBULO COMUM
# ═══════════════════════════════════════════════════════════════

PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto GUEST)
--
-- REMASTER. `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`: existe `.rbxmx` de origem
-- que mandaram converter, então a ESTRUTURA É LEI — Handle, mesh, Sound, Weld
-- e hierarquia saem da origem intactos. O que muda é a habilidade.
--
--   M1   {rotulo_primaria}
--   {tecla}    {rotulo_extra}   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- Gerado por FERRAMENTAS/gerar_servers_guest.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")

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

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extra
{estado}

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar dos 41 `math.random` que os
--- originais usavam para variar pitch e ângulo: mesma variedade, e os dois
--- clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Toca um som numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça
--- que some no quadro seguinte mata o som no quadro em que ele nasce — foi o
--- que emudeceu a explosão das seis bombas.
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

--- Versão presa ao Handle — só para som que acompanha a mão e não a peça.
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
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro — é o
-- teste que decide a Regra nº 1.
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

--- Cura. Passa pelo Núcleo como qualquer efeito de vida.
---
--- ATENÇÃO: `_G.Combate.curar` **não existe** no `NucleoCombate.lua` de hoje.
--- Quem roda é o fallback. A guarda está aqui porque a regra manda toda
--- chamada ao Núcleo ser opcional, e para que o dia em que o Núcleo ganhar uma
--- `curar` as sete passem a usá-la sem tocar em nada.
local function curar(alvoHum, quanto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	if _G.Combate and _G.Combate.curar then
		return _G.Combate.curar(jogador, alvoHum, quanto) or 0
	end
	local antes = alvoHum.Health
	alvoHum.Health = math.min(alvoHum.Health + quanto, alvoHum.MaxHealth)
	return alvoHum.Health - antes
end

--- Alvos num raio. O `Taco` original varria `workspace:GetDescendants()` a
--- cada golpe; aqui é consulta espacial, e o filtro de time é do Núcleo.
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

--- O ponto à frente do portador. É onde o golpe corpo a corpo procura alvo.
local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or CFG.ALCANCE)
end

local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Tombo com prazo. Substitui o `require(ReplicatedFirst.Ragdoll)` do Diamond,
--- que era dependência de fora e não existe em place vazio.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com prazo, e com volta garantida mesmo se a Tool sumir no meio.
local velocidadeGuardada = {{}}

local function afrouxar(alvoHum, fator, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if velocidadeGuardada[alvoHum] == nil then
		velocidadeGuardada[alvoHum] = alvoHum.WalkSpeed
	end
	alvoHum.WalkSpeed = velocidadeGuardada[alvoHum] * fator
	task.delay(tempo, function()
		local antes = velocidadeGuardada[alvoHum]
		if antes and alvoHum and alvoHum.Parent then
			alvoHum.WalkSpeed = antes
		end
		velocidadeGuardada[alvoHum] = nil
	end)
end

local function devolverVelocidades()
	for alvoHum, antes in pairs(velocidadeGuardada) do
		if alvoHum and alvoHum.Parent then alvoHum.WalkSpeed = antes end
	end
	table.clear(velocidadeGuardada)
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
--- de uma sequência, e foi assim que o `Taco` original deixava perna soldada.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	devolverVelocidades()
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
-- Script com RunContext = Client — {tool}  (conjunto GUEST)
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

local ACAO = "Guest_{sufixo}_{tecla}"
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


CONJUNTO["Taco de Baseball"] = dict(
    objeto="TacodeBaseball_Server_V1", sufixo="GuestTaco",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    rotulo_primaria="dois golpes de taco que revezam",
    rotulo_extra="Rebater",
    cfg="""	ALCANCE       = 6.5,
	RAIO_GOLPE    = 7,
	DANO_A        = 16,
	DANO_B        = 22,
	EMPURRAO      = 34,
	RECARGA       = 0.55,

	RECARGA_EXTRA = 10,
	JANELA_REBATE = 0.9,
	RAIO_REBATE   = 12,
	FORCA_REBATE  = 2.4,
	MINIMO_REBATE = 8,
	DANO_REBATE   = 26,
	DANO_EXTRA    = 55,
	RAIO_EXTRA    = 11,
	EMPURRAO_EXTRA = 95,
	TOMBO         = 2.2,""",
    estado="local golpeB = false",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — combo de dois golpes
--
-- Os dois revezam por um booleano, não por sorteio: `Hit`/`Hit2` e
-- `Ouch`/`Ouch2` vêm em par no modelo, e alternar por índice é o que a regra
-- manda usar no lugar de `math.random`.
--═══════════════════════════════════════════════════════════════

local function bater(dano, metal)
	local ponto = frente(CFG.ALCANCE)
	vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 0.4, -CFG.ALCANCE * 0.6),
		escala = 1, cor = Color3.fromRGB(255, 228, 176) })

	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.35, 0), CFG.EMPURRAO, 0.18)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end

	if achou then
		tocarEm(metal and "Hit2" or "Hit", ponto, 1 + jitter(0.3) * 0.08)
		tocarEm(metal and "Ouch2" or "Ouch", ponto, 1 + jitter(1.4) * 0.08)
	end
end

function primaria(_mira)
	ocupado = true
	local segundo = golpeB
	golpeB = not golpeB
	tocar("Swoosh", 1 + jitter(0.7) * 0.1)
	rig:PlaySequence(segundo and "GOLPE_B" or "GOLPE_A", function(passo)
		local marca = marcaDe(passo)
		if marca == "BATE" then
			bater(segundo and CFG.DANO_B or CFG.DANO_A, segundo)
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — Rebater
--
-- O taco ergue e FICA DE PRONTIDÃO. Durante a janela, tudo que estiver voando
-- perto volta na direção em que o portador olha — projétil de outra Tool, caco
-- de escudo, bomba, o que for.
--
-- A janela é o quadro SEGURADO da sequência, não o instante do golpe: rebater
-- é reação, e reação precisa de tempo em que a guarda está de pé. São 0.9 s.
--
-- O QUE CONTA COMO OBJETO REBATÍVEL
--
--   `BasePart` solta (não ancorada) com velocidade acima de 8 studs/s. Peça
--   parada não é ameaça, e peça ancorada é cenário — devolver o mapa na cara
--   de alguém não é rebater, é quebrar o jogo.
--
--   O personagem do portador fica de fora do teste, senão o taco rebateria as
--   próprias pernas a cada passo.
--
-- A velocidade volta MULTIPLICADA por 2.4, e quem for atingido pelo objeto
-- rebatido leva dano creditado a quem rebateu — não a quem atirou.
--═══════════════════════════════════════════════════════════════

local function rebaterPerto(direcao)
	local centro = raiz.Position
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }

	local rebatidos = 0
	for _, peca in ipairs(workspace:GetPartBoundsInRadius(centro,
			CFG.RAIO_REBATE, filtro)) do
		if peca:IsA("BasePart") and not peca.Anchored then
			local v = peca.AssemblyLinearVelocity
			if v.Magnitude >= CFG.MINIMO_REBATE then
				-- volta na direção em que o portador olha, com a energia dele
				-- somada: rebater não é só espelhar, é devolver com juros
				peca.AssemblyLinearVelocity =
					direcao.Unit * (v.Magnitude * CFG.FORCA_REBATE)
				vfx("IMPACTO_METAL", { posicao = peca.Position, escala = 1 })
				tocarEm("Hit2", peca.Position, 1 + jitter(0.5) * 0.1)

				-- o crédito passa a ser de quem rebateu
				local dono = peca:FindFirstChild("creator")
				if dono then dono.Parent = nil end
				local marca = Instance.new("ObjectValue")
				marca.Name = "creator"
				marca.Value = jogador
				marca.Parent = peca
				Debris:AddItem(marca, 4)

				rebatidos = rebatidos + 1
			end
		end
	end
	return rebatidos
end

function extra(_mira)
	ocupado = true
	rig:PlaySequence("REBATER", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("Equip", 1.1)
			vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 1, -2),
				escala = 1.1 })
		elseif marca == "SEGURA" then
			-- a janela: varre uma vez por quadro segurado, não por frame
			local direcao = raiz.CFrame.LookVector
			if rebaterPerto(direcao) > 0 then
				tocar("Swoosh", 0.9)
			end
		elseif marca == "GOLPE" then
			local ponto = frente(CFG.ALCANCE)
			tocarEm("Hit", ponto, 0.9)
			vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 1, -2.4),
				escala = 1.3 })
			rebaterPerto(raiz.CFrame.LookVector)

			-- e quem estiver ao alcance leva o taco, rebatendo ou não
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_EXTRA, 6)) do
				aplicarDano(alvo, CFG.DANO_REBATE)
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_EXTRA, 0.26)
					vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.2 })
				end
			end
		end
	end, function()
		ocupado = false
	end)
end

''',
    ao_equipar="\ttocar(\"Equip\", 1)\n",
    ao_guardar="",
)


CONJUNTO["Cano De Rua"] = dict(
    objeto="CanoDeRua_Server_V1", sufixo="GuestCano",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    rotulo_primaria="golpe de cano; o segundo vem mais forte",
    rotulo_extra="Cegar",
    cfg="""	ALCANCE       = 6,
	RAIO_GOLPE    = 6.5,
	DANO_A        = 13,
	DANO_B        = 19,
	EMPURRAO      = 28,
	RECARGA       = 0.5,

	RECARGA_EXTRA = 13,
	DURACAO_CEGO  = 4,
	DANO_EXTRA    = 34,
	RAIO_EXTRA    = 13,
	EMPURRAO_EXTRA = 55,
	LENTIDAO      = 0.45,
	TEMPO_LENTO   = 3.5,""",
    estado="local golpeB = false\nlocal cegos = 0\nlocal cegueiras = {}",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — dois golpes, e o segundo cobra mais caro
--
-- O original media 0.317 s por golpe, com proporção 42 : 58 — o que CONFIRMA a
-- regra 3 da gramática (combo bate cedo) e CONTRARIA a regra 1 (0.8–1.2 s).
-- Ver `ACERVO_RETROVERSE/Guest_Tools/R6_CFRAME/NOTAS.md`. A pose deste
-- conjunto fica em 0.50 s: mais lenta que o original porque ele não tinha um
-- único quadro segurado, e mais rápida que a tabela porque a 0.8 s uma briga
-- de rua vira coreografia.
--═══════════════════════════════════════════════════════════════

local function bater(dano, segundo)
	local ponto = frente(CFG.ALCANCE)
	vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 0.3, -CFG.ALCANCE * 0.6),
		escala = 0.9, cor = Color3.fromRGB(214, 226, 240) })

	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO, 0.16)
			vfx("IMPACTO_METAL", { posicao = alvoRaiz.Position, escala = 1 })
		end
		achou = true
	end

	if achou then
		tocarEm(segundo and "MetalHit2" or "MetalHit", ponto, 1 + jitter(0.5) * 0.09)
		tocarEm("Hit", ponto, 1 + jitter(1.9) * 0.07)
	end
end

function primaria(_mira)
	ocupado = true
	local segundo = golpeB
	golpeB = not golpeB
	tocar(segundo and "Swoosh2" or "Swoosh", 1 + jitter(0.9) * 0.1)
	rig:PlaySequence(segundo and "GOLPE_B" or "GOLPE_A", function(passo)
		local marca = marcaDe(passo)
		if marca == "BATE" then
			bater(segundo and CFG.DANO_B or CFG.DANO_A, segundo)
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — Cegar
--
-- É a habilidade do ORIGINAL levada até o fim. O `LeadpipeServer` já virava a
-- cabeça de quem apanhava para encarar o agressor
--
--     headdd.CFrame = CFrame.new(headdd.Position, owner.Head.Position)
--
-- e pendurava um `BoolValue` chamado `owieConcussed` — mas a "concussão" dele
-- não fazia nada além de desenhar uma `ScreenGui` na cara da vítima. GUI dentro
-- de Tool é proibida, e além de proibida é ruim: só quem levou via.
--
-- Aqui cegar é GEOMETRIA NO MUNDO 3D. Uma nuvem escura fica soldada à frente
-- da cabeça: tapa a vista de quem levou porque está fisicamente no caminho, e
-- a sala inteira vê quem está cego. Mais o que a origem já fazia — a cabeça
-- virada — e o que ela não tinha coragem de fazer: `AutoRotate = false`, que é
-- o que realmente atrapalha mirar.
--
-- Tudo com prazo, e tudo devolvido em `desmontar()`.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CEGAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("Swoosh2", 0.72)
		elseif marca == "GOLPE" then
			local ponto = frente(CFG.ALCANCE)
			tocarEm("MetalHit", ponto, 0.8)

			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_EXTRA, 6)) do
				aplicarDano(alvo, CFG.DANO_EXTRA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_CEGO)

				local corpo = alvo.Parent
				local cabeca = corpo and corpo:FindFirstChild("Head")
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if cabeca then
					local id = "CEGO_" .. tostring(cegos + 1)
					cegos = cegos + 1
					vfx("CEGUEIRA", { alvo = corpo, id = id, escala = 1,
						duracao = CFG.DURACAO_CEGO })
					table.insert(cegueiras, id)
					task.delay(CFG.DURACAO_CEGO, function()
						vfx("PARAR", { id = id })
					end)
				end

				-- a cabeça virada: é o gesto do original, e ele fica
				if cabeca and personagem and personagem:FindFirstChild("Head") then
					cabeca.CFrame = CFrame.new(cabeca.Position,
						personagem.Head.Position)
				end

				-- e o que a origem não fazia: tirar a mira
				alvo.AutoRotate = false
				task.delay(CFG.DURACAO_CEGO, function()
					if alvo and alvo.Parent and alvo.Health > 0 then
						alvo.AutoRotate = true
					end
				end)

				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO_EXTRA, 0.22)
					vfx("IMPACTO_METAL", { posicao = alvoRaiz.Position, escala = 1.2 })
				end
			end
		elseif marca == "SEGURA" then
			tocar("Swoosh", 0.66)
		end
	end, function()
		ocupado = false
	end)
end

''',
    ao_equipar="",
    ao_guardar="\ttocar(\"unequip\", 1)\n\tfor _, id in ipairs(cegueiras) do vfx(\"PARAR\", { id = id }) end\n\ttable.clear(cegueiras)\n",
)


CONJUNTO["Abacate (roubado) do mexico"] = dict(
    objeto="Abacateroubadodomexico_Server_V1", sufixo="GuestAbacate",
    arquetipo="SUPORTE", tecla="R", botao="ButtonR1", alcance_mira=60,
    rotulo_primaria="come e recupera vida",
    rotulo_extra="Caroco",
    cfg="""	ALCANCE       = 6,
	CURA          = 14,
	RECARGA       = 6,

	RECARGA_EXTRA = 5,
	DANO_EXTRA    = 12,
	RAIO_EXTRA    = 5,
	ALCANCE_MAX   = 90,
	FORCA_MIN     = 55,
	ARCO_TIRO     = 14,
	VIDA_CAROCO   = 5,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — comer
--
-- A cura do original era `h.Health = math.min(h.Health + 3, h.MaxHealth)`,
-- direto. Aqui passa pelo Núcleo, com o mesmo teto de `MaxHealth` no fallback.
--
-- O gesto continua sendo o do original: `Grip*` do servidor, sem rig nenhum.
-- Só que agora ele acompanha uma sequência de pose, e o `Grip` volta ao lugar
-- no fim da sequência — inclusive se ela for cancelada.
--═══════════════════════════════════════════════════════════════

local GRIP_NORMAL = Tool.Grip
local GRIP_BOCA = CFrame.new(1.5, -0.5, 0.3)
	* CFrame.Angles(math.rad(-40), 0, math.rad(-18))

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("COMER", function(passo)
		local marca = marcaDe(passo)
		if marca == "LEVA" then
			Tool.Grip = GRIP_BOCA
			tocar("DrinkSound", 1)
		elseif marca == "MORDE" then
			vfx("RESPINGO", { posicao = Handle.Position, escala = 0.7 })
		elseif marca == "ENGOLE" then
			Tool.Grip = GRIP_NORMAL
		elseif marca == "CURA" then
			local ganho = curar(humanoide, CFG.CURA)
			if ganho > 0 then
				vfx("CURA", { posicao = raiz.Position, escala = 1 })
			end
		end
	end, function()
		Tool.Grip = GRIP_NORMAL
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o caroço
--
-- Peça NÃO ancorada, movida por física. Peça ancorada movida por script de
-- servidor replica a ~20 Hz picotado; física replica com interpolação.
--═══════════════════════════════════════════════════════════════

local function novoCaroco(posicao)
	local caroco = Instance.new("Part")
	caroco.Name = "Caroco"
	caroco.Shape = Enum.PartType.Ball
	caroco.Size = Vector3.new(0.9, 1.1, 0.9)
	caroco.Color = Color3.fromRGB(150, 106, 52)
	caroco.Material = Enum.Material.Sand
	caroco.CanCollide = true
	caroco.CFrame = CFrame.new(posicao)
	caroco.Parent = workspace
	pcall(function() caroco:SetNetworkOwner(nil) end)
	Debris:AddItem(caroco, CFG.VIDA_CAROCO)
	return caroco
end

function extra(mira)
	ocupado = true
	rig:PlaySequence("ARREMESSO", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "SOLTA" then return end
		tocar("OpenSound", 1.3)

		local origem = Handle.Position + raiz.CFrame.LookVector * 1.5
		local caroco = novoCaroco(origem)
		local dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
		local impulso = Instance.new("BodyVelocity")
		impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		impulso.Velocity = CFrame.new(origem, mira).LookVector
			* math.max(dist, CFG.FORCA_MIN) + Vector3.new(0, CFG.ARCO_TIRO, 0)
		impulso.Parent = caroco
		Debris:AddItem(impulso, 0.1)

		local bateu = false
		guardar(caroco.Touched:Connect(function(atingido)
			if bateu then return end
			local corpo = atingido and atingido.Parent
			if not corpo or corpo == personagem then return end
			local hum = corpo:FindFirstChildOfClass("Humanoid")
			if not (hum and hum.Health > 0) then return end
			bateu = true
			local onde = caroco.Position
			vfx("RESPINGO", { posicao = onde, escala = 1.1 })
			tocarEm("DrinkSound", onde, 1.5)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_EXTRA, 4)) do
				aplicarDano(alvo, CFG.DANO_EXTRA)
			end
			caroco.Transparency = 1
			caroco.CanCollide = false
			caroco.CanTouch = false
			Debris:AddItem(caroco, 0.15)
		end))
	end, function()
		ocupado = false
	end)
end
''',
    ao_equipar="\ttocar(\"OpenSound\", 1)\n",
    ao_guardar="\tTool.Grip = GRIP_NORMAL\n",
)


CONJUNTO["Energetico"] = dict(
    objeto="Energetico_Server_V1", sufixo="GuestEnergetico",
    arquetipo="SUPORTE", tecla="R", botao="ButtonR1", alcance_mira=60,
    rotulo_primaria="bebe: cura e acelera por um tempo",
    rotulo_extra="Lata",
    cfg="""	ALCANCE       = 6,
	CURA          = 10,
	VELOCIDADE    = 26,
	TEMPO_VELOZ   = 6,
	RECARGA       = 8,

	RECARGA_EXTRA = 6,
	DANO_EXTRA    = 15,
	RAIO_EXTRA    = 7,
	ALCANCE_MAX   = 90,
	FORCA_MIN     = 60,
	ARCO_TIRO     = 12,
	VIDA_LATA     = 5,""",
    estado="local velocidadeBase = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — beber
--
-- O original acelerava com `delay(5, ...)` e não devolvia nada se o jogador
-- desequipasse antes. Aqui o valor de origem é guardado, e `desmontar()`
-- devolve — nas duas portas.
--═══════════════════════════════════════════════════════════════

local GRIP_NORMAL = Tool.Grip
local GRIP_BOCA = CFrame.new(1.5, -0.5, 0.3)
	* CFrame.Angles(math.rad(-52), 0, math.rad(-14))

local function acelerar()
	if velocidadeBase == nil then velocidadeBase = humanoide.WalkSpeed end
	humanoide.WalkSpeed = CFG.VELOCIDADE
	task.delay(CFG.TEMPO_VELOZ, function()
		if humanoide and humanoide.Parent and velocidadeBase then
			humanoide.WalkSpeed = velocidadeBase
			velocidadeBase = nil
		end
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BEBER", function(passo)
		local marca = marcaDe(passo)
		if marca == "ERGUE" then
			Tool.Grip = GRIP_BOCA
			tocar("DrinkSound", 1)
		elseif marca == "ULTIMO_GOLE" then
			vfx("RESPINGO", { posicao = Handle.Position, escala = 0.6 })
		elseif marca == "CURA" then
			Tool.Grip = GRIP_NORMAL
			local ganho = curar(humanoide, CFG.CURA)
			if ganho > 0 then
				vfx("CURA", { posicao = raiz.Position, escala = 1.1 })
			end
			acelerar()
		end
	end, function()
		Tool.Grip = GRIP_NORMAL
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — amassa a lata e joga
--═══════════════════════════════════════════════════════════════

local function novaLata(posicao)
	local lata = Handle:Clone()
	lata.Name = "Lata"
	lata.Anchored = false
	lata.CanCollide = true
	lata.Massless = false
	lata.Size = Handle.Size * 0.8
	lata.CFrame = CFrame.new(posicao)
	for _, filho in ipairs(lata:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	lata.Parent = workspace
	pcall(function() lata:SetNetworkOwner(nil) end)
	Debris:AddItem(lata, CFG.VIDA_LATA)
	return lata
end

function extra(mira)
	ocupado = true
	rig:PlaySequence("LATA", function(passo)
		local marca = marcaDe(passo)
		if marca == "AMASSA" then
			tocar("OpenSound", 0.7)
		elseif marca == "JOGA" then
			local origem = Handle.Position + raiz.CFrame.LookVector * 1.5
			local lata = novaLata(origem)
			local dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
			local impulso = Instance.new("BodyVelocity")
			impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			impulso.Velocity = CFrame.new(origem, mira).LookVector
				* math.max(dist, CFG.FORCA_MIN) + Vector3.new(0, CFG.ARCO_TIRO, 0)
			impulso.Parent = lata
			Debris:AddItem(impulso, 0.1)

			local bateu = false
			guardar(lata.Touched:Connect(function(atingido)
				if bateu then return end
				local corpo = atingido and atingido.Parent
				if not corpo or corpo == personagem then return end
				local hum = corpo:FindFirstChildOfClass("Humanoid")
				if not (hum and hum.Health > 0) then return end
				bateu = true
				local onde = lata.Position
				vfx("RESPINGO", { posicao = onde, escala = 1.3,
					cor = Color3.fromRGB(255, 208, 96) })
				tocarEm("OpenSound", onde, 1.4)
				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_EXTRA, 4)) do
					aplicarDano(alvo, CFG.DANO_EXTRA)
				end
				lata.Transparency = 1
				lata.CanCollide = false
				lata.CanTouch = false
				Debris:AddItem(lata, 0.15)
			end))
		end
	end, function()
		ocupado = false
	end)
end
''',
    ao_equipar="\ttocar(\"OpenSound\", 1)\n",
    ao_guardar="""	Tool.Grip = GRIP_NORMAL
	if humanoide and humanoide.Parent and velocidadeBase then
		humanoide.WalkSpeed = velocidadeBase
		velocidadeBase = nil
	end
""",
)


CONJUNTO["Humilhador"] = dict(
    objeto="Humilhador_Server_V1", sufixo="GuestHumilhador",
    arquetipo="SUPORTE", tecla="R", botao="ButtonR1", alcance_mira=40,
    rotulo_primaria="provoca — som e efeito, zero dano",
    rotulo_extra="Roda",
    cfg="""	ALCANCE       = 6,
	RECARGA       = 4,

	RECARGA_EXTRA = 14,
	RAIO_EXTRA    = 22,
	LENTIDAO      = 0.6,
	TEMPO_LENTO   = 4,
	ALTURA_SPRITE = 3.2,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a provocação
--
-- Esta Tool NÃO causa dano, e é de propósito: é provocação. O que ela mexe é
-- na cabeça de quem está olhando.
--
-- O sprite do original vivia num `BillboardGui` com um `mainz` que rodava
-- `while true do wait(.05) ... end` sem saída, e se auto-destruía no fim.
-- `BillboardGui` NÃO é violação — a proibição é de `ScreenGui`, e a razão dela
-- é "efeito só no mundo 3D"; billboard vive no mundo 3D. O que era violação
-- era o laço sem fim e o `:Destroy()`. O beat agora vem do animator, e quem
-- desenha é o cliente.
--═══════════════════════════════════════════════════════════════

local function pontoDaCabeca()
	local cabeca = personagem and personagem:FindFirstChild("Head")
	if cabeca then return cabeca.Position + Vector3.new(0, 1.4, 0) end
	return raiz.Position + Vector3.new(0, CFG.ALTURA_SPRITE, 0)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("PROVOCA", function(passo)
		local marca = marcaDe(passo)
		if marca == "SPRITE" then
			tocarEm("Provoca", pontoDaCabeca(), 1)
			vfx("ZOMBARIA", { posicao = pontoDaCabeca(), escala = 1 })
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — a roda
--
-- Provocação em área. Continua sem dano: o que ela faz é AFROUXAR quem está
-- perto, e a lentidão é devolvida por prazo e por `desmontar()`.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	rig:PlaySequence("RODA", function(passo)
		local marca = marcaDe(passo)
		if marca == "GIRA" then
			tocarEm("Provoca", pontoDaCabeca(), 0.85)
		elseif marca == "PULSO" then
			local onde = raiz.Position
			vfx("ZOMBARIA_RODA", { posicao = onde, escala = 1.4 })
			tocarEm("Provoca", onde, 1.25)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_EXTRA, 12)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
				local corpo = alvo.Parent
				local cabeca = corpo and corpo:FindFirstChild("Head")
				if cabeca then
					vfx("ZOMBARIA", { posicao = cabeca.Position + Vector3.new(0, 1.4, 0),
						escala = 0.7 })
				end
			end
		end
	end, function()
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="",
)


CONJUNTO["Diamond"] = dict(
    objeto="Diamond_Server_V1", sufixo="GuestDiamond",
    arquetipo="MELEE", tecla="E", botao="ButtonY", alcance_mira=40,
    rotulo_primaria="tapa que arremessa",
    rotulo_extra="Pedra",
    cfg="""	ALCANCE       = 6.5,
	RAIO_GOLPE    = 7,
	DANO          = 18,
	EMPURRAO      = 78,
	SUBIDA        = 26,
	TOMBO         = 1.6,
	RECARGA       = 0.8,

	RECARGA_EXTRA = 16,
	DURACAO_PEDRA = 4.5,
	DANO_ABERTURA = 30,
	RAIO_ABERTURA = 13,
	EMPURRAO_ABERTURA = 60,""",
    estado="local idPedra = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o tapa
--
-- O original decidia o acerto num `Touched` do CLIENTE e mandava o alvo pelo
-- Remote. Quem decide dano é o servidor, sempre — o cliente só pede.
--
-- E o tombo não vem mais de `require(ReplicatedFirst.Ragdoll)`: aquilo era
-- dependência de fora, e num place vazio a Tool errava na primeira ativação.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	tocar("Smack", 1 + jitter(0.6) * 0.12)
	rig:PlaySequence("TAPA", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "BATE" then return end
		local ponto = frente(CFG.ALCANCE)
		vfx("ARCO", { cframe = raiz.CFrame * CFrame.new(0, 0.5, -CFG.ALCANCE * 0.6),
			escala = 1.1 })
		for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
			aplicarDano(alvo, CFG.DANO)
			tombar(alvo, CFG.TOMBO)
			local corpo = alvo.Parent
			local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				empurrar(alvo, raiz.CFrame.LookVector * CFG.EMPURRAO
					+ Vector3.new(0, CFG.SUBIDA, 0), 1, 0.35)
				vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.3 })
			end
			tocarEm("Smack", alvoRaiz and alvoRaiz.Position or ponto, 0.9)
		end
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — virar pedra
--
-- O original ancorava o `HumanoidRootPart` e punha uma música em loop dentro
-- de uma `Part` chamada "rock". Duas coisas mudaram:
--
--   `Anchored = true` no personagem vira `LockCharacter(true)`, que é a API do
--   animator e desfaz sozinha no `desmontar()`. Personagem ancorado por
--   script é o tipo de estado que sobra quando algo dá errado no meio.
--
--   A música em loop saiu. Loop dentro de Tool é o que fica tocando depois que
--   a Tool some — e ela somava com o `DistortionSoundEffect` no mesmo `Sound`.
--
-- A transformação segue a regra 4 da gramática: 2 : 98. Abre no primeiro
-- quadro e passa os outros 98% sustentando.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	idPedra = idPedra + 1
	local esteId = "PEDRA_" .. tostring(idPedra)

	rig:LockCharacter(true)
	rig:PlaySequence("PEDRA", function(passo)
		local marca = marcaDe(passo)
		if marca == "FECHA" then
			tocarEm("Smack", raiz.Position, 0.55)
			vfx("PEDRA", { posicao = raiz.Position, escala = 1,
				duracao = CFG.DURACAO_PEDRA, id = esteId })
		elseif marca == "ABRE" then
			local onde = raiz.Position
			vfx("PARAR", { id = esteId })
			vfx("PEDRA_FIM", { posicao = onde, escala = 1.2 })
			tocarEm("Smack", onde, 0.7)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ABERTURA, 10)) do
				aplicarDano(alvo, CFG.DANO_ABERTURA)
				local corpo = alvo.Parent
				local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - onde)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_ABERTURA, 0.3)
				end
			end
		end
	end, function()
		rig:LockCharacter(false)
		ocupado = false
	end)
end
''',
    ao_equipar="",
    ao_guardar="\tvfx(\"PARAR\", { id = \"PEDRA_\" .. tostring(idPedra) })\n",
)


CONJUNTO["A arma"] = dict(
    objeto="Aarma_Server_V1", sufixo="GuestArma",
    arquetipo="RANGED", tecla="R", botao="ButtonB", alcance_mira=300,
    rotulo_primaria="atira — seis tiros no tambor",
    rotulo_extra="Recarregar",
    cfg="""	ALCANCE       = 8,
	CAPACIDADE    = 6,
	DANO          = 24,
	DANO_CABECA   = 46,
	ALCANCE_TIRO  = 300,
	EMPURRAO      = 12,
	RECARGA       = 0.36,
	RECARGA_EXTRA = 1.6,
	ESPALHAMENTO  = 0.012,""",
    estado="local tambor = 6",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- A BOCA DO CANO
--
-- O modelo traz uma peça chamada `barrelend`, e é dela que o tiro sai. Sem
-- isso o fogacho nasce no meio do corpo e o traçado aponta para o lado errado
-- — revólver mal enquadrado lê como faísca no ar.
--═══════════════════════════════════════════════════════════════

local function bocaDoCano()
	local modelo = Tool:FindFirstChild("model")
	local ponta = modelo and modelo:FindFirstChild("barrelend")
	if ponta then return ponta.CFrame end
	return Handle.CFrame * CFrame.new(0, 0, -1.2)
end

--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o tiro
--
-- Raycast do cano até a mira, com o portador fora do filtro. Espalhamento
-- determinístico: jitter senoidal por contador, no lugar dos 33 `math.random`
-- do original. Dois clientes veem o mesmo desvio.
--═══════════════════════════════════════════════════════════════

local function tracar(origem, direcao)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }
	filtro.IgnoreWater = true
	return workspace:Raycast(origem, direcao * CFG.ALCANCE_TIRO, filtro)
end

function primaria(mira)
	if tambor <= 0 then
		tocar("Tambor", 1.9, 0.5)
		return
	end

	ocupado = true
	tambor = tambor - 1

	rig:PlaySequence("TIRO", function(passo)
		local marca = marcaDe(passo)
		if marca ~= "DISPARA" then return end

		local cano = bocaDoCano()
		local origem = cano.Position
		local alvo = mira + Vector3.new(
			jitter(0.3) * CFG.ESPALHAMENTO * CFG.ALCANCE_TIRO,
			jitter(1.7) * CFG.ESPALHAMENTO * CFG.ALCANCE_TIRO,
			jitter(2.9) * CFG.ESPALHAMENTO * CFG.ALCANCE_TIRO)
		local direcao = (alvo - origem)
		if direcao.Magnitude < 0.01 then direcao = cano.LookVector end
		direcao = direcao.Unit

		local acerto = tracar(origem, direcao)
		local ponto = acerto and acerto.Position
			or (origem + direcao * CFG.ALCANCE_TIRO)

		vfx("FOGACHO", { cframe = CFrame.lookAt(origem, origem + direcao),
			escala = 1 })
		vfx("TRACADO", { origem = origem, destino = ponto })
		vfx("CASQUINHA", { posicao = origem })
		tocarEm("Tiro", origem, 1 + jitter(0.8) * 0.06)

		if not acerto then return end
		local corpo = acerto.Instance and acerto.Instance.Parent
		local hum = corpo and corpo:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.Health > 0) then
			vfx("IMPACTO_METAL", { posicao = ponto, escala = 0.6 })
			return
		end

		local naCabeca = acerto.Instance.Name == "Head"
		aplicarDano(hum, naCabeca and CFG.DANO_CABECA or CFG.DANO)
		vfx("IMPACTO", { posicao = ponto, escala = naCabeca and 1.3 or 0.9 })
		empurrar(hum, direcao, CFG.EMPURRAO, 0.12)
	end, function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — recarregar
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	if tambor >= CFG.CAPACIDADE then return end
	ocupado = true
	rig:PlaySequence("RECARGA", function(passo)
		local marca = marcaDe(passo)
		if marca == "ABRE" then
			tocar("Tambor", 1.1)
		elseif marca == "EJETA" then
			local cano = bocaDoCano()
			for i = 1, CFG.CAPACIDADE - tambor do
				vfx("CASQUINHA", { posicao = cano.Position
					- cano.LookVector * (0.4 + i * 0.12) })
			end
		elseif marca == "ENCHE" then
			tocar("Tambor", 0.85)
		elseif marca == "FECHA" then
			tambor = CFG.CAPACIDADE
			tocar("Fecha", 1.15)
		end
	end, function()
		ocupado = false
	end)
end
''',
    ao_equipar="\ttambor = CFG.CAPACIDADE\n",
    ao_guardar="",
)


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    servidor = (PREAMBULO.format(tool=tool, **d)
                + d["corpo"]
                + RODAPE.format(**d))
    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)

    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_GUEST, os.path.join(pasta, "VFXModule.lua"))

    print("%-28s %5d linhas de Server · Client · animator · VFXModule"
          % (tool, servidor.count("\n") + 1))
    return True


def main():
    for caminho in (ANIMATOR, VFX_GUEST):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
