-- Alvenaria_Server_V1.lua
-- Script de servidor — Alvenaria  (conjunto CRIAÇÃO)
--
--   M1   Tijolo
--   R    Muralha   (Extra 1)
--   T    Torre   (Extra 2)
--
--   Handle autoral: colher de pedreiro com tijolo e argamassa
--   TIJOLO 131219241 (SFX: Gavel) · MURALHA 281633012
--   (earthparticle) · TORRE 4870579875 (earthquake1) — do catalogo
--
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

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "MELEE"

local CFG = {
	ALCANCE       = 11,
	RECARGA       = 0.9,
	RAIO          = 7,
	DANO          = 30,

	RECARGA_R     = 16,
	SECOES        = 3,
	LARGURA_MURO  = 18,
	ALTURA_MURO   = 9,
	ESPESSURA     = 1.6,
	DISTANCIA     = 9,
	VIDA_MURO     = 12,

	RECARGA_T     = 22,
	RAIO_TORRE    = 4,
	ALTURA_TORRE  = 16,
	VIDA_TORRE    = 10,
	DANO_TORRE    = 45,
	LEVANTA       = 78,
	TOMBO         = 1.2,
	TETO_CRIADAS  = 8,
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT


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

--- Alvos ao longo de uma RETA. É o que o traço precisa: quem está NO CAMINHO,
--- não quem está perto do ponto final.
local function alvosNaReta(origem, direcao, alcance, largura, limite)
	local achados, vistos = {}, {}
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
	filtro.FilterDescendantsInstances = { personagem }
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

local criadas = {}

--- Manda o desmanche para o cliente e tira a peça do mundo.
---
--- O `RECOLHER` não é enfeite: sem ele o jogador vê a muralha sumir e não sabe
--- se ela acabou ou se quebrou. Com ele, ela volta a ser andaime e apaga —
--- que é a única leitura possível de "o prazo venceu".
local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
		vfx("RECOLHER", {
			quadro = reg.peca.CFrame, tamanho = reg.peca.Size,
			cor = reg.peca.Color,
		})
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


--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil

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


--══════════════════════════════════════════════════════════════
-- M1 — o tijolo
--══════════════════════════════════════════════════════════════

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("TIJOLO", despachar({

		CARGA = { sfx = { "TIJOLO", 1.2 } },

		GOLPE = {
			sfx = { "TIJOLO", 1.0 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("TIJOLO", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(quem, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a muralha
--
-- ELA NÃO DÁ DANO NENHUM, e isso é o desenho. É uma habilidade de TERRENO:
-- três seções de pedra colidível à frente, com prazo. O que ela faz é decidir
-- por onde o outro pode vir.
--
-- A muralha nasce À FRENTE, não em volta: nascer em volta prenderia quem a
-- ergueu dentro dela.
--══════════════════════════════════════════════════════════════

function extraR()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("MURALHA", despachar({

		CARGA = { sfx = { "MURALHA", 1.1 } },
		SEGURA = { sfx = { "TIJOLO", 1.3 } },

		ERGUE = {
			sfx = { "MURALHA", 0.85 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local base = noChao(raiz.Position + direcao * CFG.DISTANCIA)
				local quadro = CFrame.lookAt(
					base + Vector3.new(0, CFG.ALTURA_MURO * 0.5, 0),
					base + Vector3.new(0, CFG.ALTURA_MURO * 0.5, 0) + direcao)

				vfx("MURALHA", { quadro = quadro, secoes = CFG.SECOES,
					tamanho = Vector3.new(CFG.LARGURA_MURO, CFG.ALTURA_MURO,
						CFG.ESPESSURA) })
				tocarEm("MURALHA", base, 0.9)

				local largura = CFG.LARGURA_MURO / CFG.SECOES
				local i = 0
				while i < CFG.SECOES do
					local desvio = -CFG.LARGURA_MURO * 0.5
						+ largura * (i + 0.5)
					criar(quadro * CFrame.new(desvio, 0, 0),
						Vector3.new(largura * 0.96, CFG.ALTURA_MURO,
							CFG.ESPESSURA), {
							Color = Color3.fromRGB(150, 146, 138),
							Material = Enum.Material.Concrete,
						}, CFG.VIDA_MURO)
					i = i + 1
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a torre
--
-- Ela abre DEBAIXO do alvo, e o levanta. O empurrão para cima não é enfeite:
-- sem ele o alvo nasce DENTRO da peça e o Roblox o joga para um lado
-- qualquer, ou o prende. Levantar de propósito é a única forma de a
-- habilidade ser legível.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("TORRE", despachar({

		CARGA = { sfx = { "TORRE", 1.0 } },
		SEGURA = { sfx = { "MURALHA", 1.2 } },

		ERGUE = {
			sfx = { "TORRE", 0.8 },
			faz = function()
				local base = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("TORRE", { posicao = base, altura = CFG.ALTURA_TORRE,
					raio = CFG.RAIO_TORRE })
				tocarEm("TORRE", base, 0.8)

				-- levanta ANTES de a peça existir: assim ninguém nasce dentro
				levantar(base, CFG.RAIO_TORRE * 2.4, CFG.LEVANTA, 10)
				for _, quem in ipairs(alvosEm(base, CFG.RAIO_TORRE * 2.4, 10)) do
					aplicarDano(quem, CFG.DANO_TORRE)
					tombar(quem, CFG.TOMBO)
				end

				criar(CFrame.new(base + Vector3.new(0,
						CFG.ALTURA_TORRE * 0.5, 0)),
					Vector3.new(CFG.RAIO_TORRE * 2, CFG.ALTURA_TORRE,
						CFG.RAIO_TORRE * 2), {
						Color = Color3.fromRGB(150, 146, 138),
						Material = Enum.Material.Slate,
					}, CFG.VIDA_TORRE)
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

	rig = Animator.new(personagem, "CriacaoAlvenaria", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	vigiar()
end)

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
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
