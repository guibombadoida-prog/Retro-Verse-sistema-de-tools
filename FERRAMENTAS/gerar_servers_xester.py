#!/usr/bin/env python3
"""
gerar_servers_xester.py — Retro-Verse / Studios

Gera Server, Client, Poses e VFXModule das 14 Tools do Xester.

    python3 FERRAMENTAS/gerar_servers_xester.py

POR QUE UM GERADOR E NÃO 14 ARQUIVOS

    Sete Tools por forma dividem o mesmo esqueleto: recarga, energia, porta do
    Núcleo, montagem do rig, beat de VFX. Copiado à mão, o esqueleto DERIVA —
    já aconteceu neste repositório, onde as sete Tools de gravidade viraram a
    mesma Tool sete vezes porque a cópia foi manual. Aqui o esqueleto é um só e
    o que muda por Tool é o corpo da habilidade.

O QUE VEIO DO ORIGINAL, E O QUE NÃO VEIO

    Veio: os NÚMEROS. Dano, raio, velocidade de projétil, tamanho de carta,
    contagem de pulso, empurrão, e os ids de som e malha. Estão citados no
    cabeçalho de cada Server, com a linha do script de origem.

    Não veio:
      `death(modelo)`        — matava por deleção; vira dano pesado pelo Núcleo
      `enemyhum.Parent:Remove()` — idem, e ainda apagava o personagem inteiro
      `damagealll` próprio   — regra de combate tem uma porta só: o Núcleo
      `math.random` em dano  — vira faixa determinística por contador
      `:Remove()` / `:Destroy()` — vira `Parent = nil` / `Debris:AddItem`
      `wait()` / `swait()`   — vira `task.wait` e beat do animator
      `BodyGyro` por quadro no servidor — mira é do cliente
      `ScreenGui` / `BillboardGui` — proibidos dentro de Tool

    E o principal: **o servidor não move geometria por quadro**. Parte ancorada
    empurrada por script de servidor replica a ~20 Hz picotado; foi o bug de
    "não está fluido". O servidor manda um beat nomeado, o cliente desenha a
    60 Hz.
"""

import json
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(RAIZ, "FERRAMENTAS", "dados", "poses_xester.json")
ANIMATOR = os.path.join(RAIZ, "ACERVO_RETROVERSE", "_AUTORAL_RetroVerse",
                        "R6_CFRAME", "R6CFrameAnimator_V2.lua")

REGUA = "═" * 62

# A paleta costura material de duas origens no mesmo conjunto. A Forma 1 é o
# mágico de cartas: branco de palco sobre preto. A Forma 2 é O Despertar, e o
# original já anda de vermelho e preto — `doomtheme`, PointLight preto, machado.
PALETAS = {
    "Forma1": [
        ("CLARO", "Color3.fromRGB(255, 255, 255)"),
        ("ESCURO", "Color3.fromRGB(28, 28, 34)"),
        ("QUENTE", "Color3.fromRGB(255, 146, 54)"),
        ("FUMACA", "Color3.fromRGB(100, 102, 115)"),
    ],
    "Forma2": [
        ("CLARO", "Color3.fromRGB(226, 60, 60)"),
        ("ESCURO", "Color3.fromRGB(20, 18, 22)"),
        ("QUENTE", "Color3.fromRGB(255, 92, 46)"),
        ("FUMACA", "Color3.fromRGB(100, 102, 115)"),
    ],
}


# ═══════════════════════════════════════════════════════════════
# ESQUELETO DO SERVER
# ═══════════════════════════════════════════════════════════════

ESQUELETO = '''-- %(arquivo)s
-- Script de servidor — %(titulo)s
--
--   M1   %(m1)s
%(linha_extra)s--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
%(origem)s--
-- O QUE NÃO ATRAVESSOU A CONVERSÃO
--   `death()` / `:Remove()` no alvo  — matar por deleção tira o abate do
--                                      Núcleo e apaga o personagem do jogador
--   `damagealll` próprio             — regra de combate tem uma porta só
--   `math.random` no dano            — faixa determinística por contador
--   `swait()` / `wait()`             — task.wait e beat do animator
--   geometria movida por quadro NO SERVIDOR — replica a ~20 Hz picotado
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
%(acao_remote)s%(mira_remote)s
--%(regua)s
-- CFG — número mágico espalhado pelo corpo é violação
--%(regua)s

local ARQUETIPO = "%(arquetipo)s"

local CFG = {
%(cfg)s}

--%(regua)s
-- ESTADO
--%(regua)s

local jogador, personagem, humanoide, raiz
local ultimoUso, ultimoExtra = 0, 0
local ultimaMira = nil
local ativos = {}
local semente = 0

local function proximo()
\tsemente = semente + 1
\tif semente > 1000000 then semente = 1 end
\treturn semente
end

--- Faixa determinística no lugar de `math.random(a, b)`.
--- O original sorteava o dano a cada golpe; aqui a variedade vem de uma
--- senoide sobre o contador — mesma dispersão, e reproduzível.
local function naFaixa(minimo, maximo)
\tlocal onda = (math.sin(proximo() * 2.399963) + 1) * 0.5
\treturn minimo + (maximo - minimo) * onda
end

--- Ângulo áureo: espalha N pontos sem repetir e sem sortear.
local function anguloDe(indice)
\treturn math.rad(137.507764 * indice)
end

local function vfx(tipo, dados)
\tVFXRemote:FireAllClients(tipo, dados)
end

local function guardar(conexao)
\ttable.insert(ativos, conexao)
\treturn conexao
end

local function soltarTudo()
\tfor _, conexao in ipairs(ativos) do
\t\tif conexao.Connected then conexao:Disconnect() end
\tend
\tativos = {}
end

--%(regua)s
-- DANO — a Tool declara, o Núcleo decide (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL: `_G.Combate and _G.Combate.x(...) or
-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro.
--%(regua)s

local function creditar(alvoHum)
\tif _G.Combate and _G.Combate.registrarAtaque then
\t\t_G.Combate.registrarAtaque(jogador, Tool, ARQUETIPO)
\telse
\t\tlocal marca = alvoHum:FindFirstChild("creator")
\t\tif marca then marca.Parent = nil end
\t\tmarca = Instance.new("ObjectValue")
\t\tmarca.Name = "creator"
\t\tmarca.Value = jogador
\t\tmarca.Parent = alvoHum
\t\tDebris:AddItem(marca, 3)
\tend
end

local function aplicarDano(alvoHum, bruto)
\tif not alvoHum or alvoHum.Health <= 0 then return 0 end
\tlocal final = (_G.Combate and _G.Combate.calcular
\t\tand _G.Combate.calcular(jogador, alvoHum, bruto)) or bruto
\tcreditar(alvoHum)
\talvoHum:TakeDamage(final)
\treturn final
end

local function alvosEm(posicao, raio, limite)
\tif _G.Combate and _G.Combate.detectarHumanoides then
\t\treturn _G.Combate.detectarHumanoides(
\t\t\tposicao, raio, personagem, jogador, humanoide, limite or 14) or {}
\tend

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

--- Golpe em área: dano + empurrão + o beat para o cliente desenhar.
local function golpearArea(posicao, raio, minimo, maximo, forca, limite)
\tlocal atingidos = 0
\tfor _, alvo in ipairs(alvosEm(posicao, raio, limite or 14)) do
\t\taplicarDano(alvo, naFaixa(minimo, maximo))
\t\tatingidos = atingidos + 1
\t\tif forca and forca > 0 then
\t\t\tlocal corpo = alvo.Parent
\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\tif alvoRaiz then
\t\t\t\tempurrar(alvo, (alvoRaiz.Position - posicao)
\t\t\t\t\t+ Vector3.new(0, 0.3, 0), forca, 0.25)
\t\t\tend
\t\tend
\tend
\treturn atingidos
end

--%(regua)s
-- MOLDES — o asset vem de DENTRO da Tool (Regra nº 1)
--%(regua)s

--- Acha um molde por nome, em qualquer profundidade de `Moldes/`.
local function molde(nome)
\treturn Moldes:FindFirstChild(nome, true)
end

--- Clona um molde para o mundo. O molde mora apagado (Transparency = 1);
--- quem acende é o cliente, ao desenhar. O que o servidor põe no mundo é
--- SÓ o que precisa de física ou de colisão.
local function porNoMundo(nome, cframe, vida)
\tlocal base = molde(nome)
\tif not base then return nil end
\tlocal copia = base:Clone()
\tcopia.Parent = workspace
\tif copia:IsA("BasePart") then
\t\tcopia.CFrame = cframe
\telseif copia:IsA("Model") and copia.PrimaryPart then
\t\tcopia:PivotTo(cframe)
\tend
\tDebris:AddItem(copia, vida or 8)
\treturn copia
end

--%(regua)s
-- PORTA DE ENTRADA — recarga, energia, e o beat
--%(regua)s

local function podeUsar(quando, recarga)
\tif not (personagem and humanoide and humanoide.Health > 0 and raiz) then
\t\treturn false
\tend
\tif os.clock() - quando < recarga then return false end
\treturn true
end

--- Mira: o cliente manda para onde aponta. O servidor CONFERE o alcance em
--- vez de confiar — payload de cliente é entrada, não verdade.
local function mirar(pedido)
\tif typeof(pedido) ~= "Vector3" then
\t\treturn raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE
\tend
\tlocal delta = pedido - raiz.Position
\tif delta.Magnitude > CFG.ALCANCE then
\t\treturn raiz.Position + delta.Unit * CFG.ALCANCE
\tend
\treturn pedido
end

%(corpo)s
%(escuta_mira)s
--%(regua)s
-- CICLO DE VIDA
--%(regua)s

Tool.Equipped:Connect(function()
\tpersonagem = Tool.Parent
\tjogador = Players:GetPlayerFromCharacter(personagem)
\thumanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
\traiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
end)

Tool.Unequipped:Connect(function()
\tsoltarTudo()
%(ao_guardar)send)

Tool.Activated:Connect(function()
\tif not podeUsar(ultimoUso, CFG.RECARGA) then return end
\tultimoUso = os.clock()
\tprimaria()
end)
%(liga_extra)s
--- `Destroying`, não `AncestryChanged`: a Tool pode trocar de pai a cada
--- equipar sem estar sendo destruída.
Tool.Destroying:Connect(function()
\tsoltarTudo()
%(ao_guardar)send)
'''


ESCUTA_MIRA = '''
--%(regua)s
-- MIRA — o mouse é do cliente, a conferência é do servidor
--
-- A primária continua em `Tool.Activated` (§9); o que chega pelo Remote é
-- só PARA ONDE, e a cada 0.1 s. O servidor guarda o último ponto e o
-- `mirar()` corta pelo alcance antes de usar — payload de cliente é entrada,
-- nunca verdade.
--%(regua)s

MiraRemote.OnServerEvent:Connect(function(quem, ponto)
	if quem ~= jogador then return end
	if typeof(ponto) ~= "Vector3" then return end
	ultimaMira = ponto
end)
'''


LIGA_EXTRA = '''
AcaoRemote.OnServerEvent:Connect(function(quem, mira)
\t-- O Remote é a porta de fora: confere QUEM chamou antes de qualquer coisa.
\tif quem ~= jogador then return end
\tif not podeUsar(ultimoExtra, CFG.RECARGA_EXTRA) then return end
\tultimoExtra = os.clock()
\textra(mirar(mira))
end)
'''


# ═══════════════════════════════════════════════════════════════
# CORPOS — um por habilidade
# ═══════════════════════════════════════════════════════════════

CORPOS = {}

CORPOS["ATO_DE_DESAPARECER"] = '''--%(regua)s
-- PRIMÁRIA — o Ato de Desaparecer
--
-- O original ancorava o alvo, descia uma carta-plataforma sob ele e chamava
-- `enemyhum.Parent:Remove()`. Deletar o personagem tira o abate do Núcleo e
-- some com o corpo do jogador — aqui o alvo AFUNDA e leva dano pesado.
--%(regua)s

local function primaria()
\tlocal frente = raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE_ALVO
\tlocal perto = alvosEm(frente, CFG.RAIO_BUSCA, 1)
\tlocal alvo = perto[1]
\tif not alvo then
\t\t-- sem alvo o truque não acontece: devolve a recarga
\t\tultimoUso = 0
\t\treturn
\tend

\tlocal corpo = alvo.Parent
\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\tif not alvoRaiz then return end

\tlocal chao = alvoRaiz.Position - Vector3.new(0, CFG.FUNDO, 0)
\tvfx("CARTA_CHAO", { posicao = chao, tamanho = CFG.CARTA, giro = CFG.GIRO })

\t-- o alvo perde o chão: PlatformStand em vez de Anchored, que travaria o
\t-- personagem inteiro e deixaria o jogador preso se a Tool sumisse no meio
\talvo.PlatformStand = true
\ttask.delay(CFG.MERGULHO, function()
\t\tif alvo and alvo.Parent then alvo.PlatformStand = false end
\tend)

\tvfx("ONDA_DUPLA", { posicao = chao, escala = CFG.ESCALA_ONDA })
\taplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\tempurrar(alvo, Vector3.new(0, -1, 0), CFG.PUXAO, CFG.MERGULHO)
end
'''

CORPOS["FULL_HOUSE"] = '''--%(regua)s
-- PRIMÁRIA — Full House
--
-- 20 cartas em órbita, e o clique dispara. O original soldava as cartas num
-- `haloh` invisível preso ao Torso e girava por quadro NO SERVIDOR; aqui o
-- servidor só declara o leque, e o cliente gira a 60 Hz.
--%(regua)s

local leque = false

local function primaria()
\tif not leque then
\t\tleque = true
\t\tvfx("LEQUE_ABRE", { cartas = CFG.CARTAS, raio = CFG.RAIO_ORBITA })
\t\ttask.delay(CFG.DURACAO, function()
\t\t\tif leque then
\t\t\t\tleque = false
\t\t\t\tvfx("LEQUE_FECHA", {})
\t\t\tend
\t\tend)
\t\treturn
\tend

\t-- segunda ativação: as 20 saem de uma vez, em leque, para a frente
\tleque = false
\tlocal origem = raiz.Position + Vector3.new(0, 1.5, 0)
\tlocal frente = raiz.CFrame.LookVector
\tvfx("LEQUE_ATIRA", { origem = origem, direcao = frente, cartas = CFG.CARTAS })

\tlocal i = 1
\twhile i <= CFG.CARTAS do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (personagem and raiz) then return end
\t\t\tlocal desvio = math.sin(anguloDe(indice)) * CFG.ESPALHA
\t\t\tlocal ponto = origem + frente * CFG.DISTANCIA
\t\t\t\t+ raiz.CFrame.RightVector * desvio
\t\t\tvfx("CARTA_VOA", { origem = origem, destino = ponto })
\t\t\tgolpearArea(ponto, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\tCFG.EMPURRAO, 4)
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["CARDNADO"] = '''--%(regua)s
-- PRIMÁRIA — Cardnado
--
-- 35 pulsos em volta do corpo. O original rodava `damagealll(22)` dentro de um
-- `for ... swait()`, um pulso por quadro; aqui é `task.delay` por pulso, com o
-- mesmo total e o mesmo intervalo.
--%(regua)s

local function primaria()
\tvfx("TEMPESTADE", { duracao = CFG.PULSOS * CFG.INTERVALO,
\t\traio = CFG.RAIO, altura = CFG.ALTURA })

\tlocal i = 1
\twhile i <= CFG.PULSOS do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then
\t\t\t\treturn
\t\t\tend
\t\t\tgolpearArea(raiz.Position, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\tCFG.EMPURRAO, 10)
\t\t\tvfx("ONDA_CHAO", { posicao = raiz.Position - Vector3.new(0, 2.5, 0) })
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["TELEPORTE"] = '''--%(regua)s
-- PRIMÁRIA — Teleporte
--
-- O original não anima: `ghost()`, som, `Root.CFrame = mouse.Hit.p`, pronto.
-- Isso foi mantido — inventar uma pose de conjuração aqui seria autoral.
--
-- Quem escolhe o destino é o cliente (é ele que tem mouse), e o servidor
-- confere o alcance antes de mover. Sem a conferência, um payload forjado
-- teleportaria o jogador para qualquer canto do mapa.
--%(regua)s

local function primaria(destino)
\tlocal ponto = mirar(destino)
\tlocal saida = raiz.Position

\tvfx("FANTASMA", { posicao = saida })
\traiz.CFrame = CFrame.new(ponto + Vector3.new(0, CFG.ALTURA, 0),
\t\tponto + raiz.CFrame.LookVector)
\tvfx("FANTASMA", { posicao = raiz.Position })
end
'''

CORPOS["CARTA_COLOSSAL"] = '''--%(regua)s
-- PRIMÁRIA — Carta Colossal
--
-- Carta de 15.65 x 23.84 sobe sobre a cabeça e desce à frente. O impacto é
-- um ponto só, 21 studs à frente, como no original (`locationpart`).
--%(regua)s

local function primaria()
\tlocal alvoPonto = raiz.Position + raiz.CFrame.LookVector * CFG.AVANCO
\t\t- Vector3.new(0, CFG.FUNDO, 0)

\tvfx("CARTA_ERGUE", { posicao = raiz.Position + Vector3.new(0, CFG.SUBIDA, 0),
\t\ttamanho = CFG.CARTA })

\ttask.delay(CFG.CARGA, function()
\t\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then
\t\t\treturn
\t\tend
\t\tvfx("CARTA_DESABA", { posicao = alvoPonto, tamanho = CFG.CARTA,
\t\t\taneis = CFG.ANEIS })
\t\tgolpearArea(alvoPonto, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\tCFG.EMPURRAO, 16)
\tend)
end
'''

CORPOS["BURACO_NEGRO"] = '''--%(regua)s
-- PRIMÁRIA — Buraco Negro
--
-- Três tempos, como no original: a carta-portal abre, 100 orbes são sugados
-- com dano de raspão, e o colapso dá o golpe cheio com empurrão de 200.
--%(regua)s

local function primaria(destino)
\tlocal centro = mirar(destino)

\tvfx("PORTAL_ABRE", { posicao = centro, tamanho = CFG.CARTA })

\t-- sucção: dano de raspão a cada pulso, e o alvo é PUXADO (força negativa)
\tlocal i = 1
\twhile i <= CFG.PULSOS_SUGA do
\t\tlocal indice = i
\t\ttask.delay(CFG.ABERTURA + indice * CFG.INTERVALO, function()
\t\t\tif not personagem then return end
\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_SUGA, 12)) do
\t\t\t\taplicarDano(alvo, naFaixa(CFG.RASPAO_MIN, CFG.RASPAO_MAX))
\t\t\t\tlocal corpo = alvo.Parent
\t\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\t\tif alvoRaiz then
\t\t\t\t\tempurrar(alvo, centro - alvoRaiz.Position, CFG.SUCCAO, 0.2)
\t\t\t\tend
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\t-- colapso
\ttask.delay(CFG.ABERTURA + CFG.PULSOS_SUGA * CFG.INTERVALO, function()
\t\tif not personagem then return end
\t\tvfx("PORTAL_COLAPSA", { posicao = centro, aneis = CFG.ANEIS,
\t\t\testouros = CFG.ESTOUROS })
\t\tgolpearArea(centro, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\tCFG.EMPURRAO, 16)
\tend)
end
'''

CORPOS["ESCUDO_DE_CARTAS"] = '''--%(regua)s
-- PRIMÁRIA — Escudo de Cartas
--
-- Primeira ativação levanta a carta à frente; a segunda a estilhaça. É o
-- mesmo contrato do original ("Click to bounce people off, press p again to
-- shred"), com a diferença de que quem rebate é o `Touched` da carta REAL no
-- servidor — o original conectava `Touched` numa parte movida por quadro.
--%(regua)s

local escudo, toque = nil, nil

local function baixarEscudo()
\tif toque then
\t\tif toque.Connected then toque:Disconnect() end
\t\ttoque = nil
\tend
\tif escudo then
\t\tescudo.Parent = nil
\t\tescudo = nil
\tend
end

local function primaria()
\tif escudo then
\t\t-- segunda ativação: estilhaça
\t\tlocal onde = escudo.Position
\t\tbaixarEscudo()
\t\tvfx("ESCUDO_ESTILHACA", { posicao = onde, cacos = CFG.CACOS })
\t\tgolpearArea(onde, CFG.RAIO_ESTILHACO, CFG.DANO_CACO_MIN,
\t\t\tCFG.DANO_CACO_MAX, CFG.EMPURRAO, 12)
\t\treturn
\tend

\tlocal base = molde("Carta1")
\tif not base then return end

\tescudo = base:Clone()
\tescudo.Name = "EscudoDeCartas"
\tescudo.Size = CFG.CARTA
\tescudo.Transparency = 0
\tescudo.Anchored = true
\tescudo.CanCollide = false
\tfor _, decal in ipairs(escudo:GetChildren()) do
\t\tif decal:IsA("Decal") then decal.Transparency = 0 end
\tend
\tescudo.CFrame = raiz.CFrame * CFrame.new(0, CFG.ALTURA, -CFG.FRENTE)
\tescudo.Parent = workspace
\tvfx("ESCUDO_SOBE", { posicao = escudo.Position })

\t-- o escudo acompanha o portador sem que o servidor mexa nele por quadro:
\t-- um Weld o prende à raiz, e a física replica interpolada
\tescudo.Anchored = false
\tescudo.Massless = true
\tlocal solda = Instance.new("Weld")
\tsolda.Part0 = raiz
\tsolda.Part1 = escudo
\tsolda.C0 = CFrame.new(0, CFG.ALTURA, -CFG.FRENTE)
\tsolda.Parent = escudo

\ttoque = guardar(escudo.Touched:Connect(function(parte)
\t\tlocal modelo = parte:FindFirstAncestorOfClass("Model")
\t\tif not modelo or modelo == personagem then return end
\t\tlocal alvo = modelo:FindFirstChildOfClass("Humanoid")
\t\tif not alvo or alvo.Health <= 0 then return end
\t\taplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\t\tlocal alvoRaiz = modelo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tempurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.REBATE, 0.3)
\t\tend
\t\tvfx("ESCUDO_REBATE", { posicao = parte.Position })
\tend))

\ttask.delay(CFG.DURACAO, baixarEscudo)
end
'''

CORPOS["CARTA_CEIFEIRA"] = '''--%(regua)s
-- PRIMÁRIA — Carta Ceifeira
--
-- Três cartas saem do cajado, sobem em arco e caem no ponto mirado. O
-- original chamava `death(modelo)` no toque, que matava por deleção; aqui o
-- golpe é pesado mas passa pelo Núcleo, então o abate é creditado.
--%(regua)s

local function primaria(destino)
\tlocal ponto = mirar(destino)
\tlocal origem = raiz.Position + Vector3.new(0, CFG.SAIDA, 0)

\tlocal i = 1
\twhile i <= CFG.CARTAS do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (personagem and raiz) then return end
\t\t\tlocal desvio = Vector3.new(
\t\t\t\tmath.cos(anguloDe(indice)) * CFG.ESPALHA, 0,
\t\t\t\tmath.sin(anguloDe(indice)) * CFG.ESPALHA)
\t\t\tlocal chegada = ponto + desvio
\t\t\tvfx("CEIFEIRA_VOA", { origem = origem, destino = chegada,
\t\t\t\tvoo = CFG.VOO })
\t\t\ttask.delay(CFG.VOO, function()
\t\t\t\tif not personagem then return end
\t\t\t\tvfx("CEIFEIRA_ESTOURA", { posicao = chegada })
\t\t\t\tgolpearArea(chegada, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\t\tCFG.EMPURRAO, 8)
\t\t\tend)
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["ESFERA_DO_FIM"] = '''--%(regua)s
-- PRIMÁRIA — Esfera do Fim
--
-- Carrega enquanto segura, suga durante a carga, e detona ao soltar. O
-- original prendia a carga num `repeat ... until charging == false` amarrado
-- ao Button1Up do cliente; aqui a carga é um prazo com teto, para uma Tool
-- largada no chão não deixar sucção rodando para sempre.
--%(regua)s

local carregando = false

local function detonar(centro, forca)
\tvfx("ESFERA_DETONA", { posicao = centro, escala = forca })
\tgolpearArea(centro, CFG.RAIO * forca, CFG.DANO_MIN * forca,
\t\tCFG.DANO_MAX * forca, CFG.EMPURRAO, 16)
end

local function primaria()
\tif carregando then return end
\tcarregando = true

\tvfx("ESFERA_CARREGA", { duracao = CFG.CARGA_MAX })

\tlocal pulsos = math.floor(CFG.CARGA_MAX / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (carregando and personagem and raiz) then return end
\t\t\t-- sucção: puxa para o portador, com dano de raspão
\t\t\tfor _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SUGA, 12)) do
\t\t\t\taplicarDano(alvo, naFaixa(CFG.RASPAO_MIN, CFG.RASPAO_MAX))
\t\t\t\tlocal corpo = alvo.Parent
\t\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\t\tif alvoRaiz then
\t\t\t\t\tempurrar(alvo, raiz.Position - alvoRaiz.Position, CFG.SUCCAO, 0.2)
\t\t\t\tend
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.CARGA_MAX, function()
\t\tif not carregando then return end
\t\tcarregando = false
\t\tif personagem and raiz then
\t\t\tdetonar(raiz.Position + raiz.CFrame.LookVector * CFG.AVANCO, 1)
\t\tend
\tend)
end
'''

CORPOS["BARALHO_ESPECTRAL"] = '''--%(regua)s
-- PRIMÁRIA — Baralho Espectral
--
-- 2.5 s de conjuração, e o baralho gira em volta batendo em quem chega perto.
-- É a habilidade mais lenta das sete: o original trava o `ws` em 0 durante a
-- conjuração inteira, e isso foi mantido como `LockCharacter` no cliente.
--%(regua)s

local function primaria()
\tvfx("BARALHO_CONJURA", { duracao = CFG.CONJURA, cartas = CFG.CARTAS })

\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(CFG.CONJURA + indice * CFG.INTERVALO, function()
\t\t\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then
\t\t\t\treturn
\t\t\tend
\t\t\tlocal ang = anguloDe(indice)
\t\t\tlocal ponto = raiz.Position
\t\t\t\t+ Vector3.new(math.cos(ang), 0, math.sin(ang)) * CFG.ORBITA
\t\t\tvfx("BARALHO_GOLPE", { posicao = ponto })
\t\t\tgolpearArea(ponto, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\tCFG.EMPURRAO, 6)
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["INVOCACAO"] = '''--%(regua)s
-- PRIMÁRIA — Invocação
--
-- O original clonava `enemy` com os scripts `ai` e `core` ligados, e um
-- `skully` solto. Aqui o servo vem do molde SEM script nenhum: a perseguição
-- e o dano são deste Server, dentro da Tool. Script de terceiro rodando com
-- vida própria dentro de uma Tool é o oposto de autocontenção.
--%(regua)s

local servos = {}

local function dispensarServos()
\tfor _, servo in ipairs(servos) do
\t\tif servo.Parent then servo.Parent = nil end
\tend
\tservos = {}
end

local function primaria(destino)
\tlocal ponto = mirar(destino)
\tif #servos >= CFG.LIMITE then return end

\tlocal servo = porNoMundo("enemy", CFrame.new(ponto + Vector3.new(0, 3, 0)),
\t\tCFG.VIDA)
\tif not servo then return end
\tservo.Name = "ServoDoXester"
\ttable.insert(servos, servo)
\tvfx("INVOCA", { posicao = ponto })

\tlocal alvoHum = servo:FindFirstChildOfClass("Humanoid")
\tlocal alvoRaiz = servo:FindFirstChild("HumanoidRootPart")
\t\tor servo:FindFirstChild("Torso")
\tif not (alvoHum and alvoRaiz) then return end
\talvoHum.WalkSpeed = CFG.VELOCIDADE

\t-- a caça é por prazo, não por quadro: o servo escolhe alvo a cada passo e
\t-- deixa o Humanoid andar. Quem interpola o passo é o motor de física.
\tlocal passos = math.floor(CFG.VIDA / CFG.PASSO)
\tlocal i = 1
\twhile i <= passos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.PASSO, function()
\t\t\tif not (servo.Parent and alvoHum.Health > 0) then return end
\t\t\tlocal perto = alvosEm(alvoRaiz.Position, CFG.VISAO, 1)
\t\t\tlocal presa = perto[1]
\t\t\tif not presa then return end
\t\t\tlocal presaCorpo = presa.Parent
\t\t\tlocal presaRaiz = presaCorpo
\t\t\t\tand presaCorpo:FindFirstChild("HumanoidRootPart")
\t\t\tif not presaRaiz then return end
\t\t\talvoHum:MoveTo(presaRaiz.Position)
\t\t\tif (presaRaiz.Position - alvoRaiz.Position).Magnitude <= CFG.ALCANCE_GOLPE then
\t\t\t\tvfx("SERVO_GOLPE", { posicao = alvoRaiz.Position })
\t\t\t\taplicarDano(presa, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.VIDA, function()
\t\tfor indice, guardado in ipairs(servos) do
\t\t\tif guardado == servo then
\t\t\t\ttable.remove(servos, indice)
\t\t\t\tbreak
\t\t\tend
\t\tend
\tend)
end
'''

CORPOS["FURIA_DO_MACHADO"] = '''--%(regua)s
-- PRIMÁRIA — Fúria do Machado
--
-- O original põe `ws = 120` e sai correndo. 120 de WalkSpeed atravessa
-- colisão em servidor com replicação normal, então aqui a corrida é rápida
-- mas dentro do que o motor sustenta, e VOLTA sozinha — o original deixava a
-- velocidade alterada até a próxima troca de estado.
--%(regua)s

local correndo = false
local velocidadeAntes

local function pararCorrida()
\tif not correndo then return end
\tcorrendo = false
\tif humanoide and humanoide.Parent and velocidadeAntes then
\t\thumanoide.WalkSpeed = velocidadeAntes
\tend
\tvelocidadeAntes = nil
\tvfx("MACHADO_GUARDA", {})
end

local function primaria()
\tif correndo then
\t\tpararCorrida()
\t\treturn
\tend

\tcorrendo = true
\tvelocidadeAntes = humanoide.WalkSpeed
\thumanoide.WalkSpeed = CFG.VELOCIDADE
\tvfx("MACHADO_SACA", { duracao = CFG.DURACAO })

\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\ttask.delay(i * CFG.INTERVALO, function()
\t\t\tif not (correndo and personagem and raiz) then return end
\t\t\tlocal frente = raiz.Position + raiz.CFrame.LookVector * CFG.ALCANCE_GOLPE
\t\t\tif golpearArea(frente, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\t\tCFG.EMPURRAO, 6) > 0 then
\t\t\t\tvfx("MACHADO_CORTA", { posicao = frente })
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.DURACAO, pararCorrida)
end
'''

CORPOS["PROCISSAO_DE_CARTAS"] = '''--%(regua)s
-- PRIMÁRIA — Procissão de Cartas
--
-- Uma fileira de cartas sobe do chão, do portador até o ponto mirado. O
-- original andava 200 passos por quadro; aqui os passos são `task.delay` com o
-- mesmo espaçamento, e o cliente é quem faz cada carta crescer.
--%(regua)s

local function primaria(destino)
\tlocal ponto = mirar(destino)
\tlocal origem = raiz.Position
\tlocal delta = ponto - origem
\tlocal distancia = delta.Magnitude
\tif distancia < 1 then return end
\tlocal direcao = delta.Unit

\tlocal passos = math.min(CFG.PASSOS, math.floor(distancia / CFG.ESPACO))
\tvfx("PROCISSAO", { origem = origem, direcao = direcao, passos = passos,
\t\tespaco = CFG.ESPACO, intervalo = CFG.INTERVALO })

\tlocal i = 1
\twhile i <= passos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not personagem then return end
\t\t\tlocal onde = origem + direcao * (indice * CFG.ESPACO)
\t\t\tgolpearArea(onde, CFG.RAIO, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\t\tCFG.EMPURRAO, 6)
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["PORTAL_DO_CAJADO"] = '''--%(regua)s
-- PRIMÁRIA — Portal do Cajado
--
-- Carta-portal na ponta do cajado: puxa quem está à frente para dentro do
-- alcance e corta. É o ramo do `e` sem `secondform` do original — hitbox 10
-- studs à frente, 500 passos de corte.
--%(regua)s

local function primaria()
\tlocal centro = raiz.Position + raiz.CFrame.LookVector * CFG.FRENTE
\tvfx("PORTAL_CAJADO", { posicao = centro, duracao = CFG.DURACAO })

\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then
\t\t\t\treturn
\t\t\tend
\t\t\tlocal onde = raiz.Position + raiz.CFrame.LookVector * CFG.FRENTE
\t\t\tfor _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 10)) do
\t\t\t\taplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\t\t\t\tlocal corpo = alvo.Parent
\t\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\t\tif alvoRaiz then
\t\t\t\t\tempurrar(alvo, onde - alvoRaiz.Position, CFG.PUXAO, 0.2)
\t\t\t\tend
\t\t\tend
\t\t\tvfx("CORTE_PORTAL", { posicao = onde })
\t\tend)
\t\ti = i + 1
\tend
end
'''


# ═══════════════════════════════════════════════════════════════
# EXTRAS
# ═══════════════════════════════════════════════════════════════

EXTRAS = {}

EXTRAS["GARGALHADA"] = '''
--%(regua)s
-- EXTRA — Gargalhada
--
-- Provocação. O original desenhava "HaHaHaHaHa" num `BillboardGui`; GUI dentro
-- de Tool é proibido por diretriz, então a risada é som e cartas subindo em
-- volta da cabeça — efeito no mundo 3D, que é onde ele pode existir.
--%(regua)s

local function extra()
\tvfx("GARGALHADA", { posicao = raiz.Position, cartas = CFG.CARTAS_RISO })
\t-- provocação empurra sem ferir: quem está perto leva o susto, não o dano
\tfor _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_RISO, 8)) do
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tempurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.SUSTO, 0.2)
\t\tend
\tend
end
'''

EXTRAS["BOLA_DE_FOGO"] = '''
--%(regua)s
-- EXTRA — Bola de Fogo
--
-- Projétil da segunda forma do script original: esfera de 1.7, velocidade 120,
-- estoura no toque. A esfera é NÃO ancorada e voa por física — parte ancorada
-- movida por script de servidor replica picotada.
--%(regua)s

local function extra(mira)
\tlocal origem = raiz.Position + raiz.CFrame.LookVector * 2
\t\t+ Vector3.new(0, 1, 0)
\tlocal direcao = (mira - origem)
\tif direcao.Magnitude < 0.1 then direcao = raiz.CFrame.LookVector end
\tdirecao = direcao.Unit

\tlocal bola = Instance.new("Part")
\tbola.Shape = Enum.PartType.Ball
\tbola.Size = Vector3.new(CFG.CALIBRE, CFG.CALIBRE, CFG.CALIBRE)
\tbola.Material = Enum.Material.Neon
\tbola.BrickColor = BrickColor.new("Bright orange")
\tbola.CanCollide = false
\tbola.Massless = true
\tbola.CFrame = CFrame.new(origem, origem + direcao)
\tbola.Parent = workspace
\tDebris:AddItem(bola, CFG.VIDA_TIRO)

\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\timpulso.Velocity = direcao * CFG.VELOCIDADE_TIRO
\timpulso.Parent = bola

\tvfx("FOGO_SAI", { origem = origem, direcao = direcao,
\t\tcalibre = CFG.CALIBRE })

\tlocal gasto = false
\tlocal ligacao
\tligacao = bola.Touched:Connect(function(parte)
\t\tif gasto then return end
\t\tlocal modelo = parte:FindFirstAncestorOfClass("Model")
\t\tif modelo == personagem then return end
\t\tgasto = true
\t\tif ligacao.Connected then ligacao:Disconnect() end
\t\tlocal onde = bola.Position
\t\tbola.Parent = nil
\t\tvfx("FOGO_ESTOURA", { posicao = onde, escala = CFG.ESCALA_TIRO })
\t\tgolpearArea(onde, CFG.RAIO_TIRO, CFG.DANO_TIRO_MIN, CFG.DANO_TIRO_MAX,
\t\t\tCFG.EMPURRAO_TIRO, 8)
\tend)
\tguardar(ligacao)
end
'''

EXTRAS["BOLA_DE_FOGO_IMENSA"] = '''
--%(regua)s
-- EXTRA — Bola de Fogo Imensa
--
-- A mesma bola, carregada: 220 quadros de crescimento no original antes de
-- sair. Aqui a carga é um prazo, e o cliente é quem infla a esfera.
--%(regua)s

local function extra(mira)
\tvfx("FOGO_CARREGA", { duracao = CFG.CARGA_TIRO, calibre = CFG.CALIBRE })

\ttask.delay(CFG.CARGA_TIRO, function()
\t\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then
\t\t\treturn
\t\tend
\t\tlocal origem = raiz.Position + raiz.CFrame.LookVector * 3
\t\t\t+ Vector3.new(0, 1.5, 0)
\t\tlocal direcao = (mira - origem)
\t\tif direcao.Magnitude < 0.1 then direcao = raiz.CFrame.LookVector end
\t\tdirecao = direcao.Unit

\t\tlocal bola = Instance.new("Part")
\t\tbola.Shape = Enum.PartType.Ball
\t\tbola.Size = Vector3.new(CFG.CALIBRE, CFG.CALIBRE, CFG.CALIBRE)
\t\tbola.Material = Enum.Material.Neon
\t\tbola.BrickColor = BrickColor.new("Really red")
\t\tbola.CanCollide = false
\t\tbola.Massless = true
\t\tbola.CFrame = CFrame.new(origem, origem + direcao)
\t\tbola.Parent = workspace
\t\tDebris:AddItem(bola, CFG.VIDA_TIRO)

\t\tlocal impulso = Instance.new("BodyVelocity")
\t\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\t\timpulso.Velocity = direcao * CFG.VELOCIDADE_TIRO
\t\timpulso.Parent = bola

\t\tvfx("FOGO_SAI", { origem = origem, direcao = direcao,
\t\t\tcalibre = CFG.CALIBRE })

\t\tlocal gasto = false
\t\tlocal ligacao
\t\tligacao = bola.Touched:Connect(function(parte)
\t\t\tif gasto then return end
\t\t\tlocal modelo = parte:FindFirstAncestorOfClass("Model")
\t\t\tif modelo == personagem then return end
\t\t\tgasto = true
\t\t\tif ligacao.Connected then ligacao:Disconnect() end
\t\t\tlocal onde = bola.Position
\t\t\tbola.Parent = nil
\t\t\tvfx("FOGO_ESTOURA_GRANDE", { posicao = onde,
\t\t\t\tescala = CFG.ESCALA_TIRO, aneis = CFG.ANEIS_TIRO })
\t\t\tgolpearArea(onde, CFG.RAIO_TIRO, CFG.DANO_TIRO_MIN,
\t\t\t\tCFG.DANO_TIRO_MAX, CFG.EMPURRAO_TIRO, 14)
\t\tend)
\t\tguardar(ligacao)
\tend)
end
'''

EXTRAS["SOPRO_DO_DRAGAO"] = '''
--%(regua)s
-- EXTRA — Sopro do Dragão
--
-- Jato que cresce enquanto avança: 125 passos no original, com o raio e o
-- dano subindo a cada passo ("The longer you hold, the more insaner it gets").
-- Aqui o crescimento é o mesmo, por passo, com teto.
--%(regua)s

local function extra()
\tlocal origem = raiz.Position + Vector3.new(0, 1.5, 0)
\tlocal direcao = raiz.CFrame.LookVector

\tvfx("SOPRO", { origem = origem, direcao = direcao, passos = CFG.PASSOS_SOPRO,
\t\tintervalo = CFG.INTERVALO_SOPRO })

\tlocal i = 1
\twhile i <= CFG.PASSOS_SOPRO do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO_SOPRO, function()
\t\t\tif not (personagem and raiz) then return end
\t\t\tlocal fracao = indice / CFG.PASSOS_SOPRO
\t\t\tlocal onde = origem + direcao * (indice * CFG.AVANCO_SOPRO)
\t\t\tlocal raio = CFG.RAIO_SOPRO + CFG.CRESCE_SOPRO * fracao
\t\t\tgolpearArea(onde, raio, CFG.DANO_SOPRO_MIN + CFG.EXTRA_SOPRO * fracao,
\t\t\t\tCFG.DANO_SOPRO_MAX + CFG.EXTRA_SOPRO * fracao,
\t\t\t\tCFG.EMPURRAO_SOPRO, 10)
\t\tend)
\t\ti = i + 1
\tend
end
'''

EXTRAS["RAIO"] = '''
--%(regua)s
-- EXTRA — Raio
--
-- Feixe contínuo do original ("the longer you hold down the key, the stronger
-- it gets"). O feixe em si é CILINDRO DO CLIENTE — geometria esticada por
-- quadro no servidor é exatamente o caso que replica picotado. O servidor
-- pulsa o dano ao longo da linha.
--%(regua)s

local function extra(mira)
\tlocal origem = raiz.Position + Vector3.new(0, 1.5, 0)
\tlocal delta = mira - origem
\tif delta.Magnitude < 1 then return end
\tlocal direcao = delta.Unit
\tlocal alcance = math.min(delta.Magnitude, CFG.ALCANCE_RAIO)

\tvfx("RAIO", { origem = origem, direcao = direcao, alcance = alcance,
\t\tduracao = CFG.DURACAO_RAIO, calibre = CFG.CALIBRE_RAIO })

\tlocal pulsos = math.floor(CFG.DURACAO_RAIO / CFG.INTERVALO_RAIO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO_RAIO, function()
\t\t\tif not (personagem and raiz) then return end
\t\t\t-- amostra a linha em fatias: uma consulta por fatia, não uma por
\t\t\t-- stud, para não varrer o mundo inteiro a cada pulso
\t\t\tlocal fatia = 1
\t\t\twhile fatia <= CFG.FATIAS_RAIO do
\t\t\t\tlocal onde = origem + direcao
\t\t\t\t\t* (alcance * (fatia / CFG.FATIAS_RAIO))
\t\t\t\tgolpearArea(onde, CFG.RAIO_RAIO, CFG.DANO_RAIO_MIN,
\t\t\t\t\tCFG.DANO_RAIO_MAX, 0, 6)
\t\t\t\tfatia = fatia + 1
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend
end
'''


# ═══════════════════════════════════════════════════════════════
# TABELA — CFG e proveniência por Tool
# ═══════════════════════════════════════════════════════════════
#
# Cada entrada: sequência primária, CFG, resumo M1, e de onde os números vieram.

def linhas_cfg(pares):
    return "".join("\t%s = %s,\n" % (chave, valor) for chave, valor in pares)


TABELA = {
    "Xester Ato de Desaparecer": {
        "seq": "ATO_DE_DESAPARECER", "extra": "GARGALHADA",
        "arquetipo": "ARCANO",
        "m1": "Some o alvo dentro de uma carta no chao.",
        "origem": [
            "carta-plataforma 8 x 0.3 x 12 (un.lua:1654)",
            "afundamento 0.25/quadro por 35 quadros (un.lua:1719)",
            "duas ondas 20329976 crescendo (un.lua:1697, 1708)",
            "`enemyhum.Parent:Remove()` (un.lua:1737) VIROU dano pesado",
        ],
        "cfg": [("RECARGA", "24"), ("RECARGA_EXTRA", "6"), ("ALCANCE", "60"),
                ("ALCANCE_ALVO", "12"), ("RAIO_BUSCA", "9"),
                ("CARTA", "Vector3.new(8, 0.3, 12)"), ("GIRO", "10"),
                ("FUNDO", "3"), ("MERGULHO", "1.2"), ("ESCALA_ONDA", "2.5"),
                ("DANO_MIN", "72"), ("DANO_MAX", "96"), ("PUXAO", "38"),
                ("CARTAS_RISO", "8"), ("RAIO_RISO", "14"), ("SUSTO", "24")],
    },
    "Xester Full House": {
        "seq": "FULL_HOUSE", "extra": None, "arquetipo": "ARCANO",
        "m1": "Abre o leque de 20 cartas; ativar de novo atira.",
        "origem": [
            "20 cartas, uma a cada 20 graus, raio 4 (un.lua:836-846)",
            "carta 0.71 x 0.07 x 0.99 (un.lua:840)",
        ],
        "cfg": [("RECARGA", "14"), ("ALCANCE", "60"), ("CARTAS", "20"),
                ("RAIO_ORBITA", "4"), ("DURACAO", "8"), ("INTERVALO", "0.05"),
                ("DISTANCIA", "26"), ("ESPALHA", "7"), ("RAIO", "6"),
                ("DANO_MIN", "9"), ("DANO_MAX", "16"), ("EMPURRAO", "26")],
    },
    "Xester Cardnado": {
        "seq": "CARDNADO", "extra": "BOLA_DE_FOGO", "arquetipo": "ARCANO",
        "m1": "Tempestade de cartas em volta do corpo, 35 pulsos.",
        "origem": [
            "35 pulsos de raio 22 (un.lua:694-695)",
            "dano 17..35 e empurrao 20 (un.lua:697, 701)",
            "malha de tempestade 6512150 + textura 55364685 (un.lua:724)",
            "Extra: esfera 1.7, velocidade 120, dano 27..48 (un.lua:2453, 2532, 2506)",
        ],
        "cfg": [("RECARGA", "20"), ("RECARGA_EXTRA", "5"), ("ALCANCE", "60"),
                ("PULSOS", "35"), ("INTERVALO", "0.05"), ("RAIO", "22"),
                ("ALTURA", "3.2"), ("DANO_MIN", "17"), ("DANO_MAX", "35"),
                ("EMPURRAO", "20"),
                ("CALIBRE", "1.7"), ("VELOCIDADE_TIRO", "120"),
                ("VIDA_TIRO", "6"), ("RAIO_TIRO", "10"),
                ("DANO_TIRO_MIN", "27"), ("DANO_TIRO_MAX", "48"),
                ("EMPURRAO_TIRO", "60"), ("ESCALA_TIRO", "2.5")],
    },
    "Xester Teleporte": {
        "seq": "TELEPORTE", "extra": None, "arquetipo": "ARCANO",
        "m1": "Reaparece onde o mouse aponta.",
        "origem": [
            "destino = mouse.Hit.p + (0, 3.3, 0) (un.lua:1566)",
            "som 1894958339 (un.lua:1557)",
            "`ghost()` deixa copias Neon do corpo por 3 s (un.lua:196-230)",
        ],
        "cfg": [("RECARGA", "3"), ("ALCANCE", "120"), ("ALTURA", "3.3")],
        "mira_primaria": True,
    },
    "Xester Carta Colossal": {
        "seq": "CARTA_COLOSSAL", "extra": "BOLA_DE_FOGO_IMENSA",
        "arquetipo": "ARCANO",
        "m1": "Ergue uma carta de 24 studs e derruba a 21 de distancia.",
        "origem": [
            "carta 15.65 x 23.84 x 0.3, 18 acima (un.lua:1016-1017)",
            "impacto a (0, -3, -21) do portador (un.lua:1068)",
            "raio 20, dano 55..85, empurrao 110 (un.lua:1113-1119)",
            "quatro aneis 20329976 (un.lua:1078-1111)",
            "Extra: 220 quadros de carga antes de sair (un.lua:2592)",
        ],
        "cfg": [("RECARGA", "28"), ("RECARGA_EXTRA", "12"), ("ALCANCE", "60"),
                ("CARTA", "Vector3.new(15.65, 23.84, 0.3)"), ("SUBIDA", "18"),
                ("AVANCO", "21"), ("FUNDO", "3"), ("CARGA", "0.55"),
                ("ANEIS", "4"), ("RAIO", "20"), ("DANO_MIN", "55"),
                ("DANO_MAX", "85"), ("EMPURRAO", "110"),
                ("CARGA_TIRO", "1.8"), ("CALIBRE", "9"),
                ("VELOCIDADE_TIRO", "90"), ("VIDA_TIRO", "8"),
                ("RAIO_TIRO", "26"), ("DANO_TIRO_MIN", "48"),
                ("DANO_TIRO_MAX", "76"), ("EMPURRAO_TIRO", "90"),
                ("ESCALA_TIRO", "5"), ("ANEIS_TIRO", "2")],
    },
    "Xester Buraco Negro": {
        "mira_primaria": True,
        "seq": "BURACO_NEGRO", "extra": "RAIO", "arquetipo": "ARCANO",
        "m1": "Portal de carta que suga e colapsa.",
        "origem": [
            "carta-portal 10 x 15 x 0.3 no ponto do mouse (un.lua:1252, 1261)",
            "100 orbes de 2 studs sugados (un.lua:1336-1341)",
            "raspao em raio 45 (un.lua:1359, 1364)",
            "colapso: raio 60, dano 36..55, empurrao 200 (un.lua:1408-1414)",
            "Extra: feixe cilindrico ate o mouse (un.lua:3138-3168)",
        ],
        "cfg": [("RECARGA", "50"), ("RECARGA_EXTRA", "14"), ("ALCANCE", "90"),
                ("CARTA", "Vector3.new(10, 15, 0.3)"), ("ABERTURA", "0.7"),
                ("PULSOS_SUGA", "20"), ("INTERVALO", "0.08"),
                ("RAIO_SUGA", "45"), ("RASPAO_MIN", "0.4"),
                ("RASPAO_MAX", "1.2"), ("SUCCAO", "34"),
                ("ANEIS", "2"), ("ESTOUROS", "4"), ("RAIO", "60"),
                ("DANO_MIN", "36"), ("DANO_MAX", "55"), ("EMPURRAO", "200"),
                ("ALCANCE_RAIO", "180"), ("DURACAO_RAIO", "2.2"),
                ("INTERVALO_RAIO", "0.1"), ("FATIAS_RAIO", "8"),
                ("RAIO_RAIO", "7"), ("CALIBRE_RAIO", "3"),
                ("DANO_RAIO_MIN", "5"), ("DANO_RAIO_MAX", "11")],
    },
    "Xester Escudo de Cartas": {
        "seq": "ESCUDO_DE_CARTAS", "extra": "SOPRO_DO_DRAGAO",
        "arquetipo": "ARCANO",
        "m1": "Levanta a carta; ativar de novo estilhaca.",
        "origem": [
            "carta 8 x 13 x 0.3 a (0, 3, -5) do portador (un.lua:1959-1960)",
            "rebate: dano 23..44, empurrao 120 (un.lua:2030, 2028)",
            "estilhaco: raio 20, dano 7..12 (un.lua:1820-1826)",
            "Extra: 125 passos com raio e dano crescentes (un.lua:2988-2996)",
        ],
        "cfg": [("RECARGA", "16"), ("RECARGA_EXTRA", "10"), ("ALCANCE", "60"),
                ("CARTA", "Vector3.new(8, 13, 0.3)"), ("ALTURA", "3"),
                ("FRENTE", "5"), ("DURACAO", "10"),
                ("DANO_MIN", "23"), ("DANO_MAX", "44"), ("REBATE", "120"),
                ("CACOS", "12"), ("RAIO_ESTILHACO", "20"),
                ("DANO_CACO_MIN", "7"), ("DANO_CACO_MAX", "12"),
                ("EMPURRAO", "120"),
                ("PASSOS_SOPRO", "25"), ("INTERVALO_SOPRO", "0.06"),
                ("AVANCO_SOPRO", "2.4"), ("RAIO_SOPRO", "6"),
                ("CRESCE_SOPRO", "10"), ("DANO_SOPRO_MIN", "4"),
                ("DANO_SOPRO_MAX", "10"), ("EXTRA_SOPRO", "6"),
                ("EMPURRAO_SOPRO", "150")],
    },

    "Xester Carta Ceifeira": {
        "mira_primaria": True,
        "seq": "CARTA_CEIFEIRA", "extra": None, "arquetipo": "CEIFA",
        "m1": "Tres cartas que caem no ponto mirado.",
        "origem": [
            "tres cartas, carta 2.5 x 0.25 x 1.75 (xesterv2.lua:1081, 1090)",
            "velocidade 310 ate o ponto do mouse (xesterv2.lua:1102)",
            "raio 43 no toque (xesterv2.lua:1111)",
            "`death(...)` (xesterv2.lua:1114) VIROU dano pesado pelo Nucleo",
        ],
        "cfg": [("RECARGA", "22"), ("ALCANCE", "90"), ("CARTAS", "3"),
                ("INTERVALO", "0.12"), ("SAIDA", "2.5"), ("VOO", "0.35"),
                ("ESPALHA", "6"), ("RAIO", "43"), ("DANO_MIN", "58"),
                ("DANO_MAX", "82"), ("EMPURRAO", "60")],
    },
    "Xester Esfera do Fim": {
        "seq": "ESFERA_DO_FIM", "extra": None, "arquetipo": "CEIFA",
        "m1": "Carrega, suga durante a carga, e detona.",
        "origem": [
            "300 passos de succao em raio 40 (xesterv2.lua:1348-1349)",
            "puxao com velocidade * -50 (xesterv2.lua:1356)",
            "estouro: raio 40, empurrao 350 (xesterv2.lua:1392, 1399)",
            "`death(...)` (xesterv2.lua:1403) VIROU dano pesado pelo Nucleo",
        ],
        "cfg": [("RECARGA", "44"), ("ALCANCE", "60"), ("CARGA_MAX", "2.4"),
                ("INTERVALO", "0.1"), ("RAIO_SUGA", "40"),
                ("RASPAO_MIN", "1.5"), ("RASPAO_MAX", "3.5"),
                ("SUCCAO", "50"), ("AVANCO", "8"), ("RAIO", "40"),
                ("DANO_MIN", "70"), ("DANO_MAX", "95"), ("EMPURRAO", "350")],
    },
    "Xester Baralho Espectral": {
        "seq": "BARALHO_ESPECTRAL", "extra": None, "arquetipo": "CEIFA",
        "m1": "Conjura 2.5 s e o baralho gira batendo em volta.",
        "origem": [
            "2.5 s de conjuracao com ws = 0 (xesterv2.lua:1549-1556)",
            "carta 0.1 x 0.25 x 0.1 crescendo (xesterv2.lua:1436, 1453)",
        ],
        "cfg": [("RECARGA", "20"), ("ALCANCE", "60"), ("CONJURA", "2.5"),
                ("CARTAS", "12"), ("DURACAO", "3"), ("INTERVALO", "0.15"),
                ("ORBITA", "8"), ("RAIO", "9"), ("DANO_MIN", "14"),
                ("DANO_MAX", "26"), ("EMPURRAO", "45")],
    },
    "Xester Invocacao": {
        "mira_primaria": True,
        "seq": "INVOCACAO", "extra": None, "arquetipo": "CEIFA",
        "m1": "Chama um servo no ponto do mouse.",
        "origem": [
            "clona `enemy` com ai e core ligados (xesterv2.lua:1718)",
            "`skully2` solto no ponto do mouse (xesterv2.lua:1759)",
            "os scripts `ai`/`core` NAO entraram: a cacada e deste Server",
        ],
        "cfg": [("RECARGA", "40"), ("ALCANCE", "90"), ("LIMITE", "2"),
                ("VIDA", "20"), ("VELOCIDADE", "18"), ("PASSO", "0.4"),
                ("VISAO", "60"), ("ALCANCE_GOLPE", "7"),
                ("DANO_MIN", "10"), ("DANO_MAX", "18")],
    },
    "Xester Furia do Machado": {
        "seq": "FURIA_DO_MACHADO", "extra": "GARGALHADA",
        "arquetipo": "CEIFA",
        "m1": "Saca o machado e corre cortando; ativar de novo guarda.",
        "origem": [
            "`ws = 120` no original (xesterv2.lua:1818) — reduzido a 42, ver nota",
            "PointLight preto de alcance 35 (xesterv2.lua:1826-1830)",
            "tema 187042245 a partir de 3 s (xesterv2.lua:1821-1825)",
        ],
        "cfg": [("RECARGA", "12"), ("RECARGA_EXTRA", "6"), ("ALCANCE", "60"),
                ("VELOCIDADE", "42"), ("DURACAO", "6"), ("INTERVALO", "0.35"),
                ("ALCANCE_GOLPE", "6"), ("RAIO", "8"),
                ("DANO_MIN", "18"), ("DANO_MAX", "30"), ("EMPURRAO", "50"),
                ("CARTAS_RISO", "8"), ("RAIO_RISO", "14"), ("SUSTO", "24")],
    },
    "Xester Procissao de Cartas": {
        "mira_primaria": True,
        "seq": "PROCISSAO_DE_CARTAS", "extra": None, "arquetipo": "CEIFA",
        "m1": "Fileira de cartas subindo do chao ate o ponto mirado.",
        "origem": [
            "200 passos ao longo da linha (xesterv2.lua:1915)",
            "carta cresce 0.175 x 0.32 por quadro (xesterv2.lua:1938)",
            "raio 15 por carta (xesterv2.lua:1951)",
            "`death(...)` (xesterv2.lua:1954) VIROU dano pelo Nucleo",
        ],
        "cfg": [("RECARGA", "26"), ("ALCANCE", "90"), ("PASSOS", "24"),
                ("ESPACO", "3.5"), ("INTERVALO", "0.04"), ("RAIO", "15"),
                ("DANO_MIN", "20"), ("DANO_MAX", "34"), ("EMPURRAO", "40")],
    },
    "Xester Portal do Cajado": {
        "seq": "PROCISSAO_DE_CARTAS", "extra": None, "arquetipo": "CEIFA",
        "m1": "Carta-portal a frente que puxa e corta.",
        "origem": [
            "hitbox a (0, 0, -10) do portador (xesterv2.lua:2071)",
            "500 passos de corte (xesterv2.lua:2073)",
            "raio 27 por pulso (xesterv2.lua:2094)",
            "portal cilindrico 0.35 x 4.5 x 4.5 (xesterv2.lua:2046)",
        ],
        "cfg": [("RECARGA", "24"), ("ALCANCE", "60"), ("FRENTE", "10"),
                ("DURACAO", "4"), ("INTERVALO", "0.12"), ("RAIO", "27"),
                ("DANO_MIN", "12"), ("DANO_MAX", "22"), ("PUXAO", "40")],
    },
}

# A Tool do Portal usa o corpo próprio, não o da Procissão
TABELA["Xester Portal do Cajado"]["corpo"] = "PORTAL_DO_CAJADO"

FORMA_DE = {}
for _nome in ("Xester Ato de Desaparecer", "Xester Full House",
              "Xester Cardnado", "Xester Teleporte", "Xester Carta Colossal",
              "Xester Buraco Negro", "Xester Escudo de Cartas"):
    FORMA_DE[_nome] = "Forma1"
for _nome in ("Xester Carta Ceifeira", "Xester Esfera do Fim",
              "Xester Baralho Espectral", "Xester Invocacao",
              "Xester Furia do Machado", "Xester Procissao de Cartas",
              "Xester Portal do Cajado"):
    FORMA_DE[_nome] = "Forma2"


def gerar_server(nome, dados):
    corpo_chave = dados.get("corpo", dados["seq"])
    precisa_mira = dados.get("mira_primaria", False)
    corpo = CORPOS[corpo_chave] % {"regua": REGUA}
    extra_nome = dados.get("extra")
    if extra_nome:
        corpo = corpo + (EXTRAS[extra_nome] % {"regua": REGUA})

    origem = "".join("--   %s\n" % linha for linha in dados["origem"])
    linha_extra = ""
    if extra_nome:
        linha_extra = "--   %s   %s (habilidade Extra)\n" % (
            "Y ", extra_nome.replace("_", " ").title())

    ao_guardar = ""
    if corpo_chave == "ESCUDO_DE_CARTAS":
        ao_guardar = "\tbaixarEscudo()\n"
    elif corpo_chave == "INVOCACAO":
        ao_guardar = "\tdispensarServos()\n"
    elif corpo_chave == "FURIA_DO_MACHADO":
        ao_guardar = "\tpararCorrida()\n"
    elif corpo_chave == "ESFERA_DO_FIM":
        ao_guardar = "\tcarregando = false\n"
    elif corpo_chave == "FULL_HOUSE":
        ao_guardar = "\tleque = false\n"

    # quem precisa de mira na primária recebe o ponto pelo AcaoRemote
    return ESQUELETO % {
        "arquivo": "%s_Server_V1.lua" % nome.replace(" ", ""),
        "titulo": nome,
        "m1": dados["m1"],
        "linha_extra": linha_extra,
        "origem": origem,
        "regua": REGUA,
        "arquetipo": dados["arquetipo"],
        "cfg": linhas_cfg(dados["cfg"]),
        "corpo": corpo,
        "acao_remote": ("local AcaoRemote = Tool:WaitForChild(\"AcaoRemote\")\n"
                        if extra_nome else ""),
        "mira_remote": ("local MiraRemote = Tool:WaitForChild(\"MiraRemote\")\n"
                        if precisa_mira else ""),
        "escuta_mira": ((ESCUTA_MIRA % {"regua": REGUA}) if precisa_mira else ""),
        "passa_mira": ("mirar(ultimaMira)" if precisa_mira else ""),
        "liga_extra": (LIGA_EXTRA if extra_nome else ""),
        "ao_guardar": ao_guardar,
    }


# ═══════════════════════════════════════════════════════════════
# CLIENT — mira, animação, botão de mobile e DESENHO do VFX
# ═══════════════════════════════════════════════════════════════

CLIENTE = '''-- Client.lua
-- LocalScript — %(titulo)s
--
-- Três trabalhos, e nenhum deles é regra de combate:
--   1. mandar a mira (o mouse só existe aqui)
--   2. tocar a sequência de pose no animator canônico
--   3. DESENHAR o VFX que o servidor anuncia por beat nomeado
--
-- POR QUE O VFX É DAQUI
--   Parte ancorada movida por script de servidor replica a ~20 Hz, sem
--   interpolação — é o "não está fluido". Aqui o desenho roda a 60 Hz no
--   Heartbeat de cada cliente, e o servidor só diz O QUE e ONDE.
--
-- MOBILE
--   `ContextActionService:BindAction(nome, fn, true, tecla)` — o `true` é o
--   `createTouchButton`: o Roblox desenha o botão sozinho no celular. Não é
--   ScreenGui, e ContextActionService é serviço, não depósito de asset.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local jogador = Players.LocalPlayer
local rato = jogador:GetMouse()

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local VFX       = require(Tool:WaitForChild("VFXModule"))
%(remotes)s
local SEQUENCIA = "%(seq)s"
%(seq_extra)s
local ALCANCE_MIRA = %(alcance)s
local RITMO_MIRA = 0.1

local rig, personagem
local equipada = false
local conexoes = {}

local function guardar(conexao)
\ttable.insert(conexoes, conexao)
\treturn conexao
end

local function soltarTudo()
\tfor _, conexao in ipairs(conexoes) do
\t\tif conexao.Connected then conexao:Disconnect() end
\tend
\tconexoes = {}
end

--- Ponto mirado, cortado pelo alcance. O servidor CONFERE de novo — este
--- corte é para o traçado do efeito, não é a autoridade.
local function pontoMirado()
\tlocal raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
\tif not raiz then return nil end
\tlocal alvo = rato.Hit and rato.Hit.Position
\tif not alvo then return raiz.Position + raiz.CFrame.LookVector * 20 end
\tlocal delta = alvo - raiz.Position
\tif delta.Magnitude > ALCANCE_MIRA then
\t\treturn raiz.Position + delta.Unit * ALCANCE_MIRA
\tend
\treturn alvo
end

--%(regua)s
-- ANIMAÇÃO
--%(regua)s

local function montarRig()
\tif rig then return rig end
\tif not personagem then return nil end
\trig = Animator.new(personagem, "%(sufixo)s", Poses, Poses.SEQUENCIAS)
\treturn rig
end

--- Toca a sequência e devolve o beat ao VFX. `marca` é o que o keyframe
--- carrega: "CARGA" quando o gesto começa, "GOLPE" quando ele solta.
local function tocar(nome)
\tlocal atual = montarRig()
\tif not atual then return end
\tatual:PlaySequence(nome, function(passo)
\t\tif passo.marca then
\t\t\tVFX.beat(passo.marca, personagem)
\t\tend
\tend)
end

--%(regua)s
-- VFX — o servidor anuncia, este cliente desenha
--%(regua)s

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
\tVFX.desenhar(tipo, dados or {}, Moldes, personagem)
end)

--%(regua)s
-- ENTRADA
--%(regua)s

local function aoEquipar()
\tpersonagem = Tool.Parent
\tequipada = true
\tmontarRig()
%(liga_extra_cliente)s
\t-- a mira vai a 10 Hz, não por quadro: o servidor só precisa do PARA ONDE,
\t-- e 60 pacotes por segundo por jogador é tráfego jogado fora
\tif MiraRemote then
\t\ttask.spawn(function()
\t\t\twhile equipada do
\t\t\t\tlocal ponto = pontoMirado()
\t\t\t\tif ponto then MiraRemote:FireServer(ponto) end
\t\t\t\ttask.wait(RITMO_MIRA)
\t\t\tend
\t\tend)
\tend
end

local function aoGuardar()
\tequipada = false
\tsoltarTudo()
%(desliga_extra_cliente)s
\tif rig then
\t\trig:CancelSequence()
\t\trig:ReleaseLegs()
\tend
\tVFX.limpar()
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)

Tool.Activated:Connect(function()
\tif not equipada then return end
\ttocar(SEQUENCIA)
end)

--- `Destroying`, não `AncestryChanged`: guardar a Tool na mochila troca o pai
--- sem destruir nada, e o cleanup não pode disparar aí.
Tool.Destroying:Connect(function()
\taoGuardar()
\tif rig then
\t\trig:Destroy()
\t\trig = nil
\tend
end)
'''

LIGA_EXTRA_CLIENTE = '''
\t-- o `true` no terceiro argumento é o botão de mobile
\tContextActionService:BindAction("%(acao)s", function(_nome, estado)
\t\tif estado ~= Enum.UserInputState.Begin then return end
\t\tif not equipada then return end
\t\tAcaoRemote:FireServer(pontoMirado())
\t\ttocar(SEQUENCIA_EXTRA)
\tend, true, Enum.KeyCode.%(tecla)s)
\tContextActionService:SetTitle("%(acao)s", "%(rotulo)s")
'''

DESLIGA_EXTRA_CLIENTE = '''\tContextActionService:UnbindAction("%(acao)s")
'''


# ═══════════════════════════════════════════════════════════════
# VFXModule — molde apagado, clone aceso
# ═══════════════════════════════════════════════════════════════

VFXMODULE = '''-- VFXModule.lua
-- ModuleScript — desenho de efeito, 100%% cliente
--
-- QUEM DESENHA É O PACK DO ACERVO
--   O fluxo obrigatório manda ler `ACERVO_RETROVERSE/_INDICE.md` ANTES de criar
--   efeito, e reusar o que já existe. Existe: o `Stella_VFX_Addon`, dez efeitos
--   já conformados pelo §12.12.2, os mesmos que as 18 Tools anteriores usam.
--   Onda, nova, explosão, corte, anel, rachadura, feixe e espiral saem de lá.
--
--   O que sobrou de código próprio aqui é a CARTA — que o pack não tem, porque
--   é a assinatura do Xester — e o fallback de cada efeito, para o caso do pack
--   faltar. Pack ausente é Tool empobrecida, não Tool quebrada.
--
-- MOLDE APAGADO, CLONE ACESO
--   Tool equipada mora no workspace, então TODO BasePart descendente dela
--   renderiza. Por isso o molde entra com `Transparency = 1` e o emissor
--   `Enabled = false` — propriedade, não script, então vale para todo cliente
--   sem nada rodando. Quem acende é a cópia, nunca o molde.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local M = {}

--%(regua)s
-- PALETA — %(forma)s
--%(regua)s

local COR = {
%(paleta)s}

--%(regua)s
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- Regra nº 1, sem exceção: os módulos são filhos deste ModuleScript. Nada é
-- lido do Acervo em runtime — o pack é copiado para dentro na montagem.
--%(regua)s

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function deposito()
	if packProcurado then return raizPack end
	packProcurado = true
	raizPack = script:FindFirstChild(PACK.PASTA)
	return raizPack
end

local function efeitoDoPack(nome)
	if not PACK.LIGADO then return nil end
	local guardado = moduloDoPack[nome]
	if guardado ~= nil then
		if guardado == false then return nil end
		return guardado
	end
	local raiz = deposito()
	if not raiz then moduloDoPack[nome] = false return nil end
	local mod = raiz:FindFirstChild(nome)
	if not mod or not mod:IsA("ModuleScript") then
		moduloDoPack[nome] = false
		return nil
	end
	local ok, fn = pcall(require, mod)
	if not ok or type(fn) ~= "function" then
		moduloDoPack[nome] = false
		return nil
	end
	moduloDoPack[nome] = fn
	return fn
end

--- Chama um efeito do pack. Devolve `false` se ele não estiver lá, e é isso
--- que faz o fallback local entrar.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Xester VFX] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--%(regua)s
-- MOLDE -> CÓPIA ACESA
--%(regua)s

local ACESO = {
	BasePart = { Transparency = 0 },
	Decal = { Transparency = 0 },
	Texture = { Transparency = 0 },
	ParticleEmitter = { Enabled = true },
	Trail = { Enabled = true },
	Beam = { Enabled = true },
	PointLight = { Enabled = true },
	SpotLight = { Enabled = true },
}

local vivos = {}

local function acender(instancia)
	for classe, campos in pairs(ACESO) do
		if instancia:IsA(classe) then
			for campo, valor in pairs(campos) do
				pcall(function() instancia[campo] = valor end)
			end
		end
	end
end

function M.clonar(molde, vida)
	if not molde then return nil end
	local copia = molde:Clone()
	acender(copia)
	for _, filho in ipairs(copia:GetDescendants()) do
		acender(filho)
	end
	copia.Parent = workspace
	table.insert(vivos, copia)
	Debris:AddItem(copia, vida or 4)
	return copia
end

local function achar(moldes, nome)
	return moldes and moldes:FindFirstChild(nome, true)
end

--%(regua)s
-- PRIMITIVAS — pack primeiro, fallback local depois
--%(regua)s

--- Anel de choque no chão. `Shockwave` do pack; sem ele, um disco em Tween.
local function onda(posicao, escala, cor, vida)
	local base = Vector3.new(10.775, 2.3, 10.505) * (escala or 1)
	if pk("Shockwave", CFrame.new(posicao), CFrame.new(posicao), vida or 1.2,
			base, base * 3, cor or COR.CLARO, cor or COR.ESCURO,
			Enum.EasingStyle.Quint) then
		return
	end
	local disco = Instance.new("Part")
	disco.Shape = Enum.PartType.Cylinder
	disco.Size = Vector3.new(0.4, base.X, base.Z)
	disco.CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90))
	disco.Material = Enum.Material.Neon
	disco.Color = cor or COR.CLARO
	disco.Anchored, disco.CanCollide = true, false
	disco.Parent = workspace
	table.insert(vivos, disco)
	Debris:AddItem(disco, (vida or 1.2) + 0.5)
	TweenService:Create(disco, TweenInfo.new(vida or 1.2,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = disco.Size * 3, Transparency = 1 }):Play()
end

--- Anel largo e lento — o segundo tempo de um impacto grande.
local function ondaLarga(posicao, escala, cor, vida)
	local base = Vector3.new(14, 1.4, 14) * (escala or 1)
	if pk("Shockwave_2", CFrame.new(posicao), CFrame.new(posicao), vida or 1.8,
			base, base * 3.4, cor or COR.CLARO, cor or COR.ESCURO,
			Enum.EasingStyle.Quart) then
		return
	end
	onda(posicao, (escala or 1) * 1.5, cor, vida)
end

--- Clarão pequeno. É o beat de "saiu da mão".
local function nova(posicao, escala, cor, vida)
	-- Small_Nova recebe Size_A/Size_B como NÚMERO, não Vector3: o corpo do
	-- módulo faz conta com eles. Vector3 derruba em "invalid argument #1 to
	-- 'new'", e o pcall engolia o erro em silêncio.
	local raio = escala or 4
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Small_Nova", posicao, vida or 0.6, raio, raio * 4,
			cor or COR.CLARO, cor or COR.ESCURO, Enum.EasingStyle.Quint) then
		return
	end
	local bola = Instance.new("Part")
	bola.Shape = Enum.PartType.Ball
	bola.Size = a
	bola.Material = Enum.Material.Neon
	bola.Color = cor or COR.CLARO
	bola.Anchored, bola.CanCollide = true, false
	bola.CFrame = CFrame.new(posicao)
	bola.Parent = workspace
	table.insert(vivos, bola)
	Debris:AddItem(bola, (vida or 0.6) + 0.4)
	TweenService:Create(bola, TweenInfo.new(vida or 0.6,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = a * 4, Transparency = 1 }):Play()
end

--- Estouro com anel. O golpe médio.
local function estouro(posicao, escala, cor, vida)
	local raio = escala or 6
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Shockwave_Explosion", posicao, vida or 0.9, raio, raio * 3.2,
			cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	nova(posicao, escala, cor, vida)
	onda(posicao, (escala or 6) / 8, cor, (vida or 0.9) + 0.4)
end

--- Estouro grande, com fumaça. Reservado para ultimate.
local function estouroFumegante(posicao, escala, cor, fumaca)
	if pk("Smoky_Explosion", posicao, 1.4, (escala or 8),
			cor or COR.CLARO, fumaca or COR.FUMACA) then
		return
	end
	estouro(posicao, (escala or 8) * 1.6, cor, 1.3)
end

--- Risco de corte.
local function corte(cframe, escala, cor, vida)
	if pk("Small_Slash", cframe, (escala or 6),
			vida or 0.45, cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	nova(cframe.Position, (escala or 6) * 0.5, cor, vida or 0.45)
end

--- Anel fino que abre — conjuração, escudo subindo, portal nascendo.
local function anelSonar(cframe, escala, cor, vida)
	if pk("Sonar_Ring", cframe, vida or 1, (escala or 6), (escala or 6) * 4,
			0.6, 0.05, cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	onda(cframe.Position, (escala or 6) / 10, cor, vida)
end

--- Rachadura no chão. É o que dá PESO ao impacto de carta grande.
local function rachadura(posicao, escala, cor, vida)
	if pk("Floor_Crack", CFrame.new(posicao), (escala or 8),
			vida or 3, cor or COR.ESCURO) then
		return
	end
	onda(posicao, (escala or 8) / 10, cor, 1.4)
end

--- Feixe reto. O pack desenha o cilindro; nós só damos as pontas.
local function feixe(origem, destino, calibre, cor, vida)
	if pk("Laser_Shot", origem, destino, (calibre or 3), (calibre or 3) * 0.2,
			nil, cor or COR.CLARO, cor or COR.ESCURO,
			Enum.PartType.Cylinder, vida or 2) then
		return
	end
	local delta = destino - origem
	local cilindro = Instance.new("Part")
	cilindro.Shape = Enum.PartType.Cylinder
	cilindro.Size = Vector3.new(delta.Magnitude, calibre or 3, calibre or 3)
	cilindro.CFrame = CFrame.new(origem, destino)
		* CFrame.new(0, 0, -delta.Magnitude / 2)
		* CFrame.Angles(0, math.rad(90), 0)
	cilindro.Material = Enum.Material.Neon
	cilindro.Color = cor or COR.CLARO
	cilindro.Anchored, cilindro.CanCollide = true, false
	cilindro.Parent = workspace
	table.insert(vivos, cilindro)
	Debris:AddItem(cilindro, (vida or 2) + 0.5)
	TweenService:Create(cilindro, TweenInfo.new(vida or 2,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }):Play()
end

--- Espiral. É o efeito que faz sucção e tornado LEREM como sucção e tornado.
local function espiral(posicao, escala, cor, voltas, raio, altura)
	if pk("Spiral_Effect", posicao, (escala or 1.4),
			cor or COR.CLARO, voltas or 26, raio or 8, altura or 14) then
		return
	end
	local i = 1
	while i <= (voltas or 26) do
		local indice = i
		task.delay(indice * 0.02, function()
			local ang = math.rad(137.507764 * indice)
			nova(posicao + Vector3.new(math.cos(ang) * (raio or 8),
				indice * ((altura or 14) / (voltas or 26)),
				math.sin(ang) * (raio or 8)), (escala or 1.4) * 1.5, cor, 0.5)
		end)
		i = i + 1
	end
end

--%(regua)s
-- A CARTA — o pack não tem, e é a assinatura do Xester
--%(regua)s

local function carta(moldes, cframe, tamanho, vida)
	local base = achar(moldes, "Carta1")
	if not base then
		local baralho = achar(moldes, "cards")
		base = baralho and baralho:FindFirstChildWhichIsA("BasePart")
	end
	if not base or not base:IsA("BasePart") then return nil end

	local copia = M.clonar(base, vida or 2)
	if not copia then return nil end
	copia.Anchored, copia.CanCollide = true, false
	copia.Size = Vector3.new(0.1, 0.25, 0.1)
	copia.CFrame = cframe
	TweenService:Create(copia, TweenInfo.new((vida or 2) * 0.35,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = tamanho or Vector3.new(2.5, 0.25, 1.75) }):Play()
	task.delay((vida or 2) * 0.6, function()
		if copia.Parent then
			TweenService:Create(copia, TweenInfo.new((vida or 2) * 0.4),
				{ Transparency = 1 }):Play()
		end
	end)
	return copia
end

--%(regua)s
-- O CATÁLOGO — um beat nomeado por efeito
--%(regua)s

local VFX = {}

function VFX.CARTA_CHAO(d, moldes)
	carta(moldes, CFrame.new(d.posicao)
		* CFrame.Angles(0, math.rad(d.giro or 0), 0), d.tamanho, 2.5)
	rachadura(d.posicao, 10, COR.ESCURO, 3)
end

function VFX.ONDA_DUPLA(d)
	onda(d.posicao, d.escala or 1, COR.CLARO, 1.4)
	ondaLarga(d.posicao, (d.escala or 1) * 0.6, COR.ESCURO, 2)
end

function VFX.ONDA_CHAO(d)
	onda(d.posicao, 0.35, COR.CLARO, 1)
end

function VFX.LEQUE_ABRE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 5, COR.CLARO, 0.8)
	local total = d.cartas or 20
	local i = 1
	while i <= total do
		local ang = math.rad(360 / total * i)
		carta(moldes, raiz.CFrame * CFrame.new(math.cos(ang) * (d.raio or 4),
			math.sin(ang) * (d.raio or 4), 0), nil, 8)
		i = i + 1
	end
end

function VFX.LEQUE_FECHA() end

function VFX.LEQUE_ATIRA(d)
	nova(d.origem, 3, COR.CLARO, 0.5)
end

function VFX.CARTA_VOA(d, moldes)
	carta(moldes, CFrame.new(d.destino), nil, 1.2)
	corte(CFrame.new(d.destino), 5, COR.CLARO, 0.4)
end

--- Cardnado: espiral é literalmente o efeito certo, e o pack já tem.
function VFX.TEMPESTADE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position, 1.6, COR.CLARO, 30, d.raio and (d.raio / 3) or 7,
		(d.altura or 3.2) * 5)

	local base = achar(moldes, "Tempestade")
	if not base then return end
	local copia = M.clonar(base, d.duracao or 2)
	if not copia or not copia:IsA("BasePart") then return end
	copia.Anchored, copia.CanCollide = true, false
	local giro, conexao = 0, nil
	conexao = RunService.Heartbeat:Connect(function(dt)
		if not (copia.Parent and raiz.Parent) then
			conexao:Disconnect()
			return
		end
		giro = giro + dt * 6
		copia.CFrame = raiz.CFrame * CFrame.new(0, d.altura or 3.2, 0)
			* CFrame.Angles(0, giro, 0)
	end)
	task.delay(d.duracao or 2, function() conexao:Disconnect() end)
end

function VFX.FANTASMA(d, _moldes, personagem)
	nova(d.posicao, 4, COR.CLARO, 0.5)
	if not personagem then return end
	for _, parte in ipairs(personagem:GetChildren()) do
		if parte:IsA("BasePart") then
			local eco = Instance.new("Part")
			eco.Size, eco.CFrame = parte.Size, parte.CFrame
			eco.Material = Enum.Material.Neon
			eco.Color = COR.CLARO
			eco.Anchored, eco.CanCollide = true, false
			eco.Transparency = 0.4
			eco.Parent = workspace
			table.insert(vivos, eco)
			Debris:AddItem(eco, 1)
			TweenService:Create(eco, TweenInfo.new(1),
				{ Transparency = 1 }):Play()
		end
	end
end

function VFX.CARTA_ERGUE(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.2)
	anelSonar(CFrame.new(d.posicao), 8, COR.CLARO, 0.7)
end

function VFX.CARTA_DESABA(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.4)
	rachadura(d.posicao, 16, COR.ESCURO, 4)
	local i = 1
	while i <= (d.aneis or 4) do
		local indice = i
		task.delay(indice * 0.06, function()
			onda(d.posicao, 0.8 + indice * 0.3, COR.CLARO, 1.5)
		end)
		i = i + 1
	end
end

function VFX.PORTAL_ABRE(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		d.tamanho, 3)
	anelSonar(CFrame.new(d.posicao), 10, COR.ESCURO, 1.2)
	espiral(d.posicao, 1.8, COR.ESCURO, 34, 10, 18)
end

function VFX.PORTAL_COLAPSA(d)
	estouroFumegante(d.posicao, 12, COR.ESCURO, COR.FUMACA)
	local i = 1
	while i <= (d.estouros or 4) do
		local indice = i
		task.delay(indice * 0.05, function()
			estouro(d.posicao, 8 + indice * 3, COR.CLARO, 0.9)
		end)
		i = i + 1
	end
	local a = 1
	while a <= (d.aneis or 2) do
		ondaLarga(d.posicao, 1.6, COR.ESCURO, 2)
		a = a + 1
	end
end

function VFX.ESCUDO_SOBE(d)
	anelSonar(CFrame.new(d.posicao), 6, COR.CLARO, 0.6)
end

function VFX.ESCUDO_REBATE(d)
	nova(d.posicao, 4, COR.CLARO, 0.4)
end

function VFX.ESCUDO_ESTILHACA(d, moldes)
	estouro(d.posicao, 7, COR.CLARO, 0.8)
	local i = 1
	while i <= (d.cacos or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, CFrame.new(d.posicao + Vector3.new(
			math.cos(ang) * 4, i * 0.3, math.sin(ang) * 4)), nil, 1.4)
		i = i + 1
	end
end

function VFX.CEIFEIRA_VOA(d, moldes)
	local peca = carta(moldes, CFrame.new(d.origem), nil, (d.voo or 0.35) + 0.4)
	if not peca then return end
	TweenService:Create(peca, TweenInfo.new(d.voo or 0.35,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = CFrame.new(d.destino) }):Play()
	corte(CFrame.new(d.origem), 4, COR.ESCURO, 0.3)
end

function VFX.CEIFEIRA_ESTOURA(d)
	estouro(d.posicao, 9, COR.ESCURO, 0.9)
	rachadura(d.posicao, 8, COR.ESCURO, 2.5)
end

function VFX.ESFERA_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position + raiz.CFrame.LookVector * 3, 1.5, COR.ESCURO,
		30, 7, 12)
end

function VFX.ESFERA_DETONA(d)
	estouroFumegante(d.posicao, 14 * (d.escala or 1), COR.ESCURO, COR.FUMACA)
	ondaLarga(d.posicao, 2, COR.ESCURO, 2.2)
end

function VFX.BARALHO_CONJURA(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 9, COR.ESCURO, d.duracao or 2.5)
	local i = 1
	while i <= (d.cartas or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, raiz.CFrame * CFrame.new(math.cos(ang) * 8, 2,
			math.sin(ang) * 8), nil, (d.duracao or 2.5) + 3)
		i = i + 1
	end
end

function VFX.BARALHO_GOLPE(d)
	corte(CFrame.new(d.posicao), 5, COR.ESCURO, 0.4)
end

function VFX.INVOCA(d)
	espiral(d.posicao, 1.6, COR.ESCURO, 28, 6, 12)
	rachadura(d.posicao, 7, COR.ESCURO, 3)
end

function VFX.SERVO_GOLPE(d)
	corte(CFrame.new(d.posicao), 3.5, COR.QUENTE, 0.3)
end

function VFX.MACHADO_SACA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 7, COR.QUENTE, 0.8)
	local luz = Instance.new("PointLight")
	luz.Color = COR.ESCURO
	luz.Range, luz.Brightness = 35, 3
	luz.Parent = raiz
	Debris:AddItem(luz, d.duracao or 6)
end

function VFX.MACHADO_CORTA(d)
	corte(CFrame.new(d.posicao), 7, COR.QUENTE, 0.4)
end

function VFX.MACHADO_GUARDA() end

function VFX.PROCISSAO(d, moldes)
	local i = 1
	while i <= (d.passos or 24) do
		local indice = i
		task.delay(indice * (d.intervalo or 0.04), function()
			local onde = d.origem + d.direcao * (indice * (d.espaco or 3.5))
			carta(moldes, CFrame.new(onde - Vector3.new(0, 2, 0))
				* CFrame.Angles(0, math.rad(137.507764 * indice), 0),
				Vector3.new(7, 0.25, 5), 1.6)
			rachadura(onde, 4, COR.ESCURO, 1.6)
		end)
		i = i + 1
	end
end

function VFX.PORTAL_CAJADO(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		Vector3.new(9, 0.35, 9), (d.duracao or 4) + 1)
	anelSonar(CFrame.new(d.posicao), 9, COR.ESCURO, 1.2)
	espiral(d.posicao, 1.4, COR.ESCURO, 24, 6, 10)
end

function VFX.CORTE_PORTAL(d)
	corte(CFrame.new(d.posicao), 6, COR.ESCURO, 0.4)
end

function VFX.GARGALHADA(d, moldes)
	anelSonar(CFrame.new(d.posicao), 5, COR.CLARO, 0.9)
	local i = 1
	while i <= (d.cartas or 8) do
		local indice = i
		local ang = math.rad(137.507764 * indice)
		local peca = carta(moldes, CFrame.new(d.posicao + Vector3.new(
			math.cos(ang) * 3, 2, math.sin(ang) * 3)), nil, 2)
		if peca then
			TweenService:Create(peca, TweenInfo.new(2,
				Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = peca.CFrame * CFrame.new(0, 8, 0) }):Play()
		end
	end
end

function VFX.FOGO_SAI(d)
	nova(d.origem, (d.calibre or 2) * 1.2, COR.QUENTE, 0.4)
end

function VFX.FOGO_ESTOURA(d)
	estouro(d.posicao, 7 * (d.escala or 1), COR.QUENTE, 0.9)
end

function VFX.FOGO_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position + raiz.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0),
		1.4, COR.QUENTE, 26, 5, 9)
end

function VFX.FOGO_ESTOURA_GRANDE(d)
	estouroFumegante(d.posicao, 16 * (d.escala or 1), COR.QUENTE, COR.FUMACA)
	local i = 1
	while i <= (d.aneis or 2) do
		ondaLarga(d.posicao, 1.4, COR.QUENTE, 2)
		i = i + 1
	end
end

function VFX.SOPRO(d)
	local i = 1
	while i <= (d.passos or 25) do
		local indice = i
		task.delay(indice * (d.intervalo or 0.06), function()
			local onde = d.origem + d.direcao * (indice * 2.4)
			nova(onde, 4 + indice * 0.35, COR.QUENTE, 0.55)
			if indice %% 5 == 0 then
				corte(CFrame.new(onde, onde + d.direcao), 6, COR.QUENTE, 0.35)
			end
		end)
		i = i + 1
	end
end

--- O feixe é do pack: uma peça esticada de uma vez, no cliente. Esticar por
--- quadro no servidor é o caso que replica picotado.
function VFX.RAIO(d)
	feixe(d.origem, d.origem + d.direcao * (d.alcance or 60),
		d.calibre or 3, COR.CLARO, d.duracao or 2.2)
	nova(d.origem, 3, COR.CLARO, 0.4)
	estouro(d.origem + d.direcao * (d.alcance or 60), 6, COR.CLARO, 0.8)
end

--%(regua)s

function M.desenhar(tipo, dados, moldes, personagem)
	local fn = VFX[tipo]
	if not fn then return end
	local ok, erro = pcall(fn, dados, moldes, personagem)
	if not ok then
		warn("[Xester VFX] " .. tostring(tipo) .. ": " .. tostring(erro))
	end
end

--- Beat do animator. O gesto marca CARGA e GOLPE; aqui viram brilho na mão,
--- para o golpe ter peso ANTES do efeito grande chegar.
function M.beat(marca, personagem)
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not braco then return end
	if marca == "CARGA" then
		nova(braco.Position, 2, COR.CLARO, 0.3)
	elseif marca == "GOLPE" then
		nova(braco.Position, 4, COR.CLARO, 0.35)
	end
end

function M.limpar()
	for _, peca in ipairs(vivos) do
		if peca and peca.Parent then peca.Parent = nil end
	end
	vivos = {}
end

return M
'''

# ═══════════════════════════════════════════════════════════════
# POSES por Tool — recortadas da tabela extraída do original
# ═══════════════════════════════════════════════════════════════

CABECALHO_POSES = '''-- Poses.lua
-- ModuleScript "Poses" — %(titulo)s
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama ReleaseLegs
-- ao fim de toda sequência. Perna soldada permanentemente trava a caminhada.
--
-- ESTAS POSES NÃO SÃO AUTORAIS. Saíram do script original do modelo, pelo
-- FERRAMENTAS/extrair_poses_xester.py: a convenção de Weld foi invertida
-- (o original solda membro→Torso, o animator solda Torso→membro), o pivô do
-- C1 foi composto, e cada keyframe é o ponto que o `:lerp(alvo, alpha)`
-- repetido N quadros REALMENTE alcança — não o alvo escrito no código.
--
-- GUARDA_1 é a postura de `position == "Idle"` do original: é ela que segura
-- tronco e pernas enquanto o golpe move só o braço.

local P = {}

'''


def escrever_poses(titulo, forma, nomes, tabela):
    corpo = [CABECALHO_POSES % {"titulo": titulo}]
    for nome in nomes:
        track = tabela[forma][nome]
        for indice, kf in enumerate(track):
            corpo.append("P.%s_%d = {" % (nome, indice + 1))
            for junta in sorted(kf["juntas"]):
                corpo.append("\t%s = %s," % (junta, kf["juntas"][junta]))
            corpo.append("}")
            corpo.append("")

    corpo.append("P.SEQUENCIAS = {")
    corpo.append("")
    for nome in nomes:
        if nome == "GUARDA":
            continue
        track = tabela[forma][nome]
        corpo.append("\t%s = {" % nome)
        if len(track) < 2:
            corpo.append('\t\t{ pose = "%s_1", time = 0.12, style = "Quad", '
                         'dir = "Out", marca = "GOLPE" },' % nome)
        else:
            for indice in range(1, len(track)):
                dt = max(track[indice]["t"] - track[indice - 1]["t"], 0.03)
                marca = ""
                if indice == 1:
                    marca = ', marca = "CARGA"'
                elif indice == len(track) - 1:
                    marca = ', marca = "GOLPE"'
                corpo.append(
                    '\t\t{ pose = "%s_%d", time = %.3f, style = "Exponential", '
                    'dir = "Out"%s },' % (nome, indice + 1, dt, marca))
        corpo.append('\t\t{ pose = "GUARDA_1", time = 0.24, style = "Quad", '
                     'dir = "Out" },')
        corpo.append("\t},")
        corpo.append("")
    corpo.append("}")
    corpo.append("")
    corpo.append("return P")
    corpo.append("")
    return "\n".join(corpo)


# ═══════════════════════════════════════════════════════════════

def gerar_cliente(nome, dados):
    extra_nome = dados.get("extra")
    alcance = "60"
    for chave, valor in dados["cfg"]:
        if chave == "ALCANCE":
            alcance = valor
    sufixo = nome.replace(" ", "")

    remotes = []
    if extra_nome:
        remotes.append('local AcaoRemote = Tool:WaitForChild("AcaoRemote")')
    if dados.get("mira_primaria"):
        remotes.append('local MiraRemote = Tool:WaitForChild("MiraRemote")')
    else:
        remotes.append("local MiraRemote = nil")

    liga, desliga, seq_extra = "", "", ""
    if extra_nome:
        rotulo = extra_nome.replace("_", " ").title()[:12]
        seq_extra = 'local SEQUENCIA_EXTRA = "%s"\n' % extra_nome
        liga = LIGA_EXTRA_CLIENTE % {"acao": "Xester_%s" % sufixo,
                                     "tecla": dados.get("tecla", "Y"),
                                     "rotulo": rotulo}
        desliga = DESLIGA_EXTRA_CLIENTE % {"acao": "Xester_%s" % sufixo}

    return CLIENTE % {
        "titulo": nome,
        "regua": REGUA,
        "seq": dados["seq"],
        "seq_extra": seq_extra,
        "alcance": alcance,
        "sufixo": sufixo,
        "remotes": "\n".join(remotes) + "\n",
        "liga_extra_cliente": liga,
        "desliga_extra_cliente": desliga,
    }


def main():
    if not os.path.exists(DADOS):
        print("tabela de poses não encontrada: %s" % DADOS)
        print("rode antes: python3 FERRAMENTAS/extrair_poses_xester.py")
        return 1
    with open(DADOS, encoding="utf-8") as f:
        tabela = json.load(f)

    if not os.path.exists(ANIMATOR):
        print("animator canônico não encontrado: %s" % ANIMATOR)
        return 1
    with open(ANIMATOR, encoding="utf-8") as f:
        animator = f.read()

    print("GERAÇÃO DE SCRIPTS — Xester")
    print("")

    total = 0
    for nome in sorted(TABELA):
        dados = TABELA[nome]
        pasta = os.path.join(TOOLS, nome)
        if not os.path.isdir(pasta):
            print("  PAREI: falta a pasta %s — rode preparar_xester.py antes" % nome)
            return 1

        forma = FORMA_DE[nome]
        usadas = ["GUARDA", dados["seq"]]
        if dados.get("extra") and dados["extra"] not in usadas:
            usadas.append(dados["extra"])
        # a Extra pode viver na outra forma (as moves de fogo são da Forma 1)
        faltando = [u for u in usadas if u not in tabela[forma]]
        if faltando:
            print("  PAREI: %s não tem a(s) track(s) %s na %s"
                  % (nome, ", ".join(faltando), forma))
            return 1

        arquivos = {
            "%s_Server_V1.lua" % nome.replace(" ", ""): gerar_server(nome, dados),
            "Client.lua": gerar_cliente(nome, dados),
            "Poses.lua": escrever_poses(nome, forma, usadas, tabela),
            "R6CFrameAnimator.lua": animator,
            "VFXModule.lua": VFXMODULE % {
                "regua": REGUA,
                "forma": ("Forma 1, o Mestre das Cartas" if forma == "Forma1"
                          else "Forma 2, O Despertar"),
                "paleta": "".join("\t%s = %s,\n" % (c, v)
                                  for c, v in PALETAS[forma]),
            },
        }
        for arquivo, conteudo in arquivos.items():
            with open(os.path.join(pasta, arquivo), "w", encoding="utf-8") as f:
                f.write(conteudo)

        extra = dados.get("extra") or "—"
        print("  %-30s %-22s %s" % (nome, dados["seq"], extra))
        total = total + 1

    print("")
    print("%d Tool(s) com Server, Client, Poses, Animator e VFXModule." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
