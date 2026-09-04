-- CajadodaEscuridao_Server_V1.lua
-- Script de servidor — Cajado da Escuridao  (conjunto MARIA)
--
-- Sai do `reality_tools.rbxmx`, que NÃO é uma Tool: é um Script de 2650
-- linhas solto na raiz. Handle, moldes e sons vêm de lá; a habilidade é escrita
-- aqui. Ver `FERRAMENTAS/preparar_reality.py` para o mapa.
--
--   M1   orbe teleguiado   (a habilidade que a origem ja tinha)
--   R    Enxame   (Extra 1)
--   T    Cegueira   (Extra 2)
--   Y    Manto   (Extra 3)
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "ESPECTRAL"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	ALCANCE       = 45,
	VOO           = 0.5,
	RAIO_ORBE     = 8,
	DANO_ORBE     = 26,
	EMPURRAO      = 40,
	RECARGA       = 1,

	RECARGA_R     = 12,
	ORBES         = 3,
	PASSO_ENXAME  = 0.14,
	DANO_ENXAME   = 16,

	RECARGA_T     = 18,
	RAIO_CEGUEIRA = 14,
	DANO_CEGUEIRA = 12,
	TEMPO_CEGO    = 4,
	LENTIDAO_CEGO = 0.5,

	RECARGA_Y     = 30,
	TEMPO_MANTO   = 6,
	RAIO_MANTO    = 9,
	LENTIDAO_MANTO = 0.6,
	TIQUE_MANTO   = 0.8,
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
local ultimoPrimaria, ultimoR, ultimoT, ultimoY = 0, 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as quatro virariam globais.
local primaria, extraR, extraT, extraY
local mantoId = nil
local geracao = 0

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

	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
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

	local inimigos = {}
	for _, hostil in ipairs(alvosEm(posicao, raio, limite or 12)) do
		inimigos[hostil] = true
	end

	local achados, vistos = {}, {}
	if humanoide and humanoide.Health > 0 then
		vistos[humanoide] = true
		table.insert(achados, humanoide)
	end

	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
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


--══════════════════════════════════════════════════════════════
-- O ORBE — teleguiado, como o `Follow` da origem
--
-- Na origem o orbe é uma `Part` com `BodyVelocity` e um script `Follow` que
-- reaponta a velocidade a cada quadro. Aqui quem desenha o voo é o cliente, e
-- o servidor só resolve o impacto no fim — o servidor mover geometria por
-- quadro replica a ~20 Hz picotado, e foi o bug de "não está fluido".
--══════════════════════════════════════════════════════════════

local function lancarOrbe(ponto, raioDano, dano)
	local mao = raiz.Position + raiz.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)
	vfx("ORBE", { origem = mao, destino = ponto, tempo = CFG.VOO, escala = 1 })
	task.delay(CFG.VOO, function()
		vfx("ORBE_FIM", { posicao = ponto, escala = 1 })
		tocarEm("ATAQUE", ponto, 0.9)
		for _, alvo in ipairs(alvosEm(ponto, raioDano, 8)) do
			aplicarDano(alvo, dano)
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - ponto)
					+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.24)
			end
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ORBE", despachar({
		CARGA = { sfx = { "ATAQUE", 1 } },
		GOLPE = { faz = function()
			lancarOrbe(destino or frente(CFG.ALCANCE), CFG.RAIO_ORBE,
				CFG.DANO_ORBE)
		end },
	}), function() ocupado = false end)
end

--══════════════════════════════════════════════════════════════
-- R — o Enxame  ·  T — a Cegueira  ·  Y — o Manto
--══════════════════════════════════════════════════════════════

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ENXAME", despachar({
		CARGA = { sfx = { "ENXAME", 1.15 } },
		GOLPE = { faz = function()
			local base = destino or frente(CFG.ALCANCE)
			task.spawn(function()
				for i = 1, CFG.ORBES do
					if not (raiz and raiz.Parent) then break end
					-- ângulo áureo espalha sem sorteio: três orbes nunca
					-- saem alinhados, e todos os clientes veem o mesmo
					local a = i * 2.399963
					lancarOrbe(base + Vector3.new(math.cos(a), 0, math.sin(a)) * 4,
						CFG.RAIO_ORBE * 0.8, CFG.DANO_ENXAME)
					task.wait(CFG.PASSO_ENXAME)
				end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CEGUEIRA", despachar({
		CARGA = { sfx = { "CEGUEIRA", 0.75 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("CEGUEIRA", { posicao = centro, escala = 1,
				duracao = CFG.TEMPO_CEGO })
			tocarEm("CEGUEIRA", centro, 0.7)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CEGUEIRA, 12)) do
				aplicarDano(alvo, CFG.DANO_CEGUEIRA)
				afrouxar(alvo, CFG.LENTIDAO_CEGO, CFG.TEMPO_CEGO)
			end
		end },
	}), function() ocupado = false end)
end

local function tirarManto()
	geracao = geracao + 1
	if mantoId then
		vfx("APAGAR", { id = mantoId })
		mantoId = nil
	end
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("MANTO", despachar({
		CARGA = { sfx = { "MANTO", 0.9 } },
		GOLPE = { faz = function()
			tirarManto()
			geracao = geracao + 1
			local minha = geracao
			mantoId = novoId("MANTO")
			local id = mantoId
			vfx("MANTO", { posicao = raiz.Position, escala = 1,
				duracao = CFG.TEMPO_MANTO, id = id })
			tocarEm("MANTO", raiz.Position, 0.9)

			task.spawn(function()
				local ate = os.clock() + CFG.TEMPO_MANTO
				while minha == geracao and os.clock() < ate do
					if not (raiz and raiz.Parent) then break end
					vfx("MOVER", { id = id, posicao = raiz.Position,
						tempo = CFG.TIQUE_MANTO })
					for _, alvo in ipairs(alvosEm(raiz.Position,
							CFG.RAIO_MANTO, 10)) do
						afrouxar(alvo, CFG.LENTIDAO_MANTO,
							CFG.TIQUE_MANTO * 1.4)
					end
					task.wait(CFG.TIQUE_MANTO)
				end
				if minha == geracao then tirarManto() end
			end)
		end },
	}), function() ocupado = false end)
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

--- As TRÊS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R", "T" e "Y" é descartada sem
--- resposta.
--- Confiar no cliente para dizer qual habilidade rodar seria dar a ele a
--- escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end

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

	rig = Animator.new(personagem, "MariaEscuridao", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	tirarManto()
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
