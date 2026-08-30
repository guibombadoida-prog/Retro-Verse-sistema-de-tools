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
local Deposito   = require(Tool:WaitForChild("DepositoVFX"))
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
	local base = somDe(nome)
	if not base then return nil end

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

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Handle/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight"). Tool
--- antiga não muda de comportamento.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o clone é
--- parenteado no `Handle` pelo servidor, então a INSTÂNCIA replica e todo
--- mundo ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons
--- diferentes para o mesmo golpe.
---
--- ⚠️ O último `return` do sorteio não é paranoia: `math.random() * total`
---    pode sobrar por arredondamento e cair fora do laço. A implementação de
---    onde a ideia veio devolve `nil` aí — um som mudo, calado, de vez em
---    quando.
---
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1.
local function sortearNoGrupo(pasta)
	local candidatos, total = {{}}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, {{ som = filho, peso = peso }})
			total = total + peso
		end
	end
	if #candidatos == 0 then return nil end
	if #candidatos == 1 then return candidatos[1].som end

	local sorteio = math.random() * total
	for _, c in ipairs(candidatos) do
		if sorteio < c.peso then return c.som end
		sorteio = sorteio - c.peso
	end
	return candidatos[#candidatos].som
end

local function somDe(nome)
	local achado = Handle:FindFirstChild(nome)
	if not achado then
		local pasta = Tool:FindFirstChild("SFX")
		achado = pasta and pasta:FindFirstChild(nome)
	end
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
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

--- Alvos num raio. O `Fists` varria `workspace:GetDescendants()` e o `dodge`
--- mantinha uma tabela viva de TODO Humanoid do jogo por
--- `workspace.DescendantAdded`. Aqui é consulta espacial sob demanda, e quem
--- filtra time é o Núcleo.
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

--- Lentidão com volta GARANTIDA.
---
--- ELE FALTAVA. O `Corte Frio` chamava `afrouxar` em DOIS lugares — no beat do
--- corte e no gelo do chão — e ele não existia em lugar nenhum do arquivo:
--- `attempt to call a nil value`, e as duas habilidades morriam caladas. Só
--- apareceu quando a lista `AJUDANTES` do `verificar_beats.py` cresceu.
---
--- Guarda a velocidade de ANTES e devolve ESSA, nunca 16 fixo: o alvo pode ter
--- velocidade própria, e devolver um número chapado quebra quem tinha.
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

--═══════════════════════════════════════════════════════════════
-- ATORDOAR — trava no lugar, e devolve garantido
--
-- Diferente do `tombar`: quem está atordoado continua DE PÉ. A leitura é
-- "travou", não "caiu", e as duas habilidades que atordoam neste conjunto
-- (o counter e a aura) querem a primeira.
--
-- O atributo não é enfeite. Sem ele, um segundo atordoamento em cima do
-- primeiro guardaria `WalkSpeed = 0` como "o valor de antes" e devolveria
-- zero no fim — o alvo ficaria parado para sempre. É o bug clássico de
-- lentidão que empilha, e ele não aparece em teste de um alvo só.
--═══════════════════════════════════════════════════════════════

local function atordoar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum:GetAttribute("DramaAtordoado") then return end

	local usaPotencia = alvoHum.UseJumpPower
	local andar = alvoHum.WalkSpeed
	local pular = usaPotencia and alvoHum.JumpPower or alvoHum.JumpHeight

	alvoHum:SetAttribute("DramaAtordoado", true)
	alvoHum.WalkSpeed = 0
	if usaPotencia then
		alvoHum.JumpPower = 0
	else
		alvoHum.JumpHeight = 0
	end

	task.delay(tempo or 1, function()
		if alvoHum and alvoHum.Parent then
			alvoHum.WalkSpeed = andar
			if usaPotencia then
				alvoHum.JumpPower = pular
			else
				alvoHum.JumpHeight = pular
			end
			alvoHum:SetAttribute("DramaAtordoado", nil)
		end
	end)
end

--═══════════════════════════════════════════════════════════════
-- QUEM ME BATEU — a etiqueta `creator`, lida do lado de dentro
--
-- O contra-ataque do `Combate` e a aura do `Aura` precisam da MESMA coisa: a
-- identidade de quem acabou de me acertar. O repositório já grava isso —
-- `creditar()` põe um `ObjectValue` chamado `creator` no Humanoid da VÍTIMA, e
-- o Núcleo faz igual em `marcarCredito`. A informação já está aqui dentro;
-- basta ler.
--
-- ⚠️ Nada de gancho global de sistema nenhum: a Tool não conhece sistema.
--    Ler a etiqueta funciona num place vazio, que é o que a Regra nº 1 cobra.
--═══════════════════════════════════════════════════════════════

local function quemMeBateu()
	if not humanoide then return nil end

	local marca = humanoide:FindFirstChild("creator")
	local autor = marca and marca:IsA("ObjectValue") and marca.Value or nil
	if autor and autor:IsA("Player") then
		local corpo = autor.Character
		local hum = corpo and corpo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then return hum end
	end

	-- Sem etiqueta — dano de queda, de NPC sem crédito, de qualquer coisa. O
	-- mais perto é o palpite honesto, e ele é LIMITADO POR RAIO: devolver dano
	-- em quem está do outro lado do mapa seria pior que não devolver nada.
	if raiz then
		return maisPerto(raiz.Position, CFG.RAIO_DEVOLVE or 24)
	end
	return nil
end

--- Vigia a própria vida e chama `aoLevar(quanto, quemBateu)` a cada QUEDA.
---
--- `HealthChanged` também dispara em cura; a subtração filtra. E a conexão é
--- devolvida para quem chamou desligar — janela de counter que fica ligada
--- depois do prazo é counter permanente.
local function vigiarVida(aoLevar)
	if not humanoide then return nil end
	local anterior = humanoide.Health
	return humanoide.HealthChanged:Connect(function(nova)
		local queda = anterior - nova
		anterior = nova
		if queda <= 0 then return end
		aoLevar(queda, quemMeBateu())
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

{ligacao_primaria}
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

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- fica lá até o servidor cair.
--
-- ISTO ESTAVA FORA DO GERADOR. A ligação tinha sido enxertada nos arquivos
-- prontos por `FERRAMENTAS/ligar_deposito.py`, e por isso a primeira
-- regeneração do DRAMA a perdeu — as sete Tools voltaram a não ter depósito, e
-- só o `verificar_deposito_vfx.py` percebeu. Enxerto que não volta para o
-- gerador é conserto que dura até a próxima geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
'''



# ═══════════════════════════════════════════════════════════════
# OS DOIS CANAIS DA PRIMÁRIA
#
# `clique`  — o de sempre: um `FireServer`, uma recarga, uma habilidade.
# `feixe`   — SEGURAR. `Tool.Activated` abre, `Tool.Deactivated` fecha, e no
#             meio o cliente manda a mira a 12 pacotes por segundo para o feixe
#             acompanhar o mouse.
#
# Só `Olhos Laser` usa o segundo, e ele existe porque feixe que sai em tiro
# único não é o feixe que foi pedido: o do Capitão Pátria é contínuo e VARRE.
# ═══════════════════════════════════════════════════════════════

LIGACAO_CLIQUE = '''
VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)
'''

LIGACAO_FEIXE = '''
--- TRÊS fases num remote só. A FASE vem no payload e é conferida aqui antes
--- de qualquer coisa; um segundo `RemoteEvent` seria outra porta para o mesmo
--- cômodo, e outra superfície para validar.
---
--- `MIRA` e `FECHA` passam mesmo com `ocupado`. Têm de passar: enquanto o
--- feixe está de pé o estado É ocupado, e exigir que ele acabe tornaria
--- impossível mirar e soltar.
VFXRemote.OnServerEvent:Connect(function(quem, mira, fase)
	if quem ~= jogador then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if fase == "MIRA" then
		apontar(mira)
		return
	end
	if fase == "FECHA" then
		fechar()
		return
	end

	if not podeAgir() then return end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)
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

{ciclo_primaria}
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



CICLO_CLIQUE = """
Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira())
end)
"""

CICLO_FEIXE = """
--══════════════════════════════════════════════════════════════
-- O FEIXE É SEGURADO
--
-- `Tool.Activated` abre e `Tool.Deactivated` fecha — o par que o Roblox já dá
-- para clique mantido. Entre os dois, a mira sobe a `PASSO_MIRA`, e é isso que
-- faz o feixe VARRER em vez de apontar para onde estava quando saiu.
--
-- 12 pacotes por segundo. Um `RenderStepped` mandaria 60 por um ponto que o
-- mouse move devagar, e o desenho do feixe já interpola o meio do caminho.
--══════════════════════════════════════════════════════════════

local PASSO_MIRA = 0.08
local LIMITE_FEIXE = 6
local segurando = false

Tool.Activated:Connect(function()
	if not souODono() or segurando then return end
	segurando = true
	VFXRemote:FireServer(mira(), "ABRE")
	task.spawn(function()
		local ate = os.clock() + LIMITE_FEIXE
		while segurando and equipado and os.clock() < ate do
			VFXRemote:FireServer(mira(), "MIRA")
			task.wait(PASSO_MIRA)
		end
		-- o teto de tempo também fecha: soltar o clique é o caminho normal, e
		-- ele não pode ser o ÚNICO, ou um alt-tab deixaria o feixe ligado.
		if segurando then
			segurando = false
			VFXRemote:FireServer(mira(), "FECHA")
		end
	end)
end)

Tool.Deactivated:Connect(function()
	if not souODono() or not segurando then return end
	segurando = false
	VFXRemote:FireServer(mira(), "FECHA")
end)
"""

# ═══════════════════════════════════════════════════════════════
# AS 7 TOOLS
# ═══════════════════════════════════════════════════════════════

CONJUNTO = {}

R = "═" * 62


# ═══════════════════════════════════════════════════════════════
# t1 · COMBATE — soco + counter
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Combate"] = dict(
    objeto="Combate_Server_V1", sufixo="DramaCombate",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False, canal="clique",
    rotulo_primaria="combo de tres socos que encadeiam",
    rotulo_extra="Counter",
    cfg="""	ALCANCE       = 6,
	RAIO_GOLPE    = 6.5,
	DANO_A        = 12,
	DANO_B        = 12,
	DANO_C        = 22,
	EMPURRAO      = 26,
	RECARGA       = 0.4,
	JANELA_COMBO  = 1.4,

	RECARGA_EXTRA = 9,
	JANELA_CONTRA = 1.0,
	FATOR_DEVOLVE = 1.6,
	TETO_DEVOLVE  = 55,
	RAIO_DEVOLVE  = 22,
	ATORDOAMENTO  = 1.6,
	EMPURRAO_CONTRA = 46,""",
    estado=("local passoCombo = 0\n"
            "local ultimoGolpe = 0\n"
            "local vigiaContra = nil\n"
            "local contraAberto = false\n"
            "--- `function x()` sem esta linha atribui a uma GLOBAL\n"
            "local fecharContra"),
    ao_equipar="",
    ao_guardar="\tpassoCombo = 0\n\tfecharContra()\n",
    corpo='''
--''' + R + '''
-- M1 — combo de três
--
-- O passo avança só se o golpe anterior caiu dentro da janela. Passou do
-- prazo, volta ao primeiro: é o que faz combo ser combo e não uma fila de
-- socos avulsos. INTACTO do refazimento anterior.
--''' + R + '''

local ORDEM = { "SOCO_A", "SOCO_B", "SOCO_C" }
local DANOS = { "DANO_A", "DANO_B", "DANO_C" }

function primaria(_mira)
	local agora = os.clock()
	if agora - ultimoGolpe > CFG.JANELA_COMBO then passoCombo = 0 end
	passoCombo = passoCombo + 1
	if passoCombo > 3 then passoCombo = 1 end
	ultimoGolpe = agora

	local passo = passoCombo
	ocupado = true
	rig:PlaySequence(ORDEM[passo], despachar({
		-- o TERCEIRO tem timbre próprio. É o gancho, o que fecha o combo e o
		-- que dá quase o dobro do dano dos dois primeiros — som igual aos
		-- outros dois desperdiçaria a única pista sonora de que ele é
		-- diferente. E é o que tira o `CARGA` da lista de som depositado e
		-- mudo: asset viajando dentro da Tool sem ninguém tocá-lo.
		CARGA = { sfx = { passo == 3 and "CARGA" or "PREPARA",
			passo == 3 and 0.9 or 1.15 } },
		BATE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local pegou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
				aplicarDano(alvo, CFG[DANOS[passo]])
				empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.2, 0),
					CFG.EMPURRAO, 0.18)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("SOCO", { posicao = alvoRaiz.Position, escala = 1 })
				end
				pegou = true
			end
			if pegou then
				tocarEm("IMPACTO", ponto, 1 + jitter(0.3) * 0.1)
			else
				tocar("GOLPE", 1.2)
			end
		end },
		FIM = { faz = function() passoCombo = 0 end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Counter
--
-- Abre uma janela de `JANELA_CONTRA` segundos. Se alguém acertar o portador
-- dentro dela, o dano é DEVOLVIDO multiplicado, e quem bateu fica atordoado.
--
-- COMO ELE SABE QUE LEVOU
--
--   `humanoide.HealthChanged`, que é a única coisa do Roblox que avisa perda
--   de vida sem importar de onde ela veio. A subtração filtra cura. E quem
--   bateu vem da etiqueta `creator` que o próprio repositório grava na vítima
--   — nada de gancho global do Núcleo, que é declarado lá como sendo para
--   sistemas e não para Tools.
--
-- O QUE ELE NÃO FAZ
--
--   Não anula o dano. Contra que zera o golpe é invencibilidade com outro
--   nome, e o `Desviar` já é a Tool que dá i-frames. Aqui você LEVA e devolve
--   mais — a troca é boa, e continua sendo uma troca.
--
--   E ele devolve UMA vez. A janela fecha no primeiro acerto: contra que
--   devolve tudo o que vier durante um segundo apaga qualquer time.
--''' + R + '''

function fecharContra()
	contraAberto = false
	if vigiaContra then
		vigiaContra:Disconnect()
		vigiaContra = nil
	end
end

local function devolver(quanto, agressor)
	if not contraAberto then return end
	fecharContra()

	local devolvido = math.min(quanto * CFG.FATOR_DEVOLVE, CFG.TETO_DEVOLVE)
	if not agressor then
		-- pegou o golpe mas não achou quem deu: o gesto sai, o dano não.
		vfx("CONTRA_VAZIO", { posicao = raiz.Position, escala = 1 })
		tocar("PREPARA", 0.8)
		return
	end

	local alvoRaiz = raizDe(agressor)
	aplicarDano(agressor, devolvido)
	atordoar(agressor, CFG.ATORDOAMENTO)
	if alvoRaiz then
		empurrar(agressor, alvoRaiz.Position - raiz.Position
			+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_CONTRA, 0.24)
		vfx("CONTRA_DEVOLVE", { posicao = alvoRaiz.Position,
			de = raiz.Position, escala = 1 })
		tocarEm("IMPACTO", alvoRaiz.Position, 0.85)
	end

	-- a resposta interrompe a guarda no quadro em que o golpe chega, que é
	-- exatamente como counter deve ler. `PlaySequence` cancela a anterior.
	rig:PlaySequence("DEVOLVER", despachar({
		DEVOLVE = { sfx = { "GOLPE", 0.9 } },
	}), function() ocupado = false end)
end

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CONTRA", despachar({
		ABRE = { sfx = { "PREPARA", 1.3 }, faz = function()
			fecharContra()
			contraAberto = true
			vfx("CONTRA_ABRE", { posicao = raiz.Position, escala = 1,
				vida = CFG.JANELA_CONTRA })
			vigiaContra = guardar(vigiarVida(devolver))
			task.delay(CFG.JANELA_CONTRA, fecharContra)
		end },
		ESPERA = { faz = function()
			vfx("CONTRA_ABRE", { posicao = raiz.Position, escala = 0.6,
				vida = 0.4 })
		end },
		FECHA = { faz = fecharContra },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
# t2 · DESVIAR — a esquiva virou a primária
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Desviar"] = dict(
    objeto="Desviar_Server_V1", sufixo="DramaDesviar",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False, canal="clique",
    rotulo_primaria="esquiva com invencibilidade",
    rotulo_extra="Empurrao",
    cfg="""	ALCANCE       = 7,
	DISTANCIA_ESQ = 34,
	TEMPO_IMUNE   = 0.42,
	TEMPO_ESQ     = 0.28,
	RECARGA       = 3,

	RECARGA_EXTRA = 6,
	RAIO_CONE     = 11,
	DANO          = 9,
	EMPURRAO      = 92,
	SUBIDA        = 16,""",
    estado="local impulsoEsq = nil",
    ao_equipar="",
    ao_guardar='''	if impulsoEsq then
		impulsoEsq.Parent = nil
		impulsoEsq = nil
	end
	if humanoide and humanoide.Parent then
		humanoide.PlatformStand = false
	end
''',
    corpo='''
--''' + R + '''
-- M1 — a esquiva
--
-- Era a Extra e virou a PRIMÁRIA, a pedido. Faz sentido: é ela que dá nome à
-- Tool, e é o único pedaço de mecânica do `dodge` do Rufus14 que sobreviveu
-- inteiro ao passe de conformidade.
--
-- `TEMPO_ESQ = 0.28` e `TEMPO_IMUNE = 0.42`. A imunidade é MAIOR que o
-- deslocamento de propósito: esquivar e levar o golpe no quadro em que você
-- para é a coisa mais frustrante que um jogo de briga faz.
--
-- A INVENCIBILIDADE É `ForceField`, e ela tem prazo pelo `Debris`.
--
--   `ForceField` é o único jeito de recusar dano que respeita `TakeDamage` —
--   qualquer Tool do repositório que chame `TakeDamage` bate nele e não passa.
--   Um `atributo = imune` que só ESTA Tool consultasse não valeria nada contra
--   as outras 90 do repositório.
--
-- O que a origem tinha e não entrou: dois `workspace.DescendantAdded` globais
-- mantendo uma tabela viva de TODO Humanoid do jogo, ligados para sempre.
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ESQUIVA", despachar({
		ENTRA = { sfx = { "PREPARA", 1.35 }, faz = function()
			local para = destino - raiz.Position
			para = Vector3.new(para.X, 0, para.Z)
			if para.Magnitude < 1 then
				para = -raiz.CFrame.LookVector
			else
				para = para.Unit
			end

			if impulsoEsq then impulsoEsq.Parent = nil end
			impulsoEsq = Instance.new("BodyVelocity")
			impulsoEsq.MaxForce = Vector3.new(1e5, 0, 1e5)
			impulsoEsq.Velocity = para * CFG.DISTANCIA_ESQ
			impulsoEsq.Parent = raiz
			Debris:AddItem(impulsoEsq, CFG.TEMPO_ESQ)

			vfx("ESQUIVA", { posicao = raiz.Position,
				para = raiz.Position + para * 8, escala = 1 })
		end },
		IMUNE = { faz = function()
			local campo = personagem:FindFirstChildOfClass("ForceField")
			if not campo then
				campo = Instance.new("ForceField")
				campo.Visible = false
				campo.Parent = personagem
			end
			Debris:AddItem(campo, CFG.TEMPO_IMUNE)
			vfx("IMUNE", { posicao = raiz.Position, escala = 1,
				vida = CFG.TEMPO_IMUNE })
		end },
		SAI = { sfx = { "GOLPE", 1.5 } },
	}), function()
		ocupado = false
		impulsoEsq = nil
	end)
end

--''' + R + '''
-- R — Empurrão
--
-- Era a primária e desceu para Extra. Cone à frente: dano pequeno, empurrão
-- grande. Ele não mata — ele TIRA gente de cima, e é o par natural da esquiva.
--''' + R + '''

function extra(_mira)
	ocupado = true
	rig:PlaySequence("EMPURRAO", despachar({
		CARGA = { sfx = { "CARGA", 1.1 } },
		EMPURRA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			vfx("EMPURRAO", { posicao = ponto, cframe = raiz.CFrame,
				raio = CFG.RAIO_CONE, escala = 1 })
			tocarEm("IMPACTO", ponto, 0.95)

			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CONE, 10)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					-- CONE, não esfera: só quem está à frente é empurrado.
					-- Empurrar quem está atrás de você é o defeito clássico
					-- de área de melee, e ele passa despercebido em teste
					-- contra um alvo parado na sua frente.
					local delta = alvoRaiz.Position - raiz.Position
					local plano = Vector3.new(delta.X, 0, delta.Z)
					if plano.Magnitude > 0.5
							and plano.Unit:Dot(raiz.CFrame.LookVector) > 0.25 then
						aplicarDano(alvo, CFG.DANO)
						empurrar(alvo, raiz.CFrame.LookVector
							+ Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),
							CFG.EMPURRAO, 0.28)
					end
				end
			end
		end },
	}), function() ocupado = false end)
end
''')

# ═══════════════════════════════════════════════════════════════
# t3 · CORTE FRIO — a cutscene de cortes consecutivos
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Corte Frio"] = dict(
    objeto="CorteFrio_Server_V1", sufixo="DramaCorteFrio",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=True, canal="clique",
    rotulo_primaria="corte de lamina que congela",
    rotulo_extra="Serie de Cortes",
    cfg="""	ALCANCE       = 7,
	RAIO_CORTE    = 7.5,
	DANO          = 26,
	EMPURRAO      = 24,
	LENTIDAO      = 0.6,
	TEMPO_FRIO    = 1.8,
	RECARGA       = 0.9,

	RECARGA_EXTRA = 22,
	RAIO_ALVO     = 14,
	DANO_CORTE    = 16,
	DANO_ULTIMO   = 44,
	CORTES        = 5,
	AVANCO        = 6,
	DURACAO_GELO  = 2.8,
	LENTIDAO_GELO = 0.3,""",
    estado="local alvoDaSerie = nil\nlocal cortesDados = 0",
    ao_equipar="",
    ao_guardar="\talvoDaSerie = nil\n\tcortesDados = 0\n\tfecharCena()\n",
    corpo='''
--''' + R + '''
-- M1 — o corte
--
-- Corte de lâmina que deixa o alvo LENTO. É o preparo da Extra: alvo devagar é
-- alvo que ainda está lá quando a série começa.
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CORTE", despachar({
		ERGUE = { sfx = { "PREPARA", 1.2 } },
		CORTA = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local q = raiz.CFrame * CFrame.new(0, 1, -3)
			vfx("CORTE", { cframe = q, escala = 1 })
			local pegou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CORTE, 6)) do
				aplicarDano(alvo, CFG.DANO)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_FRIO)
				empurrar(alvo, raiz.CFrame.LookVector, CFG.EMPURRAO, 0.16)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("GELO", { posicao = alvoRaiz.Position, escala = 0.8,
						vida = CFG.TEMPO_FRIO })
				end
				pegou = true
			end
			if pegou then
				tocarEm("IMPACTO", ponto, 1.1)
			else
				tocar("GOLPE", 1.25)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Série de Cortes  (CUTSCENE)
--
-- O pedido foi "cutscene de cortes consecutivos", e a diferença com a execução
-- que estava aqui antes é a PROPORÇÃO. A execução tinha 70% de preparação e um
-- corte no fim: a leitura era "o golpe definitivo". Esta tem 0.57 s de
-- preparação e depois seis cortes seguidos, um a cada 0.22 s: a leitura é
-- "não dá para parar".
--
-- CADA CORTE É UM BEAT, E CADA BEAT É UM ACERTO
--
--   `CORTE_1` a `CORTE_5` e `ULTIMO` — seis marcas na sequência, seis entradas
--   na tabela do despachante. Nenhum `task.wait` encadeia nada: quem conduz o
--   tempo é o animator, e o dano cai quando a lâmina cai.
--
--   `TESTES/verificar_beats.py` confere que os seis existem dos dois lados. É
--   o verificador que nasceu porque 14 Tools saíram com beat escrito só de um
--   lado e dano zero.
--
-- O ALVO É FIXADO NO INÍCIO
--
--   Ele é escolhido uma vez, no `AVANCA`, e a série inteira persegue ESSE. Um
--   `maisPerto` por corte faria a lâmina pular de alvo em alvo no meio da
--   cena — o que é outra habilidade, e não a que foi pedida.
--''' + R + '''

--- Um corte da série. `ordem` é só para o desenho: o ângulo de cada lâmina sai
--- do ângulo áureo, então os seis nunca se sobrepõem.
local function cortarNaSerie(ordem, dano)
	local alvo = alvoDaSerie
	if not (alvo and alvo.Parent and alvo.Health > 0) then
		-- o alvo caiu no meio da série: o gesto continua, o dano não tem onde
		-- cair. Cortar o ar é melhor que a cena parar pela metade.
		tocar("GOLPE", 1.3 + ordem * 0.04)
		return
	end
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return end

	cortesDados = cortesDados + 1
	aplicarDano(alvo, dano)
	afrouxar(alvo, CFG.LENTIDAO_GELO, CFG.DURACAO_GELO)

	vfx("CORTE_SERIE", { posicao = alvoRaiz.Position, angulo = angulo(ordem),
		ordem = ordem, escala = 1 })
	tocarEm("GOLPE", alvoRaiz.Position, 1.1 + ordem * 0.06)
end

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.RAIO_ALVO), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.8)
		return
	end

	ocupado = true
	alvoDaSerie = alvo
	cortesDados = 0

	rig:PlaySequence("SERIE", despachar({
		CAMERA = { cam = true, sfx = { "CARGA", 0.9 }, faz = function()
			abrirCena(alvoDaSerie, "SERIE")
			rig:LockCharacter(true)
		end },
		AVANCA = { cam = true, faz = function()
			-- encosta no alvo: a série é corpo a corpo, e o avanço é o que
			-- fecha a distância sem teleportar ninguém.
			local alvoRaiz = raizDe(alvoDaSerie)
			if alvoRaiz and raiz then
				local delta = alvoRaiz.Position - raiz.Position
				local plano = Vector3.new(delta.X, 0, delta.Z)
				if plano.Magnitude > CFG.AVANCO then
					empurrar(humanoide, plano, plano.Magnitude * 2.4, 0.2)
				end
			end
			vfx("GELO", { posicao = raiz.Position, escala = 1.2, vida = 3 })
		end },
		CORTE_1 = { cam = true, faz = function() cortarNaSerie(1, CFG.DANO_CORTE) end },
		CORTE_2 = { faz = function() cortarNaSerie(2, CFG.DANO_CORTE) end },
		CORTE_3 = { cam = true, faz = function() cortarNaSerie(3, CFG.DANO_CORTE) end },
		CORTE_4 = { faz = function() cortarNaSerie(4, CFG.DANO_CORTE) end },
		CORTE_5 = { faz = function() cortarNaSerie(5, CFG.DANO_CORTE) end },
		SEGURA = { cam = true, sfx = { "CARGA", 0.7 } },
		ULTIMO = { cam = true, faz = function()
			cortarNaSerie(6, CFG.DANO_ULTIMO)
			local alvoRaiz = raizDe(alvoDaSerie)
			local onde = alvoRaiz and alvoRaiz.Position or frente(CFG.ALCANCE)
			vfx("ESTILHACO", { posicao = onde, escala = 1,
				cortes = cortesDados })
			tocarEm("IMPACTO", onde, 0.8)
			if alvoDaSerie and alvoDaSerie.Health > 0 then
				tombar(alvoDaSerie, 1.4)
			end
		end },
		FIM = { cam = true, faz = function()
			rig:LockCharacter(false)
			fecharCena()
			alvoDaSerie = nil
		end },
	}), function()
		ocupado = false
		rig:LockCharacter(false)
		fecharCena()
		alvoDaSerie = nil
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# t4 · IMPACTO FORTE — o soco sério
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Impacto Forte"] = dict(
    objeto="ImpactoForte_Server_V1", sufixo="DramaImpacto",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False, canal="clique",
    rotulo_primaria="soco serio: um corredor reto de vento",
    rotulo_extra="Rachar o Chao",
    cfg="""	ALCANCE       = 6.5,
	RAIO_GOLPE    = 6,
	DANO          = 46,
	DANO_VENTO    = 30,
	EMPURRAO      = 128,
	SUBIDA        = 26,
	TOMBO         = 2,
	RECARGA       = 3.4,

	COMPRIMENTO   = 90,
	LARGURA       = 7,
	PASSOS_VENTO  = 15,

	RECARGA_EXTRA = 13,
	RAIO_RACHA    = 20,
	NUCLEO_RACHA  = 7,
	DANO_RACHA    = 52,
	BORDA_RACHA   = 26,
	EMPURRAO_RACHA = 70,
	TOMBO_RACHA   = 1.6,""",
    estado="",
    ao_equipar="",
    ao_guardar="",
    corpo='''
--''' + R + '''
-- M1 — o soco sério
--
-- O pedido foi "parecido com o soco do Saitama", e o que define aquele soco
-- não é o dano: é o CORREDOR. O punho acerta quem está à frente, e o
-- deslocamento de ar continua em linha reta por 90 studs, pegando tudo o que
-- estiver na faixa.
--
-- POR QUE CORREDOR E NÃO ESFERA
--
--   A versão anterior era um raio em volta do ponto de impacto — a mesma forma
--   de qualquer soco pesado do repositório. Esfera lê como explosão; faixa
--   reta lê como sopro. É a forma que carrega a referência, e trocá-la era o
--   pedido inteiro.
--
--   A colheita é em `PASSOS_VENTO` pontos ao longo da reta, com um raio
--   pequeno em cada, e `vistos` impede o mesmo alvo de levar duas vezes por
--   estar entre dois pontos.
--
-- E A ANIMAÇÃO ACOMPANHA
--
--   1.60 s, com 58% do tempo na carga parada e um impacto de 0.08 s — o mais
--   curto do conjunto. Golpe que demora a sair e sai instantâneo é o que dá a
--   impressão de que a força não coube na animação.
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("SOCO", despachar({
		CARGA = { sfx = { "CARGA", 0.8 } },
		SEGURA = { faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ raiz.CFrame.LookVector * 1.6 + Vector3.new(0, 1.2, 0),
				escala = 1 })
		end },
		BATE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local direcao = raiz.CFrame.LookVector
			local saida = raiz.Position + Vector3.new(0, 1.2, 0)

			vfx("SOCO_SERIO", { posicao = saida,
				para = saida + direcao * CFG.COMPRIMENTO,
				largura = CFG.LARGURA, escala = 1 })
			tocarEm("IMPACTO", ponto, 0.75)

			local vistos = {}

			-- o punho: perto, e é onde o dano cheio mora
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 6)) do
				vistos[alvo] = true
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				empurrar(alvo, direcao + Vector3.new(0, CFG.SUBIDA / CFG.EMPURRAO, 0),
					CFG.EMPURRAO, 0.34)
			end

			-- o corredor: 90 studs de faixa reta, dano menor, empurrão igual
			for i = 1, CFG.PASSOS_VENTO do
				local passo = saida + direcao
					* (CFG.COMPRIMENTO * i / CFG.PASSOS_VENTO)
				for _, alvo in ipairs(alvosEm(passo, CFG.LARGURA, 6)) do
					if not vistos[alvo] then
						vistos[alvo] = true
						aplicarDano(alvo, CFG.DANO_VENTO)
						tombar(alvo, CFG.TOMBO * 0.6)
						empurrar(alvo, direcao + Vector3.new(0, 0.2, 0),
							CFG.EMPURRAO * 0.7, 0.3)
					end
				end
			end
		end },
		VENTO = { sfx = { "GOLPE", 0.7 } },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Rachar o Chão
--
-- Núcleo e borda em volta do portador. INTACTA: ela já era o par certo do
-- soco — um pega em linha, a outra pega em volta.
--''' + R + '''

function extra(_mira)
	ocupado = true
	rig:PlaySequence("RACHA", despachar({
		ERGUE = { sfx = { "PREPARA", 0.85 } },
		SEGURA = { faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ Vector3.new(0, 2.4, 0), escala = 0.8 })
		end },
		RACHA = { faz = function()
			local centro = raiz.Position - Vector3.new(0, 1.6, 0)
			vfx("RACHA", { posicao = centro, raio = CFG.RAIO_RACHA,
				escala = 1 })
			tocarEm("IMPACTO", centro, 0.65)

			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_RACHA, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - centro).Magnitude
					or CFG.RAIO_RACHA
				if d <= CFG.NUCLEO_RACHA then
					aplicarDano(alvo, CFG.DANO_RACHA)
					tombar(alvo, CFG.TOMBO_RACHA)
				else
					aplicarDano(alvo, CFG.BORDA_RACHA)
					tombar(alvo, CFG.TOMBO_RACHA * 0.5)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.7, 0), CFG.EMPURRAO_RACHA, 0.3)
				end
			end
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
# t5 · AURA — todo dano sofrido é devolvido, e quem bateu trava
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Aura"] = dict(
    objeto="Aura_Server_V1", sufixo="DramaAura",
    arquetipo="SUPORTE", tecla="R", botao="ButtonR1", alcance_mira=40,
    cutscene=False, canal="clique",
    rotulo_primaria="liga a aura: o dano sofrido volta em quem deu",
    rotulo_extra="Pulso",
    cfg="""	ALCANCE       = 6,
	DURACAO       = 10,
	FATOR_DEVOLVE = 1.0,
	TETO_DEVOLVE  = 40,
	RAIO_DEVOLVE  = 26,
	ATORDOAMENTO  = 0.9,
	ESPACO_ATORDOA = 1.6,
	RECARGA       = 20,

	RECARGA_EXTRA = 9,
	RAIO_PULSO    = 18,
	DANO_PULSO    = 24,
	EMPURRAO_PULSO = 64,
	ATORDOA_PULSO = 1.4,""",
    estado=("local auraLigada = false\n"
            "local idAura = nil\n"
            "local vigiaAura = nil\n"
            "local ultimoAtordoa = 0\n"
            "--- `function x()` sem esta linha atribui a uma GLOBAL\n"
            "local desligarAura"),
    ao_equipar="",
    ao_guardar="\tdesligarAura()\n",
    corpo='''
--''' + R + '''
-- M1 — a aura de reflexão
--
-- O pedido: "todo o dano sofrido é devolvido + atordoamento". É literalmente
-- isso. Enquanto ela está de pé, cada perda de vida do portador vira dano em
-- quem a causou, e quem a causou trava.
--
-- ELA NÃO ANULA O DANO
--
--   Devolver E não levar seria invencibilidade com passo extra. O portador
--   apanha normalmente; o que ele ganha é que apanhar CUSTA. A `DURACAO` de 10
--   s contra 20 s de recarga é o que fecha a conta: metade do tempo ligada, e
--   quem sabe disso simplesmente para de bater e espera.
--
-- O ATORDOAMENTO TEM ESPAÇAMENTO PRÓPRIO
--
--   `ESPACO_ATORDOA` — 1.6 s entre travadas. Sem isso, um agressor com uma
--   arma automática ficaria travado permanentemente pela própria cadência: a
--   aura seria um `stunlock` infinito, e nada nela diz que deveria ser.
--   O dano volta SEMPRE; o atordoamento é que é espaçado.
--
-- ONDE ELE ACHA QUEM BATEU
--
--   Na etiqueta `creator`, gravada no Humanoid da vítima pelo próprio
--   repositório. Sem Núcleo nenhum isso funciona — e sem etiqueta, o alvo mais
--   perto dentro de `RAIO_DEVOLVE` é o palpite, limitado por raio de propósito.
--''' + R + '''

function desligarAura()
	auraLigada = false
	if vigiaAura then
		vigiaAura:Disconnect()
		vigiaAura = nil
	end
	if idAura then
		vfx("PARAR", { id = idAura })
		idAura = nil
	end
end

local function refletir(quanto, agressor)
	if not (auraLigada and raiz) then return end

	local devolvido = math.min(quanto * CFG.FATOR_DEVOLVE, CFG.TETO_DEVOLVE)
	if devolvido < 1 then return end

	if not agressor then
		vfx("AURA_DEVOLVE", { posicao = raiz.Position, escala = 0.7 })
		return
	end

	local alvoRaiz = raizDe(agressor)
	aplicarDano(agressor, devolvido)

	local agora = os.clock()
	if agora - ultimoAtordoa >= CFG.ESPACO_ATORDOA then
		ultimoAtordoa = agora
		atordoar(agressor, CFG.ATORDOAMENTO)
	end

	if alvoRaiz then
		vfx("AURA_DEVOLVE", { posicao = alvoRaiz.Position,
			de = raiz.Position, escala = 1 })
		tocarEm("GOLPE", alvoRaiz.Position, 1.35)
	end

	-- reação curta: ela toca no meio de outra coisa, toda vez que a aura
	-- devolve, e sequência longa aqui deixaria o portador travado apanhando.
	if not ocupado then
		rig:PlaySequence("REFLETE", despachar({
			DEVOLVE = { faz = function() end },
		}))
	end
end

function primaria(_mira)
	if auraLigada then
		desligarAura()
		tocar("PREPARA", 0.7)
		return
	end

	ocupado = true
	rig:PlaySequence("LIGAR", despachar({
		LIGA = { sfx = { "CARGA", 1 }, faz = function()
			auraLigada = true
			ultimoAtordoa = 0
			idAura = novoId("AURA")
			-- `peca = raiz` é o que faz a aura ANDAR com o portador. Sem
			-- ela o emissor nasce no chão e o jogador sai de dentro da
			-- própria aura em dois passos. A peça viaja pelo Remote como
			-- instância — é mais barato que um tique de posição.
			vfx("AURA", { id = idAura, posicao = raiz.Position,
				peca = raiz, escala = 1, vida = CFG.DURACAO })
			vigiaAura = guardar(vigiarVida(refletir))
			task.delay(CFG.DURACAO, function()
				if auraLigada then desligarAura() end
			end)
		end },
		SUSTENTA = { faz = function()
			vfx("AURA_DEVOLVE", { posicao = raiz.Position, escala = 0.5 })
		end },
		FECHA = { sfx = { "PREPARA", 1.2 } },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Pulso
--
-- O jeito de USAR a aura em vez de esperar por ela: um estouro que atordoa em
-- volta. Ele funciona com a aura desligada — só bate mais forte com ela de pé,
-- porque o dano da aura entra por cima.
--''' + R + '''

function extra(_mira)
	ocupado = true
	rig:PlaySequence("PULSO", despachar({
		RECOLHE = { sfx = { "PREPARA", 0.95 } },
		SOLTA = { faz = function()
			local centro = raiz.Position
			vfx("AURA_PULSO", { posicao = centro, raio = CFG.RAIO_PULSO,
				escala = 1, ligada = auraLigada })
			tocarEm("IMPACTO", centro, 1.05)

			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PULSO, 12)) do
				aplicarDano(alvo, CFG.DANO_PULSO)
				atordoar(alvo, CFG.ATORDOA_PULSO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_PULSO, 0.26)
				end
			end
		end },
	}), function() ocupado = false end)
end
''')

# ═══════════════════════════════════════════════════════════════
# t6 · OLHOS LASER — o feixe contínuo, do Capitão Pátria
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Olhos Laser"] = dict(
    objeto="OlhosLaser_Server_V1", sufixo="DramaOlhos",
    arquetipo="RANGED", tecla="R", botao="ButtonR1", alcance_mira=220,
    cutscene=False, canal="feixe",
    rotulo_primaria="feixe continuo enquanto segurar o clique",
    rotulo_extra="Sobrecarga",
    cfg="""	ALCANCE       = 6,
	ALCANCE_FEIXE = 220,
	RECARGA       = 2.6,
	DURACAO_FEIXE = 6,
	INTERVALO     = 0.12,
	DANO_TIQUE    = 4,
	RAIO_FEIXE    = 3.5,
	PASSOS_FEIXE  = 22,
	ALTURA_OLHOS  = 1.5,

	RECARGA_EXTRA = 14,
	CARGA_SOBRE   = 0.9,
	RAIO_SOBRE    = 22,
	NUCLEO_SOBRE  = 8,
	DANO_SOBRE    = 62,
	BORDA_SOBRE   = 30,
	EMPURRAO_SOBRE = 72,""",
    estado=("local feixeLigado = false\n"
            "local idFeixe = nil\n"
            "local pontoFeixe = nil\n"
            "local geracaoFeixe = 0\n"
            "--- `function x()` sem esta linha atribui a uma GLOBAL\n"
            "local apontar, fechar"),
    ao_equipar="",
    ao_guardar="\tfechar()\n",
    corpo='''
--''' + R + '''
-- M1 — o feixe contínuo
--
-- O pedido foi "igual do Capitão Pátria", e o que define aquele feixe é que
-- ele é SEGURADO e VARRE. Tiro único aponta para onde estava o mouse quando
-- saiu; este acompanha, e é a varredura que corta o que atravessa.
--
-- TRÊS FASES NUM `RemoteEvent` SÓ
--
--   `ABRE` no `Tool.Activated`, `MIRA` a cada 0.08 s enquanto o clique está
--   mantido, `FECHA` no `Tool.Deactivated`. A fase vem no payload e é
--   conferida no servidor antes de qualquer coisa — um segundo remote seria
--   outra porta para o mesmo cômodo, e outra superfície para validar.
--
--   `MIRA` e `FECHA` NÃO passam por recarga e passam mesmo com `ocupado`.
--   Têm de passar: enquanto o feixe está de pé o estado É ocupado.
--
-- O DANO É POR TIQUE, NÃO POR QUADRO
--
--   `INTERVALO = 0.12` — cerca de 8 tiques por segundo, 4 de dano cada. Um
--   tique por quadro daria 60, e a mesma habilidade custaria 30 de dano por
--   segundo ou 240 dependendo do FPS de quem segura. Dano que depende de
--   framerate não é dano, é loteria.
--
-- O TETO DE TEMPO NÃO É ENFEITE
--
--   `DURACAO_FEIXE = 6`. Soltar o clique é o caminho normal de fechar, e ele
--   não pode ser o ÚNICO: um alt-tab, uma queda de conexão ou um cliente que
--   some deixariam o feixe ligado para sempre. O servidor conta o tempo dele.
--''' + R + '''

--- Colhe a linha do olho até o ponto mirado. `vistos` impede o mesmo alvo de
--- levar duas vezes por estar entre dois passos.
local function queimarLinha(destino)
	local saida = raiz.Position + Vector3.new(0, CFG.ALTURA_OLHOS, 0)
	local delta = destino - saida
	local distancia = math.min(delta.Magnitude, CFG.ALCANCE_FEIXE)
	if distancia < 1 then return saida, saida end
	local direcao = delta.Unit
	local fim = saida + direcao * distancia

	local vistos = {}
	for i = 1, CFG.PASSOS_FEIXE do
		local passo = saida + direcao * (distancia * i / CFG.PASSOS_FEIXE)
		for _, alvo in ipairs(alvosEm(passo, CFG.RAIO_FEIXE, 6)) do
			if not vistos[alvo] then
				vistos[alvo] = true
				aplicarDano(alvo, CFG.DANO_TIQUE)
			end
		end
	end
	return saida, fim
end

--- Um tique do feixe. Recursivo por `task.delay`, e a GERAÇÃO é o que impede
--- dois feixes de rodarem juntos se o jogador reabrir antes do anterior morrer.
local function tiqueFeixe(geracao, restantes)
	if not (feixeLigado and geracao == geracaoFeixe) then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		fechar()
		return
	end

	local destino = pontoFeixe or frente(CFG.ALCANCE_FEIXE)
	local saida, fim = queimarLinha(destino)
	vfx("FEIXE", { id = idFeixe, posicao = saida, para = fim, escala = 1,
		tempo = CFG.INTERVALO })

	task.delay(CFG.INTERVALO, function()
		tiqueFeixe(geracao, restantes - 1)
	end)
end

--- A mira móvel. Não é habilidade: não passa por recarga, e só anota o ponto.
--- Quem decide se ele ainda vale é o servidor, que sabe se o feixe existe.
function apontar(mira)
	if not feixeLigado then return end
	pontoFeixe = mira
end

function fechar()
	if not feixeLigado then return end
	feixeLigado = false
	geracaoFeixe = geracaoFeixe + 1
	pontoFeixe = nil
	if idFeixe then
		vfx("PARAR", { id = idFeixe })
		idFeixe = nil
	end
	-- saída cedo em vez de aninhar: com o `PlaySequence` dentro de um `if`, o
	-- bloco do `despachar` fecha com uma tabulação a mais, e o
	-- `TESTES/verificar_beats.py` casa o fim errado — ele leu os beats da
	-- sequência SEGUINTE como se fossem desta. O verificador estava certo em
	-- reclamar; quem estava torto era a indentação.
	if not rig then
		ocupado = false
		return
	end
	rig:PlaySequence("FEIXE_FECHA", despachar({
		CORTA = { sfx = { "GOLPE", 1.4 } },
	}), function() ocupado = false end)
end

function primaria(mira)
	if feixeLigado then return end
	ocupado = true
	feixeLigado = true
	pontoFeixe = mira
	geracaoFeixe = geracaoFeixe + 1
	local geracao = geracaoFeixe
	idFeixe = novoId("FEIXE")

	rig:PlaySequence("FEIXE_ABRE", despachar({
		MIRA = { sfx = { "PREPARA", 1.4 } },
		ATIRA = { sfx = { "CARGA", 1.25 }, faz = function()
			-- a pose fica em `FEIXE_OLHOS` até alguém tocar outra sequência:
			-- `PlaySequence` para no último keyframe e não volta ao IDLE.
			tiqueFeixe(geracao, math.floor(CFG.DURACAO_FEIXE / CFG.INTERVALO))
		end },
	}))
end

--''' + R + '''
-- R — Sobrecarga
--
-- O outro lado do mesmo poder: em vez de varrer, ele CONCENTRA. Carrega
-- `CARGA_SOBRE` segundos e estoura num ponto, com núcleo e borda.
--
-- Ela FECHA o feixe antes de começar. Os dois usam os olhos, e deixar os dois
-- ligados ao mesmo tempo daria dois desenhos disputando a mesma cabeça.
--''' + R + '''

function extra(mira)
	fechar()
	ocupado = true
	local destino = mira

	rig:PlaySequence("SOBRECARGA", despachar({
		MIRA = { sfx = { "PREPARA", 0.9 } },
		ABRE = { faz = function()
			vfx("SOBRECARGA_CARGA", { posicao = raiz.Position
				+ Vector3.new(0, CFG.ALTURA_OLHOS, 0), escala = 1,
				vida = CFG.CARGA_SOBRE })
		end },
		CARREGA = { sfx = { "CARGA", 0.75 } },
		ESTOURA = { faz = function()
			local saida = raiz.Position + Vector3.new(0, CFG.ALTURA_OLHOS, 0)
			vfx("SOBRECARGA", { posicao = destino, de = saida,
				raio = CFG.RAIO_SOBRE, escala = 1 })
			tocarEm("IMPACTO", destino, 0.7)

			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_SOBRE, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - destino).Magnitude
					or CFG.RAIO_SOBRE
				if d <= CFG.NUCLEO_SOBRE then
					aplicarDano(alvo, CFG.DANO_SOBRE)
				else
					aplicarDano(alvo, CFG.BORDA_SOBRE)
				end
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - destino)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_SOBRE, 0.28)
				end
			end
		end },
		FIM = { sfx = { "GOLPE", 0.8 } },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
# t7 · CORTADA FATAL — substitui a `TryHard`
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Cortada Fatal"] = dict(
    objeto="CortadaFatal_Server_V1", sufixo="DramaCortada",
    arquetipo="MELEE", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=True, canal="clique",
    rotulo_primaria="cortada de cima, com onda no chao",
    rotulo_extra="Fatal",
    cfg="""	ALCANCE       = 6.5,
	RAIO_CORTADA  = 8,
	DANO          = 34,
	EMPURRAO      = 58,
	TOMBO         = 1.4,
	RECARGA       = 2.4,
	ALCANCE_ONDA  = 26,
	LARGURA_ONDA  = 5,
	DANO_ONDA     = 18,
	PASSOS_ONDA   = 8,

	RECARGA_EXTRA = 26,
	RAIO_ALVO     = 14,
	LIMIAR        = 0.4,
	DANO_FATAL    = 120,
	DANO_FRACO    = 44,
	AVANCO        = 5,""",
    estado="local alvoFatal = nil\nlocal fatalArmado = false",
    ao_equipar="",
    ao_guardar="\talvoFatal = nil\n\tfatalArmado = false\n\tfecharCena()\n",
    corpo='''
--''' + R + '''
-- M1 — a cortada
--
-- Desce de CIMA. O arco passa inteiro acima da cabeça antes de cair, e a onda
-- corre pelo chão à frente — é o que separa esta Tool do soco do `Combate` e
-- do corredor do `Impacto Forte`.
--
-- Ela SUBSTITUI o combo de quatro da `TryHard`. Combo de quatro socos ao lado
-- do combo de três do `Combate` eram a mesma Tool com outro nome.
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CORTADA", despachar({
		ERGUE = { sfx = { "PREPARA", 0.9 } },
		SEGURA = { faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ Vector3.new(0, 3.4, 0), escala = 1 })
		end },
		DESCE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local direcao = raiz.CFrame.LookVector
			local chao = raiz.Position - Vector3.new(0, 2.2, 0)

			vfx("CORTADA", { posicao = ponto, cframe = raiz.CFrame,
				alcance = CFG.ALCANCE_ONDA, escala = 1 })
			tocarEm("IMPACTO", ponto, 0.85)

			local vistos = {}
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_CORTADA, 8)) do
				vistos[alvo] = true
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				empurrar(alvo, direcao + Vector3.new(0, 0.25, 0),
					CFG.EMPURRAO, 0.24)
			end

			-- a onda: corre pelo chão, e é o que dá alcance à cortada
			for i = 1, CFG.PASSOS_ONDA do
				local passo = chao + direcao
					* (CFG.ALCANCE_ONDA * i / CFG.PASSOS_ONDA)
				for _, alvo in ipairs(alvosEm(passo, CFG.LARGURA_ONDA, 6)) do
					if not vistos[alvo] then
						vistos[alvo] = true
						aplicarDano(alvo, CFG.DANO_ONDA)
						tombar(alvo, CFG.TOMBO * 0.5)
					end
				end
			end
		end },
		FIM = { sfx = { "GOLPE", 1.05 } },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Fatal  (CUTSCENE)
--
-- A execução. Ela só sai CHEIA em alvo abaixo de `LIMIAR` da vida — 40%.
--
-- POR QUE O LIMIAR
--
--   Cutscene de execução que o alvo sobrevive é anticlímax: seis segundos de
--   câmera presa para um golpe que não fechou nada. E execução SEM limiar é só
--   um golpe grande com câmera, que é o que a `TryHard` era.
--
--   Acima do limiar a habilidade não é recusada — ela sai, com `DANO_FRACO` e
--   sem cena. Recusar gastaria a recarga de 26 s do jogador por um alvo que
--   ele não tinha como medir com precisão.
--
-- O ALVO É FIXADO NO INÍCIO, como na série do `Corte Frio`.
--''' + R + '''

function extra(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.RAIO_ALVO), CFG.RAIO_ALVO)
	if not alvo then
		tocar("PREPARA", 0.75)
		return
	end

	local fracao = alvo.MaxHealth > 0 and (alvo.Health / alvo.MaxHealth) or 1
	fatalArmado = fracao <= CFG.LIMIAR
	alvoFatal = alvo

	-- ACIMA do limiar: o golpe sai, sem cena e sem o dano de execução.
	if not fatalArmado then
		ocupado = true
		rig:PlaySequence("CORTADA", despachar({
			ERGUE = { sfx = { "PREPARA", 1.1 } },
			DESCE = { faz = function()
				local alvoRaiz = raizDe(alvoFatal)
				aplicarDano(alvoFatal, CFG.DANO_FRACO)
				tombar(alvoFatal, 1)
				if alvoRaiz then
					vfx("CORTADA", { posicao = alvoRaiz.Position,
						cframe = raiz.CFrame, alcance = 8, escala = 0.8 })
					tocarEm("IMPACTO", alvoRaiz.Position, 1)
				end
			end },
		}), function()
			ocupado = false
			alvoFatal = nil
		end)
		return
	end

	ocupado = true
	rig:PlaySequence("FATAL", despachar({
		CAMERA = { cam = true, sfx = { "CARGA", 0.7 }, faz = function()
			abrirCena(alvoFatal, "FATAL")
			rig:LockCharacter(true)
			if alvoFatal and alvoFatal.Health > 0 then
				atordoar(alvoFatal, 4)
			end
		end },
		ERGUE = { cam = true, faz = function()
			vfx("CARREGA", { posicao = raiz.Position
				+ Vector3.new(0, 4, 0), escala = 1.4 })
		end },
		CARGA = { cam = true, sfx = { "PREPARA", 0.6 } },
		AVANCA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			if alvoRaiz and raiz then
				local delta = alvoRaiz.Position - raiz.Position
				local plano = Vector3.new(delta.X, 0, delta.Z)
				if plano.Magnitude > CFG.AVANCO then
					empurrar(humanoide, plano, plano.Magnitude * 2.6, 0.22)
				end
			end
		end },
		SEGURA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			if alvoRaiz then
				vfx("FATAL_MARCA", { posicao = alvoRaiz.Position, escala = 1 })
			end
		end },
		EXECUTA = { cam = true, faz = function()
			local alvoRaiz = raizDe(alvoFatal)
			local onde = alvoRaiz and alvoRaiz.Position or frente(CFG.ALCANCE)
			vfx("FATAL", { posicao = onde, cframe = raiz.CFrame, escala = 1 })
			tocarEm("IMPACTO", onde, 0.55)
			if alvoFatal and alvoFatal.Health > 0 then
				aplicarDano(alvoFatal, CFG.DANO_FATAL)
				tombar(alvoFatal, 2.4)
			end
		end },
		FIM = { cam = true, faz = function()
			rig:LockCharacter(false)
			fecharCena()
			alvoFatal = nil
			fatalArmado = false
		end },
	}), function()
		ocupado = false
		rig:LockCharacter(false)
		fecharCena()
		alvoFatal = nil
		fatalArmado = false
	end)
end
''')

def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    d = dict(d)
    d["extra_require"] = ("local CutsceneRemote = Tool:WaitForChild(\"CutsceneRemote\")\n"
                          if d["cutscene"] else "")

    # `feixe` só o `Olhos Laser`; as outras seis são clique
    feixe = d.get("canal") == "feixe"
    d["ligacao_primaria"] = LIGACAO_FEIXE if feixe else LIGACAO_CLIQUE
    d["ciclo_primaria"] = CICLO_FEIXE if feixe else CICLO_CLIQUE

    corpo = (CUTSCENE if d["cutscene"] else "") + DESPACHANTE + d["corpo"]
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

    print("%-20s %5d linhas de Server%s%s"
          % (tool, servidor.count("\n") + 1,
             " · CutsceneCam" if d["cutscene"] else "",
             " · feixe segurado" if feixe else ""))
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
