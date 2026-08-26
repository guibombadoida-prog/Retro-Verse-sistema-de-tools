-- VFXModule.lua
-- ModuleScript "VFXModule" — Cosmic Sword Revamp
--
-- TODO EFEITO DESTA TOOL DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- POR QUE ESTE ARQUIVO EXISTE
--═══════════════════════════════════════════════════════════════
--
--   Os quatro efeitos `HAWKING_*` e o `PARAR` já estavam escritos — mas
--   moravam dentro de um `LocalScript`. `LocalScript` dentro de Tool só roda
--   para quem SEGURA a Tool: todo mundo mais via o portador girando o braço
--   no vazio. Era o mesmo bug que já custou o conjunto do escudo.
--
--   Aqui eles são módulo, e quem escuta é um `Script` com
--   `RunContext = Client`, que roda em TODO cliente.
--
--   Os cinco efeitos das habilidades originais (`CORTE`, `SUPERNOVA`,
--   `SHURIKEN_VOO`, `SHURIKEN_ESTOURO`, `DOBRA`) eram feitos de outro jeito:
--   o servidor clonava a peça de `ServerStorage` e pendurava nela um `Script`
--   de tween que rodava NO SERVIDOR. Geometria movida pelo servidor replica a
--   ~20 Hz sem interpolação — era a queixa de "os VFX não estão fluidos".
--   Os mesmos tweens estão aqui, com os mesmos números, a 60 Hz.
--
--═══════════════════════════════════════════════════════════════
-- O REQUIRE QUE SAIU
--═══════════════════════════════════════════════════════════════
--
--   O `Server` da origem abria com `require(125275839196878)` — asset remoto
--   buscado por id e executado NO SERVIDOR — e usava o resultado só para três
--   chamadas de `Slash_Trail` no M1. Quem controlasse aquele asset controlava
--   o servidor de quem equipasse a Tool. O rastro é `Efeitos.CORTE`, logo
--   abaixo, e o require não existe mais em lugar nenhum da Tool.
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `math.random` — ângulo áureo, para que todos os clientes desenhem a
--   MESMA cena (sorteio por cliente lê como lag). Zero `:Destroy()` —
--   `Parent = nil` e `Debris`. Zero `tick()` — acumulador de `dt` a partir de
--   zero. `workspace.CurrentCamera` é lido só para o tremor, e o valor de
--   antes é sempre devolvido.

local Players      = game:GetService("Players")
local Debris       = game:GetService("Debris")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tool = script.Parent
local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	ESPERA_CURTA = 2,     -- timeout de toda busca opcional
	ANGULO_AUREO = math.rad(137.507764),

	COR_EVENTO   = Color3.fromRGB(12, 0, 24),     -- o corpo do buraco negro
	COR_BORDA    = Color3.fromRGB(150, 90, 255),  -- a radiação na borda
	COR_NUCLEO   = Color3.fromRGB(255, 240, 255),
	COR_COSMICA  = Color3.fromRGB(255, 255, 255), -- o branco da origem

	TREMOR_FORCA = 0.55,
	TREMOR_TEMPO = 0.9,
	LIMITE_VIVOS = 220,
}

--═══════════════════════════════════════════════════════════════
-- OS MOLDES — AS DUAS PORTAS (Regra nº 2)
--
-- Primeiro o depósito em `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`, para
-- onde o Server manda a pasta `CosmicVFX2` assim que a Tool chega ao jogador.
-- Depois o interior da Tool, que é o que mantém verdadeiro o teste do place
-- vazio: enquanto ninguém equipou, não há depósito nenhum e o molde ainda
-- está aqui dentro.
--
-- A busca é PREGUIÇOSA e o resultado só é guardado enquanto tiver pai. O
-- código antigo resolvia os oito moldes na carga do script, o que dava nil
-- quando a replicação chegava atrasada — e nil na carga é efeito que nunca
-- mais desenha, porque ninguém procura de novo.
--═══════════════════════════════════════════════════════════════

local cacheMolde = {}

local function molde(nome)
	local guardado = cacheMolde[nome]
	if guardado and guardado.Parent then return guardado end

	local achado = Deposito.achar(script, nome)         -- porta 1
	if not achado then
		achado = Tool:FindFirstChild(nome, true)        -- porta 2
	end
	if not achado then
		local pack = Deposito.achar(script, "CosmicVFX2")
			or Tool:FindFirstChild("CosmicVFX2")
		achado = pack and pack:FindFirstChild(nome, true) or nil
	end

	cacheMolde[nome] = achado
	return achado
end

--═══════════════════════════════════════════════════════════════
-- INFRAESTRUTURA
--═══════════════════════════════════════════════════════════════

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

local function registrar(inst, vida)
	table.insert(Vivos, inst)
	if #Vivos > CFG.LIMITE_VIVOS then
		local velho = table.remove(Vivos, 1)
		if velho and velho.Parent then velho.Parent = nil end
	end
	if vida then Debris:AddItem(inst, vida) end
	return inst
end

local function anotar(id, inst, conexao)
	if not id then return inst end
	PorId[id] = PorId[id] or { partes = {}, conexoes = {} }
	if inst then table.insert(PorId[id].partes, inst) end
	if conexao then table.insert(PorId[id].conexoes, conexao) end
	return inst
end

local function novaParte(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Massless, p.CastShadow = true, false
	p.Material = Enum.Material.Neon
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(tempo,
		style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), alvo)
	t:Play()
	return t
end

--- Escala um Model inteiro em volta do pivô. `ScaleTo` existe no Roblox
--- moderno; se não existir, cai no redimensionamento peça a peça.
local function escalarModelo(modelo, fator)
	local ok = pcall(function() modelo:ScaleTo(fator) end)
	if ok then return end
	local pivo = modelo:GetPivot()
	for _, parte in ipairs(modelo:GetDescendants()) do
		if parte:IsA("BasePart") then
			parte.Size = parte.Size * fator
			local desvio = parte.Position - pivo.Position
			parte.CFrame = CFrame.new(pivo.Position + desvio * fator)
				* (parte.CFrame - parte.Position)
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA — Jupiter primeiro, próprio como reserva
--
-- workspace.CurrentCamera é singleton por cliente, e isto é LocalScript:
-- é acesso de serviço, não depósito de asset. O valor original é guardado e
-- devolvido — câmera presa é bug sem saída para o jogador.
--═══════════════════════════════════════════════════════════════

local tremorAtivo = nil

local function tremorProprio(forca, duracao)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
	local camera = workspace.CurrentCamera
	if not camera then return end

	local passado = 0
	tremorAtivo = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not workspace.CurrentCamera then
			if tremorAtivo then
				tremorAtivo:Disconnect()
				tremorAtivo = nil
			end
			return
		end
		local restante = 1 - (passado / duracao)
		local a = forca * restante
		-- ruído senoidal por acumulador de dt, nunca tick()
		local x = math.sin(passado * 61.3) * a
		local y = math.sin(passado * 47.7 + 1.3) * a
		local z = math.sin(passado * 53.1 + 2.6) * a * 0.4
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(
			math.rad(x), math.rad(y), math.rad(z))
	end)
end

--═══════════════════════════════════════════════════════════════
-- MONTAR A SHURIKEN BURACO NEGRO
--═══════════════════════════════════════════════════════════════

--- Pinta o clone com a cara de horizonte de eventos: corpo preto Neon,
--- borda roxa incandescente. Os Trails do modelo continuam ali.
local function pintarBuracoNegro(modelo)
	for _, peca in ipairs(modelo:GetDescendants()) do
		if peca:IsA("BasePart") then
			peca.Anchored = true
			peca.CanCollide = false
			peca.CanTouch = false
			peca.CanQuery = false
			peca.CastShadow = false
			if peca.Name == "Outline" then
				peca.Color = CFG.COR_BORDA
				peca.Material = Enum.Material.Neon
				peca.Transparency = 0.15
			else
				peca.Color = CFG.COR_EVENTO
				peca.Material = Enum.Material.Neon
			end
		elseif peca:IsA("Trail") then
			peca.Color = ColorSequence.new(CFG.COR_BORDA, CFG.COR_EVENTO)
			peca.LightEmission = 1
			peca.Lifetime = 0.5
		end
	end
end

--- O núcleo escuro: uma esfera preta que engole a luz no meio da shuriken.
local function nucleoEscuro(centro, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio),
		Color = Color3.new(0, 0, 0),
		Material = Enum.Material.Glass,
		Transparency = 0.02,
		Reflectance = 0.15,
		CFrame = CFrame.new(centro),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = CFG.COR_BORDA, 6, raio * 3
	luz.Parent = bola
	return bola
end

--- O anel de acreção: disco fino girando em volta do horizonte.
local function anelAcrescao(centro, raio)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, raio * 2.2, raio * 2.2),
		Color = CFG.COR_BORDA,
		Transparency = 0.45,
		CFrame = CFrame.new(centro) * CFrame.Angles(0, 0, math.rad(90)),
	})
	return anel
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

--- FASE 1: a shuriken gigante viva, girando sobre o próprio eixo.
function Efeitos.HAWKING_SHURIKEN(d)
	local centro = d.posicao or Vector3.new()
	local escala = d.escala or 10
	local giro   = d.giro or 20
	local id     = d.id

	tremorProprio(CFG.TREMOR_FORCA * 0.5, 0.45)

	local corpo = nil
	if molde("ShurikenModel") and molde("ShurikenModel"):IsA("Model") then
		corpo = molde("ShurikenModel"):Clone()
		corpo.Name = "HawkingShuriken"
		corpo.Parent = workspace
		pcall(function() corpo:PivotTo(CFrame.new(centro)) end)
		escalarModelo(corpo, escala)
		pintarBuracoNegro(corpo)
		registrar(corpo, (d.duracao or 4) + 1)
		anotar(id, corpo)
	end

	-- raio aparente do horizonte, para o núcleo e o anel acompanharem a escala
	local raio = 2.2 * escala

	local nucleo = nucleoEscuro(centro, raio * 0.55)
	registrar(nucleo, (d.duracao or 4) + 1)
	anotar(id, nucleo)

	local anel = anelAcrescao(centro, raio)
	registrar(anel, (d.duracao or 4) + 1)
	anotar(id, anel)

	-- radiação escapando da borda: pontos em ângulo áureo, subindo
	local marca = novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(centro),
	})
	local att = Instance.new("Attachment")
	att.Parent = marca
	local radiacao = Instance.new("ParticleEmitter")
	radiacao.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	radiacao.Color = ColorSequence.new(CFG.COR_NUCLEO, CFG.COR_BORDA)
	radiacao.LightEmission = 1
	radiacao.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, raio * 0.16),
		NumberSequenceKeypoint.new(1, 0),
	})
	radiacao.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	radiacao.Lifetime = NumberRange.new(0.5, 1.1)
	radiacao.Speed = NumberRange.new(raio * 0.8, raio * 1.6)
	radiacao.SpreadAngle = Vector2.new(180, 180)
	radiacao.Rate = 90
	radiacao.Parent = att
	registrar(marca, (d.duracao or 4) + 1.5)
	anotar(id, marca)

	-- GIRO a 60 Hz, por acumulador de dt a partir de zero
	local passado = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= (d.duracao or 4) then
			conexao:Disconnect()
			return
		end
		local angulo = passado * giro
		if corpo and corpo.Parent then
			pcall(function()
				corpo:PivotTo(CFrame.new(centro)
					* CFrame.Angles(0, 0, angulo)
					* CFrame.Angles(0, math.sin(passado * 0.7) * 0.25, 0))
			end)
		end
		if anel and anel.Parent then
			anel.CFrame = CFrame.new(centro)
				* CFrame.Angles(0, angulo * 0.35, 0)
				* CFrame.Angles(0, 0, math.rad(90))
		end
		if nucleo and nucleo.Parent then
			local pulso = 1 + math.sin(passado * 8) * 0.06
			nucleo.Size = Vector3.new(raio * 0.55, raio * 0.55, raio * 0.55) * pulso
		end
	end)
	anotar(id, nil, conexao)

	-- as linhas de sucção: risquinhos correndo de fora para dentro
	local puxando = 0
	local sugador
	sugador = RunService.Heartbeat:Connect(function(dt)
		puxando = puxando + dt
		if puxando >= (d.duracao or 4) then
			sugador:Disconnect()
			return
		end
		local i = proximo()
		local ang = i * CFG.ANGULO_AUREO
		local alcance = (d.raio or 60)
		local de = centro + Vector3.new(
			math.cos(ang) * alcance * 0.8,
			math.sin(ang * 0.5) * alcance * 0.35,
			math.sin(ang) * alcance * 0.8)
		local risco = novaParte({
			Size = Vector3.new(0.4, 0.4, 6),
			Color = CFG.COR_BORDA,
			Transparency = 0.25,
			CFrame = CFrame.new(de, centro),
		})
		tween(risco, 0.45, {
			CFrame = CFrame.new(centro, centro + (centro - de)),
			Size = Vector3.new(0.05, 0.05, 1),
			Transparency = 1,
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		registrar(risco, 0.7)
	end)
	anotar(id, nil, sugador)
end

--- FASE 2: a explosão colossal.
function Efeitos.HAWKING_COLOSSAL(d)
	local centro = d.posicao or Vector3.new()
	local escala = d.escala or 4

	tremorProprio(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)

	if molde("Impact_Sound") and molde("Impact_Sound"):IsA("Sound") then
		local som = molde("Impact_Sound"):Clone()
		som.Parent = workspace
		som:Play()
		Debris:AddItem(som, 6)
	end

	-- clarão branco de um frame: "aconteceu agora"
	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8) * escala,
		Color = CFG.COR_NUCLEO,
		Transparency = 0.02,
		CFrame = CFrame.new(centro),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = CFG.COR_BORDA, 40, 90 * escala
	luz.Parent = clarao
	tween(clarao, 0.09, { Size = Vector3.new(15, 15, 15) * escala,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(clarao, 0.4)

	-- a esfera real do modelo, se existir
	if molde("Explosion_Sphere") and molde("Explosion_Sphere"):IsA("BasePart") then
		local esfera = molde("Explosion_Sphere"):Clone()
		esfera.Anchored = true
		esfera.CanCollide, esfera.CanTouch, esfera.CanQuery = false, false, false
		esfera.CFrame = CFrame.new(centro)
		esfera.Size = Vector3.new(6, 6, 6) * escala
		esfera.Parent = workspace
		tween(esfera, 0.55, { Size = Vector3.new(34, 34, 34) * escala,
			Transparency = 1 }, Enum.EasingStyle.Quint)
		registrar(esfera, 1.2)
	end

	if molde("Explosion_Wind") and molde("Explosion_Wind"):IsA("BasePart") then
		local vento = molde("Explosion_Wind"):Clone()
		vento.Anchored = true
		vento.CanCollide, vento.CanTouch, vento.CanQuery = false, false, false
		vento.CFrame = CFrame.new(centro)
		vento.Size = Vector3.new(10, 3, 10) * escala
		vento.Parent = workspace
		tween(vento, 0.75, { Size = Vector3.new(70, 4, 70) * escala,
			Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(vento, 1.4)
	end

	-- anéis do modelo, em tempos diferentes: escala, e não borrão
	local aneis = { molde("Nova_Circle"), molde("MegaWave") }
	local i = 0
	while i < #aneis do
		local molde = aneis[i + 1]
		local atraso = i * 0.14
		if molde and molde:IsA("BasePart") then
			local indice = i
            task.delay(atraso, function()
				local anel = molde:Clone()
				anel.Anchored = true
				anel.CanCollide, anel.CanTouch, anel.CanQuery = false, false, false
				anel.CFrame = CFrame.new(centro) * CFrame.Angles(math.rad(90), 0, 0)
				anel.Size = Vector3.new(8, 8, 1) * escala
				anel.Parent = workspace
				tween(anel, 0.6 + indice * 0.2, {
					Size = Vector3.new(90, 90, 1) * escala,
					Transparency = 1,
				}, Enum.EasingStyle.Quint)
				registrar(anel, 1.6)
			end)
		end
		i = i + 1
	end

	-- detrito: a única camada que persiste
	local marca = novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(centro),
	})
	local att = Instance.new("Attachment")
	att.Parent = marca
	local cacos = Instance.new("ParticleEmitter")
	cacos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	cacos.Color = ColorSequence.new(CFG.COR_NUCLEO, CFG.COR_BORDA)
	cacos.LightEmission = 1
	cacos.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6 * escala),
		NumberSequenceKeypoint.new(1, 0),
	})
	cacos.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	cacos.Lifetime = NumberRange.new(0.6, 1.3)
	cacos.Speed = NumberRange.new(60 * escala, 130 * escala)
	cacos.SpreadAngle = Vector2.new(180, 180)
	cacos.Acceleration = Vector3.new(0, -80, 0)
	cacos.Rate, cacos.Enabled = 0, false
	cacos.Parent = att
	cacos:Emit(120)
	registrar(marca, 2.2)
end

--- As 5 mini shurikens: cada uma segue o corpo físico que o servidor criou.
function Efeitos.HAWKING_MINI(d)
	local alvo = d.alvoParte
	local escala = d.escala or 3
	local id = d.id
	if not alvo or not alvo:IsA("BasePart") then return end

	local corpo = nil
	if molde("ShurikenModel") and molde("ShurikenModel"):IsA("Model") then
		corpo = molde("ShurikenModel"):Clone()
		corpo.Name = "HawkingMiniShuriken"
		corpo.Parent = workspace
		pcall(function() corpo:PivotTo(alvo.CFrame) end)
		escalarModelo(corpo, escala)
		pintarBuracoNegro(corpo)
		registrar(corpo, (d.duracao or 6) + 1)
		anotar(id, corpo)
	end

	if molde("Launch_Trail") and molde("Launch_Trail"):IsA("Trail") then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1.2 * escala, 0)
		a0.Parent = alvo
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.2 * escala, 0)
		a1.Parent = alvo
		local rastro = molde("Launch_Trail"):Clone()
		rastro.Attachment0, rastro.Attachment1 = a0, a1
		rastro.Enabled = true
		rastro.Parent = alvo
		anotar(id, rastro)
	end

	local passado = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		if not alvo.Parent or not corpo or not corpo.Parent then
			conexao:Disconnect()
			return
		end
		passado = passado + dt
		pcall(function()
			corpo:PivotTo(CFrame.new(alvo.Position) * CFrame.Angles(0, 0, passado * 34))
		end)
	end)
	anotar(id, nil, conexao)
end

function Efeitos.HAWKING_MINI_EXPLODE(d)
	local centro = d.posicao or Vector3.new()
	local escala = d.escala or 1.4

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3) * escala,
		Color = CFG.COR_NUCLEO,
		Transparency = 0.05,
		CFrame = CFrame.new(centro),
	})
	tween(clarao, 0.1, { Size = Vector3.new(7, 7, 7) * escala,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(clarao, 0.35)

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2) * escala,
		Color = CFG.COR_BORDA,
		Transparency = 0.15,
		CFrame = CFrame.new(centro),
	})
	tween(bola, 0.32, { Size = Vector3.new(16, 16, 16) * escala,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.6)

	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 3 * escala, 3 * escala),
		Color = CFG.COR_BORDA,
		Transparency = 0.3,
		CFrame = CFrame.new(centro) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, 0.45, { Size = Vector3.new(0.05, 26 * escala, 26 * escala),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, 0.7)

	tremorProprio(CFG.TREMOR_FORCA * 0.22, 0.3)
end

--═══════════════════════════════════════════════════════════════
-- API DE LIMPEZA
--═══════════════════════════════════════════════════════════════

local function parar(id)
	local reg = PorId[id]
	if not reg then return end
	for _, conn in ipairs(reg.conexoes) do
		if conn then conn:Disconnect() end
	end
	for _, inst in ipairs(reg.partes) do
		if inst and inst.Parent then
			if inst:IsA("ParticleEmitter") or inst:IsA("Trail") then
				inst.Enabled = false
			end
			inst.Parent = nil
		end
	end
	PorId[id] = nil
end

local function limparTudo()
	for id in pairs(PorId) do parar(id) end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then inst.Parent = nil end
	end
	table.clear(Vivos)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS DAS QUATRO HABILIDADES ORIGINAIS
--
-- Os NÚMEROS destes tweens não foram inventados: são os mesmos dos oito
-- `Script` de tween que a origem pendurava no clone e rodava no servidor —
-- `tween1` (Size 130,5,130 em 1.6 s Quart/Out; fade 0.8 s Sine/In), `Tween2`
-- (Size 150,10,150, giro de 200° em 3 s), `Tween3`, `tween4` (0.4 s / 0.2 s) e
-- `tweenring` (Scale 7,3,7). O que mudou foi ONDE eles rodam.
--═══════════════════════════════════════════════════════════════

--- Prepara um clone de molde para viver solto no mundo: nada colide, nada
--- consulta, nada projeta sombra. Sem isto um `Explosion_Sphere` de 150 studs
--- empurra todo mundo que estiver perto.
local function soltar(clone, posicao)
	for _, peca in ipairs(clone:GetDescendants()) do
		if peca:IsA("BasePart") then
			peca.Anchored = true
			peca.CanCollide = false
			peca.CanTouch = false
			peca.CanQuery = false
			peca.CastShadow = false
			peca.Massless = true
		end
	end
	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanTouch = false
		clone.CanQuery = false
		clone.CastShadow = false
		clone.Position = posicao
	elseif clone:IsA("Model") then
		clone:PivotTo(CFrame.new(posicao))
	end
	clone.Parent = workspace
	return clone
end

--- Dispara os emissores de um `Attachment` chamado `Center`, como a origem
--- fazia — mas SEM o `wait()` entre um e outro, que no servidor custava um
--- quadro por emissor.
local function emitirCentro(clone, quantidade)
	local centro = clone:FindFirstChild("Center", true)
	if not centro then return end
	for _, peca in ipairs(centro:GetDescendants()) do
		if peca:IsA("ParticleEmitter") then
			peca:Emit(quantidade or 30)
		end
	end
end

--- Um molde clonado, solto no mundo, com prazo. Devolve nil sem reclamar se o
--- molde não existir — num place vazio a Tool continua funcionando.
local function clonarMolde(nome, posicao, vida)
	local base = molde(nome)
	if not base then return nil end
	local clone = base:Clone()
	soltar(clone, posicao)
	registrar(clone, vida or 7)
	return clone
end

--- O E: Nova_Circle sobe e abre, Nova_Wave abre girando.
function Efeitos.SUPERNOVA(d)
	local centro = d.posicao or Vector3.new()
	local cor = d.cor or CFG.COR_COSMICA

	local circulo = clonarMolde("Nova_Circle", centro + Vector3.new(0, 3, 0), 7)
	if circulo then
		if circulo:IsA("BasePart") then circulo.Color = cor end
		tween(circulo, 1.6, { Size = Vector3.new(130, 5, 130) },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(circulo, 0.8, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		emitirCentro(circulo, 30)
	end

	local onda = clonarMolde("Nova_Wave", centro, 7)
	if onda then
		if onda:IsA("BasePart") then onda.Color = cor end
		tween(onda, 1.6, { Size = Vector3.new(150, 10, 150) },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(onda, 3, { Orientation = Vector3.new(0, 200, 0) },
			Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(onda, 0.8, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	tremorProprio(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
end

--- O M1: o rastro do corte.
---
--- Isto é o que substitui `require(125275839196878)`. A origem pedia ao módulo
--- remoto um `Slash_Trail` com raio 19, espessura 1.3, branco, 0.25 s de vida
--- e um ângulo de rotação. Os mesmos números estão aqui, e o arco é montado
--- com peças próprias.
function Efeitos.CORTE(d)
	local origem = d.posicao or Vector3.new()
	local direcao = d.direcao or Vector3.new(0, 0, -1)
	local giro = d.giro or 0
	local raio = d.raio or 6
	local cor = d.cor or CFG.COR_COSMICA
	local vida = d.vida or 0.25

	if direcao.Magnitude < 0.01 then direcao = Vector3.new(0, 0, -1) end
	local base = CFrame.lookAt(origem, origem + direcao.Unit)
		* CFrame.Angles(0, 0, giro)

	-- Onze lascas ao longo de um arco de 150°. Uma peça só não lê como corte:
	-- o que lê é a sequência delas apagando de uma ponta à outra.
	local LASCAS = 11
	for i = 0, LASCAS - 1 do
		local fracao = i / (LASCAS - 1)
		local angulo = math.rad(-75 + 150 * fracao)
		local ponto = base * CFrame.Angles(angulo, 0, 0)
			* CFrame.new(0, 0, -raio)
		local lasca = novaParte({
			Size = Vector3.new(0.28, 1.3, 2.6),
			Color = cor,
			Transparency = 0.1,
			CFrame = ponto * CFrame.Angles(0, 0, math.rad(90)),
		})
		registrar(lasca, vida + 0.2)
		tween(lasca, vida, {
			Transparency = 1,
			Size = Vector3.new(0.05, 0.3, 3.4),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Color = cor,
		Transparency = 0.35,
		CFrame = CFrame.new(origem + direcao.Unit * (raio * 0.5)),
	})
	registrar(clarao, 0.3)
	tween(clarao, 0.18, { Transparency = 1, Size = Vector3.new(4.2, 4.2, 4.2) })
end

--- O Q, fase 1: a shuriken do espaço voando até o ponto.
---
--- O voo é do CLIENTE, a 60 Hz. O servidor calcula a mesma reta por aritmética
--- para saber onde bate — ele não move peça nenhuma por quadro.
function Efeitos.SHURIKEN_VOO(d)
	local base = molde("ShurikenModel")
	if not base then return end

	local origem = d.posicao or Vector3.new()
	local destino = d.destino or (origem + Vector3.new(0, 0, -60))
	local escala = d.escala or 3
	local duracao = math.max(d.duracao or 0.9, 0.05)
	local giro = d.giro or 26

	local clone = base:Clone()
	soltar(clone, origem)
	if escala ~= 1 then escalarModelo(clone, escala) end
	registrar(clone, duracao + 1)
	anotar(d.id, clone)

	-- O `Summon` viaja DENTRO do ShurikenModel, pendurado no `Outline`. Ele
	-- veio com o modelo e estava mudo desde sempre: ninguém o tocava. Como o
	-- clone é do cliente e cada cliente faz o seu, o som sai da posição certa
	-- para todo mundo, sem âncora nenhuma.
	local nascer = clone:FindFirstChild("Summon", true)
	if nascer and nascer:IsA("Sound") then
		nascer:Play()
	end

	local delta = destino - origem
	local passado = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		local fracao = math.min(passado / duracao, 1)
		local onde = origem + delta * fracao
		local ok = pcall(function()
			clone:PivotTo(CFrame.new(onde)
				* CFrame.Angles(0, 0, passado * giro))
		end)
		if fracao >= 1 or not ok or not clone.Parent then
			conexao:Disconnect()
		end
	end)
	anotar(d.id, nil, conexao)
end

--- O Q, fase 2: o estouro. Core, MainCore, WindWave e MegaWave — os mesmos
--- quatro moldes que a origem usava, com os números do `Tween3`/`tween4`.
function Efeitos.SHURIKEN_ESTOURO(d)
	local centro = d.posicao or Vector3.new()
	local escala = d.escala or 1
	local cor = d.cor or CFG.COR_COSMICA

	local nucleo = clonarMolde("Core", centro, 5)
	if nucleo then
		if nucleo:IsA("BasePart") then nucleo.Color = cor end
		tween(nucleo, 0.4, { Size = Vector3.new(18, 18, 18) * escala },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(nucleo, 0.2, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		emitirCentro(nucleo, 30)
	end

	local miolo = clonarMolde("MainCore", centro, 5)
	if miolo then
		tween(miolo, 0.4, { Size = Vector3.new(10, 10, 10) * escala },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(miolo, 0.2, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	local vento = clonarMolde("WindWave", centro, 6)
	if vento then
		tween(vento, 1.6, { Size = Vector3.new(70, 22, 70) * escala },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(vento, 1.6, { Orientation = Vector3.new(0, 200, 0) },
			Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween(vento, 1.6, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	local mega = clonarMolde("MegaWave", centro, 6)
	if mega then
		tween(mega, 1.6, { Size = Vector3.new(96, 14, 96) * escala },
			Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tween(mega, 1.6, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	tremorProprio(CFG.TREMOR_FORCA * 0.7, CFG.TREMOR_TEMPO * 0.7)
end

--- O X: a dobra. Explosion_Sphere e Explosion_Wind nas DUAS pontas, e um
--- caminho de estrelas entre elas.
---
--- O rastro da origem nascia de um laço no servidor que criava uma peça por
--- salto e escrevia `hrp.CFrame` no meio. Aqui as estrelas são todas do
--- cliente e o servidor só manda as duas pontas.
function Efeitos.DOBRA(d)
	local saida = d.posicao or Vector3.new()
	local chegada = d.destino or saida
	local cor = d.cor or CFG.COR_BORDA

	for _, ponta in ipairs({ saida, chegada }) do
		local esfera = clonarMolde("Explosion_Sphere", ponta, 3)
		if esfera then
			tween(esfera, 0.4, { Size = Vector3.new(14, 14, 14) },
				Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tween(esfera, 0.2, { Transparency = 1 },
				Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			emitirCentro(esfera, 20)
		end
		local vento = clonarMolde("Explosion_Wind", ponta, 3)
		if vento then
			tween(vento, 0.4, { Size = Vector3.new(22, 8, 22) },
				Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			tween(vento, 0.2, { Transparency = 1 },
				Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		end
	end

	-- O caminho: uma estrela a cada trecho, apagando de trás para a frente.
	local delta = chegada - saida
	local distancia = delta.Magnitude
	if distancia < 1 then return end

	local ESTRELAS = math.clamp(math.floor(distancia / 8), 2, 14)
	for i = 0, ESTRELAS do
		local fracao = i / ESTRELAS
		local ponto = saida + delta * fracao
		local estrela = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.1, 1.1, 1.1),
			Color = cor,
			Transparency = 0.2,
			CFrame = CFrame.new(ponto),
		})
		registrar(estrela, 0.9)
		tween(estrela, 0.28 + fracao * 0.3, {
			Transparency = 1,
			Size = Vector3.new(0.15, 0.15, 0.15),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

--═══════════════════════════════════════════════════════════════
-- A API DO MÓDULO
--
-- Três funções, as mesmas de todo VFXModule do repositório. O `Client` não
-- conhece nem `Efeitos` nem `PorId` — ele manda o nome e os dados.
--═══════════════════════════════════════════════════════════════

local M = {}

function M.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[CosmicSword] falha em " .. tostring(tipo) .. ": " .. tostring(err))
	end
	return ok
end

function M.Parar(id)
	if id then parar(id) end
end

function M.LimparTudo()
	limparTudo()
end

return M
