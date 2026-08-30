-- Bomba_Nuclear_Server_V1.lua
-- Script de servidor — Bomba Nuclear
--
-- CLONE do bomba_v4: mesmo Handle, mesmo mesh, mesmos sons.
-- Habilidade única, em `Tool.Activated`. Sem Extra, sem AcaoRemote.
--
--   M1  uma nuke — cogumelo, clarão e três anéis
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

local ARQUETIPO = "EXPLOSIVO"

local CFG = {
	EMPURRAO      = 50,
	ALCANCE_MAX   = 150,
	FORCA_MIN     = 45,
	ARCO          = 18,
	VIDA_BOMBA    = 6,
	PRAZO         = 1,

	RECARGA       = 45,
	DANO          = 120,
	RAIO          = 90,
	ESCALA        = 3,
	PRAZO_NUKE    = 1.4,   -- o tempo de queda antes do estouro

	ANEIS         = 3,
	INTERVALO_ANEL = 0.22,
	DANO_ANEL     = 25,
	RAIO_ANEL     = 130,

	DANO_NO_DONO  = 40,    -- nuke no próprio pé cobra o preço
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
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

--- A nuke estoura em CAMADAS: o centro leva tudo de uma vez, e depois três
--- anéis expandindo cobram o resto. Um estouro só, num raio de 90, mataria
--- silenciosamente quem estivesse na borda sem nenhum aviso visual.
local function detonarNuke(centro)
	vfx("NUKE", { posicao = centro, escala = CFG.ESCALA })

	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 20)) do
		aplicarDano(alvo, CFG.DANO)
		local corpo = alvo.Parent
		local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - centro) + Vector3.new(0, 1, 0),
				CFG.EMPURRAO * 2.5, 0.4)
		end
	end

	local i = 1
	while i <= CFG.ANEIS do
		local indice = i
		task.delay(indice * CFG.INTERVALO_ANEL, function()
			if not (personagem and personagem.Parent) then return end
			local raioAnel = CFG.RAIO + (CFG.RAIO_ANEL - CFG.RAIO)
				* (indice / CFG.ANEIS)
			for _, alvo in ipairs(alvosEm(centro, raioAnel, 20)) do
				aplicarDano(alvo, CFG.DANO_ANEL)
			end
		end)
		i = i + 1
	end

	-- O portador não é imune à própria nuke, se estiver perto.
	if humanoide and humanoide.Health > 0 and raiz then
		if (raiz.Position - centro).Magnitude < CFG.RAIO then
			local reduzido = CFG.DANO_NO_DONO
			humanoide:TakeDamage(reduzido)
		end
	end
end

function primaria(mira)
	tocar("Throw", Handle, 0.6)
	if rig then rig:PlaySequence("CHAMADO") end
	piscarHandle(1.4)

	-- cai de cima, no ponto mirado
	local alto = mira + Vector3.new(0, 220, 0)
	vfx("METEORO", {
		origem = alto, posicao = mira, duracao = CFG.PRAZO_NUKE,
		escala = 2.4, cor = Color3.fromRGB(255, 245, 214),
	})

	task.delay(CFG.PRAZO_NUKE, function()
		if not (personagem and personagem.Parent) then return end
		detonarNuke(mira)
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

--- Recarga por TIMESTAMP, como no original: sobrevive a desequipar/equipar, e
--- por isso não dá para zerar a recarga guardando e sacando a Tool.
VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not personagem then return end
	if typeof(mira) ~= "Vector3" then
		mira = raiz and (raiz.Position + raiz.CFrame.LookVector * 20) or Vector3.new()
	end
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

	rig = Animator.new(personagem, "BombaNuclear", Poses, Poses.SEQUENCIAS)
end)

local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
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
