-- Brasa_Server_V1.lua
-- Script de servidor — Brasa  (conjunto PODER DE FOGO)
--
--   M1   soco em brasa que acumula queimadura
--   R    solta a brasa acumulada   (a Extra)
--
-- CONJUNTO AUTORAL — o quinto. Não sai de modelo nenhum: a geometria é
-- primitiva soldada, e os SoundId saem do catálogo do Acervo (id de som não se
-- inventa: id chutado é som mudo que nenhum verificador estático pega).
--
--═══════════════════════════════════════════════════════════════
-- O QUE ESTE CONJUNTO TEM QUE NENHUM OUTRO TINHA
--═══════════════════════════════════════════════════════════════
--
--   1. POLARIDADE, e ela ATRAVESSA as sete Tools. Quem é atingido fica
--      carregado NORTE ou SUL por um prazo, e a carga mede o que as outras
--      seis fazem com ele: mesma polaridade repele mais forte, oposta atrai
--      mais forte. É o primeiro conjunto do repositório em que uma Tool
--      depende do que outra fez.
--
--   2. GRUPO DE VARIAÇÃO DE SFX. `Tool/SFX/<PAPEL>` é uma `Folder` quando há
--      mais de uma gravação, e `tocar()` sorteia com peso. A `Bobina de Tesla`
--      tem SEIS gravações de raio no `ARCO`.
--
--   3. `quando` no keyframe: o beat cai no MEIO do passo, não na borda.
--
--   Os três saem de FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_fogo.py. Editar aqui à mão faz as
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "Brasa"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	--- Força por unidade de massa, e ela é FINITA. `BodyPosition` com
	--- `maxForce` infinito arrasta um prédio como arrasta um cubo, e por isso
	--- nada feito com ele tem peso.
	FORCA_POR_MASSA = 260,
	TORQUE_POR_MASSA = 90,
	G_PADRAO = 196.2,
	PASSOS_MAX = 600,

	--- QUEIMADURA — a contagem que atravessa as sete.
	---
	--- O TETO é o que impede o M1 de virar dano infinito por repetição. O
	--- bônus recompensa quem acumulou antes de dar o golpe grande: sem ele a
	--- queimadura seria enfeite, e ninguém trocaria de Tool para montá-la.
	QUEIMA_TETO = 5,
	QUEIMA_DURA = 6.0,
	QUEIMA_DANO = 3,
	QUEIMA_BONUS = 0.18,

	--- Teto de peças de servidor SIMULTÂNEAS desta Tool. Sem ele um jogador
	--- assenta trinta trilhos e todos ficam.
	TETO_PECAS = 10,

	RECARGA = 0.7,
	RECARGA_R = 9,

	DANO = 13,
	ALCANCE = 11,
	--- cos(46°) — o cone do soco é curto e fechado: é corpo a corpo.
	COSSENO = 0.69,
	LIMITE = 3,
	EMPURRAO = 46,

	ESTOURO_RAIO = 13,
	ESTOURO_DANO = 30,
	ESTOURO_FORCA = 84,
	--- quantas camadas o estouro CONSOME do alvo. Ele troca acúmulo por dano
	--- imediato, e é o que dá ao M1 um motivo para existir antes do R.
	ESTOURO_CONSOME = 2,
	TETO_PECAS = 4,

}

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
local ultimoPrimaria, ultimoR = 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0
local passeAtual = 0
local ultimoTique = setmetatable({}, { __mode = "k" })

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR


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
-- SOM — GRUPO DE VARIAÇÃO
--
-- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre) OU uma `Folder` com
-- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight").
--
-- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: `tocar()` clona e
-- parenteia no `Handle` PELO SERVIDOR, então a INSTÂNCIA replica e todo mundo
-- ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons diferentes para
-- o mesmo golpe.
--═══════════════════════════════════════════════════════════════

local function sortearNoGrupo(pasta)
	local candidatos, total = {}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, { som = filho, peso = peso })
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
	--- ⚠️ Não é paranoia: `math.random() * total` pode sobrar por
	---    arredondamento e cair fora do laço. A implementação de onde a ideia
	---    veio devolve `nil` aí — um som mudo, calado, de vez em quando.
	return candidatos[#candidatos].som
end

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- Toca numa ÂNCORA PRÓPRIA. Um `Sound` só toca enquanto tem pai no
--- DataModel, e a peça que o carrega pode sair do mundo antes do fim.
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
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- A GUARDA — O QUE É MEU NÃO É ALVO
--
-- Toda função abaixo consulta ESTA, e nenhuma repete a checagem. Filtro
-- copiado é um lugar a mais para esquecer, e num conjunto que ATRAI esquecer
-- significa o jogador se puxar para dentro do próprio campo.
--═══════════════════════════════════════════════════════════════

local function ehMinha(inst)
	if not inst then return true end
	if personagem and inst:IsDescendantOf(personagem) then return true end
	if inst:IsDescendantOf(Tool) then return true end
	if inst:FindFirstAncestorOfClass("Tool") then return true end
	return false
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
	if alvoHum == humanoide then return 0 end
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function alvosEm(posicao, raio, limite)
	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
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

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um campo para a frente pega quem está atrás de quem o abriu.
local function alvosNoCone(origem, direcao, alcance, cosseno, limite)
	local achados = {}
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

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or 20)
end

local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(ponto + Vector3.new(0, 8, 0),
		Vector3.new(0, -400, 0), filtro)
	return batida and batida.Position or ponto
end


--═══════════════════════════════════════════════════════════════
-- ⚙️  O BLOCO DE FÍSICA — a família NOVA, e por que ela é outra coisa
--
-- Tudo daqui para baixo é constraint. Nenhuma linha usa `BodyVelocity`,
-- `BodyPosition`, `BodyGyro`, `BodyForce` nem `BodyAngularVelocity`.
--
-- A DIFERENÇA QUE IMPORTA, e não é o nome:
--
--   `BodyPosition` teleporta. Ele tem `maxForce` infinito, ignora colisão no
--   caminho, e a peça chega ao destino atravessando o que estiver no meio. É
--   o que a `Physics Gun` e o `Gravity Inducer` da origem faziam — e por isso
--   nada neles tinha PESO: um cubo de 4 studs e um prédio se moviam igual.
--
--   `AlignPosition` PUXA. A força tem teto, a peça acelera, colide, balança,
--   e chega tarde se for pesada. `ForceLimitMode = Magnitude` com
--   `MaxForce ∝ massa` é o que faz o jogador sentir a diferença entre um
--   caixote e uma pedra sem que ninguém escreva um número na tela.
--
-- TODA constraint aqui precisa de `Attachment`, e a antiga não precisava. Por
-- isso `pontoDe()` existe, e por isso ele REUSA o attachment pelo nome: criar
-- um novo por chamada deixa lixo pendurado na peça de outro jogador.
--═══════════════════════════════════════════════════════════════

--═══════════════════════════════════════════════════════════════
-- 🔒 O PREFIXO ISOLA POR INSTÂNCIA, NÃO SÓ POR ARQUÉTIPO
--
-- ⚠️ ELE ERA `"RV_" .. ARQUETIPO`, E O COMENTÁRIO ABAIXO MENTIA.
--
--    Eu tinha escrito que "duas Tools deste conjunto na mesma peça não
--    desfazem uma à outra" — verdade, porque os arquétipos diferem. Mas o caso
--    que importa é OUTRO: **dois jogadores com a MESMA Tool**.
--
--    Aí os dois prefixos são idênticos. O `soltarPeca()` de um varre a peça
--    por `nome:sub(1, #PREFIXO) == PREFIXO` e ARRANCA o `AlignPosition` do
--    outro — a caixa que o segundo jogador estava segurando cai no meio do
--    ar, sem nada no log.
--
--    Pior: `pontoDe()` REUSA o attachment pelo nome, então os dois passariam a
--    dividir o mesmo `Attachment` e a mesma constraint, com destinos
--    diferentes brigando no solver.
--
--    Agora o prefixo carrega o `UserId` do dono e um TOKEN da instância da
--    Tool. Dois jogadores nunca colidem; e a mesma pessoa com duas cópias da
--    mesma Tool também não, porque o token é por instância.
--
--    `os.clock()` entra no token porque `UserId` sozinho não separa duas
--    cópias, e `tostring(Tool)` devolve só o Name. Não precisa ser
--    criptográfico: precisa ser único entre as Tools vivas de um servidor.
--
--    Revisão do Codex no PR #1, item P1.5.
--═══════════════════════════════════════════════════════════════

local TOKEN = string.format("%08x", math.floor(os.clock() * 1000) % 0xFFFFFFFF)
local PREFIXO = "RV_" .. ARQUETIPO .. "_" .. TOKEN

--- Chamado no `Equipped`: o `UserId` só existe quando há dono.
---
--- ⚠️ O prefixo muda AQUI, e por isso `soltarPeca` tem de ser chamado ANTES —
---    o `desmontar()` do rodapé faz isso. Mudar o prefixo com constraint viva
---    deixaria a antiga órfã, com nome que ninguém mais procura.
local function fixarPrefixo()
	local id = jogador and jogador.UserId or 0
	PREFIXO = "RV_" .. ARQUETIPO .. "_" .. tostring(id) .. "_" .. TOKEN
end

local function gravidade()
	local g = workspace.Gravity
	if type(g) ~= "number" or g <= 0 then return CFG.G_PADRAO end
	return g
end

--- Um `Attachment` com nome próprio, criado uma vez e reusado.
local function pontoDe(peca, sufixo, deslocamento)
	local nome = PREFIXO .. "_" .. sufixo
	local a = peca:FindFirstChild(nome)
	if a and a:IsA("Attachment") then
		if deslocamento then a.Position = deslocamento end
		return a
	end
	a = Instance.new("Attachment")
	a.Name = nome
	a.Position = deslocamento or Vector3.new()
	a.Parent = peca
	return a
end

--- Tira TUDO que este arquétipo pendurou numa peça.
---
--- É o oposto exato de `pontoDe` + as constraints, e é o que garante que a
--- peça de outro jogador volte a ser dela. O `PREFIXO` carrega o arquétipo, o
--- `UserId` do dono E um token da instância — então nem duas Tools diferentes
--- nem dois JOGADORES com a mesma Tool desfazem o trabalho um do outro.
---
--- ⛔ Note o que ele NÃO faz: ele não toca na peça. Nada aqui apaga, esconde
---    nem redimensiona geometria do mapa — só remove o que esta Tool pendurou.
local function soltarPeca(peca)
	if not (peca and peca.Parent) then return end
	for _, filho in ipairs(peca:GetChildren()) do
		if filho.Name:sub(1, #PREFIXO) == PREFIXO then
			filho.Parent = nil
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- IMPULSO — `LinearVelocity`, o substituto de `BodyVelocity`
--
-- `MaxForce` é PROPORCIONAL À MASSA, e finito. Com teto fixo, um alvo pesado
-- nem se move e um leve sai voando — que é o defeito que 160 `BodyVelocity`
-- deste repositório têm hoje e ninguém percebeu porque todo alvo é R6.
--═══════════════════════════════════════════════════════════════

local function impulso(peca, direcao, velocidade, tempo)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored then return nil end
	if direcao.Magnitude < 0.001 then return nil end

	local a = pontoDe(peca, "Imp")
	local lv = peca:FindFirstChild(PREFIXO .. "_LV")
	if not lv then
		lv = Instance.new("LinearVelocity")
		lv.Name = PREFIXO .. "_LV"
		lv.Attachment0 = a
	end
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.max(peca.AssemblyMass, 0.1) * CFG.FORCA_POR_MASSA
	lv.VectorVelocity = direcao.Unit * velocidade
	lv.Parent = peca
	Debris:AddItem(lv, tempo or 0.2)
	return lv
end

--- GIRO — `AngularVelocity`. É o que a `Lapada Seca` tem e a origem não tinha:
--- o alvo sai RODANDO, não deslizando. Um empurrão sem giro lê como escorregão.
local function giro(peca, eixo, velocidade, tempo)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored then return nil end

	local a = pontoDe(peca, "Gir")
	local av = peca:FindFirstChild(PREFIXO .. "_AV")
	if not av then
		av = Instance.new("AngularVelocity")
		av.Name = PREFIXO .. "_AV"
		av.Attachment0 = a
	end
	av.RelativeTo = Enum.ActuatorRelativeTo.World
	av.MaxTorque = math.max(peca.AssemblyMass, 0.1) * CFG.TORQUE_POR_MASSA
	av.AngularVelocity = (eixo or Vector3.new(0, 1, 0)).Unit * velocidade
	av.Parent = peca
	Debris:AddItem(av, tempo or 0.4)
	return av
end

--- Empurra um HUMANOIDE. É `impulso` na raiz dele, e existe separado porque
--- personagem tem dono de rede próprio e o alvo é sempre a `HumanoidRootPart`.
local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return end
	if direcao.Magnitude < 0.01 then return end
	impulso(alvoRaiz, direcao, forca, tempo or 0.2)
	vfx("EMPURRAO", {
		ponto = alvoRaiz.Position, direcao = direcao.Unit, forca = forca,
	})
end

--═══════════════════════════════════════════════════════════════
-- OS TRÊS PESOS DE QUEDA — e eles têm nome (TRIAGEM_FISICA, decisão #3)
--
--   `empurrar`  só desloca. O alvo continua de pé e no controle.
--   `tombar`    `PlatformStand`. Fica mole, juntas RÍGIDAS. Boneco de pau.
--   `desabar`   `BallSocketConstraint` por junta. O corpo desmonta de verdade.
--
-- `desabar` guarda `Enabled` de cada `Motor6D` e devolve AQUELE valor, nunca
-- `true` fixo. `BreakJoints` continua proibido — ragdoll sem volta é
-- `BreakJoints` com outro nome, e este SEMPRE volta: por prazo, e de novo no
-- `desmontar()`.
--═══════════════════════════════════════════════════════════════

local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum == humanoide then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- O blueprint R6 do `ragdoll-system` (MIT): seis juntas, quatro números cada.
--- Tabela de dados pura, do mesmo feitio que o `Poses.lua`.
local SOCKET = {
	["Neck"] = { atrito = 150, limite = 45, tw0 = -30, tw1 = 30 },
	["RootJoint"] = { atrito = 50, limite = 20, tw0 = 0, tw1 = 30 },
	["Right Shoulder"] = { atrito = 150, limite = 50, tw0 = -70, tw1 = 160 },
	["Left Shoulder"] = { atrito = 150, limite = 50, tw0 = -70, tw1 = 160 },
	["Right Hip"] = { atrito = 150, limite = 40, tw0 = -60, tw1 = 80 },
	["Left Hip"] = { atrito = 150, limite = 40, tw0 = -60, tw1 = 80 },
}

--- Quem está desabado agora, e o que precisa voltar. Chave fraca: se o
--- personagem for coletado, o registro vai junto.
local desabados = setmetatable({}, { __mode = "k" })

local function levantar(alvoHum)
	local reg = desabados[alvoHum]
	if not reg then return end
	desabados[alvoHum] = nil

	for _, s in ipairs(reg.sockets) do
		if s then s.Parent = nil end
	end
	for _, a in ipairs(reg.pontos) do
		if a then a.Parent = nil end
	end
	-- devolve o valor DE ANTES, não `true`
	for motor, ligado in pairs(reg.motores) do
		if motor and motor.Parent then motor.Enabled = ligado end
	end
	for peca, valor in pairs(reg.colide) do
		if peca and peca.Parent then peca.CanCollide = valor end
	end
	if alvoHum and alvoHum.Parent then
		alvoHum.PlatformStand = false
	end
end

local function levantarTodos()
	for alvoHum in pairs(desabados) do
		levantar(alvoHum)
	end
end

local function desabar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum == humanoide then return end
	if desabados[alvoHum] then return end   -- guarda contra empilhar

	local corpo = alvoHum.Parent
	if not corpo then return end

	local reg = { sockets = {}, pontos = {}, motores = {}, colide = {} }

	for _, d in ipairs(corpo:GetDescendants()) do
		if d:IsA("Motor6D") and SOCKET[d.Name] and d.Part0 and d.Part1 then
			local cfg = SOCKET[d.Name]
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")
			a0.Name = PREFIXO .. "_Rag0"
			a1.Name = PREFIXO .. "_Rag1"
			a0.CFrame = d.C0
			a1.CFrame = d.C1
			a0.Parent = d.Part0
			a1.Parent = d.Part1

			local s = Instance.new("BallSocketConstraint")
			s.Name = PREFIXO .. "_Socket"
			s.Attachment0 = a0
			s.Attachment1 = a1
			s.LimitsEnabled = true
			s.TwistLimitsEnabled = true
			s.MaxFrictionTorque = cfg.atrito
			s.UpperAngle = cfg.limite
			s.TwistLowerAngle = cfg.tw0
			s.TwistUpperAngle = cfg.tw1
			s.Parent = d.Parent

			reg.motores[d] = d.Enabled
			d.Enabled = false
			table.insert(reg.sockets, s)
			table.insert(reg.pontos, a0)
			table.insert(reg.pontos, a1)
		elseif d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			reg.colide[d] = d.CanCollide
			d.CanCollide = true
		end
	end

	if #reg.sockets == 0 then
		-- rig sem os `Motor6D` esperados (R15, ou já desmontado): cai para o
		-- tombo, que sempre funciona. Melhor um tombo leve do que nada, e
		-- melhor do que forçar juntas que não existem.
		for peca, valor in pairs(reg.colide) do
			if peca and peca.Parent then peca.CanCollide = valor end
		end
		tombar(alvoHum, tempo)
		return
	end

	alvoHum.PlatformStand = true
	desabados[alvoHum] = reg
	task.delay(tempo or 2.0, function() levantar(alvoHum) end)
end

--═══════════════════════════════════════════════════════════════
-- AMARRAR — `RopeConstraint` (TRIAGEM_FISICA, decisão #4)
--
-- A corda não tem equivalente na família `BodyMover`, e é por isso que as 55
-- Tools que "puxam" hoje aproximam isso com `BodyPosition` em tique — o alvo
-- desliza em linha reta e para. Com corda ele CORRE, estica, e é puxado de
-- volta em arco.
--
-- Devolve a função que desamarra. Quem amarra é obrigado a guardá-la.
--═══════════════════════════════════════════════════════════════

local function amarrar(peca, ancora, comprimento, elasticidade)
	if not (peca and peca.Parent and ancora and ancora.Parent) then
		return function() end
	end
	if peca.Anchored then return function() end end

	local a0 = pontoDe(ancora, "Corda0")
	local a1 = pontoDe(peca, "Corda1")

	local corda = Instance.new("RopeConstraint")
	corda.Name = PREFIXO .. "_Corda"
	corda.Attachment0 = a0
	corda.Attachment1 = a1
	corda.Length = comprimento or 14
	corda.Restitution = elasticidade or 0.28
	corda.Visible = false
	corda.Parent = ancora

	local solto = false
	return function()
		if solto then return end
		solto = true
		if corda then corda.Parent = nil end
		if a1 and a1.Parent then a1.Parent = nil end
	end
end

--═══════════════════════════════════════════════════════════════
-- ATRAIR POR MASSA — `VectorForce`, o poço de gravidade
--
-- A origem usava `BodyPosition` com `maxForce = massa * 3000`, renovado a cada
-- 0.25 s. Isso PUXA PARA UM PONTO com força de mola: a peça chega, para, e
-- fica parada no centro como se estivesse colada.
--
-- Poço de verdade não faz isso. Ele acelera, e a peça PASSA do centro e volta.
-- `VectorForce` dá a aceleração; o resto é o solver. E a queda com a distância
-- é o que faz o efeito ter borda em vez de recortar num raio seco.
--═══════════════════════════════════════════════════════════════

local function atrairPeca(peca, centro, forca, raio)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored or ehMinha(peca) then return nil end

	local delta = centro - peca.Position
	local dist = delta.Magnitude
	if dist < 0.4 or dist > raio then return nil end

	-- queda LINEAR até a borda: 1 no centro, 0 na borda. Inverso do quadrado
	-- daria força enorme perto do centro, e a peça sairia disparada — que é o
	-- oposto do que um poço deve parecer.
	local queda = 1 - (dist / raio)
	local a = pontoDe(peca, "Poco")
	local vf = peca:FindFirstChild(PREFIXO .. "_VF")
	if not vf then
		vf = Instance.new("VectorForce")
		vf.Name = PREFIXO .. "_VF"
		vf.Attachment0 = a
	end
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.ApplyAtCenterOfMass = true
	vf.Force = delta.Unit * (math.max(peca.AssemblyMass, 0.1) * forca * queda)
	vf.Parent = peca
	return vf
end

--- As peças SOLTAS num raio. Não personagens (esses vão por `alvosEm`, e pela
--- raiz, para nunca puxar um membro), não ancoradas, e nunca as minhas.
---
--- ⛔ A ORIGEM VARRIA `workspace:GetDescendants()` RECURSIVAMENTE, a cada
---    0.25 s, durante 3.5 s. Num mapa de verdade isso é o place inteiro
---    quatorze vezes. `GetPartBoundsInRadius` faz a mesma pergunta ao
---    broadphase, que é para isso que ele existe.
local function pecasEm(centro, raio, limite)
	local achadas = {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }
	for _, peca in ipairs(workspace:GetPartBoundsInRadius(centro, raio, filtro)) do
		local modelo = peca:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if not hum and not peca.Anchored and not ehMinha(peca) then
			table.insert(achadas, peca)
			if limite and #achadas >= limite then break end
		end
	end
	return achadas
end

--═══════════════════════════════════════════════════════════════
-- SEGURAR — `AlignPosition` + `AlignOrientation`, a garra
--
-- É a mecânica da `Physics Gun` da origem, e é a única coisa dela que valia a
-- pena: pegar uma peça solta e mantê-la a uma distância do cano, seguindo o
-- mouse. O que muda é que aqui ela tem PESO.
--
--   `ForceLimitMode = Magnitude` + `MaxForce ∝ massa` — a peça pesada chega
--   atrasada, balança, e bate nas coisas no caminho. A `Responsiveness` baixa
--   é o que dá o balanço; a origem punha `P` alto justamente para tirá-lo.
--═══════════════════════════════════════════════════════════════

local function segurar(peca, alvo)
	if not (peca and peca.Parent) then return nil end
	local massa = math.max(peca.AssemblyMass, 0.1)

	local a = pontoDe(peca, "Garra")
	local ap = peca:FindFirstChild(PREFIXO .. "_AP")
	if not ap then
		ap = Instance.new("AlignPosition")
		ap.Name = PREFIXO .. "_AP"
		ap.Attachment0 = a
		ap.Mode = Enum.PositionAlignmentMode.OneAttachment
		ap.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		ap.ApplyAtCenterOfMass = true
		ap.Parent = peca
	end
	ap.MaxForce = massa * CFG.FORCA_POR_MASSA * 4
	ap.Responsiveness = math.clamp(60 / (1 + massa * 0.35), 6, 45)
	ap.Position = alvo

	local ao = peca:FindFirstChild(PREFIXO .. "_AO")
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = PREFIXO .. "_AO"
		ao.Attachment0 = a
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Parent = peca
	end
	ao.MaxTorque = massa * CFG.TORQUE_POR_MASSA * 3
	ao.Responsiveness = 12
	return ap
end

--═══════════════════════════════════════════════════════════════
-- PROJÉTIL — o método do FastCast, em doze linhas
--
-- A bala NÃO é uma `Part` física. É um ponto integrado à mão, e entre dois
-- passos vai um RAYCAST. O que se vê é cosmético, desenhado pelo cliente.
--
--   pos' = pos + v*dt + 0.5*a*dt²        v' = v + a*dt
--
-- ⛔ POR QUE ISTO E NÃO `Velocity = dir * 200`, QUE É O QUE A ORIGEM FAZIA:
--    a 60 Hz, 200 studs/s é um salto de 3,3 studs por quadro. Parede fina de
--    2 studs: a bala está de um lado num quadro e do outro no seguinte, e o
--    `Touched` nunca dispara. O raio cobre o trecho inteiro, então não há
--    como atravessar.
--
-- `aoBater` devolve `true` para PARAR e `false` para QUICAR. É o que dá o
-- ricochete da `ClassicSuperball` da origem sem uma peça física no meio.
--═══════════════════════════════════════════════════════════════

--- Balística fechada (roPhysics): o ângulo que faz o tiro cair no alcance.
--- Devolve `nil` se o alcance for maior do que a velocidade permite.
local function anguloParaAlcance(velocidade, alcance)
	local s = (gravidade() * alcance) / (velocidade * velocidade)
	if s > 1 or s < -1 then return nil end
	return math.asin(s) * 0.5
end

local function dispararProjetil(origem, direcao, velocidade, opcoes)
	opcoes = opcoes or {}
	local pos = origem
	local vel = direcao.Unit * velocidade
	local acel = opcoes.aceleracao or Vector3.new(0, -gravidade(), 0)
	local quiques = opcoes.quiques or 0
	local vida = opcoes.vida or 4
	local raioBala = opcoes.raio or 0.4

	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }

	local passado = 0
	local passos = 0
	local conexao
	conexao = RunService.Heartbeat:Connect(function(dt)
		passos = passos + 1
		passado = passado + dt
		if passado >= vida or passos > CFG.PASSOS_MAX then
			conexao:Disconnect()
			if opcoes.aoFim then opcoes.aoFim(pos) end
			return
		end

		local adiante = pos + vel * dt + acel * (dt * dt * 0.5)
		local delta = adiante - pos
		local batida = nil
		if delta.Magnitude > 0.001 then
			batida = workspace:Raycast(pos, delta, filtro)
		end

		if batida then
			local parar = true
			if opcoes.aoBater then
				parar = opcoes.aoBater(batida, vel, quiques)
			end
			if parar or quiques <= 0 then
				conexao:Disconnect()
				if opcoes.aoFim then opcoes.aoFim(batida.Position) end
				return
			end
			-- REFLEXÃO: v' = v - 2(v·n)n, com perda por quique
			quiques = quiques - 1
			local n = batida.Normal
			vel = (vel - n * (2 * vel:Dot(n))) * (opcoes.perda or 0.86)
			pos = batida.Position + n * raioBala
		else
			pos = adiante
			vel = vel + acel * dt
		end

		if opcoes.aoAndar then opcoes.aoAndar(pos, vel) end
	end)
	guardar(conexao)
	return conexao
end


--═══════════════════════════════════════════════════════════════
-- 🔥 A QUEIMADURA — o eixo que atravessa as sete Tools
--
-- Como a polaridade no MAGNETISMO, uma mecânica só liga as sete: toda Tool
-- APLICA queimadura, e toda Tool LÊ a que as outras deixaram.
--
-- A DIFERENÇA É QUE FOGO EMPILHA
--
--   Polaridade é um estado (norte ou sul). Queimadura é uma CONTAGEM, e cada
--   camada faz três coisas:
--
--     · tira vida por segundo, sozinha
--     · faz o próximo golpe de fogo doer mais
--     · e, no teto, o alvo PEGA FOGO — passa a queimar quem encostar nele
--
--   O TETO existe para o M1 não virar dano infinito por repetição. É a mesma
--   razão do teto de aquecimento da `Forja`, no conjunto CRIAÇÃO, e é a razão
--   pela qual `queimar()` empilha em DURAÇÃO e não em força depois do teto.
--
-- ONDE ELA MORA
--
--   Num `Attribute` do `Humanoid` do alvo, com prazo — marca de ENTIDADE EM
--   CAMPO, a mesma natureza da tag `creator`. Não é depósito nem global.
--
--   As sete Tools leem e escrevem os MESMOS atributos, e isso é o ponto: elas
--   se falam através do alvo, sem uma precisar alcançar a outra.
--═══════════════════════════════════════════════════════════════

local ATRIB_CAMADAS = "RV_FogoCamadas"
local ATRIB_ATE = "RV_FogoExpira"

--- As camadas VÁLIDAS de um alvo. Vencida conta como zero, e o atributo é
--- limpo na hora: marca velha pendurada num jogador é dado errado esperando
--- alguém acreditar nele.
local function camadasDe(alvoHum)
	if not (alvoHum and alvoHum.Parent) then return 0 end
	local n = alvoHum:GetAttribute(ATRIB_CAMADAS)
	if type(n) ~= "number" or n <= 0 then return 0 end
	local ate = alvoHum:GetAttribute(ATRIB_ATE)
	if type(ate) ~= "number" or os.clock() > ate then
		alvoHum:SetAttribute(ATRIB_CAMADAS, nil)
		alvoHum:SetAttribute(ATRIB_ATE, nil)
		return 0
	end
	return math.min(n, CFG.QUEIMA_TETO)
end

--- O multiplicador de dano por queimadura já acumulada.
local function fatorDe(alvoHum)
	return 1 + camadasDe(alvoHum) * CFG.QUEIMA_BONUS
end

--- Quem esta Tool acendeu. Chave fraca: personagem coletado sai junto.
local acesos = setmetatable({{}}, {{ __mode = "k" }})

local function apagarTudo()
	for alvoHum in pairs(acesos) do
		if alvoHum and alvoHum.Parent then
			alvoHum:SetAttribute(ATRIB_CAMADAS, nil)
			alvoHum:SetAttribute(ATRIB_ATE, nil)
		end
	end
	table.clear(acesos)
end

--- Acende, ou empilha. No TETO ele para de somar camada e só RENOVA o prazo —
--- senão bater dez vezes viraria dano multiplicado por dez.
local function queimar(alvoHum, quantas, ponto)
	if not (alvoHum and alvoHum.Parent) or alvoHum == humanoide then return end
	if alvoHum.Health <= 0 then return end

	local antes = camadasDe(alvoHum)
	local agora = math.min(antes + (quantas or 1), CFG.QUEIMA_TETO)
	alvoHum:SetAttribute(ATRIB_CAMADAS, agora)
	alvoHum:SetAttribute(ATRIB_ATE, os.clock() + CFG.QUEIMA_DURA)
	acesos[alvoHum] = true

	local alvoRaiz = raizDe(alvoHum)
	vfx("QUEIMA", {{
		ponto = ponto or (alvoRaiz and alvoRaiz.Position) or Vector3.new(),
		camadas = agora,
	}})

	-- o tique de dano é UM por alvo, e ele se auto-encerra quando as camadas
	-- vencem. Sem a guarda `antes > 0`, cada golpe abriria um laço novo e o
	-- dano por segundo viraria dano por golpe vezes o número de golpes.
	if antes > 0 then return end

	guardar(RunService.Heartbeat:Connect(function()
		-- o laço só existe enquanto houver camada; `camadasDe` limpa sozinho
		local n = camadasDe(alvoHum)
		if n <= 0 then return end
		if os.clock() - (ultimoTique[alvoHum] or 0) < 1 then return end
		ultimoTique[alvoHum] = os.clock()
		aplicarDano(alvoHum, math.floor(CFG.QUEIMA_DANO * n + 0.5))
		local r = raizDe(alvoHum)
		if r then
			vfx("QUEIMA", {{ ponto = r.Position, camadas = n }})
		end
	end))
end

--- Alvos num raio QUE JÁ ESTÃO QUEIMANDO. É o que a `Lanca Chamas` e o
--- `Inferno` consomem — as duas habilidades que COBRAM a queimadura.
local function acesosEm(ponto, raio, limite)
	local achados = {{}}
	for _, alvo in ipairs(alvosEm(ponto, raio, (limite or 10) * 2)) do
		local n = camadasDe(alvo)
		if n > 0 then
			table.insert(achados, {{ hum = alvo, camadas = n }})
			if #achados >= (limite or 10) then break end
		end
	end
	return achados
end

--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É POSTO NO MUNDO É RECOLHIDO
--
-- Quatro das sete Tools põem `Part` DE SERVIDOR no mundo: o trilho, a bobina,
-- a bola de sucata e a malha. Peça de servidor que fica é lixo permanente no
-- mapa, e `Instance.new` + `Debris:AddItem` NÃO basta — o `Debris` não roda se
-- a thread morrer antes de chamá-lo, e a Tool destruída no meio deixa o
-- trilho no chão até o servidor cair.
--
-- Nada é posto fora de `criar()`. O registro tem TETO e TRÊS saídas: o prazo,
-- o `Unequipped` e o `Destroying`. É o mesmo desenho do conjunto CRIAÇÃO, que
-- foi o primeiro a precisar dele.
--═══════════════════════════════════════════════════════════════

local criadas = {}

local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
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

--- Põe uma peça no mundo e a REGISTRA. Única porta.
---
--- `ancorada = false` é para o que tem de ser movido por constraint (a bola de
--- sucata). Peça ancorada cujo `CFrame` o servidor escreve por quadro replica
--- a ~20 Hz e SEM interpolação — é a proibição "servidor não move geometria
--- por frame", e é por isso que a bola é solta e puxada, nunca teleportada.
local function criar(quadro, tamanho, props, vida, ancorada)
	while #criadas >= CFG.TETO_PECAS do
		recolher(table.remove(criadas, 1))
	end

	local p = Instance.new("Part")
	p.Anchored = (ancorada ~= false)
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = tamanho
	p.CFrame = quadro
	p.Material = Enum.Material.Metal
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace

	local reg = { peca = p, ate = os.clock() + vida }
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

--- O VIGIA. Cada peça tem prazo próprio e o `task.delay` do `criar` o cobra no
--- caso normal; este laço é a rede embaixo, para quando a thread morrer.
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

--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil

--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — com `quando`
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` NO INÍCIO do
-- passo, antes de o tween começar (conferido no `R6CFrameAnimator`: o
-- `if onBeat then` vem antes do `TweenService:Create`).
--
-- Então `kf.quando` — a fração do passo — é um ATRASO de `time * quando`.
--
-- ⚙️ Este é o primeiro despachante do repositório a implementar isso, e é o
--    achado nº 4 da triagem. Até aqui a marca só podia cair na BORDA de um
--    passo: um som que devia tocar no meio de um quadro de 0.9 s virava um
--    passo extra só para ter onde ser pendurado.
--
--    E o beat ANDA JUNTO com a duração. Mudou o passo de 0.9 para 0.6 e a
--    marca acompanha, porque ela é fração e não segundo.
--
-- ⚠️ O ATRASO PRECISA DE TOKEN. `task.delay` sobrevive ao cancelamento da
--    sequência: sem o `passe`, trocar de habilidade no meio faria o beat da
--    anterior disparar em cima da nova. `passeAtual` sobe a cada sequência, e
--    o disparo confere.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	passeAtual = passeAtual + 1
	local meuPasse = passeAtual

	local function disparar(kf, passo)
		if meuPasse ~= passeAtual then return end
		if not (personagem and personagem.Parent) then return end
		if kf.cam and beatCena then beatCena(passo.marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end

	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end

		local atraso = 0
		if type(passo) == "table" and passo.quando and passo.time then
			atraso = passo.time * math.clamp(passo.quando, 0, 1)
		end
		if atraso <= 0 then
			disparar(kf, passo)
		else
			task.delay(atraso, function() disparar(kf, passo) end)
		end
	end
end


--══════════════════════════════════════════════════════════════
-- M1 — o soco em brasa
--
-- É o M1 do jogo inteiro, e por isso é o mais barato do conjunto: 0.7 s de
-- recarga, cone curto, uma camada de queimadura por acerto.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		GOLPE = {
			sfx = { "GOLPE", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.55)
				vfx("GOLPE", { ponto = centro })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					-- o dano JÁ conta a queimadura que estava lá: bater em
					-- quem queima dói mais, e é o que liga o M1 ao resto
					aplicarDano(alvo, math.floor(CFG.DANO * fatorDe(alvo) + 0.5))
					empurrar(alvo, (direcao + Vector3.new(0, 0.3, 0)).Unit,
						CFG.EMPURRAO, 0.2)
					queimar(alvo, 1)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o estouro
--
-- Ele CONSOME camadas. É a única habilidade do conjunto que tira queimadura
-- em vez de pôr, e é o que dá ao M1 um motivo para vir antes: acumule com o
-- soco, gaste no estouro.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "GOLPE", 0.8 } },

		ESTOURO = {
			sfx = { "ESTOURO", 0.95 },
			faz = function()
				if not raiz then return end
				local centro = typeof(mira) == "Vector3" and mira
					or frente(CFG.ESTOURO_RAIO * 0.5)
				vfx("IMPACTO", { ponto = centro, raio = CFG.ESTOURO_RAIO })
				tocarEm("ESTOURO", centro, 0.9)

				for _, alvo in ipairs(alvosEm(centro, CFG.ESTOURO_RAIO, 8)) do
					local alvoRaiz = raizDe(alvo)
					local queda = 1
					if alvoRaiz then
						queda = math.clamp(1 - ((alvoRaiz.Position - centro)
							.Magnitude / CFG.ESTOURO_RAIO), 0.25, 1)
					end
					local n = camadasDe(alvo)
					-- o bônus é pelo que ESTAVA lá; depois a camada é gasta
					local f = 1 + n * CFG.QUEIMA_BONUS * 2
					aplicarDano(alvo,
						math.floor(CFG.ESTOURO_DANO * queda * f + 0.5))
					if alvoRaiz then
						empurrar(alvo, ((alvoRaiz.Position - centro).Unit
							+ Vector3.new(0, 0.6, 0)).Unit,
							CFG.ESTOURO_FORCA * queda, 0.26)
					end
					if n > CFG.ESTOURO_CONSOME then
						alvo:SetAttribute("RV_FogoCamadas", n - CFG.ESTOURO_CONSOME)
					else
						alvo:SetAttribute("RV_FogoCamadas", nil)
						alvo:SetAttribute("RV_FogoExpira", nil)
					end
					tombar(alvo, 0.9)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

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

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end

	-- a whitelist de ação: só "R". Qualquer outra coisa é descartada.
	if tecla ~= "R" then return end
	if not pronto(ultimoR, CFG.RECARGA_R) then return end
	ultimoR = os.clock()
	extraR(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "Brasa", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	-- 🔒 o prefixo das constraints passa a carregar o UserId do dono: sem
	--    isso, dois jogadores com a MESMA Tool arrancam as constraints um do
	--    outro na mesma peça. Vem do BLOCO_FISICA, importado do Reality.
	fixarPrefixo()
	vigiar()
end)

--- AS DUAS PORTAS, e a terceira coisa que elas fazem: DESCARREGAR.
---
--- Carga que sobrevive a quem a aplicou é modificador permanente num jogador
--- que não tem como tirá-lo — a mesma família do ragdoll que não volta. Some
--- a isso o `passeAtual`, que invalida qualquer beat atrasado ainda na fila.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	passeAtual = passeAtual + 1
	apagarTudo()
	recolherTudo()
	levantarTodos()
	if rig then
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
-- NINGUÉM a apaga: ela é do MODELO, e outro jogador pode estar com a irmã.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
