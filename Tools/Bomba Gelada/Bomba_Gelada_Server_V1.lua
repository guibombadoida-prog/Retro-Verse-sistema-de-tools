-- Bomba_Gelada_Server_V1.lua
-- Script de servidor — Bomba Gelada
--
-- CLONE do bomba_v4: mesmo Handle, mesmo mesh, mesmos sons.
-- Habilidade única, em `Tool.Activated`. Sem Extra, sem AcaoRemote.
--
--   M1  congela quem pega e deixa um chão de gelo escorregadio
--
-- CONVERSÃO (§12.12.2) — o que veio do original foram os NÚMEROS:
--   dano 20 · raio 20 · 3 mini a 20% em raio 15 · delay 1 s · CD 1 s ·
--   explode ao tocar Humanoid OU por prazo.
--
-- O que NÃO veio, e por quê:
--   `require(8199013483)`  id numérico é execução de código remoto
--   `IsAlly` próprio       regra de combate tem uma porta só: o Núcleo
--   `workspace:GetDescendants()` por explosão — varria o jogo inteiro
--   `tick()` alimentando geometria, e a expansão animada NO SERVIDOR
--                          (replica a ~20 Hz; a expansão agora é Tween no cliente)
--   `math.random` na dispersão — virou ângulo áureo
--   `:Destroy()` e `AncestryChanged` — viraram `Parent = nil` e `Destroying`
--
-- Gerado por FERRAMENTAS/gerar_servers_bombas.py. Editar aqui à mão faz as
-- seis derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "GELO"

local CFG = {
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	EMPURRAO      = 50,
	ALCANCE_MAX   = 150,
	FORCA_MIN     = 45,
	ARCO          = 18,
	VIDA_BOMBA    = 6,
	PRAZO         = 1,

	RECARGA       = 14,
	DANO          = 26,
	RAIO          = 24,
	ESCALA        = 1.5,

	CONGELA       = 2.2,    -- segundos parado
	RAIO_CHAO     = 26,
	VIDA_CHAO     = 8,
	ATRITO_GELO   = 0.05,
	LENTIDAO      = 0.4,    -- fração da WalkSpeed de quem pisa no gelo
	PASSO_CHAO    = 0.4,
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
local ultimoUso = 0
local ativos = {}
local semente = 0

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

--- Jitter determinístico em [-1,1]. No lugar do math.random da dispersão:
--- mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

--- Toca um som do Handle numa ÂNCORA PRÓPRIA, nunca na peça que o pediu.
---
--- Era o bug que emudecia a explosão das seis: `tocar("Explode", bomba)`
--- punha o Sound dentro da bomba, e a linha seguinte tirava a bomba do mundo.
--- O som morria no quadro em que nascia. Um `Sound` só toca enquanto tem pai
--- no DataModel, então ele precisa de um pai que sobreviva a ele.
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

local function tocarEm(nome, posicao, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = ancora
	som:Play()

	local vida = corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1)
	Debris:AddItem(ancora, vida)
	return som
end

--- Versão presa a uma peça — só para peça que NÃO vai sumir (o Handle).
local function tocar(nome, onde, pitch, corte)
	local alvo = onde or Handle
	if alvo ~= Handle then
		-- qualquer peça que não seja o Handle pode sumir no meio do som
		return tocarEm(nome, alvo.Position, pitch, corte)
	end
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica (§12.5 / §12.6)
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

--- Alvos num raio. O original varria `workspace:GetDescendants()` INTEIRO a
--- cada explosão; aqui é consulta espacial, e o filtro de time é do Núcleo.
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

local function empurrar(alvoHum, direcao, forca, tempo)
	local corpo = alvoHum.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not alvoRaiz or direcao.Magnitude < 0.01 then return end
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = direcao.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, tempo or 0.2)
end

--- Estouro: dano em raio + empurrão + o beat de VFX para o cliente desenhar.
local function estourar(posicao, raio, dano, escala, tipo)
	vfx(tipo or "EXPLOSAO", { posicao = posicao, escala = escala or 1 })
	for _, alvo in ipairs(alvosEm(posicao, raio, 14)) do
		aplicarDano(alvo, dano)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - posicao) + Vector3.new(0, 0.3, 0),
				CFG.EMPURRAO, 0.2)
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- ARREMESSO — a bomba é Part NÃO ancorada, movida por FÍSICA
--
-- Física replica com interpolação; parte ancorada movida por script de
-- servidor replica a ~20 Hz picotado. É por isso que a bomba voa por
-- BodyVelocity e não por CFrame no Heartbeat.
--═══════════════════════════════════════════════════════════════

local function novaBomba(posicao, tamanho)
	local bomba = Handle:Clone()
	bomba.Name = "Bomba"
	bomba.Transparency = 0
	bomba.CanCollide = true
	bomba.Anchored = false
	bomba.Massless = false
	bomba.Size = Handle.Size * (tamanho or 1)
	bomba.CFrame = CFrame.new(posicao)
	for _, filho in ipairs(bomba:GetChildren()) do
		if filho:IsA("Sound") then filho.Parent = nil end
	end
	bomba.Parent = workspace
	pcall(function() bomba:SetNetworkOwner(nil) end)
	Debris:AddItem(bomba, CFG.VIDA_BOMBA)
	return bomba
end

local function rastroDe(bomba)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = bomba
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = bomba
	local rastro = Instance.new("Trail")
	rastro.Attachment0, rastro.Attachment1 = a0, a1
	rastro.FaceCamera = true
	rastro.Lifetime = 0.25
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.WidthScale = NumberSequence.new(1, 0)
	rastro.Parent = bomba
end

--- Some com a bomba sem `:Destroy()`: transparente, sem colisão, e o Debris
--- recolhe. Destruir na hora deixa o som do estouro sem pai.
local function sumir(bomba)
	if not bomba or not bomba.Parent then return end
	bomba.Transparency = 1
	bomba.CanCollide = false
	bomba.CanTouch = false
	Debris:AddItem(bomba, 0.15)
end

--- Arremessa a bomba na direção da mira e chama `aoEstourar(posicao)` quando
--- ela tocar um Humanoid ou o prazo vencer — o que vier primeiro.
local function arremessar(mira, aoEstourar, prazo)
	local origem = Handle.Position
	local bomba = novaBomba(origem, 1)
	bomba.CFrame = CFrame.new(origem, mira)
	rastroDe(bomba)

	local dist = math.min((origem - mira).Magnitude, CFG.ALCANCE_MAX)
	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = bomba.CFrame.LookVector * math.max(dist, CFG.FORCA_MIN)
		+ Vector3.new(0, CFG.ARCO, 0)
	impulso.Parent = bomba
	Debris:AddItem(impulso, 0.1)

	local estourou = false
	local function detonar()
		if estourou or not bomba.Parent then return end
		estourou = true
		local onde = bomba.Position
		tocar("Explode", bomba, 1)
		sumir(bomba)
		aoEstourar(onde)
	end

	guardar(bomba.Touched:Connect(function(atingido)
		if estourou then return end
		local corpo = atingido and atingido.Parent
		if not corpo or corpo == personagem then return end
		local hum = corpo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then detonar() end
	end))

	task.delay(prazo or CFG.PRAZO, detonar)
	return bomba
end

--- Esconde o Handle enquanto a bomba está no ar e devolve com o "crescer" do
--- original. `Size` guardado uma vez — reler depois pegaria o valor animado.
local TAMANHO_HANDLE = Handle.Size

local function piscarHandle(tempo)
	Handle.Transparency = 1
	Handle.Size = Vector3.new(0.05, 0.05, 0.05)
	game:GetService("TweenService"):Create(Handle,
		TweenInfo.new(tempo or 1), { Size = TAMANHO_HANDLE }):Play()
	task.delay(tempo or 1, function()
		if Handle.Parent then Handle.Transparency = 0 end
	end)
end

--═══════════════════════════════════════════════════════════════
-- HABILIDADE
--═══════════════════════════════════════════════════════════════

--- Velocidade guardada e SEMPRE devolvida. Congelar sem descongelar é bug sem
--- saída para o jogador — e o `desmontar` também devolve, para largar a Tool
--- no meio não deixar ninguém preso.
local congelados = {}
local chaos = {}

local function devolverMovimento()
	for alvo, guardadoAlvo in pairs(congelados) do
		if alvo and alvo.Parent then
			alvo.WalkSpeed = guardadoAlvo.velocidade
			alvo.JumpPower = guardadoAlvo.pulo
			alvo.JumpHeight = guardadoAlvo.altura
		end
	end
	congelados = {}
end

local function congelar(alvo, tempo, parar)
	if congelados[alvo] then return end
	congelados[alvo] = {
		velocidade = alvo.WalkSpeed,
		pulo = alvo.JumpPower,
		altura = alvo.JumpHeight,
	}
	if parar then
		alvo.WalkSpeed = 0
		alvo.JumpPower = 0
		alvo.JumpHeight = 0
	else
		alvo.WalkSpeed = alvo.WalkSpeed * CFG.LENTIDAO
	end

	local corpo = alvo.Parent
	vfx("GELO", {
		alvoNome = corpo and corpo.Name,
		deslocamento = Vector3.new(0, -2.6, 0),
		escala = 1,
	})

	task.delay(tempo, function()
		local guardadoAlvo = congelados[alvo]
		if guardadoAlvo and alvo and alvo.Parent then
			alvo.WalkSpeed = guardadoAlvo.velocidade
			alvo.JumpPower = guardadoAlvo.pulo
			alvo.JumpHeight = guardadoAlvo.altura
		end
		congelados[alvo] = nil
	end)
end

--- O chão de gelo é uma Part ANCORADA com atrito baixo. Ela nasce e não se
--- move — nada de CFrame por frame no servidor. O visual é do cliente.
local function porChao(centro)
	local id = "gelo_" .. tostring(proximo())

	local chao = Instance.new("Part")
	chao.Name = "ChaoDeGelo"
	chao.Anchored = true
	chao.CanCollide = true
	chao.Size = Vector3.new(CFG.RAIO_CHAO * 2, 0.4, CFG.RAIO_CHAO * 2)
	chao.CFrame = CFrame.new(centro - Vector3.new(0, 2.6, 0))
	chao.Material = Enum.Material.Ice
	chao.Color = Color3.fromRGB(150, 220, 255)
	chao.Transparency = 0.45
	chao.TopSurface = Enum.SurfaceType.Smooth
	chao.CustomPhysicalProperties =
		PhysicalProperties.new(0.9, CFG.ATRITO_GELO, 0.1, 1, 1)
	chao.Parent = workspace
	table.insert(chaos, chao)
	Debris:AddItem(chao, CFG.VIDA_CHAO)

	vfx("CHAO_GELO", { posicao = centro - Vector3.new(0, 2.4, 0),
		escala = CFG.RAIO_CHAO, id = id, duracao = CFG.VIDA_CHAO })

	-- Quem estiver em cima fica lento enquanto o gelo durar
	local fim = os.clock() + CFG.VIDA_CHAO
	local proximoPasso = 0
	local laco
	laco = guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		if agora >= fim or not chao.Parent then
			if laco then laco:Disconnect() end
			vfx("PARAR", { id = id })
			return
		end
		if agora < proximoPasso then return end
		proximoPasso = agora + CFG.PASSO_CHAO

		for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CHAO, 14)) do
			congelar(alvo, CFG.PASSO_CHAO * 2, false)
		end
	end))
end

function primaria(mira)
	tocar("Throw", Handle, 1.3)
	if rig then rig:PlaySequence("ARREMESSO") end
	piscarHandle(1)

	arremessar(mira, function(onde)
		vfx("GELO", { posicao = onde, escala = CFG.ESCALA })
		for _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 14)) do
			aplicarDano(alvo, CFG.DANO)
			congelar(alvo, CFG.CONGELA, true)
		end
		porChao(onde)
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

--- Recarga por TIMESTAMP, como no original: sobrevive a desequipar/equipar, e
--- por isso não dá para zerar a recarga guardando e sacando a Tool.
VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not personagem then return end
	if not taxaOk() then return end
	mira = sanearMira(mira)
		or (raiz and (raiz.Position + raiz.CFrame.LookVector * 20))
		or Vector3.new()
	if not humanoide or humanoide.Health <= 0 then return end

	local agora = os.clock()
	if agora - ultimoUso < CFG.RECARGA then return end
	ultimoUso = agora

	primaria(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "BombaGelada", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	devolverMovimento()
	for _, chao in ipairs(chaos) do
		if chao and chao.Parent then chao.Parent = nil end
	end
	table.clear(chaos)
	if Handle.Parent then
		Handle.Transparency = 0
		Handle.Size = TAMANHO_HANDLE
	end
	if rig then
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
