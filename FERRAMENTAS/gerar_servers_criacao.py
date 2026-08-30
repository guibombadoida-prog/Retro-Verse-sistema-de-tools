#!/usr/bin/env python3
"""
gerar_servers_criacao.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule`, o `R6CFrameAnimator` e — no
`Demiurgo` — a `CutsceneCam` das 7 Tools do conjunto CRIAÇÃO.

    python3 FERRAMENTAS/preparar_criacao.py      # antes
    python3 FERRAMENTAS/gerar_poses_criacao.py   # antes
    python3 FERRAMENTAS/gerar_servers_criacao.py

TRÊS HABILIDADES POR TOOL — M1 + `R` + `T`

    21 habilidades. O `AcaoRemote` é UM só: quem diferencia é o nome da tecla
    no payload, conferido no servidor antes de agir.

O QUE ESTE CONJUNTO TEM QUE NENHUM OUTRO TINHA

    Ele cria PEÇA DE SERVIDOR — coisa com que se colide. A muralha bloqueia, a
    torre levanta, o cipó prende. Todo conjunto anterior punha no mundo só VFX,
    que é do cliente e some sozinho.

    Peça de servidor que fica é lixo permanente no mapa, e é a mesma família do
    defeito que o `timetools` tinha com `Anchored`. Por isso o bloco central
    deste gerador é o REGISTRO: toda peça criada entra nele com prazo, e sai
    por três portas — o prazo, o `Unequipped` e o `Destroying`.

    E tem TETO. Sem ele um jogador ergue trinta muralhas e o servidor carrega
    trinta peças colidíveis dele para sempre.
"""


import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_CRIACAO = os.path.join(DADOS, "VFXModule_Criacao.lua")
CUTSCENE = os.path.join(DADOS, "CutsceneCam_Criacao.lua")


BLOCO_CENA = '''
--═══════════════════════════════════════════════════════════════
-- A CENA — quem assiste, e o que cada um vê
--
-- NÃO é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
-- câmera por causa de um relógio alheio. Assistem: quem virou a ampulheta, e
-- quem estiver DENTRO do raio.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(ponto, raioCena, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, ponto = ponto,
	})

	for _, alvo in ipairs(alvosEm(ponto, raioCena, 8)) do
		local corpo = alvo.Parent
		local outro = corpo and Players:GetPlayerFromCharacter(corpo)
		if outro and outro ~= jogador then
			CutsceneRemote:FireClient(outro, "INICIO", {
				papel = "ALVO", nome = nomeBeat,
				portador = personagem.Name, ponto = ponto,
			})
		end
	end
end

local function beatCena(nome, ponto)
	if not emCena then return end
	CutsceneRemote:FireAllClients("BEAT", { nome = nome, ponto = ponto })
end

--- Fechar a cena é caminho que não pode falhar: no fim da sequência, no
--- `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end
'''

SEM_CENA = '''
--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil
'''


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto CRIAÇÃO)
--
--   M1   {rotulo_m1}
--   R    {rotulo_r}   (Extra 1)
--   T    {rotulo_t}   (Extra 2)
--
{origem}--
-- CONJUNTO AUTORAL
--
--   O CRIAÇÃO não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega. A
--   geometria do Handle é primitiva soldada, e a lógica é escrita aqui.
--
-- A REGRA DESTE ARQUIVO: TUDO QUE É CRIADO É RECOLHIDO
--
--   Esta é a primeira Tool do repositório que põe no mundo `Part` DE
--   SERVIDOR — coisa colidível, com que todo mundo esbarra. Todo conjunto
--   anterior punha só VFX, que é do cliente e some sozinho.
--
--   Peça de servidor que fica é lixo permanente no mapa. Por isso NADA é
--   criado fora de `criar()`, que registra a peça com prazo, e o registro tem
--   TRÊS saídas: o prazo, o `Unequipped` e o `Destroying`. E tem TETO, porque
--   sem ele um jogador ergue trinta muralhas e todas ficam.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_criacao.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

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
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {{}}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT
{estado}

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function anguloDe(i)
	return (i or proximo()) * 2.399963
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

--═══════════════════════════════════════════════════════════════
-- SOM — mora em `Tool/SFX/`, três por Tool
--═══════════════════════════════════════════════════════════════

--- Sorteia DENTRO de um grupo de variação, com peso.
---
--- Um `Sound` com um `NumberValue` chamado `Weight` sai mais (ou menos) que os
--- irmãos. Serve para o take bom sair 3× mais que o esquisito sem ter de
--- apagar o esquisito.
---
--- ⚠️ A última linha NÃO é paranoia. `math.random() * total` pode, por
---    arredondamento de ponto flutuante, sobrar depois de subtrair todos os
---    pesos e cair fora do laço. A implementação de onde a ideia veio devolve
---    `nil` nesse caso — que é um som MUDO, em silêncio, uma vez a cada muitas.
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

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	-- `Folder` com o nome do papel É o grupo de variação
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

--- GRUPO DE VARIAÇÃO — o mesmo golpe não soa igual cem vezes seguidas.
---
--- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre foi) OU uma `Folder` com
--- vários. Se for `Folder`, sorteia com peso. Tool antiga não muda de
--- comportamento: `Sound` avulso cai no primeiro `return`.
---
--- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: o `Sound` que
--- `tocar()` clona é parenteado no `Handle` pelo servidor, então a INSTÂNCIA
--- replica e todo mundo ouve a mesma. Se cada cliente sorteasse, duas pessoas
--- ouviriam sons diferentes para o mesmo golpe.
---
--- Achado ao ler o `ROBLOX-Audio-Manager` — ver
--- FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md, Parte I §1. Os modelos de
--- entrada já trazem 76 variantes que ninguém usava (`block1`..`block22` só no
--- Danilo, `Swing1`..`Swing5` no Reality).
local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
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

--- Toca numa ÂNCORA PRÓPRIA. Um `Sound` só toca enquanto tem pai no
--- DataModel, e a peça que congela é exatamente a que pode sumir.
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

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- `TakeDamage` respeita `ForceField`; escrever em `Health` fura. A tag
-- `creator` é o que credita o abate, e o `Name` vem ANTES do `Parent`.
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
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

--- Alvos num raio, por consulta espacial sob demanda.
---
--- A ORIGEM VARRIA `workspace:GetDescendants()` em três lugares. Num mapa de
--- verdade isso é o place inteiro por chamada, e ela ancorava tudo o que
--- achasse — inclusive o cenário de quem não estava na briga.
local function alvosEm(posicao, raio, limite)
	local achados, vistos = {{}}, {{}}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum ~= humanoide and not vistos[hum] then
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

local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um arco para a frente acerta quem está atrás de quem o traçou.
local function alvosNoCone(origem, direcao, alcance, cosseno, limite)
	local achados = {{}}
	for _, alvo in ipairs(alvosEm(origem, alcance, (limite or 12) * 2)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - origem
			if delta.Magnitude > 0.01
					and delta.Unit:Dot(direcao.Unit) >= cosseno then
				table.insert(achados, alvo)
				if #achados >= (limite or 12) then break end
			end
		end
	end
	return achados
end

--- Alvos ao longo de uma RETA. É o que o traço precisa: quem está NO CAMINHO,
--- não quem está perto do ponto final.
local function alvosNaReta(origem, direcao, alcance, largura, limite)
	local achados, vistos = {{}}, {{}}
	local passo = math.max(largura * 0.8, 2)
	local andado = 0
	while andado <= alcance do
		local onde = origem + direcao.Unit * andado
		for _, alvo in ipairs(alvosEm(onde, largura, limite or 12)) do
			if not vistos[alvo] then
				vistos[alvo] = true
				table.insert(achados, alvo)
			end
		end
		andado = andado + passo
	end
	return achados
end

--- O chão sob um ponto mirado.
---
--- NUM CONJUNTO QUE CONSTRÓI, ISTO NÃO É DETALHE. Uma muralha que nasce na
--- altura do mouse fica boiando, e o jogador não entende por que ela não
--- bloqueia nada. Toda peça deste conjunto assenta no chão.
local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	local batida = workspace:Raycast(ponto + Vector3.new(0, 8, 0),
		Vector3.new(0, -80, 0), filtro)
	return batida and batida.Position or ponto
end

--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É CRIADO É RECOLHIDO
--
-- Este bloco é o conjunto inteiro. As sete Tools criam `Part` DE SERVIDOR —
-- colidível, com que todo mundo esbarra — e peça de servidor que fica é lixo
-- permanente no mapa.
--
-- É a mesma família do defeito que o `timetools` tinha com `Anchored`:
-- `Instance.new("Part")` seguido de `Debris:AddItem` parece resolver, mas o
-- `Debris` não roda se o script morrer antes de chamá-lo, e a Tool destruída
-- no meio deixa a muralha no mapa até o servidor cair.
--
-- Aqui nada é criado sem entrar no registro, e o registro tem TRÊS saídas: o
-- prazo, o `Unequipped` e o `Destroying`. E tem TETO — sem ele um jogador
-- ergue trinta muralhas e todas ficam.
--═══════════════════════════════════════════════════════════════

local criadas = {{}}

--- Manda o desmanche para o cliente e tira a peça do mundo.
---
--- O `RECOLHER` não é enfeite: sem ele o jogador vê a muralha sumir e não sabe
--- se ela acabou ou se quebrou. Com ele, ela volta a ser andaime e apaga —
--- que é a única leitura possível de "o prazo venceu".
local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
		vfx("RECOLHER", {{
			quadro = reg.peca.CFrame, tamanho = reg.peca.Size,
			cor = reg.peca.Color,
		}})
		reg.peca.CanCollide = false
		reg.peca.Parent = nil
	end
	reg.peca = nil
end

local function recolherTudo()
	for _, reg in ipairs(criadas) do
		recolher(reg)
	end
	table.clear(criadas)
end

--- Cria uma peça de servidor, colidível, e a REGISTRA.
---
--- Esta é a única porta pela qual matéria entra no mundo neste conjunto. Toda
--- habilidade que constrói passa por aqui, e por isso o teto e o prazo valem
--- para todas sem cada uma ter de lembrar.
local function criar(quadro, tamanho, props, vida)
	while #criadas >= CFG.TETO_CRIADAS do
		recolher(table.remove(criadas, 1))
	end

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = tamanho
	p.CFrame = quadro
	p.Material = Enum.Material.SmoothPlastic
	for chave, valor in pairs(props or {{}}) do
		p[chave] = valor
	end
	p.Parent = workspace

	local reg = {{ peca = p, ate = os.clock() + vida }}
	table.insert(criadas, reg)
	task.delay(vida, function()
		local i = table.find(criadas, reg)
		if i then
			table.remove(criadas, i)
			recolher(reg)
		end
	end)
	return p
end

--- Levanta quem estiver em cima do que subiu.
---
--- Sem isto, a torre nasce DENTRO do alvo e o Roblox o empurra para um lado
--- qualquer — ou o prende dentro da peça. Empurrar para cima de propósito é a
--- única forma de a habilidade ser legível.
local function levantar(centro, raio, forca, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 10)) do
		empurrar(alvo, Vector3.new(jitter(1) * 0.25, 1, jitter(2) * 0.25),
			forca, 0.3)
		pegos = pegos + 1
	end
	return pegos
end

{bloco_cena}
--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO.
--
-- `TESTES/verificar_beats.py` confere que todo beat despachado aqui existe na
-- sequência do `Poses.lua`, e que todo beat com `cam` tem enquadramento.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam and beatCena then beatCena(marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

'''

RODAPE = '''
--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e DUAS Extras
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

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if tecla == "R" then
		if not pronto(ultimoR, CFG.RECARGA_R) then return end
		ultimoR = os.clock()
		extraR(mira)
	elseif tecla == "T" then
		if not pronto(ultimoT, CFG.RECARGA_T) then return end
		ultimoT = os.clock()
		extraT(mira)
	end
end)

--- O VIGIA DO REGISTRO
---
--- Cada peça tem prazo próprio, e o `task.delay` do `criar` é quem o cobra no
--- caso normal. Este laço é a rede embaixo: se um `task.delay` for perdido —
--- e ele é, se a thread morrer —, o vigia recolhe assim mesmo.
local function vigiar()
	guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		local i = #criadas
		while i >= 1 do
			local reg = criadas[i]
			if agora > reg.ate then
				table.remove(criadas, i)
				recolher(reg)
			end
			i = i - 1
		end
	end))
end

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "{sufixo}", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	vigiar()
{ao_equipar}end)

--- As DUAS portas, e a terceira coisa que elas fazem: RECOLHER O QUE FOI
--- CRIADO. `Unequipped` sozinho não cobre a Tool ser destruída com uma
--- muralha de pé, e muralha sem dono fica no mapa até o servidor cair.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	recolherTudo()
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
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
'''


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (conjunto CRIAÇÃO)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. `RunContext = Client` roda em TODO cliente, e nada saiu de dentro
-- da Tool.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica.
--
-- E A CÂMERA TAMBÉM NÃO. Quem enquadra é a `CutsceneCam`, que é outro
-- `Script` com `RunContext = Client` — só no `Demiurgo`. Este arquivo não
-- toca em `workspace.CurrentCamera` em lugar nenhum.
--
-- DOIS BOTÕES DE CELULAR, EM ALTURAS DIFERENTES
--
--   Com a mesma altura os dois empilham e o de baixo fica inalcançável.
--
-- Gerado por FERRAMENTAS/gerar_servers_criacao.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO_R = "Criacao_{sufixo}_R"
local ACAO_T = "Criacao_{sufixo}_T"
local ALCANCE_MIRA = {alcance_mira}

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" or tipo == "PARAR" then
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

--- Onde o jogador aponta, limitado ao alcance.
---
--- A ORIGEM FAZIA ISTO POR `RemoteFunction`: `DirectionInvoker:InvokeClient`,
--- e o `Celestial Staff` chamava TRÊS VEZES por fóton, DENTRO de um laço. O
--- servidor invocava o cliente e ficava esperando a resposta — cliente que
--- não responde trava a thread do servidor até o timeout. Aqui a mira viaja
--- junto do pedido, num sentido só.
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
	ContextActionService:BindAction(ACAO_R, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("R", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)
	ContextActionService:SetTitle(ACAO_R, "{rotulo_r}")
	ContextActionService:SetPosition(ACAO_R, UDim2.new(1, -150, 1, -190))

	ContextActionService:BindAction(ACAO_T, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("T", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.T, Enum.KeyCode.ButtonL1)
	ContextActionService:SetTitle(ACAO_T, "{rotulo_t}")
	-- 70 px acima do R: com a mesma altura os dois empilham
	ContextActionService:SetPosition(ACAO_T, UDim2.new(1, -150, 1, -260))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO_R)
	ContextActionService:UnbindAction(ACAO_T)
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


sys.path.insert(0, DADOS)
from servers_criacao import CONJUNTO, COM_CUTSCENE  # noqa: E402


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s — rode preparar_criacao.py antes" % tool)
        return False

    d = dict(d)
    d["origem"] = "".join("--   %s\n" % linha for linha in d["origem"])
    tem_cena = tool in COM_CUTSCENE
    d["bloco_cena"] = BLOCO_CENA if tem_cena else SEM_CENA
    d["extra_require"] = ('local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")\n'
                          if tem_cena else "")

    servidor = PREAMBULO.format(tool=tool, **d) + d["corpo"] + RODAPE.format(**d)

    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_CRIACAO, os.path.join(pasta, "VFXModule.lua"))
    if tem_cena:
        shutil.copyfile(CUTSCENE, os.path.join(pasta, "CutsceneCam.lua"))

    print("%-20s %5d linhas de Server · M1 + R + T%s"
          % (tool, servidor.count("\n") + 1, "  · CENA" if tem_cena else ""))
    return True


def main():
    for caminho in (ANIMATOR, VFX_CRIACAO, CUTSCENE):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    print("")
    print("7 Tool(s), 21 habilidade(s) — tudo que é mexido é devolvido, por "
          "prazo, Unequipped e Destroying.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
