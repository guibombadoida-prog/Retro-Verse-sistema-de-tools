-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto TEMPO
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL VEIO DA ORIGEM, E ELA ACERTOU DUAS COISAS
--═══════════════════════════════════════════════════════════════
--
--   O `timetools.rbxmx` fez duas escolhas que este módulo mantém inteiras,
--   porque as duas são o que faz tempo parecer tempo:
--
--   1. `Enum.Material.ForceField` PARA O QUE ESTÁ CONGELADO.
--
--      `Para o tempo/Main/stopFX` monta a esfera com `Material = ForceField`.
--      Não é enfeite: `ForceField` tem aquele quadriculado que se move
--      sozinho, e sobre um objeto PARADO ele lê como "isto está suspenso",
--      que é exatamente a leitura que a habilidade quer. Neon leria como
--      "isto está aceso".
--
--   2. O FANTASMA VERMELHO, ADIANTADO NO TEMPO.
--
--      `reverter!!` clona o objeto, pinta de `Color3.fromRGB(255,47,47)`,
--      deixa a 0.5 de transparência e o posiciona 40 QUADROS À FRENTE do
--      objeto que está voltando:
--
--          beforeimage.CFrame = positions[frame + 40]
--
--      Sem ele o jogador vê um objeto teleportando; com ele vê DE ONDE ele
--      está voltando. É o detalhe que faz a reversão ser legível, e virou o
--      eixo da Tool `Paradoxo` inteira.
--
--   As camadas daqui:
--
--     `camadaCongelado`  a casca ForceField sobre o que parou
--     `camadaFantasma`   o clone vermelho semitransparente
--     `camadaPonteiro`   o ponteiro varrendo o mostrador
--     `camadaMostrador`  o mostrador com as marcas de hora
--     `camadaAreia`      os grãos da ampulheta
--     `camadaAnel`       o anel que abre
--     `camadaEstilhaco`  os cacos de tempo quebrado
--
--═══════════════════════════════════════════════════════════════
-- OS IDS SÃO DA ORIGEM, E ESTÃO NA FICHA
--═══════════════════════════════════════════════════════════════
--
--   A esfera da parada usa a malha `3732570516` com a textura `5850567969`,
--   que a origem criava em código dentro do `Main`. O fóton é `4610890646`, a
--   lâmina é `2578685003`, o holofote é `1251157745` e o anel é `559831844`.
--   Todos catalogados em `ACERVO_RETROVERSE/Time_Tools/MALHAS/ids.md`.
--
--   Id de malha não se inventa: malha invisível é o equivalente do som mudo,
--   e nenhum verificador estático pega nenhum dos dois.
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   ZERO `ColorCorrectionEffect` e ZERO `BlurEffect`. A origem punha os dois
--   em `game.Lighting` para o efeito de cinza — e `Lighting` é estado do
--   PLACE INTEIRO: quem estivesse do outro lado do mapa ficava sem cor por
--   causa de uma briga alheia, e uma Tool destruída no meio deixava o mundo
--   cinza para sempre. O cinza deste conjunto vive no mundo 3D, em volta de
--   quem foi atingido.
--
--   Zero `ScreenGui`. Zero `math.random` — ângulo áureo. Zero `:Destroy()` —
--   `Parent = nil` e `Debris`. Zero `tick()`.

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
	LIMITE_VIVOS = 250,

	--- as cores da origem, as duas mantidas
	GELO      = Color3.fromRGB(167, 184, 255),   -- a esfera do `Para o tempo`
	FANTASMA  = Color3.fromRGB(255, 47, 47),     -- o `beforeimage` do `reverter!!`

	BRONZE    = Color3.fromRGB(186, 148, 84),
	DOURADO   = Color3.fromRGB(255, 208, 96),
	AREIA     = Color3.fromRGB(226, 206, 156),
	SOL       = Color3.fromRGB(255, 236, 168),
	LUA       = Color3.fromRGB(178, 200, 255),
	CINZA     = Color3.fromRGB(120, 120, 128),

	--- as malhas da ficha
	MESH_ESFERA  = "rbxassetid://3732570516",
	TEX_ESFERA   = "rbxassetid://5850567969",
	MESH_FOTON   = "rbxassetid://4610890646",
	MESH_LAMINA  = "rbxassetid://2578685003",
	MESH_HOLOFOTE = "rbxassetid://1251157745",
	MESH_ANEL    = "rbxassetid://559831844",

	--- 40 quadros, o número da origem. A 60 Hz dá 2/3 de segundo, que é o
	--- tempo mínimo para o olho separar o fantasma do objeto.
	ATRASO_FANTASMA = 40,

	TREMOR_FORCA = 0.42,
	TREMOR_TEMPO = 0.7,
}

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
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

--- Pendura um `SpecialMesh` numa Part.
---
--- `SpecialMesh` filho, nunca `MeshPart`: assim a malha viaja como id, sem
--- `AeroMeshData` nem tabela de `SharedStrings` para carregar junto — que é o
--- que já fez o Studio chamar arquivo de corrompido neste repositório.
local function malha(parte, id, textura, escala)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.FileMesh
	m.MeshId = id
	if textura then m.TextureId = textura end
	m.Scale = escala or Vector3.new(1, 1, 1)
	m.Parent = parte
	return m
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

local function acima(p, quanto)
	return (p or Vector3.new()) + Vector3.new(0, quanto or 2, 0)
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

--- `pk` de nome que não existe no pack devolve false EM SILÊNCIO. Os dez
--- nomes reais são Floor_Crack, Laser_Shot, Shockwave, Shockwave_2,
--- Shockwave_Explosion, Small_Nova, Small_Slash, Smoky_Explosion, Sonar_Ring
--- e Spiral_Effect.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Tempo] pack " .. tostring(nome) .. ": "
			.. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA
--
-- `workspace.CurrentCamera` é singleton por cliente, e este módulo roda em
-- cliente: é acesso de serviço, não depósito de asset. O tremor é
-- multiplicação relativa e some sozinho — nada aqui escreve `CameraType`.
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
-- AS CAMADAS
--═══════════════════════════════════════════════════════════════

--- A CASCA DO CONGELADO — `ForceField`, como na origem.
---
--- Ela SEGUE a peça enquanto existir, mas isso quase nunca importa: a peça
--- está parada, que é o ponto. O laço existe para o caso de o alvo ser
--- descongelado no meio e sair andando com a casca colada.
local function camadaCongelado(d, peca, tamanho, duracao, cor)
	if not (peca and peca:IsA("BasePart")) then return nil end
	local lado = tamanho or (peca.Size.Magnitude * 1.5)
	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(lado, lado, lado),
		Color = cor or CFG.GELO,
		Material = Enum.Material.ForceField,
		Transparency = 0.35,
		CFrame = peca.CFrame,
	})
	anotar(d, casca)
	registrar(casca, (duracao or 4) + 0.6)

	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= (duracao or 4) or not (casca.Parent and peca.Parent) then
			laco:Disconnect()
			if casca.Parent then
				tween(casca, 0.3, { Transparency = 1 })
			end
			return
		end
		casca.CFrame = peca.CFrame
	end)
	anotar(d, nil, laco)
	return casca
end

--- O FANTASMA — o `beforeimage` da origem, com a cor dela.
---
--- Ele é um clone SEM SCRIPT e sem colisão, adiantado no tempo em relação a
--- quem está voltando. `caminho` é a lista de CFrames; o fantasma anda dela do
--- índice `ATRASO_FANTASMA` para a frente enquanto o alvo anda do 1.
local function camadaFantasma(d, modelo, caminho, duracao)
	if not (modelo and caminho and #caminho > 1) then return nil end

	local corpo = novaParte({
		Size = Vector3.new(2, 5, 1),
		Color = CFG.FANTASMA,
		Material = Enum.Material.ForceField,
		Transparency = 0.5,
		CFrame = caminho[1],
	})
	anotar(d, corpo)
	registrar(corpo, (duracao or 1.2) + 0.5)

	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		local fracao = math.min(passado / (duracao or 1.2), 1)
		if not corpo.Parent then laco:Disconnect() return end

		local i = math.floor(fracao * (#caminho - 1)) + 1 + CFG.ATRASO_FANTASMA
		if i <= #caminho then
			corpo.CFrame = caminho[i]
		else
			-- passou do fim do caminho: some devagar, como na origem
			corpo.Transparency = math.min(corpo.Transparency + 0.75 / 40, 1)
		end

		if fracao >= 1 then
			laco:Disconnect()
			tween(corpo, 0.25, { Transparency = 1 })
		end
	end)
	anotar(d, nil, laco)
	return corpo
end

--- O PONTEIRO varrendo, e o mostrador debaixo dele.
local function camadaMostrador(p, raio, cor, vida)
	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio * 2, raio * 2),
		Color = cor or CFG.BRONZE,
		Transparency = 0.55,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(disco, (vida or 1.2) + 0.3)
	tween(disco, vida or 1.2, { Transparency = 1 })

	-- as doze marcas de hora, por divisão exata: relógio com marca sorteada
	-- não é relógio
	for i = 0, 11 do
		local a = math.rad(i * 30)
		local marca = novaParte({
			Size = Vector3.new(0.3, 0.16, (i % 3 == 0) and 2.2 or 1.2),
			Color = branco(cor or CFG.DOURADO, 0.4),
			Transparency = 0.25,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a) * raio * 0.85, 0.2,
				math.sin(a) * raio * 0.85)) * CFrame.Angles(0, -a, 0),
		})
		registrar(marca, (vida or 1.2) + 0.3)
		tween(marca, (vida or 1.2) * 0.8, { Transparency = 1 })
	end
	return disco
end

local function camadaPonteiro(p, raio, direcao, cor, giro, vida)
	local ponteiro = novaParte({
		Size = Vector3.new(0.4, 0.3, raio),
		Color = cor or CFG.DOURADO,
		Transparency = 0.05,
		CFrame = CFrame.lookAt(p, p + direcao) * CFrame.new(0, 0, -raio * 0.5),
	})
	registrar(ponteiro, (vida or 0.6) + 0.3)
	tween(ponteiro, vida or 0.6, {
		Transparency = 1,
		CFrame = CFrame.lookAt(p, p + direcao) * CFrame.Angles(0, giro or math.rad(300), 0)
			* CFrame.new(0, 0, -raio * 0.5),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return ponteiro
end

--- OS GRÃOS DA AMPULHETA — eles CAEM para dentro, não para fora.
local function camadaAreia(p, raio, quantidade, vida, paraDentro)
	local n = quantidade or 26
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.35 + (i / n) * 0.65)
		local alto = 1 + math.abs(jitter(a)) * raio * 0.4
		local fora = p + Vector3.new(math.cos(a) * alcance, alto,
			math.sin(a) * alcance)
		local dentro = p + Vector3.new(0, 0.6, 0)
		local nasce = paraDentro and fora or dentro
		local morre = paraDentro and dentro or fora

		local grao = novaParte({
			Size = Vector3.new(0.26, 0.26, 0.26),
			Color = CFG.AREIA,
			Transparency = 0.1,
			CFrame = CFrame.new(nasce),
		})
		registrar(grao, (vida or 0.9) + 0.3)
		tween(grao, (vida or 0.9) * (0.55 + (i % 4) * 0.15), {
			Transparency = 1,
			CFrame = CFrame.new(morre),
			Size = Vector3.new(0.06, 0.06, 0.06),
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
end

local function camadaAnel(p, cor, raioFinal, vida)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 2, 2),
		Color = cor,
		Transparency = 0.25,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(anel, (vida or 0.6) + 0.3)
	tween(anel, vida or 0.6, {
		Transparency = 1,
		Size = Vector3.new(0.08, raioFinal * 2, raioFinal * 2),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return anel
end

--- OS CACOS DE TEMPO QUEBRADO. Eles ficam PARADOS no ar e apagam — não voam.
--- Caco que voa é estilhaço de explosão; caco parado é tempo quebrado.
local function camadaEstilhaco(p, cor, raio, quantidade, vida)
	local n = quantidade or 16
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.3 + (i / n) * 0.7)
		local alto = jitter(a) * raio * 0.5
		local onde = p + Vector3.new(math.cos(a) * alcance, alto,
			math.sin(a) * alcance)
		local lado = 0.3 + math.abs(jitter(a + 1.7)) * 0.6
		local caco = novaParte({
			Size = Vector3.new(lado * 0.16, lado * 2.2, lado),
			Color = cor,
			Material = Enum.Material.Glass,
			Reflectance = 0.4,
			Transparency = 0.2,
			CFrame = CFrame.new(onde) * CFrame.Angles(a, a * 1.4, a * 0.6),
		})
		registrar(caco, (vida or 1.0) + 0.3)
		-- só a transparência muda: a posição fica
		tween(caco, (vida or 1.0) * (0.5 + (i % 5) * 0.14), { Transparency = 1 })
	end
end

--═══════════════════════════════════════════════════════════════
-- LEITURA DO PAYLOAD
--═══════════════════════════════════════════════════════════════

local function pos(d)
	return (d and typeof(d.posicao) == "Vector3") and d.posicao or Vector3.new()
end

local function dir(d)
	local v = d and d.direcao
	if typeof(v) ~= "Vector3" or v.Magnitude < 0.01 then
		return Vector3.new(0, 0, -1)
	end
	return v.Unit
end

local function raioDe(d, padrao)
	return (d and tonumber(d.raio)) or padrao
end

local function corDe(d, padrao)
	return (d and typeof(d.cor) == "Color3") and d.cor or padrao
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

-- ── 1. PARADA DO TEMPO ───────────────────────────────────────────────────

--- M1: um alvo só, travado.
function Efeitos.TRAVA(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 2.5
	camadaCongelado(d, peca, nil, duracao, CFG.GELO)
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)
	camadaAnel(acima(onde, 0.4), CFG.GELO, 6, 0.45)
	camadaEstilhaco(acima(onde, 2), CFG.GELO, 4, 8, 0.8)
end

--- R: a esfera. É a `stopFX` da origem, com a malha e a textura dela.
function Efeitos.ZONA_PARADA(d)
	local centro = acima(pos(d), 2)
	local raio = raioDe(d, 34)
	local duracao = (d and tonumber(d.duracao)) or 5

	local esfera = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.001, 0.001, 0.001),
		Color = CFG.GELO,
		Material = Enum.Material.ForceField,
		Transparency = 0,
		CFrame = CFrame.new(centro),
	})
	local m = malha(esfera, CFG.MESH_ESFERA, CFG.TEX_ESFERA,
		Vector3.new(0.001, 0.001, 0.001))
	anotar(d, esfera)
	registrar(esfera, duracao + 2)

	-- os mesmos 0.75 s Exponential/InOut da origem, abrindo e fechando
	local escalaCheia = Vector3.new(raio * 0.3, raio * 0.3, raio * 0.3)
	tween(m, 0.75, { Scale = escalaCheia },
		Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
	task.delay(duracao, function()
		if m.Parent then
			tween(m, 0.75, { Scale = Vector3.new(0.001, 0.001, 0.001) },
				Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
		end
	end)

	camadaMostrador(pos(d) + Vector3.new(0, 0.4, 0), raio * 0.7, CFG.GELO, 1.4)
	camadaEstilhaco(centro, CFG.GELO, raio * 0.5, 22, duracao * 0.5)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
end

--- T: a retomada, e o que ficou guardado caindo de uma vez.
function Efeitos.RETOMAR(d)
	local centro = acima(pos(d), 2)
	local raio = raioDe(d, 34)
	camadaAnel(centro, branco(CFG.GELO, 0.5), raio, 0.55)
	camadaAnel(centro, CFG.GELO, raio * 0.6, 0.4)
	camadaEstilhaco(centro, CFG.GELO, raio * 0.45, 20, 0.5)
	tremor(CFG.TREMOR_FORCA * 1.2, CFG.TREMOR_TEMPO)
	pk("Shockwave_Explosion", centro, 0.6, 3, raio, CFG.GELO,
		branco(CFG.GELO, 0.7))
end

-- ── 2. REVERSAO ──────────────────────────────────────────────────────────

--- M1: o instante marcado.
function Efeitos.MARCA_INSTANTE(d)
	local peca = d and d.peca
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)
	camadaMostrador(onde + Vector3.new(0, 0.4, 0), 5, CFG.DOURADO, 1.0)
	camadaAnel(acima(onde, 1), CFG.DOURADO, 5, 0.5)
end

--- R e T: a volta, com o fantasma adiantado.
---
--- `caminho` é a lista de CFrames que o servidor gravou. É o mesmo dado que a
--- origem guardava em `positions`, e a mesma ideia: o alvo anda dela do índice
--- 1, e o fantasma do índice 40.
function Efeitos.REVERTER(d)
	local caminho = d and d.caminho
	local duracao = (d and tonumber(d.duracao)) or 1.2
	local onde = pos(d)

	camadaAnel(acima(onde, 1), CFG.FANTASMA, 8, 0.5)
	camadaEstilhaco(acima(onde, 2), CFG.FANTASMA, 5, 10, 0.7)

	if type(caminho) == "table" and #caminho > 1 then
		camadaFantasma(d, true, caminho, duracao)
	end
end

function Efeitos.REVERTER_EU(d)
	Efeitos.REVERTER(d)
	camadaMostrador(pos(d) + Vector3.new(0, 0.4, 0), 7, CFG.FANTASMA, 1.2)
	tremor(CFG.TREMOR_FORCA * 0.8, CFG.TREMOR_TEMPO)
end

-- ── 3. CAJADO CELESTE ────────────────────────────────────────────────────

--- M1 sob o SOL: um fóton caindo do céu. A malha é a da origem.
function Efeitos.FOTON(d)
	local destino = pos(d)
	local alto = destino + Vector3.new(0, 50, 0)
	local duracao = math.max((d and tonumber(d.duracao)) or 0.7, 0.1)

	local corpo = novaParte({
		Size = Vector3.new(2, 2, 2),
		Color = CFG.SOL,
		Transparency = 0.05,
		CFrame = CFrame.lookAt(alto, destino),
	})
	malha(corpo, CFG.MESH_FOTON, nil, Vector3.new(1.4, 1.4, 1.4))
	anotar(d, corpo)
	registrar(corpo, duracao + 0.5)
	tween(corpo, duracao, { CFrame = CFrame.lookAt(destino, destino
		+ (destino - alto).Unit) }, Enum.EasingStyle.Quint,
		Enum.EasingDirection.In)

	task.delay(duracao, function()
		camadaAnel(acima(destino, 0.4), CFG.SOL, 9, 0.5)
		camadaEstilhaco(acima(destino, 1), CFG.SOL, 5, 10, 0.6)
	end)
end

--- M1 sob a LUA: a lâmina que atravessa. A malha e o alcance são da origem.
function Efeitos.LAMINA_LUA(d)
	local origem = acima(pos(d), 2)
	local direcao = dir(d)
	local alcance = raioDe(d, 120)
	local duracao = math.max((d and tonumber(d.duracao)) or 1.4, 0.1)

	local corpo = novaParte({
		Size = Vector3.new(6, 6, 2),
		Color = CFG.LUA,
		Transparency = 0.1,
		CFrame = CFrame.lookAt(origem, origem + direcao)
			* CFrame.Angles(0, 0, math.rad(135)),
	})
	malha(corpo, CFG.MESH_LAMINA, nil, Vector3.new(3, 3, 3))
	anotar(d, corpo)
	registrar(corpo, duracao + 0.5)
	-- 2.1 s Quad/Out era o tween da origem; aqui a duração vem do servidor,
	-- que precisa dela para saber onde a lâmina está a cada instante
	tween(corpo, duracao, {
		CFrame = CFrame.lookAt(origem + direcao * alcance,
			origem + direcao * (alcance + 10)) * CFrame.Angles(0, 0, math.rad(135)),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tween(corpo, duracao, { Transparency = 0.8 }, Enum.EasingStyle.Sine,
		Enum.EasingDirection.In)
end

--- R: o holofote. A malha é a da origem.
function Efeitos.HOLOFOTE(d)
	local p = pos(d)
	local raio = raioDe(d, 20)
	local duracao = (d and tonumber(d.duracao)) or 4

	local coluna = novaParte({
		Size = Vector3.new(raio, 80, raio),
		Color = CFG.SOL,
		Transparency = 0.8,
		CFrame = CFrame.new(p + Vector3.new(0, 40, 0)),
	})
	malha(coluna, CFG.MESH_HOLOFOTE, nil, Vector3.new(raio * 0.4, 8, raio * 0.4))
	anotar(d, coluna)
	registrar(coluna, duracao + 0.6)

	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = CFG.SOL, 6, raio * 2
	luz.Parent = coluna

	local passado, proximoAnel = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not coluna.Parent then
			laco:Disconnect()
			if coluna.Parent then tween(coluna, 0.4, { Transparency = 1 }) end
			return
		end
		if passado < proximoAnel then return end
		proximoAnel = passado + 0.7
		camadaAnel(p + Vector3.new(0, 0.4, 0), CFG.SOL, raio, 0.65)
	end)
	anotar(d, nil, laco)
end

--- T: o eco do instante — o anel da origem, parado no ar.
function Efeitos.ECO_INSTANTE(d)
	local p = acima(pos(d), 2)
	local raio = raioDe(d, 16)

	local anel = novaParte({
		Size = Vector3.new(raio, raio, 1),
		Color = CFG.LUA,
		Transparency = 0.2,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, 0),
	})
	malha(anel, CFG.MESH_ANEL, nil, Vector3.new(raio * 0.3, raio * 0.3, 2))
	registrar(anel, 1.2)
	tween(anel, 0.9, { Transparency = 1,
		Size = Vector3.new(raio * 2, raio * 2, 1) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	camadaEstilhaco(p, CFG.LUA, raio * 0.5, 12, 0.8)
end

-- ── 4. ACELERACAO ────────────────────────────────────────────────────────

--- M1: três cortes que chegam como um.
function Efeitos.GOLPE_RAPIDO(d)
	local p = acima(pos(d), 1.6)
	local direcao = dir(d)
	local raio = raioDe(d, 8)
	local base = CFrame.lookAt(p, p + direcao)

	for i = 0, 2 do
		local atraso = i * 0.05
		task.delay(atraso, function()
			local giro = math.rad(-30 + i * 30)
			for j = 0, 6 do
				local fracao = j / 6
				local a = math.rad(-60 + 120 * fracao)
				local ponto = base * CFrame.Angles(0, 0, giro)
					* CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -raio)
				local lasca = novaParte({
					Size = Vector3.new(0.22, 1.0, 2.2),
					Color = branco(CFG.DOURADO, 0.4),
					Transparency = 0.12,
					CFrame = ponto * CFrame.Angles(0, 0, math.rad(90)),
				})
				registrar(lasca, 0.35)
				tween(lasca, 0.18, { Transparency = 1,
					Size = Vector3.new(0.04, 0.2, 2.8) })
			end
		end)
	end
end

--- R: o passo rápido. Um rastro que fica atrás de quem acelerou.
function Efeitos.PASSO_RAPIDO(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 5

	if not (peca and peca:IsA("BasePart")) then return end
	local passado, proximoVulto = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not peca.Parent then
			laco:Disconnect()
			return
		end
		if passado < proximoVulto then return end
		proximoVulto = passado + 0.08

		local vulto = novaParte({
			Size = Vector3.new(2, 5, 1),
			Color = CFG.DOURADO,
			Material = Enum.Material.ForceField,
			Transparency = 0.55,
			CFrame = peca.CFrame,
		})
		registrar(vulto, 0.5)
		tween(vulto, 0.3, { Transparency = 1 })
	end)
	anotar(d, nil, laco)
end

--- T: envelhecer. O cinza vive AQUI, no mundo 3D, não em `Lighting`.
function Efeitos.ENVELHECER(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 4
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)

	camadaCongelado(d, peca, nil, duracao, CFG.CINZA)
	camadaAreia(onde + Vector3.new(0, 4, 0), 3, 18, 1.2, true)
	camadaAnel(acima(onde, 0.4), CFG.CINZA, 5, 0.5)
end

-- ── 5. LENTIDAO ──────────────────────────────────────────────────────────

function Efeitos.PESO(d)
	local p = acima(pos(d), 1.4)
	local raio = raioDe(d, 8)
	camadaAnel(p, CFG.CINZA, raio, 0.7)
	camadaEstilhaco(p, CFG.CINZA, raio * 0.6, 8, 0.9)
end

--- R: o campo lento. Ele DURA, e por isso tem id.
function Efeitos.CAMPO_LENTO(d)
	local p = pos(d)
	local raio = raioDe(d, 28)
	local duracao = (d and tonumber(d.duracao)) or 6

	local cupula = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 2, raio * 2, raio * 2),
		Color = CFG.CINZA,
		Material = Enum.Material.ForceField,
		Transparency = 0.7,
		CFrame = CFrame.new(p + Vector3.new(0, raio * 0.3, 0)),
	})
	anotar(d, cupula)
	registrar(cupula, duracao + 0.6)

	camadaMostrador(p + Vector3.new(0, 0.4, 0), raio * 0.8, CFG.CINZA, 1.6)

	local passado, proximoGrao = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not cupula.Parent then
			laco:Disconnect()
			if cupula.Parent then tween(cupula, 0.4, { Transparency = 1 }) end
			return
		end
		if passado < proximoGrao then return end
		proximoGrao = passado + 0.55
		camadaAreia(p + Vector3.new(0, raio * 0.5, 0), raio * 0.7, 10, 1.6, true)
	end)
	anotar(d, nil, laco)
end

--- T: o segundo longo. Um alvo quase parado.
function Efeitos.SEGUNDO_LONGO(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 3
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)

	camadaCongelado(d, peca, nil, duracao, CFG.CINZA)
	camadaMostrador(onde + Vector3.new(0, 0.4, 0), 6, CFG.CINZA, duracao * 0.6)
	camadaEstilhaco(acima(onde, 2), CFG.CINZA, 4, 10, duracao * 0.5)
end

-- ── 6. PARADOXO ──────────────────────────────────────────────────────────

--- M1: o eco. Um vulto de você mesmo, parado onde você estava.
function Efeitos.ECO(d)
	local onde = pos(d)
	local duracao = (d and tonumber(d.duracao)) or 4

	local vulto = novaParte({
		Size = Vector3.new(2, 5, 1),
		Color = CFG.FANTASMA,
		Material = Enum.Material.ForceField,
		Transparency = 0.5,
		CFrame = (d and typeof(d.quadro) == "CFrame") and d.quadro
			or CFrame.new(onde),
	})
	anotar(d, vulto)
	registrar(vulto, duracao + 0.5)
	tween(vulto, duracao, { Transparency = 0.85 }, Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut)
	camadaAnel(acima(onde, 0.4), CFG.FANTASMA, 5, 0.45)
end

--- R: o duplo. O eco fica opaco e ataca junto.
function Efeitos.DUPLO(d)
	local onde = pos(d)
	local direcao = dir(d)
	camadaAnel(acima(onde, 1), branco(CFG.FANTASMA, 0.4), 8, 0.5)
	camadaPonteiro(acima(onde, 2), 7, direcao, CFG.FANTASMA,
		math.rad(180), 0.5)
end

--- T: o colapso. Todos os ecos estouram ao mesmo tempo.
function Efeitos.COLAPSO(d)
	local p = acima(pos(d), 1.5)
	local raio = raioDe(d, 26)
	camadaAnel(p, CFG.FANTASMA, raio, 0.7)
	camadaAnel(p, branco(CFG.FANTASMA, 0.5), raio * 0.6, 0.5)
	camadaEstilhaco(p, CFG.FANTASMA, raio * 0.5, 22, 0.9)
	tremor(CFG.TREMOR_FORCA * 1.1, CFG.TREMOR_TEMPO)
	pk("Smoky_Explosion", p, 0.8, raio * 0.4, CFG.FANTASMA,
		Color3.fromRGB(30, 10, 14))
end

-- ── 7. FIM DO RELOGIO ────────────────────────────────────────────────────

function Efeitos.PONTEIRO(d)
	local p = acima(pos(d), 1.6)
	local raio = raioDe(d, 16)
	camadaMostrador(pos(d) + Vector3.new(0, 0.4, 0), raio * 0.8, CFG.BRONZE, 1.0)
	camadaPonteiro(p, raio, dir(d), CFG.DOURADO, math.rad(330), 0.6)
end

--- R: a ampulheta. Os grãos caem PARA DENTRO, como quem é puxado.
function Efeitos.AMPULHETA(d)
	local p = pos(d)
	local raio = raioDe(d, 30)
	local duracao = (d and tonumber(d.duracao)) or 4

	local bulbo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 1.6, raio * 1.6, raio * 1.6),
		Color = CFG.AREIA,
		Material = Enum.Material.ForceField,
		Transparency = 0.78,
		CFrame = CFrame.new(p + Vector3.new(0, raio * 0.3, 0)),
	})
	anotar(d, bulbo)
	registrar(bulbo, duracao + 0.6)

	local passado, proximaLeva = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not bulbo.Parent then
			laco:Disconnect()
			if bulbo.Parent then tween(bulbo, 0.4, { Transparency = 1 }) end
			return
		end
		if passado < proximaLeva then return end
		proximaLeva = passado + 0.3
		camadaAreia(p + Vector3.new(0, 2, 0), raio * 0.8, 16, 1.1, true)
	end)
	anotar(d, nil, laco)
end

--- T: o Fim do Relógio. A ultimate.
function Efeitos.FIM_RELOGIO(d)
	local p = acima(pos(d), 1)
	local raio = raioDe(d, 55)

	camadaMostrador(pos(d) + Vector3.new(0, 0.4, 0), raio * 0.7, CFG.BRONZE, 2.0)

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Color = Color3.new(1, 1, 1),
		Transparency = 0.02,
		CFrame = CFrame.new(p),
	})
	registrar(clarao, 1.4)
	tween(clarao, 0.5, { Transparency = 1,
		Size = Vector3.new(raio * 1.6, raio * 1.6, raio * 1.6) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- os doze ponteiros: um por hora, todos saindo do centro de uma vez.
	-- Por divisão exata, nunca sorteio: o relógio tem doze horas.
	for i = 0, 11 do
		local a = math.rad(i * 30)
		local direcao = Vector3.new(math.cos(a), 0, math.sin(a))
		camadaPonteiro(p, raio * 0.8, direcao, CFG.DOURADO, math.rad(60), 0.9)
	end

	local i = 0
	while i < 3 do
		local atraso = 0.16 * i
		task.delay(atraso, function()
			camadaAnel(p, branco(CFG.DOURADO, i * 0.25), raio * (1 + i * 0.3),
				0.8 + i * 0.2)
		end)
		i = i + 1
	end

	camadaEstilhaco(p, CFG.DOURADO, raio * 0.55, 28, 1.6)
	camadaAreia(p, raio * 0.6, 30, 1.6, true)
	tremor(CFG.TREMOR_FORCA * 1.8, CFG.TREMOR_TEMPO * 2)
	pk("Sonar_Ring", CFrame.new(p), 1.3, 6, raio * 2, 1.6, 0.1,
		CFG.DOURADO, CFG.BRONZE)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Tempo] falha em " .. tostring(tipo)
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
