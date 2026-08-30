-- XesterRoyalGuard_Server_V1.lua
-- Script de servidor — Xester Royal Guard  (Xester, Forma 1)
--
--═══════════════════════════════════════════════════════════════
-- ESTA TOOL: quatro Reis de guarda; o clique seguinte lanca um
--
--   P na Forma 1. O baque dos quatro é a metade de trás da MESMA
--   habilidade — combo na mesma entrada conta como uma —, mas ele
--   precisa de uma entrada própria porque o clique já é o lançamento.
--
-- A DISTRIBUIÇÃO
--
--   Forma 1 tem OITO habilidades e vira SETE Tools: `The Final Deal` entra
--   como Extra em `Xester Eclipse Deck`, que é a outra habilidade de clímax
--   dela. Forma 2 tem SEIS e vira SEIS Tools, uma por habilidade. É a
--   `REGRA_DISTRIBUICAO_DE_TOOLS` aplicada ao pé da letra.
--
-- A TROCA DE FORMA, SEM ALCANÇAR NINGUÉM
--
--   `F` transforma, e a Tool que transforma NÃO procura a Tool da outra forma
--   — procurar seria referência para fora, e a Regra nº 1 vence tudo.
--
--   O que ela faz é escrever um Attribute no Character: `XesterForma = 2`.
--   Quem lê, lê sob guarda e com padrão. É estado opcional compartilhado:
--   estado opcional compartilhado, não caminho de instância, não depósito de
--   asset.
--
--   Arraste ESTA Tool sozinha para um place vazio: o atributo não existe, ela
--   o cria com o padrão dela, e a habilidade sai igual.
--
-- A PASSIVA ATRAVESSA AS SETE, PELO MESMO CAMINHO
--
--   A cada TRÊS habilidades da Forma 1 nasce a Carta Coringa, e a próxima sai
--   com dano × 1.6 e raio × 1.25. O contador é `XesterUsos` no Character, e
--   mora no SERVIDOR porque é ele que aplica o dano — deixar o multiplicador
--   no cliente seria deixá-lo com quem pode mentir.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester_v3.py. Editar aqui à mão faz as
-- treze derivarem; edite o gerador.
--═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
local AcaoRemote = Tool:WaitForChild("AcaoRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "SUPORTE"

--- A forma a que esta Tool pertence. Ela NÃO bloqueia nada: uma Tool da Forma 2
--- na mão de quem está na Forma 1 funciona igual. O número serve para a
--- passiva, que só conta na Forma 1, e para o cajado.
local MINHA_FORMA = 1

local CFG = {
	ALCANCE_MIRA   = 60,

	-- ── a passiva, igual nas sete da Forma 1 ──────────────────
	PASSO_CORINGA  = 3,
	BONUS_DANO     = 1.6,
	BONUS_RAIO     = 1.25,
	VIDA_CORINGA   = 30,

	RECARGA        = 18,
	DURACAO        = 14,
	ORBITA         = 4.4,
	ALCANCE        = 42,
	VOO            = 0.24,
	RAIO_REI       = 8,
	DANO_REI       = 30,
	EMPURRAO       = 104,

	RECARGA_EXTRA  = 2,
	RAIO_BAQUE     = 14,
	NUCLEO_BAQUE   = 6,
	DANO_BAQUE     = 46,
	BORDA_BAQUE    = 23,
	TOMBO          = 1.8,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ocupado = false
local ativos = {}
local semente, idEfeito = 0, 0
local ultimoM1, ultimoExtra = 0, 0

--- A geração corta laço velho: cada habilidade com prazo incrementa a sua, e o
--- laço confere antes de cada passo. Sem isso, usar a habilidade duas vezes
--- deixa dois laços vivos escrevendo no mesmo `id`.
local geracao = {}

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso virariam globais. `limparTudo`
--- e `segundaEtapa` entram na lista porque o corpo de cada Tool as define e o
--- rodapé as chama — sem a declaração, as duas viveriam no ambiente global e
--- duas Tools na mesma sessão brigariam pelo mesmo nome.
local primaria, extra, limparTudo, segundaEtapa
local beatCena, comecarCena, acabarCena
local guardaId = nil

-- Com todos os clientes desenhando, um sorteio faria cada um ver uma cena
-- diferente, o que lê como lag. O ângulo áureo (137.507764°) nunca repete
-- alinhamento, então o que se espalha por ele nunca fica empilhado.
--═══════════════════════════════════════════════════════════════

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function anguloDe(indice)
	return (indice or proximo()) * 2.399963
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function apagarEfeito(id)
	if id then vfx("APAGAR", { id = id }) end
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Avança a geração de uma habilidade e devolve a nova. Quem roda um laço
--- guarda o valor e compara antes de cada passo.
local function novaGeracao(chave)
	geracao[chave] = (geracao[chave] or 0) + 1
	return geracao[chave]
end

--═══════════════════════════════════════════════════════════════
-- SOM — sempre numa âncora própria, nunca na peça que o pediu
--
-- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
-- some no quadro seguinte mata o som no quadro em que ele nasce.
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
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
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- O BEAT VEM COMO KEYFRAME, NÃO COMO STRING
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--- Tabela de keyframe no lugar da escada de `elseif marca == "X"`.
---
---     GOLPE = { cam = true, sfx = { "DESABA", 0.9 }, faz = derrubar }
---
--- `cam` manda o beat para a câmera com o nome do PRÓPRIO keyframe — não dá
--- para escrever `beatCena("CARGA")` dentro de `GOLPE` por engano. `sfx` toca
--- um som. `faz` é o trabalho que não cabe em dado.
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


--- Esta Tool não tem cutscene. As três portas de câmera existem como no-op
--- para o `despachar` não precisar de um caminho diferente: um `if` a menos no
--- caminho quente, e nenhuma chance de chamar função nil.
function beatCena(_nome) end
function comecarCena(_qual) end
function acabarCena() end

--═══════════════════════════════════════════════════════════════
-- A FORMA E A PASSIVA — estado no CHARACTER, não em outra Tool
--
-- `SetAttribute` / `GetAttribute` no personagem é escrita e leitura de ESTADO,
-- não de instância: nenhum caminho, nenhum asset, nenhum script fora da Tool.
-- É estado opcional compartilhado, lido sempre com guarda e com padrão, e
-- padrão — sozinha num place vazio, a Tool cria o atributo e segue.
--═══════════════════════════════════════════════════════════════

local ATR_FORMA   = "XesterForma"
local ATR_USOS    = "XesterUsos"
local ATR_CORINGA = "XesterCoringa"

local function lerAtributo(nome, padrao)
	if not personagem then return padrao end
	local valor = personagem:GetAttribute(nome)
	if valor == nil then return padrao end
	return valor
end

local function escreverAtributo(nome, valor)
	if not personagem then return end
	personagem:SetAttribute(nome, valor)
end

local function formaAtual()
	local valor = lerAtributo(ATR_FORMA, 1)
	if valor ~= 1 and valor ~= 2 then return 1 end
	return valor
end

--═══════════════════════════════════════════════════════════════
-- O CAJADO — a peça que diz em qual forma o Xester está
--
-- O Handle NÃO pode trocar: `RequiresHandle` exige que ele exista o tempo
-- todo, e mexer na geometria dele desmonta o `Grip` do `Humanoid`.
--
-- O cajado mora no CHARACTER, não na Tool. É por isso que ele sobrevive à
-- troca de Tool na mochila — o jogador vira dragão com o `Eclipse Deck` e
-- saca o `Wyrm Sparks` sem perder o cajado — e é por isso que ele não precisa
-- de limpeza: morre com o respawn, junto do personagem.
--
-- `Weld` criado no SERVIDOR replica; criado no cliente, não — os outros
-- jogadores veriam o Xester de mãos vazias.
--═══════════════════════════════════════════════════════════════

local function acharCajado()
	if not personagem then return nil end
	return personagem:FindFirstChild("CajadoDoXester")
end

local function tirarCajado()
	local velho = acharCajado()
	if velho then velho.Parent = nil end
end

local function porCajado()
	if acharCajado() then return end
	local moldes = Tool:FindFirstChild("Moldes")
	local base = moldes and moldes:FindFirstChild("Cajado")
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not (base and base:IsA("BasePart") and braco) then return end

	local copia = base:Clone()
	copia.Name = "CajadoDoXester"
	copia.Anchored = false
	copia.CanCollide = false
	copia.CanQuery = false
	copia.CanTouch = false
	copia.Massless = true
	copia.Transparency = 0
	for _, filho in ipairs(copia:GetDescendants()) do
		if filho:IsA("BasePart") then
			filho.Transparency = 0
			filho.CanCollide = false
			filho.Massless = true
		elseif filho:IsA("Decal") or filho:IsA("Texture") then
			filho.Transparency = 0
		elseif filho:IsA("PointLight") or filho:IsA("SpotLight") then
			filho.Enabled = true
		end
	end
	copia.CFrame = braco.CFrame
	copia.Parent = personagem

	local solda = Instance.new("Weld")
	solda.Part0 = braco
	solda.Part1 = copia
	solda.C0 = CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(90), 0, 0)
	solda.Parent = copia
end

--- A aura de brasas da Forma 2. Tem `id` e é apagada por quem a acendeu.
local auraId = nil

local function apagarAura()
	apagarEfeito(auraId)
	auraId = nil
end

local function ligarAura()
	if not raiz then return end
	apagarAura()
	auraId = novoId("AURA")
	vfx("AURA_DRAGAO", { posicao = raiz.Position, id = auraId })
end

--═══════════════════════════════════════════════════════════════
-- A PASSIVA — a Carta Coringa
--
-- O contador atravessa as SETE Tools da Forma 1 pelo atributo. Numa Tool
-- sozinha ele conta só os usos dela, e a carta nasce do mesmo jeito — o
-- comportamento degrada, não quebra.
--═══════════════════════════════════════════════════════════════

local coringaId = nil
local bonusAtivo = false

local function apagarCoringa()
	apagarEfeito(coringaId)
	coringaId = nil
	escreverAtributo(ATR_CORINGA, false)
end

--- Chamada NO COMEÇO de toda habilidade.
local function abrirHabilidade()
	bonusAtivo = false
	if lerAtributo(ATR_CORINGA, false) == true then
		bonusAtivo = true
		if raiz then
			vfx("CORINGA_GASTA", { posicao = raiz.Position })
			tocarEm("CORINGA", raiz.Position, 1.35)
		end
		apagarCoringa()
	end
	if formaAtual() ~= 1 then return end
	local usos = lerAtributo(ATR_USOS, 0) + 1
	if usos < CFG.PASSO_CORINGA then
		escreverAtributo(ATR_USOS, usos)
		return
	end
	escreverAtributo(ATR_USOS, 0)
	if not raiz then return end
	apagarCoringa()
	coringaId = novoId("CORINGA")
	escreverAtributo(ATR_CORINGA, true)
	vfx("CORINGA_NASCE", { posicao = raiz.Position,
		duracao = CFG.VIDA_CORINGA, id = coringaId })
	tocarEm("CORINGA", raiz.Position, 1.25)
end

--- Chamada no FIM de toda habilidade, pelo callback do `PlaySequence`.
local function fecharHabilidade()
	ocupado = false
	bonusAtivo = false
end

local function comBonus(valor)
	if bonusAtivo then return valor * CFG.BONUS_RAIO end
	return valor
end
--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
--
-- Toda chamada ao Núcleo é OPCIONAL: `-- <fallback>`. A Tool sozinha num place vazio funciona por inteiro.
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

--- O bônus da Carta Coringa entra AQUI, numa porta só: `bonusAtivo` é ligado
--- por `abrirHabilidade` e desligado por `fecharHabilidade`, lá em cima. Se um
--- dia o número mudar, muda no CFG, e as treze habilidades acompanham.
local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local pedido = bonusAtivo and (bruto * CFG.BONUS_DANO) or bruto
	local final = pedido
	creditar(alvoHum)
	alvoHum:TakeDamage(final)
	return final
end

--- Alvos num raio. Quem filtra time é o Núcleo; o fallback é consulta espacial
--- sob demanda, nunca varredura do mundo por assinatura.
---
--- `personagem` é EXCLUÍDO da consulta: é o que garante que nenhuma das treze
--- fere o próprio portador, mesmo as que estouram em cima dele.
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

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or 20)
end

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

--- Prender no lugar com prazo. `BodyPosition` onde o alvo JÁ ESTÁ — não é
--- teleporte, é âncora. Nunca `Anchored`, que travaria o personagem inteiro e
--- deixaria o jogador preso se a Tool sumisse no meio.
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

--- Lentidão com volta garantida. Guarda a velocidade ANTES e devolve essa —
--- nunca um número fixo, porque o alvo pode ter velocidade própria.
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

--- Dano em área com NÚCLEO e BORDA. Dois raios é o que impede uma explosão
--- grande de matar meio servidor por estar por perto.
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

--- Cura o portador. `Health` escrito à mão é proibido em DANO — mas cura não
--- é dano, e `TakeDamage` negativo não existe. O teto é `MaxHealth`.
local function curar(quanto)
	if not (humanoide and humanoide.Parent and humanoide.Health > 0) then
		return 0
	end
	local antes = humanoide.Health
	humanoide.Health = math.min(humanoide.MaxHealth, antes + quanto)
	return humanoide.Health - antes
end


function limparTudo()
	novaGeracao("P")
	apagarEfeito(guardaId)
	guardaId = nil
end

function segundaEtapa()
	return guardaId ~= nil
end

--- Os Reis ACOMPANHAM o portador: eles são guarda, e guarda que fica para trás
--- não guarda nada.
local function seguirGuarda()
	local minha = novaGeracao("P")
	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		while geracao.P == minha and os.clock() < ate do
			if not (personagem and raiz and raiz.Parent
					and humanoide and humanoide.Health > 0) then
				break
			end
			vfx("MOVER", { id = guardaId, posicao = raiz.Position,
				tempo = 0.3 })
			task.wait(0.3)
		end
		if geracao.P == minha then
			apagarEfeito(guardaId)
			guardaId = nil
		end
	end)
end

local function levantarGuarda()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("GUARDA_REAL", despachar({
		CARGA = { sfx = { "GUARDA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(guardaId)
			guardaId = novoId("GUARDA")
			vfx("GUARDA_SOBE", { posicao = raiz.Position,
				raio = CFG.ORBITA, duracao = CFG.DURACAO, id = guardaId })
			tocarEm("GUARDA", raiz.Position, 1)
			seguirGuarda()
		end },
	}), fecharHabilidade)
end

local function lancarRei(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("REI_LANCA", despachar({
		CARGA = { sfx = { "REI", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("GUARDA_LANCA", { origem = origem, destino = ponto,
				voo = CFG.VOO })
			tocarEm("REI", ponto, 1.05)
			for _, alvo in ipairs(alvosEm(ponto, comBonus(CFG.RAIO_REI), 10)) do
				aplicarDano(alvo, CFG.DANO_REI)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - origem)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.32)
				end
			end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		lancarRei(mira)
	else
		levantarGuarda()
	end
end

--- Extra: os quatro batem no chão de uma vez, e a guarda ACABA. É o preço —
--- quem quer o estouro abre mão da proteção.
function extra(_mira)
	if not guardaId then return end
	abrirHabilidade()
	ocupado = true
	local meu = guardaId
	rig:PlaySequence("REI_BAQUE", despachar({
		CARGA  = { sfx = { "REI", 0.9 } },
		SEGURA = { sfx = { "GUARDA", 0.85 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position
			vfx("GUARDA_BAQUE", { posicao = centro,
				raio = comBonus(CFG.RAIO_BAQUE), id = meu })
			tocarEm("REI", centro, 0.85)
			golpearArea(centro, comBonus(CFG.RAIO_BAQUE), CFG.NUCLEO_BAQUE,
				CFG.DANO_BAQUE, CFG.BORDA_BAQUE, CFG.EMPURRAO * 0.6,
				CFG.TOMBO)
			novaGeracao("P")
			apagarEfeito(meu)
			if guardaId == meu then guardaId = nil end
		end },
	}), fecharHabilidade)
end

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
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente(20) end
	-- a segunda etapa é a metade de trás da MESMA habilidade: cobrar recarga
	-- de novo por ela a tornaria inalcançável na prática.
	if not segundaEtapa() then
		if not pronto(ultimoM1, CFG.RECARGA) then return end
		ultimoM1 = os.clock()
	end
	primaria(mira)
end)

AcaoRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente(20) end
	if not pronto(ultimoExtra, CFG.RECARGA_EXTRA) then return end
	ultimoExtra = os.clock()
	extra(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then return end

	rig = Animator.new(personagem, "XesterGuarda", Poses, Poses.SEQUENCIAS,
		Poses.TRACKS)

	-- a Forma 2 acende sozinha: quem já virou dragão com o `Eclipse Deck`
	-- saca esta Tool e continua dragão, porque o estado mora no Character.
	if formaAtual() == 2 then
		porCajado()
		ligarAura()
	end

	-- morte devolve tudo. O cajado morre com o personagem sem ninguém pedir.
	guardar(humanoide.Died:Connect(function()
		limparTudo()
		apagarAura()
	end))
end)

--- As DUAS portas. `Unequipped` sozinho não cobre a Tool ser destruída no meio
--- de uma sequência.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	bonusAtivo = false
	limparTudo()
	apagarAura()
	acabarCena()
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
-- ISTO ESTAVA FORA DO GERADOR — o terceiro conjunto com o mesmo defeito
-- (DRAMA, COLLECTOR e agora XESTER). A ligação foi enxertada nos arquivos
-- PRONTOS por `FERRAMENTAS/ligar_deposito.py`, e a primeira regeneração a
-- perdia: as 13 Tools voltavam a não ter depósito, e só o
-- `verificar_deposito_vfx.py` percebia.
--
-- Enxerto que não volta para o gerador é conserto que dura até a próxima
-- geração.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
