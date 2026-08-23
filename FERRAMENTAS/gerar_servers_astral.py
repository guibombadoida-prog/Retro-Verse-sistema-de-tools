#!/usr/bin/env python3
"""
gerar_servers_astral.py — Retro-Verse / Studios

Escreve o `<Tool>_Server_V1.lua` das 4 Tools CLONADAS do Astral Periastron.

    python3 FERRAMENTAS/gerar_servers_astral.py

POR QUE UM GERADOR, E NÃO QUATRO ARQUIVOS À MÃO

    As quatro compartilham o mesmo esqueleto: mesmo ciclo de vida, mesmo
    pipeline de dano pelo Núcleo, mesma detecção que enxerga NPC, mesma
    política de "servidor manda beat, cliente desenha". O que muda é o CORPO
    das duas habilidades de cada uma.

    Manter o esqueleto num lugar só é o que impede as quatro de derivarem —
    foi exatamente o que aconteceu com as 7 Tools de gravidade da primeira
    leva, que acabaram sendo a mesma Tool sete vezes por cópia manual.

    O Server da `Astral Periastron` NÃO sai daqui: ele é escrito à mão porque
    carrega as habilidades ORIGINAIS do modelo, com os números do original.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")

CABECALHO = '''-- %(arquivo)s
-- Script de servidor — %(titulo)s
--
-- CLONE do Astral Periastron: mesmo Handle, mesmo mesh, mesmos sons e
-- emissores. O que muda são as duas habilidades.
--
--   M1  %(m1)s
--   X   %(extra)s
--
-- Gerado por FERRAMENTAS/gerar_servers_astral.py — o esqueleto (ciclo de vida,
-- dano pelo Núcleo, detecção que enxerga NPC, beat para o cliente) mora lá.
-- Editar aqui à mão faz as quatro derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
%(remote_cutscene)s
--%(regua)s
-- CFG — número mágico espalhado pelo corpo é violação
--%(regua)s

local ARQUETIPO = "ASTRAL"

local CFG = {
%(cfg)s}

--%(regua)s
-- ESTADO
--%(regua)s

local jogador, personagem, humanoide, raiz, rig
local podeExtra = true
local ativos = {}
local semente = 0

local function proximo()
\tsemente = semente + 1
\tif semente > 100000 then semente = 1 end
\treturn semente
end

local function vfx(tipo, dados)
\tVFXRemote:FireAllClients(tipo, dados)
end

local function tocar(nome, pitch)
\tlocal base = Handle:FindFirstChild(nome)
\tif not base or not base:IsA("Sound") then return end
\tlocal som = base:Clone()
\tsom.PlaybackSpeed = pitch or 1
\tsom.Parent = Handle
\tsom:Play()
\tDebris:AddItem(som, (som.TimeLength > 0 and som.TimeLength or 4) + 1)
end

local function guardar(conexao)
\ttable.insert(ativos, conexao)
\treturn conexao
end

local function soltarTudo()
\tfor _, c in ipairs(ativos) do
\t\tif typeof(c) == "RBXScriptConnection" then c:Disconnect() end
\tend
\ttable.clear(ativos)
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

--- NPC é Model com Humanoid, NÃO é Player: varrer `Players:GetPlayers()` não
--- enxerga NPC nenhum, e foi assim que uma leva inteira saiu sem acertar
--- inimigo de mapa.
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

--- Empurrão sem mexer em Health nem em estado: BodyVelocity com prazo.
local function empurrar(alvoHum, direcao, forca, tempo)
\tlocal corpo = alvoHum.Parent
\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\tif not alvoRaiz then return end
\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
\timpulso.Velocity = direcao.Unit * forca
\timpulso.Parent = alvoRaiz
\tDebris:AddItem(impulso, tempo or 0.2)
end

--%(regua)s
-- HABILIDADES
--%(regua)s

%(corpo)s
--%(regua)s
-- CICLO DE VIDA
--%(regua)s

Tool.Activated:Connect(primaria)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
\tif quem ~= jogador then return end
\tif tecla ~= "X" then return end
\tif typeof(mira) ~= "Vector3" then mira = raiz and raiz.Position or Vector3.new() end
\textra(mira)
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
\tsoltarTudo()
%(limpeza)s\tif rig then
\t\trig:Destroy()
\t\trig = nil
\tend
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)
'''


TOOLS_GERADAS = [
    {
        "nome": "Astral Nova",
        "sufixo": "AstralNova",
        "titulo": "Astral Nova",
        "m1": "Nova Estelar — onda estelar em cone, empurra quem pega",
        "extra": "Colapso Anão — puxa tudo para o centro e detona",
        "cfg": """\tDANO_NOVA       = 31,
\tALCANCE_NOVA    = 15,
\tANGULO_NOVA     = 70,      -- graus, meia-abertura do cone
\tEMPURRAO_NOVA   = 55,
\tDEBOUNCE_NOVA   = 0.5,

\tRAIO_COLAPSO    = 26,
\tDANO_COLAPSO    = 44,
\tPUXAO_COLAPSO   = 70,
\tTEMPO_COLAPSO   = 0.55,
\tCD_COLAPSO      = 18,

\tSFX_GOLPE       = "SlashSound",
\tSFX_EXTRA       = "TeleSpike",
""",
        "corpo": '''--- Nova Estelar: cone à frente. O cone é conferido por ÂNGULO, não por
--- caixa: quem está atrás do portador não leva.
function primaria()
\tif not Tool.Enabled or not raiz then return end
\tTool.Enabled = false
\ttask.delay(CFG.DEBOUNCE_NOVA, function() Tool.Enabled = true end)

\tlocal frente = raiz.CFrame.LookVector
\tlocal centro = raiz.Position + frente * 4

\ttocar(CFG.SFX_GOLPE, 1.05)
\tif rig then rig:PlaySequence("NOVA") end
\tvfx("NOVA", { posicao = centro, escala = 1.2, direcao = frente })

\tlocal limite = math.cos(math.rad(CFG.ANGULO_NOVA))
\tlocal acertou = false
\tfor _, alvo in ipairs(alvosEm(centro, CFG.ALCANCE_NOVA, 12)) do
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tlocal para = (alvoRaiz.Position - raiz.Position)
\t\t\tif para.Magnitude > 0.1 and para.Unit:Dot(frente) >= limite then
\t\t\t\taplicarDano(alvo, CFG.DANO_NOVA)
\t\t\t\tempurrar(alvo, para + Vector3.new(0, 0.4, 0), CFG.EMPURRAO_NOVA, 0.22)
\t\t\t\tacertou = true
\t\t\tend
\t\tend
\tend
\tif acertou then
\t\tvfx("IMPACTO", { posicao = centro, escala = 1.2 })
\tend
end

--- Colapso Anão: puxa por PULSOS, não continuamente. Puxão contínuo briga
--- com o Humanoid do alvo — dois donos do mesmo corpo, e o alvo trava.
function extra(mira)
\tif not podeExtra or not raiz then return end
\tpodeExtra = false
\ttask.delay(CFG.CD_COLAPSO, function() podeExtra = true end)

\tlocal centro = raiz.Position + raiz.CFrame.LookVector * 8
\ttocar(CFG.SFX_EXTRA, 0.9)
\tif rig then rig:PlaySequence("COLAPSO") end
\tvfx("COLAPSO", { posicao = centro, escala = 1.3 })

\tlocal fim = os.clock() + CFG.TEMPO_COLAPSO
\tlocal proximoPulso = 0
\tlocal laco
\tlaco = guardar(RunService.Heartbeat:Connect(function()
\t\tlocal agora = os.clock()
\t\tif agora >= fim then
\t\t\tif laco then laco:Disconnect() end
\t\t\tvfx("IMPACTO_NOVA", { posicao = centro, escala = 1.4 })
\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
\t\t\t\taplicarDano(alvo, CFG.DANO_COLAPSO)
\t\t\tend
\t\t\treturn
\t\tend
\t\tif agora < proximoPulso then return end
\t\tproximoPulso = agora + 0.2

\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLAPSO, 14)) do
\t\t\tlocal corpo = alvo.Parent
\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\tif alvoRaiz then
\t\t\t\tlocal para = centro - alvoRaiz.Position
\t\t\t\tif para.Magnitude > 2 then
\t\t\t\t\tempurrar(alvo, para, CFG.PUXAO_COLAPSO, 0.18)
\t\t\t\tend
\t\t\tend
\t\tend
\tend))
end
''',
        "limpeza": "",
        "cutscene": False,
    },
    {
        "nome": "Astral Cometa",
        "sufixo": "AstralCometa",
        "titulo": "Astral Cometa",
        "m1": "Cometa — projétil incandescente com cauda",
        "extra": "Chuva Sideral — meteoros caem na área da mira",
        "cfg": """\tDANO_COMETA     = 29,
\tRAIO_COMETA     = 8,
\tALCANCE_COMETA  = 90,
\tVELOCIDADE      = 120,
\tDEBOUNCE_COMETA = 0.45,

\tMETEOROS        = 5,
\tDANO_METEORO    = 22,
\tRAIO_METEORO    = 12,
\tRAIO_CHUVA      = 22,
\tINTERVALO_METEORO = 0.22,
\tCD_CHUVA        = 22,

\tSFX_GOLPE       = "SlashSound",
\tSFX_EXTRA       = "TeleWarp",
""",
        "corpo": '''--- Cometa: o servidor não move geometria. Ele calcula a rota, manda UM beat
--- com origem, destino e tempo, e o cliente desenha a 60 Hz. Parte ancorada
--- movida por script de servidor replica a ~20 Hz sem interpolação.
function primaria()
\tif not Tool.Enabled or not raiz then return end
\tTool.Enabled = false
\ttask.delay(CFG.DEBOUNCE_COMETA, function() Tool.Enabled = true end)

\tlocal origem = raiz.Position + raiz.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0)
\tlocal direcao = raiz.CFrame.LookVector

\ttocar(CFG.SFX_GOLPE, 1.1)
\tif rig then rig:PlaySequence("COMETA") end

\tlocal filtro = RaycastParams.new()
\tfiltro.FilterType = Enum.RaycastFilterType.Exclude
\tfiltro.FilterDescendantsInstances = { personagem }
\tlocal batida = workspace:Raycast(origem, direcao * CFG.ALCANCE_COMETA, filtro)
\tlocal destino = batida and batida.Position or (origem + direcao * CFG.ALCANCE_COMETA)
\tlocal voo = (destino - origem).Magnitude / CFG.VELOCIDADE

\tvfx("COMETA", { posicao = origem, destino = destino, direcao = direcao,
\t\tduracao = voo, escala = 1.1 })

\t-- o dano acontece quando o cometa chega, não quando sai
\ttask.delay(voo, function()
\t\tif not (personagem and personagem.Parent) then return end
\t\tvfx("IMPACTO_NOVA", { posicao = destino, escala = 1.1 })
\t\tfor _, alvo in ipairs(alvosEm(destino, CFG.RAIO_COMETA, 8)) do
\t\t\taplicarDano(alvo, CFG.DANO_COMETA)
\t\tend
\tend)
end

--- Chuva Sideral: meteoros na área da mira, espalhados por ÂNGULO ÁUREO —
--- nunca math.random, para os dois clientes verem a mesma chuva.
function extra(mira)
\tif not podeExtra or not raiz then return end
\tpodeExtra = false
\ttask.delay(CFG.CD_CHUVA, function() podeExtra = true end)

\ttocar(CFG.SFX_EXTRA, 0.95)
\tif rig then rig:PlaySequence("CHUVA") end

\tlocal i = 0
\twhile i < CFG.METEOROS do
\t\tlocal indice = i
\t\tlocal ang = indice * 2.39996
\t\tlocal raioQueda = CFG.RAIO_CHUVA * math.sqrt((indice + 1) / CFG.METEOROS)
\t\tlocal ponto = mira + Vector3.new(math.cos(ang) * raioQueda, 0,
\t\t\tmath.sin(ang) * raioQueda)

\t\ttask.delay(indice * CFG.INTERVALO_METEORO, function()
\t\t\tif not (personagem and personagem.Parent) then return end
\t\t\tvfx("CHUVA", { posicao = ponto, escala = 1 })
\t\t\tfor _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_METEORO, 8)) do
\t\t\t\taplicarDano(alvo, CFG.DANO_METEORO)
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend
end
''',
        "limpeza": "",
        "cutscene": False,
    },
    {
        "nome": "Astral Constelacao",
        "sufixo": "AstralConstelacao",
        "titulo": "Astral Constelação",
        "m1": "Traço Sideral — marca quem for atingido",
        "extra": "Sentença da Constelação — liga as marcas e detona",
        "cfg": """\tDANO_TRACO      = 24,
\tALCANCE_TRACO   = 10,
\tDEBOUNCE_TRACO  = 0.4,
\tVIDA_MARCA      = 8,
\tMAX_MARCAS      = 6,

\tDANO_SENTENCA   = 26,
\tBONUS_TRES      = 40,     -- a partir de 3 marcas a sentença pesa mais
\tCD_SENTENCA     = 30,

\tSFX_GOLPE       = "SlashSound",
\tSFX_EXTRA       = "Antificated",
""",
        "corpo": '''local marcas = {}   -- [Humanoid] = { id = string, ate = number }

local function marcar(alvo)
\tlocal atual = marcas[alvo]
\tif atual then
\t\tatual.ate = os.clock() + CFG.VIDA_MARCA
\t\treturn
\tend

\tlocal quantas = 0
\tfor _ in pairs(marcas) do quantas = quantas + 1 end
\tif quantas >= CFG.MAX_MARCAS then return end

\tlocal id = "marca_" .. tostring(proximo())
\tmarcas[alvo] = { id = id, ate = os.clock() + CFG.VIDA_MARCA }

\tlocal corpo = alvo.Parent
\tvfx("TRACO", {
\t\talvoNome = corpo and corpo.Name,
\t\tdeslocamento = Vector3.new(0, 3, 0),
\t\tid = id, duracao = CFG.VIDA_MARCA,
\t})

\ttask.delay(CFG.VIDA_MARCA, function()
\t\tlocal reg = marcas[alvo]
\t\tif reg and os.clock() >= reg.ate then
\t\t\tmarcas[alvo] = nil
\t\t\tvfx("PARAR", { id = reg.id })
\t\tend
\tend)
end

function primaria()
\tif not Tool.Enabled or not raiz then return end
\tTool.Enabled = false
\ttask.delay(CFG.DEBOUNCE_TRACO, function() Tool.Enabled = true end)

\tlocal frente = raiz.CFrame.LookVector
\tlocal ponto = raiz.Position + frente * 3

\ttocar(CFG.SFX_GOLPE, 1)
\tif rig then rig:PlaySequence("TRACO") end
\tvfx("GOLPE", { posicao = ponto, direcao = frente, escala = 1 })

\tfor _, alvo in ipairs(alvosEm(ponto, CFG.ALCANCE_TRACO, 6)) do
\t\taplicarDano(alvo, CFG.DANO_TRACO)
\t\tmarcar(alvo)
\t\tvfx("IMPACTO", { posicao = ponto, escala = 0.9 })
\tend
end

--- Sentença: liga as marcas vivas e detona todas de uma vez. Sem marca não
--- acontece — e sem acontecer, NÃO gasta recarga.
function extra(mira)
\tif not podeExtra or not raiz then return end

\tlocal vivos, pontos = {}, {}
\tlocal agora = os.clock()
\tfor alvo, reg in pairs(marcas) do
\t\tif alvo and alvo.Health > 0 and agora < reg.ate then
\t\t\tlocal corpo = alvo.Parent
\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\tif alvoRaiz then
\t\t\t\ttable.insert(vivos, alvo)
\t\t\t\ttable.insert(pontos, alvoRaiz.Position + Vector3.new(0, 3, 0))
\t\t\tend
\t\tend
\tend
\tif #vivos == 0 then return end

\tpodeExtra = false
\ttask.delay(CFG.CD_SENTENCA, function() podeExtra = true end)

\ttocar(CFG.SFX_EXTRA, 0.9)
\tif rig then rig:PlaySequence("SENTENCA") end
\tvfx("SENTENCA", { pontos = pontos })

\tlocal dano = CFG.DANO_SENTENCA
\tif #vivos >= 3 then dano = dano + CFG.BONUS_TRES end

\tfor _, alvo in ipairs(vivos) do
\t\tlocal reg = marcas[alvo]
\t\tif reg then vfx("PARAR", { id = reg.id }) end
\t\tmarcas[alvo] = nil
\t\taplicarDano(alvo, dano)
\tend
end
''',
        "limpeza": '''\tfor _, reg in pairs(marcas) do
\t\tvfx("PARAR", { id = reg.id })
\tend
\tmarcas = {}
''',
        "cutscene": False,
    },
]


def main():
    for tool in TOOLS_GERADAS:
        nome = tool["nome"]
        # o nome de arquivo tem de bater com clonar_tool.nome_arquivo, que
        # troca tudo que não é \w por "_" — senão o montar não acha o .lua e
        # entrega o script vazio da base, calado
        arquivo = "%s_Server_V1.lua" % nome.replace(" ", "_")
        pasta = os.path.join(TOOLS, nome)
        if not os.path.isdir(pasta):
            print("pasta ausente: Tools/%s — rode preparar_astral.py antes" % nome)
            return 1

        texto = CABECALHO % {
            "arquivo": arquivo,
            "titulo": tool["titulo"],
            "m1": tool["m1"],
            "extra": tool["extra"],
            "cfg": tool["cfg"],
            "corpo": tool["corpo"],
            "limpeza": tool["limpeza"],
            "sufixo": tool["sufixo"],
            "regua": "═" * 63,
            "remote_cutscene": (
                'local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")\n'
                if tool["cutscene"] else ""),
        }

        with open(os.path.join(pasta, arquivo), "w", encoding="utf-8") as f:
            f.write(texto)
        print("  %-24s %5d linhas" % (nome, len(texto.splitlines())))

    print("")
    print("%d Server(s) gerado(s)." % len(TOOLS_GERADAS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
