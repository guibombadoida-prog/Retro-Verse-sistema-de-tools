-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto REALITY
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: DESENHAR FORÇA, NÃO LUZ
--═══════════════════════════════════════════════════════════════
--
--   Todo conjunto anterior deste repositório desenha LUZ: clarão, nova, feixe,
--   fagulha. Funciona, e é a linguagem certa para magia.
--
--   Este conjunto é de FÍSICA, e luz mente sobre física. O que o jogador
--   precisa ver aqui não é que algo brilhou — é que algo foi EMPURRADO, e com
--   quanta força. Isso se desenha com três coisas, e nenhuma delas é brilho:
--
--     1. LINHA DE FORÇA — o vetor visível. De onde sai, para onde vai, e
--        quanto ela ESTICA. A linha da garra fina quando a peça é leve e
--        engrossa quando é pesada, porque é a única leitura de massa que
--        cabe num quadro.
--
--     2. ANEL NO CHÃO — a onda de choque não é uma esfera. Esfera lê como
--        explosão de magia; anel RENTE AO CHÃO lê como pressão, e é o que
--        um impacto de verdade faz na poeira.
--
--     3. DESTROÇO — pedaço voando. E aqui está a regra dura deste conjunto:
--        **o destroço é SEMPRE cosmético.** Nada aqui quebra peça do mapa.
--        O que voa é uma cópia que o cliente desenhou e o `Debris` recolhe;
--        a peça de verdade continua onde estava.
--
--   As camadas:
--
--     `camadaLinhaForca`   o vetor entre a arma e a coisa — engrossa com a massa
--     `camadaAnelChoque`   o anel rente ao chão, a pressão do impacto
--     `camadaDestroco`     pedaço COSMÉTICO voando — nada do mapa é tocado
--     `camadaVinco`        o vinco do golpe, curto e reto
--     `camadaFeixeOrbital` a coluna que desce, em segmentos
--     `camadaPoco`         o poço de gravidade: anéis que CONTRAEM
--     `camadaCipo`         o cipó entre o tronco e quem foi amarrado
--     `camadaQuique`       a marca de cada ricochete
--     `camadaMarca`        o retículo no chão, antes da coisa cair
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `:Destroy()` de peça do mundo — nem cosmética: `Parent = nil` e
--   `Debris`. Zero `tick()`. Zero `wait/spawn/delay`. Zero `ScreenGui`,
--   `ColorCorrection` e `Sky`. Zero `Instance.new("Explosion")`.
--
--   `math.random` é permitido pelas regras novas, e este módulo NÃO o usa:
--   o destroço tem de cair no mesmo lugar na tela de todo mundo, senão dois
--   jogadores discutem sobre onde estava o pedaço. Ângulo áureo.

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
	LIMITE_VIVOS = 260,

	ACO      = Color3.fromRGB(158, 168, 182),
	AZUL_GAR = Color3.fromRGB(96, 214, 232),
	LARANJA  = Color3.fromRGB(255, 150, 62),
	POEIRA   = Color3.fromRGB(154, 142, 124),
	ROXO     = Color3.fromRGB(148, 96, 224),
	VERDE    = Color3.fromRGB(104, 176, 92),
	PRETO    = Color3.fromRGB(18, 16, 24),
	BRANCO   = Color3.fromRGB(238, 242, 248),
	VERMELHO = Color3.fromRGB(226, 74, 62),

	T_ANEL     = 0.5,
	T_DESTROCO = 1.1,
	T_VINCO    = 0.22,
}

local Vivos, PorId, contador = {}, {}, 0

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
		warn("[" .. script.Name .. "/Reality] pack " .. tostring(nome) .. ": "
			.. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- MOLDES — a geometria que veio da origem
--
-- DUAS PORTAS, de novo. O depósito MOVE `Moldes` para fora da Tool quando ela
-- chega ao jogador; sem a primeira porta a `Arvore Maligna` pararia de achar
-- as próprias `UnionOperation`.
--
-- Na ENTREGA os moldes são invisíveis e ancorados (`Transparency = 1`). Quem
-- os acende é `molde()`, no instante da habilidade — que é exatamente a regra
-- "invisível dentro da Tool, visível na execução".
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
	else
		for _, filho in ipairs(copia:GetDescendants()) do
			if filho:IsA("BasePart") then
				filho.Anchored = true
				filho.CanCollide = false
				filho.CanTouch = false
				filho.CanQuery = false
				if visivel ~= false then filho.Transparency = 0 end
			end
		end
	end
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	copia.Parent = workspace
	return copia
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
-- AS CAMADAS
--═══════════════════════════════════════════════════════════════

--- LINHA DE FORÇA — o vetor visível, e ele ENGROSSA COM A MASSA.
---
--- Herdado do `LineConnect` da `Physics Gun` da origem, com o acréscimo que
--- faz dela uma leitura e não um enfeite: a espessura sai de `massa`. Peça
--- leve dá um fio; peça pesada dá um cabo. É a única forma de o jogador saber
--- quanto pesa o que ele está segurando sem que ninguém escreva um número.
local function camadaLinhaForca(de, ate, cor, massa, vida, d)
	local delta = ate - de
	local dist = delta.Magnitude
	if dist < 0.05 then return nil end

	local grossura = math.clamp(0.12 + (massa or 1) * 0.012, 0.12, 1.1)
	local linha = novaParte({
		Size = Vector3.new(grossura, grossura, dist),
		Color = cor or CFG.AZUL_GAR,
		Transparency = 0.24,
		CFrame = CFrame.new(de + delta * 0.5, ate),
	})
	registrar(linha, (vida or 0.3) + 0.3)
	anotar(d, linha)
	if vida then
		tween(linha, vida, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
	return linha
end

--- ANEL NO CHÃO — pressão, não explosão.
---
--- Rente ao chão e achatado. Uma esfera no mesmo lugar leria como magia; o
--- anel lê como o ar sendo empurrado, que é o que a força fez.
local function camadaAnelChoque(ponto, cor, raio, espessura, vida, d)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1.2, 1.2),
		Color = branco(cor or CFG.POEIRA, 0.3),
		Transparency = 0.2,
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

--- DESTROÇO — pedaço voando, e ele é SEMPRE cosmético.
---
--- ISTO É A REGRA DURA DO CONJUNTO. Nada aqui quebra peça do mapa: o que voa
--- é uma `Part` que este cliente criou e o `Debris` recolhe. A origem fazia o
--- contrário — `moller` clonava a peça de verdade e apagava a original — e é
--- exatamente o que foi mandado parar de fazer.
local function camadaDestroco(ponto, cor, forca, quantos, vida, d)
	for i = 1, (quantos or 10) do
		local a = angulo(i)
		local alto = 0.4 + (i % 5) * 0.14
		local dir = Vector3.new(math.cos(a), alto, math.sin(a)).Unit
		local lado = 0.22 + (i % 4) * 0.1

		local caco = novaParte({
			Material = Enum.Material.Slate,
			Size = Vector3.new(lado, lado * 0.7, lado * 1.2),
			Color = cor or CFG.POEIRA,
			Transparency = 0.05,
			CFrame = CFrame.new(ponto) * CFrame.Angles(a, a * 0.7, a * 0.3),
		})
		registrar(caco, (vida or CFG.T_DESTROCO) + 0.3)
		anotar(d, caco)

		local longe = ponto + dir * (forca or 8)
		-- a queda: sobe e volta, em dois tempos, sem simular gravidade
		tween(caco, (vida or CFG.T_DESTROCO) * 0.45, {
			CFrame = CFrame.new(longe) * CFrame.Angles(a * 2, a, a * 1.4),
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay((vida or CFG.T_DESTROCO) * 0.45, function()
			if caco and caco.Parent then
				tween(caco, (vida or CFG.T_DESTROCO) * 0.55, {
					CFrame = CFrame.new(longe - Vector3.new(0, 3.2, 0))
						* CFrame.Angles(a * 3, a * 1.6, a * 2),
					Transparency = 1,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end)
	end
end

--- VINCO — o golpe, curto e reto. Um plano fino no eixo da mão.
local function camadaVinco(quadro, cor, comprimento, vida, d)
	local vinco = novaParte({
		Size = Vector3.new(comprimento or 7, 0.16, 0.5),
		Color = branco(cor or CFG.BRANCO, 0.4),
		Transparency = 0.14,
		CFrame = quadro,
	})
	registrar(vinco, (vida or CFG.T_VINCO) + 0.3)
	anotar(d, vinco)
	tween(vinco, vida or CFG.T_VINCO, {
		Size = Vector3.new((comprimento or 7) * 1.5, 0.02, 1.6),
		Transparency = 1,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return vinco
end

--- FEIXE ORBITAL — a coluna que desce, EM SEGMENTOS.
---
--- Segmentada de propósito: uma coluna inteira que aparece de uma vez não tem
--- direção, e o feixe deste conjunto vem de cima. Cada segmento acende com
--- atraso proporcional à altura, e o olho lê a descida.
local function camadaFeixeOrbital(ponto, cor, altura, largura, vida, d)
	local passos = 14
	local trecho = (altura or 300) / passos
	for i = passos, 1, -1 do
		local y = (i - 0.5) * trecho
		local atraso = (passos - i) * 0.018
		task.delay(atraso, function()
			local seg = novaParte({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(trecho, largura or 6, largura or 6),
				Color = branco(cor or CFG.AZUL_GAR, 0.25),
				Transparency = 0.18,
				CFrame = CFrame.new(ponto + Vector3.new(0, y, 0))
					* CFrame.Angles(0, 0, math.rad(90)),
			})
			registrar(seg, (vida or 0.7) + 0.4)
			anotar(d, seg)
			tween(seg, vida or 0.7, {
				Size = Vector3.new(trecho, (largura or 6) * 0.2, (largura or 6) * 0.2),
				Transparency = 1,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
	end
end

--- POÇO DE GRAVIDADE — anéis que CONTRAEM.
---
--- Todo anel deste repositório se abre. Este é o único que fecha, e a inversão
--- é o efeito inteiro: anel que cresce lê como "saia daqui", anel que encolhe
--- lê como "você está sendo puxado". A física por baixo puxa; o desenho tem
--- de concordar com ela.
local function camadaPoco(ponto, cor, raio, quantos, vida, d)
	local nucleo = novaParte({
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Glass,
		Size = Vector3.new(0.4, 0.4, 0.4),
		Color = CFG.PRETO,
		Transparency = 0.1,
		CFrame = CFrame.new(ponto),
	})
	registrar(nucleo, (vida or 1.6) + 0.5)
	anotar(d, nucleo)
	tween(nucleo, (vida or 1.6) * 0.3, {
		Size = Vector3.new(2.6, 2.6, 2.6),
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay((vida or 1.6) * 0.75, function()
		if nucleo and nucleo.Parent then
			tween(nucleo, (vida or 1.6) * 0.25, {
				Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		end
	end)

	for i = 1, (quantos or 5) do
		local atraso = (i - 1) * ((vida or 1.6) / (quantos or 5)) * 0.55
		local a = angulo(i)
		task.delay(atraso, function()
			local anel = novaParte({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.22, raio * 2, raio * 2),
				Color = branco(cor or CFG.ROXO, 0.2),
				Transparency = 0.42,
				CFrame = CFrame.new(ponto)
					* CFrame.Angles(a * 0.2, a, math.rad(90) + a * 0.15),
			})
			registrar(anel, (vida or 1.6) + 0.4)
			anotar(d, anel)
			tween(anel, (vida or 1.6) * 0.6, {
				Size = Vector3.new(0.06, 0.5, 0.5),
				Transparency = 1,
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
	end
end

--- CIPÓ — a corda entre o tronco e quem foi amarrado.
---
--- Ela é desenhada em GOMOS, e os gomos ficam menores perto do alvo. Uma linha
--- reta não leria como cipó, e o afinamento é o que diz para onde ele cresceu.
local function camadaCipo(de, ate, cor, gomos, vida, d)
	local delta = ate - de
	local n = gomos or 7
	for i = 1, n do
		local t0 = (i - 1) / n
		local t1 = i / n
		local p0 = de + delta * t0
		local p1 = de + delta * t1
		local meio = (p0 + p1) * 0.5
		-- a barriga do cipó: ele não vai reto, cede no meio
		local cede = math.sin(t0 * math.pi) * (delta.Magnitude * 0.09)
		meio = meio - Vector3.new(0, cede, 0)
		local grossura = 0.44 * (1 - t0 * 0.6)

		local gomo = novaParte({
			Material = Enum.Material.Grass,
			Size = Vector3.new(grossura, grossura, (p1 - p0).Magnitude * 1.15),
			Color = (cor or CFG.VERDE):Lerp(CFG.PRETO, t0 * 0.35),
			Transparency = 1,
			CFrame = CFrame.new(meio, p1),
		})
		registrar(gomo, (vida or 1.2) + 0.4)
		anotar(d, gomo)
		task.delay(t0 * 0.16, function()
			if gomo and gomo.Parent then
				tween(gomo, 0.1, { Transparency = 0.05 })
			end
		end)
		task.delay((vida or 1.2) * 0.7, function()
			if gomo and gomo.Parent then
				tween(gomo, (vida or 1.2) * 0.3, { Transparency = 1 },
					Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			end
		end)
	end
end

--- QUIQUE — a marca de cada ricochete.
---
--- Sem ela o jogador não vê a peça bater na parede, vê a peça mudar de direção
--- por conta própria. É o que transforma "bugou" em "quicou".
local function camadaQuique(ponto, normal, cor, d)
	local marca = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.12, 0.6, 0.6),
		Color = branco(cor or CFG.LARANJA, 0.4),
		Transparency = 0.16,
		CFrame = CFrame.new(ponto, ponto + (normal or Vector3.new(0, 1, 0)))
			* CFrame.Angles(0, math.rad(90), 0),
	})
	registrar(marca, 0.6)
	anotar(d, marca)
	tween(marca, 0.34, {
		Size = Vector3.new(0.02, 4.2, 4.2), Transparency = 1,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

--- MARCA — o retículo no chão, ANTES de a coisa cair.
---
--- Existe para dar tempo de sair. Ultimate que cai sem aviso é ultimate que o
--- alvo não teve como jogar contra.
local function camadaMarca(ponto, cor, raio, vida, d)
	local fora = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.1, raio * 2.4, raio * 2.4),
		Color = cor or CFG.VERMELHO,
		Transparency = 0.62,
		CFrame = CFrame.new(ponto) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(fora, (vida or 0.8) + 0.3)
	anotar(d, fora)
	tween(fora, vida or 0.8, {
		Size = Vector3.new(0.1, raio * 2, raio * 2), Transparency = 0.3,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	for i = 1, 4 do
		local a = angulo(i)
		local risco = novaParte({
			Size = Vector3.new(raio * 0.5, 0.1, 0.14),
			Color = branco(cor or CFG.VERMELHO, 0.3),
			Transparency = 0.3,
			CFrame = CFrame.new(ponto) * CFrame.Angles(0, a, 0)
				* CFrame.new(raio * 0.72, 0, 0),
		})
		registrar(risco, (vida or 0.8) + 0.3)
		anotar(d, risco)
		tween(risco, vida or 0.8, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS — o que o Server despacha por nome
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

--- LAPADA — vinco curto, anel raso, e o destroço mínimo do pé raspando.
function Efeitos.TAPA(d)
	local ponto = d.ponto or Vector3.new()
	camadaVinco(d.quadro or CFrame.new(ponto), CFG.BRANCO, 8, CFG.T_VINCO, d)
	camadaAnelChoque(ponto, CFG.POEIRA, 5.5, 0.24, 0.38, d)
	camadaDestroco(ponto, CFG.POEIRA, 5, 6, 0.7, d)
	pk("Small_Slash", ponto)
	tremor(0.5, 0.22)
end

--- GIRO — o que se vê quando o alvo sai RODANDO. Três vincos em hélice.
function Efeitos.GIRO(d)
	local ponto = d.ponto or Vector3.new()
	for i = 1, 3 do
		local a = angulo(i)
		task.delay((i - 1) * 0.05, function()
			camadaVinco(CFrame.new(ponto + Vector3.new(0, (i - 2) * 0.8, 0))
				* CFrame.Angles(0, a, math.rad(18) * (i - 2)),
				CFG.AZUL_GAR, 5, 0.3, d)
		end)
	end
end

--- CANHÃO — a marca vem primeiro, e a coluna só depois.
function Efeitos.MARCA(d)
	camadaMarca(d.ponto or Vector3.new(), CFG.VERMELHO, d.raio or 14,
		d.vida or 0.9, d)
	pk("Sonar_Ring", d.ponto)
end

function Efeitos.FEIXE(d)
	local ponto = d.ponto or Vector3.new()
	camadaFeixeOrbital(ponto, CFG.AZUL_GAR, 300, (d.raio or 14) * 0.5, 0.8, d)
	task.delay(0.26, function()
		camadaAnelChoque(ponto, CFG.AZUL_GAR, d.raio or 14, 0.6, 0.6, d)
		camadaAnelChoque(ponto, CFG.LARANJA, (d.raio or 14) * 0.55, 1.1, 0.44, d)
		camadaDestroco(ponto, CFG.POEIRA, (d.raio or 14) * 0.7, 18, 1.4, d)
		pk("Shockwave_Explosion", ponto)
		tremor(1.4, 0.9)
	end)
end

--- ÁRVORE — o tronco sobe, e os cipós saem dele.
function Efeitos.ARVORE(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelChoque(ponto, CFG.VERDE, 8, 0.4, 0.5, d)
	camadaDestroco(ponto, CFG.POEIRA, 7, 12, 1.0, d)
	pk("Floor_Crack", ponto)

	-- as `UnionOperation` da origem, acesas só agora
	local nomes = { "Phys", "Phys2", "Phys3", "Phys4", "Death" }
	for i, nome in ipairs(nomes) do
		local peca = molde(nome, {
			CFrame = CFrame.new(ponto + Vector3.new(0, -6, 0))
				* CFrame.Angles(0, angulo(i) * 0.1, 0),
		})
		if peca then
			registrar(peca, (d.vida or 6) + 0.6)
			anotar(d, peca)
			tween(peca, 0.4, {
				CFrame = CFrame.new(ponto + Vector3.new(0, i * 0.4, 0))
					* CFrame.Angles(0, angulo(i) * 0.1, 0),
			}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end
	tremor(0.9, 0.6)
end

function Efeitos.CIPO(d)
	camadaCipo(d.de or Vector3.new(), d.ate or Vector3.new(), CFG.VERDE,
		7, d.vida or 1.4, d)
end

--- GATO — a poeira do salto, e nada mais: o gato É o efeito.
function Efeitos.GATO(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelChoque(ponto, CFG.POEIRA, 3.6, 0.2, 0.34, d)
	pk("Small_Nova", ponto)
end

--- SAMSUNGUS — o quique, e o estouro no fim.
function Efeitos.QUIQUE(d)
	camadaQuique(d.ponto or Vector3.new(), d.normal, CFG.LARANJA, d)
end

function Efeitos.ESTOURO(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelChoque(ponto, CFG.LARANJA, d.raio or 10, 0.5, 0.5, d)
	camadaAnelChoque(ponto, CFG.BRANCO, (d.raio or 10) * 0.5, 0.9, 0.34, d)
	camadaDestroco(ponto, CFG.ACO, (d.raio or 10) * 0.8, 14, 1.2, d)
	pk("Smoky_Explosion", ponto)
	tremor(1.0, 0.5)
end

--- ARMA DE FÍSICA — a linha é CONTÍNUA, e por isso é redesenhada por quadro.
---
--- Ela não usa `id` para se manter viva: cada quadro manda um `LINHA` novo com
--- vida curta. É mais tráfego, e é a escolha certa aqui — uma linha guardada
--- por `id` ficaria pendurada se o `SOLTA` se perdesse, e o jogador veria um
--- cabo saindo da arma para o nada até o servidor cair.
function Efeitos.LINHA(d)
	camadaLinhaForca(d.de or Vector3.new(), d.ate or Vector3.new(),
		CFG.AZUL_GAR, d.massa or 1, 0.12, d)
end

function Efeitos.TRAVA(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelChoque(ponto, CFG.AZUL_GAR, 2.4, 0.3, 0.3, d)
	for i = 1, 3 do
		local a = angulo(i)
		camadaVinco(CFrame.new(ponto) * CFrame.Angles(a * 0.4, a, a * 0.2),
			CFG.AZUL_GAR, 2.6, 0.26, d)
	end
end

function Efeitos.SOLTA(d)
	local ponto = d.ponto or Vector3.new()
	camadaLinhaForca(ponto, ponto + (d.direcao or Vector3.new(0, 1, 0)) * 6,
		CFG.BRANCO, (d.massa or 1) * 1.4, 0.24, d)
	camadaAnelChoque(ponto, CFG.AZUL_GAR, 3.4, 0.24, 0.3, d)
end

--- INDUTOR — o poço, e os anéis que fecham.
function Efeitos.POCO(d)
	local ponto = d.ponto or Vector3.new()
	camadaPoco(ponto, CFG.ROXO, d.raio or 18, 6, d.vida or 2.2, d)
	camadaAnelChoque(ponto, CFG.ROXO, (d.raio or 18) * 0.4, 0.3, 0.4, d)
	pk("Spiral_Effect", ponto)
	tremor(0.8, d.vida or 2.2)
end

function Efeitos.COLAPSO(d)
	local ponto = d.ponto or Vector3.new()
	camadaAnelChoque(ponto, CFG.ROXO, d.raio or 18, 0.7, 0.55, d)
	camadaDestroco(ponto, CFG.POEIRA, (d.raio or 18) * 0.5, 16, 1.3, d)
	pk("Shockwave_2", ponto)
	tremor(1.2, 0.6)
end

--- Comum às sete: o empurrão visto de fora.
function Efeitos.EMPURRAO(d)
	local ponto = d.ponto or Vector3.new()
	local dir = d.direcao or Vector3.new(0, 1, 0)
	camadaLinhaForca(ponto, ponto + dir.Unit * math.min((d.forca or 40) * 0.1, 9),
		CFG.BRANCO, (d.forca or 40) * 0.1, 0.2, d)
end

--═══════════════════════════════════════════════════════════════
-- DESPACHO
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Reality] falha em " .. tostring(tipo)
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
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
end

return VFX
