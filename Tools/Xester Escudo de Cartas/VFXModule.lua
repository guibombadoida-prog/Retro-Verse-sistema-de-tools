-- VFXModule.lua
-- ModuleScript — desenho de efeito, 100% cliente
--
-- MOLDE APAGADO, CLONE ACESO
--   Tool equipada mora no workspace, então TODO BasePart descendente dela
--   renderiza. Por isso o molde entra com `Transparency = 1` e o emissor
--   `Enabled = false` — propriedade, não script, então vale para todo cliente
--   sem nada rodando.
--
--   Quem acende é o `_rv_clone`: ele restaura, por CAMINHO dentro do molde, os
--   valores originais gravados em `ACESO`. Acender pela cópia (e não pelo
--   molde) é o que impede o molde de aparecer dentro da Tool guardada.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester.py.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local M = {}

-- valores que o clone recupera, por classe
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

--- Clona um molde JÁ ACESO. O molde continua invisível dentro da Tool.
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

--- Onda de choque: a malha 20329976 do original, crescendo por Tween.
--- Tween no cliente em vez de `Size + Vector3` por quadro no servidor.
local function onda(moldes, posicao, escala, vida)
	local base = achar(moldes, "Onda") or achar(moldes, "shockwave")
	if not base then return end
	local copia = M.clonar(base, vida or 2)
	if not copia or not copia:IsA("BasePart") then return end
	copia.Anchored = true
	copia.CanCollide = false
	copia.CFrame = CFrame.new(posicao)
	local malha = copia:FindFirstChildOfClass("SpecialMesh")
	local alvo = (malha and malha.Scale or Vector3.new(1, 1, 1))
		+ Vector3.new(60, 3, 60) * (escala or 1)
	if malha then
		TweenService:Create(malha, TweenInfo.new(vida or 2,
			Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Scale = alvo }):Play()
	end
	TweenService:Create(copia, TweenInfo.new(vida or 2,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }):Play()
end

local function esfera(posicao, escala, cor, vida)
	local bola = Instance.new("Part")
	bola.Shape = Enum.PartType.Ball
	bola.Size = Vector3.new(1, 1, 1)
	bola.Material = Enum.Material.Neon
	bola.BrickColor = BrickColor.new(cor or "White")
	bola.Anchored = true
	bola.CanCollide = false
	bola.CFrame = CFrame.new(posicao)
	bola.Parent = workspace
	table.insert(vivos, bola)
	Debris:AddItem(bola, vida or 1.2)
	TweenService:Create(bola, TweenInfo.new(vida or 1.2,
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = Vector3.new(1, 1, 1) * (escala or 6),
		Transparency = 1,
	}):Play()
	return bola
end

--- Carta que sobe do chão e some. É a peça mais repetida do Xester.
local function carta(moldes, cframe, tamanho, vida)
	local base = achar(moldes, "Carta1") or achar(moldes, "cards")
	if base and base:IsA("Model") then
		base = base:FindFirstChildWhichIsA("BasePart")
	end
	if not base then return end
	local copia = M.clonar(base, vida or 2)
	if not copia or not copia:IsA("BasePart") then return end
	copia.Anchored = true
	copia.CanCollide = false
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
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(0, math.rad(d.giro or 0), 0),
		d.tamanho, 2.5)
end

function VFX.ONDA_DUPLA(d, moldes)
	onda(moldes, d.posicao, d.escala or 1, 1.6)
	onda(moldes, d.posicao, (d.escala or 1) * 0.4, 2.2)
end

function VFX.ONDA_CHAO(d, moldes)
	onda(moldes, d.posicao, 0.35, 1.1)
end

function VFX.LEQUE_ABRE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	local i = 1
	while i <= (d.cartas or 20) do
		local ang = math.rad(360 / (d.cartas or 20) * i)
		carta(moldes, raiz.CFrame * CFrame.new(
			math.cos(ang) * (d.raio or 4), math.sin(ang) * (d.raio or 4), 0), nil, 8)
		i = i + 1
	end
end

function VFX.LEQUE_FECHA() end

function VFX.LEQUE_ATIRA(d)
	esfera(d.origem, 3, "White", 0.5)
end

function VFX.CARTA_VOA(d, moldes)
	carta(moldes, CFrame.new(d.destino), nil, 1.2)
	esfera(d.destino, 4, "White", 0.6)
end

function VFX.TEMPESTADE(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	local base = achar(moldes, "Tempestade")
	if not base then return end
	local copia = M.clonar(base, d.duracao or 2)
	if not copia or not copia:IsA("BasePart") then return end
	copia.Anchored = true
	copia.CanCollide = false
	local conexao
	local giro = 0
	conexao = game:GetService("RunService").Heartbeat:Connect(function(dt)
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
	if not personagem then return end
	for _, parte in ipairs(personagem:GetChildren()) do
		if parte:IsA("BasePart") then
			local eco = Instance.new("Part")
			eco.Size = parte.Size
			eco.CFrame = parte.CFrame
			eco.Material = Enum.Material.Neon
			eco.BrickColor = BrickColor.new("White")
			eco.Anchored = true
			eco.CanCollide = false
			eco.Transparency = 0.4
			eco.Parent = workspace
			Debris:AddItem(eco, 1)
			TweenService:Create(eco, TweenInfo.new(1),
				{ Transparency = 1 }):Play()
		end
	end
end

function VFX.CARTA_ERGUE(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.2)
end

function VFX.CARTA_DESABA(d, moldes)
	carta(moldes, CFrame.new(d.posicao), d.tamanho, 1.4)
	local i = 1
	while i <= (d.aneis or 4) do
		local indice = i
		task.delay(indice * 0.06, function()
			onda(moldes, d.posicao, 0.8 + indice * 0.3, 1.6)
		end)
		i = i + 1
	end
end

function VFX.PORTAL_ABRE(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		d.tamanho, 3)
	esfera(d.posicao, 10, "Really black", 1.5)
end

function VFX.PORTAL_COLAPSA(d, moldes)
	local i = 1
	while i <= (d.estouros or 4) do
		local indice = i
		task.delay(indice * 0.05, function()
			esfera(d.posicao, 14 + indice * 4, "White", 1)
		end)
		i = i + 1
	end
	local a = 1
	while a <= (d.aneis or 2) do
		onda(moldes, d.posicao, 1.4, 2)
		a = a + 1
	end
end

function VFX.ESCUDO_SOBE(d)
	esfera(d.posicao, 5, "White", 0.6)
end

function VFX.ESCUDO_REBATE(d)
	esfera(d.posicao, 5, "White", 0.5)
end

function VFX.ESCUDO_ESTILHACA(d, moldes)
	local i = 1
	while i <= (d.cacos or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, CFrame.new(d.posicao
			+ Vector3.new(math.cos(ang) * 4, i * 0.3, math.sin(ang) * 4)), nil, 1.4)
		i = i + 1
	end
	onda(moldes, d.posicao, 0.6, 1.4)
end

function VFX.CEIFEIRA_VOA(d, moldes)
	local peca = carta(moldes, CFrame.new(d.origem), nil, (d.voo or 0.35) + 0.4)
	if not peca then return end
	TweenService:Create(peca, TweenInfo.new(d.voo or 0.35,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = CFrame.new(d.destino) }):Play()
end

function VFX.CEIFEIRA_ESTOURA(d, moldes)
	esfera(d.posicao, 12, "Really black", 0.9)
	onda(moldes, d.posicao, 0.7, 1.5)
end

function VFX.ESFERA_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	local bola = esfera(raiz.Position + raiz.CFrame.LookVector * 3, 8,
		"Really black", d.duracao or 2.4)
	if bola then bola.Transparency = 0.2 end
end

function VFX.ESFERA_DETONA(d, moldes)
	esfera(d.posicao, 30 * (d.escala or 1), "Really black", 1.2)
	onda(moldes, d.posicao, 1.6, 2)
end

function VFX.BARALHO_CONJURA(d, moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	local i = 1
	while i <= (d.cartas or 12) do
		local ang = math.rad(137.507764 * i)
		carta(moldes, raiz.CFrame * CFrame.new(math.cos(ang) * 8, 2,
			math.sin(ang) * 8), nil, (d.duracao or 2.5) + 3)
		i = i + 1
	end
end

function VFX.BARALHO_GOLPE(d)
	esfera(d.posicao, 6, "White", 0.5)
end

function VFX.INVOCA(d, moldes)
	esfera(d.posicao, 12, "Really black", 1)
	onda(moldes, d.posicao, 0.5, 1.4)
end

function VFX.SERVO_GOLPE(d)
	esfera(d.posicao, 4, "Really red", 0.4)
end

function VFX.MACHADO_SACA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	local luz = Instance.new("PointLight")
	luz.Color = Color3.new(0.1, 0, 0)
	luz.Range = 35
	luz.Brightness = 3
	luz.Parent = raiz
	Debris:AddItem(luz, d.duracao or 6)
end

function VFX.MACHADO_CORTA(d)
	esfera(d.posicao, 7, "Really red", 0.4)
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
		end)
		i = i + 1
	end
end

function VFX.PORTAL_CAJADO(d, moldes)
	carta(moldes, CFrame.new(d.posicao) * CFrame.Angles(math.rad(90), 0, 0),
		Vector3.new(9, 0.35, 9), (d.duracao or 4) + 1)
end

function VFX.CORTE_PORTAL(d)
	esfera(d.posicao, 8, "Really black", 0.5)
end

function VFX.GARGALHADA(d, moldes)
	local i = 1
	while i <= (d.cartas or 8) do
		local indice = i
		local ang = math.rad(137.507764 * indice)
		local peca = carta(moldes, CFrame.new(d.posicao
			+ Vector3.new(math.cos(ang) * 3, 2, math.sin(ang) * 3)), nil, 2)
		if peca then
			TweenService:Create(peca, TweenInfo.new(2,
				Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = peca.CFrame * CFrame.new(0, 8, 0) }):Play()
		end
		i = i + 1
	end
end

function VFX.FOGO_SAI(d)
	esfera(d.origem, (d.calibre or 2) * 1.5, "Bright orange", 0.4)
end

function VFX.FOGO_ESTOURA(d, moldes)
	esfera(d.posicao, 10 * (d.escala or 1), "Bright orange", 0.9)
	onda(moldes, d.posicao, 0.4, 1.2)
end

function VFX.FOGO_CARREGA(d, _moldes, personagem)
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then return end
	esfera(raiz.Position + raiz.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0),
		d.calibre or 9, "Really red", d.duracao or 1.8)
end

function VFX.FOGO_ESTOURA_GRANDE(d, moldes)
	esfera(d.posicao, 26 * (d.escala or 1), "Really red", 1.3)
	local i = 1
	while i <= (d.aneis or 2) do
		onda(moldes, d.posicao, 1.2, 2)
		i = i + 1
	end
end

function VFX.SOPRO(d, _moldes)
	local i = 1
	while i <= (d.passos or 25) do
		local indice = i
		task.delay(indice * (d.intervalo or 0.06), function()
			esfera(d.origem + d.direcao * (indice * 2.4),
				6 + indice * 0.5, "Bright orange", 0.6)
		end)
		i = i + 1
	end
end

--- O feixe é UM cilindro esticado de uma vez, no cliente. Esticar por quadro
--- no servidor é o caso que replica picotado.
function VFX.RAIO(d)
	local feixe = Instance.new("Part")
	feixe.Shape = Enum.PartType.Cylinder
	feixe.Material = Enum.Material.Neon
	feixe.BrickColor = BrickColor.new("White")
	feixe.Anchored = true
	feixe.CanCollide = false
	local calibre = d.calibre or 3
	feixe.Size = Vector3.new(d.alcance or 60, calibre, calibre)
	feixe.CFrame = CFrame.new(d.origem, d.origem + d.direcao)
		* CFrame.new(0, 0, -(d.alcance or 60) / 2)
		* CFrame.Angles(0, math.rad(90), 0)
	feixe.Parent = workspace
	table.insert(vivos, feixe)
	Debris:AddItem(feixe, d.duracao or 2.2)
	TweenService:Create(feixe, TweenInfo.new(d.duracao or 2.2,
		Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }):Play()
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

--- Beat do animator. O gesto marca CARGA e GOLPE; aqui eles viram brilho na
--- mão, para o golpe ter peso antes do efeito grande chegar.
function M.beat(marca, personagem)
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not braco then return end
	if marca == "CARGA" then
		esfera(braco.Position, 2.5, "White", 0.35)
	elseif marca == "GOLPE" then
		esfera(braco.Position, 5, "White", 0.4)
	end
end

function M.limpar()
	for _, peca in ipairs(vivos) do
		if peca and peca.Parent then peca.Parent = nil end
	end
	vivos = {}
end

return M
