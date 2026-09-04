-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto PODER DE FOGO
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: FOGO SOBE, E SOBE TORTO
--═══════════════════════════════════════════════════════════════
--
--   Fogo é o efeito que todo jogo tem e quase nenhum acerta, e o que separa
--   os dois é UMA coisa: fogo não é uma bola laranja que cresce. Fogo tem
--   TRÊS camadas com temperaturas diferentes, e elas se movem em velocidades
--   diferentes.
--
--     1. O NÚCLEO — quase branco, pequeno, e o que menos se move. É a parte
--        quente, e ela fica onde a coisa está queimando.
--     2. A LABAREDA — laranja, sobe RÁPIDO e some. É o que dá a direção.
--     3. A FUMAÇA — cinza, sobe DEVAGAR, e dura o triplo. É o que faz o
--        efeito continuar existindo depois de o fogo acabar.
--
--   Desenhar as três com a mesma cor e a mesma velocidade é o que produz a
--   "bola laranja". Aqui cada camada tem cor, prazo e velocidade próprios.
--
--   E ELE SOBE TORTO. Chama que sobe reta lê como jato de gás. O desvio
--   lateral por ângulo áureo é o que faz a labareda ondular — e é
--   determinístico, então todos os clientes veem a MESMA ondulação.
--
--   As camadas:
--
--     `camadaFagulha`    centenas de fagulhas subindo — o caso do BulkMoveTo
--     `camadaLabareda`   a chama laranja, rápida e torta
--     `camadaNucleo`     o miolo quase branco, parado
--     `camadaFumaca`     o cinza que sobe devagar e dura
--     `camadaAnelBrasa`  o anel no chão, para impacto
--     `camadaLinhaFogo`  a linha acesa (a muralha, o risco)
--     `camadaRastro`     o rastro do que voa
--
--═══════════════════════════════════════════════════════════════
-- ⚙️  `BulkMoveTo` E LOD — herdados do MAGNETISMO
--═══════════════════════════════════════════════════════════════
--
--   As fagulhas são centenas de peças que se movem todo quadro, e é o mesmo
--   caso da limalha: `workspace:BulkMoveTo` faz as N numa chamada, e
--   `densidade()` corta a contagem pela distância da câmera.
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `:Destroy()` de peça do mundo. Zero `tick()`. Zero `wait/spawn/delay`.
--   Zero `ScreenGui`, `ColorCorrection` e `Sky` — fogo é tentação para os
--   três, e nenhum deles respeita a regra nº 1. Zero
--   `Instance.new("Explosion")`.
--
--   `math.random` é permitido e este módulo NÃO o usa: a labareda tem de
--   ondular igual na tela de todo mundo.

local Debris       = game:GetService("Debris")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	LIMITE_VIVOS = 420,

	NUCLEO   = Color3.fromRGB(255, 244, 214),
	CHAMA    = Color3.fromRGB(255, 174, 56),
	BRASA    = Color3.fromRGB(238, 96, 28),
	CARVAO   = Color3.fromRGB(52, 40, 36),
	FUMACA   = Color3.fromRGB(96, 90, 88),
	AZUL_Q   = Color3.fromRGB(120, 190, 255),
	BRANCO   = Color3.fromRGB(238, 242, 248),

	T_ANEL = 0.45,
}

local Vivos, PorId, contador = {}, {}, 0
local limalhaViva = 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

local function angulo(i)
	return (i or proximo()) * CFG.ANGULO_AUREO
end

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id]
end

local function anotar(d, inst, conexao)
	local reg = registroDe(d)
	if not reg then return inst end
	if inst then table.insert(reg.partes, inst) end
	if conexao then table.insert(reg.conexoes, conexao) end
	return inst
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

local function novaParte(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Massless, p.CastShadow = true, false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, estilo, direcao)
	local info = TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad,
		direcao or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, alvo)
	t:Play()
	return t
end

local function branco(cor, quanto)
	return cor:Lerp(Color3.new(1, 1, 1), quanto or 0.5)
end

local function corDoPolo(polaridade)
	if polaridade == "SUL" then return CFG.SUL end
	return CFG.NORTE
end

--═══════════════════════════════════════════════════════════════
-- LOD — quantas partículas vale a pena desenhar daqui
--═══════════════════════════════════════════════════════════════

local function densidade(ponto, base)
	local cam = workspace.CurrentCamera
	if not cam or typeof(ponto) ~= "Vector3" then return base end
	local dist = (cam.CFrame.Position - ponto).Magnitude
	if dist <= CFG.LOD_PERTO then return base end
	if dist >= CFG.LOD_LONGE then
		return math.max(4, math.floor(base * CFG.LOD_PISO))
	end
	local t = (dist - CFG.LOD_PERTO) / (CFG.LOD_LONGE - CFG.LOD_PERTO)
	return math.max(4, math.floor(base * (1 - t * (1 - CFG.LOD_PISO))))
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function acharPack()
	if packProcurado then return raizPack end
	packProcurado = true
	raizPack = Deposito.achar(script, PACK.PASTA)
		or script:FindFirstChild(PACK.PASTA)
	return raizPack
end

local function efeitoDoPack(nome)
	if not PACK.LIGADO then return nil end
	local guardado = moduloDoPack[nome]
	if guardado ~= nil then
		if guardado == false then return nil end
		return guardado
	end
	local raiz = acharPack()
	if not raiz then moduloDoPack[nome] = false return nil end
	local modulo = raiz:FindFirstChild(nome)
	if not modulo or not modulo:IsA("ModuleScript") then
		moduloDoPack[nome] = false
		return nil
	end
	local ok, fn = pcall(require, modulo)
	if not ok or type(fn) ~= "function" then
		moduloDoPack[nome] = false
		return nil
	end
	moduloDoPack[nome] = fn
	return fn
end

--- `pk` de nome que não existe no pack devolve false EM SILÊNCIO. Os dez nomes
--- reais são Floor_Crack, Laser_Shot, Shockwave, Shockwave_2,
--- Shockwave_Explosion, Small_Nova, Small_Slash, Smoky_Explosion, Sonar_Ring
--- e Spiral_Effect.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Fogo] pack " .. tostring(nome)
			.. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- MOLDES — a agulha de limalha, e o resto
--
-- Na ENTREGA o molde é invisível e ancorado (`Transparency = 1`). Quem o
-- acende é `molde()`, no instante da habilidade — a regra "invisível dentro da
-- Tool, visível na execução".
--═══════════════════════════════════════════════════════════════

local pastaMoldes = nil
local procurada = false

local function moldes()
	if procurada then return pastaMoldes end
	procurada = true
	local tool = script.Parent
	pastaMoldes = Deposito.achar(script, "Moldes")
		or (tool and tool:FindFirstChild("Moldes"))
	return pastaMoldes
end

local function molde(nome, props, visivel)
	local pasta = moldes()
	local base = pasta and pasta:FindFirstChild(nome)
	if not base then return nil end
	local copia = base:Clone()
	if copia:IsA("BasePart") then
		copia.Anchored = true
		copia.CanCollide = false
		copia.CanTouch = false
		copia.CanQuery = false
		if visivel ~= false then copia.Transparency = 0 end
	end
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	copia.Parent = workspace
	return copia
end

--- ⚙️ ATRIBUTOS NO EMISSOR — o tempo mora na instância, não no Server.
---
--- Achado nº 5 da triagem: `acender(peca, fator)` multiplicava o `Rate` do
--- autor por um número escrito no Server, e quem faz o efeito não tinha como
--- ajustar sem mexer em Lua.
---
--- Agora o emissor carrega `EmitCount`, `EmitDelay` e `EmitDuration` como
--- ATRIBUTOS, editáveis no painel de propriedades do Studio. E atributo viaja
--- com a instância, então ele atravessa o depósito da regra nº 2 de graça.
---
--- Sem atributo nenhum, o comportamento é o de antes: liga e deixa o `Rate`.
local function acender(peca, fator)
	if not peca then return end
	for _, filho in ipairs(peca:GetDescendants()) do
		if filho:IsA("ParticleEmitter") then
			local atraso = filho:GetAttribute("EmitDelay") or 0
			local conta = filho:GetAttribute("EmitCount")
			local duracao = filho:GetAttribute("EmitDuration")

			local function ligar()
				if not (filho and filho.Parent) then return end
				if conta and conta > 0 then
					-- `:Emit` é do CLIENTE. No servidor ele não replica, e foi
					-- esse o bug de uma leva inteira aqui.
					filho:Emit(conta)
					return
				end
				filho.Enabled = true
				if fator and fator ~= 1 then
					filho.Rate = filho.Rate * fator
				end
				if duracao and duracao > 0 then
					task.delay(duracao, function()
						if filho and filho.Parent then filho.Enabled = false end
					end)
				end
			end

			if atraso > 0 then
				task.delay(atraso, ligar)
			else
				ligar()
			end
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA
--
-- `workspace.CurrentCamera` é singleton por cliente, e este módulo roda em
-- cliente. Multiplicação relativa, some sozinho, e nada aqui escreve
-- `CameraType`.
--═══════════════════════════════════════════════════════════════

local tremorAtivo = nil

local function tremor(forca, duracao)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
	if not workspace.CurrentCamera then return end

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
		local x = math.sin(passado * 61.3) * a
		local y = math.sin(passado * 47.7 + 1.3) * a
		local z = math.sin(passado * 53.1 + 2.6) * a * 0.4
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(
			math.rad(x), math.rad(y), math.rad(z))
	end)
end

--═══════════════════════════════════════════════════════════════
-- ⭐ A FAGULHA — centenas subindo, movidas em UMA chamada
--═══════════════════════════════════════════════════════════════

local function novaFagulha(cor)
	local m = molde("Fagulha", { Color = cor })
	if m then return m end
	return novaParte({
		Size = Vector3.new(0.14, 0.14, 0.14),
		Color = cor,
		Transparency = 0,
	})
end

--- Onde a fagulha `i` está no instante `t`.
---
--- Ela SOBE e ABRE, e o desvio lateral cresce com a altura — é o que faz a
--- coluna de fogo ter forma de pena em vez de forma de cano. E o `sobe` de
--- cada fagulha é diferente (o `% 5`), senão todas chegam ao topo juntas e a
--- coluna pisca em vez de fluir.
local function quadroDaFagulha(centro, raio, i, t, altura)
	local a = angulo(i)
	local sobe = 0.55 + (i % 5) * 0.22
	local h = (t * sobe * altura) % altura
	local fracao = h / altura
	-- abre com a altura, e ondula: o seno é o que tira a linha reta
	local r = raio * (0.15 + fracao * 0.85)
		* (1 + math.sin(t * 3.1 + a) * 0.18)
	local pos = centro + Vector3.new(
		math.cos(a + t * 0.6) * r,
		h,
		math.sin(a + t * 0.6) * r)
	return CFrame.new(pos) * CFrame.Angles(a, a * 0.7, a * 0.4)
end

local function camadaFagulha(centro, raio, altura, base, vida, cor, d)
	local quantos = densidade(centro, base)
	if limalhaViva + quantos > CFG.TETO_LIMALHA then
		quantos = math.max(0, CFG.TETO_LIMALHA - limalhaViva)
	end
	if quantos <= 0 then return end

	local fagulhas = table.create(quantos)
	local quadros = table.create(quantos)
	for i = 1, quantos do
		local f = novaFagulha(cor or CFG.CHAMA)
		if not f then break end
		f.CFrame = quadroDaFagulha(centro, raio, i, 0, altura)
		fagulhas[i] = f
		quadros[i] = f.CFrame
		registrar(f, vida + 0.5)
		anotar(d, f)
	end
	if #fagulhas == 0 then return end
	limalhaViva = limalhaViva + #fagulhas

	local passado = 0
	local conexao
	conexao = RunService.Heartbeat:Connect(function(dt)
		passado = passado + dt
		if passado >= vida then
			conexao:Disconnect()
			limalhaViva = math.max(0, limalhaViva - #fagulhas)
			for _, f in ipairs(fagulhas) do
				if f and f.Parent then f.Parent = nil end
			end
			return
		end

		local restante = 1 - (passado / vida)
		local transp = restante > 0.3 and 0 or (1 - restante / 0.3)

		local n = 0
		for i, f in ipairs(fagulhas) do
			if f and f.Parent then
				n = n + 1
				fagulhas[n] = f
				quadros[n] = quadroDaFagulha(centro, raio, i, passado, altura)
				if transp > 0 then f.Transparency = transp end
			end
		end
		for k = #fagulhas, n + 1, -1 do
			fagulhas[k] = nil
			quadros[k] = nil
		end
		if n == 0 then return end
		workspace:BulkMoveTo(fagulhas, quadros,
			Enum.BulkMoveMode.FireCFrameChanged)
	end)
	anotar(d, nil, conexao)
end

--═══════════════════════════════════════════════════════════════
-- AS TRÊS TEMPERATURAS
--
-- Núcleo, labareda e fumaça têm cor, prazo e velocidade DIFERENTES. Desenhar
-- as três iguais é o que produz a bola laranja que todo jogo tem.
--═══════════════════════════════════════════════════════════════

--- O NÚCLEO: quase branco, pequeno, e quase parado.
local function camadaNucleo(ponto, tamanho, vida, d)
	local n = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(tamanho, tamanho, tamanho),
		Color = CFG.NUCLEO,
		Transparency = 0.05,
		CFrame = CFrame.new(ponto),
	})
	registrar(n, (vida or 0.3) + 0.3)
	anotar(d, n)
	tween(n, vida or 0.3, {
		Size = Vector3.new(tamanho * 0.2, tamanho * 0.2, tamanho * 0.2),
		Transparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	return n
end

--- A LABAREDA: laranja, sobe RÁPIDO, e some. É ela que dá a direção.
local function camadaLabareda(ponto, cor, tamanho, quantos, vida, d)
	local n = densidade(ponto, quantos or 6)
	for i = 1, n do
		local a = angulo(i)
		local lado = tamanho * 0.34
		local lingua = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(lado, lado * 1.5, lado),
			Color = cor or CFG.CHAMA,
			Transparency = 0.16,
			CFrame = CFrame.new(ponto + Vector3.new(
				math.cos(a) * tamanho * 0.3, 0, math.sin(a) * tamanho * 0.3)),
		})
		registrar(lingua, (vida or 0.42) + 0.3)
		anotar(d, lingua)
		-- sobe TORTO: o desvio lateral é o que tira a leitura de jato de gás
		tween(lingua, vida or 0.42, {
			CFrame = CFrame.new(ponto + Vector3.new(
				math.cos(a) * tamanho * 0.9,
				tamanho * (1.4 + (i % 3) * 0.3),
				math.sin(a) * tamanho * 0.9)),
			Size = Vector3.new(lado * 0.2, lado * 0.4, lado * 0.2),
			Transparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

--- A FUMAÇA: cinza, sobe DEVAGAR, e dura o TRIPLO. É ela que faz o efeito
--- continuar existindo depois de o fogo acabar — sem ela o fogo pisca e some,
--- e o lugar volta a parecer intocado no quadro seguinte.
local function camadaFumaca(ponto, tamanho, quantos, vida, d)
	local n = densidade(ponto, quantos or 5)
	for i = 1, n do
		local a = angulo(i * 2)
		local lado = tamanho * 0.5
		local nuvem = novaParte({
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(lado, lado, lado),
			Color = CFG.FUMACA,
			Transparency = 0.55,
			CFrame = CFrame.new(ponto),
		})
		registrar(nuvem, (vida or 1.3) + 0.4)
		anotar(d, nuvem)
		tween(nuvem, vida or 1.3, {
			CFrame = CFrame.new(ponto + Vector3.new(
				math.cos(a) * tamanho * 0.8,
				tamanho * 1.8,
				math.sin(a) * tamanho * 0.8)),
			Size = Vector3.new(lado * 2.4, lado * 2.4, lado * 2.4),
			Transparency = 1,
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
end

--- O ANEL DE BRASA no chão: pressão, não magia.
local function camadaAnelBrasa(ponto, cor, raio, espessura, vida, d)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1.2, 1.2),
		Color = branco(cor or CFG.BRASA, 0.2),
		Transparency = 0.2,
		CFrame = CFrame.new(ponto) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(anel, (vida or 0.5) + 0.4)
	anotar(d, anel)
	tween(anel, vida or 0.5, {
		Size = Vector3.new(espessura or 0.3, raio * 2, raio * 2),
		Transparency = 1,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return anel
end

--- A LINHA ACESA: a muralha, o risco no chão.
local function camadaLinhaFogo(de, ate, cor, altura, vida, d)
	local delta = ate - de
	local dist = delta.Magnitude
	if dist < 0.5 then return end
	local passos = densidade(de, math.max(4, math.floor(dist / 2.4)))
	for i = 1, passos do
		local t = (i - 0.5) / passos
		local p = de + delta * t
		local atraso = t * 0.12
		task.delay(atraso, function()
			camadaLabareda(p, cor or CFG.CHAMA, altura or 3, 4,
				(vida or 1.0) * 0.5, d)
			if i % 2 == 0 then
				camadaFumaca(p, (altura or 3) * 0.6, 2, (vida or 1.0), d)
			end
		end)
	end
end

--- O RASTRO do que voa: núcleo pequeno, sem labareda (custaria caro por
--- quadro), e a fumaça fica para trás.
local function camadaRastro(ponto, cor, d)
	local n = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.9, 0.9, 0.9),
		Color = cor or CFG.CHAMA,
		Transparency = 0.24,
		CFrame = CFrame.new(ponto),
	})
	registrar(n, 0.5)
	anotar(d, n)
	tween(n, 0.34, { Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS — o que o Server despacha por nome
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

--- O golpe curto: núcleo, labareda, e o anel raso.
function Efeitos.GOLPE(d)
	local ponto = d.ponto or Vector3.new()
	camadaNucleo(ponto, 1.6, 0.24, d)
	camadaLabareda(ponto, CFG.CHAMA, 2.4, 6, 0.4, d)
	camadaAnelBrasa(ponto, CFG.BRASA, 4.5, 0.24, 0.34, d)
	camadaFumaca(ponto, 1.6, 3, 1.1, d)
	pk("Small_Slash", ponto)
	tremor(0.4, 0.2)
end

--- O JATO: o cone contínuo. Ele é o efeito mais caro do conjunto, e por isso
--- é o único que respeita o LOD duas vezes — nas fagulhas E nas labaredas.
function Efeitos.JATO(d)
	local origem = d.ponto or Vector3.new()
	local dir = (d.direcao or Vector3.new(0, 0, -1))
	if dir.Magnitude < 0.01 then dir = Vector3.new(0, 0, -1) end
	dir = dir.Unit
	local alcance = d.alcance or 22

	local passos = densidade(origem, 7)
	for i = 1, passos do
		local t = i / passos
		local p = origem + dir * (alcance * t)
		task.delay(t * 0.1, function()
			camadaLabareda(p, i > passos * 0.6 and CFG.BRASA or CFG.CHAMA,
				1.6 + t * 3.4, 4, 0.34, d)
		end)
	end
	camadaNucleo(origem + dir * 1.5, 1.2, 0.2, d)
	camadaFagulha(origem + dir * (alcance * 0.5), alcance * 0.3, 6,
		90, 0.7, CFG.BRASA, d)
	pk("Laser_Shot", origem + dir * alcance)
end

function Efeitos.COMBUSTAO(d)
	local ponto = d.ponto or Vector3.new()
	camadaNucleo(ponto, 4.2, 0.3, d)
	camadaAnelBrasa(ponto, CFG.CHAMA, d.raio or 16, 0.7, 0.5, d)
	camadaAnelBrasa(ponto, CFG.BRANCO, (d.raio or 16) * 0.5, 1.1, 0.34, d)
	camadaFagulha(ponto, (d.raio or 16) * 0.5, 10, 200, 1.0, CFG.CHAMA, d)
	camadaFumaca(ponto, 5, 8, 1.8, d)
	pk("Shockwave_Explosion", ponto)
	tremor(1.3, 0.7)
end

--- O voo da bola: só rastro. Labareda por quadro seria custo de nada.
function Efeitos.LANCA(d)
	camadaRastro(d.ponto or Vector3.new(), CFG.CHAMA, d)
end

function Efeitos.IMPACTO(d)
	local ponto = d.ponto or Vector3.new()
	camadaNucleo(ponto, 2.6, 0.26, d)
	camadaLabareda(ponto, CFG.BRASA, 3.4, 8, 0.44, d)
	camadaAnelBrasa(ponto, CFG.BRASA, d.raio or 10, 0.5, 0.46, d)
	camadaFumaca(ponto, 3, 5, 1.4, d)
	pk("Smoky_Explosion", ponto)
	tremor(0.9, 0.4)
end

function Efeitos.ESTILHACO(d)
	local ponto = d.ponto or Vector3.new()
	for i = 1, 5 do
		local a = angulo(i)
		local p = ponto + Vector3.new(math.cos(a), 0.3, math.sin(a))
			* ((d.raio or 12) * 0.55)
		task.delay((i - 1) * 0.05, function()
			camadaNucleo(p, 1.8, 0.22, d)
			camadaLabareda(p, CFG.CHAMA, 2.6, 5, 0.38, d)
		end)
	end
	camadaAnelBrasa(ponto, CFG.CHAMA, d.raio or 12, 0.6, 0.5, d)
	pk("Shockwave_2", ponto)
	tremor(1.0, 0.5)
end

--- A linha no chão, e a muralha que sobe dela.
function Efeitos.RISCO(d)
	camadaLinhaFogo(d.de or Vector3.new(), d.ate or Vector3.new(),
		CFG.CHAMA, 2.4, d.vida or 1.0, d)
	pk("Floor_Crack", d.de)
end

function Efeitos.MURALHA(d)
	camadaLinhaFogo(d.de or Vector3.new(), d.ate or Vector3.new(),
		CFG.BRASA, 6, d.vida or 4.0, d)
	local meio = ((d.de or Vector3.new()) + (d.ate or Vector3.new())) * 0.5
	camadaFagulha(meio, 6, 7, 160, d.vida or 4.0, CFG.CHAMA, d)
	tremor(0.7, 0.5)
end

--- METEORO: a marca vem ANTES, e ela é o aviso.
function Efeitos.MARCA(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelBrasa(ponto, CFG.BRASA, d.raio or 14, 0.3, d.vida or 0.9, d)
	pk("Sonar_Ring", ponto)
end

function Efeitos.QUEDA(d)
	local ponto = d.ponto or Vector3.new()
	-- a pedra caindo, em segmentos que acendem de cima para baixo
	local passos = 10
	for i = passos, 1, -1 do
		local y = i * 22
		task.delay((passos - i) * 0.03, function()
			camadaNucleo(ponto + Vector3.new(0, y, 0), 3.2, 0.28, d)
			camadaRastro(ponto + Vector3.new(0, y, 0), CFG.BRASA, d)
		end)
	end
	task.delay(0.34, function()
		camadaNucleo(ponto, 6, 0.4, d)
		camadaAnelBrasa(ponto, CFG.BRASA, d.raio or 18, 0.9, 0.6, d)
		camadaAnelBrasa(ponto, CFG.CHAMA, (d.raio or 18) * 0.5, 1.3, 0.4, d)
		camadaFagulha(ponto, (d.raio or 18) * 0.5, 12, 240, 1.2, CFG.BRASA, d)
		camadaFumaca(ponto, 6, 10, 2.2, d)
		pk("Shockwave_Explosion", ponto)
		tremor(1.6, 0.9)
	end)
end

--- FÊNIX
function Efeitos.ASA(d)
	local ponto = d.ponto or Vector3.new()
	for lado = -1, 1, 2 do
		local q = (d.quadro or CFrame.new(ponto))
			* CFrame.Angles(0, 0, math.rad(24 * lado))
		local pena = novaParte({
			Size = Vector3.new(7, 0.2, 0.6),
			Color = branco(CFG.CHAMA, 0.3),
			Transparency = 0.12,
			CFrame = q,
		})
		registrar(pena, 0.5)
		anotar(d, pena)
		tween(pena, 0.28, {
			Size = Vector3.new(10, 0.02, 1.6), Transparency = 1,
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
	camadaLabareda(ponto, CFG.CHAMA, 2.2, 5, 0.36, d)
	pk("Small_Slash", ponto)
end

function Efeitos.RENASCER(d)
	local ponto = d.ponto or Vector3.new()
	camadaNucleo(ponto, 4.6, 0.5, d)
	camadaFagulha(ponto, 5, 14, 220, d.vida or 1.6, CFG.NUCLEO, d)
	camadaAnelBrasa(ponto, CFG.NUCLEO, 10, 0.5, 0.6, d)
	camadaFumaca(ponto, 4, 6, 1.8, d)
	pk("Small_Nova", ponto)
	tremor(0.8, 0.6)
end

--- INFERNO — o único AZUL, e a cor é a informação: fogo azul é mais quente.
function Efeitos.CHICOTE(d)
	local ponto = d.ponto or Vector3.new()
	camadaNucleo(ponto, 1.8, 0.22, d)
	camadaLabareda(ponto, CFG.AZUL_Q, 2.8, 7, 0.4, d)
	camadaAnelBrasa(ponto, CFG.AZUL_Q, 6, 0.26, 0.36, d)
	pk("Small_Slash", ponto)
	tremor(0.5, 0.24)
end

function Efeitos.INFERNO(d)
	local ponto = d.ponto or Vector3.new()
	camadaFagulha(ponto, d.raio or 20, 14, 300, d.vida or 3.0, CFG.AZUL_Q, d)
	camadaAnelBrasa(ponto, CFG.AZUL_Q, d.raio or 20, 0.8, 0.7, d)
	camadaNucleo(ponto, 5, 0.6, d)
	camadaFumaca(ponto, 7, 10, 2.6, d)
	pk("Spiral_Effect", ponto)
	tremor(1.2, d.vida or 3.0)
end

--- A QUEIMADURA vista de fora: quanto mais camadas, mais alto o fogo.
function Efeitos.QUEIMA(d)
	local ponto = d.ponto or Vector3.new()
	local camadas = math.clamp(d.camadas or 1, 1, 5)
	camadaLabareda(ponto, camadas >= 4 and CFG.AZUL_Q or CFG.CHAMA,
		1.2 + camadas * 0.5, 2 + camadas, 0.5, d)
	if camadas >= 3 then
		camadaFumaca(ponto, 1.6, 2, 1.2, d)
	end
end

--- Comum às sete: a força vista de fora.
function Efeitos.EMPURRAO(d)
	local ponto = d.ponto or Vector3.new()
	camadaRastro(ponto, CFG.BRASA, d)
end

--═══════════════════════════════════════════════════════════════
-- DESPACHO
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Fogo] falha em " .. tostring(tipo)
			.. ": " .. tostring(err))
	end
	return ok
end

function VFX.Parar(id)
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

function VFX.LimparTudo()
	for id in pairs(PorId) do VFX.Parar(id) end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then inst.Parent = nil end
	end
	table.clear(Vivos)
	limalhaViva = 0
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
end

return VFX
