#!/usr/bin/env python3
"""
gerar_servers_bombas.py — Retro-Verse / Studios

Escreve o `<Tool>_Server_V1.lua` das 6 Tools do conjunto BOMBAS.

    python3 FERRAMENTAS/gerar_servers_bombas.py

As seis são clones da mesma Tool. O esqueleto — ciclo de vida, dano pelo
Núcleo, detecção que enxerga NPC, e o ARREMESSO em si — é o mesmo; o que muda
é o que acontece quando a bomba estoura. Manter isso num lugar só é o que
impede as seis de derivarem.

Nenhuma tem habilidade Extra: só `Tool.Activated`. Por isso não há AcaoRemote
nem botão de toque — o ícone da Tool já é o botão, em qualquer plataforma.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
REGUA = "═" * 63

ESQUELETO = '''-- %(arquivo)s
-- Script de servidor — %(titulo)s
--
-- CLONE do bomba_v4: mesmo Handle, mesmo mesh, mesmos sons.
-- Habilidade única, em `Tool.Activated`. Sem Extra, sem AcaoRemote.
--
--   M1  %(m1)s
--
-- CONVERSÃO (§12.12.2) — o que veio do original foram os NÚMEROS:
--   dano 20 · raio 20 · 3 mini a 20%% em raio 15 · delay 1 s · CD 1 s ·
--   explode ao tocar Humanoid OU por prazo.
--
-- O que NÃO veio, e por quê:
--   `require(8199013483)`  id numérico é execução de código remoto
--   `IsAlly` próprio       regra de combate tem uma porta só: o Núcleo
--   `workspace:GetDescendants()` por explosão — varria o jogo inteiro
--   `tick()` alimentando geometria, e a expansão animada NO SERVIDOR
--                          (replica a ~20 Hz; a expansão agora é Tween no cliente)
--   `math.random` na dispersão — virou ângulo áureo
--   `:Destroy()` e `AncestryChanged` — viraram `Parent = nil` e `Destroying`
--
-- Gerado por FERRAMENTAS/gerar_servers_bombas.py. Editar aqui à mão faz as
-- seis derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))

--%(regua)s
-- CFG — número mágico espalhado pelo corpo é violação
--%(regua)s

local ARQUETIPO = "%(arquetipo)s"

local CFG = {
%(cfg)s}

--%(regua)s
-- ESTADO
--%(regua)s

local jogador, personagem, humanoide, raiz, rig
local ultimoUso = 0
local ativos = {}
local semente = 0

local function proximo()
\tsemente = semente + 1
\tif semente > 100000 then semente = 1 end
\treturn semente
end

--- Jitter determinístico em [-1,1]. No lugar do math.random da dispersão:
--- mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
\treturn math.sin(proximo() * 2.399963 + (fase or 0))
end

local function vfx(tipo, dados)
\tVFXRemote:FireAllClients(tipo, dados)
end

--- Toca um som do Handle numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Era o bug que emudecia a explosão das seis: `tocar("Explode", bomba)`
--- punha o Sound dentro da bomba, e a linha seguinte tirava a bomba do mundo.
--- O som morria no quadro em que nascia. Um `Sound` só toca enquanto tem pai
--- no DataModel, então ele precisa de um pai que sobreviva a ele.
local function tocarEm(nome, posicao, pitch, corte)
\tlocal base = Handle:FindFirstChild(nome)
\tif not base or not base:IsA("Sound") then return nil end

\tlocal ancora = Instance.new("Part")
\tancora.Size = Vector3.new(0.2, 0.2, 0.2)
\tancora.Transparency = 1
\tancora.Anchored = true
\tancora.CanCollide = false
\tancora.CanQuery = false
\tancora.CFrame = CFrame.new(posicao or Vector3.new())
\tancora.Parent = workspace

\tlocal som = base:Clone()
\tsom.PlaybackSpeed = pitch or 1
\tsom.Parent = ancora
\tsom:Play()

\tlocal vida = corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1)
\tDebris:AddItem(ancora, vida)
\treturn som
end

--- Versão presa a uma peça — só para peça que NÃO vai sumir (o Handle).
local function tocar(nome, onde, pitch, corte)
\tlocal alvo = onde or Handle
\tif alvo ~= Handle then
\t\t-- qualquer peça que não seja o Handle pode sumir no meio do som
\t\treturn tocarEm(nome, alvo.Position, pitch, corte)
\tend
\tlocal base = Handle:FindFirstChild(nome)
\tif not base or not base:IsA("Sound") then return nil end
\tlocal som = base:Clone()
\tsom.PlaybackSpeed = pitch or 1
\tsom.Parent = Handle
\tsom:Play()
\tDebris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
\treturn som
end

local function guardar(conexao)
\ttable.insert(ativos, conexao)
\treturn conexao
end

--%(regua)s
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--%(regua)s

local function creditar(alvoHum)
\tlocal marca = alvoHum:FindFirstChild("creator")
\tif marca then marca.Parent = nil end
\tmarca = Instance.new("ObjectValue")
\tmarca.Name = "creator"
\tmarca.Value = jogador
\tmarca.Parent = alvoHum
\tDebris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
\tif not alvoHum or alvoHum.Health <= 0 then return 0 end
\tlocal final = bruto
\tcreditar(alvoHum)
\talvoHum:TakeDamage(final)
\treturn final
end

--- Alvos num raio. O original varria `workspace:GetDescendants()` INTEIRO a
--- cada explosão; aqui é consulta espacial, e o filtro de time é do Núcleo.
local function alvosEm(posicao, raio, limite)

\tlocal achados, vistos = {}, {}
\tlocal filtro = OverlapParams.new()
\tfiltro.FilterType = Enum.RaycastFilterType.Exclude
\tfiltro.FilterDescendantsInstances = { personagem }
\tfor _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
\t\tlocal modelo = parte:FindFirstAncestorOfClass("Model")
\t\tlocal hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
\t\tif hum and hum.Health > 0 and not vistos[hum] then
\t\t\tvistos[hum] = true
\t\t\ttable.insert(achados, hum)
\t\t\tif limite and #achados >= limite then break end
\t\tend
\tend
\treturn achados
end

local function empurrar(alvoHum, direcao, forca, tempo)
\tlocal corpo = alvoHum.Parent
\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\tif not alvoRaiz or direcao.Magnitude < 0.01 then return end
\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
\timpulso.Velocity = direcao.Unit * forca
\timpulso.Parent = alvoRaiz
\tDebris:AddItem(impulso, tempo or 0.2)
end

--- Estouro: dano em raio + empurrão + o beat de VFX para o cliente desenhar.
local function estourar(posicao, raio, dano, escala, tipo)
\tvfx(tipo or "EXPLOSAO", { posicao = posicao, escala = escala or 1 })
\tfor _, alvo in ipairs(alvosEm(posicao, raio, 14)) do
\t\taplicarDano(alvo, dano)
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tempurrar(alvo, (alvoRaiz.Position - posicao) + Vector3.new(0, 0.3, 0),
\t\t\t\tCFG.EMPURRAO, 0.2)
\t\tend
\tend
end

--%(regua)s
-- ARREMESSO — a bomba é Part NÃO ancorada, movida por FÍSICA
--
-- Física replica com interpolação; parte ancorada movida por script de
-- servidor replica a ~20 Hz picotado. É por isso que a bomba voa por
-- BodyVelocity e não por CFrame no Heartbeat.
--%(regua)s

local function novaBomba(posicao, tamanho)
\tlocal bomba = Handle:Clone()
\tbomba.Name = "Bomba"
\tbomba.Transparency = 0
\tbomba.CanCollide = true
\tbomba.Anchored = false
\tbomba.Massless = false
\tbomba.Size = Handle.Size * (tamanho or 1)
\tbomba.CFrame = CFrame.new(posicao)
\tfor _, filho in ipairs(bomba:GetChildren()) do
\t\tif filho:IsA("Sound") then filho.Parent = nil end
\tend
\tbomba.Parent = workspace
\tpcall(function() bomba:SetNetworkOwner(nil) end)
\tDebris:AddItem(bomba, CFG.VIDA_BOMBA)
\treturn bomba
end

local function rastroDe(bomba)
\tlocal a0 = Instance.new("Attachment")
\ta0.Position = Vector3.new(0, 1, 0)
\ta0.Parent = bomba
\tlocal a1 = Instance.new("Attachment")
\ta1.Position = Vector3.new(0, -1, 0)
\ta1.Parent = bomba
\tlocal rastro = Instance.new("Trail")
\trastro.Attachment0, rastro.Attachment1 = a0, a1
\trastro.FaceCamera = true
\trastro.Lifetime = 0.25
\trastro.Transparency = NumberSequence.new(0, 1)
\trastro.WidthScale = NumberSequence.new(1, 0)
\trastro.Parent = bomba
end

--- Some com a bomba sem `:Destroy()`: transparente, sem colisão, e o Debris
--- recolhe. Destruir na hora deixa o som do estouro sem pai.
local function sumir(bomba)
\tif not bomba or not bomba.Parent then return end
\tbomba.Transparency = 1
\tbomba.CanCollide = false
\tbomba.CanTouch = false
\tDebris:AddItem(bomba, 0.15)
end

--- Arremessa a bomba na direção da mira e chama `aoEstourar(posicao)` quando
--- ela tocar um Humanoid ou o prazo vencer — o que vier primeiro.
local function arremessar(mira, aoEstourar, prazo)
\tlocal origem = Handle.Position
\tlocal bomba = novaBomba(origem, 1)
\tbomba.CFrame = CFrame.new(origem, mira)
\trastroDe(bomba)

\tlocal dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\timpulso.Velocity = bomba.CFrame.LookVector * math.max(dist, CFG.FORCA_MIN)
\t\t+ Vector3.new(0, CFG.ARCO, 0)
\timpulso.Parent = bomba
\tDebris:AddItem(impulso, 0.1)

\tlocal estourou = false
\tlocal function detonar()
\t\tif estourou or not bomba.Parent then return end
\t\testourou = true
\t\tlocal onde = bomba.Position
\t\ttocar("Explode", bomba, 1)
\t\tsumir(bomba)
\t\taoEstourar(onde)
\tend

\tguardar(bomba.Touched:Connect(function(atingido)
\t\tif estourou then return end
\t\tlocal corpo = atingido and atingido.Parent
\t\tif not corpo or corpo == personagem then return end
\t\tlocal hum = corpo:FindFirstChildOfClass("Humanoid")
\t\tif hum and hum.Health > 0 then detonar() end
\tend))

\ttask.delay(prazo or CFG.PRAZO, detonar)
\treturn bomba
end

--- Esconde o Handle enquanto a bomba está no ar e devolve com o "crescer" do
--- original. `Size` guardado uma vez — reler depois pegaria o valor animado.
local TAMANHO_HANDLE = Handle.Size

local function piscarHandle(tempo)
\tHandle.Transparency = 1
\tHandle.Size = Vector3.new(0.05, 0.05, 0.05)
\tgame:GetService("TweenService"):Create(Handle,
\t\tTweenInfo.new(tempo or 1), { Size = TAMANHO_HANDLE }):Play()
\ttask.delay(tempo or 1, function()
\t\tif Handle.Parent then Handle.Transparency = 0 end
\tend)
end

--%(regua)s
-- HABILIDADE
--%(regua)s

%(corpo)s
--%(regua)s
-- CICLO DE VIDA
--%(regua)s

--- Recarga por TIMESTAMP, como no original: sobrevive a desequipar/equipar, e
--- por isso não dá para zerar a recarga guardando e sacando a Tool.
VFXRemote.OnServerEvent:Connect(function(quem, mira)
\tif quem ~= jogador or not personagem then return end
\tif typeof(mira) ~= "Vector3" then
\t\tmira = raiz and (raiz.Position + raiz.CFrame.LookVector * 20) or Vector3.new()
\tend
\tif not humanoide or humanoide.Health <= 0 then return end

\tlocal agora = os.clock()
\tif agora - ultimoUso < CFG.RECARGA then return end
\tultimoUso = agora

\tprimaria(mira)
end)

Tool.Equipped:Connect(function()
\tpersonagem = Tool.Parent
\thumanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
\traiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
\tjogador    = personagem and Players:GetPlayerFromCharacter(personagem)
\tif not (personagem and humanoide and raiz) then return end

\trig = Animator.new(personagem, "%(sufixo)s", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
\tfor _, c in ipairs(ativos) do
\t\tif typeof(c) == "RBXScriptConnection" then c:Disconnect() end
\tend
\ttable.clear(ativos)
%(limpeza)s\tif Handle.Parent then
\t\tHandle.Transparency = 0
\t\tHandle.Size = TAMANHO_HANDLE
\tend
\tif rig then
\t\trig:Destroy()
\t\trig = nil
\tend
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
'''


COMUM = """\tEMPURRAO      = 50,
\tALCANCE_MAX   = 150,
\tFORCA_MIN     = 45,
\tARCO          = 18,
\tVIDA_BOMBA    = 6,
\tPRAZO         = 1,
"""


# a lista NÃO pode se chamar TOOLS: sombreava o caminho da pasta
CONJUNTO = [
    # ─────────────────────────────────────────────────────────── T1
    {
        "nome": "Multiplas Bombas",
        "sufixo": "MultiplasBombas",
        "titulo": "Múltiplas Bombas",
        "arquetipo": "EXPLOSIVO",
        "m1": "uma bomba que estoura em 3 mini bombas",
        "cfg": COMUM + """
\tRECARGA       = 1,
\tDANO          = 20,
\tRAIO          = 20,
\tESCALA        = 2,

\tMINIS         = 3,
\tDANO_MINI     = 4,     -- 20% de 20, como no original
\tRAIO_MINI     = 15,
\tESCALA_MINI   = 0.6,
\tPRAZO_MINI    = 1,
\tESPALHA       = 30,
""",
        "corpo": '''--- Espalha as mini bombas por ÂNGULO ÁUREO. O original sorteava a dispersão
--- com math.random, e dois clientes viam levas diferentes.
local function soltarMinis(centro)
\tlocal i = 0
\twhile i < CFG.MINIS do
\t\tlocal ang = i * 2.39996
\t\tlocal mini = novaBomba(centro + Vector3.new(0, 1.5, 0), 0.6)

\t\tlocal impulso = Instance.new("BodyVelocity")
\t\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\t\timpulso.Velocity = Vector3.new(
\t\t\tmath.cos(ang) * CFG.ESPALHA, 40, math.sin(ang) * CFG.ESPALHA)
\t\timpulso.Parent = mini
\t\tDebris:AddItem(impulso, 0.2)

\t\ttask.delay(CFG.PRAZO_MINI, function()
\t\t\tif not mini.Parent then return end
\t\t\tlocal onde = mini.Position
\t\t\tsumir(mini)
\t\t\testourar(onde, CFG.RAIO_MINI, CFG.DANO_MINI, CFG.ESCALA_MINI,
\t\t\t\t"EXPLOSAO_MINI")
\t\tend)
\t\ti = i + 1
\tend
end

function primaria(mira)
\ttocar("Throw", Handle, 1)
\tif rig then rig:PlaySequence("ARREMESSO") end
\tpiscarHandle(1)

\tarremessar(mira, function(onde)
\t\testourar(onde, CFG.RAIO, CFG.DANO, CFG.ESCALA)
\t\tsoltarMinis(onde)
\tend)
end
''',
        "limpeza": "",
    },
    # ─────────────────────────────────────────────────────────── T2
    {
        "nome": "Bomba Nuclear",
        "sufixo": "BombaNuclear",
        "titulo": "Bomba Nuclear",
        "arquetipo": "EXPLOSIVO",
        "m1": "uma nuke — cogumelo, clarão e três anéis",
        "cfg": COMUM + """
\tRECARGA       = 45,
\tDANO          = 120,
\tRAIO          = 90,
\tESCALA        = 3,
\tPRAZO_NUKE    = 1.4,   -- o tempo de queda antes do estouro

\tANEIS         = 3,
\tINTERVALO_ANEL = 0.22,
\tDANO_ANEL     = 25,
\tRAIO_ANEL     = 130,

\tDANO_NO_DONO  = 40,    -- nuke no próprio pé cobra o preço
""",
        "corpo": '''--- A nuke estoura em CAMADAS: o centro leva tudo de uma vez, e depois três
--- anéis expandindo cobram o resto. Um estouro só, num raio de 90, mataria
--- silenciosamente quem estivesse na borda sem nenhum aviso visual.
local function detonarNuke(centro)
\tvfx("NUKE", { posicao = centro, escala = CFG.ESCALA })

\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 20)) do
\t\taplicarDano(alvo, CFG.DANO)
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tempurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 1, 0),
\t\t\t\tCFG.EMPURRAO * 2.5, 0.4)
\t\tend
\tend

\tlocal i = 1
\twhile i <= CFG.ANEIS do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO_ANEL, function()
\t\t\tif not (personagem and personagem.Parent) then return end
\t\t\tlocal raioAnel = CFG.RAIO + (CFG.RAIO_ANEL - CFG.RAIO)
\t\t\t\t* (indice / CFG.ANEIS)
\t\t\tfor _, alvo in ipairs(alvosEm(centro, raioAnel, 20)) do
\t\t\t\taplicarDano(alvo, CFG.DANO_ANEL)
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\t-- O portador não é imune à própria nuke, se estiver perto.
\tif humanoide and humanoide.Health > 0 and raiz then
\t\tif (raiz.Position - centro).Magnitude < CFG.RAIO then
\t\t\tlocal reduzido = CFG.DANO_NO_DONO
\t\t\thumanoide:TakeDamage(reduzido)
\t\tend
\tend
end

function primaria(mira)
\ttocar("Throw", Handle, 0.6)
\tif rig then rig:PlaySequence("CHAMADO") end
\tpiscarHandle(1.4)

\t-- cai de cima, no ponto mirado
\tlocal alto = mira + Vector3.new(0, 220, 0)
\tvfx("METEORO", {
\t\torigem = alto, posicao = mira, duracao = CFG.PRAZO_NUKE,
\t\tescala = 2.4, cor = Color3.fromRGB(255, 245, 214),
\t})

\ttask.delay(CFG.PRAZO_NUKE, function()
\t\tif not (personagem and personagem.Parent) then return end
\t\tdetonarNuke(mira)
\tend)
end
''',
        "limpeza": "",
    },
    # ─────────────────────────────────────────────────────────── T3
    {
        "nome": "Bomba Meteorica",
        "sufixo": "BombaMeteorica",
        "titulo": "Bomba Meteórica",
        "arquetipo": "EXPLOSIVO",
        "m1": "meteoro na diagonal que espalha 10 mini bombas para cima",
        "cfg": COMUM + """
\tRECARGA       = 26,
\tDANO          = 65,
\tRAIO          = 34,
\tESCALA        = 2.4,

\tQUEDA         = 1,     -- 1 s de queda, com áudio, como pedido
\tALTURA        = 170,
\tDIAGONAL      = 130,   -- o quanto o meteoro vem "de lado"

\tMINIS         = 10,
\tDANO_MINI     = 13,
\tRAIO_MINI     = 15,
\tESCALA_MINI   = 0.7,
\tPRAZO_MINI    = 1.1,
\tSUBIDA_MINI   = 62,
\tESPALHA       = 26,
""",
        "corpo": '''--- As 10 mini bombas sobem e caem. A dispersão é por ângulo áureo, e o raio
--- cresce com a raiz do índice — é o que faz 10 pontos parecerem espalhados
--- em vez de enfileirados num círculo.
local function soltarMinis(centro)
\tlocal i = 0
\twhile i < CFG.MINIS do
\t\tlocal ang = i * 2.39996
\t\tlocal raioSaida = CFG.ESPALHA * math.sqrt((i + 1) / CFG.MINIS)
\t\tlocal mini = novaBomba(centro + Vector3.new(0, 2, 0), 0.55)

\t\tlocal impulso = Instance.new("BodyVelocity")
\t\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\t\timpulso.Velocity = Vector3.new(
\t\t\tmath.cos(ang) * raioSaida,
\t\t\tCFG.SUBIDA_MINI + jitter(i) * 8,
\t\t\tmath.sin(ang) * raioSaida)
\t\timpulso.Parent = mini
\t\tDebris:AddItem(impulso, 0.25)

\t\ttask.delay(CFG.PRAZO_MINI, function()
\t\t\tif not mini.Parent then return end
\t\t\tlocal onde = mini.Position
\t\t\tsumir(mini)
\t\t\testourar(onde, CFG.RAIO_MINI, CFG.DANO_MINI, CFG.ESCALA_MINI,
\t\t\t\t"EXPLOSAO_MINI")
\t\tend)
\t\ti = i + 1
\tend
end

function primaria(mira)
\tif rig then rig:PlaySequence("CHAMADO") end
\tpiscarHandle(CFG.QUEDA + 0.4)

\t-- Vem na DIAGONAL: alto e deslocado, não em queda vertical.
\tlocal lado = Vector3.new(CFG.DIAGONAL, 0, CFG.DIAGONAL * 0.6)
\tlocal alto = mira + Vector3.new(0, CFG.ALTURA, 0) + lado

\tvfx("METEORO", {
\t\torigem = alto, posicao = mira, duracao = CFG.QUEDA, escala = 2.6,
\t})

\t-- ÁUDIO DE QUEDA, 1 s: o modelo só traz `Explode` e `Throw`, então a queda
\t-- é o `Throw` desacelerado e cortado em 1 s. Inventar um rbxassetid que eu
\t-- não conferi seria pior — som que não existe é silêncio sem aviso.
\tlocal marca = novaBomba(alto, 0.05)
\tmarca.Anchored = true
\tmarca.Transparency = 1
\tmarca.CanCollide = false
\ttocar("Throw", marca, 0.45, CFG.QUEDA)
\tDebris:AddItem(marca, CFG.QUEDA + 0.5)

\ttask.delay(CFG.QUEDA, function()
\t\tif not (personagem and personagem.Parent) then return end
\t\testourar(mira, CFG.RAIO, CFG.DANO, CFG.ESCALA)
\t\tsoltarMinis(mira)
\tend)
end
''',
        "limpeza": "",
    },
    # ─────────────────────────────────────────────────────────── T4
    {
        "nome": "Bomba Basquete",
        "sufixo": "BombaBasquete",
        "titulo": "Bomba Basquete",
        "arquetipo": "EXPLOSIVO",
        "m1": "arremessa e quica 3 vezes antes de estourar",
        "cfg": COMUM + """
\tRECARGA       = 6,
\tDANO          = 38,
\tRAIO          = 24,
\tESCALA        = 1.6,

\tQUIQUES       = 3,
\tALTURA_QUIQUE = 46,
\tPERDA         = 0.62,   -- cada quique guarda 62% da altura anterior
\tPRAZO_QUIQUE  = 0.12,   -- não conta dois toques do mesmo pouso
\tPRAZO_MAXIMO  = 8,      -- teto: bomba não fica quicando para sempre
""",
        "corpo": '''--- Quique de verdade é PROPRIEDADE FÍSICA, não CFrame no Heartbeat: a bomba
--- ganha elasticidade e o chão devolve. O script só CONTA os pousos e dá o
--- empurrão para cima, para o quique ter a altura que a gente quer.
function primaria(mira)
\ttocar("Throw", Handle, 1.15)
\tif rig then rig:PlaySequence("ARREMESSO") end
\tpiscarHandle(1)

\tlocal origem = Handle.Position
\tlocal bomba = novaBomba(origem, 1)
\tbomba.CFrame = CFrame.new(origem, mira)
\tbomba.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.85, 1, 1)
\trastroDe(bomba)

\tlocal dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\timpulso.Velocity = bomba.CFrame.LookVector * math.max(dist, CFG.FORCA_MIN)
\t\t+ Vector3.new(0, CFG.ARCO, 0)
\timpulso.Parent = bomba
\tDebris:AddItem(impulso, 0.1)

\tlocal quiques, estourou, ultimoQuique = 0, false, 0

\tlocal function detonar()
\t\tif estourou or not bomba.Parent then return end
\t\testourou = true
\t\tlocal onde = bomba.Position
\t\ttocar("Explode", bomba, 1)
\t\tsumir(bomba)
\t\testourar(onde, CFG.RAIO, CFG.DANO, CFG.ESCALA)
\tend

\tguardar(bomba.Touched:Connect(function(atingido)
\t\tif estourou or not bomba.Parent then return end
\t\tlocal corpo = atingido and atingido.Parent
\t\tif corpo == personagem then return end

\t\t-- tocou em gente: estoura na hora, sem esperar os quiques
\t\tlocal hum = corpo and corpo:FindFirstChildOfClass("Humanoid")
\t\tif hum and hum.Health > 0 then
\t\t\tdetonar()
\t\t\treturn
\t\tend

\t\tlocal agora = os.clock()
\t\tif agora - ultimoQuique < CFG.PRAZO_QUIQUE then return end
\t\tultimoQuique = agora

\t\tquiques = quiques + 1
\t\tvfx("QUICA", { posicao = bomba.Position, escala = 1 })
\t\ttocar("Throw", bomba, 1.4 + quiques * 0.15)

\t\tif quiques >= CFG.QUIQUES then
\t\t\tdetonar()
\t\t\treturn
\t\tend

\t\t-- devolve para cima, cada vez mais baixo
\t\tlocal sobe = Instance.new("BodyVelocity")
\t\tsobe.MaxForce = Vector3.new(1e5, 1e6, 1e5)
\t\tsobe.Velocity = Vector3.new(
\t\t\tbomba.AssemblyLinearVelocity.X * 0.7,
\t\t\tCFG.ALTURA_QUIQUE * (CFG.PERDA ^ (quiques - 1)),
\t\t\tbomba.AssemblyLinearVelocity.Z * 0.7)
\t\tsobe.Parent = bomba
\t\tDebris:AddItem(sobe, 0.08)
\tend))

\t-- teto de segurança: se nunca quicar (caiu na água, ficou preso), estoura
\ttask.delay(CFG.PRAZO_MAXIMO, detonar)
end
''',
        "limpeza": "",
    },
    # ─────────────────────────────────────────────────────────── T5
    {
        "nome": "Bomba Doida",
        "sufixo": "BombaDoida",
        "titulo": "Bomba Doida",
        "arquetipo": "EXPLOSIVO",
        "m1": "solta 2 bombas-NPC kamikaze que ficam mais rápidas sem alvo",
        "cfg": COMUM + """
\tRECARGA       = 30,
\tQUANTAS       = 2,
\tVIDA_NPC      = 20,     -- some sozinha depois disso
\tVIDA_CORPO    = 60,

\tDANO          = 55,
\tRAIO          = 22,
\tESCALA        = 1.8,

\tPROCURA       = 120,    -- alcance de busca por alvo
\tPASSO_BUSCA   = 0.4,    -- de quanto em quanto tempo reavalia
\tTOQUE         = 4.5,    -- distância que conta como "encostou"

\tVEL_CALMA     = 14,
\tVEL_BRAVA     = 42,
\tSUBIDA_RAIVA  = 0.09,   -- por segundo SEM alvo
\tALIVIO_RAIVA  = 0.25,   -- por segundo COM alvo
""",
        "corpo": '''--- A bomba-NPC é montada AQUI, com primitivas — nada de modelo guardado fora
--- da Tool (Regra nº 1). R6 mínimo: HumanoidRootPart, Torso, Head e o
--- Humanoid, com os Motor6D que o Humanoid precisa para andar.
---
--- NOTA DE ESCOPO: isto é uma HABILIDADE de Tool, não um sistema de NPC. A
--- bomba nasce no uso, persegue, estoura e some; não há spawner, não há
--- respawn, não há nada dela fora da Tool.
local function montarBombaNPC(posicao, cor)
\tlocal corpo = Instance.new("Model")
\tcorpo.Name = "BombaDoida"

\tlocal function pedaco(nome, tamanho, offset)
\t\tlocal p = Instance.new("Part")
\t\tp.Name = nome
\t\tp.Size = tamanho
\t\tp.CFrame = CFrame.new(posicao + offset)
\t\tp.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
\t\tp.Color = cor
\t\tp.Material = Enum.Material.Metal
\t\tp.Parent = corpo
\t\treturn p
\tend

\tlocal raizNPC = pedaco("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
\traizNPC.Transparency = 1
\traizNPC.CanCollide = false

\tlocal torso = pedaco("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
\tlocal cabeca = pedaco("Head", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 4.6, 0))
\tcabeca.Shape = Enum.PartType.Ball
\tcabeca.Material = Enum.Material.Neon

\t-- as juntas que o Humanoid usa para andar
\tlocal function junta(nome, p0, p1, c0, c1)
\t\tlocal m = Instance.new("Motor6D")
\t\tm.Name, m.Part0, m.Part1, m.C0, m.C1 = nome, p0, p1, c0, c1
\t\tm.Parent = p0
\t\treturn m
\tend
\tjunta("RootJoint", raizNPC, torso, CFrame.new(), CFrame.new())
\tjunta("Neck", torso, cabeca, CFrame.new(0, 1.6, 0), CFrame.new())

\tlocal humNPC = Instance.new("Humanoid")
\thumNPC.MaxHealth = CFG.VIDA_CORPO
\thumNPC.Health = CFG.VIDA_CORPO
\thumNPC.WalkSpeed = CFG.VEL_CALMA
\thumNPC.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
\thumNPC.Parent = corpo

\tcorpo.PrimaryPart = raizNPC
\tcorpo.Parent = workspace
\treturn corpo, humNPC, raizNPC
end

--- Alvo mais próximo. Reusa `alvosEm`, que já passa pelo filtro de time do
--- Núcleo — a bomba não persegue aliado.
local function alvoMaisProximo(de)
\tlocal melhor, menor = nil, math.huge
\tfor _, alvo in ipairs(alvosEm(de, CFG.PROCURA, 16)) do
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tlocal d = (alvoRaiz.Position - de).Magnitude
\t\t\tif d < menor then melhor, menor = alvoRaiz, d end
\t\tend
\tend
\treturn melhor, menor
end

local vivas = {}

local function soltarUma(indice, mira)
\tlocal ang = indice * 2.39996
\tlocal saida = (raiz and raiz.Position or mira)
\t\t+ Vector3.new(math.cos(ang) * 4, 1, math.sin(ang) * 4)

\tlocal corpo, humNPC, raizNPC = montarBombaNPC(saida,
\t\tColor3.fromRGB(60, 55, 50))
\ttable.insert(vivas, corpo)
\tDebris:AddItem(corpo, CFG.VIDA_NPC)

\tlocal raiva = 0
\tlocal estourou = false
\tlocal proximaBusca = 0
\tlocal alvo = nil

\tlocal function detonar()
\t\tif estourou or not corpo.Parent then return end
\t\testourou = true
\t\tlocal onde = raizNPC.Position
\t\ttocar("Explode", raizNPC, 1.1)
\t\tcorpo.Parent = nil
\t\testourar(onde, CFG.RAIO, CFG.DANO, CFG.ESCALA)
\tend

\tlocal laco
\tlaco = guardar(RunService.Heartbeat:Connect(function(dt)
\t\tif estourou or not corpo.Parent or humNPC.Health <= 0 then
\t\t\tif laco then laco:Disconnect() end
\t\t\tif humNPC.Health <= 0 then detonar() end
\t\t\treturn
\t\tend

\t\tlocal agora = os.clock()
\t\tif agora >= proximaBusca then
\t\t\tproximaBusca = agora + CFG.PASSO_BUSCA
\t\t\tlocal achado = alvoMaisProximo(raizNPC.Position)
\t\t\talvo = achado
\t\t\tif alvo then
\t\t\t\thumNPC:MoveTo(alvo.Position)
\t\t\telse
\t\t\t\t-- sem alvo: anda em círculo à espera, e vai ficando brava
\t\t\t\thumNPC:MoveTo(raizNPC.Position
\t\t\t\t\t+ Vector3.new(math.cos(agora) * 8, 0, math.sin(agora) * 8))
\t\t\tend
\t\tend

\t\t-- QUANTO MAIS TEMPO SEM ALVO, MAIS BRAVA E MAIS RÁPIDA
\t\tif alvo then
\t\t\traiva = math.max(0, raiva - CFG.ALIVIO_RAIVA * dt)
\t\telse
\t\t\traiva = math.min(1, raiva + CFG.SUBIDA_RAIVA * dt)
\t\tend
\t\thumNPC.WalkSpeed = CFG.VEL_CALMA
\t\t\t+ (CFG.VEL_BRAVA - CFG.VEL_CALMA) * raiva

\t\t-- a cabeça acende conforme a raiva sobe
\t\tlocal cabeca = corpo:FindFirstChild("Head")
\t\tif cabeca then
\t\t\tcabeca.Color = Color3.fromRGB(255, 151, 0):Lerp(
\t\t\t\tColor3.fromRGB(255, 40, 30), raiva)
\t\tend
\t\tif agora >= proximaBusca - CFG.PASSO_BUSCA * 0.5 then
\t\t\tvfx("RAIVA", { posicao = raizNPC.Position, nivel = raiva, escala = 1 })
\t\tend

\t\t-- KAMIKAZE: encostou, estourou
\t\tif alvo and (alvo.Position - raizNPC.Position).Magnitude <= CFG.TOQUE then
\t\t\tdetonar()
\t\tend
\tend))

\t-- se o prazo vencer sem achar ninguém, estoura onde estiver
\ttask.delay(CFG.VIDA_NPC - 0.1, detonar)
end

function primaria(mira)
\ttocar("Throw", Handle, 0.85)
\tif rig then rig:PlaySequence("SOLTAR") end
\tpiscarHandle(1)

\tlocal i = 0
\twhile i < CFG.QUANTAS do
\t\tsoltarUma(i, mira)
\t\ti = i + 1
\tend
end
''',
        "limpeza": '''\tfor _, corpo in ipairs(vivas) do
\t\tif corpo and corpo.Parent then corpo.Parent = nil end
\tend
\ttable.clear(vivas)
''',
    },
    # ─────────────────────────────────────────────────────────── T6
    {
        "nome": "Bomba Gelada",
        "sufixo": "BombaGelada",
        "titulo": "Bomba Gelada",
        "arquetipo": "GELO",
        "m1": "congela quem pega e deixa um chão de gelo escorregadio",
        "cfg": COMUM + """
\tRECARGA       = 14,
\tDANO          = 26,
\tRAIO          = 24,
\tESCALA        = 1.5,

\tCONGELA       = 2.2,    -- segundos parado
\tRAIO_CHAO     = 26,
\tVIDA_CHAO     = 8,
\tATRITO_GELO   = 0.05,
\tLENTIDAO      = 0.4,    -- fração da WalkSpeed de quem pisa no gelo
\tPASSO_CHAO    = 0.4,
""",
        "corpo": '''--- Velocidade guardada e SEMPRE devolvida. Congelar sem descongelar é bug sem
--- saída para o jogador — e o `desmontar` também devolve, para largar a Tool
--- no meio não deixar ninguém preso.
local congelados = {}
local chaos = {}

local function devolverMovimento()
\tfor alvo, guardadoAlvo in pairs(congelados) do
\t\tif alvo and alvo.Parent then
\t\t\talvo.WalkSpeed = guardadoAlvo.velocidade
\t\t\talvo.JumpPower = guardadoAlvo.pulo
\t\t\talvo.JumpHeight = guardadoAlvo.altura
\t\tend
\tend
\tcongelados = {}
end

local function congelar(alvo, tempo, parar)
\tif congelados[alvo] then return end
\tcongelados[alvo] = {
\t\tvelocidade = alvo.WalkSpeed,
\t\tpulo = alvo.JumpPower,
\t\taltura = alvo.JumpHeight,
\t}
\tif parar then
\t\talvo.WalkSpeed = 0
\t\talvo.JumpPower = 0
\t\talvo.JumpHeight = 0
\telse
\t\talvo.WalkSpeed = alvo.WalkSpeed * CFG.LENTIDAO
\tend

\tlocal corpo = alvo.Parent
\tvfx("GELO", {
\t\talvoNome = corpo and corpo.Name,
\t\tdeslocamento = Vector3.new(0, -2.6, 0),
\t\tescala = 1,
\t})

\ttask.delay(tempo, function()
\t\tlocal guardadoAlvo = congelados[alvo]
\t\tif guardadoAlvo and alvo and alvo.Parent then
\t\t\talvo.WalkSpeed = guardadoAlvo.velocidade
\t\t\talvo.JumpPower = guardadoAlvo.pulo
\t\t\talvo.JumpHeight = guardadoAlvo.altura
\t\tend
\t\tcongelados[alvo] = nil
\tend)
end

--- O chão de gelo é uma Part ANCORADA com atrito baixo. Ela nasce e não se
--- move — nada de CFrame por frame no servidor. O visual é do cliente.
local function porChao(centro)
\tlocal id = "gelo_" .. tostring(proximo())

\tlocal chao = Instance.new("Part")
\tchao.Name = "ChaoDeGelo"
\tchao.Anchored = true
\tchao.CanCollide = true
\tchao.Size = Vector3.new(CFG.RAIO_CHAO * 2, 0.4, CFG.RAIO_CHAO * 2)
\tchao.CFrame = CFrame.new(centro - Vector3.new(0, 2.6, 0))
\tchao.Material = Enum.Material.Ice
\tchao.Color = Color3.fromRGB(150, 220, 255)
\tchao.Transparency = 0.45
\tchao.TopSurface = Enum.SurfaceType.Smooth
\tchao.CustomPhysicalProperties =
\t\tPhysicalProperties.new(0.9, CFG.ATRITO_GELO, 0.1, 1, 1)
\tchao.Parent = workspace
\ttable.insert(chaos, chao)
\tDebris:AddItem(chao, CFG.VIDA_CHAO)

\tvfx("CHAO_GELO", { posicao = centro - Vector3.new(0, 2.4, 0),
\t\tescala = CFG.RAIO_CHAO, id = id, duracao = CFG.VIDA_CHAO })

\t-- Quem estiver em cima fica lento enquanto o gelo durar
\tlocal fim = os.clock() + CFG.VIDA_CHAO
\tlocal proximoPasso = 0
\tlocal laco
\tlaco = guardar(RunService.Heartbeat:Connect(function()
\t\tlocal agora = os.clock()
\t\tif agora >= fim or not chao.Parent then
\t\t\tif laco then laco:Disconnect() end
\t\t\tvfx("PARAR", { id = id })
\t\t\treturn
\t\tend
\t\tif agora < proximoPasso then return end
\t\tproximoPasso = agora + CFG.PASSO_CHAO

\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CHAO, 14)) do
\t\t\tcongelar(alvo, CFG.PASSO_CHAO * 2, false)
\t\tend
\tend))
end

function primaria(mira)
\ttocar("Throw", Handle, 1.3)
\tif rig then rig:PlaySequence("ARREMESSO") end
\tpiscarHandle(1)

\tarremessar(mira, function(onde)
\t\tvfx("GELO", { posicao = onde, escala = CFG.ESCALA })
\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 14)) do
\t\t\taplicarDano(alvo, CFG.DANO)
\t\t\tcongelar(alvo, CFG.CONGELA, true)
\t\tend
\t\tporChao(onde)
\tend)
end
''',
        "limpeza": '''\tdevolverMovimento()
\tfor _, chao in ipairs(chaos) do
\t\tif chao and chao.Parent then chao.Parent = nil end
\tend
\ttable.clear(chaos)
''',
    },
]


def main():
    for tool in CONJUNTO:
        nome = tool["nome"]
        arquivo = "%s_Server_V1.lua" % nome.replace(" ", "_")
        pasta = os.path.join(TOOLS, nome)
        if not os.path.isdir(pasta):
            print("pasta ausente: Tools/%s — rode preparar_bombas.py antes" % nome)
            return 1

        texto = ESQUELETO % {
            "arquivo": arquivo,
            "titulo": tool["titulo"],
            "m1": tool["m1"],
            "arquetipo": tool["arquetipo"],
            "cfg": tool["cfg"],
            "corpo": tool["corpo"],
            "limpeza": tool["limpeza"],
            "sufixo": tool["sufixo"],
            "regua": REGUA,
        }

        with open(os.path.join(pasta, arquivo), "w", encoding="utf-8") as f:
            f.write(texto)
        print("  %-22s %5d linhas" % (nome, len(texto.splitlines())))

    print("")
    print("%d Server(s) gerado(s)." % len(CONJUNTO))
    return 0


if __name__ == "__main__":
    sys.exit(main())
