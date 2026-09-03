#!/usr/bin/env python3
"""
gerar_servers_noob.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule`, o `R6CFrameAnimator` e — nas
duas que têm cena — a `CutsceneCam` das 7 Tools do conjunto NOOB.

    python3 FERRAMENTAS/gerar_servers_noob.py

OS NÚMEROS DA ORIGEM SÃO DE SHOWCASE, E ESTÃO TODOS DECLARADOS

    | Ataque | Raio na origem | Dano | INSTAKILL | Vira |
    |---|---|---|---|---|
    | `Shot` | — | **`Foe:Destroy()`** | — | 34, feixe de 220 |
    | `BlastShoot` | **400** | **999** | sim | 88 em raio 22 |
    | `Lava` | **900** | 90–100 | sim | 105 no núcleo, 46 na borda, raio 30 |
    | `TimeStop` | **1000** | 25–50 | não | 18 e trava, raio 26 |
    | `ClockDestroyer` | 15 | 30–40 | não | 42 em raio 15 (o único já na faixa) |
    | `BlackRole` | 100 | 90–100 | sim | 26 por tique, colapso 70, raio 24 |
    | `Neckless` | — | `ApplyDamage(HUM, 0, ...)` | — | 14 por tique enquanto segura |
    | `Lunar_Blast` | 25 | `killnearest(25, 25)` | — | 62 em raio 20 |
    | `SuperDominus` | 200 | 100 | sim | 130 no núcleo, 58 na borda, raio 34 |

    Quatro dos nove eram INSTAKILL e um fazia 999 em raio 400. Raio 1000 é o
    mapa inteiro. A conversão guarda a IDENTIDADE — a Lava é a de área, o
    BlastShoot é o tiro pesado, o ClockDestroyer é o preciso — e traz tudo para
    a faixa dos outros conjuntos (o teto do repositório é a `Era Do Fim`, 120
    no núcleo em raio 58).

    O `ClockDestroyer` é o único que já estava na faixa: 30–40 em raio 15. Ele
    entra quase intocado, e é a prova de que o autor sabia — os outros oito são
    escolha de exibição, não descuido.

O `Banish` NÃO ATRAVESSA

    ```lua
    Foe:Destroy()
    CLONE.Parent = Effects
    CLONE:BreakJoints()
    ```

    Destruir o alvo tira o abate do Núcleo e apaga o personagem do jogador. É a
    terceira vez que este padrão chega aqui — depois do `death()` do Xester e do
    `enemyhum.Parent:Remove()` do Ato de Desaparecer — e sai pelo mesmo caminho:
    `TakeDamage` pesado, com o crédito indo para quem atirou.

O BEAT VEM COMO KEYFRAME

    `onBeat(kf, indice)`, e a marca está em `kf.marca`. Comparar o keyframe com
    string nunca dá verdadeiro e falha em SILÊNCIO. O helper `marcaDe` está
    escrito desde a primeira linha.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_NOOB = os.path.join(DADOS, "VFXModule_Noob.lua")
CAM_NOOB = os.path.join(DADOS, "CutsceneCam_Noob.lua")


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto NOOB)
--
-- Sai do `noob_despertado.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_noob.py` para o mapa.
--
--   M1   {rotulo_primaria}
--   {tecla}    {rotulo_extra}   (Extra, por `AcaoRemote` — e por botão no celular)
--
-- DE ONDE VIERAM OS NÚMEROS (§12.12.2)
{origem}--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_noob.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
{extra_require}
--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "{arquetipo}"

local CFG = {{
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
{cfg}
}}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA, e o repositório inteiro dependia
--    dele: eram 217 pontos que conferiam só o TIPO.
--
--    `Vector3.new(0/0, 0/0, 0/0)` é um `Vector3` legítimo para o `typeof`.
--    Um cliente modificado manda isso, `.Unit` devolve NaN, e força NaN
--    aplicada a uma peça envenena a assembly dela — o alvo trava, voa para
--    coordenada absurda, ou o solver do motor engasga. Nenhum `pcall` pega,
--    porque não há erro: a conta simplesmente não tem resultado.
--
--    `n ~= n` é o único teste de NaN que funciona em Lua: NaN é o único valor
--    que não é igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda
--    na mesma linha.
--
-- E RATE LIMIT É DO SERVIDOR, não do cliente.
--
--    O `Client` já limita a 20 Hz, e isso não vale nada: quem manda o pacote
--    é o cliente, e cliente modificado manda a 2 000 Hz. O limite que conta
--    é o daqui.
--═══════════════════════════════════════════════════════════════

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
---
--- O corte por alcance não é só anticheat: mira a 5 000 studs faria o
--- `noChao()` varrer 400 studs de raycast a partir de um ponto onde não há
--- mapa, e a habilidade nasceria no vazio.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > CFG.MIRA_MAX then
		return raiz.Position + delta.Unit * CFG.MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem está abusando é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= CFG.PEDIDOS_POR_SEG
end
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

--- Jitter determinístico em [-1,1]. No lugar dos 21 `math.random` da origem —
--- e com todos os clientes desenhando, um sorteio faria cada um ver uma cena
--- diferente, o que lê como lag.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Faixa determinística no lugar de `math.random(minimo, maximo)`.
local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
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
-- A ORIGEM NÃO TINHA UM `TakeDamage`. Ela escrevia em `Health` cinco vezes,
-- chamava `BreakJoints` seis, e o `Banish` fazia `Foe:Destroy()` — matar por
-- deleção tira o abate do Núcleo e apaga o personagem do jogador.
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

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
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
--- não é teleporte, é âncora. Nunca `Anchored`, que travaria o personagem
--- inteiro e deixaria o jogador preso se a Tool sumisse no meio.
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

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta —
--- a origem chamava seis.
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

--- Dano em área com NÚCLEO e BORDA.
---
--- A origem fazia `ApplyAoE(pos, RAIO, MIN, MAX, FLING, INSTAKILL)` com um raio
--- só e dano chapado — e quatro das nove marcavam INSTAKILL. Dois raios é o que
--- impede uma explosão grande de matar meio servidor por estar por perto.
local function golpearArea(centro, raio, raioNucleo, danoNucleo, danoBorda,
		forca, tombo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 16)) do
		local alvoRaiz = raizDe(alvo)
		local d = alvoRaiz and (alvoRaiz.Position - centro).Magnitude or raio
		if d <= raioNucleo then
			aplicarDano(alvo, danoNucleo)
			if tombo then tombar(alvo, tombo) end
		else
			aplicarDano(alvo, danoBorda)
			if tombo then tombar(alvo, tombo * 0.5) end
		end
		if alvoRaiz and forca then
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.6, 0),
				forca, 0.32)
		end
		pegos = pegos + 1
	end
	return pegos
end

'''

CUTSCENE = '''
--═══════════════════════════════════════════════════════════════
-- A CUTSCENE — um `FireClient` POR ESPECTADOR
--
-- `GRAMATICA_CUTSCENE.md` regra 2: enquadramento por espectador.
--
-- As duas cenas deste conjunto nascem NO PORTADOR: a laje sobe sob os pés
-- dele, a coroa desce sobre a cabeça. A plateia é quem está no raio, e cada um
-- recebe o papel dele. Quem está fora não perde a câmera.
--
-- ⚠️ ZERO `Camera` neste arquivo, e em nenhum Server do repositório. Câmera é
--    100% cliente; o servidor manda beat NOMEADO e nada mais.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(plateia, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

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
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	if not taxaOk() then return end
	-- a whitelist de ação: qualquer tecla fora desta é descartada
	if tecla ~= "{tecla}" then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end
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
-- ⚠️ ISTO VIVIA FORA DO GERADOR, e o defeito estava em NOVE conjuntos.
--
--    A ligação tinha sido enxertada nos arquivos PRONTOS por
--    `FERRAMENTAS/ligar_deposito.py`, uma vez. Enquanto ninguém regerasse,
--    tudo passava. A primeira regeneração de cada conjunto a perdia — em
--    silêncio, porque o Server continua funcionando sem ela; o que para é o
--    VFX sair da Tool.
--
--    Enxerto que não volta para o gerador é conserto que dura até a próxima
--    geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
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

--- ⚠️ `beatCena` DECLARADO, mesmo nas Tools sem cutscene.
---
--- A guarda do despachante é `if kf.cam and beatCena then`, e sem esta linha
--- `beatCena` é uma GLOBAL IMPLÍCITA: em Lua ler global inexistente devolve
--- `nil`, então o curto-circuito segura e nada quebra — hoje.
---
--- O risco não é este arquivo: é qualquer script do place que um dia crie uma
--- global com esse nome. A partir daí `kf.cam` verdadeiro chamaria função de
--- estranho, com os argumentos desta Tool.
---
--- Nas Tools COM cutscene, o `local function beatCena` mais abaixo sombreia
--- este `nil` — que é o comportamento certo, e é por isso que a declaração
--- pode ser incondicional.
local beatCena = nil

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
-- Script com RunContext = Client — {tool}  (conjunto NOOB)
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
-- O terceiro argumento faz o Roblox desenhar o botão de toque sozinho. A origem
-- tinha uma `ScreenGui` chamada `Talk` com dois `TextLabel`; `ScreenGui` dentro
-- de Tool é proibida, e o botão do CAS faz o trabalho sem sair da Tool.
--
-- Gerado por FERRAMENTAS/gerar_servers_noob.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO = "Noob_{sufixo}_{tecla}"
local ALCANCE_MIRA = {alcance_mira}

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" then
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


CONJUNTO["Tiro do Vazio"] = dict(
    objeto="TirodoVazio_Server_V1", sufixo="NoobTiroVazio",
    arquetipo="ARCANO", tecla="R", botao="ButtonR1", alcance_mira=220,
    cutscene=False,
    rotulo_primaria="feixe que alcanca 220 studs",
    rotulo_extra="Disparo",
    origem=[
        "`Shot`: CastProperRay(Hole.Position, Mouse.Hit.p, **1000**) (un.lua:1854)",
        "`Banish(HIT.Parent)` -> `Foe:Destroy()` VIROU dano pesado (un.lua:760)",
        "`BlastShoot`: ApplyAoE(int.CFrame, **400**, **999**, 999, false, **true**)",
        "   raio 400 com 999 de dano e INSTAKILL -> 88 em raio 22",
    ],
    cfg="""	ALCANCE        = 12,
	ALCANCE_FEIXE  = 220,
	RAIO_FEIXE     = 4,
	DANO           = 34,
	EMPURRAO       = 30,
	RECARGA        = 1.2,

	RECARGA_EXTRA  = 9,
	ALCANCE_TIRO   = 220,
	RAIO_TIRO      = 22,
	RAIO_NUCLEO    = 8,
	DANO_TIRO      = 88,
	DANO_BORDA     = 38,
	EMPURRAO_TIRO  = 84,
	TOMBO          = 1.6,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o feixe
--
-- A origem lançava um raio de 1000 studs e, se acertasse, chamava `Banish`, que
-- fazia `Foe:Destroy()`. Aqui o alcance é 220 e o resultado é dano: destruir o
-- alvo tira o abate do Núcleo e apaga o personagem do jogador.
--
-- O ponto de saída é o Handle, não uma peça chamada `Hole` — aquela era criada
-- em código, dentro do modelo `banish` que não existe mais.
--═══════════════════════════════════════════════════════════════

local function mirarPonto(mira)
	local origem = Handle.Position
	local destino = mira or frente(CFG.ALCANCE_FEIXE)
	local delta = destino - origem
	if delta.Magnitude > CFG.ALCANCE_FEIXE then
		destino = origem + delta.Unit * CFG.ALCANCE_FEIXE
	end
	return origem, destino
end

function primaria(mira)
	ocupado = true
	rig:PlaySequence("TIRO", despachar({
		CARGA = { sfx = { "CARGA", 1.1 }, faz = function()
			vfx("CONJURA", { posicao = Handle.Position, escala = 0.8,
				duracao = 0.4 })
		end },
		GOLPE = { faz = function()
			local origem, destino = mirarPonto(mira)
			vfx("FEIXE", { origem = origem, destino = destino,
				grossura = 1.2, escala = 1 })
			tocarEm("TIRO", origem, 1 + jitter(0.3) * 0.08)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_FEIXE, 4)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, destino - origem, CFG.EMPURRAO, 0.18)
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o disparo pesado
--
-- É o `BlastShoot`, um dos três ataques que a origem escreveu e ENTERROU: ele
-- só sai no `mode == "banish"`, e a tecla `e` que ligaria a forma cai em dois
-- `if` seguidos, terminando em `mode = "light"`.
--
-- Na origem: raio 400, dano 999, INSTAKILL. Aqui: 88 no núcleo de 8, 38 na
-- borda de 22.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	rig:PlaySequence("DISPARO", despachar({
		CARGA = { sfx = { "CARGA", 0.75 }, faz = function()
			vfx("CONJURA", { posicao = Handle.Position, escala = 1.4,
				duracao = 0.55 })
		end },
		GOLPE = { faz = function()
			local origem = Handle.Position
			local destino = mira or frente(CFG.ALCANCE_TIRO)
			local delta = destino - origem
			if delta.Magnitude > CFG.ALCANCE_TIRO then
				destino = origem + delta.Unit * CFG.ALCANCE_TIRO
			end
			vfx("DISPARO", { origem = origem, destino = destino,
				grossura = 3.4, escala = 1.4 })
			tocarEm("VAZIO", destino, 0.8)
			tocarEm("TIRO", origem, 0.7)
			golpearArea(destino, CFG.RAIO_TIRO, CFG.RAIO_NUCLEO,
				CFG.DANO_TIRO, CFG.DANO_BORDA, CFG.EMPURRAO_TIRO, CFG.TOMBO)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["Chuva de Lava"] = dict(
    objeto="ChuvadeLava_Server_V1", sufixo="NoobChuvaLava",
    arquetipo="EXPLOSIVO", tecla="R", botao="ButtonR1", alcance_mira=60,
    cutscene=True,
    rotulo_primaria="a laje que sobe — ultimate com cutscene",
    rotulo_extra="—  (esta Tool tem uma habilidade so)",
    origem=[
        "laje clonada de `script.Lava`, **900 x 20 x 900 studs** (un.lua:1918)",
        "sobe 2 studs por quadro, 10 quadros, com `wait(0.08)` (un.lua:1938)",
        "ApplyAoE(new.Position, **900**, 90, 100, 0, **true**) (un.lua:1936)",
        "   raio 900 com INSTAKILL -> 105 no nucleo de 12, 46 na borda de 30",
        "som 159882598 volume 10 e 62339698 volume 10 -> volume 2",
    ],
    cfg="""	ALCANCE        = 10,
	RECARGA        = 34,
	RAIO_CENA      = 46,
	RAIO_LAVA      = 30,
	RAIO_NUCLEO    = 12,
	DANO_NUCLEO    = 105,
	DANO_BORDA     = 46,
	EMPURRAO       = 110,
	TOMBO          = 2.6,
	DURACAO_LAJE   = 4.5,
	LENTIDAO       = 0.6,
	TEMPO_LENTO    = 3,

	RECARGA_EXTRA  = 1,""",
    estado="local lajeId = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a laje, COM CUTSCENE
--
-- ULTIMATE: 7.10 s com 70% de preparação, dentro da faixa da regra 5.
--
-- A peça de origem tem **900 × 20 × 900 studs**, o mesmo 900 do
-- `ApplyAoE(..., 900, ...)`: a laje ERA o raio. Os dois vieram para 30 juntos,
-- porque mexer num sem o outro deixaria o efeito mentindo sobre o alcance.
--═══════════════════════════════════════════════════════════════

local function apagarLaje()
	if lajeId then
		vfx("APAGAR", { id = lajeId })
		lajeId = nil
	end
end

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 14), "CAMERA")

	rig:PlaySequence("LAVA", despachar({
		CAMERA = { sfx = { "GRAVE", 0.55 } },
		CARGA = { cam = true, sfx = { "ESTOURO", 0.6 } },
		SEGURA = { cam = true },
		DESCE = { cam = true, faz = function()
			apagarLaje()
			local onde = raiz and raiz.Position or centro
			lajeId = novoId("LAJE")
			vfx("LAVA", { posicao = onde, escala = 1, raio = CFG.RAIO_LAVA,
				duracao = CFG.DURACAO_LAJE, id = lajeId })
			tocarEm("GRAVE", onde, 0.5)
		end },
		GOLPE = { cam = true, faz = function()
			local onde = raiz and raiz.Position or centro
			vfx("LAVA_FIM", { posicao = onde, escala = 1.6 })
			tocarEm("ESTOURO", onde, 0.7)
			tocarEm("ECO", onde, 0.6)
			golpearArea(onde, CFG.RAIO_LAVA, CFG.RAIO_NUCLEO,
				CFG.DANO_NUCLEO, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_LAVA, 16)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
			end
		end },
		FIM = { faz = function()
			apagarLaje()
			fecharCena()
		end },
	}), function()
		apagarLaje()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- SEM EXTRA
--
-- O `mode == "banish"` da origem tinha três ataques e os três já estão no
-- `Tiro do Vazio` (z e c). A Lava é o `x`, e sozinha: uma ultimate de 7 s com
-- segunda habilidade por cima seria a Tool inteira num botão.
--
-- `extra` existe e não faz nada porque o `AcaoRemote` está montado — a Tool
-- não ganha botão de toque, e apertar a tecla não deve dar erro.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	return
end
''',
    ao_equipar="", ao_guardar="\tapagarLaje()\n\tfecharCena()\n",
)


CONJUNTO["Parada do Tempo"] = dict(
    objeto="ParadadoTempo_Server_V1", sufixo="NoobParadaTempo",
    arquetipo="ARCANO", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=False,
    rotulo_primaria="trava quem esta no raio",
    rotulo_extra="Relogio",
    origem=[
        "`TimeStop`: ApplyAoE(HITPOS, **1000**, 25, 50, 0, false) (un.lua:1950)",
        "   raio 1000 e o mapa inteiro -> 18 em raio 26",
        "som 1636723480 volume 10 -> volume 1.6",
        "`ClockDestroyer`: ApplyAoE(bomb.Position, 15, 30, 40, 0, false)",
        "   O UNICO ja na faixa: entra quase intocado, 42 em raio 15",
        "OS DOIS eram inalcancaveis: so saem no mode `master`, e a tecla `e`",
        "   cai em dois `if` seguidos terminando em mode = `light`",
    ],
    cfg="""	ALCANCE        = 10,
	RECARGA        = 26,
	RAIO_PARADA    = 26,
	DANO_PARADA    = 18,
	DURACAO_TRAVA  = 2.4,
	LENTIDAO       = 0.25,
	TEMPO_LENTO    = 3.5,

	RECARGA_EXTRA  = 11,
	RAIO_RELOGIO   = 15,
	RAIO_NUCLEO    = 6,
	DANO_RELOGIO   = 42,
	DANO_BORDA     = 22,
	EMPURRAO       = 62,
	TOMBO          = 1.4,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — parar o tempo
--
-- A origem cobria **raio 1000** — o mapa inteiro, para todo mundo, de um
-- clique. Aqui são 26.
--
-- Travar é `BodyPosition` com prazo, nunca `Anchored`: se a Tool sumir no meio,
-- o alvo volta a andar sozinho quando o `Debris` recolher a âncora.
--═══════════════════════════════════════════════════════════════

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("PARAR", despachar({
		CARGA = { sfx = { "TEMPO", 1.1 }, faz = function()
			vfx("CONJURA", { posicao = Handle.Position, escala = 1,
				duracao = 0.45 })
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			tocarEm("TEMPO", centro, 0.85)
			tocarEm("ZUMBIDO", centro, 1)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PARADA, 16)) do
				aplicarDano(alvo, CFG.DANO_PARADA)
				prender(alvo, CFG.DURACAO_TRAVA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("PARAR", { posicao = alvoRaiz.Position, escala = 1,
						duracao = CFG.DURACAO_TRAVA })
				end
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o relógio
--
-- `ClockDestroyer`, e é o único ataque dos nove cujos números da origem já
-- estavam na faixa: 30–40 em raio 15. Ele entra quase intocado — 42 no núcleo,
-- 22 na borda — e serve de prova de que os outros oito são escolha de exibição,
-- não descuido do autor.
--═══════════════════════════════════════════════════════════════

function extra(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("RELOGIO", despachar({
		CARGA = { sfx = { "ZUMBIDO", 0.9 } },
		GOLPE = { faz = function()
			local onde = destino or frente(CFG.ALCANCE)
			vfx("RELOGIO", { posicao = onde, escala = 1.2 })
			tocarEm("ESTOURO", onde, 1.15)
			golpearArea(onde, CFG.RAIO_RELOGIO, CFG.RAIO_NUCLEO,
				CFG.DANO_RELOGIO, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["Buraco Negro"] = dict(
    objeto="BuracoNegro_Server_V1", sufixo="NoobBuracoNegro",
    arquetipo="ARCANO", tecla="R", botao="ButtonR1", alcance_mira=55,
    cutscene=False,
    rotulo_primaria="abre a esfera que puxa",
    rotulo_extra="Colapso",
    origem=[
        "`BlackRole`: ApplyAoE(ball.Position, **100**, 90, 100, 0, **true**)",
        "   raio 100 com INSTAKILL -> 26 por tique e 70 no colapso, raio 24",
        "som 487214658 e 262562442 (un.lua:1959-2020)",
        "fala `beware of the black hole friend.` -> nao entra: Chat e do modelo",
        "TAMBEM era inalcancavel: so sai no mode `master`",
    ],
    cfg="""	ALCANCE        = 12,
	RECARGA        = 30,
	RAIO_BURACO    = 24,
	DURACAO        = 4,
	INTERVALO_TICK = 0.7,
	DANO_TICK      = 26,
	SUGA           = 34,

	RECARGA_EXTRA  = 8,
	RAIO_NUCLEO    = 9,
	DANO_COLAPSO   = 70,
	DANO_BORDA     = 32,
	EMPURRAO       = 96,
	TOMBO          = 2,""",
    estado="local buracoId = nil\nlocal buracoOnde = nil\nlocal geracao = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — abrir o buraco
--
-- A origem fazia raio **100 com INSTAKILL**. Aqui o buraco vive 4 s, puxa, e
-- cobra 26 por tique de 0.7 s — quem entrar e sair rápido paga pouco.
--
-- Quem move a geometria é o CLIENTE, por tween: o servidor manda o efeito uma
-- vez com a duração no payload e só volta a falar nos tiques.
--═══════════════════════════════════════════════════════════════

local function fecharBuraco()
	geracao = geracao + 1
	if buracoId then
		vfx("APAGAR", { id = buracoId })
		buracoId = nil
	end
	buracoOnde = nil
end

local function manterBuraco(onde, id)
	geracao = geracao + 1
	local minha = geracao
	local ate = os.clock() + CFG.DURACAO

	task.spawn(function()
		while minha == geracao and os.clock() < ate do
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_BURACO, 14)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				puxar(alvo, onde, CFG.SUGA, CFG.INTERVALO_TICK * 0.8)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			buracoId = nil
			buracoOnde = nil
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ABRIR", despachar({
		CARGA = { sfx = { "VAZIO", 1 }, faz = function()
			vfx("CONJURA", { posicao = Handle.Position, escala = 1.2,
				duracao = 0.5 })
		end },
		GOLPE = { faz = function()
			fecharBuraco()
			local onde = (destino or frente(CFG.ALCANCE)) + Vector3.new(0, 3, 0)
			buracoOnde = onde
			buracoId = novoId("BURACO")
			vfx("BURACO", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO, id = buracoId })
			tocarEm("VAZIO", onde, 0.75)
			manterBuraco(onde, buracoId)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- EXTRA — o colapso
--
-- Consome o buraco. Sem um aberto ela ainda sai, com metade do dano — a Tool
-- nunca fica inerte, mas o par certo rende mais.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	ocupado = true
	local onde = buracoOnde
	rig:PlaySequence("COLAPSO", despachar({
		CARGA = { sfx = { "COLAPSO", 1.1 } },
		SEGURA = { faz = function()
			local centro = onde or frente(CFG.ALCANCE)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_BURACO, 14)) do
				puxar(alvo, centro, CFG.SUGA * 1.6, 0.3)
			end
		end },
		GOLPE = { faz = function()
			local centro = onde or frente(CFG.ALCANCE)
			local cheio = onde ~= nil
			fecharBuraco()
			vfx("BURACO_FIM", { posicao = centro, escala = cheio and 1.6 or 0.9 })
			tocarEm("COLAPSO", centro, 0.7)
			tocarEm("ECO", centro, 0.65)
			golpearArea(centro, CFG.RAIO_BURACO, CFG.RAIO_NUCLEO,
				cheio and CFG.DANO_COLAPSO or CFG.DANO_COLAPSO * 0.5,
				cheio and CFG.DANO_BORDA or CFG.DANO_BORDA * 0.5,
				CFG.EMPURRAO, cheio and CFG.TOMBO or nil)
		end },
	}), function()
		ocupado = false
	end)
end
''',
    ao_equipar="", ao_guardar="\tfecharBuraco()\n",
)


CONJUNTO["Colar das Trevas"] = dict(
    objeto="ColardasTrevas_Server_V1", sufixo="NoobColarTrevas",
    arquetipo="ARCANO", tecla="R", botao="ButtonR1", alcance_mira=35,
    cutscene=False,
    rotulo_primaria="agarra o alvo pelo pescoco e drena",
    rotulo_extra="—  (esta Tool tem uma habilidade so)",
    origem=[
        "`Neckless`: ApplyDamage(HUM, **0**, true) (un.lua:2021-2080)",
        "   dano ZERO na origem: o agarrao existia e nao cobrava nada",
        "sons 235097614 e 363808674",
        "unico ataque do mode `dark`, e o unico de CONTATO do modelo inteiro",
    ],
    cfg="""	ALCANCE        = 9,
	RAIO_ALVO      = 12,
	RECARGA        = 18,
	DURACAO_COLAR  = 2.5,
	INTERVALO_TICK = 0.5,
	DANO_TICK      = 14,
	DANO_SOLTA     = 30,
	LENTIDAO       = 0.35,
	EMPURRAO       = 58,
	TOMBO          = 1.5,

	RECARGA_EXTRA  = 1,""",
    estado="local colarId = nil\nlocal geracao = 0",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — o agarrão
--
-- Na origem o `Neckless` chamava `ApplyDamage(HUM, 0, true)`: **dano zero**. O
-- agarrão existia, prendia, e não cobrava nada. É o oposto dos outros oito, que
-- matavam de um golpe — e sugere que o autor parou no meio deste.
--
-- Aqui ele drena: 14 por tique de 0.5 s enquanto segura, e 30 ao soltar.
--
-- É o único ataque de CONTATO do modelo inteiro. Sem alvo não acontece — e a
-- recarga é devolvida, porque cobrar espera por um agarrão que pegou o ar é
-- punir quem errou duas vezes.
--═══════════════════════════════════════════════════════════════

local function soltarColar()
	geracao = geracao + 1
	if colarId then
		vfx("APAGAR", { id = colarId })
		colarId = nil
	end
end

local function manterColar(alvo, id)
	geracao = geracao + 1
	local minha = geracao
	local ate = os.clock() + CFG.DURACAO_COLAR

	task.spawn(function()
		while minha == geracao and os.clock() < ate do
			if not (alvo and alvo.Parent and alvo.Health > 0) then break end
			aplicarDano(alvo, CFG.DANO_TICK)
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz and raiz then
				vfx("DRENO", { origem = alvoRaiz.Position,
					destino = raiz.Position })
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			colarId = nil
		end
	end)
end

function primaria(mira)
	local alvo = maisPerto(mira, CFG.RAIO_ALVO)
		or maisPerto(frente(CFG.ALCANCE), CFG.RAIO_ALVO)
	if not alvo then
		tocar("ZUMBIDO", 0.7)
		ultimoPrimaria = 0
		return
	end

	ocupado = true
	rig:PlaySequence("AGARRAR", despachar({
		CARGA = { sfx = { "CORRENTE", 1.1 } },
		GOLPE = { faz = function()
			local alvoRaiz = raizDe(alvo)
			if not alvoRaiz then return end
			soltarColar()
			colarId = novoId("COLAR")
			vfx("COLAR", { posicao = alvoRaiz.Position, escala = 1,
				duracao = CFG.DURACAO_COLAR, id = colarId })
			tocarEm("CORRENTE", alvoRaiz.Position, 0.9)
			prender(alvo, CFG.DURACAO_COLAR)
			afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_COLAR + 1)
			manterColar(alvo, colarId)
		end },
		SEGURA = { faz = function()
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				tocarEm("DRENO", alvoRaiz.Position, 0.85)
				aplicarDano(alvo, CFG.DANO_SOLTA)
				tombar(alvo, CFG.TOMBO)
				empurrar(alvo, (alvoRaiz.Position - raiz.Position)
					+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.28)
			end
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- SEM EXTRA
--
-- O `mode == "dark"` da origem tinha UM ataque só. Inventar um segundo aqui
-- seria escrever habilidade que o modelo não tem.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	return
end
''',
    ao_equipar="", ao_guardar="\tsoltarColar()\n",
)


CONJUNTO["Explosao Lunar"] = dict(
    objeto="ExplosaoLunar_Server_V1", sufixo="NoobExplosaoLunar",
    arquetipo="EXPLOSIVO", tecla="R", botao="ButtonR1", alcance_mira=90,
    cutscene=False,
    rotulo_primaria="chama a lua sobre o ponto mirado",
    rotulo_extra="—  (esta Tool tem uma habilidade so)",
    origem=[
        "`Lunar_Blast`: killnearest(ECH, 25, 25) (un.lua:2081-2106)",
        "   `killnearest` empurra e mata em raio 25 -> 62 em raio 20",
        "som 168586621",
        "unico ataque `z` do mode `dominus`",
    ],
    cfg="""	ALCANCE        = 16,
	RECARGA        = 28,
	ALTURA_LUA     = 70,
	QUEDA          = 0.55,
	RAIO_LUA       = 20,
	RAIO_NUCLEO    = 7,
	DANO_LUA       = 62,
	DANO_BORDA     = 28,
	EMPURRAO       = 88,
	TOMBO          = 1.8,

	RECARGA_EXTRA  = 1,""",
    estado="",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a lua
--
-- A origem chamava `killnearest(ECH, 25, 25)`, que empurra e mata em raio 25.
-- Aqui são 62 no núcleo de 7 e 28 na borda de 20.
--
-- A queda é do CLIENTE: o servidor manda a lua com a altura e o tempo no
-- payload, e o dano cai por `task.delay` no mesmo prazo. Servidor arrastando
-- peça por quadro replica a ~20 Hz picotado.
--═══════════════════════════════════════════════════════════════

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LUA", despachar({
		CARGA = { sfx = { "CARGA", 0.85 } },
		GOLPE = { faz = function()
			local onde = destino or frente(CFG.ALCANCE)
			vfx("LUA", { posicao = onde, escala = 1,
				altura = CFG.ALTURA_LUA, queda = CFG.QUEDA })
			tocarEm("LUA", onde + Vector3.new(0, CFG.ALTURA_LUA * 0.5, 0), 1)
			-- o impacto cai quando a lua chega, não quando ela sai
			task.delay(CFG.QUEDA, function()
				vfx("LUA_FIM", { posicao = onde, escala = 1.3 })
				tocarEm("ESTOURO", onde, 0.8)
				golpearArea(onde, CFG.RAIO_LUA, CFG.RAIO_NUCLEO,
					CFG.DANO_LUA, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
			end)
		end },
	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- SEM EXTRA
--
-- O `x` do mode `dominus` é o `SuperDominus`, e ele é a Tool 7 inteira.
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	return
end
''',
    ao_equipar="", ao_guardar="",
)


CONJUNTO["Super Dominus"] = dict(
    objeto="SuperDominus_Server_V1", sufixo="NoobSuperDominus",
    arquetipo="EXPLOSIVO", tecla="R", botao="ButtonR1", alcance_mira=50,
    cutscene=True,
    rotulo_primaria="a coroa desce — ultimate com cutscene",
    rotulo_extra="—  (esta Tool tem uma habilidade so)",
    origem=[
        "`SuperDominus`: ApplyAoE(HITPOS, **200**, 100, 100, 0, **true**)",
        "   raio 200 com INSTAKILL -> 130 no nucleo de 12, 58 na borda de 34",
        "som 824687369",
        "falas `This is...` e `Epic Broooooooo !!!` -> nao entram: Chat e do modelo",
        "malha `dominus` id 138923368 VIROU o Handle desta Tool",
    ],
    cfg="""	ALCANCE        = 12,
	RECARGA        = 46,
	RAIO_CENA      = 44,
	RAIO_COROA     = 34,
	RAIO_NUCLEO    = 12,
	DANO_NUCLEO    = 130,
	DANO_BORDA     = 58,
	EMPURRAO       = 128,
	TOMBO          = 3,
	DURACAO_AURA   = 3,

	RECARGA_EXTRA  = 1,""",
    estado="local auraId = nil",
    corpo='''
--═══════════════════════════════════════════════════════════════
-- PRIMÁRIA — a coroa, COM CUTSCENE
--
-- ULTIMATE: 7.85 s com 71% de preparação, dentro da faixa da regra 5. É a
-- sequência mais longa deste conjunto.
--
-- A origem cobria **raio 200 com INSTAKILL**. Aqui são 130 no núcleo de 12 e
-- 58 na borda de 34 — o maior número do repositório depois da `Era Do Fim`, e
-- é onde ele deve estar: é a ultimate mais cara do conjunto, com 46 s de
-- recarga.
--
-- O Handle desta Tool é a malha `dominus` do próprio modelo (id 138923368).
--═══════════════════════════════════════════════════════════════

local function apagarAura()
	if auraId then
		vfx("APAGAR", { id = auraId })
		auraId = nil
	end
end

function primaria(_mira)
	ocupado = true
	local centro = raiz.Position
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 14), "CAMERA")

	rig:PlaySequence("COROA", despachar({
		CAMERA = { sfx = { "GRAVE", 0.5 } },
		CARGA = { cam = true, sfx = { "COROA", 0.8 }, faz = function()
			apagarAura()
			auraId = novoId("AURA")
			vfx("COROA", { posicao = raiz.Position, escala = 1,
				duracao = CFG.DURACAO_AURA, id = auraId })
		end },
		SEGURA = { cam = true },
		DESCE = { cam = true, sfx = { "COLAPSO", 0.7 } },
		GOLPE = { cam = true, faz = function()
			local onde = raiz and raiz.Position or centro
			apagarAura()
			vfx("COROA_FIM", { posicao = onde, escala = 1.8 })
			tocarEm("COROA", onde, 0.6)
			tocarEm("GRAVE", onde, 0.45)
			golpearArea(onde, CFG.RAIO_COROA, CFG.RAIO_NUCLEO,
				CFG.DANO_NUCLEO, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
		end },
		FIM = { faz = function()
			apagarAura()
			fecharCena()
		end },
	}), function()
		apagarAura()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- SEM EXTRA
--═══════════════════════════════════════════════════════════════

function extra(_mira)
	return
end
''',
    ao_equipar="", ao_guardar="\tapagarAura()\n\tfecharCena()\n",
)


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    d = dict(d)
    d["extra_require"] = ("local CutsceneRemote = Tool:WaitForChild(\"CutsceneRemote\")\n"
                          if d["cutscene"] else "")
    d["origem"] = "".join("--   %s\n" % linha for linha in d["origem"])
    corpo = (CUTSCENE if d["cutscene"] else "") + DESPACHANTE + d["corpo"]
    servidor = PREAMBULO.format(tool=tool, **d) + corpo + RODAPE.format(**d)

    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_NOOB, os.path.join(pasta, "VFXModule.lua"))
    if d["cutscene"]:
        shutil.copyfile(CAM_NOOB, os.path.join(pasta, "CutsceneCam.lua"))

    print("%-20s %5d linhas de Server%s"
          % (tool, servidor.count("\n") + 1,
             " · CutsceneCam" if d["cutscene"] else ""))
    return True


def main():
    for caminho in (ANIMATOR, VFX_NOOB, CAM_NOOB):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
