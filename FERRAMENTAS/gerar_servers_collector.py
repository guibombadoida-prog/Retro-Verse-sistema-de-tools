#!/usr/bin/env python3
"""
gerar_servers_collector.py — Retro-Verse / Studios

Gera Server, Client, Poses e VFXModule das 6 Tools do conjunto COLLECTOR.

    python3 FERRAMENTAS/gerar_servers_collector.py

CONJUNTO AUTORAL — o que isso muda

    Nos conjuntos anteriores eu tinha um script de origem para copiar número de
    dano, raio e tempo. Aqui não tenho: os seis conceitos são do autor do
    projeto, e o balanceamento é decisão minha, declarada no `CFG` de cada Tool.
    Não há "linha do original" para citar, e não vou inventar uma.

    As poses também são autorais pelo mesmo motivo. Silhueta de conjurador com
    cajado — o Handle das seis é o `staff` do Xester.

DUAS COISAS QUE O CONCEITO PEDIA E A REGRA NÃO DEIXA

    1. `BillboardGui` sobre a cabeça do alvo (T2). Proibido dentro de Tool.
       O contador virou 20 selos em anel, um apagando por segundo — mesma
       leitura, no mundo 3D.

    2. Caveira "flutuante" movida por CFrame no servidor (T3). Parte ancorada
       empurrada por script de servidor replica a ~20 Hz picotado. A caveira voa
       por `AlignPosition`, que é física, e física replica interpolada.
"""

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
ANIMATOR = os.path.join(RAIZ, "ACERVO_RETROVERSE", "_AUTORAL_RetroVerse",
                        "R6_CFRAME", "R6CFrameAnimator_V2.lua")

REGUA = "═" * 62


# ═══════════════════════════════════════════════════════════════
# POSES — autorais, silhueta de conjurador com cajado
# ═══════════════════════════════════════════════════════════════

POSES = '''-- Poses.lua
-- ModuleScript "Poses" — conjunto COLLECTOR
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
-- ESTAS POSES SÃO AUTORAIS. Não há modelo de origem neste conjunto — os seis
-- conceitos são do autor do projeto. A silhueta é de conjurador com cajado na
-- mão direita, que é o Handle das seis (o `staff` do Xester Forma 2).

local P = {}

--═══════════════════════════════════════════════════════════════
-- BASE
--═══════════════════════════════════════════════════════════════

-- Guarda: cajado plantado ao lado, peso na perna de trás, cabeça baixa.
P.GUARDA = {
\tRightArm = CFrame.new(1.52, 0.18, -0.34) * CFrame.Angles(math.rad(38), math.rad(6), math.rad(9)),
\tLeftArm = CFrame.new(-1.48, -0.06, 0.12) * CFrame.Angles(math.rad(-8), math.rad(-6), math.rad(-11)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-9), math.rad(-7), 0),
\tHRP = CFrame.new(0, -0.08, 0) * CFrame.Angles(math.rad(3), math.rad(-12), 0),
}

--═══════════════════════════════════════════════════════════════
-- ERGUER — o pilar. Cajado sobe e crava no chão.
--═══════════════════════════════════════════════════════════════

P.ERGUER_CARGA = {
\tRightArm = CFrame.new(1.42, 0.86, 0.22) * CFrame.Angles(math.rad(158), math.rad(-14), math.rad(22)),
\tLeftArm = CFrame.new(-1.46, 0.42, -0.5) * CFrame.Angles(math.rad(62), math.rad(10), math.rad(-16)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-28), 0, 0),
\tHRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-12), 0, 0),
}

P.ERGUER_CRAVA = {
\tRightArm = CFrame.new(1.5, -0.22, -0.62) * CFrame.Angles(math.rad(24), math.rad(-6), math.rad(-14)),
\tLeftArm = CFrame.new(-1.5, -0.24, -0.58) * CFrame.Angles(math.rad(22), math.rad(6), math.rad(13)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(20), 0, 0),
\tHRP = CFrame.new(0, -0.34, 0) * CFrame.Angles(math.rad(17), 0, 0),
\tRightLeg = CFrame.new(0.5, -1.76, -0.38) * CFrame.Angles(math.rad(-22), 0, 0),
\tLeftLeg = CFrame.new(-0.5, -1.82, 0.26) * CFrame.Angles(math.rad(15), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SELAR — o julgamento. Braço estendido, palma para o alvo.
--═══════════════════════════════════════════════════════════════

P.SELAR_APONTA = {
\tRightArm = CFrame.new(1.56, 0.34, -1.32) * CFrame.Angles(math.rad(94), math.rad(8), math.rad(-6)),
\tLeftArm = CFrame.new(-1.44, 0.1, -0.22) * CFrame.Angles(math.rad(26), math.rad(-8), math.rad(-14)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(4), 0),
\tHRP = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(10), 0),
}

P.SELAR_FECHA = {
\tRightArm = CFrame.new(1.5, 0.26, -0.96) * CFrame.Angles(math.rad(76), math.rad(4), math.rad(-2)),
\tLeftArm = CFrame.new(-1.46, 0.04, -0.1) * CFrame.Angles(math.rad(12), math.rad(-4), math.rad(-9)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(2), 0),
\tHRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(0, math.rad(5), 0),
}

--═══════════════════════════════════════════════════════════════
-- SOLTAR — a caveira. Mão abre para baixo e larga.
--═══════════════════════════════════════════════════════════════

P.SOLTAR_ABRE = {
\tRightArm = CFrame.new(1.64, -0.12, -0.66) * CFrame.Angles(math.rad(56), math.rad(24), math.rad(-28)),
\tLeftArm = CFrame.new(-1.62, -0.14, -0.62) * CFrame.Angles(math.rad(54), math.rad(-24), math.rad(27)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(13), 0, 0),
\tHRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(10), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- DESFAZER — a perturbação. Corpo abre para trás, braços soltos.
--═══════════════════════════════════════════════════════════════

P.DESFAZER_ABRE = {
\tRightArm = CFrame.new(1.7, 0.44, 0.5) * CFrame.Angles(math.rad(-42), math.rad(18), math.rad(34)),
\tLeftArm = CFrame.new(-1.7, 0.42, 0.52) * CFrame.Angles(math.rad(-40), math.rad(-18), math.rad(-33)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-32), 0, 0),
\tHRP = CFrame.new(0, 0.12, 0) * CFrame.Angles(math.rad(-16), 0, 0),
}

P.DESFAZER_VOLTA = {
\tRightArm = CFrame.new(1.54, 0.12, -0.3) * CFrame.Angles(math.rad(30), math.rad(4), math.rad(8)),
\tLeftArm = CFrame.new(-1.54, 0.1, -0.28) * CFrame.Angles(math.rad(28), math.rad(-4), math.rad(-7)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(6), 0, 0),
\tHRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(4), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- ABRIR — o portal. Duas mãos descem juntas.
--═══════════════════════════════════════════════════════════════

P.ABRIR_ERGUE = {
\tRightArm = CFrame.new(1.46, 0.8, 0.1) * CFrame.Angles(math.rad(168), math.rad(-6), math.rad(12)),
\tLeftArm = CFrame.new(-1.46, 0.78, 0.08) * CFrame.Angles(math.rad(166), math.rad(6), math.rad(-11)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-36), 0, 0),
\tHRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-11), 0, 0),
}

P.ABRIR_DESCE = {
\tRightArm = CFrame.new(1.48, -0.3, -0.72) * CFrame.Angles(math.rad(18), math.rad(-10), math.rad(-20)),
\tLeftArm = CFrame.new(-1.48, -0.32, -0.7) * CFrame.Angles(math.rad(16), math.rad(10), math.rad(19)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), 0, 0),
\tHRP = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(20), 0, 0),
\tRightLeg = CFrame.new(0.5, -1.7, -0.42) * CFrame.Angles(math.rad(-25), 0, 0),
\tLeftLeg = CFrame.new(-0.5, -1.7, -0.4) * CFrame.Angles(math.rad(-24), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- APONTAR — o olho. Cajado ao alto, cabeça atrás dele.
--═══════════════════════════════════════════════════════════════

P.APONTAR_SOBE = {
\tRightArm = CFrame.new(1.38, 0.92, 0.06) * CFrame.Angles(math.rad(176), math.rad(-8), math.rad(16)),
\tLeftArm = CFrame.new(-1.5, -0.02, 0.08) * CFrame.Angles(math.rad(-6), math.rad(-4), math.rad(-10)),
\tHead = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-40), math.rad(6), 0),
\tHRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), 0, 0),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

\tERGUER = {
\t\t{ pose = "ERGUER_CARGA", time = 0.34, style = "Back", dir = "Out", tremor = 0.03, freq = 22, marca = "CARGA" },
\t\t{ pose = "ERGUER_CRAVA", time = 0.12, style = "Quint", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.3, style = "Quad", dir = "Out" },
\t},

\tSELAR = {
\t\t{ pose = "SELAR_APONTA", time = 0.22, style = "Back", dir = "Out", marca = "CARGA" },
\t\t{ pose = "SELAR_FECHA", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.26, style = "Quad", dir = "Out" },
\t},

\tSOLTAR = {
\t\t{ pose = "SOLTAR_ABRE", time = 0.18, style = "Back", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.24, style = "Quad", dir = "Out" },
\t},

\tDESFAZER = {
\t\t{ pose = "DESFAZER_ABRE", time = 0.28, style = "Quint", dir = "Out", marca = "CARGA" },
\t\t{ pose = "DESFAZER_VOLTA", time = 0.2, style = "Quad", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.26, style = "Quad", dir = "Out" },
\t},

\tABRIR = {
\t\t{ pose = "ABRIR_ERGUE", time = 0.32, style = "Quad", dir = "InOut", tremor = 0.025, freq = 18, marca = "CARGA" },
\t\t{ pose = "ABRIR_DESCE", time = 0.14, style = "Quint", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.3, style = "Quad", dir = "Out" },
\t},

\tAPONTAR = {
\t\t{ pose = "APONTAR_SOBE", time = 0.3, style = "Back", dir = "Out", marca = "GOLPE" },
\t\t{ pose = "GUARDA", time = 0.28, style = "Quad", dir = "Out" },
\t},
}

return P
'''


# ═══════════════════════════════════════════════════════════════
# ESQUELETO DO SERVER
# ═══════════════════════════════════════════════════════════════

ESQUELETO = '''-- %(arquivo)s
-- Script de servidor — %(titulo)s (conjunto COLLECTOR)
--
--   M1   %(m1)s
--
-- CONJUNTO AUTORAL. Não há script de origem para citar: o conceito é do autor
-- do projeto e os números do `CFG` são decisão de balanceamento, não cópia.
--
-- O QUE A REGRA IMPÔS AO CONCEITO
%(nota)s--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py. Editar aqui à mão faz as
-- seis derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
%(mira_remote)s
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
local ultimaMira = nil
local ativos = {}
local semente = 0

local function proximo()
\tsemente = semente + 1
\tif semente > 1000000 then semente = 1 end
\treturn semente
end

--- Faixa determinística, no lugar de `math.random(a, b)`.
local function naFaixa(minimo, maximo)
\tlocal onda = (math.sin(proximo() * 2.399963) + 1) * 0.5
\treturn minimo + (maximo - minimo) * onda
end

local function anguloDe(indice)
\treturn math.rad(137.507764 * indice)
end

local function vfx(tipo, dados)
\tVFXRemote:FireAllClients(tipo, dados)
end

--- Beat que SÓ o portador vê. Revelação de inimigo é informação dele, não do
--- servidor inteiro: mandar para todos entregaria a posição a quem está sendo
--- revelado.
local function vfxSo(tipo, dados)
\tif jogador then VFXRemote:FireClient(jogador, tipo, dados) end
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
-- Toda chamada é OPCIONAL: `<fallback>`.
-- A Tool sozinha num place vazio funciona por inteiro.
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
-- ATORDOAMENTO — trava e SEMPRE devolve
--
-- Guardar o valor anterior e devolver não é zelo: WalkSpeed zerado sem
-- restauração é jogador preso para sempre, e a Tool pode sumir no meio do
-- prazo. Por isso a devolução mora em `task.delay` E no cleanup.
--%(regua)s

local presos = {}

local function atordoar(alvoHum, tempo)
\tif not alvoHum or alvoHum.Health <= 0 then return end
\tif presos[alvoHum] then return end
\tpresos[alvoHum] = { anda = alvoHum.WalkSpeed, pula = alvoHum.JumpPower }
\talvoHum.WalkSpeed = 0
\talvoHum.JumpPower = 0
\ttask.delay(tempo, function()
\t\tlocal guardado = presos[alvoHum]
\t\tif not guardado then return end
\t\tpresos[alvoHum] = nil
\t\tif alvoHum.Parent then
\t\t\talvoHum.WalkSpeed = guardado.anda
\t\t\talvoHum.JumpPower = guardado.pula
\t\tend
\tend)
end

local function soltarPresos()
\tfor alvoHum, guardado in pairs(presos) do
\t\tif alvoHum and alvoHum.Parent then
\t\t\talvoHum.WalkSpeed = guardado.anda
\t\t\talvoHum.JumpPower = guardado.pula
\t\tend
\tend
\tpresos = {}
end

--%(regua)s
-- MOLDES — o asset vem de DENTRO da Tool (Regra nº 1)
--%(regua)s

local function molde(nome)
\treturn Moldes:FindFirstChild(nome, true)
end

--- Clona um molde para o mundo já visível. O molde fica apagado dentro da Tool.
local function porNoMundo(nome, cframe, vida)
\tlocal base = molde(nome)
\tif not base then return nil end
\tlocal copia = base:Clone()
\tfor _, peca in ipairs(copia:GetDescendants()) do
\t\tif peca:IsA("BasePart") then peca.Transparency = 0 end
\tend
\tif copia:IsA("BasePart") then copia.Transparency = 0 end
\tcopia.Parent = workspace
\tif copia:IsA("BasePart") then
\t\tcopia.CFrame = cframe
\telseif copia:IsA("Model") then
\t\tif not copia.PrimaryPart then
\t\t\tcopia.PrimaryPart = copia:FindFirstChildWhichIsA("BasePart")
\t\tend
\t\tif copia.PrimaryPart then copia:PivotTo(cframe) end
\tend
\tDebris:AddItem(copia, vida or 8)
\treturn copia
end

--%(regua)s
-- PORTA DE ENTRADA
--%(regua)s

local function podeUsar()
\tif not (personagem and humanoide and humanoide.Health > 0 and raiz) then
\t\treturn false
\tend
\treturn os.clock() - ultimoUso >= CFG.RECARGA
end

--- Mira: o cliente manda para onde aponta; o servidor CORTA pelo alcance.
--- Payload de cliente é entrada, nunca verdade.
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
-- ANIMAÇÃO — o rig é DO SERVIDOR, e é por isso que ele existe aqui
--
-- `Instance.new("Weld")` criado num LocalScript é instância LOCAL: não replica.
-- Enquanto o rig morou no cliente, os outros jogadores viam o portador
-- executando a habilidade PARADO. Weld criado no servidor replica, e a mudança
-- de `C0` replica junto — então a pose aparece para a sala inteira.
--
-- O beat volta para os clientes por VFXRemote: quem desenha o brilho na mão
-- continua sendo cada cliente, a 60 Hz.
--%(regua)s

local function montarRig()
\tif rig then return rig end
\tif not personagem then return nil end
\trig = Animator.new(personagem, "%(sufixo)s", Poses, Poses.SEQUENCIAS)
\treturn rig
end

local function animar()
\tlocal atual = montarRig()
\tif not atual then return end
\tatual:PlaySequence("%(seq)s", function(passo)
\t\tif passo.marca then vfx("BEAT", { marca = passo.marca }) end
\tend)
end

local function desmontarRig()
\tif not rig then return end
\trig:CancelSequence()
\trig:ReleaseLegs()
end

--%(regua)s
-- CICLO DE VIDA
--%(regua)s

local function limpar()
\tsoltarTudo()
\tsoltarPresos()
%(ao_guardar)send

Tool.Equipped:Connect(function()
\tpersonagem = Tool.Parent
\tjogador = Players:GetPlayerFromCharacter(personagem)
\thumanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
\traiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
end)

Tool.Unequipped:Connect(function()
\tultimaMira = nil
\tlimpar()
end)

Tool.Activated:Connect(function()
\tif not podeUsar() then return end
\tultimoUso = os.clock()
\tprimaria(%(passa_mira)s)
end)

--- `Destroying`, não `AncestryChanged`: guardar na mochila troca o pai sem
--- destruir nada, e o cleanup não pode disparar aí.
Tool.Destroying:Connect(function()
\tlimpar()
\tif rig then
\t\trig:Destroy()
\t\trig = nil
\tend
end)

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- ISTO ESTAVA FORA DO GERADOR — o mesmo defeito que o DRAMA teve, e pela mesma
-- causa: a ligação foi enxertada nos arquivos PRONTOS por
-- `FERRAMENTAS/ligar_deposito.py`, e a primeira regeneração a perdeu. As 6
-- Tools voltaram a não ter depósito, e só o `verificar_deposito_vfx.py`
-- percebeu.
--
-- Enxerto que não volta para o gerador é conserto que dura até a próxima
-- geração. Agora ele mora aqui.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
'''

ESCUTA_MIRA = '''
--%(regua)s
-- MIRA — o mouse é do cliente, a conferência é do servidor
--%(regua)s

MiraRemote.OnServerEvent:Connect(function(quem, ponto)
\tif quem ~= jogador then return end
\tif typeof(ponto) ~= "Vector3" then return end
\tultimaMira = ponto
end)
'''


# ═══════════════════════════════════════════════════════════════
# OS SEIS CORPOS
# ═══════════════════════════════════════════════════════════════

CORPOS = {}

CORPOS["Pilar das Lamentacoes"] = '''--%(regua)s
-- PRIMÁRIA — o Pilar das Lamentações
--
-- O pilar é uma Part ANCORADA que nasce e não se move mais: quem cresce e
-- gira é a cópia do cliente. Servidor que empurra geometria por quadro replica
-- a ~20 Hz picotado — o pilar aqui só existe como hitbox e âncora do som.
--%(regua)s

local pilar = nil

local function derrubarPilar()
\tif pilar then
\t\tpilar.Parent = nil
\t\tpilar = nil
\tend
end

local function primaria(destino)
\tlocal centro = mirar(destino)
\tderrubarPilar()

\tpilar = Instance.new("Part")
\tpilar.Name = "PilarDasLamentacoes"
\tpilar.Shape = Enum.PartType.Cylinder
\tpilar.Size = Vector3.new(CFG.ALTURA, CFG.GROSSURA, CFG.GROSSURA)
\tpilar.CFrame = CFrame.new(centro + Vector3.new(0, CFG.ALTURA / 2, 0))
\t\t* CFrame.Angles(0, 0, math.rad(90))
\tpilar.Material = Enum.Material.Slate
\tpilar.Color = Color3.fromRGB(24, 22, 30)
\tpilar.Anchored = true
\tpilar.CanCollide = false
\tpilar.Parent = workspace
\tDebris:AddItem(pilar, CFG.DURACAO + 1)

\tvfx("PILAR_ERGUE", { posicao = centro, altura = CFG.ALTURA,
\t\tgrossura = CFG.GROSSURA, duracao = CFG.DURACAO })

\t-- o grito: um pulso por vez, com o atordoamento junto
\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (pilar and pilar.Parent and personagem) then return end
\t\t\tvfx("PILAR_GRITO", { posicao = centro, passo = indice })
\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 12)) do
\t\t\t\taplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\t\t\t\t-- o atordoamento é curto e reaplicado a cada grito: assim ele
\t\t\t\t-- solta sozinho se o alvo sair do alcance, sem prender ninguém
\t\t\t\tatordoar(alvo, CFG.ATORDOAMENTO)
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.DURACAO, function()
\t\tvfx("PILAR_CAI", { posicao = centro })
\t\tderrubarPilar()
\tend)
end
'''

CORPOS["Julgamento Final"] = '''--%(regua)s
-- PRIMÁRIA — o Julgamento Final
--
-- Marca um alvo por 20 s. Se o alvo NÃO matar o portador nesse prazo, leva
-- 250. Se matar, a sentença cai junto com quem a proferiu.
--
-- O contador não é GUI: `BillboardGui` é proibido dentro de Tool. São 20 selos
-- em anel sobre a cabeça do alvo, e o cliente apaga um por segundo. Quem conta
-- é o SERVIDOR — o cliente só desenha o que já foi contado.
--
-- Três coisas cancelam a sentença, e todas precisam existir: o portador morre,
-- o alvo morre antes, ou a Tool sai da mão.
--%(regua)s

local sentenca = nil

local function encerrarSentenca(motivo)
\tif not sentenca then return end
\tlocal alvo = sentenca.alvo
\tfor _, conexao in ipairs(sentenca.lacos) do
\t\tif conexao.Connected then conexao:Disconnect() end
\tend
\tsentenca = nil
\tvfx("SELO_TIRA", { alvo = alvo and alvo.Parent or nil, motivo = motivo })
end

local function executar()
\tif not sentenca then return end
\tlocal alvo = sentenca.alvo
\tencerrarSentenca("executada")
\tif not (alvo and alvo.Parent and alvo.Health > 0) then return end
\tvfx("SELO_EXECUTA", { alvo = alvo.Parent })
\t-- passa pelo Núcleo como qualquer outro dano: 250 é o BRUTO, não o final
\taplicarDano(alvo, CFG.SENTENCA)
end

local function primaria(destino)
\tlocal ponto = mirar(destino)
\tlocal perto = alvosEm(ponto, CFG.RAIO_BUSCA, 1)
\tlocal alvo = perto[1]
\tif not alvo then
\t\tultimoUso = 0   -- sem alvo não há julgamento: devolve a recarga
\t\treturn
\tend

\tencerrarSentenca("substituida")

\tlocal corpo = alvo.Parent
\tsentenca = { alvo = alvo, restam = CFG.SELOS, lacos = {} }

\tvfx("SELO_POE", { alvo = corpo, selos = CFG.SELOS,
\t\taltura = CFG.ALTURA_SELO, raio = CFG.RAIO_SELO })

\t-- o alvo morreu antes do prazo: sentença cumprida por outra via
\ttable.insert(sentenca.lacos, alvo.Died:Connect(function()
\t\tencerrarSentenca("alvo caiu")
\tend))

\t-- o portador morreu: o alvo cumpriu a condição, a sentença some
\tif humanoide then
\t\ttable.insert(sentenca.lacos, humanoide.Died:Connect(function()
\t\t\tencerrarSentenca("portador caiu")
\t\tend))
\tend

\tlocal marcaDesta = sentenca
\tlocal i = 1
\twhile i <= CFG.SELOS do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.TIQUE, function()
\t\t\tif sentenca ~= marcaDesta then return end
\t\t\tsentenca.restam = CFG.SELOS - indice
\t\t\tvfx("SELO_TIQUE", { alvo = corpo, restam = sentenca.restam })
\t\t\tif sentenca.restam <= 0 then executar() end
\t\tend)
\t\ti = i + 1
\tend
end
'''

CORPOS["Atraso Mortal"] = '''--%(regua)s
-- PRIMÁRIA — o Atraso Mortal
--
-- Uma caveira lenta que persegue e bombardeia. "Atraso" é o nome certo: ela
-- não alcança ninguém correndo — ela cobra o espaço com as bombas.
--
-- A caveira voa por `AlignPosition`, não por CFrame de servidor. Física
-- replica interpolada; CFrame ancorado empurrado por script replica picotado.
--%(regua)s

local caveiras = {}

local function dispensarCaveiras()
\tfor _, peca in ipairs(caveiras) do
\t\tif peca and peca.Parent then peca.Parent = nil end
\tend
\tcaveiras = {}
end

local function largarBomba(origem, alvoPos)
\tlocal base = molde("Bomba")
\tif not base then return end
\tlocal bomba = base:Clone()
\tbomba.Transparency = 0
\tbomba.Anchored = false
\tbomba.CanCollide = false
\tbomba.Massless = true
\tbomba.CFrame = CFrame.new(origem)
\tbomba.Parent = workspace
\tDebris:AddItem(bomba, CFG.VIDA_BOMBA + 1)

\tlocal delta = alvoPos - origem
\tlocal impulso = Instance.new("BodyVelocity")
\timpulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
\timpulso.Velocity = delta.Unit * CFG.VELOCIDADE_BOMBA
\t\t+ Vector3.new(0, CFG.ARCO, 0)
\timpulso.Parent = bomba
\tDebris:AddItem(impulso, 0.35)

\tvfx("BOMBA_SAI", { origem = origem })

\t-- estoura ao tocar Humanoid OU por prazo, o que vier primeiro
\tlocal gasta = false
\tlocal function estourar()
\t\tif gasta then return end
\t\tgasta = true
\t\tlocal onde = bomba.Position
\t\tbomba.Parent = nil
\t\tvfx("BOMBA_ESTOURA", { posicao = onde })
\t\tgolpearArea(onde, CFG.RAIO_BOMBA, CFG.DANO_MIN, CFG.DANO_MAX,
\t\t\tCFG.EMPURRAO, 8)
\tend

\tlocal ligacao
\tligacao = bomba.Touched:Connect(function(parte)
\t\tlocal modelo = parte:FindFirstAncestorOfClass("Model")
\t\tif not modelo or modelo == personagem then return end
\t\tif not modelo:FindFirstChildOfClass("Humanoid") then return end
\t\tif ligacao.Connected then ligacao:Disconnect() end
\t\testourar()
\tend)
\tguardar(ligacao)
\ttask.delay(CFG.VIDA_BOMBA, estourar)
end

local function primaria(destino)
\tif #caveiras >= CFG.LIMITE then return end
\tlocal ponto = mirar(destino)

\tlocal caveira = porNoMundo("skully",
\t\tCFrame.new(ponto + Vector3.new(0, CFG.VOO, 0)), CFG.VIDA)
\tif not caveira then return end
\tcaveira.Name = "CaveiraDoAtraso"
\ttable.insert(caveiras, caveira)
\tvfx("CAVEIRA_NASCE", { posicao = ponto + Vector3.new(0, CFG.VOO, 0) })

\tlocal corpo = caveira:IsA("Model")
\t\tand (caveira.PrimaryPart or caveira:FindFirstChildWhichIsA("BasePart"))
\t\tor caveira
\tif not corpo then return end

\t-- solta as peças e prende tudo na principal, para a física ter um corpo só
\tfor _, peca in ipairs(caveira:GetDescendants()) do
\t\tif peca:IsA("BasePart") then
\t\t\tpeca.Anchored = false
\t\t\tpeca.CanCollide = false
\t\t\tpeca.Massless = true
\t\t\tif peca ~= corpo then
\t\t\t\tlocal solda = Instance.new("WeldConstraint")
\t\t\t\tsolda.Part0 = corpo
\t\t\t\tsolda.Part1 = peca
\t\t\t\tsolda.Parent = corpo
\t\t\tend
\t\tend
\tend
\tcorpo.Massless = false

\tlocal apoio = Instance.new("Attachment")
\tapoio.Parent = corpo
\tlocal voo = Instance.new("AlignPosition")
\tvoo.Attachment0 = apoio
\tvoo.Mode = Enum.PositionAlignmentMode.OneAttachment
\tvoo.MaxForce = CFG.FORCA_VOO
\tvoo.Responsiveness = CFG.AGILIDADE
\tvoo.Position = corpo.Position
\tvoo.Parent = corpo

\tlocal passos = math.floor(CFG.VIDA / CFG.PASSO)
\tlocal i = 1
\twhile i <= passos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.PASSO, function()
\t\t\tif not (caveira.Parent and corpo.Parent and personagem) then return end
\t\t\tlocal perto = alvosEm(corpo.Position, CFG.VISAO, 1)
\t\t\tlocal presa = perto[1]
\t\t\tif not presa then return end
\t\t\tlocal presaCorpo = presa.Parent
\t\t\tlocal presaRaiz = presaCorpo
\t\t\t\tand presaCorpo:FindFirstChild("HumanoidRootPart")
\t\t\tif not presaRaiz then return end

\t\t\t-- persegue devagar: o alvo sempre à frente, nunca alcançado
\t\t\tlocal rumo = (presaRaiz.Position - corpo.Position)
\t\t\tif rumo.Magnitude > 1 then
\t\t\t\tvoo.Position = corpo.Position + rumo.Unit * CFG.AVANCO
\t\t\t\t\t+ Vector3.new(0, CFG.VOO * 0.1, 0)
\t\t\tend
\t\t\tif indice %% CFG.CADA_QUANTOS == 0 then
\t\t\t\tlargarBomba(corpo.Position, presaRaiz.Position)
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.VIDA, function()
\t\tfor indice, guardada in ipairs(caveiras) do
\t\t\tif guardada == caveira then
\t\t\t\ttable.remove(caveiras, indice)
\t\t\t\tbreak
\t\t\tend
\t\tend
\tend)
end
'''

CORPOS["Perturbacao"] = '''--%(regua)s
-- PRIMÁRIA — a Perturbação
--
-- Seis segundos incorpóreo: o dano que chegaria é ABSORVIDO em vez de sofrido,
-- e no fim volta como golpe em área. Quanto mais te bateram, maior o troco.
--
-- Como a absorção funciona, e por que ela tem teto:
--   `HealthChanged` avisa DEPOIS que a vida caiu. O servidor devolve a vida e
--   guarda o quanto caiu. Sem teto, dois jogadores batendo juntos por 6 s
--   viram um golpe de área impossível de sobreviver — `CFG.TETO` corta isso.
--
-- E a devolução é obrigatória: se a Tool sair da mão no meio, o estado tem de
-- desligar, senão fica um jogador imortal em campo.
--%(regua)s

local desfeito = false
local absorvido = 0
local lacoVida = nil

local function refazer(devolver)
\tif not desfeito then return end
\tdesfeito = false
\tif lacoVida and lacoVida.Connected then lacoVida:Disconnect() end
\tlacoVida = nil

\tlocal troco = math.min(absorvido, CFG.TETO)
\tabsorvido = 0
\tvfx("PERTURBA_VOLTA", {})

\tif not devolver then return end
\tif not (personagem and raiz and humanoide and humanoide.Health > 0) then return end
\tif troco <= 0 then return end

\tvfx("PERTURBA_DEVOLVE", { posicao = raiz.Position, escala = troco / CFG.TETO })
\tfor _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO, 14)) do
\t\taplicarDano(alvo, troco * CFG.CONVERSAO)
\t\tlocal corpo = alvo.Parent
\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\tif alvoRaiz then
\t\t\tempurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.EMPURRAO, 0.3)
\t\tend
\tend
end

local function primaria()
\tif desfeito then return end
\tdesfeito = true
\tabsorvido = 0

\tlocal vidaAntes = humanoide.Health
\tvfx("PERTURBA_DESFAZ", { duracao = CFG.DURACAO })

\tlacoVida = humanoide.HealthChanged:Connect(function(agora)
\t\tif not desfeito then return end
\t\tif agora >= vidaAntes then
\t\t\tvidaAntes = agora
\t\t\treturn
\t\tend
\t\tlocal perdido = vidaAntes - agora
\t\tabsorvido = absorvido + perdido
\t\t-- devolve a vida: o golpe foi absorvido, não sofrido
\t\thumanoide.Health = math.min(vidaAntes, humanoide.MaxHealth)
\t\tvfx("PERTURBA_ABSORVE", { posicao = raiz and raiz.Position or nil })
\tend)
\tguardar(lacoVida)

\ttask.delay(CFG.DURACAO, function()
\t\trefazer(true)
\tend)
end
'''

CORPOS["Portal do Submundo"] = '''--%(regua)s
-- PRIMÁRIA — o Portal do Submundo
--
-- Um disco no chão que prende com correntes quem pisar. O portal é hitbox e
-- âncora; as correntes são desenho do cliente.
--
-- O preso é solto de três jeitos, e os três precisam existir: o prazo dele
-- acaba, o portal fecha, ou a Tool sai da mão. Corrente sem chave é jogador
-- travado para sempre.
--%(regua)s

local portal = nil

local function fecharPortal()
\tif portal then
\t\tlocal onde = portal.Position
\t\tportal.Parent = nil
\t\tportal = nil
\t\tvfx("PORTAL_FECHA", { posicao = onde })
\tend
\tsoltarPresos()
end

local function primaria(destino)
\tlocal centro = mirar(destino)
\tfecharPortal()

\tportal = Instance.new("Part")
\tportal.Name = "PortalDoSubmundo"
\tportal.Shape = Enum.PartType.Cylinder
\tportal.Size = Vector3.new(CFG.ESPESSURA, CFG.RAIO * 2, CFG.RAIO * 2)
\tportal.CFrame = CFrame.new(centro) * CFrame.Angles(0, 0, math.rad(90))
\tportal.Material = Enum.Material.Neon
\tportal.Color = Color3.fromRGB(28, 20, 34)
\tportal.Transparency = 0.25
\tportal.Anchored = true
\tportal.CanCollide = false
\tportal.Parent = workspace
\tDebris:AddItem(portal, CFG.DURACAO + 1)

\tvfx("PORTAL_ABRE", { posicao = centro, raio = CFG.RAIO,
\t\tduracao = CFG.DURACAO })

\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (portal and portal.Parent and personagem) then return end
\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
\t\t\t\taplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
\t\t\t\t-- prende por pouco e reaplica: quem sai do disco se solta sozinho
\t\t\t\tatordoar(alvo, CFG.PRISAO)
\t\t\t\tlocal corpo = alvo.Parent
\t\t\t\tlocal alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\t\t\t\tif alvoRaiz then
\t\t\t\t\tvfx("CORRENTE_PRENDE", { alvo = corpo, ancora = centro,
\t\t\t\t\t\telos = CFG.ELOS })
\t\t\t\t\tempurrar(alvo, centro - alvoRaiz.Position, CFG.PUXAO, 0.2)
\t\t\t\tend
\t\t\tend
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.DURACAO, fecharPortal)
end
'''

CORPOS["Olho do Vigia"] = '''--%(regua)s
-- PRIMÁRIA — o Olho do Vigia
--
-- Um olho gigante que revela inimigos através das paredes.
--
-- A revelação é do PORTADOR, e só dele. O servidor manda a lista por
-- `FireClient`, não `FireAllClients`: transmitir para todos entregaria a
-- posição de quem está sendo revelado justamente a quem foi revelado.
--
-- Quem desenha o contorno é o cliente, com `Highlight` — é a única forma
-- honesta de "ver através da parede" sem mexer em câmera nem em ScreenGui.
--%(regua)s

local olho = nil

local function fecharOlho()
\tif olho then
\t\tlocal onde = olho.Position
\t\tolho.Parent = nil
\t\tolho = nil
\t\tvfx("OLHO_FECHA", { posicao = onde })
\tend
\tvfxSo("REVELAR", { alvos = {} })
end

local function primaria(destino)
\tlocal centro = mirar(destino) + Vector3.new(0, CFG.ALTURA, 0)
\tfecharOlho()

\tolho = Instance.new("Part")
\tolho.Name = "OlhoDoVigia"
\tolho.Shape = Enum.PartType.Ball
\tolho.Size = Vector3.new(CFG.TAMANHO, CFG.TAMANHO, CFG.TAMANHO)
\tolho.CFrame = CFrame.new(centro)
\tolho.Material = Enum.Material.Neon
\tolho.Color = Color3.fromRGB(226, 214, 198)
\tolho.Anchored = true
\tolho.CanCollide = false
\tolho.Parent = workspace
\tDebris:AddItem(olho, CFG.DURACAO + 1)

\tvfx("OLHO_ABRE", { posicao = centro, tamanho = CFG.TAMANHO,
\t\tduracao = CFG.DURACAO })

\tlocal pulsos = math.floor(CFG.DURACAO / CFG.INTERVALO)
\tlocal i = 1
\twhile i <= pulsos do
\t\tlocal indice = i
\t\ttask.delay(indice * CFG.INTERVALO, function()
\t\t\tif not (olho and olho.Parent and personagem) then return end
\t\t\tlocal vistos = {}
\t\t\tfor _, alvo in ipairs(alvosEm(centro, CFG.VISAO, CFG.LIMITE)) do
\t\t\t\tif alvo.Parent then table.insert(vistos, alvo.Parent) end
\t\t\tend
\t\t\tvfxSo("REVELAR", { alvos = vistos, duracao = CFG.INTERVALO * 1.6 })
\t\t\tvfx("OLHO_VARRE", { posicao = centro, passo = indice })
\t\tend)
\t\ti = i + 1
\tend

\ttask.delay(CFG.DURACAO, fecharOlho)
end
'''


# ═══════════════════════════════════════════════════════════════
# TABELA — CFG por Tool
#
# Sem script de origem, estes números são decisão de balanceamento minha.
# Estão aqui, num bloco só, para você trocar sem caçar no corpo do script.
# ═══════════════════════════════════════════════════════════════

TABELA = {
    "Pilar das Lamentacoes": {
        "seq": "ERGUER", "arquetipo": "ESPECTRAL", "mira": True,
        "m1": "Ergue o pilar no ponto mirado; grita por 8s.",
        "nota": ["--   nada — o conceito coube inteiro"],
        "ao_guardar": "\tderrubarPilar()\n",
        "cfg": [("RECARGA", "26"), ("ALCANCE", "70"), ("ALTURA", "40"),
                ("GROSSURA", "6"), ("DURACAO", "8"), ("INTERVALO", "0.8"),
                ("RAIO", "26"), ("DANO_MIN", "9"), ("DANO_MAX", "16"),
                ("ATORDOAMENTO", "1.1")],
    },
    "Julgamento Final": {
        "seq": "SELAR", "arquetipo": "ESPECTRAL", "mira": True,
        "m1": "Marca um alvo com 20 selos; 250 se ele nao te matar em 20s.",
        "nota": [
            "--   `BillboardGui` sobre a cabeca do alvo e proibido dentro de Tool",
            "--   (REGRA_CAMERA_DE_CUTSCENE). O contador virou 20 selos em anel,",
            "--   um apagando por segundo — mesma leitura, no mundo 3D.",
        ],
        "ao_guardar": '\tencerrarSentenca("tool guardada")\n',
        "cfg": [("RECARGA", "60"), ("ALCANCE", "90"), ("RAIO_BUSCA", "10"),
                ("SELOS", "20"), ("TIQUE", "1"), ("SENTENCA", "250"),
                ("ALTURA_SELO", "4"), ("RAIO_SELO", "2.2")],
    },
    "Atraso Mortal": {
        "seq": "SOLTAR", "arquetipo": "ESPECTRAL", "mira": True,
        "m1": "Solta a caveira que persegue devagar e bombardeia.",
        "nota": [
            "--   a caveira voa por `AlignPosition`, nao por CFrame de servidor:",
            "--   fisica replica interpolada, CFrame ancorado replica picotado.",
        ],
        "ao_guardar": "\tdispensarCaveiras()\n",
        "cfg": [("RECARGA", "34"), ("ALCANCE", "80"), ("LIMITE", "2"),
                ("VIDA", "22"), ("VOO", "7"), ("PASSO", "0.3"),
                ("AVANCO", "5"), ("VISAO", "70"), ("CADA_QUANTOS", "6"),
                ("FORCA_VOO", "24000"), ("AGILIDADE", "12"),
                ("VELOCIDADE_BOMBA", "58"), ("ARCO", "16"),
                ("VIDA_BOMBA", "2.4"), ("RAIO_BOMBA", "16"),
                ("DANO_MIN", "16"), ("DANO_MAX", "26"), ("EMPURRAO", "48")],
    },
    "Perturbacao": {
        "seq": "DESFAZER", "arquetipo": "ESPECTRAL", "mira": False,
        "m1": "Fica incorporeo 6s, absorve o dano e devolve em area.",
        "nota": [
            "--   a absorcao tem TETO. Sem ele, dois jogadores batendo por 6 s",
            "--   viram um golpe de area impossivel de sobreviver.",
        ],
        "ao_guardar": "\trefazer(false)\n",
        "cfg": [("RECARGA", "30"), ("ALCANCE", "40"), ("DURACAO", "6"),
                ("TETO", "220"), ("CONVERSAO", "0.75"), ("RAIO", "24"),
                ("EMPURRAO", "70")],
    },
    "Portal do Submundo": {
        "seq": "ABRIR", "arquetipo": "ESPECTRAL", "mira": True,
        "m1": "Abre o portal; correntes prendem quem pisar nele.",
        "nota": [
            "--   corrente nao existe em asset nenhum do Acervo. O elo e a malha",
            "--   de anel 3270017 repetida — a unica peca desenhada do conjunto.",
        ],
        "ao_guardar": "\tfecharPortal()\n",
        "cfg": [("RECARGA", "38"), ("ALCANCE", "75"), ("RAIO", "14"),
                ("ESPESSURA", "0.6"), ("DURACAO", "10"), ("INTERVALO", "0.7"),
                ("DANO_MIN", "7"), ("DANO_MAX", "13"), ("PRISAO", "0.95"),
                ("PUXAO", "26"), ("ELOS", "8")],
    },
    "Olho do Vigia": {
        "seq": "APONTAR", "arquetipo": "ESPECTRAL", "mira": True,
        "m1": "Abre o olho; revela inimigos atraves das paredes por 14s.",
        "nota": [
            "--   a revelacao vai por FireClient, so para o portador. Mandar para",
            "--   todos entregaria a posicao de quem esta sendo revelado a ele.",
        ],
        "ao_guardar": "\tfecharOlho()\n",
        "cfg": [("RECARGA", "28"), ("ALCANCE", "70"), ("ALTURA", "14"),
                ("TAMANHO", "12"), ("DURACAO", "14"), ("INTERVALO", "0.9"),
                ("VISAO", "180"), ("LIMITE", "12")],
    },
}


def gerar_server(nome, dados):
    return ESQUELETO % {
        "arquivo": "%s_Server_V1.lua" % nome.replace(" ", ""),
        "titulo": nome,
        "m1": dados["m1"],
        "nota": "".join("%s\n" % linha for linha in dados["nota"]),
        "regua": REGUA,
        "arquetipo": dados["arquetipo"],
        "cfg": "".join("\t%s = %s,\n" % (c, v) for c, v in dados["cfg"]),
        "corpo": CORPOS[nome] % {"regua": REGUA},
        "mira_remote": ('local MiraRemote = Tool:WaitForChild("MiraRemote")\n'
                        if dados["mira"] else ""),
        "escuta_mira": ((ESCUTA_MIRA % {"regua": REGUA})
                        if dados["mira"] else ""),
        "passa_mira": "mirar(ultimaMira)" if dados["mira"] else "",
        "ao_guardar": dados["ao_guardar"],
        "sufixo": nome.replace(" ", ""),
        "seq": dados["seq"],
    }


# ═══════════════════════════════════════════════════════════════
# CLIENT
# ═══════════════════════════════════════════════════════════════

CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — %(titulo)s (conjunto COLLECTOR)
--
-- POR QUE NÃO É LocalScript, E POR QUE ISSO IMPORTA
--
--   LocalScript dentro de uma Tool só roda para o jogador cujo Character a
--   contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
--   mundo — mas o único ouvinte que existe é o de quem está segurando. Foi por
--   isso que, dos Escudos até aqui, o efeito aparecia só para o portador.
--
--   `Script` com `RunContext = Client` roda em TODO cliente, onde quer que
--   esteja na árvore, inclusive dentro da Tool de outro jogador. Cada cliente
--   desenha o mesmo efeito, a 60 Hz, com custo de rede zero — e nada saiu de
--   dentro da Tool, então a Regra nº 1 continua de pé.
--
-- O QUE É DE TODO MUNDO, E O QUE É SÓ DO DONO
--
--   De todo mundo: desenhar o VFX. É o ponto.
--   Só do dono:    mandar a mira. Sem esta trava, os cinco clientes da sala
--                  mandariam a mira DELES para a Tool alheia.
--
--   A animação NÃO está aqui: o rig é do servidor, porque Weld criado no
--   cliente não replica e os outros jogadores viam o portador parado.
--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py.

local Players = game:GetService("Players")

local jogador = Players.LocalPlayer

local Tool      = script.Parent
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Moldes    = Tool:WaitForChild("Moldes")
local VFX       = require(Tool:WaitForChild("VFXModule"))
%(mira_remote)s
local ALCANCE_MIRA = %(alcance)s
local RITMO_MIRA = 0.1

local portador = nil
local mandandoMira = false

--- Quem está com a Tool na mão. É `Tool.Parent` quando equipada, e nil quando
--- ela está na mochila.
local function donoDaTool()
\tlocal pai = Tool.Parent
\tif not pai then return nil end
\tlocal humano = pai:FindFirstChildOfClass("Humanoid")
\tif not humano then return nil end
\treturn pai
end

local function souODono()
\tlocal corpo = donoDaTool()
\tif not corpo then return false end
\treturn Players:GetPlayerFromCharacter(corpo) == jogador
end

--%(regua)s
-- DESENHO — este trecho roda em TODOS os clientes
--%(regua)s

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
\tif tipo == "BEAT" then
\t\tVFX.beat(dados and dados.marca, portador or donoDaTool())
\t\treturn
\tend
\tVFX.desenhar(tipo, dados or {}, Moldes, portador or donoDaTool())
end)

--%(regua)s
-- MIRA — só o dono manda
--%(regua)s

local rato = nil

local function pontoMirado()
\tlocal corpo = portador
\tlocal raiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
\tif not (raiz and rato) then return nil end
\tlocal alvo = rato.Hit and rato.Hit.Position
\tif not alvo then return raiz.Position + raiz.CFrame.LookVector * 20 end
\tlocal delta = alvo - raiz.Position
\tif delta.Magnitude > ALCANCE_MIRA then
\t\treturn raiz.Position + delta.Unit * ALCANCE_MIRA
\tend
\treturn alvo
end

local function comecarMira()
\tif mandandoMira or not MiraRemote then return end
\tmandandoMira = true
\trato = rato or (jogador and jogador:GetMouse())
\ttask.spawn(function()
\t\twhile mandandoMira do
\t\t\tlocal ponto = pontoMirado()
\t\t\tif ponto then MiraRemote:FireServer(ponto) end
\t\t\ttask.wait(RITMO_MIRA)
\t\tend
\tend)
end

--%(regua)s
-- CICLO
--%(regua)s

local function aoEquipar()
\tportador = donoDaTool()
\tif souODono() then comecarMira() end
end

local function aoGuardar()
\tmandandoMira = false
\tportador = nil
\tVFX.limpar()
end

Tool.Equipped:Connect(aoEquipar)
Tool.Unequipped:Connect(aoGuardar)

-- `Tool.Equipped` não dispara nos clientes que NÃO são o dono: para eles a
-- Tool simplesmente aparece dentro de um Character já montado. Por isso o
-- portador também é resolvido na entrada, e a cada troca de pai.
portador = donoDaTool()
Tool.AncestryChanged:Connect(function()
\tportador = donoDaTool()
\tif portador and souODono() then comecarMira() end
end)

Tool.Destroying:Connect(aoGuardar)

'''

# ═══════════════════════════════════════════════════════════════
# VFXModule — desenho, 100%% cliente, sobre o pack da Stella
# ═══════════════════════════════════════════════════════════════

VFXMODULE = '''-- VFXModule.lua
-- ModuleScript — desenho de efeito, 100%% cliente (conjunto COLLECTOR)
--
-- QUEM DESENHA É O PACK DO ACERVO
--   O fluxo obrigatório manda ler o `_INDICE.md` antes de criar efeito e
--   reusar o que existe. Onda, nova, explosão, corte, anel, rachadura, feixe e
--   espiral são os 10 do `Stella_VFX_Addon`, copiados para `VFXModule/Pack` na
--   montagem. Pack ausente é Tool empobrecida, não quebrada — cada primitiva
--   tem fallback local.
--
-- O QUE É PRÓPRIO DAQUI
--   O anel de selos do Julgamento, a corrente do Portal e o Highlight do Olho.
--   Nenhum dos três existe no pack, e os três são a identidade do conjunto.
--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local M = {}

local COR = {
\tOSSO = Color3.fromRGB(226, 214, 198),
\tSOMBRA = Color3.fromRGB(24, 20, 30),
\tALMA = Color3.fromRGB(122, 196, 208),
\tSENTENCA = Color3.fromRGB(214, 74, 62),
}

--%(regua)s
-- PACK DE VFX — DENTRO DA TOOL
--%(regua)s

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function deposito()
\tif packProcurado then return raizPack end
\tpackProcurado = true
\t-- DUAS PORTAS (Regra nº 2): o depósito PRIMEIRO, o interior depois.
\t--
\t-- ⚠️ A primeira porta faltava aqui, e não era detalhe: o `DepositoVFX`
\t--    MOVE a pasta `Pack` para fora da Tool assim que ela chega ao
\t--    jogador. Sem consultar o depósito, este módulo parava de achar o
\t--    próprio pack no instante em que a Tool era equipada — e falhava
\t--    em SILÊNCIO, desenhando nada.
\t--
\t--    Estava certo nos arquivos prontos (enxertado por
\t--    `ligar_deposito.py`) e errado no gerador. A regeneração desfazia.
\traizPack = Deposito.achar(script, PACK.PASTA)
\t\tor script:FindFirstChild(PACK.PASTA)
\treturn raizPack
end

local function efeitoDoPack(nome)
\tif not PACK.LIGADO then return nil end
\tlocal guardado = moduloDoPack[nome]
\tif guardado ~= nil then
\t\tif guardado == false then return nil end
\t\treturn guardado
\tend
\tlocal raiz = deposito()
\tif not raiz then moduloDoPack[nome] = false return nil end
\tlocal mod = raiz:FindFirstChild(nome)
\tif not mod or not mod:IsA("ModuleScript") then
\t\tmoduloDoPack[nome] = false
\t\treturn nil
\tend
\tlocal ok, fn = pcall(require, mod)
\tif not ok or type(fn) ~= "function" then
\t\tmoduloDoPack[nome] = false
\t\treturn nil
\tend
\tmoduloDoPack[nome] = fn
\treturn fn
end

local function pk(nome, ...)
\tlocal fn = efeitoDoPack(nome)
\tif not fn then return false end
\tlocal ok, err = pcall(fn, ...)
\tif not ok then
\t\twarn("[Collector VFX] pack " .. tostring(nome) .. ": " .. tostring(err))
\tend
\treturn ok
end

local vivos = {}

local function guardarPeca(peca, vida)
\tpeca.Parent = workspace
\ttable.insert(vivos, peca)
\tDebris:AddItem(peca, vida)
\treturn peca
end

--%(regua)s
-- SOM
--
-- Toca aqui, e não no servidor, pelo mesmo motivo do VFX: este script roda em
-- TODO cliente (RunContext = Client), então cada um cria o seu Sound local na
-- posição certa. Todo mundo ouve, posicionado, com custo de rede zero.
--
-- O molde vem de `Tool/SFX/` — o som é filho da Tool, como o resto.
--%(regua)s

local SFX = script.Parent:FindFirstChild("SFX")

local function som(rotulo, posicao, pitch)
\tlocal base = SFX and SFX:FindFirstChild(rotulo)
\tif not base then return nil end

\tlocal ancora = Instance.new("Part")
\tancora.Size = Vector3.new(0.2, 0.2, 0.2)
\tancora.Transparency = 1
\tancora.Anchored, ancora.CanCollide = true, false
\tancora.CFrame = CFrame.new(posicao or Vector3.new())
\tancora.Parent = workspace

\tlocal copia = base:Clone()
\tif pitch then copia.PlaybackSpeed = base.PlaybackSpeed * pitch end
\tcopia.Parent = ancora
\tcopia:Play()

\ttable.insert(vivos, ancora)
\tlocal duracao = (copia.TimeLength > 0 and copia.TimeLength or 5) + 1
\tDebris:AddItem(ancora, duracao)
\treturn copia
end

--%(regua)s
-- SOM
--
-- Toca aqui, e nao no servidor, pelo mesmo motivo do VFX: este script roda em
-- TODO cliente (RunContext = Client), entao cada um cria o seu Sound local na
-- posicao certa. Todo mundo ouve, posicionado, com custo de rede zero.
--
-- O molde vem de `Tool/SFX/` — o som e filho da Tool, como o resto.
--%(regua)s

local SFX = script.Parent:FindFirstChild("SFX")

local function som(rotulo, posicao, pitch)
\tlocal base = SFX and SFX:FindFirstChild(rotulo)
\tif not base then return nil end

\tlocal ancora = Instance.new("Part")
\tancora.Size = Vector3.new(0.2, 0.2, 0.2)
\tancora.Transparency = 1
\tancora.Anchored, ancora.CanCollide = true, false
\tancora.CFrame = CFrame.new(posicao or Vector3.new())
\tancora.Parent = workspace

\tlocal copia = base:Clone()
\tif pitch then copia.PlaybackSpeed = base.PlaybackSpeed * pitch end
\tcopia.Parent = ancora
\tcopia:Play()

\ttable.insert(vivos, ancora)
\tDebris:AddItem(ancora, (copia.TimeLength > 0 and copia.TimeLength or 5) + 1)
\treturn copia
end

--%(regua)s
-- PRIMITIVAS — pack primeiro, fallback local depois
--%(regua)s

local function onda(posicao, escala, cor, vida)
\tlocal base = Vector3.new(10.775, 2.3, 10.505) * (escala or 1)
\tif pk("Shockwave", CFrame.new(posicao), CFrame.new(posicao), vida or 1.2,
\t\t\tbase, base * 3, cor or COR.OSSO, cor or COR.SOMBRA,
\t\t\tEnum.EasingStyle.Quint) then
\t\treturn
\tend
\tlocal disco = Instance.new("Part")
\tdisco.Shape = Enum.PartType.Cylinder
\tdisco.Size = Vector3.new(0.4, base.X, base.Z)
\tdisco.CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90))
\tdisco.Material = Enum.Material.Neon
\tdisco.Color = cor or COR.OSSO
\tdisco.Anchored, disco.CanCollide = true, false
\tguardarPeca(disco, (vida or 1.2) + 0.5)
\tTweenService:Create(disco, TweenInfo.new(vida or 1.2,
\t\tEnum.EasingStyle.Quint, Enum.EasingDirection.Out),
\t\t{ Size = disco.Size * 3, Transparency = 1 }):Play()
end

local function ondaLarga(posicao, escala, cor, vida)
\tlocal base = Vector3.new(14, 1.4, 14) * (escala or 1)
\tif pk("Shockwave_2", CFrame.new(posicao), CFrame.new(posicao), vida or 1.8,
\t\t\tbase, base * 3.4, cor or COR.OSSO, cor or COR.SOMBRA,
\t\t\tEnum.EasingStyle.Quart) then
\t\treturn
\tend
\tonda(posicao, (escala or 1) * 1.5, cor, vida)
end

local function nova(posicao, escala, cor, vida)
\t-- Small_Nova recebe Size_A/Size_B como NÚMERO, não Vector3: o corpo do
\t-- módulo faz a conta com eles. Mandar Vector3 derruba em
\t-- "invalid argument #1 to 'new'", e o pcall engole o erro em silêncio.
\tlocal raio = escala or 4
\tlocal a = Vector3.new(1, 1, 1) * raio
\tif pk("Small_Nova", posicao, vida or 0.6, raio, raio * 4,
\t\t\tcor or COR.OSSO, cor or COR.SOMBRA, Enum.EasingStyle.Quint) then
\t\treturn
\tend
\tlocal bola = Instance.new("Part")
\tbola.Shape = Enum.PartType.Ball
\tbola.Size = a
\tbola.Material = Enum.Material.Neon
\tbola.Color = cor or COR.OSSO
\tbola.Anchored, bola.CanCollide = true, false
\tbola.CFrame = CFrame.new(posicao)
\tguardarPeca(bola, (vida or 0.6) + 0.4)
\tTweenService:Create(bola, TweenInfo.new(vida or 0.6,
\t\tEnum.EasingStyle.Quint, Enum.EasingDirection.Out),
\t\t{ Size = a * 4, Transparency = 1 }):Play()
end

local function estouro(posicao, escala, cor, vida)
\tlocal raio = escala or 6
\tlocal a = Vector3.new(1, 1, 1) * raio
\tif pk("Shockwave_Explosion", posicao, vida or 0.9, raio, raio * 3.2,
\t\t\tcor or COR.OSSO, cor or COR.SOMBRA) then
\t\treturn
\tend
\tnova(posicao, escala, cor, vida)
\tonda(posicao, (escala or 6) / 8, cor, (vida or 0.9) + 0.4)
end

local function estouroFumegante(posicao, escala, cor)
\tif pk("Smoky_Explosion", posicao, 1.4, (escala or 8), cor or COR.SOMBRA,
\t\t\tColor3.fromRGB(100, 102, 115)) then
\t\treturn
\tend
\testouro(posicao, (escala or 8) * 1.6, cor, 1.3)
end

local function corte(cframe, escala, cor, vida)
\tif pk("Small_Slash", cframe, (escala or 6),
\t\t\tvida or 0.45, cor or COR.OSSO, cor or COR.SOMBRA) then
\t\treturn
\tend
\tnova(cframe.Position, (escala or 6) * 0.5, cor, vida or 0.45)
end

local function anelSonar(cframe, escala, cor, vida)
\tif pk("Sonar_Ring", cframe, vida or 1, (escala or 6), (escala or 6) * 4,
\t\t\t0.6, 0.05, cor or COR.OSSO, cor or COR.SOMBRA) then
\t\treturn
\tend
\tonda(cframe.Position, (escala or 6) / 10, cor, vida)
end

local function rachadura(posicao, escala, cor, vida)
\tif pk("Floor_Crack", CFrame.new(posicao), (escala or 8),
\t\t\tvida or 3, cor or COR.SOMBRA) then
\t\treturn
\tend
\tonda(posicao, (escala or 8) / 10, cor, 1.4)
end

local function feixe(origem, destino, calibre, cor, vida)
\tif pk("Laser_Shot", origem, destino, (calibre or 3), (calibre or 3) * 0.2,
\t\t\tnil, cor or COR.OSSO, cor or COR.SOMBRA,
\t\t\tEnum.PartType.Cylinder, vida or 2) then
\t\treturn
\tend
\tlocal delta = destino - origem
\tlocal cilindro = Instance.new("Part")
\tcilindro.Shape = Enum.PartType.Cylinder
\tcilindro.Size = Vector3.new(delta.Magnitude, calibre or 3, calibre or 3)
\tcilindro.CFrame = CFrame.new(origem, destino)
\t\t* CFrame.new(0, 0, -delta.Magnitude / 2)
\t\t* CFrame.Angles(0, math.rad(90), 0)
\tcilindro.Material = Enum.Material.Neon
\tcilindro.Color = cor or COR.OSSO
\tcilindro.Anchored, cilindro.CanCollide = true, false
\tguardarPeca(cilindro, (vida or 2) + 0.5)
\tTweenService:Create(cilindro, TweenInfo.new(vida or 2), { Transparency = 1 }):Play()
end

local function espiral(posicao, escala, cor, voltas, raio, altura)
\tif pk("Spiral_Effect", posicao, (escala or 1.4),
\t\t\tcor or COR.ALMA, voltas or 26, raio or 8, altura or 14) then
\t\treturn
\tend
\tlocal i = 1
\twhile i <= (voltas or 26) do
\t\tlocal indice = i
\t\ttask.delay(indice * 0.02, function()
\t\t\tlocal ang = math.rad(137.507764 * indice)
\t\t\tnova(posicao + Vector3.new(math.cos(ang) * (raio or 8),
\t\t\t\tindice * ((altura or 14) / (voltas or 26)),
\t\t\t\tmath.sin(ang) * (raio or 8)), (escala or 1.4) * 1.5, cor, 0.5)
\t\tend)
\t\ti = i + 1
\tend
end

--%(regua)s
-- PRÓPRIO — selo, corrente e revelação
--%(regua)s

--- O contador do Julgamento. 20 selos em anel sobre a cabeça, um por segundo.
--- Não é `BillboardGui`: é geometria, e vive no mundo 3D.
local selos, ancoraSelo = {}, nil

local function tirarSelos()
\tfor _, selo in ipairs(selos) do
\t\tif selo and selo.Parent then selo.Parent = nil end
\tend
\tselos = {}
\tif ancoraSelo then
\t\tancoraSelo:Disconnect()
\t\tancoraSelo = nil
\tend
end

local function porSelos(corpo, quantos, altura, raio)
\ttirarSelos()
\tlocal cabeca = corpo and (corpo:FindFirstChild("Head")
\t\tor corpo:FindFirstChild("HumanoidRootPart"))
\tif not cabeca then return end

\tlocal i = 1
\twhile i <= quantos do
\t\tlocal selo = Instance.new("Part")
\t\tselo.Shape = Enum.PartType.Block
\t\tselo.Size = Vector3.new(0.28, 0.5, 0.12)
\t\tselo.Material = Enum.Material.Neon
\t\tselo.Color = COR.SENTENCA
\t\tselo.Anchored, selo.CanCollide = true, false
\t\tguardarPeca(selo, quantos + 4)
\t\ttable.insert(selos, selo)
\t\ti = i + 1
\tend

\t-- os selos seguem a cabeça a 60 Hz NO CLIENTE. Fazer isso no servidor
\t-- seria mover geometria por quadro, que replica picotado.
\tlocal giro = 0
\tancoraSelo = RunService.Heartbeat:Connect(function(dt)
\t\tif not cabeca.Parent then
\t\t\ttirarSelos()
\t\t\treturn
\t\tend
\t\tgiro = giro + dt * 0.9
\t\tfor indice, selo in ipairs(selos) do
\t\t\tif selo.Parent then
\t\t\t\tlocal ang = giro + math.rad(360 / quantos * indice)
\t\t\t\tselo.CFrame = CFrame.new(cabeca.Position
\t\t\t\t\t+ Vector3.new(math.cos(ang) * raio, altura, math.sin(ang) * raio))
\t\t\t\t\t* CFrame.Angles(0, -ang, 0)
\t\t\tend
\t\tend
\tend)
end

--- Corrente do Portal: elos entre o preso e a âncora. O elo é a malha de anel
--- do molde; sem ele, um cilindro fino serve de corda.
local function corrente(moldes, corpo, ancora, quantos)
\tlocal raizAlvo = corpo and (corpo:FindFirstChild("HumanoidRootPart")
\t\tor corpo:FindFirstChild("Torso"))
\tif not raizAlvo then return end
\tlocal base = moldes and moldes:FindFirstChild("Elo", true)

\tlocal i = 1
\twhile i <= (quantos or 8) do
\t\tlocal fracao = i / (quantos or 8)
\t\tlocal ponto = ancora:Lerp(raizAlvo.Position, fracao)
\t\tlocal elo
\t\tif base then
\t\t\telo = base:Clone()
\t\t\telo.Transparency = 0
\t\telse
\t\t\telo = Instance.new("Part")
\t\t\telo.Size = Vector3.new(0.3, 0.3, 1.2)
\t\t\telo.Material = Enum.Material.Metal
\t\t\telo.Color = COR.SOMBRA
\t\tend
\t\telo.Anchored, elo.CanCollide = true, false
\t\telo.CFrame = CFrame.new(ponto, raizAlvo.Position)
\t\t\t* CFrame.Angles(0, 0, math.rad(90 * (i %% 2)))
\t\tguardarPeca(elo, 1.4)
\t\tTweenService:Create(elo, TweenInfo.new(1.2,
\t\t\tEnum.EasingStyle.Quad, Enum.EasingDirection.In),
\t\t\t{ Transparency = 1 }):Play()
\t\ti = i + 1
\tend
end

--- Revelação do Olho. `Highlight` com `DepthMode = AlwaysOnTop` é a forma
--- honesta de ver através de parede: sem mexer em câmera, sem ScreenGui, e
--- visível só neste cliente, que é o do portador.
local realces = {}

local function limparRealces()
\tfor _, realce in pairs(realces) do
\t\tif realce and realce.Parent then realce.Parent = nil end
\tend
\trealces = {}
end

local function revelar(alvos, duracao)
\tlocal vistos = {}
\tfor _, corpo in ipairs(alvos or {}) do
\t\tif typeof(corpo) == "Instance" and corpo:IsA("Model") then
\t\t\tvistos[corpo] = true
\t\t\tif not realces[corpo] then
\t\t\t\tlocal realce = Instance.new("Highlight")
\t\t\t\trealce.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
\t\t\t\trealce.FillColor = COR.SENTENCA
\t\t\t\trealce.FillTransparency = 0.72
\t\t\t\trealce.OutlineColor = COR.OSSO
\t\t\t\trealce.Adornee = corpo
\t\t\t\trealce.Parent = corpo
\t\t\t\trealces[corpo] = realce
\t\t\tend
\t\t\tDebris:AddItem(realces[corpo], duracao or 1.5)
\t\tend
\tend
\tfor corpo, realce in pairs(realces) do
\t\tif not vistos[corpo] then
\t\t\tif realce and realce.Parent then realce.Parent = nil end
\t\t\trealces[corpo] = nil
\t\tend
\tend
end

--%(regua)s
-- O CATÁLOGO
--%(regua)s

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

function VFX.PILAR_ERGUE(d)
\tsom("ERGUE", d.posicao)
\tespiral(d.posicao, 2, COR.ALMA, 34, (d.grossura or 6) * 1.6,
\t\t(d.altura or 40) * 0.8)
\trachadura(d.posicao, 14, COR.SOMBRA, (d.duracao or 8) + 1)
\tanelSonar(CFrame.new(d.posicao), 12, COR.ALMA, 1.2)
end

function VFX.PILAR_GRITO(d)
\t-- o grito sobe de altura a cada pulso, ate o fim
\tsom("GRITO", d.posicao, 0.9 + (d.passo or 1) * 0.02)
\tonda(d.posicao, 1.4, COR.ALMA, 1.1)
\tnova(d.posicao + Vector3.new(0, 6, 0), 5, COR.ALMA, 0.7)
end

function VFX.PILAR_CAI(d)
\tsom("CAI", d.posicao)
\testouroFumegante(d.posicao, 10, COR.SOMBRA)
\tondaLarga(d.posicao, 1.6, COR.ALMA, 2)
end

function VFX.SELO_POE(d)
\tlocal cab = d.alvo and d.alvo:FindFirstChild("Head")
\tsom("SELA", cab and cab.Position or nil)
\tporSelos(d.alvo, d.selos or 20, d.altura or 4, d.raio or 2.2)
\tlocal cabeca = d.alvo and d.alvo:FindFirstChild("Head")
\tif cabeca then anelSonar(cabeca.CFrame, 4, COR.SENTENCA, 0.9) end
end

function VFX.SELO_TIQUE(d)
\t-- o tique fica mais agudo quanto menos selo resta
\tlocal cab = d.alvo and d.alvo:FindFirstChild("Head")
\tsom("TIQUE", cab and cab.Position or nil, 1 + (20 - (d.restam or 0)) * 0.03)
\tlocal restam = d.restam or 0
\t-- apaga de trás para a frente: some o último selo aceso
\tfor indice = #selos, 1, -1 do
\t\tif indice > restam and selos[indice] and selos[indice].Parent then
\t\t\tlocal selo = selos[indice]
\t\t\ttable.remove(selos, indice)
\t\t\tTweenService:Create(selo, TweenInfo.new(0.3),
\t\t\t\t{ Transparency = 1, Size = selo.Size * 2 }):Play()
\t\t\tDebris:AddItem(selo, 0.4)
\t\t\tbreak
\t\tend
\tend
end

function VFX.SELO_EXECUTA(d)
\tlocal cab = d.alvo and (d.alvo:FindFirstChild("Head")
\t\tor d.alvo:FindFirstChild("HumanoidRootPart"))
\tsom("EXECUTA", cab and cab.Position or nil)
\ttirarSelos()
\tlocal cabeca = d.alvo and (d.alvo:FindFirstChild("Head")
\t\tor d.alvo:FindFirstChild("HumanoidRootPart"))
\tif not cabeca then return end
\tfeixe(cabeca.Position + Vector3.new(0, 60, 0), cabeca.Position, 5,
\t\tCOR.SENTENCA, 0.9)
\testouro(cabeca.Position, 9, COR.SENTENCA, 1)
\tondaLarga(cabeca.Position, 1.2, COR.SENTENCA, 1.8)
end

function VFX.SELO_TIRA()
\ttirarSelos()
end

function VFX.CAVEIRA_NASCE(d)
\tsom("NASCE", d.posicao)
\tespiral(d.posicao, 1.4, COR.ALMA, 22, 5, 8)
\tnova(d.posicao, 6, COR.OSSO, 0.7)
end

function VFX.BOMBA_SAI(d)
\tnova(d.origem, 3, COR.SOMBRA, 0.35)
end

function VFX.BOMBA_ESTOURA(d)
\testouro(d.posicao, 8, COR.SOMBRA, 0.9)
\trachadura(d.posicao, 6, COR.SOMBRA, 2)
end

function VFX.PERTURBA_DESFAZ(d, _moldes, personagem)
\tlocal raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
\tif not raiz then return end
\tsom("DESFAZ", raiz.Position)
\tanelSonar(raiz.CFrame, 6, COR.ALMA, 0.9)
\tespiral(raiz.Position, 1.2, COR.ALMA, 20, 4, 7)

\t-- o eco: uma cópia esmaecida do corpo a cada meio segundo
\tlocal restante = d.duracao or 6
\tlocal passo = 0
\ttask.spawn(function()
\t\twhile passo < restante do
\t\t\tfor _, parte in ipairs(personagem:GetChildren()) do
\t\t\t\tif parte:IsA("BasePart") then
\t\t\t\t\tlocal eco = Instance.new("Part")
\t\t\t\t\teco.Size, eco.CFrame = parte.Size, parte.CFrame
\t\t\t\t\teco.Material = Enum.Material.Neon
\t\t\t\t\teco.Color = COR.ALMA
\t\t\t\t\teco.Transparency = 0.65
\t\t\t\t\teco.Anchored, eco.CanCollide = true, false
\t\t\t\t\tguardarPeca(eco, 0.8)
\t\t\t\t\tTweenService:Create(eco, TweenInfo.new(0.8),
\t\t\t\t\t\t{ Transparency = 1 }):Play()
\t\t\t\tend
\t\t\tend
\t\t\ttask.wait(0.5)
\t\t\tpasso = passo + 0.5
\t\tend
\tend)
end

function VFX.PERTURBA_ABSORVE(d)
\tif d.posicao then nova(d.posicao, 3, COR.ALMA, 0.35) end
end

function VFX.PERTURBA_VOLTA() end

function VFX.PERTURBA_DEVOLVE(d)
\tsom("DEVOLVE", d.posicao, 0.9 + (d.escala or 0.5) * 0.3)
\testouroFumegante(d.posicao, 10 * (0.5 + (d.escala or 0.5)), COR.ALMA)
\tondaLarga(d.posicao, 1.8, COR.ALMA, 2)
end

function VFX.PORTAL_ABRE(d)
\tsom("ABRE", d.posicao)
\tanelSonar(CFrame.new(d.posicao), d.raio or 14, COR.SOMBRA, 1.4)
\tespiral(d.posicao, 1.6, COR.ALMA, 30, (d.raio or 14) * 0.6, 10)
\trachadura(d.posicao, (d.raio or 14), COR.SOMBRA, (d.duracao or 10) + 1)
end

function VFX.CORRENTE_PRENDE(d, moldes)
\tsom("CORRENTE", d.ancora)
\tcorrente(moldes, d.alvo, d.ancora, d.elos)
end

function VFX.PORTAL_FECHA(d)
\tsom("FECHA", d.posicao)
\testouro(d.posicao, 8, COR.SOMBRA, 0.9)
end

function VFX.OLHO_ABRE(d)
\tsom("ABRE", d.posicao)
\tanelSonar(CFrame.new(d.posicao), (d.tamanho or 12), COR.OSSO, 1.2)
\tnova(d.posicao, (d.tamanho or 12) * 0.6, COR.OSSO, 0.8)

\t-- a pupila: uma esfera escura dentro do olho, girando devagar
\tlocal pupila = Instance.new("Part")
\tpupila.Shape = Enum.PartType.Ball
\tpupila.Size = Vector3.new(1, 1, 1) * ((d.tamanho or 12) * 0.42)
\tpupila.Material = Enum.Material.Neon
\tpupila.Color = COR.SOMBRA
\tpupila.Anchored, pupila.CanCollide = true, false
\tguardarPeca(pupila, (d.duracao or 14) + 1)

\tlocal giro, conexao = 0, nil
\tconexao = RunService.Heartbeat:Connect(function(dt)
\t\tif not pupila.Parent then
\t\t\tconexao:Disconnect()
\t\t\treturn
\t\tend
\t\tgiro = giro + dt * 0.7
\t\tpupila.CFrame = CFrame.new(d.posicao)
\t\t\t* CFrame.Angles(0, giro, 0)
\t\t\t* CFrame.new(0, 0, -(d.tamanho or 12) * 0.3)
\tend)
\ttask.delay(d.duracao or 14, function() conexao:Disconnect() end)
end

function VFX.OLHO_VARRE(d)
\tsom("VARRE", d.posicao, 1 + (d.passo or 1) * 0.01)
\tanelSonar(CFrame.new(d.posicao), 8, COR.OSSO, 0.8)
end

function VFX.OLHO_FECHA(d)
\tsom("FECHA", d.posicao)
\tnova(d.posicao, 8, COR.OSSO, 0.6)
\tlimparRealces()
end

function VFX.REVELAR(d)
\trevelar(d.alvos, d.duracao)
end

--%(regua)s

function M.desenhar(tipo, dados, moldes, personagem)
\tlocal fn = VFX[tipo]
\tif not fn then return end
\tlocal ok, erro = pcall(fn, dados, moldes, personagem)
\tif not ok then
\t\twarn("[Collector VFX] " .. tostring(tipo) .. ": " .. tostring(erro))
\tend
end

function M.beat(marca, personagem)
\tlocal braco = personagem and personagem:FindFirstChild("Right Arm")
\tif not braco then return end
\tif marca == "CARGA" then
\t\tnova(braco.Position, 2, COR.ALMA, 0.3)
\telseif marca == "GOLPE" then
\t\tnova(braco.Position, 4, COR.ALMA, 0.35)
\tend
end

function M.limpar()
\ttirarSelos()
\tlimparRealces()
\tfor _, peca in ipairs(vivos) do
\t\tif peca and peca.Parent then peca.Parent = nil end
\tend
\tvivos = {}
end

return M
'''


def gerar_cliente(nome, dados):
    alcance = "60"
    for chave, valor in dados["cfg"]:
        if chave == "ALCANCE":
            alcance = valor
    return CLIENTE % {
        "titulo": nome,
        "regua": REGUA,
        "alcance": alcance,
        "mira_remote": ('local MiraRemote = Tool:WaitForChild("MiraRemote")\n'
                        if dados["mira"] else "local MiraRemote = nil\n"),
    }


def main():
    if not os.path.exists(ANIMATOR):
        print("animator canônico não encontrado: %s" % ANIMATOR)
        return 1
    with open(ANIMATOR, encoding="utf-8") as f:
        animator = f.read()

    print("GERAÇÃO DE SCRIPTS — conjunto COLLECTOR")
    print("")
    for nome in sorted(TABELA):
        dados = TABELA[nome]
        pasta = os.path.join(TOOLS, nome)
        if not os.path.isdir(pasta):
            print("  PAREI: falta Tools/%s — rode preparar_submundo.py antes" % nome)
            return 1
        arquivos = {
            "%s_Server_V1.lua" % nome.replace(" ", ""): gerar_server(nome, dados),
            "Client.lua": gerar_cliente(nome, dados),
            "Poses.lua": POSES,
            "R6CFrameAnimator.lua": animator,
            "VFXModule.lua": VFXMODULE % {"regua": REGUA},
        }
        for arquivo, conteudo in arquivos.items():
            with open(os.path.join(pasta, arquivo), "w", encoding="utf-8") as f:
                f.write(conteudo)
        print("  %-24s %s" % (nome, dados["seq"]))
    print("")
    print("%d Tool(s) com Server, Client, Poses, Animator e VFXModule."
          % len(TABELA))
    return 0


if __name__ == "__main__":
    sys.exit(main())
