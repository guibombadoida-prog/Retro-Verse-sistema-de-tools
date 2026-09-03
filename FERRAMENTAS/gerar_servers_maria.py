#!/usr/bin/env python3
"""
gerar_servers_maria.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule` e o `R6CFrameAnimator` das 7
Tools do conjunto MARIA.

    python3 FERRAMENTAS/preparar_maria.py      # antes
    python3 FERRAMENTAS/gerar_poses_maria.py   # antes
    python3 FERRAMENTAS/gerar_servers_maria.py

QUATRO HABILIDADES POR TOOL

    O `jodro` levou o conjunto a M1 + duas Extras. Estas sete vão a M1 + TRÊS,
    em `R`, `T` e `Y` — a habilidade que a origem já tinha mais as três novas.

    O `AcaoRemote` continua sendo UM. Quem separa as duas é o nome da tecla no
    payload, conferido no servidor antes de qualquer coisa — dois remotes
    seriam duas portas para o mesmo cômodo, e duas superfícies para validar.

    No cliente são três `BindAction`, cada um desenhando o próprio botão de
    celular. As três alturas são separadas por 70 px: empilhados, os de baixo
    ficam inalcançáveis.

O SOM MORA EM `Tool/SFX/`

    Nos outros conjuntos o `Sound` fica pendurado no Handle. Aqui são três por
    Tool, e pasta deixa claro que são irmãos. `somDe(nome)` é o único ponto que
    sabe disso.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
DADOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dados")

ANIMATOR = os.path.join(TOOLS, "Bomba Nuclear", "R6CFrameAnimator.lua")
VFX_MARIA = os.path.join(DADOS, "VFXModule_Maria.lua")


DESPACHANTE = '''
--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- Antes cada sequência tinha uma escada de `elseif marca == "X" then`, com o
-- nome do beat escrito DUAS vezes: no `Poses.lua` e de novo no `if`. Errar a
-- segunda falha em silêncio — a animação roda inteira e o beat não acontece.
-- Foi assim que 14 Tools de dois conjuntos ficaram sem dano.
--
-- Agora cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { cam = true, sfx = { "IMPACTO", 0.9 }, faz = bater }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe —
--          não dá mais para escrever `beatCena("CARGA")` dentro de `GOLPE`
--   `sfx`  toca um som: `{ nome, pitch }`
--   `faz`  o trabalho que não cabe em dado
--
-- Câmera e som viraram DADO. Só o que é trabalho continua sendo código, e ele
-- vem com nome em vez de posição na escada.
--
-- A ideia é do `grims-cutscene-engine`, que guarda Keyframes e Actions como
-- dado e deixa um runner interpretar. Nenhuma linha dele foi copiada — aquele
-- repositório não declara licença. Ver
-- FERRAMENTAS/TRIAGEM_FERRAMENTAS_EXTERNAS.md.
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

PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto MARIA)
--
-- Sai do `reality_tools.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_reality.py` para o mapa.
--
--   M1   {rotulo_m1}   (a habilidade que a origem ja tinha)
--   R    {rotulo_r}   (Extra 1)
--   T    {rotulo_t}   (Extra 2)
--   Y    {rotulo_y}   (Extra 3)
--
-- TRÊS HABILIDADES, E UM `AcaoRemote` SÓ
--
--   Os conjuntos anteriores tinham M1 mais uma Extra. Estas têm DUAS, e a
--   tentação seria dois `RemoteEvent`. Não: quem separa é o NOME DA TECLA no
--   payload, conferido aqui antes de qualquer coisa. Dois remotes seriam duas
--   portas para o mesmo cômodo, e duas superfícies para validar.
--
-- CONJUNTO SEM MODELO DE ORIGEM
--
--   Ninguém mandou um modelo de meme: Handle, som e pose são autorais. O
--   `SoundId` de cada um já toca em outra Tool entregue deste repositório —
--   nenhum id foi inventado, porque id chutado é som mudo que nenhum
--   verificador pega.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_maria.py. Editar aqui à mão faz as sete
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
{cfg}
}}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT, ultimoY = 0, 0, 0, 0
local ocupado = false
local ativos = {{}}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as quatro virariam globais.
local primaria, extraR, extraT, extraY
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
--- No JODRO o som mora em `Tool/SFX/`, não pendurado no Handle: são três por
--- Tool e a pasta deixa claro que são irmãos.
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


--═══════════════════════════════════════════════════════════════
-- ALIADO — o espelho de `alvosEm`, e o primeiro do repositório
--
-- O `Cajado Curador` é a primeira Tool que precisa saber em quem NÃO bater. E
-- o `CLAUDE.md` é explícito: `IsTeamMate` só existe dentro do
-- `NucleoCombate.lua`. Chamar aqui seria abrir uma segunda porta para a regra
-- de time, e é exatamente o que o invariante proíbe.
--
-- Então a pergunta é feita ao Núcleo. E o FALLBACK não inventa regra de time:
-- ele DERIVA. Quem está no raio e NÃO está na lista de inimigos que o próprio
-- `alvosEm` devolveu é aliado — mais o portador, que nunca é inimigo de si.
--
-- Sem Núcleo e sem time configurado, `alvosEm` devolve todo mundo, a subtração
-- devolve só o portador, e a cura vira auto-cura. Que é o comportamento certo
-- para uma Tool sozinha num place vazio.
--═══════════════════════════════════════════════════════════════

local function aliadosEm(posicao, raio, limite)

	local inimigos = {{}}
	for _, hostil in ipairs(alvosEm(posicao, raio, limite or 12)) do
		inimigos[hostil] = true
	end

	local achados, vistos = {{}}, {{}}
	if humanoide and humanoide.Health > 0 then
		vistos[humanoide] = true
		table.insert(achados, humanoide)
	end

	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not vistos[hum] and not inimigos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function maisPertoAliado(ponto, raio)
	local melhor, dist = nil, math.huge
	for _, amigo in ipairs(aliadosEm(ponto, raio or 24, 12)) do
		local corpo = amigo.Parent
		local amigoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		local onde = amigoRaiz and amigoRaiz.Position
			or (corpo and corpo:FindFirstChild("Head")
				and corpo.Head.Position)
		if onde then
			local d = (onde - ponto).Magnitude
			if d < dist then melhor, dist = amigo, d end
		end
	end
	return melhor or humanoide
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

--- As TRÊS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R", "T" e "Y" é descartada sem
--- resposta.
--- Confiar no cliente para dizer qual habilidade rodar seria dar a ele a
--- escolha da recarga também.
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
	elseif tecla == "Y" then
		if not pronto(ultimoY, CFG.RECARGA_Y) then return end
		ultimoY = os.clock()
		extraY(mira)
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "{sufixo}", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
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


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (conjunto MARIA)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. O servidor manda o beat com `FireAllClients` e ele CHEGA em todo
-- mundo — mas o único ouvinte seria o de quem está segurando. `RunContext =
-- Client` roda em TODO cliente, e nada saiu de dentro da Tool.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica e os outros jogadores viam o portador parado.
--
-- DOIS BOTÕES DE CELULAR, EM ALTURAS DIFERENTES
--
--   `ContextActionService:BindAction(nome, fn, criarBotaoDeToque, ...)` — o
--   terceiro argumento faz o Roblox desenhar o botão sozinho. São duas Extras,
--   então são dois `BindAction`, e as posições são separadas de propósito: com
--   a mesma altura os dois botões empilham e o de baixo fica inalcançável.
--
-- Gerado por FERRAMENTAS/gerar_servers_maria.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO_R = "Maria_{sufixo}_R"
local ACAO_T = "Maria_{sufixo}_T"
local ACAO_Y = "Maria_{sufixo}_Y"
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
	-- 70 px acima do R: com a mesma altura eles empilham e o de baixo some
	ContextActionService:SetPosition(ACAO_T, UDim2.new(1, -150, 1, -260))

	ContextActionService:BindAction(ACAO_Y, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("Y", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Y, Enum.KeyCode.ButtonL2)
	ContextActionService:SetTitle(ACAO_Y, "{rotulo_y}")
	ContextActionService:SetPosition(ACAO_Y, UDim2.new(1, -150, 1, -330))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO_R)
	ContextActionService:UnbindAction(ACAO_T)
	ContextActionService:UnbindAction(ACAO_Y)
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

sys.path.insert(0, DADOS)
from servers_maria import CONJUNTO  # noqa: E402


def escrever(tool, d):
    pasta = os.path.join(TOOLS, tool)
    if not os.path.isdir(pasta):
        print("sem pasta Tools/%s" % tool)
        return False

    d = dict(d)
    d["extra_require"] = ""
    d["origem"] = "".join("--   %s\n" % linha for linha in d["origem"])
    corpo = DESPACHANTE + d["corpo"]
    servidor = PREAMBULO.format(tool=tool, **d) + corpo + RODAPE.format(**d)

    with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
              encoding="utf-8") as f:
        f.write(servidor)
    with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
        f.write(CLIENTE.format(tool=tool, **d))

    shutil.copyfile(ANIMATOR, os.path.join(pasta, "R6CFrameAnimator.lua"))
    shutil.copyfile(VFX_MARIA, os.path.join(pasta, "VFXModule.lua"))

    print("%-22s %5d linhas de Server · M1 + R + T + Y"
          % (tool, servidor.count("\n") + 1))
    return True


def main():
    for caminho in (ANIMATOR, VFX_MARIA):
        if not os.path.exists(caminho):
            print("faltando: %s" % caminho)
            return 1
    for tool, d in CONJUNTO.items():
        if not escrever(tool, d):
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
