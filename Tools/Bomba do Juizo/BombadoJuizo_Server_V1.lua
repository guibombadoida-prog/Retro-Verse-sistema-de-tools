-- BombadoJuizo_Server_V1.lua
-- Script de servidor — Bomba do Juizo  (conjunto PODERES DE BOMBA)
--
--   M1   Contagem
--   R    Juizo Final   (Extra)
--
--   Handle: esfera de ferro com mostrador, cinta Neon e pavio
--   CONTAGEM 9125673453 (Beep) · JUIZO 95335614812989 (Supernova)
--   ONDA 4870579875 (earthquake1) — os tres do catalogo do Acervo
--
-- AS DUAS SÃO UM PAR, NÃO DUAS HABILIDADES SOLTAS
--
--   O M1 começa a CONTAGEM, que já bate e ARMA o R por um tempo. Fora da janela, o Juízo sai pela metade — a grande do conjunto se paga.
--
-- CONJUNTO AUTORAL
--
--   O conjunto não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega. A
--   geometria é primitiva soldada, e a lógica é escrita aqui.
--
--   E ele NÃO repete o `Bomba_V4`. As seis de lá são split, nuke, meteoro,
--   quique, kamikaze e gelo; o eixo daqui é PLANTAR E DETONAR.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_bombas7.py. Editar aqui à mão faz as
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
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	ALCANCE       = 14,
	RECARGA       = 1.5,
	TEMPO_CONTA   = 3,
	RAIO_CONTA    = 12,
	DANO_CONTA    = 26,
	JANELA_ARMADO = 8,

	RECARGA_R     = 40,
	RAIO          = 60,
	NUCLEO        = 22,
	DANO          = 190,
	BORDA         = 65,
	EMPURRAO      = 165,
	TOMBO         = 2.4,
	ATRASO_ONDA   = 0.45,
	DANO_ONDA     = 60,
	FATOR_FRIO    = 0.5,
	RAIO_CENA     = 66,
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

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as duas virariam globais.
local primaria, extraR
local contaId, armadoAte = nil, 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. Com TODOS os clientes desenhando, um
--- sorteio faria cada um ver uma cena diferente, o que lê como lag.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice: espalha sem sorteio nenhum.
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
--
-- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
-- some no quadro seguinte mata o som no quadro em que ele nasce — por isso
-- `tocarEm` cria uma âncora própria. Numa Tool de bomba isso não é detalhe: a
-- peça que estoura é EXATAMENTE a que some.
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
-- `creator` é o que credita o abate.
--
-- ORDEM DA TAG: `Name` ANTES de `Parent`. Ao contrário, o `Humanoid` recebe um
-- `ObjectValue` chamado "Value" e o abate não conta para ninguém.
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

--- Tombo com prazo. Nunca `BreakJoints`, que desmonta personagem sem volta.
local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- Lentidão com volta GARANTIDA. Guarda a velocidade de ANTES e devolve essa
--- — nunca um número fixo, porque o alvo pode ter velocidade própria.
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
-- A EXPLOSÃO — NÚCLEO E BORDA, sempre
--
-- É a única forma de dano deste conjunto inteiro, e ela nunca é chapada. Raio
-- de 40 com dano igual em todo lugar mata quem está na borda sem nenhum aviso
-- visual de que estava dentro; e o VFX desenha um anel que ABRE, o que promete
-- ao jogador exatamente o contrário.
--
-- E NUNCA `Instance.new("Explosion")`: ela empurra e desmonta junta por conta
-- própria, sem passar por `TakeDamage` nem respeitar `ForceField`, e o
-- servidor perde o controle do que ela fez.
--═══════════════════════════════════════════════════════════════

local function estourar(centro, raio, raioNucleo, danoNucleo, danoBorda,
		forca, tombo, limite)
	local pegos = 0
	for _, alvo in ipairs(alvosEm(centro, raio, limite or 20)) do
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
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 0.7, 0),
				forca, 0.34)
		end
		pegos = pegos + 1
	end
	return pegos
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um jato de espuma acerta quem está atrás de quem esguichou.
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

--- O chão sob um ponto mirado. Bomba que fica boiando na altura do mouse é o
--- que faz o jogador errar sem entender por quê.
local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(ponto + Vector3.new(0, 6, 0),
		Vector3.new(0, -60, 0), filtro)
	return batida and batida.Position or ponto
end

--═══════════════════════════════════════════════════════════════
-- A CENA — quem assiste, e o que cada um vê
--
-- NÃO é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
-- câmera por causa de uma bomba alheia — cutscene que toma a câmera de quem
-- não está envolvido é a definição de tempo morto.
--
-- Assistem: quem detonou, e quem estiver DENTRO do raio. É a regra 2 da
-- GRAMATICA_CUTSCENE — enquadramento por espectador — e aqui ela tem um
-- sentido que numa cena de espada não teria: numa bomba, "estar no raio" é
-- exatamente a informação que o jogador precisa ter.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(ponto, raioCena, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, ponto = ponto,
	})

	-- a outra metade da regra 2: cada um que está no raio recebe a cena DELE
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

--- Fechar a cena é caminho que não pode falhar: ele roda no fim da sequência,
--- no `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end

--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--
--     ESTOURA = { cam = true, sfx = { "NUCLEAR", 0.8 }, faz = detonar }
--
--   `cam`  manda o beat para a cutscene, com o nome do próprio keyframe
--   `sfx`  toca um som: { nome, pitch }
--   `faz`  o trabalho que não cabe em dado
--
-- `TESTES/verificar_beats.py` confere, Tool a Tool, que todo beat despachado
-- aqui existe na sequência do `Poses.lua`.
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


--══════════════════════════════════════════════════════════════
-- A CONTAGEM
--══════════════════════════════════════════════════════════════

function pararConta()
	if contaId then
		vfx("PARAR", { id = contaId })
		contaId = nil
	end
end

local function armado()
	return os.clock() <= armadoAte
end

--══════════════════════════════════════════════════════════════
-- M1 — começar a contagem
--
-- Ela já bate sozinha, e ARMA o R por `JANELA_ARMADO` segundos. É o que impede
-- a Tool de ser um botão de 40 s de recarga com nada para fazer no meio.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end
	local onde = noChao(mira)

	ocupado = true
	rig:PlaySequence("CONTAGEM", despachar({

		CARGA = { sfx = { "CONTAGEM", 1.15 } },

		ESTOURA = {
			sfx = { "CONTAGEM", 1.0 },
			faz = function()
				pararConta()
				contaId = novoId("conta")
				armadoAte = os.clock() + CFG.JANELA_ARMADO

				vfx("CONTAGEM", {
					id = contaId, posicao = onde,
					raio = CFG.RAIO_CONTA, duracao = CFG.TEMPO_CONTA,
				})
				tocarEm("CONTAGEM", onde, 1.05)

				task.delay(CFG.TEMPO_CONTA, function()
					pararConta()
					if not (personagem and personagem.Parent) then return end
					vfx("ESTOURO_ELO", { posicao = onde, raio = CFG.RAIO_CONTA })
					estourar(onde, CFG.RAIO_CONTA, CFG.RAIO_CONTA * 0.4,
						CFG.DANO_CONTA, CFG.DANO_CONTA * 0.5, 60, 0.7, 10)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o Juízo Final, COM CENA
--
-- A maior do conjunto. Fora da janela de `JANELA_ARMADO` ela sai por
-- `FATOR_FRIO` do dano — não é bloqueada, porque bloquear a ultimate de uma
-- Tool de 40 s de recarga é fazer o jogador esperar 40 s por nada.
--
-- E ela tem DUAS batidas: o estouro, e a onda que vem `ATRASO_ONDA` depois.
-- A segunda pega quem se levantou.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not rig or not raiz then return end
	local ponto = noChao(raiz.Position)
	local frio = not armado()
	local fator = frio and CFG.FATOR_FRIO or 1

	ocupado = true
	rig:PlaySequence("JUIZO", despachar({

		CENA = {
			sfx = { "JUIZO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "CONTAGEM", 1.4 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "JUIZO", 0.75 },
			faz = function()
				armadoAte = 0
				pararConta()

				vfx("JUIZO", { posicao = ponto, raio = CFG.RAIO })
				tocarEm("JUIZO", ponto, 0.7)

				estourar(ponto, CFG.RAIO, CFG.NUCLEO,
					CFG.DANO * fator, CFG.BORDA * fator,
					CFG.EMPURRAO, CFG.TOMBO, 28)

				-- a segunda batida, para quem se levantou
				task.delay(CFG.ATRASO_ONDA, function()
					if not (personagem and personagem.Parent) then return end
					vfx("ONDA_JUIZO", { posicao = ponto, raio = CFG.RAIO })
					tocarEm("ONDA", ponto, 0.7)
					estourar(ponto, CFG.RAIO, CFG.NUCLEO,
						CFG.DANO_ONDA * fator, CFG.DANO_ONDA * 0.5 * fator,
						CFG.EMPURRAO * 0.6, CFG.TOMBO * 0.6, 28)
				end)
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.6, fecharCena)
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e UMA Extra
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

--- A Extra chega pelo `AcaoRemote`, com a tecla no payload. Qualquer coisa
--- fora de "R" é descartada sem resposta: confiar no cliente para dizer qual
--- habilidade rodar seria dar a ele a escolha da recarga também.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end
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

	rig = Animator.new(personagem, "BombaJuizo", Poses,
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
	pararConta()
	fecharCena()
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
-- fica lá até o servidor cair.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
