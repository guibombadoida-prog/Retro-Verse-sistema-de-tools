-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto MAGNETISMO
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: A LIMALHA MOSTRA O CAMPO
--═══════════════════════════════════════════════════════════════
--
--   Campo magnético é invisível. Todo mundo que já viu um sabe disso por UMA
--   imagem: limalha de ferro numa folha de papel, sobre um ímã, desenhando as
--   linhas sozinha.
--
--   É a imagem inteira deste conjunto. As outras camadas servem a ela:
--
--     `camadaLimalha`   centenas de agulhas que se ALINHAM à linha de campo
--     `camadaPolo`      o par vermelho/azul que diz de que lado a força puxa
--     `camadaArco`      o raio que salta de alvo em alvo, em zigue-zague
--     `camadaTrilho`    a linha no chão, com as travessas
--     `camadaAnelCampo` o anel que marca a borda do alcance
--     `camadaSucata`    os cacos de metal que orbitam antes de virar bola
--     `camadaColapso`   a limalha toda caindo para dentro de um ponto
--
--═══════════════════════════════════════════════════════════════
-- ⚙️  `workspace:BulkMoveTo` — E POR QUE ESTE MÓDULO É DIFERENTE
--═══════════════════════════════════════════════════════════════
--
--   A limalha são CENTENAS de peças, e todas se movem todo quadro. Escrever
--   `peca.CFrame` trezentas vezes por quadro é trezentas travessias da
--   fronteira Lua↔motor, cada uma com sua invalidação.
--
--   `workspace:BulkMoveTo(partes, quadros, modo)` faz as trezentas em UMA.
--
--   O repositório tinha 2 243 `Instance.new("Part")` nos 33 VFXModules e ZERO
--   `BulkMoveTo` — medido em `FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md`,
--   Parte I §3. Este é o primeiro módulo a usar, e é o caso em que ele
--   realmente importa: sem ele a limalha não seria viável.
--
--   `Enum.BulkMoveMode.FireCFrameChanged` é o modo certo aqui: o mais barato
--   (`FireAllEvents` dispara Touched e afins) sem ser mudo demais.
--
--═══════════════════════════════════════════════════════════════
-- ⚙️  LOD POR DISTÂNCIA DE CÂMERA
--═══════════════════════════════════════════════════════════════
--
--   Achado nº 6 da triagem: todo efeito do repositório desenha igual a 5 e a
--   500 studs. Numa briga de sete pessoas com Tools diferentes, é isso que
--   derruba o quadro — e o jogador nem está olhando para a maioria delas.
--
--   `densidade()` corta a contagem de partícula pela distância da câmera. A
--   30 studs a limalha tem 240 agulhas; a 200 studs tem 36, e ninguém percebe
--   porque a essa distância elas ocupam três pixels.
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `:Destroy()` de peça do mundo. Zero `tick()`. Zero `wait/spawn/delay`.
--   Zero `ScreenGui`, `ColorCorrection` e `Sky`. Zero `Instance.new("Explosion")`.
--
--   `math.random` é permitido pelas regras novas, e este módulo NÃO o usa: a
--   limalha tem de desenhar a MESMA figura na tela de todo mundo, senão duas
--   pessoas discutem sobre onde estava a linha de campo. Ângulo áureo.

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

	FERRO    = Color3.fromRGB(108, 114, 124),
	ACO      = Color3.fromRGB(168, 176, 188),
	NORTE    = Color3.fromRGB(226, 62, 58),
	SUL      = Color3.fromRGB(58, 122, 226),
	COBRE    = Color3.fromRGB(196, 122, 62),
	FAISCA   = Color3.fromRGB(150, 220, 255),
	ROXO     = Color3.fromRGB(148, 96, 224),
	BRANCO   = Color3.fromRGB(238, 242, 248),
	ESCURO   = Color3.fromRGB(28, 26, 34),

	--- LOD: perto de tudo, longe quase nada.
	LOD_PERTO = 40,
	LOD_LONGE = 200,
	LOD_PISO = 0.15,

	--- Teto de agulhas SIMULTÂNEAS no cliente inteiro. A limalha é o efeito
	--- mais caro do repositório, e ela precisa de um freio próprio.
	TETO_LIMALHA = 600,

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
		warn("[" .. script.Name .. "/Magnetismo] pack " .. tostring(nome)
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
-- ⭐ A LIMALHA — o efeito do conjunto, e o único que precisa de BulkMoveTo
--═══════════════════════════════════════════════════════════════

--- A agulha: o molde da Tool, ou uma peça equivalente se ele não vier.
local function novaAgulha(cor)
	local m = molde("Limalha", { Color = cor })
	if m then return m end
	return novaParte({
		Size = Vector3.new(0.08, 0.08, 0.34),
		Material = Enum.Material.Metal,
		Color = cor,
		Transparency = 0,
	})
end

--- Onde a agulha `i` está no instante `t`, e para onde ela aponta.
---
--- A figura é a de um dipolo visto de fora: anéis concêntricos em torno do
--- eixo, e a agulha ALINHADA À TANGENTE. O alinhamento é o efeito inteiro —
--- limalha que não se alinha é confete.
---
--- `sentido` de -1 fecha a espiral para dentro (atração) e +1 abre (repulsão).
local function quadroDaAgulha(centro, eixo, raio, i, quantos, t, sentido)
	local anel = 1 + (i % 4)
	local passo = (i / quantos)
	local a = angulo(i) + t * (1.6 + anel * 0.22) * sentido

	-- o raio respira: cada anel a uma altura, e a espiral encolhe/cresce com t
	local r = raio * (0.28 + anel * 0.19) * (1 + sentido * t * 0.18)
	local alt = (passo - 0.5) * raio * 0.9

	local base = CFrame.new(centro) * CFrame.fromAxisAngle(eixo, a)
	local pos = (base * CFrame.new(r, alt, 0)).Position

	-- a tangente do anel: a direção em que a agulha DEITA
	local adiante = (base * CFrame.new(r, alt, 0.6)).Position - pos
	if adiante.Magnitude < 0.001 then
		adiante = Vector3.new(0, 0, 1)
	end
	return CFrame.new(pos, pos + adiante.Unit)
end

--- A LIMALHA. Cria N agulhas e as move TODAS numa chamada por quadro.
---
--- ⚙️ Este é o corpo do achado nº 3 da triagem. Sem `BulkMoveTo`, 240 agulhas
---    seriam 240 escritas de `CFrame` por quadro — 14 400 por segundo, por
---    jogador que estivesse vendo o efeito. Com ele são 60.
local function camadaLimalha(centro, eixo, raio, base, vida, cor, sentido, d)
	local quantos = densidade(centro, base)
	if limalhaViva + quantos > CFG.TETO_LIMALHA then
		quantos = math.max(0, CFG.TETO_LIMALHA - limalhaViva)
	end
	if quantos <= 0 then return end

	eixo = (eixo and eixo.Magnitude > 0.001) and eixo.Unit or Vector3.new(0, 1, 0)

	local agulhas = table.create(quantos)
	local quadros = table.create(quantos)
	for i = 1, quantos do
		local a = novaAgulha(cor or CFG.FERRO)
		if not a then break end
		a.CFrame = quadroDaAgulha(centro, eixo, raio, i, quantos, 0, sentido)
		agulhas[i] = a
		quadros[i] = a.CFrame
		registrar(a, vida + 0.5)
		anotar(d, a)
	end
	if #agulhas == 0 then return end
	limalhaViva = limalhaViva + #agulhas

	local passado = 0
	local conexao
	conexao = RunService.Heartbeat:Connect(function(dt)
		passado = passado + dt
		if passado >= vida then
			conexao:Disconnect()
			limalhaViva = math.max(0, limalhaViva - #agulhas)
			for _, a in ipairs(agulhas) do
				if a and a.Parent then a.Parent = nil end
			end
			return
		end

		-- o desvanecer: a agulha some no último terço
		local restante = 1 - (passado / vida)
		local transp = restante > 0.34 and 0 or (1 - restante / 0.34)

		local n = 0
		for i, a in ipairs(agulhas) do
			if a and a.Parent then
				n = n + 1
				agulhas[n] = a
				quadros[n] = quadroDaAgulha(centro, eixo, raio, i, #agulhas,
					passado, sentido)
				if transp > 0 then a.Transparency = transp end
			end
		end
		for k = #agulhas, n + 1, -1 do
			agulhas[k] = nil
			quadros[k] = nil
		end
		if n == 0 then return end

		-- ⚙️ UMA chamada para as N agulhas
		workspace:BulkMoveTo(agulhas, quadros,
			Enum.BulkMoveMode.FireCFrameChanged)
	end)
	anotar(d, nil, conexao)
end

--═══════════════════════════════════════════════════════════════
-- AS OUTRAS CAMADAS
--═══════════════════════════════════════════════════════════════

--- O PAR DE PÓLOS: vermelho e azul, e é o que diz para que lado a força puxa.
local function camadaPolo(centro, eixo, tamanho, vida, invertido, d)
	eixo = (eixo and eixo.Magnitude > 0.001) and eixo.Unit or Vector3.new(0, 1, 0)
	local cores = invertido and { CFG.SUL, CFG.NORTE } or { CFG.NORTE, CFG.SUL }
	for lado = 1, 2 do
		local sinal = (lado == 1) and 1 or -1
		local p = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(tamanho, tamanho, tamanho),
			Color = cores[lado],
			Transparency = 0.24,
			CFrame = CFrame.new(centro + eixo * (sinal * tamanho * 0.9)),
		})
		registrar(p, vida + 0.4)
		anotar(d, p)
		tween(p, vida, {
			Size = Vector3.new(tamanho * 0.2, tamanho * 0.2, tamanho * 0.2),
			Transparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end

--- O ANEL que marca a borda do alcance. Rente ao chão: é pressão, não magia.
local function camadaAnelCampo(ponto, cor, raio, espessura, vida, d)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1.2, 1.2),
		Color = branco(cor or CFG.ACO, 0.25),
		Transparency = 0.22,
		CFrame = CFrame.new(ponto) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(anel, (vida or CFG.T_ANEL) + 0.4)
	anotar(d, anel)
	tween(anel, vida or CFG.T_ANEL, {
		Size = Vector3.new(espessura or 0.3, raio * 2, raio * 2),
		Transparency = 1,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return anel
end

--- O ARCO ELÉTRICO: zigue-zague entre dois pontos.
---
--- Segmentado e QUEBRADO. Um raio reto lê como laser; o que faz o olho ler
--- "eletricidade" é o desvio lateral entre segmentos, e ele tem de ser
--- determinístico (ângulo áureo) para todos verem o mesmo raio.
local function camadaArco(de, ate, cor, gomos, vida, d)
	local delta = ate - de
	local dist = delta.Magnitude
	if dist < 0.2 then return end
	local n = gomos or 7
	local lateral = delta.Unit:Cross(Vector3.new(0, 1, 0))
	if lateral.Magnitude < 0.01 then
		lateral = delta.Unit:Cross(Vector3.new(1, 0, 0))
	end
	lateral = lateral.Unit
	local cima = lateral:Cross(delta.Unit).Unit

	local anterior = de
	for i = 1, n do
		local t = i / n
		local alvo = de + delta * t
		if i < n then
			local desvio = dist * 0.06
			local a = angulo(i * 3)
			alvo = alvo + lateral * (math.cos(a) * desvio)
				+ cima * (math.sin(a) * desvio)
		end
		local trecho = alvo - anterior
		local seg = novaParte({
			Size = Vector3.new(0.16, 0.16, trecho.Magnitude),
			Color = branco(cor or CFG.FAISCA, 0.5),
			Transparency = 0.1,
			CFrame = CFrame.new(anterior + trecho * 0.5, alvo),
		})
		registrar(seg, (vida or 0.2) + 0.3)
		anotar(d, seg)
		tween(seg, vida or 0.2, { Transparency = 1, Size = Vector3.new(
			0.02, 0.02, trecho.Magnitude) },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		anterior = alvo
	end
end

--- O TRILHO: a linha no chão, com travessas.
local function camadaTrilho(de, ate, cor, vida, d)
	local delta = ate - de
	local dist = delta.Magnitude
	if dist < 0.5 then return end
	local lado = delta.Unit:Cross(Vector3.new(0, 1, 0))
	if lado.Magnitude < 0.01 then return end
	lado = lado.Unit

	for sinal = -1, 1, 2 do
		local barra = novaParte({
			Size = Vector3.new(0.22, 0.16, dist),
			Material = Enum.Material.Metal,
			Color = cor or CFG.ACO,
			Transparency = 0.1,
			CFrame = CFrame.new(de + delta * 0.5 + lado * (sinal * 0.9), ate),
		})
		registrar(barra, vida + 0.4)
		anotar(d, barra)
		tween(barra, vida, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end

	local travessas = densidade(de, math.max(3, math.floor(dist / 3)))
	for i = 1, travessas do
		local t = (i - 0.5) / travessas
		local trav = novaParte({
			Size = Vector3.new(2.0, 0.12, 0.3),
			Color = branco(cor or CFG.FAISCA, 0.4),
			Transparency = 0.3,
			CFrame = CFrame.new(de + delta * t, de + delta * t + lado),
		})
		registrar(trav, vida + 0.3)
		anotar(d, trav)
		tween(trav, vida * 0.7, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
end

--- A SUCATA que orbita antes de virar bola.
local function camadaSucata(centro, raio, quantos, vida, d)
	local n = densidade(centro, quantos)
	for i = 1, n do
		local a = angulo(i)
		local alto = ((i % 5) - 2) * 0.35
		local lado = 0.24 + (i % 3) * 0.12
		local caco = novaParte({
			Material = Enum.Material.CorrodedMetal,
			Size = Vector3.new(lado, lado * 0.6, lado * 1.3),
			Color = CFG.FERRO,
			Transparency = 0.05,
			CFrame = CFrame.new(centro)
				* CFrame.Angles(0, a, 0)
				* CFrame.new(raio, alto, 0)
				* CFrame.Angles(a, a * 0.7, a * 0.3),
		})
		registrar(caco, vida + 0.3)
		anotar(d, caco)
		-- todos convergem para o centro: é a bola se formando
		tween(caco, vida, {
			CFrame = CFrame.new(centro) * CFrame.Angles(a * 2, a * 1.4, a),
			Transparency = 0.4,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
end

--- O COLAPSO: tudo caindo para dentro de um ponto, e o ponto sumindo.
local function camadaColapso(centro, raio, vida, d)
	local nucleo = novaParte({
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Glass,
		Size = Vector3.new(0.4, 0.4, 0.4),
		Color = CFG.ESCURO,
		Transparency = 0.06,
		CFrame = CFrame.new(centro),
	})
	registrar(nucleo, vida + 0.6)
	anotar(d, nucleo)
	tween(nucleo, vida * 0.35, { Size = Vector3.new(3.4, 3.4, 3.4) },
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(vida * 0.72, function()
		if nucleo and nucleo.Parent then
			tween(nucleo, vida * 0.28, {
				Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
	end)

	-- os anéis que FECHAM, não que abrem: é a leitura de "você está sendo
	-- puxado" em vez de "saia daqui"
	for i = 1, 6 do
		local a = angulo(i)
		task.delay((i - 1) * (vida / 8), function()
			local anel = novaParte({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, raio * 2, raio * 2),
				Color = branco(CFG.ROXO, 0.2),
				Transparency = 0.44,
				CFrame = CFrame.new(centro)
					* CFrame.Angles(a * 0.3, a, math.rad(90) + a * 0.2),
			})
			registrar(anel, vida + 0.4)
			anotar(d, anel)
			tween(anel, vida * 0.55, {
				Size = Vector3.new(0.05, 0.4, 0.4), Transparency = 1,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
	end
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS — o que o Server despacha por nome
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

--- POLO NORTE — a limalha FECHA em espiral para dentro
function Efeitos.PUXAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, d.eixo or Vector3.new(0, 1, 0), d.raio or 12,
		140, 0.8, CFG.FERRO, -1, d)
	camadaPolo(ponto, d.eixo, 2.2, 0.6, false, d)
	camadaAnelCampo(ponto, CFG.NORTE, d.raio or 12, 0.3, 0.45, d)
	pk("Sonar_Ring", ponto)
end

function Efeitos.CUPULA(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 22, 220,
		d.vida or 2.0, CFG.FERRO, -1, d)
	camadaAnelCampo(ponto, CFG.NORTE, d.raio or 22, 0.5, 0.7, d)
	pk("Spiral_Effect", ponto)
	tremor(0.5, d.vida or 2.0)
end

function Efeitos.IMPLOSAO(d)
	local ponto = d.ponto or Vector3.new()
	camadaColapso(ponto, d.raio or 18, 1.1, d)
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 18, 240, 1.0,
		CFG.ACO, -1, d)
	camadaAnelCampo(ponto, CFG.NORTE, d.raio or 18, 0.8, 0.6, d)
	pk("Shockwave_Explosion", ponto)
	tremor(1.4, 0.8)
end

--- POLO SUL — a limalha ABRE
function Efeitos.EMPURRAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, d.eixo or Vector3.new(0, 1, 0), d.raio or 12,
		140, 0.7, CFG.FERRO, 1, d)
	camadaPolo(ponto, d.eixo, 2.2, 0.5, true, d)
	camadaAnelCampo(ponto, CFG.SUL, d.raio or 12, 0.3, 0.4, d)
	pk("Shockwave", ponto)
end

function Efeitos.ESCUDO(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 9, 160,
		d.vida or 2.4, CFG.SUL, 1, d)
	camadaAnelCampo(ponto, CFG.SUL, d.raio or 9, 0.4, 0.5, d)
	pk("Small_Nova", ponto)
end

function Efeitos.ONDA(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelCampo(ponto, CFG.SUL, d.raio or 20, 0.7, 0.55, d)
	camadaAnelCampo(ponto, CFG.BRANCO, (d.raio or 20) * 0.5, 1.1, 0.36, d)
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 20, 220, 0.9,
		CFG.ACO, 1, d)
	pk("Shockwave_2", ponto)
	tremor(1.2, 0.6)
end

--- FERROVIA
function Efeitos.TRILHO(d)
	camadaTrilho(d.de or Vector3.new(), d.ate or Vector3.new(),
		CFG.ACO, d.vida or 5.0, d)
	pk("Floor_Crack", d.de)
end

function Efeitos.MONTAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, d.eixo or Vector3.new(0, 1, 0), 6, 80, 0.6,
		CFG.FAISCA, 1, d)
	camadaAnelCampo(ponto, CFG.FAISCA, 5, 0.25, 0.35, d)
end

function Efeitos.MALHA(d)
	local ponto = d.ponto or Vector3.new()
	for i = 1, 4 do
		local a = angulo(i)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		camadaTrilho(ponto - dir * (d.raio or 16), ponto + dir * (d.raio or 16),
			CFG.ACO, d.vida or 4.0, d)
	end
	camadaAnelCampo(ponto, CFG.FAISCA, d.raio or 16, 0.5, 0.6, d)
	tremor(0.9, 0.5)
end

--- SUCATA
function Efeitos.COLETAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaSucata(ponto, d.raio or 8, 16, 0.6, d)
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 8, 90, 0.7,
		CFG.FERRO, -1, d)
end

function Efeitos.ARREMESSAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelCampo(ponto, CFG.FERRO, 4, 0.3, 0.3, d)
	camadaArco(ponto, ponto + (d.direcao or Vector3.new(0, 1, 0)) * 5,
		CFG.FERRO, 4, 0.2, d)
end

function Efeitos.CHUVA(d)
	local ponto = d.ponto or Vector3.new()
	camadaSucata(ponto + Vector3.new(0, 14, 0), d.raio or 12, 22, 0.9, d)
	task.delay(0.35, function()
		camadaAnelCampo(ponto, CFG.FERRO, d.raio or 12, 0.6, 0.5, d)
		pk("Smoky_Explosion", ponto)
		tremor(1.0, 0.5)
	end)
end

--- BOBINA DE TESLA
function Efeitos.ARCO(d)
	camadaArco(d.de or Vector3.new(), d.ate or Vector3.new(),
		CFG.FAISCA, 8, 0.18, d)
	pk("Laser_Shot", d.ate)
end

function Efeitos.BOBINA(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 10, 120,
		d.vida or 4.0, CFG.COBRE, 1, d)
	camadaAnelCampo(ponto, CFG.FAISCA, d.raio or 10, 0.35, 0.5, d)
end

function Efeitos.DESCARGA(d)
	local ponto = d.ponto or Vector3.new()
	for i, alvo in ipairs(d.alvos or {}) do
		task.delay((i - 1) * 0.04, function()
			camadaArco(ponto + Vector3.new(0, 3, 0), alvo, CFG.FAISCA, 9, 0.24, d)
		end)
	end
	camadaAnelCampo(ponto, CFG.FAISCA, d.raio or 24, 0.6, 0.5, d)
	pk("Shockwave_Explosion", ponto)
	tremor(1.3, 0.7)
end

--- LEVITAÇÃO
function Efeitos.SUSPENDER(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), 5, 70, d.vida or 2.6,
		CFG.FAISCA, 1, d)
	camadaPolo(ponto, Vector3.new(0, 1, 0), 1.6, 0.6, false, d)
end

function Efeitos.FLUTUAR(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), 4, 60, d.vida or 3.0,
		CFG.SUL, 1, d)
	camadaAnelCampo(ponto, CFG.SUL, 4, 0.25, 0.4, d)
end

function Efeitos.INVERTER(d)
	local ponto = d.ponto or Vector3.new()
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 20, 240,
		d.vida or 3.4, CFG.ROXO, 1, d)
	camadaAnelCampo(ponto, CFG.ROXO, d.raio or 20, 0.6, 0.7, d)
	pk("Spiral_Effect", ponto)
	tremor(0.8, 1.0)
end

--- COLAPSO MAGNÉTICO
function Efeitos.CARGA(d)
	local ponto = d.ponto or Vector3.new()
	camadaPolo(ponto, Vector3.new(0, 1, 0), 1.4, 0.5,
		d.polaridade == "SUL", d)
	camadaAnelCampo(ponto, corDoPolo(d.polaridade), 3, 0.25, 0.35, d)
end

function Efeitos.ATRAIR_CARGAS(d)
	local ponto = d.ponto or Vector3.new()
	for i, alvo in ipairs(d.alvos or {}) do
		camadaArco(ponto, alvo, corDoPolo(d.polaridade), 6, 0.3, d)
		if i > 8 then break end
	end
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 24, 200, 1.0,
		CFG.ACO, -1, d)
	tremor(1.0, 0.6)
end

function Efeitos.SINGULARIDADE(d)
	local ponto = d.ponto or Vector3.new()
	camadaColapso(ponto, d.raio or 28, 1.8, d)
	camadaLimalha(ponto, Vector3.new(0, 1, 0), d.raio or 28, 300, 1.6,
		CFG.ACO, -1, d)
	camadaAnelCampo(ponto, CFG.ROXO, d.raio or 28, 1.0, 0.8, d)
	-- ⚠️ AQUI ESTAVA `pk("Supernova", ...)`, e `Supernova` NÃO EXISTE no pack.
	--    `pk` de nome inexistente devolve `false` EM SILÊNCIO — a ultimate
	--    perderia uma camada e ninguém saberia. O `verificar_pack_vfx.py`
	--    pegou; o comentário do topo deste arquivo já listava os dez nomes
	--    reais, e eu usei um décimo primeiro.
	pk("Small_Nova", ponto)
	pk("Shockwave_Explosion", ponto)
	tremor(1.8, 1.4)
end

--- Comum às sete: a força vista de fora. O nome é `EMPURRAO` porque é o do
--- bloco de física compartilhado; aqui ele desenha puxão também.
function Efeitos.EMPURRAO(d)
	local ponto = d.ponto or Vector3.new()
	local dir = d.direcao or Vector3.new(0, 1, 0)
	camadaArco(ponto, ponto + dir.Unit * math.min((d.forca or 40) * 0.12, 10),
		corDoPolo(d.polaridade), 5, 0.18, d)
end

--═══════════════════════════════════════════════════════════════
-- DESPACHO
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Magnetismo] falha em " .. tostring(tipo)
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
