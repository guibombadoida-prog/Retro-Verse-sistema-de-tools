-- TitanPropulsor_Server_V1.lua
-- Script de servidor — Titan Propulsor  (conjunto TITAN)
--
--   M1   Investida
--   R    Voo   (Extra 1)
--   T    Desvio   (Extra 2)
--
--   Handle: turbina cromada com bocal e chama Neon
--   INVESTIDA 9126231485 (whoosh) · VOO 8186570431 (Fly)
--   DESVIO 7449437048 (Launch1) — os tres do catalogo do Acervo
--
-- CONJUNTO AUTORAL
--
--   O TITAN não sai de modelo nenhum. Os três `SoundId` desta Tool saem do
--   catálogo do Acervo, que é reuso previsto (§12.16.2) — id de som não se
--   inventa: id chutado é som mudo que nenhum verificador estático pega.
--   A geometria é primitiva soldada, e a lógica é escrita aqui.
--
-- TRÊS HABILIDADES, E UM `AcaoRemote` SÓ
--
--   Quem separa as duas Extras é o NOME DA TECLA no payload, conferido aqui
--   antes de qualquer coisa. Confiar no cliente para dizer qual habilidade
--   rodar seria dar a ele a escolha da recarga também.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. O servidor manda por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_titan.py. Editar aqui à mão faz as
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
	ALCANCE       = 26,
	RECARGA       = 0.8,
	AVANCO        = 78,
	TEMPO_AVANCO  = 0.3,
	RAIO_INVEST   = 7,
	DANO          = 26,
	EMPURRAO      = 55,

	RECARGA_R     = 12,
	SUBIDA        = 68,
	TEMPO_SUBIDA  = 0.4,
	TEMPO_VOO     = 1.3,
	RAIO_POUSO    = 20,
	NUCLEO_POUSO  = 8,
	DANO_POUSO    = 52,
	BORDA_POUSO   = 20,
	EMPURRAO_POUSO = 85,
	TOMBO_POUSO   = 1.2,

	RECARGA_T     = 9,
	LATERAL       = 66,
	TEMPO_LATERAL = 0.22,
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
local vooId = nil

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

--- Ângulo áureo por índice: é o que espalha os raios do leque e os pontos do
--- chuvisco sem sorteio nenhum.
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
-- `tocarEm` cria uma âncora própria.
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
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--
-- Cada sequência tem uma TABELA, um registro por keyframe:
--
--     GOLPE = { sfx = { "CORTE", 0.9 }, faz = bater }
--
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
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
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

--- Alvos num raio, por consulta espacial sob demanda — nunca varredura do
--- mundo inteiro por assinatura.
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

--- Dano em área com NÚCLEO e BORDA. Raio grande com dano chapado mata quem
--- está na borda sem nenhum aviso visual.
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

--- Alvos num CONE à frente. O que separa cone de esfera é o produto escalar:
--- sem ele, "cone de choque" acerta quem está atrás de quem gritou.
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

--- Alvos ao longo de uma RETA. É o que o feixe precisa: quem está no caminho,
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

--- Avança o PRÓPRIO personagem. `BodyVelocity` com prazo, nunca escrita de
--- `CFrame` por quadro: escrever CFrame no servidor briga com a autoridade de
--- física do dono e produz o tranco que o jogador lê como travada.
local function avancar(direcao, forca, tempo)
	if not raiz or direcao.Magnitude < 0.01 then return nil end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = raiz
	Debris:AddItem(impulso, tempo or 0.3)
	return impulso
end


--══════════════════════════════════════════════════════════════
-- M1 — a investida
--
-- Avança e atropela quem estiver no caminho. O alcance do dano acompanha o
-- avanço: o servidor percorre a MESMA reta por aritmética, e por isso o que
-- ele acerta é o que o cliente desenhou.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("INVESTIDA", despachar({

		CARGA = { sfx = { "INVESTIDA", 1.2 } },

		GOLPE = {
			sfx = { "INVESTIDA", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 1.6, 0)
				local direcao = raiz.CFrame.LookVector

				avancar(direcao, CFG.AVANCO, CFG.TEMPO_AVANCO)
				vfx("INVESTIDA", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE })

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.RAIO_INVEST, 10)) do
					aplicarDano(alvo, CFG.DANO)
					empurrar(alvo, direcao + Vector3.new(0, 0.45, 0),
						CFG.EMPURRAO, 0.26)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o voo curto, com pouso
--
-- Sobe, fica no ar `TEMPO_VOO`, e desce batendo. A subida é `BodyVelocity` com
-- prazo — nunca `Anchored`, que travaria o personagem inteiro e deixaria o
-- jogador preso no ar se a Tool sumisse no meio.
--
-- O POUSO ACONTECE MESMO SE A TOOL FOR GUARDADA. Ele é `task.delay`, e o dano
-- só é aplicado se o personagem ainda existir: guardar a Tool no meio do voo
-- não pode deixar o jogador flutuando nem cobrar a recarga sem entregar nada.
--══════════════════════════════════════════════════════════════

function pararVoo()
	if vooId then
		vfx("PARAR", { id = vooId })
		vooId = nil
	end
end

function extraR(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("VOO", despachar({

		CARGA = { sfx = { "VOO", 1.15 } },

		SEGURA = { sfx = { "INVESTIDA", 1.3 } },

		GOLPE = {
			sfx = { "VOO", 0.9 },
			faz = function()
				if not raiz then return end
				pararVoo()

				avancar(Vector3.new(0, 1, 0), CFG.SUBIDA, CFG.TEMPO_SUBIDA)

				vooId = novoId("voo")
				vfx("VOO", { id = vooId, posicao = raiz.Position,
					peca = raiz, duracao = CFG.TEMPO_VOO })

				task.delay(CFG.TEMPO_VOO, function()
					pararVoo()
					if not (personagem and personagem.Parent and raiz) then
						return
					end
					if humanoide and humanoide.Health <= 0 then return end

					local centro = raiz.Position
					vfx("POUSO", { posicao = centro,
						direcao = raiz.CFrame.LookVector,
						raio = CFG.RAIO_POUSO })
					tocarEm("VOO", centro, 0.75)

					golpearArea(centro, CFG.RAIO_POUSO, CFG.NUCLEO_POUSO,
						CFG.DANO_POUSO, CFG.BORDA_POUSO,
						CFG.EMPURRAO_POUSO, CFG.TOMBO_POUSO, 16)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — o desvio lateral
--
-- Recarga curta de propósito: é mobilidade, não dano. Ela não acerta ninguém, e
-- por isso pode voltar rápido sem virar a habilidade principal da Tool.
--
-- O LADO SAI DA MIRA. Se o jogador está mirando à esquerda, ele desvia para a
-- esquerda; sem mira, desvia para a direita. Um desvio de lado fixo é inútil
-- metade das vezes.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not rig or not raiz then return end
	local alvoMira = mira

	ocupado = true
	rig:PlaySequence("DESVIO", despachar({

		CARGA = { sfx = { "DESVIO", 1.25 } },

		GOLPE = {
			sfx = { "DESVIO", 1.0 },
			faz = function()
				if not raiz then return end
				local lado = raiz.CFrame.RightVector
				if typeof(alvoMira) == "Vector3" then
					local delta = alvoMira - raiz.Position
					if delta.Magnitude > 1 and delta.Unit:Dot(lado) < 0 then
						lado = -lado
					end
				end
				avancar(lado + Vector3.new(0, 0.22, 0),
					CFG.LATERAL, CFG.TEMPO_LATERAL)
				vfx("DESVIO", { posicao = raiz.Position, direcao = lado })
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

--- As DUAS Extras chegam pelo MESMO remote. A tecla vem no payload e é
--- conferida aqui: qualquer coisa fora de "R" e "T" é descartada sem resposta.
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

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "TitanPropulsor", Poses,
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
	pararVoo()
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
