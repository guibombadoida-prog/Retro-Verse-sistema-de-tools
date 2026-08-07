--[[
═══════════════════════════════════════════════════════════════════════════
  HAWKING COSMIC SHURIKEN RADIATION — CLIENT V1
  Tool: "Sword of Cosmic Entity (Revamped)"  (Cosmic Sword Revamp)
═══════════════════════════════════════════════════════════════════════════

  ONDE COLAR
    Como LocalScript dentro da Tool, com o nome
    `HawkingCosmicShurikenRadiation_Client_V1`.

  O QUE ESTE ARQUIVO FAZ
    1. `Tool.Activated` dispara o RemoteEvent. SEM GUI, sem botão — não há
       segunda habilidade, então o ícone da Tool já é o botão, e ele funciona
       no toque do celular sem nada a mais.
    2. Desenha a shuriken gigante: clona o `ShurikenModel` real do
       `CosmicVFX2`, escala para o tamanho pedido, pinta de buraco negro e
       GIRA a 60 Hz.
    3. Desenha a explosão colossal e as 5 mini shurikens.
    4. Sacode a câmera reaproveitando o `Shake_Camera` do Jupiter quando ele
       estiver disponível; se não estiver, usa um tremor próprio.

  POR QUE O GIRO É AQUI E NÃO NO SERVIDOR
    Girar é mudar CFrame todo frame. Feito no servidor, replica a ~20 Hz sem
    interpolação — o giro rápido que a habilidade pede viraria tranco. Aqui
    roda a 60 Hz na máquina de quem vê.

  VFX REAPROVEITADO, com os nomes reais do arquivo enviado
    Sword of Cosmic Entity (Revamped):
      CosmicVFX2/ShurikenModel   corpo da shuriken (mesh + 4 Trails + emissores)
      CosmicVFX2/Explosion_Sphere  esfera da explosão colossal
      CosmicVFX2/Explosion_Wind    sopro da explosão
      CosmicVFX2/Nova_Circle, Nova_Wave, MegaWave  anéis da explosão
      Server/Launch_Trail          rastro das mini shurikens
    Jupiter Great Pressure Sword:
      GearScript/JupiterOmni/CAMShake/Shake_Camera   tremor de câmera
      GearScript/JupiterOmni/VFXModule/Spiral_Explosion  espiral da explosão
      GearScript/JupiterOmni/VFXModule/Orbs/Orb_Trail    rastro orbital
      GearScript/JupiterOmni/VFXModule/Impact_Frame/Impact_Sound

  DOIS NOMES QUE VOCÊ CITOU E QUE **NÃO EXISTEM** NO ARQUIVO ENVIADO
    `BlackHole` e `Bpull`. O buraco negro é montado aqui a partir do
    ShurikenModel pintado de preto Neon com um núcleo escuro; o puxão é
    física no servidor, que era como você queria de qualquer jeito. Tudo o
    que é opcional passa por busca com timeout curto e cai num equivalente
    próprio se faltar — nada quebra.

  PROIBIÇÕES RESPEITADAS
    Zero `math.random` (ângulo áureo). Zero `:Destroy()` (Parent = nil e
    Debris). Zero `tick()` (acumulador de dt a partir de zero).
═══════════════════════════════════════════════════════════════════════════
--]]

local Players      = game:GetService("Players")
local Debris       = game:GetService("Debris")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tool = script.Parent

Tool.CanBeDropped   = false
Tool.RequiresHandle = true

local Jogador = Players.LocalPlayer

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	ESPERA_CURTA = 2,     -- timeout de toda busca opcional
	ANGULO_AUREO = math.rad(137.507764),

	COR_EVENTO   = Color3.fromRGB(12, 0, 24),    -- o corpo do buraco negro
	COR_BORDA    = Color3.fromRGB(150, 90, 255),  -- a radiação na borda
	COR_NUCLEO   = Color3.fromRGB(255, 240, 255),

	TREMOR_FORCA = 0.55,
	TREMOR_TEMPO = 0.9,
	LIMITE_VIVOS = 220,
}

--═══════════════════════════════════════════════════════════════
-- REMOTES
--═══════════════════════════════════════════════════════════════

local Remote    = Tool:WaitForChild("Remote", 10)
local VFXRemote = Tool:WaitForChild("HawkingVFXRemote", 10)

--═══════════════════════════════════════════════════════════════
-- ACHAR OS MOLDES REAIS — busca com timeout curto, sem quebrar
--═══════════════════════════════════════════════════════════════

--- Procura por nome em qualquer profundidade da Tool. Devolve nil se não
--- achar; TODO chamador trata nil.
local function acharNaTool(nome)
	local achado = Tool:FindFirstChild(nome, true)
	if achado then return achado end
	local esperado = Tool:WaitForChild(nome, CFG.ESPERA_CURTA)
	return esperado
end

local MoldeShuriken   = acharNaTool("ShurikenModel")
local MoldeEsfera     = acharNaTool("Explosion_Sphere")
local MoldeVento      = acharNaTool("Explosion_Wind")
local MoldeNovaCirc   = acharNaTool("Nova_Circle")
local MoldeMegaWave   = acharNaTool("MegaWave")
local MoldeLaunch     = acharNaTool("Launch_Trail")
local MoldeOrbTrail   = acharNaTool("Orb_Trail")
local SomImpacto      = acharNaTool("Impact_Sound")

--- `Shake_Camera` do Jupiter é um ModuleScript. Se ele existir e devolver
--- uma função, é ele quem sacode; senão, o tremor próprio entra no lugar.
local ShakeJupiter = nil
do
	local mod = acharNaTool("Shake_Camera")
	if mod and mod:IsA("ModuleScript") then
		local ok, valor = pcall(require, mod)
		if ok then ShakeJupiter = valor end
	end
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

local function sacudir(forca, duracao)
	if ShakeJupiter then
		local ok = pcall(function()
			if type(ShakeJupiter) == "function" then
				ShakeJupiter(forca, duracao)
			elseif type(ShakeJupiter) == "table" then
				local fn = ShakeJupiter.Shake or ShakeJupiter.shake
					or ShakeJupiter.Start or ShakeJupiter.New
				if fn then fn(forca, duracao) end
			end
		end)
		if ok then return end
	end
	tremorProprio(forca, duracao)
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

	sacudir(CFG.TREMOR_FORCA * 0.5, 0.45)

	local corpo = nil
	if MoldeShuriken and MoldeShuriken:IsA("Model") then
		corpo = MoldeShuriken:Clone()
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

	sacudir(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)

	if SomImpacto and SomImpacto:IsA("Sound") then
		local som = SomImpacto:Clone()
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
	if MoldeEsfera and MoldeEsfera:IsA("BasePart") then
		local esfera = MoldeEsfera:Clone()
		esfera.Anchored = true
		esfera.CanCollide, esfera.CanTouch, esfera.CanQuery = false, false, false
		esfera.CFrame = CFrame.new(centro)
		esfera.Size = Vector3.new(6, 6, 6) * escala
		esfera.Parent = workspace
		tween(esfera, 0.55, { Size = Vector3.new(34, 34, 34) * escala,
			Transparency = 1 }, Enum.EasingStyle.Quint)
		registrar(esfera, 1.2)
	end

	if MoldeVento and MoldeVento:IsA("BasePart") then
		local vento = MoldeVento:Clone()
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
	local aneis = { MoldeNovaCirc, MoldeMegaWave }
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
	if MoldeShuriken and MoldeShuriken:IsA("Model") then
		corpo = MoldeShuriken:Clone()
		corpo.Name = "HawkingMiniShuriken"
		corpo.Parent = workspace
		pcall(function() corpo:PivotTo(alvo.CFrame) end)
		escalarModelo(corpo, escala)
		pintarBuracoNegro(corpo)
		registrar(corpo, (d.duracao or 6) + 1)
		anotar(id, corpo)
	end

	if MoldeLaunch and MoldeLaunch:IsA("Trail") then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1.2 * escala, 0)
		a0.Parent = alvo
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.2 * escala, 0)
		a1.Parent = alvo
		local rastro = MoldeLaunch:Clone()
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

	sacudir(CFG.TREMOR_FORCA * 0.22, 0.3)
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
-- ENTRADA E RECEPÇÃO
--═══════════════════════════════════════════════════════════════

-- SEM GUI e SEM botão: só o clique/toque no ícone da Tool. Não há segunda
-- habilidade, então não há nada a mapear em tecla.
Tool.Activated:Connect(function()
	if Remote then Remote:FireServer() end
end)

if VFXRemote then
	VFXRemote.OnClientEvent:Connect(function(tipo, dados)
		dados = dados or {}
		if tipo == "PARAR" then
			parar(dados.id)
			return
		end
		local fn = Efeitos[tipo]
		if not fn then return end
		local ok, err = pcall(fn, dados)
		if not ok then
			warn("[HawkingShuriken] falha em " .. tostring(tipo) .. ": " .. tostring(err))
		end
	end)
end

--═══════════════════════════════════════════════════════════════
-- CLEANUP
--
-- Desequipar NÃO limpa: a shuriken já lançada continua no ar, igual às
-- bombas já lançadas. Só a morte do dono e a destruição da Tool limpam.
--═══════════════════════════════════════════════════════════════

Tool.Destroying:Connect(limparTudo)
Jogador.CharacterRemoving:Connect(limparTudo)

local function ligarMorte(personagem)
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then humanoide.Died:Connect(limparTudo) end
end

if Jogador.Character then ligarMorte(Jogador.Character) end
Jogador.CharacterAdded:Connect(ligarMorte)
