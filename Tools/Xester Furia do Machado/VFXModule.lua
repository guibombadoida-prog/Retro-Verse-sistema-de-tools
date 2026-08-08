-- VFXModule.lua
-- ModuleScript — desenho de efeito, 100% cliente
--
-- QUEM DESENHA É O PACK DO ACERVO
--   O fluxo obrigatório manda ler `ACERVO_RETROVERSE/_INDICE.md` ANTES de criar
--   efeito, e reusar o que já existe. Existe: o `Stella_VFX_Addon`, dez efeitos
--   já conformados pelo §12.12.2, os mesmos que as 18 Tools anteriores usam.
--   Onda, nova, explosão, corte, anel, rachadura, feixe e espiral saem de lá.
--
--   O que sobrou de código próprio aqui é a CARTA — que o pack não tem, porque
--   é a assinatura do Xester — e o fallback de cada efeito, para o caso do pack
--   faltar. Pack ausente é Tool empobrecida, não Tool quebrada.
--
-- MOLDE APAGADO, CLONE ACESO
--   Tool equipada mora no workspace, então TODO BasePart descendente dela
--   renderiza. Por isso o molde entra com `Transparency = 1` e o emissor
--   `Enabled = false` — propriedade, não script, então vale para todo cliente
--   sem nada rodando. Quem acende é a cópia, nunca o molde.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local M = {}

--══════════════════════════════════════════════════════════════
-- PALETA — Forma 2, O Despertar
--══════════════════════════════════════════════════════════════

local COR = {
	CLARO = Color3.fromRGB(226, 60, 60),
	ESCURO = Color3.fromRGB(20, 18, 22),
	QUENTE = Color3.fromRGB(255, 92, 46),
	FUMACA = Color3.fromRGB(100, 102, 115),
}

--══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- Regra nº 1, sem exceção: os módulos são filhos deste ModuleScript. Nada é
-- lido do Acervo em runtime — o pack é copiado para dentro na montagem.
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

--- Chama um efeito do pack. Devolve `false` se ele não estiver lá, e é isso
--- que faz o fallback local entrar.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Xester VFX] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--══════════════════════════════════════════════════════════════
-- MOLDE -> CÓPIA ACESA
--══════════════════════════════════════════════════════════════

local ACESO = {
	BasePart = { Transparency = 0 },
	Decal = { Transparency = 0 },
	Texture = { Transparency = 0 },
	ParticleEmitter = { Enabled = true },
	Trail = { Enabled = true },
	Beam = { Enabled = true },
	PointLight = { Enabled = true },
	SpotLight = { Enabled = true },
}

local vivos = {}

local function acender(instancia)
	for classe, campos in pairs(ACESO) do
		if instancia:IsA(classe) then
			for campo, valor in pairs(campos) do
				pcall(function() instancia[campo] = valor end)
			end
		end
	end
end

function M.clonar(molde, vida)
	if not molde then return nil end
	local copia = molde:Clone()
	acender(copia)
	for _, filho in ipairs(copia:GetDescendants()) do
		acender(filho)
	end
	copia.Parent = workspace
	table.insert(vivos, copia)
	Debris:AddItem(copia, vida or 4)
	return copia
end

local function achar(moldes, nome)
	return moldes and moldes:FindFirstChild(nome, true)
end

--══════════════════════════════════════════════════════════════
-- PRIMITIVAS — pack primeiro, fallback local depois
--══════════════════════════════════════════════════════════════

--- Anel de choque no chão. `Shockwave` do pack; sem ele, um disco em Tween.
local function onda(posicao, escala, cor, vida)
	local base = Vector3.new(10.775, 2.3, 10.505) * (escala or 1)
	if pk("Shockwave", CFrame.new(posicao), CFrame.new(posicao), vida or 1.2,
			base, base * 3, cor or COR.CLARO, cor or COR.ESCURO,
			Enum.EasingStyle.Quint) then
		return
	end
	local disco = Instance.new("Part")
	disco.Shape = Enum.PartType.Cylinder
	disco.Size = Vector3.new(0.4, base.X, base.Z)
	disco.CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90))
	disco.Material = Enum.Material.Neon
	disco.Color = cor or COR.CLARO
	disco.Anchored, disco.CanCollide = true, false
	disco.Parent = workspace
	table.insert(vivos, disco)
	Debris:AddItem(disco, (vida or 1.2) + 0.5)
	TweenService:Create(disco, TweenInfo.new(vida or 1.2,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = disco.Size * 3, Transparency = 1 }):Play()
end

--- Anel largo e lento — o segundo tempo de um impacto grande.
local function ondaLarga(posicao, escala, cor, vida)
	local base = Vector3.new(14, 1.4, 14) * (escala or 1)
	if pk("Shockwave_2", CFrame.new(posicao), CFrame.new(posicao), vida or 1.8,
			base, base * 3.4, cor or COR.CLARO, cor or COR.ESCURO,
			Enum.EasingStyle.Quart) then
		return
	end
	onda(posicao, (escala or 1) * 1.5, cor, vida)
end

--- Clarão pequeno. É o beat de "saiu da mão".
local function nova(posicao, escala, cor, vida)
	-- Small_Nova recebe Size_A/Size_B como NÚMERO, não Vector3: o corpo do
	-- módulo faz conta com eles. Vector3 derruba em "invalid argument #1 to
	-- 'new'", e o pcall engolia o erro em silêncio.
	local raio = escala or 4
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Small_Nova", posicao, vida or 0.6, raio, raio * 4,
			cor or COR.CLARO, cor or COR.ESCURO, Enum.EasingStyle.Quint) then
		return
	end
	local bola = Instance.new("Part")
	bola.Shape = Enum.PartType.Ball
	bola.Size = a
	bola.Material = Enum.Material.Neon
	bola.Color = cor or COR.CLARO
	bola.Anchored, bola.CanCollide = true, false
	bola.CFrame = CFrame.new(posicao)
	bola.Parent = workspace
	table.insert(vivos, bola)
	Debris:AddItem(bola, (vida or 0.6) + 0.4)
	TweenService:Create(bola, TweenInfo.new(vida or 0.6,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = a * 4, Transparency = 1 }):Play()
end

--- Estouro com anel. O golpe médio.
local function estouro(posicao, escala, cor, vida)
	local raio = escala or 6
	local a = Vector3.new(1, 1, 1) * raio
	if pk("Shockwave_Explosion", posicao, vida or 0.9, raio, raio * 3.2,
			cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	nova(posicao, escala, cor, vida)
	onda(posicao, (escala or 6) / 8, cor, (vida or 0.9) + 0.4)
end

--- Estouro grande, com fumaça. Reservado para ultimate.
local function estouroFumegante(posicao, escala, cor, fumaca)
	if pk("Smoky_Explosion", posicao, 1.4, (escala or 8),
			cor or COR.CLARO, fumaca or COR.FUMACA) then
		return
	end
	estouro(posicao, (escala or 8) * 1.6, cor, 1.3)
end

--- Risco de corte.
local function corte(cframe, escala, cor, vida)
	if pk("Small_Slash", cframe, (escala or 6),
			vida or 0.45, cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	nova(cframe.Position, (escala or 6) * 0.5, cor, vida or 0.45)
end

--- Anel fino que abre — conjuração, escudo subindo, portal nascendo.
local function anelSonar(cframe, escala, cor, vida)
	if pk("Sonar_Ring", cframe, vida or 1, (escala or 6), (escala or 6) * 4,
			0.6, 0.05, cor or COR.CLARO, cor or COR.ESCURO) then
		return
	end
	onda(cframe.Position, (escala or 6) / 10, cor, vida)
end

--- Rachadura no chão. É o que dá PESO ao impacto de carta grande.
local function rachadura(posicao, escala, cor, vida)
	if pk("Floor_Crack", CFrame.new(posicao), (escala or 8),
			vida or 3, cor or COR.ESCURO) then
		return
	end
	onda(posicao, (escala or 8) / 10, cor, 1.4)
end

--- Feixe reto. O pack desenha o cilindro; nós só damos as pontas.
local function feixe(origem, destino, calibre, cor, vida)
	if pk("Laser_Shot", origem, destino, (calibre or 3), (calibre or 3) * 0.2,
			nil, cor or COR.CLARO, cor or COR.ESCURO,
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
	cilindro.Color = cor or COR.CLARO
	cilindro.Anchored, cilindro.CanCollide = true, false
	cilindro.Parent = workspace
	table.insert(vivos, cilindro)
	Debris:AddItem(cilindro, (vida or 2) + 0.5)
	TweenService:Create(cilindro, TweenInfo.new(vida or 2,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }):Play()
end

--- Espiral. É o efeito que faz sucção e tornado LEREM como sucção e tornado.
local function espiral(posicao, escala, cor, voltas, raio, altura)
	if pk("Spiral_Effect", posicao, (escala or 1.4),
			cor or COR.CLARO, voltas or 26, raio or 8, altura or 14) then
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
-- A CARTA — o pack não tem, e é a assinatura do Xester
--══════════════════════════════════════════════════════════════

local function carta(moldes, cframe, tamanho, vida)
	local base = achar(moldes, "Carta1")
	if not base then
		local baralho = achar(moldes, "cards")
		base = baralho and baralho:FindFirstChildWhichIsA("BasePart")
	end
	if not base or not base:IsA("BasePart") then return nil end

	local copia = M.clonar(base, vida or 2)
	if not copia then return nil end
	copia.Anchored, copia.CanCollide = true, false
	copia.Size = Vector3.new(0.1, 0.25, 0.1)
	copia.CFrame = cframe
	TweenService:Create(copia, TweenInfo.new((vida or 2) * 0.35,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = tamanho or Vector3.new(2.5, 0.25, 1.75) }):Play()
	task.delay((vida or 2) * 0.6, function()
		if copia.Parent then
			TweenService:Create(copia, TweenInfo.new((vida or 2) * 0.4),
				{ Transparency = 1 }):Play()
		end
	end)
	return copia
end

--══════════════════════════════════════════════════════════════
-- O CATÁLOGO — um beat nomeado por efeito
--══════════════════════════════════════════════════════════════

local VFX = {}

function VFX.CARTA_CHAO(d, moldes)
	carta(moldes, CFrame.new(d.posicao)
		* CFrame.Angles(0, math.rad(d.giro or 0), 0), d.tamanho, 2.5)
	rachadura(d.posicao, 10, COR.ESCURO, 3)
end

function VFX.ONDA_DUPLA(d)
	onda(d.posicao, d.escala or 1, COR.CLARO, 1.4)
	ondaLarga(d.posicao, (d.escala or 1) * 0.6, COR.ESCURO, 2)
end

function VFX.ONDA_CHAO(d)
	onda(d.posicao, 0.35, COR.CLARO, 1)
end

function VFX.LEQUE_ABRE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 5, COR.CLARO, 0.8)
	local total = d.cartas or 20
	local i = 1
	while i <= total do
		local ang = math.rad(360 / total * i)
		carta(moldes, raiz.CFrame * CFrame.new(math.cos(ang) * (d.raio or 4),
			math.sin(ang) * (d.raio or 4), 0), nil, 8)
		i = i + 1
	end
end

function VFX.LEQUE_FECHA() end

function VFX.LEQUE_ATIRA(d)
	nova(d.origem, 3, COR.CLARO, 0.5)
end

function VFX.CARTA_VOA(d, moldes)
	carta(moldes, CFrame.new(d.destino), nil, 1.2)
	corte(CFrame.new(d.destino), 5, COR.CLARO, 0.4)
end

--- Cardnado: espiral é literalmente o efeito certo, e o pack já tem.
function VFX.TEMPESTADE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position, 1.6, COR.CLARO, 30, d.raio and (d.raio / 3) or 7,
		(d.altura or 3.2) * 5)

	local base = achar(moldes, "Tempestade")
	if not base then return end
	local copia = M.clonar(base, d.duracao or 2)
	if not copia or not copia:IsA("BasePart") then return end
	copia.Anchored, copia.CanCollide = true, false
	local giro, conexao = 0, nil
	conexao = RunService.Heartbeat:Connect(function(dt)
		if not (copia.Parent and raiz.Parent) then
			conexao:Disconnect()
			return
		end
		giro = giro + dt * 6
		copia.CFrame = raiz.CFrame * CFrame.new(0, d.altura or 3.2, 0)
			* CFrame.Angles(0, giro, 0)
	end)
	task.delay(d.duracao or 2, function() conexao:Disconnect() end)
end

function VFX.FANTASMA(d, _moldes, personagem)
	nova(d.posicao, 4, COR.CLARO, 0.5)
	if not personagem then return end
	for _, parte in ipairs(personagem:GetChildren()) do
		if parte:IsA("BasePart") then
			local eco = Instance.new("Part")
			eco.Size, eco.CFrame = parte.Size, parte.CFrame
			eco.Material = Enum.Material.Neon
			eco.Color = COR.CLARO
			eco.Anchored, eco.CanCollide = true, false
			eco.Transparency = 0.4
			eco.Parent = workspace
			table.insert(vivos, eco)
			Debris:AddItem(eco, 1)
			TweenService:Create(eco, TweenInfo.new(1),
				{ Transparency = 1 }):Play()
		end
	end
end

function VFX.CARTA_ERGUE(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.2)
	anelSonar(CFrame.new(d.posicao), 8, COR.CLARO, 0.7)
end

function VFX.CARTA_DESABA(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.4)
	rachadura(d.posicao, 16, COR.ESCURO, 4)
	local i = 1
	while i <= (d.aneis or 4) do
		local indice = i
		task.delay(indice * 0.06, function()
			onda(d.posicao, 0.8 + indice * 0.3, COR.CLARO, 1.5)
		end)
		i = i + 1
	end
end

function VFX.PORTAL_ABRE(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		d.tamanho, 3)
	anelSonar(CFrame.new(d.posicao), 10, COR.ESCURO, 1.2)
	espiral(d.posicao, 1.8, COR.ESCURO, 34, 10, 18)
end

function VFX.PORTAL_COLAPSA(d)
	estouroFumegante(d.posicao, 12, COR.ESCURO, COR.FUMACA)
	local i = 1
	while i <= (d.estouros or 4) do
		local indice = i
		task.delay(indice * 0.05, function()
			estouro(d.posicao, 8 + indice * 3, COR.CLARO, 0.9)
		end)
		i = i + 1
	end
	local a = 1
	while a <= (d.aneis or 2) do
		ondaLarga(d.posicao, 1.6, COR.ESCURO, 2)
		a = a + 1
	end
end

function VFX.ESCUDO_SOBE(d)
	anelSonar(CFrame.new(d.posicao), 6, COR.CLARO, 0.6)
end

function VFX.ESCUDO_REBATE(d)
	nova(d.posicao, 4, COR.CLARO, 0.4)
end

function VFX.ESCUDO_ESTILHACA(d, moldes)
	estouro(d.posicao, 7, COR.CLARO, 0.8)
	local i = 1
	while i <= (d.cacos or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, CFrame.new(d.posicao + Vector3.new(
			math.cos(ang) * 4, i * 0.3, math.sin(ang) * 4)), nil, 1.4)
		i = i + 1
	end
end

function VFX.CEIFEIRA_VOA(d, moldes)
	local peca = carta(moldes, CFrame.new(d.origem), nil, (d.voo or 0.35) + 0.4)
	if not peca then return end
	TweenService:Create(peca, TweenInfo.new(d.voo or 0.35,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = CFrame.new(d.destino) }):Play()
	corte(CFrame.new(d.origem), 4, COR.ESCURO, 0.3)
end

function VFX.CEIFEIRA_ESTOURA(d)
	estouro(d.posicao, 9, COR.ESCURO, 0.9)
	rachadura(d.posicao, 8, COR.ESCURO, 2.5)
end

function VFX.ESFERA_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position + raiz.CFrame.LookVector * 3, 1.5, COR.ESCURO,
		30, 7, 12)
end

function VFX.ESFERA_DETONA(d)
	estouroFumegante(d.posicao, 14 * (d.escala or 1), COR.ESCURO, COR.FUMACA)
	ondaLarga(d.posicao, 2, COR.ESCURO, 2.2)
end

function VFX.BARALHO_CONJURA(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 9, COR.ESCURO, d.duracao or 2.5)
	local i = 1
	while i <= (d.cartas or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, raiz.CFrame * CFrame.new(math.cos(ang) * 8, 2,
			math.sin(ang) * 8), nil, (d.duracao or 2.5) + 3)
		i = i + 1
	end
end

function VFX.BARALHO_GOLPE(d)
	corte(CFrame.new(d.posicao), 5, COR.ESCURO, 0.4)
end

function VFX.INVOCA(d)
	espiral(d.posicao, 1.6, COR.ESCURO, 28, 6, 12)
	rachadura(d.posicao, 7, COR.ESCURO, 3)
end

function VFX.SERVO_GOLPE(d)
	corte(CFrame.new(d.posicao), 3.5, COR.QUENTE, 0.3)
end

function VFX.MACHADO_SACA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	anelSonar(raiz.CFrame, 7, COR.QUENTE, 0.8)
	local luz = Instance.new("PointLight")
	luz.Color = COR.ESCURO
	luz.Range, luz.Brightness = 35, 3
	luz.Parent = raiz
	Debris:AddItem(luz, d.duracao or 6)
end

function VFX.MACHADO_CORTA(d)
	corte(CFrame.new(d.posicao), 7, COR.QUENTE, 0.4)
end

function VFX.MACHADO_GUARDA() end

function VFX.PROCISSAO(d, moldes)
	local i = 1
	while i <= (d.passos or 24) do
		local indice = i
		task.delay(indice * (d.intervalo or 0.04), function()
			local onde = d.origem + d.direcao * (indice * (d.espaco or 3.5))
			carta(moldes, CFrame.new(onde - Vector3.new(0, 2, 0))
				* CFrame.Angles(0, math.rad(137.507764 * indice), 0),
				Vector3.new(7, 0.25, 5), 1.6)
			rachadura(onde, 4, COR.ESCURO, 1.6)
		end)
		i = i + 1
	end
end

function VFX.PORTAL_CAJADO(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		Vector3.new(9, 0.35, 9), (d.duracao or 4) + 1)
	anelSonar(CFrame.new(d.posicao), 9, COR.ESCURO, 1.2)
	espiral(d.posicao, 1.4, COR.ESCURO, 24, 6, 10)
end

function VFX.CORTE_PORTAL(d)
	corte(CFrame.new(d.posicao), 6, COR.ESCURO, 0.4)
end

function VFX.GARGALHADA(d, moldes)
	anelSonar(CFrame.new(d.posicao), 5, COR.CLARO, 0.9)
	local i = 1
	while i <= (d.cartas or 8) do
		local indice = i
		local ang = math.rad(137.507764 * indice)
		local peca = carta(moldes, CFrame.new(d.posicao + Vector3.new(
			math.cos(ang) * 3, 2, math.sin(ang) * 3)), nil, 2)
		if peca then
			TweenService:Create(peca, TweenInfo.new(2,
				Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = peca.CFrame * CFrame.new(0, 8, 0) }):Play()
		end
	end
end

function VFX.FOGO_SAI(d)
	nova(d.origem, (d.calibre or 2) * 1.2, COR.QUENTE, 0.4)
end

function VFX.FOGO_ESTOURA(d)
	estouro(d.posicao, 7 * (d.escala or 1), COR.QUENTE, 0.9)
end

function VFX.FOGO_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	espiral(raiz.Position + raiz.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0),
		1.4, COR.QUENTE, 26, 5, 9)
end

function VFX.FOGO_ESTOURA_GRANDE(d)
	estouroFumegante(d.posicao, 16 * (d.escala or 1), COR.QUENTE, COR.FUMACA)
	local i = 1
	while i <= (d.aneis or 2) do
		ondaLarga(d.posicao, 1.4, COR.QUENTE, 2)
		i = i + 1
	end
end

function VFX.SOPRO(d)
	local i = 1
	while i <= (d.passos or 25) do
		local indice = i
		task.delay(indice * (d.intervalo or 0.06), function()
			local onde = d.origem + d.direcao * (indice * 2.4)
			nova(onde, 4 + indice * 0.35, COR.QUENTE, 0.55)
			if indice % 5 == 0 then
				corte(CFrame.new(onde, onde + d.direcao), 6, COR.QUENTE, 0.35)
			end
		end)
		i = i + 1
	end
end

--- O feixe é do pack: uma peça esticada de uma vez, no cliente. Esticar por
--- quadro no servidor é o caso que replica picotado.
function VFX.RAIO(d)
	feixe(d.origem, d.origem + d.direcao * (d.alcance or 60),
		d.calibre or 3, COR.CLARO, d.duracao or 2.2)
	nova(d.origem, 3, COR.CLARO, 0.4)
	estouro(d.origem + d.direcao * (d.alcance or 60), 6, COR.CLARO, 0.8)
end

--══════════════════════════════════════════════════════════════

function M.desenhar(tipo, dados, moldes, personagem)
	local fn = VFX[tipo]
	if not fn then return end
	local ok, erro = pcall(fn, dados, moldes, personagem)
	if not ok then
		warn("[Xester VFX] " .. tostring(tipo) .. ": " .. tostring(erro))
	end
end

--- Beat do animator. O gesto marca CARGA e GOLPE; aqui viram brilho na mão,
--- para o golpe ter peso ANTES do efeito grande chegar.
function M.beat(marca, personagem)
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not braco then return end
	if marca == "CARGA" then
		nova(braco.Position, 2, COR.CLARO, 0.3)
	elseif marca == "GOLPE" then
		nova(braco.Position, 4, COR.CLARO, 0.35)
	end
end

function M.limpar()
	for _, peca in ipairs(vivos) do
		if peca and peca.Parent then peca.Parent = nil end
	end
	vivos = {}
end

return M
