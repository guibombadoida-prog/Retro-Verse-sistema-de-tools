--[[
═══════════════════════════════════════════════════════════════════════════
  HAWKING COSMIC SHURIKEN RADIATION — SERVER V1
  Tool: "Sword of Cosmic Entity (Revamped)"  (Cosmic Sword Revamp)
═══════════════════════════════════════════════════════════════════════════

  ONDE COLAR
    Como Script (servidor) dentro da Tool, com o nome
    `HawkingCosmicShurikenRadiation_Server_V1`.

  FUSÍVEL DE DUAS FASES
    FASE 1 — SUCÇÃO. A shuriken nasce gigante à frente do jogador, gira sobre
      o próprio eixo e puxa todo Humanoid inimigo do raio para perto dela.
      O fusível dela é POR TEMPO, não por toque.
    FASE 2 — EXPLOSÃO COLOSSAL, e o split em 5 mini shurikens.

  POR QUE O FUSÍVEL DA PRINCIPAL É POR TEMPO, E NÃO POR TOQUE
    Nas bombas o padrão é "explode ao tocar Humanoid OU por prazo, o que vier
    primeiro". Aqui esse padrão se anula: a habilidade PUXA inimigos para
    dentro da shuriken, então o primeiro toque aconteceria no instante em que
    o puxão começasse a funcionar — a sucção morreria antes de existir.
    Então a principal usa o fusível por prazo (o mesmo da queda da Bomba
    Meteórica), e as 5 MINI usam o fusível de toque-ou-prazo, que é
    exatamente o das mini bombas. As duas metades do padrão estão presentes,
    cada uma onde faz sentido.

  ANTI-FRIENDLY-FIRE
    Por consulta espacial (`GetPartBoundsInRadius`), que já aplica o filtro de
    time e nunca devolve o dono. As Tools deste repositório NÃO carregam
    `IsAlly` próprio: a função foi removida na conversão porque regra de
    combate tem uma porta só (REGRA 12). Sem o Núcleo instalado, o fallback
    abaixo faz a consulta espacial e exclui o próprio personagem.

  CLEANUP
    Shuriken e mini shurikens em voo NÃO são canceladas ao desequipar —
    mesmo padrão das bombas. Só limpam na MORTE do dono ou na destruição da
    Tool.

  PROIBIÇÕES RESPEITADAS
    Zero `math.random` (as 5 direções são tabela fixa; o resto é ângulo
    áureo). Zero `:Destroy()` (Transparency = 1 + Debris, ou Parent = nil).
    Zero `tick()`. Zero geometria movida por frame no servidor.
═══════════════════════════════════════════════════════════════════════════
--]]

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool = script.Parent
local Deposito = require(Tool:WaitForChild("DepositoVFX"))

Tool.CanBeDropped   = false
Tool.RequiresHandle = true

local Handle = Tool:WaitForChild("Handle", 10)

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "COSMICO"

local CFG = {
	RECARGA          = 22,

	-- ── FASE 1: a shuriken viva ──
	ESCALA_SHURIKEN  = 14,     -- EXTREMAMENTE gigante, como pedido
	ALTURA           = 9,      -- acima do chão, à frente do jogador
	DISTANCIA        = 22,     -- à frente do jogador
	SUCCAO_DURACAO   = 3.5,
	SUCCAO_RAIO      = 70,
	SUCCAO_PULSO     = 0.15,   -- de quanto em quanto tempo o puxão é renovado
	PUXAO_MAX        = 95,     -- velocidade de puxão a raio cheio
	PUXAO_MIN        = 18,     -- perto do centro o puxão afrouxa
	ZONA_MORTA       = 6,      -- dentro disto não puxa mais (evita tremida)
	DANO_SUCCAO      = 4,      -- radiação Hawking: sangra devagar durante a fase
	GIRO             = 26,     -- rad/s, desenhado pelo CLIENTE

	-- ── FASE 2: a explosão colossal ──
	DANO_CENTRO      = 190,
	DANO_BORDA       = 60,     -- dano cai com a distância (padrão da Nuclear)
	RAIO_EXPLOSAO    = 62,
	EMPURRAO         = 130,
	ESCALA_EXPLOSAO  = 4,

	-- ── FASE 2b: as 5 mini shurikens ──
	MINIS            = 5,
	ESCALA_MINI      = 3.5,
	DANO_MINI        = 45,
	RAIO_MINI        = 22,
	VELOCIDADE_MINI  = 92,
	PRAZO_MINI       = 4,      -- fusível por prazo, se não tocar ninguém
	ESCALA_EXP_MINI  = 1.4,
	VIDA_MINI        = 8,

	-- ── som: nomes REAIS do modelo. Ausente = segue sem quebrar ──
	ESPERA_SOM       = 2,      -- timeout curto do WaitForChild
	SFX_INVOCA       = "Power Up",
	SFX_SUCCAO       = "Locked On",
	SFX_EXPLOSAO     = "ShurikenExplode",
	SFX_MINI         = "ShuriHit",
	SFX_COLOSSAL     = "Supernova",
}

--- As 5 direções fixas do split. Tabela, como MINI_BOMB_SPREADS — nunca
--- math.random, para os dois clientes verem a mesma leva. Uma sobe reta e
--- quatro abrem em cruz inclinada; os vetores são normalizados no uso.
local SPREADS_MINI = {
	Vector3.new( 0.00, 1.00,  0.00),
	Vector3.new( 0.85, 0.45,  0.00),
	Vector3.new(-0.85, 0.45,  0.00),
	Vector3.new( 0.00, 0.45,  0.85),
	Vector3.new( 0.00, 0.45, -0.85),
}

--═══════════════════════════════════════════════════════════════
-- REMOTES — o de ativação já existe na Tool; o de VFX é criado se faltar
--═══════════════════════════════════════════════════════════════

local Remote = Tool:FindFirstChild("Remote")
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = "Remote"
	Remote.Parent = Tool
end

local VFXRemote = Tool:FindFirstChild("HawkingVFXRemote")
if not VFXRemote then
	VFXRemote = Instance.new("RemoteEvent")
	VFXRemote.Name = "HawkingVFXRemote"
	VFXRemote.Parent = Tool
end

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz
local ultimoUso = 0

-- Duas listas separadas, de propósito:
--   `ligacoesDaTool`  morre no unequip (nada aqui hoje, mas o gancho fica)
--   `emVoo`           NÃO morre no unequip — só na morte ou na destruição
local ligacoesEmVoo = {}
local pecasEmVoo    = {}
local ligacaoMorte  = nil

local semente = 0
local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function guardarEmVoo(conexao)
	table.insert(ligacoesEmVoo, conexao)
	return conexao
end

local function limparEmVoo()
	for _, c in ipairs(ligacoesEmVoo) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ligacoesEmVoo)
	for _, p in ipairs(pecasEmVoo) do
		if p and p.Parent then p.Parent = nil end
	end
	table.clear(pecasEmVoo)
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

--- Toca um som do modelo. `WaitForChild` com TIMEOUT CURTO: se o som não
--- existir no clone, devolve nil e o script segue — nunca pendura.
local function tocar(nome, onde, pitch)
	if not Handle then return nil end
	local base = Tool:FindFirstChild(nome, true)
	if not base then
		base = Handle:WaitForChild(nome, CFG.ESPERA_SOM)
	end
	if not base or not base:IsA("Sound") then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = onde or Handle
	som:Play()
	Debris:AddItem(som, (som.TimeLength > 0 and som.TimeLength or 5) + 1)
	return som
end

--═══════════════════════════════════════════════════════════════
-- DANO — a Tool declara, o Núcleo aplica
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

--- Inimigos num raio. NPC é Model com Humanoid, NÃO é Player — varrer
--- `Players:GetPlayers()` não enxergaria NPC nenhum.
local function inimigosEm(posicao, raio, limite)

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
	return corpo and corpo:FindFirstChild("HumanoidRootPart")
end

--═══════════════════════════════════════════════════════════════
-- FASE 1 — SUCÇÃO GRAVITACIONAL
--
-- BodyVelocity por alvo, com força LIMITADA POR DISTÂNCIA e renovada em
-- pulsos. Nunca teleporte, e nunca contínuo:
--   · teleporte tira o controle do jogador e atravessa parede;
--   · puxão contínuo briga com o Humanoid do alvo (dois donos do mesmo
--     corpo), e o alvo trava no lugar tremendo.
-- Pulso curto com prazo curto deixa o Humanoid respirar entre os empurrões —
-- é o mesmo desenho do Colapso Anão.
--═══════════════════════════════════════════════════════════════

local function puxarPara(centro, alvoHum)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end

	local delta = centro - alvoRaiz.Position
	local dist = delta.Magnitude
	if dist < CFG.ZONA_MORTA or dist < 0.01 then return end

	-- Perto do centro puxa pouco, longe puxa muito: a força cresce com a
	-- distância normalizada pelo raio. Sem isso, quem já está colado leva um
	-- empurrão do mesmo tamanho de quem está na borda, e vibra.
	local fracao = math.clamp(dist / CFG.SUCCAO_RAIO, 0, 1)
	local forca = CFG.PUXAO_MIN + (CFG.PUXAO_MAX - CFG.PUXAO_MIN) * fracao

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.P = 1250
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, CFG.SUCCAO_PULSO * 0.9)
end

--═══════════════════════════════════════════════════════════════
-- FASE 2b — AS 5 MINI SHURIKENS
--
-- Fusível de TOQUE-OU-PRAZO, igual ao das mini bombas: explode ao encostar
-- num Humanoid inimigo, ou sozinha quando o prazo vence.
--═══════════════════════════════════════════════════════════════

local function estourarMini(onde)
	vfx("HAWKING_MINI_EXPLODE", { posicao = onde, escala = CFG.ESCALA_EXP_MINI })
	for _, alvo in ipairs(inimigosEm(onde, CFG.RAIO_MINI, 12)) do
		aplicarDano(alvo, CFG.DANO_MINI)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local fora = (alvoRaiz.Position - onde) + Vector3.new(0, 0.4, 0)
			if fora.Magnitude > 0.01 then
				local impulso = Instance.new("BodyVelocity")
				impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				impulso.Velocity = fora.Unit * (CFG.EMPURRAO * 0.5)
				impulso.Parent = alvoRaiz
				Debris:AddItem(impulso, 0.2)
			end
		end
	end
end

local function soltarMini(centro, direcao, indice)
	-- Corpo físico mínimo: uma Part invisível que carrega a colisão. O visual
	-- da mini shuriken é do CLIENTE, que clona o ShurikenModel e gira a 60 Hz.
	-- Parte ancorada movida pelo servidor replicaria a ~20 Hz, picotada.
	local corpo = Instance.new("Part")
	corpo.Name = "HawkingMiniShuriken"
	corpo.Shape = Enum.PartType.Ball
	corpo.Size = Vector3.new(3, 3, 3)
	corpo.Transparency = 1
	corpo.CanCollide = false
	corpo.CanQuery = false
	corpo.Anchored = false
	corpo.Massless = true
	corpo.CFrame = CFrame.new(centro)
	corpo.Parent = workspace
	table.insert(pecasEmVoo, corpo)
	Debris:AddItem(corpo, CFG.VIDA_MINI)
	pcall(function() corpo:SetNetworkOwner(nil) end)

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	impulso.Velocity = direcao.Unit * CFG.VELOCIDADE_MINI
	impulso.Parent = corpo
	Debris:AddItem(impulso, 0.35)

	local id = "hawkmini_" .. tostring(proximo())
	vfx("HAWKING_MINI", {
		id = id, escala = CFG.ESCALA_MINI,
		alvoParte = corpo, duracao = CFG.VIDA_MINI,
	})

	local estourou = false
	local function detonar()
		if estourou or not corpo.Parent then return end
		estourou = true
		local onde = corpo.Position
		tocar(CFG.SFX_MINI, corpo, 1.05 + indice * 0.03)
		vfx("PARAR", { id = id })
		corpo.Transparency = 1
		corpo.CanTouch = false
		Debris:AddItem(corpo, 0.15)
		estourarMini(onde)
	end

	guardarEmVoo(corpo.Touched:Connect(function(atingido)
		if estourou then return end
		local outro = atingido and atingido.Parent
		if not outro or outro == personagem then return end
		local hum = outro:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or hum == humanoide then return end
		-- confere pelo Núcleo se este Humanoid é alvo legítimo
		local legitimo = false
		for _, candidato in ipairs(inimigosEm(corpo.Position, 12, 20)) do
			if candidato == hum then legitimo = true break end
		end
		if legitimo then detonar() end
	end))

	task.delay(CFG.PRAZO_MINI, detonar)
end

--═══════════════════════════════════════════════════════════════
-- FASE 2 — A EXPLOSÃO COLOSSAL
--
-- Dano varia com a distância: cheio no centro, `DANO_BORDA` na borda. É o
-- mesmo desenho da Bomba Nuclear — explosão de raio 62 com dano chapado
-- mataria quem está na borda sem nenhum aviso visual.
--═══════════════════════════════════════════════════════════════

local function explodirColossal(centro)
	tocar(CFG.SFX_EXPLOSAO, Handle, 0.85)
	tocar(CFG.SFX_COLOSSAL, Handle, 0.9)

	vfx("HAWKING_COLOSSAL", { posicao = centro, escala = CFG.ESCALA_EXPLOSAO })

	for _, alvo in ipairs(inimigosEm(centro, CFG.RAIO_EXPLOSAO, 24)) do
		local alvoRaiz = raizDe(alvo)
		local dano = CFG.DANO_CENTRO
		if alvoRaiz then
			local fracao = math.clamp(
				(alvoRaiz.Position - centro).Magnitude / CFG.RAIO_EXPLOSAO, 0, 1)
			dano = CFG.DANO_CENTRO
				+ (CFG.DANO_BORDA - CFG.DANO_CENTRO) * fracao
		end
		aplicarDano(alvo, math.floor(dano + 0.5))

		if alvoRaiz then
			local fora = (alvoRaiz.Position - centro) + Vector3.new(0, 0.6, 0)
			if fora.Magnitude > 0.01 then
				local impulso = Instance.new("BodyVelocity")
				impulso.MaxForce = Vector3.new(1e6, 1e6, 1e6)
				impulso.Velocity = fora.Unit * CFG.EMPURRAO
				impulso.Parent = alvoRaiz
				Debris:AddItem(impulso, 0.35)
			end
		end
	end

	-- o split: 5 direções fixas, da tabela
	local i = 1
	while i <= CFG.MINIS do
		soltarMini(centro, SPREADS_MINI[i], i)
		i = i + 1
	end
end

--═══════════════════════════════════════════════════════════════
-- A HABILIDADE
--═══════════════════════════════════════════════════════════════

local function lancar()
	if not raiz or not personagem then return end

	local frente = raiz.CFrame.LookVector
	local centro = raiz.Position + frente * CFG.DISTANCIA
		+ Vector3.new(0, CFG.ALTURA, 0)
	local id = "hawking_" .. tostring(proximo())

	tocar(CFG.SFX_INVOCA, Handle, 0.9)
	tocar(CFG.SFX_SUCCAO, Handle, 0.8)

	-- A shuriken viva é 100% VFX de CLIENTE: ela fica parada no ar e GIRA,
	-- e girar é mudar CFrame todo frame. No servidor isso replicaria a
	-- ~20 Hz, e o giro rápido que a habilidade pede viraria tranco.
	vfx("HAWKING_SHURIKEN", {
		id = id, posicao = centro,
		escala = CFG.ESCALA_SHURIKEN,
		giro = CFG.GIRO,
		duracao = CFG.SUCCAO_DURACAO,
		raio = CFG.SUCCAO_RAIO,
	})

	local fim = os.clock() + CFG.SUCCAO_DURACAO
	local proximoPulso = 0

	local laco
	laco = guardarEmVoo(RunService.Heartbeat:Connect(function()
		local agora = os.clock()

		if agora >= fim then
			if laco then laco:Disconnect() end
			vfx("PARAR", { id = id })
			explodirColossal(centro)
			return
		end

		if agora < proximoPulso then return end
		proximoPulso = agora + CFG.SUCCAO_PULSO

		for _, alvo in ipairs(inimigosEm(centro, CFG.SUCCAO_RAIO, 20)) do
			puxarPara(centro, alvo)
			-- radiação Hawking: sangra devagar enquanto a sucção dura
			aplicarDano(alvo, CFG.DANO_SUCCAO)
		end
	end))
end

--═══════════════════════════════════════════════════════════════
-- ATIVAÇÃO — recarga por timestamp, sobrevive a desequipar
--═══════════════════════════════════════════════════════════════

Remote.OnServerEvent:Connect(function(quem)
	if quem ~= jogador or not personagem then return end
	if not humanoide or humanoide.Health <= 0 then return end

	local agora = os.clock()
	if agora - ultimoUso < CFG.RECARGA then return end
	ultimoUso = agora

	lancar()
end)

--═══════════════════════════════════════════════════════════════
-- SISTEMA NPC — a Tool na mão de um NPC usa a habilidade sozinha
--═══════════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(1)
		if personagem and not Players:GetPlayerFromCharacter(personagem) then
			if humanoide and humanoide.Health > 0 and raiz then
				local agora = os.clock()
				if agora - ultimoUso >= CFG.RECARGA then
					local perto = inimigosEm(raiz.Position, CFG.SUCCAO_RAIO, 1)
					if #perto > 0 then
						ultimoUso = agora
						lancar()
					end
				end
			end
		end
	end
end)

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA
--═══════════════════════════════════════════════════════════════

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)

	-- A recarga NÃO é zerada aqui: guardar e sacar a Tool não pode ser um
	-- jeito de recarregar de graça.

	if humanoide then
		if ligacaoMorte then ligacaoMorte:Disconnect() end
		ligacaoMorte = humanoide.Died:Connect(limparEmVoo)
	end
end)

-- Desequipar NÃO cancela o que está no ar: a shuriken já lançada continua a
-- sucção e estoura no prazo dela, como as bombas já lançadas continuam.
Tool.Unequipped:Connect(function() end)

Tool.Destroying:Connect(function()
	limparEmVoo()
	if ligacaoMorte then
		ligacaoMorte:Disconnect()
		ligacaoMorte = nil
	end
end)

--═══════════════════════════════════════════════════════════════
-- REGRA Nº 2 — o VFX sai da Tool quando ela chega ao jogador
-- Ver DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
