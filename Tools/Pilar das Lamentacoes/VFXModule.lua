-- VFXModule.lua
-- ModuleScript — desenho de efeito, 100% cliente (conjunto COLLECTOR)
--
-- QUEM DESENHA É O PACK DO ACERVO
--   O fluxo obrigatório manda ler o `_INDICE.md` antes de criar efeito e
--   reusar o que existe. Onda, nova, explosão, corte, anel, rachadura, feixe e
--   espiral são os 10 do `Stella_VFX_Addon`, copiados para `VFXModule/Pack` na
--   montagem. Pack ausente é Tool empobrecida, não quebrada — cada primitiva
--   tem fallback local.
--
-- O QUE É PRÓPRIO DAQUI
--   O anel de selos do Julgamento, a corrente do Portal e o Highlight do Olho.
--   Nenhum dos três existe no pack, e os três são a identidade do conjunto.
--
-- Gerado por FERRAMENTAS/gerar_servers_collector.py.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local M = {}

local COR = {
	OSSO = Color3.fromRGB(226, 214, 198),
	SOMBRA = Color3.fromRGB(24, 20, 30),
	ALMA = Color3.fromRGB(122, 196, 208),
	SENTENCA = Color3.fromRGB(214, 74, 62),
}

--══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL
--══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function deposito()
	if packProcurado then return raizPack end
	packProcurado = true
	raizPack = script:FindFirstChild(PACK.PASTA)
	return raizPack
end

local function efeitoDoPack(nome)
	if not PACK.LIGADO then return nil end
	local guardado = moduloDoPack[nome]
	if guardado ~= nil then
		if guardado == false then return nil end
		return guardado
	end
	local raiz = deposito()
	if not raiz then moduloDoPack[nome] = false return nil end
	local mod = raiz:FindFirstChild(nome)
	if not mod or not mod:IsA("ModuleScript") then
		moduloDoPack[nome] = false
		return nil
	end
	local ok, fn = pcall(require, mod)
	if not ok or type(fn) ~= "function" then
		moduloDoPack[nome] = false
		return nil
	end
	moduloDoPack[nome] = fn
	return fn
end

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Collector VFX] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

local vivos = {}

local function guardarPeca(peca, vida)
	peca.Parent = workspace
	table.insert(vivos, peca)
	Debris:AddItem(peca, vida)
	return peca
end

--══════════════════════════════════════════════════════════════
-- SOM
--
-- Toca aqui, e não no servidor, pelo mesmo motivo do VFX: este script roda em
-- TODO cliente (RunContext = Client), então cada um cria o seu Sound local na
-- posição certa. Todo mundo ouve, posicionado, com custo de rede zero.
--
-- O molde vem de `Tool/SFX/` — o som é filho da Tool, como o resto.
--══════════════════════════════════════════════════════════════

local SFX = script.Parent:FindFirstChild("SFX")

local function som(rotulo, posicao, pitch)
	local base = SFX and SFX:FindFirstChild(rotulo)
	if not base then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored, ancora.CanCollide = true, false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local copia = base:Clone()
	if pitch then copia.PlaybackSpeed = base.PlaybackSpeed * pitch end
	copia.Parent = ancora
	copia:Play()

	table.insert(vivos, ancora)
	local duracao = (copia.TimeLength > 0 and copia.TimeLength or 5) + 1
	Debris:AddItem(ancora, duracao)
	return copia
end

--══════════════════════════════════════════════════════════════
-- SOM
--
-- Toca aqui, e nao no servidor, pelo mesmo motivo do VFX: este script roda em
-- TODO cliente (RunContext = Client), entao cada um cria o seu Sound local na
-- posicao certa. Todo mundo ouve, posicionado, com custo de rede zero.
--
-- O molde vem de `Tool/SFX/` — o som e filho da Tool, como o resto.
--══════════════════════════════════════════════════════════════

local SFX = script.Parent:FindFirstChild("SFX")

local function som(rotulo, posicao, pitch)
	local base = SFX and SFX:FindFirstChild(rotulo)
	if not base then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored, ancora.CanCollide = true, false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local copia = base:Clone()
	if pitch then copia.PlaybackSpeed = base.PlaybackSpeed * pitch end
	copia.Parent = ancora
	copia:Play()

	table.insert(vivos, ancora)
	Debris:AddItem(ancora, (copia.TimeLength > 0 and copia.TimeLength or 5) + 1)
	return copia
end

--══════════════════════════════════════════════════════════════
-- PRIMITIVAS — pack primeiro, fallback local depois
--══════════════════════════════════════════════════════════════

local function onda(posicao, escala, cor, vida)
	local base = Vector3.new(10.775, 2.3, 10.505) * (escala or 1)
	if pk("Shockwave", CFrame.new(posicao), CFrame.new(posicao), vida or 1.2,
			base, base * 3, cor or COR.OSSO, cor or COR.SOMBRA,
			Enum.EasingStyle.Quint) then
		return
	end
	local disco = Instance.new("Part")
	disco.Shape = Enum.PartType.Cylinder
	disco.Size = Vector3.new(0.4, base.X, base.Z)
	disco.CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90))
	disco.Material = Enum.Material.Neon
	disco.Color = cor or COR.OSSO
	disco.Anchored, disco.CanCollide = true, false
	guardarPeca(disco, (vida or 1.2) + 0.5)
	TweenService:Create(disco, TweenInfo.new(vida or 1.2,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = disco.Size * 3, Transparency = 1 }):Play()
end

local function ondaLarga(posicao, escala, cor, vida)
	local base = Vector3.new(14, 1.4, 14) * (escala or 1)
	if pk("Shockwave_2", CFrame.new(posicao), CFrame.new(posicao), vida or 1.8,
			base, base * 3.4, cor or COR.OSSO, cor or COR.SOMBRA,
			Enum.EasingStyle.Quart) then
		return
	end
	onda(posicao, (escala or 1) * 1.5, cor, vida)
end

local function nova(posicao, escala, cor, vida)
	-- Small_Nova recebe Size_A/Size_B como NÚMERO, não Vector3: o corpo do
	-- módulo faz a conta com eles. Mandar Vector3 derruba em
	-- "invalid argument #1 to 'new'", e o pcall engole o erro em silêncio.
	local raio = escala or 4
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Small_Nova", posicao, vida or 0.6, raio, raio * 4,
			cor or COR.OSSO, cor or COR.SOMBRA, Enum.EasingStyle.Quint) then
		return
	end
	local bola = Instance.new("Part")
	bola.Shape = Enum.PartType.Ball
	bola.Size = a
	bola.Material = Enum.Material.Neon
	bola.Color = cor or COR.OSSO
	bola.Anchored, bola.CanCollide = true, false
	bola.CFrame = CFrame.new(posicao)
	guardarPeca(bola, (vida or 0.6) + 0.4)
	TweenService:Create(bola, TweenInfo.new(vida or 0.6,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = a * 4, Transparency = 1 }):Play()
end

local function estouro(posicao, escala, cor, vida)
	local raio = escala or 6
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Shockwave_Explosion", posicao, vida or 0.9, raio, raio * 3.2,
			cor or COR.OSSO, cor or COR.SOMBRA) then
		return
	end
	nova(posicao, escala, cor, vida)
	onda(posicao, (escala or 6) / 8, cor, (vida or 0.9) + 0.4)
end

local function estouroFumegante(posicao, escala, cor)
	if pk("Smoky_Explosion", posicao, 1.4, (escala or 8), cor or COR.SOMBRA,
			Color3.fromRGB(100, 102, 115)) then
		return
	end
	estouro(posicao, (escala or 8) * 1.6, cor, 1.3)
end

local function corte(cframe, escala, cor, vida)
	if pk("Small_Slash", cframe, (escala or 6),
			vida or 0.45, cor or COR.OSSO, cor or COR.SOMBRA) then
		return
	end
	nova(cframe.Position, (escala or 6) * 0.5, cor, vida or 0.45)
end

local function anelSonar(cframe, escala, cor, vida)
	if pk("Sonar_Ring", cframe, vida or 1, (escala or 6), (escala or 6) * 4,
			0.6, 0.05, cor or COR.OSSO, cor or COR.SOMBRA) then
		return
	end
	onda(cframe.Position, (escala or 6) / 10, cor, vida)
end

local function rachadura(posicao, escala, cor, vida)
	if pk("Floor_Crack", CFrame.new(posicao), (escala or 8),
			vida or 3, cor or COR.SOMBRA) then
		return
	end
	onda(posicao, (escala or 8) / 10, cor, 1.4)
end

local function feixe(origem, destino, calibre, cor, vida)
	if pk("Laser_Shot", origem, destino, (calibre or 3), (calibre or 3) * 0.2,
			nil, cor or COR.OSSO, cor or COR.SOMBRA,
			Enum.PartType.Cylinder, vida or 2) then
		return
	end
	local delta = destino - origem
	local cilindro = Instance.new("Part")
	cilindro.Shape = Enum.PartType.Cylinder
	cilindro.Size = Vector3.new(delta.Magnitude, calibre or 3, calibre or 3)
	cilindro.CFrame = CFrame.new(origem, destino)
		* CFrame.new(0, 0, -delta.Magnitude / 2)
		* CFrame.Angles(0, math.rad(90), 0)
	cilindro.Material = Enum.Material.Neon
	cilindro.Color = cor or COR.OSSO
	cilindro.Anchored, cilindro.CanCollide = true, false
	guardarPeca(cilindro, (vida or 2) + 0.5)
	TweenService:Create(cilindro, TweenInfo.new(vida or 2), { Transparency = 1 }):Play()
end

local function espiral(posicao, escala, cor, voltas, raio, altura)
	if pk("Spiral_Effect", posicao, (escala or 1.4),
			cor or COR.ALMA, voltas or 26, raio or 8, altura or 14) then
		return
	end
	local i = 1
	while i <= (voltas or 26) do
		local indice = i
		task.delay(indice * 0.02, function()
			local ang = math.rad(137.507764 * indice)
			nova(posicao + Vector3.new(math.cos(ang) * (raio or 8),
				indice * ((altura or 14) / (voltas or 26)),
				math.sin(ang) * (raio or 8)), (escala or 1.4) * 1.5, cor, 0.5)
		end)
		i = i + 1
	end
end

--══════════════════════════════════════════════════════════════
-- PRÓPRIO — selo, corrente e revelação
--══════════════════════════════════════════════════════════════

--- O contador do Julgamento. 20 selos em anel sobre a cabeça, um por segundo.
--- Não é `BillboardGui`: é geometria, e vive no mundo 3D.
local selos, ancoraSelo = {}, nil

local function tirarSelos()
	for _, selo in ipairs(selos) do
		if selo and selo.Parent then selo.Parent = nil end
	end
	selos = {}
	if ancoraSelo then
		ancoraSelo:Disconnect()
		ancoraSelo = nil
	end
end

local function porSelos(corpo, quantos, altura, raio)
	tirarSelos()
	local cabeca = corpo and (corpo:FindFirstChild("Head")
		or corpo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return end

	local i = 1
	while i <= quantos do
		local selo = Instance.new("Part")
		selo.Shape = Enum.PartType.Block
		selo.Size = Vector3.new(0.28, 0.5, 0.12)
		selo.Material = Enum.Material.Neon
		selo.Color = COR.SENTENCA
		selo.Anchored, selo.CanCollide = true, false
		guardarPeca(selo, quantos + 4)
		table.insert(selos, selo)
		i = i + 1
	end

	-- os selos seguem a cabeça a 60 Hz NO CLIENTE. Fazer isso no servidor
	-- seria mover geometria por quadro, que replica picotado.
	local giro = 0
	ancoraSelo = RunService.Heartbeat:Connect(function(dt)
		if not cabeca.Parent then
			tirarSelos()
			return
		end
		giro = giro + dt * 0.9
		for indice, selo in ipairs(selos) do
			if selo.Parent then
				local ang = giro + math.rad(360 / quantos * indice)
				selo.CFrame = CFrame.new(cabeca.Position
					+ Vector3.new(math.cos(ang) * raio, altura, math.sin(ang) * raio))
					* CFrame.Angles(0, -ang, 0)
			end
		end
	end)
end

--- Corrente do Portal: elos entre o preso e a âncora. O elo é a malha de anel
--- do molde; sem ele, um cilindro fino serve de corda.
local function corrente(moldes, corpo, ancora, quantos)
	local raizAlvo = corpo and (corpo:FindFirstChild("HumanoidRootPart")
		or corpo:FindFirstChild("Torso"))
	if not raizAlvo then return end
	local base = moldes and moldes:FindFirstChild("Elo", true)

	local i = 1
	while i <= (quantos or 8) do
		local fracao = i / (quantos or 8)
		local ponto = ancora:Lerp(raizAlvo.Position, fracao)
		local elo
		if base then
			elo = base:Clone()
			elo.Transparency = 0
		else
			elo = Instance.new("Part")
			elo.Size = Vector3.new(0.3, 0.3, 1.2)
			elo.Material = Enum.Material.Metal
			elo.Color = COR.SOMBRA
		end
		elo.Anchored, elo.CanCollide = true, false
		elo.CFrame = CFrame.new(ponto, raizAlvo.Position)
			* CFrame.Angles(0, 0, math.rad(90 * (i % 2)))
		guardarPeca(elo, 1.4)
		TweenService:Create(elo, TweenInfo.new(1.2,
			Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }):Play()
		i = i + 1
	end
end

--- Revelação do Olho. `Highlight` com `DepthMode = AlwaysOnTop` é a forma
--- honesta de ver através de parede: sem mexer em câmera, sem ScreenGui, e
--- visível só neste cliente, que é o do portador.
local realces = {}

local function limparRealces()
	for _, realce in pairs(realces) do
		if realce and realce.Parent then realce.Parent = nil end
	end
	realces = {}
end

local function revelar(alvos, duracao)
	local vistos = {}
	for _, corpo in ipairs(alvos or {}) do
		if typeof(corpo) == "Instance" and corpo:IsA("Model") then
			vistos[corpo] = true
			if not realces[corpo] then
				local realce = Instance.new("Highlight")
				realce.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				realce.FillColor = COR.SENTENCA
				realce.FillTransparency = 0.72
				realce.OutlineColor = COR.OSSO
				realce.Adornee = corpo
				realce.Parent = corpo
				realces[corpo] = realce
			end
			Debris:AddItem(realces[corpo], duracao or 1.5)
		end
	end
	for corpo, realce in pairs(realces) do
		if not vistos[corpo] then
			if realce and realce.Parent then realce.Parent = nil end
			realces[corpo] = nil
		end
	end
end

--══════════════════════════════════════════════════════════════
-- O CATÁLOGO
--══════════════════════════════════════════════════════════════

local VFX = {}

function VFX.PILAR_ERGUE(d)
	som("ERGUE", d.posicao)
	espiral(d.posicao, 2, COR.ALMA, 34, (d.grossura or 6) * 1.6,
		(d.altura or 40) * 0.8)
	rachadura(d.posicao, 14, COR.SOMBRA, (d.duracao or 8) + 1)
	anelSonar(CFrame.new(d.posicao), 12, COR.ALMA, 1.2)
end

function VFX.PILAR_GRITO(d)
	-- o grito sobe de altura a cada pulso, ate o fim
	som("GRITO", d.posicao, 0.9 + (d.passo or 1) * 0.02)
	onda(d.posicao, 1.4, COR.ALMA, 1.1)
	nova(d.posicao + Vector3.new(0, 6, 0), 5, COR.ALMA, 0.7)
end

function VFX.PILAR_CAI(d)
	som("CAI", d.posicao)
	estouroFumegante(d.posicao, 10, COR.SOMBRA)
	ondaLarga(d.posicao, 1.6, COR.ALMA, 2)
end

function VFX.SELO_POE(d)
	local cab = d.alvo and d.alvo:FindFirstChild("Head")
	som("SELA", cab and cab.Position or nil)
	porSelos(d.alvo, d.selos or 20, d.altura or 4, d.raio or 2.2)
	local cabeca = d.alvo and d.alvo:FindFirstChild("Head")
	if cabeca then anelSonar(cabeca.CFrame, 4, COR.SENTENCA, 0.9) end
end

function VFX.SELO_TIQUE(d)
	-- o tique fica mais agudo quanto menos selo resta
	local cab = d.alvo and d.alvo:FindFirstChild("Head")
	som("TIQUE", cab and cab.Position or nil, 1 + (20 - (d.restam or 0)) * 0.03)
	local restam = d.restam or 0
	-- apaga de trás para a frente: some o último selo aceso
	for indice = #selos, 1, -1 do
		if indice > restam and selos[indice] and selos[indice].Parent then
			local selo = selos[indice]
			table.remove(selos, indice)
			TweenService:Create(selo, TweenInfo.new(0.3),
				{ Transparency = 1, Size = selo.Size * 2 }):Play()
			Debris:AddItem(selo, 0.4)
			break
		end
	end
end

function VFX.SELO_EXECUTA(d)
	local cab = d.alvo and (d.alvo:FindFirstChild("Head")
		or d.alvo:FindFirstChild("HumanoidRootPart"))
	som("EXECUTA", cab and cab.Position or nil)
	tirarSelos()
	local cabeca = d.alvo and (d.alvo:FindFirstChild("Head")
		or d.alvo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return end
	feixe(cabeca.Position + Vector3.new(0, 60, 0), cabeca.Position, 5,
		COR.SENTENCA, 0.9)
	estouro(cabeca.Position, 9, COR.SENTENCA, 1)
	ondaLarga(cabeca.Position, 1.2, COR.SENTENCA, 1.8)
end

function VFX.SELO_TIRA()
	tirarSelos()
end

function VFX.CAVEIRA_NASCE(d)
	som("NASCE", d.posicao)
	espiral(d.posicao, 1.4, COR.ALMA, 22, 5, 8)
	nova(d.posicao, 6, COR.OSSO, 0.7)
end

function VFX.BOMBA_SAI(d)
	nova(d.origem, 3, COR.SOMBRA, 0.35)
end

function VFX.BOMBA_ESTOURA(d)
	estouro(d.posicao, 8, COR.SOMBRA, 0.9)
	rachadura(d.posicao, 6, COR.SOMBRA, 2)
end

function VFX.PERTURBA_DESFAZ(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	som("DESFAZ", raiz.Position)
	anelSonar(raiz.CFrame, 6, COR.ALMA, 0.9)
	espiral(raiz.Position, 1.2, COR.ALMA, 20, 4, 7)

	-- o eco: uma cópia esmaecida do corpo a cada meio segundo
	local restante = d.duracao or 6
	local passo = 0
	task.spawn(function()
		while passo < restante do
			for _, parte in ipairs(personagem:GetChildren()) do
				if parte:IsA("BasePart") then
					local eco = Instance.new("Part")
					eco.Size, eco.CFrame = parte.Size, parte.CFrame
					eco.Material = Enum.Material.Neon
					eco.Color = COR.ALMA
					eco.Transparency = 0.65
					eco.Anchored, eco.CanCollide = true, false
					guardarPeca(eco, 0.8)
					TweenService:Create(eco, TweenInfo.new(0.8),
						{ Transparency = 1 }):Play()
				end
			end
			task.wait(0.5)
			passo = passo + 0.5
		end
	end)
end

function VFX.PERTURBA_ABSORVE(d)
	if d.posicao then nova(d.posicao, 3, COR.ALMA, 0.35) end
end

function VFX.PERTURBA_VOLTA() end

function VFX.PERTURBA_DEVOLVE(d)
	som("DEVOLVE", d.posicao, 0.9 + (d.escala or 0.5) * 0.3)
	estouroFumegante(d.posicao, 10 * (0.5 + (d.escala or 0.5)), COR.ALMA)
	ondaLarga(d.posicao, 1.8, COR.ALMA, 2)
end

function VFX.PORTAL_ABRE(d)
	som("ABRE", d.posicao)
	anelSonar(CFrame.new(d.posicao), d.raio or 14, COR.SOMBRA, 1.4)
	espiral(d.posicao, 1.6, COR.ALMA, 30, (d.raio or 14) * 0.6, 10)
	rachadura(d.posicao, (d.raio or 14), COR.SOMBRA, (d.duracao or 10) + 1)
end

function VFX.CORRENTE_PRENDE(d, moldes)
	som("CORRENTE", d.ancora)
	corrente(moldes, d.alvo, d.ancora, d.elos)
end

function VFX.PORTAL_FECHA(d)
	som("FECHA", d.posicao)
	estouro(d.posicao, 8, COR.SOMBRA, 0.9)
end

function VFX.OLHO_ABRE(d)
	som("ABRE", d.posicao)
	anelSonar(CFrame.new(d.posicao), (d.tamanho or 12), COR.OSSO, 1.2)
	nova(d.posicao, (d.tamanho or 12) * 0.6, COR.OSSO, 0.8)

	-- a pupila: uma esfera escura dentro do olho, girando devagar
	local pupila = Instance.new("Part")
	pupila.Shape = Enum.PartType.Ball
	pupila.Size = Vector3.new(1, 1, 1) * ((d.tamanho or 12) * 0.42)
	pupila.Material = Enum.Material.Neon
	pupila.Color = COR.SOMBRA
	pupila.Anchored, pupila.CanCollide = true, false
	guardarPeca(pupila, (d.duracao or 14) + 1)

	local giro, conexao = 0, nil
	conexao = RunService.Heartbeat:Connect(function(dt)
		if not pupila.Parent then
			conexao:Disconnect()
			return
		end
		giro = giro + dt * 0.7
		pupila.CFrame = CFrame.new(d.posicao)
			* CFrame.Angles(0, giro, 0)
			* CFrame.new(0, 0, -(d.tamanho or 12) * 0.3)
	end)
	task.delay(d.duracao or 14, function() conexao:Disconnect() end)
end

function VFX.OLHO_VARRE(d)
	som("VARRE", d.posicao, 1 + (d.passo or 1) * 0.01)
	anelSonar(CFrame.new(d.posicao), 8, COR.OSSO, 0.8)
end

function VFX.OLHO_FECHA(d)
	som("FECHA", d.posicao)
	nova(d.posicao, 8, COR.OSSO, 0.6)
	limparRealces()
end

function VFX.REVELAR(d)
	revelar(d.alvos, d.duracao)
end

--══════════════════════════════════════════════════════════════

function M.desenhar(tipo, dados, moldes, personagem)
	local fn = VFX[tipo]
	if not fn then return end
	local ok, erro = pcall(fn, dados, moldes, personagem)
	if not ok then
		warn("[Collector VFX] " .. tostring(tipo) .. ": " .. tostring(erro))
	end
end

function M.beat(marca, personagem)
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not braco then return end
	if marca == "CARGA" then
		nova(braco.Position, 2, COR.ALMA, 0.3)
	elseif marca == "GOLPE" then
		nova(braco.Position, 4, COR.ALMA, 0.35)
	end
end

function M.limpar()
	tirarSelos()
	limparRealces()
	for _, peca in ipairs(vivos) do
		if peca and peca.Parent then peca.Parent = nil end
	end
	vivos = {}
end

return M
