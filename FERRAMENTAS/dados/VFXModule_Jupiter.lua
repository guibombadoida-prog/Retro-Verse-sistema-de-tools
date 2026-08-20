-- VFXModule_Jupiter_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto JUPITER
--
-- ONDE RODA: CLIENTE, EM TODOS ELES. O servidor transmite por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- O ANDAIME É O MESMO DO JODRO, E ISSO É DE PROPÓSITO
--
--   `novaParte`, `tween`, `registrar`, `angulo`, as cinco
--   `camada*` e o `pk` do pack Stella já estavam escritos e testados.
--   Reescrever tudo para um conjunto novo seria criar uma segunda versão de
--   cada bug já consertado.
--
--   O que muda são os EFEITOS: 25 novos, um ou mais por habilidade das 7.
--
-- O QUE FOI REUSADO DO ACERVO (fluxo obrigatório, passo 1)
--
--   O `_INDICE.md` lista três emissores do próprio Jupiter já conformados e
--   nunca usados em Tool nenhuma: `RAIO_TEMPORAL` (Plasma + Clarão), `FAISCA`
--   (Faísca + Anel) e `AURA`. Os três entram aqui, reconstruídos a partir dos
--   parâmetros de verdade que estão em
--   `ACERVO_RETROVERSE/Jupiter_Great_Pressure_Sword/VFX/NOTAS.md` —
--   que é o que a ficha do modelo manda fazer: ler a tabela e REESCREVER o
--   efeito conforme, nunca copiar o emissor da origem.
--
--   Daí vêm as texturas de `CFG`: o espiral do `JupiterSpin` (com o
--   `RotSpeed = 360` que é dele), o anel do `JupiterRange`, o clarão do
--   `GlareEmitter`, o estouro do `ExplosionParticles`, o ponto do
--   `ExplosionBrightspot` e o choque do `Shock`. Nenhum id foi inventado.
--
-- O QUE NÃO FOI REUSADO
--
--   A LÓGICA. O `LOGICA/HABILIDADES.md` da ficha registra o que os 31 scripts
--   da origem faziam: `Health = 0`, raio de 1500 studs, `TagHumanoid` e
--   `IsTeamMate` reimplementados por fora do Núcleo, 69 `:Destroy()`, 37
--   `wait()`, 16 `math.random`, e um `Impact_Frame` que era `ScreenGui` mais
--   `ColorCorrectionEffect` mais `Sky` ao mesmo tempo. As 21 habilidades são
--   escritas do zero.
--
-- GIRO SEM QUADRO A QUADRO
--
--   A Grande Mancha, o cinturão e o planeta giram pelo `RotSpeed` do emissor,
--   não por uma conexão de `Heartbeat`. É a solução do próprio modelo de
--   origem (`JupiterSpin.RotSpeed = 360`), custa zero por quadro, e continua
--   girando mesmo se o cliente engasgar.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador. Com todos os
-- clientes desenhando, um sorteio faria cada um ver uma cena diferente.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),

	-- A paleta é a de Júpiter visto de perto, a mesma dos Handles.
	COR_MANCHA   = Color3.fromRGB(198, 84, 62),
	COR_CREME    = Color3.fromRGB(238, 222, 190),
	COR_OCRE     = Color3.fromRGB(196, 148, 96),
	COR_RAIO     = Color3.fromRGB(196, 228, 255),
	COR_RAD      = Color3.fromRGB(150, 240, 150),
	COR_BRASA    = Color3.fromRGB(255, 156, 62),
	COR_VACUO    = Color3.fromRGB(96, 78, 140),
	COR_FERRO    = Color3.fromRGB(146, 152, 164),

	-- As seis texturas do modelo de origem, pelo `MALHAS/ids.md` da ficha.
	TEX_ESPIRAL  = "rbxassetid://11283087951",  -- JupiterSpin
	TEX_FAIXA    = "rbxassetid://6700005265",   -- JupiterRange
	TEX_CLARAO   = "rbxassetid://243660364",    -- GlareEmitter
	TEX_ESTOURO  = "rbxassetid://1141830599",   -- ExplosionParticles
	TEX_PONTO    = "rbxassetid://243098098",    -- ExplosionBrightspot
	TEX_CHOQUE   = "rbxassetid://257173628",    -- Shock

	-- As duas embutidas do Roblox: essas resolvem em qualquer place.
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA   = "rbxasset://textures/particles/smoke_main.dds",

	MALHA_JUPITER  = "rbxassetid://907848103",
	TEXTURA_JUPITER = "rbxassetid://8077647902",

	LIMITE_VIVOS = 220,
}

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

--- Jitter determinístico em [-1,1]. No lugar do math.random: mesma variedade,
--- e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice. É o que distribui coisa em anel sem `math.random`:
--- 137.507764° nunca repete alinhamento, então as 4 luas nunca ficam empilhadas.
local function angulo(i)
	return (i or proximo()) * CFG.ANGULO_AUREO
end

--- O registro por `id`, para o servidor poder mandar `APAGAR` e `MOVER` depois.
---
--- Sem isto, efeito com prazo (a mancha, o cinturão, o planeta) não teria como
--- ser desfeito antes da hora — e a Tool guardada no meio deixaria lixo na tela.
local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {}, desvios = {} }
	PorId[d.id].desvios = PorId[d.id].desvios or {}
	return PorId[d.id]
end

--- Guarda a peça sob o `id`, JUNTO DO DESLOCAMENTO dela em relação ao centro.
---
--- O deslocamento não é detalhe: sem ele o `MOVER` empilha tudo no mesmo
--- ponto. Os dois anéis do cinturão viram um, a casca da blindagem some dentro
--- da cúpula, e a faixa do planeta descola dele. É medido UMA vez, no
--- nascimento — ler a posição de novo no meio de um tween daria a posição
--- interpolada, e o efeito derivaria um pouco a cada tique.
local function guardarPeca(d, inst, centro)
	local reg = registroDe(d)
	if not reg then return inst end
	table.insert(reg.partes, inst)
	reg.desvios[#reg.partes] = inst.Position - (centro or Vector3.new())
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
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
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
-- O pack do Acervo viaja como filho deste módulo, não em ReplicatedStorage:
-- a Regra nº 1 não abre exceção para pack. Se ele não estiver lá, cada efeito
-- daqui continua desenhando sozinho — `pk` só devolve false.
--
-- ATENÇÃO AO TIPO DO ARGUMENTO. Cinco dos dez efeitos do pack tomam tamanho
-- como NÚMERO e dois como Vector3, e o nome não avisa qual é qual
-- (`Size_A` × `Vector_Size_A`). Passar Vector3 onde ele quer número estoura
-- dentro do pcall e o efeito some sem avisar — foi o bug do `Small_Nova`.
-- `TESTES/verificar_pack_vfx.py` confere isso arquivo a arquivo.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function acharPack()
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

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Jupiter] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

--- O contato. 0.06 s — mais que isso e vira explosão, que não é o que é.
local function camadaFlash(p, c, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.5,
		Color = branco(c, 0.35),
		Transparency = 0.1,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 6, raio * 4
	luz.Parent = bola
	tween(bola, 0.06, { Size = Vector3.new(raio, raio, raio) * 1.4,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.2)
end

local function camadaFaiscas(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.3), c)
	em.LightEmission = 1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.2, 0.5)
	em.Speed = NumberRange.new(14 * forca, 32 * forca)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Rotation = NumberRange.new(0, 360)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 10)
	registrar(ancora, 1)
end

local function camadaAnel(p, c, raio, tempo)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio * 0.4, raio * 0.4),
		Color = branco(c, 0.4),
		Transparency = 0.25,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, tempo, { Size = Vector3.new(0.05, raio * 2.2, raio * 2.2),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, tempo + 0.2)
end

local function camadaPoeira(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FUMACA
	em.Color = ColorSequence.new(c, branco(c, 0.2))
	em.LightEmission = 0.15
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2 * forca),
		NumberSequenceKeypoint.new(1, 3.4 * forca),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.6, 1.2)
	em.Speed = NumberRange.new(4 * forca, 11 * forca)
	em.SpreadAngle = Vector2.new(60, 60)
	em.Rotation = NumberRange.new(0, 360)
	em.RotSpeed = NumberRange.new(-30, 30)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 8)
	registrar(ancora, 2)
end

--- Motes que SOBEM. É a assinatura da cura, e o único efeito do conjunto com
--- velocidade positiva no eixo Y — é o que faz ela não parecer dano.
local function camadaSubida(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.4), c)
	em.LightEmission = 0.9
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.5 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.7, 1.3)
	em.Speed = NumberRange.new(5 * forca, 9 * forca)
	em.SpreadAngle = Vector2.new(22, 22)
	em.Acceleration = Vector3.new(0, 6, 0)
	em.EmissionDirection = Enum.NormalId.Top
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 16)
	registrar(ancora, 2.4)
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS DO JUPITER — as três do `_INDICE.md`, reconstruídas
--
-- `RAIO_TEMPORAL` (Plasma + Clarão), `FAISCA` (Faísca + Anel) e `AURA`. Os
-- parâmetros vêm do `VFX/NOTAS.md` da ficha; o que mudou está anotado em cada
-- uma, porque a origem tinha valores que o repositório não aceita.
--═══════════════════════════════════════════════════════════════

--- Um emissor pronto, ancorado num ponto. Todo efeito daqui passa por aqui —
--- é o único lugar que sabe montar `Part` + `Attachment` + `ParticleEmitter`.
local function emissor(p, props, quantidade, vida)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	for chave, valor in pairs(props or {}) do
		em[chave] = valor
	end
	em.Enabled = false
	em.Parent = att
	if quantidade and quantidade > 0 then em:Emit(quantidade) end
	registrar(ancora, vida or 2)
	return ancora, em
end

--- `AURA` do Acervo — a faixa de Júpiter girando em volta de um ponto.
---
--- Origem: `JupiterSpin`, `Rate = 5`, `Lifetime = 2`, `Size = 65`,
--- `RotSpeed = 360`, `Orientation = 3` (VelocityParallel).
--- Mudou a cor (rgb(255,0,0) da origem → paleta do repositório) e o `Size`,
--- que a 65 studs tapava a tela inteira.
local function camadaAura(p, c, raio, vida)
	local ancora, em = emissor(p, {
		Texture = CFG.TEX_ESPIRAL,
		Color = ColorSequence.new(c, branco(c, 0.25)),
		LightEmission = 1,
		Size = NumberSequence.new(raio),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.8, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(vida or 2),
		Speed = NumberRange.new(0.01),
		RotSpeed = NumberRange.new(360),
		Rate = 5,
		ZOffset = 3,
	}, 3, (vida or 2) + 0.6)
	return ancora, em
end

--- `FAISCA` do Acervo — o anel achatado que sai do centro.
---
--- Origem: `JupiterRange`, `Drag = -6` (acelera para fora em vez de frear),
--- `Squash = -3` e `Orientation = 3`. O `Drag` negativo é a assinatura: é o
--- que faz o anel ABRIR em vez de dissipar.
local function camadaFaixa(p, c, raio, quantidade)
	local ancora, em = emissor(p, {
		Texture = CFG.TEX_FAIXA,
		Color = ColorSequence.new(c, c),
		LightEmission = 1,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, raio * 0.12),
			NumberSequenceKeypoint.new(0.5, raio * 0.8),
			NumberSequenceKeypoint.new(1, raio),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(0.85),
		Speed = NumberRange.new(0.05),
		Drag = -6,
		ZOffset = -2,
		Squash = NumberSequence.new(-3),
		Rate = 50,
	}, quantidade or 4, 1.6)
	return ancora, em
end

--- `RAIO_TEMPORAL` do Acervo — plasma quente mais o clarão por trás.
---
--- Origem: `PlasmaEmitter` (`Speed = 100`, `Lifetime = 0.1–0.2`, `Size = 18`)
--- e `GlareEmitter` (`Size = 30`, `ZOffset = 15`, `Brightness = 10`). Baixei o
--- `Rate` de 10000 e 5555 para 0: aqui quem dispara é `:Emit`, e a origem
--- ligava e desligava `Enabled` na mão.
local function camadaPlasma(p, c, forca, quantidade)
	emissor(p, {
		Texture = CFG.TEX_FAISCA,
		Color = ColorSequence.new(c, branco(c, 0.4)),
		LightEmission = 1,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 3.6 * forca),
			NumberSequenceKeypoint.new(1, 0.4 * forca),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.3),
		}),
		Lifetime = NumberRange.new(0.1, 0.2),
		Speed = NumberRange.new(46 * forca, 100 * forca),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		ZOffset = 5,
	}, quantidade or 14, 0.9)

	emissor(p, {
		Texture = CFG.TEX_CLARAO,
		Color = ColorSequence.new(c, c),
		LightEmission = 1,
		Brightness = 10,
		Size = NumberSequence.new(9 * forca),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.74),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(0.1),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
		ZOffset = 15,
	}, 3, 0.6)
end

--- O estouro do `ExplosionParticles`. A origem tinha 20 keypoints de `Size`
--- alternando 7 e 0 — um serrilhado que pisca. Ficaram três.
local function camadaEstouro(p, c, forca, quantidade)
	emissor(p, {
		Texture = CFG.TEX_ESTOURO,
		Color = ColorSequence.new(c, branco(c, 0.3)),
		LightEmission = 1,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.4 * forca),
			NumberSequenceKeypoint.new(0.4, 4.2 * forca),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(0.7, 1.4),
		Speed = NumberRange.new(18 * forca, 44 * forca),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		Drag = 2,
	}, quantidade or 20, 2.4)
end

--- O `Shock` do `Tased`, preso a uma peça que ANDA — é o único emissor daqui
--- com `LockedToPart`, porque ele acompanha o alvo em vez de ficar no ponto.
local function camadaChoque(peca, c, forca, vida)
	local att = Instance.new("Attachment")
	att.Parent = peca
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_CHOQUE
	em.Color = ColorSequence.new(c, c)
	em.LightEmission = 1
	em.Brightness = 5
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8 * forca),
		NumberSequenceKeypoint.new(1, 1.8 * forca),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.1)
	em.Speed = NumberRange.new(10 * forca)
	em.Rotation = NumberRange.new(-360, 360)
	em.RotSpeed = NumberRange.new(-360, 360)
	em.LockedToPart = true
	em.Rate = 150
	em.Enabled = true
	em.Parent = att
	task.delay(vida or 1, function()
		if em and em.Parent then em.Enabled = false end
	end)
	Debris:AddItem(att, (vida or 1) + 0.6)
	return em
end

--- O ponto branco do `ExplosionBrightspot` — o núcleo duro do estouro.
local function camadaPonto(p, c, tamanho)
	emissor(p, {
		Texture = CFG.TEX_PONTO,
		Color = ColorSequence.new(branco(c, 0.5), c),
		LightEmission = 1,
		Brightness = 10,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, tamanho),
			NumberSequenceKeypoint.new(0.5, tamanho * 0.25),
			NumberSequenceKeypoint.new(1, tamanho),
		}),
		Transparency = NumberSequence.new(0),
		Lifetime = NumberRange.new(0.2),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
		ZOffset = 2,
	}, 4, 0.7)
end

--═══════════════════════════════════════════════════════════════
-- FORMAS
--═══════════════════════════════════════════════════════════════

--- O planeta: a malha do modelo de origem, com a faixa vermelha em volta.
---
--- `SpecialMesh` filha de uma `Part`, não `MeshPart`: a malha viaja como id e
--- não pede a citação md5 do `AeroMeshData` nem a tabela de `SharedStrings`
--- que o `MeshPart` arrasta atrás.
local function planeta(p, tamanho, transparencia)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(tamanho, tamanho, tamanho),
		Color = CFG.COR_CREME,
		Material = Enum.Material.SmoothPlastic,
		Transparency = transparencia or 0,
		CFrame = CFrame.new(p),
	})
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.FileMesh
	malha.MeshId = CFG.MALHA_JUPITER
	malha.TextureId = CFG.TEXTURA_JUPITER
	malha.Scale = Vector3.new(tamanho, tamanho, tamanho) * 0.5
	malha.Parent = bola

	local luz = Instance.new("PointLight")
	luz.Color = CFG.COR_OCRE
	luz.Brightness = 3
	luz.Range = tamanho * 3
	luz.Parent = bola
	return bola
end

--- Um raio partido de `a` até `b`, em pedaços retos com desvio determinístico.
---
--- A origem trazia um `LightningBolt` completo (módulo de terceiro, 800+
--- linhas, com `math.random` no meio). Isto aqui é o que ele desenhava: n
--- segmentos, cada nó torto pelo mesmo ângulo áureo que distribui tudo neste
--- módulo. Determinístico, então os dois clientes veem o mesmo raio.
local function raio(a, b, c, largura, vida, nos)
	nos = nos or 7
	local delta = b - a
	local comprimento = delta.Magnitude
	if comprimento < 0.1 then return end
	local direcao = delta.Unit
	local lado = direcao:Cross(Vector3.new(0, 1, 0))
	if lado.Magnitude < 0.01 then lado = Vector3.new(1, 0, 0) end
	lado = lado.Unit
	local cima = direcao:Cross(lado).Unit

	local anterior = a
	for i = 1, nos do
		local fracao = i / nos
		local reto = a + direcao * (comprimento * fracao)
		local ponto = reto
		if i < nos then
			local ang = angulo(i)
			local desvio = comprimento * 0.055 * (1 + jitter(i * 0.3) * 0.5)
			ponto = reto + lado * (math.cos(ang) * desvio)
				+ cima * (math.sin(ang) * desvio)
		end
		local meio = (anterior + ponto) * 0.5
		local trecho = (ponto - anterior).Magnitude
		local perna = novaParte({
			Size = Vector3.new(largura, largura, trecho),
			Color = branco(c, 0.55),
			Transparency = 0.05,
			CFrame = CFrame.lookAt(meio, ponto),
		})
		tween(perna, vida, { Transparency = 1,
			Size = Vector3.new(largura * 0.2, largura * 0.2, trecho) },
			Enum.EasingStyle.Quint)
		registrar(perna, vida + 0.1)
		anterior = ponto
	end
	camadaPlasma(b, c, 0.7, 10)
end

--- A coluna vertical: um cilindro alto que desce e some.
local function coluna(p, c, raioColuna, altura, vida)
	local tubo = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(altura, raioColuna * 2, raioColuna * 2),
		Color = c,
		Transparency = 0.35,
		CFrame = CFrame.new(p + Vector3.new(0, altura * 0.5, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(tubo, vida, {
		Size = Vector3.new(altura, raioColuna * 0.3, raioColuna * 0.3),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(tubo, vida + 0.2)
	return tubo
end

--- A cúpula: meia esfera em volta de um ponto. Vira escudo e vira campo.
local function cupula(p, c, raioCupula, transparencia)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raioCupula, raioCupula, raioCupula) * 2,
		Color = c,
		Material = Enum.Material.ForceField,
		Transparency = transparencia or 0.6,
		CFrame = CFrame.new(p),
	})
	return bola
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

local function pos(d)
	return (d and d.posicao) or Vector3.new()
end

local function escala(d)
	return (d and d.escala) or 1
end

local function cor(d, padrao)
	return (d and d.cor) or padrao or CFG.COR_CREME
end

local function quadro(d)
	if d and d.cframe then return d.cframe end
	return CFrame.new(pos(d))
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS — 7 Tools, 3 habilidades cada
--═══════════════════════════════════════════════════════════════

-- ── GRANDE MANCHA ───────────────────────────────────────────────────

--- A tempestade. Fica de pé enquanto o servidor não mandar `APAGAR`, e gira
--- pelo `RotSpeed` do emissor — nenhuma conexão por quadro.
function Efeitos.MANCHA(d)
	local p, e = pos(d), escala(d)
	local raioTempestade = (d and d.raio) or 18
	local vida = (d and d.vida) or 5
	local c = cor(d, CFG.COR_MANCHA)

	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, raioTempestade * 2, raioTempestade * 2),
		Color = c,
		Transparency = 0.55,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(disco, vida + 0.4)
	guardarPeca(d, disco, p)

	local ancora = camadaAura(p, c, 26 * e, vida)
	guardarPeca(d, ancora, p)

	camadaFaixa(p, branco(c, 0.3), raioTempestade * 0.9, 4)
	camadaFlash(p, c, 5 * e)
end

--- Um sopro na borda, a cada tique da tempestade. É o que dá vida ao disco
--- sem precisar animá-lo.
function Efeitos.MANCHA_TIQUE(d)
	local p, e = pos(d), escala(d)
	local raioTempestade = (d and d.raio) or 18
	local c = cor(d, CFG.COR_MANCHA)
	local a = angulo()
	local borda = p + Vector3.new(math.cos(a), 0, math.sin(a))
		* (raioTempestade * 0.8)
	camadaPoeira(borda, CFG.COR_OCRE, 0.8 * e, 8)
	camadaFaiscas(borda, c, 0.6 * e, 6)
end

--- O olho: o centro parado. Coluna calma para cima, e o anel em volta parado
--- também — é o contrário da mancha, e tem de LER como o contrário.
function Efeitos.OLHO(d)
	local p, e = pos(d), escala(d)
	local raioOlho = (d and d.raio) or 10
	local c = cor(d, CFG.COR_CREME)
	coluna(p, c, raioOlho * 0.55 * e, 42 * e, 1.1)
	camadaAnel(p, c, raioOlho * e, 0.7)
	camadaSubida(p, branco(c, 0.3), 1.1 * e, 22)
	camadaFlash(p, c, 5 * e)
	pk("Sonar_Ring", CFrame.new(p), 0.9, 0, raioOlho * 2.4 * e, 2, 0.2,
		c, branco(c, 0.5))
end

--- A dispersão: a tempestade inteira vai para fora de uma vez.
function Efeitos.DISPERSAR(d)
	local p, e = pos(d), escala(d)
	local raioSopro = (d and d.raio) or 26
	local c = cor(d, CFG.COR_MANCHA)
	camadaFaixa(p, c, raioSopro * 1.1, 8)
	camadaPoeira(p, CFG.COR_OCRE, 1.6 * e, 26)
	camadaFlash(p, branco(c, 0.4), 8 * e)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.55,
		Vector3.new(6, 2, 6) * e,
		Vector3.new(raioSopro, 3, raioSopro) * e,
		c, branco(c, 0.6), Enum.EasingStyle.Quint)
end

-- ── PRESSAO ESMAGADORA ──────────────────────────────────────────────

--- A coluna que desce do céu. Ela vem de CIMA para baixo, e é isso que a
--- separa da coluna do olho, que sobe.
function Efeitos.COLUNA(d)
	local p, e = pos(d), escala(d)
	local raioColuna = (d and d.raio) or 7
	local c = cor(d, CFG.COR_RAIO)
	local alto = p + Vector3.new(0, 70 * e, 0)

	local tubo = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(70 * e, raioColuna * 2.2 * e, raioColuna * 2.2 * e),
		Color = c,
		Transparency = 0.4,
		CFrame = CFrame.new(alto) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(tubo, 0.22, { CFrame = CFrame.new(p + Vector3.new(0, 35 * e, 0))
		* CFrame.Angles(0, 0, math.rad(90)) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	tween(tubo, 0.6, { Transparency = 1,
		Size = Vector3.new(70 * e, raioColuna * 0.4 * e, raioColuna * 0.4 * e) })
	registrar(tubo, 0.8)

	camadaPonto(p, c, 6 * e)
	camadaAnel(p, c, raioColuna * 2 * e, 0.4)
	camadaPoeira(p, CFG.COR_FERRO, 1.2 * e, 16)
end

--- A prensa: dois blocos que fecham no alvo. É a mecânica desenhada — quem vê
--- entende que o dano veio de cima E de baixo ao mesmo tempo.
function Efeitos.PRENSA(d)
	local p, e = pos(d), escala(d)
	local largura = (d and d.raio) or 9
	local c = cor(d, CFG.COR_FERRO)
	local vao = 16 * e

	for _, sinal in ipairs({ 1, -1 }) do
		local placa = novaParte({
			Size = Vector3.new(largura * 2 * e, 1.2 * e, largura * 2 * e),
			Color = c,
			Material = Enum.Material.Metal,
			Transparency = 0.1,
			CFrame = CFrame.new(p + Vector3.new(0, sinal * vao, 0)),
		})
		tween(placa, 0.26, {
			CFrame = CFrame.new(p + Vector3.new(0, sinal * 1.4 * e, 0)),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(placa, 0.75, { Transparency = 1 })
		registrar(placa, 0.9)
	end

	task.delay(0.26, function()
		camadaFlash(p, CFG.COR_RAIO, 6 * e)
		camadaFaiscas(p, CFG.COR_RAIO, 1.2 * e, 20)
		camadaPoeira(p, CFG.COR_FERRO, 1.1 * e, 14)
	end)
end

--- O vácuo: a bola escura que puxa. Ela ENCOLHE enquanto vive, porque é o
--- contrário de uma explosão e não pode ler como uma.
function Efeitos.VACUO(d)
	local p, e = pos(d), escala(d)
	local raioVacuo = (d and d.raio) or 22
	local vida = (d and d.vida) or 2.4
	local c = cor(d, CFG.COR_VACUO)

	local nucleo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raioVacuo, raioVacuo, raioVacuo) * 0.9,
		Color = c,
		Transparency = 0.25,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 4, raioVacuo * 2
	luz.Parent = nucleo
	tween(nucleo, vida, {
		Size = Vector3.new(1.4, 1.4, 1.4) * e,
		Transparency = 0.05,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(nucleo, vida + 0.3)
	guardarPeca(d, nucleo, p)

	local ancora = camadaAura(p, c, 20 * e, vida)
	guardarPeca(d, ancora, p)

	camadaFlash(p, branco(c, 0.3), 4 * e)
end

-- ── RAIO JOVIANO ────────────────────────────────────────────────────

--- O raio que cai. Vem de 90 studs acima, sempre — é o que faz ele ler como
--- vindo do céu e não como saindo do chão.
function Efeitos.RAIO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_RAIO)
	local alto = (d and d.origem) or (p + Vector3.new(0, 90 * e, 0))
	raio(alto, p, c, 1.1 * e, 0.34, 9)
	camadaPonto(p, c, 7 * e)
	camadaAnel(p, c, 9 * e, 0.36)
	camadaFaiscas(p, c, 1.1 * e, 16)
end

--- O arco entre dois alvos. Mais fino e mais curto que o raio do céu — a
--- cadeia tem de parecer o eco dele, não outro golpe.
function Efeitos.ARCO(d)
	local a = (d and d.de) or pos(d)
	local b = (d and d.para) or pos(d)
	local e = escala(d)
	local c = cor(d, CFG.COR_RAIO)
	raio(a, b, c, 0.55 * e, 0.28, 6)
	camadaPonto(b, c, 4 * e)
end

--- A tormenta: a nuvem que fica de pé enquanto os raios caem. A nuvem é o
--- efeito com id; cada raio dela chega depois, por tique, como `RAIO`.
function Efeitos.TORMENTA(d)
	local p, e = pos(d), escala(d)
	local raioNuvem = (d and d.raio) or 30
	local vida = (d and d.vida) or 4
	local c = cor(d, CFG.COR_RAIO)

	local nuvem = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4 * e, raioNuvem * 2, raioNuvem * 2),
		Color = CFG.COR_FERRO,
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.5,
		CFrame = CFrame.new(p + Vector3.new(0, 34 * e, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(nuvem, vida + 0.5)
	guardarPeca(d, nuvem, p)

	local ancora = camadaAura(p + Vector3.new(0, 34 * e, 0), c, 30 * e, vida)
	guardarPeca(d, ancora, p)

	camadaFaixa(p, c, raioNuvem * 0.7, 4)
end

-- ── LUAS GALILEANAS ─────────────────────────────────────────────────

--- As quatro luas em volta de quem conjurou. Nascem já espalhadas pelo ângulo
--- áureo, e o servidor as leva pelo `MOVER` — nunca por quadro.
function Efeitos.LUAS(d)
	local p, e = pos(d), escala(d)
	local raioOrbita = (d and d.raio) or 8
	local vida = (d and d.vida) or 6
	local cores = { CFG.COR_BRASA, CFG.COR_RAIO, CFG.COR_FERRO, CFG.COR_OCRE }
	local tamanhos = { 1.5, 1.3, 1.8, 1.6 }

	for i = 1, 4 do
		local a = angulo(i)
		local ponto = p + Vector3.new(math.cos(a), jitter(i) * 0.35,
			math.sin(a)) * raioOrbita
		local lua = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * tamanhos[i] * e,
			Color = cores[i],
			Material = Enum.Material.Neon,
			Transparency = 0.05,
			CFrame = CFrame.new(ponto),
		})
		local luz = Instance.new("PointLight")
		luz.Color, luz.Brightness, luz.Range = cores[i], 3, 9 * e
		luz.Parent = lua
		registrar(lua, vida + 0.5)
		guardarPeca(d, lua, p)
	end

	camadaAnel(p, CFG.COR_CREME, raioOrbita * 1.4 * e, 0.5)
	camadaFlash(p, CFG.COR_CREME, 3.4 * e)
end

--- Io atravessando. É a lua vulcânica: brasa, não gelo.
function Efeitos.IO(d)
	local a = (d and d.de) or pos(d)
	local b = (d and d.para) or pos(d)
	local e = escala(d)
	local tempo = (d and d.tempo) or 0.4
	local c = cor(d, CFG.COR_BRASA)

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4) * e,
		Color = c,
		Transparency = 0,
		CFrame = CFrame.new(a),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 6, 16 * e
	luz.Parent = bola
	local rastro = Instance.new("Trail")
	local frente = Instance.new("Attachment")
	frente.Position = Vector3.new(0, 1.2 * e, 0)
	frente.Parent = bola
	local tras = Instance.new("Attachment")
	tras.Position = Vector3.new(0, -1.2 * e, 0)
	tras.Parent = bola
	rastro.Attachment0, rastro.Attachment1 = frente, tras
	rastro.Color = ColorSequence.new(branco(c, 0.4), c)
	rastro.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	rastro.Lifetime = 0.35
	rastro.FaceCamera = true
	rastro.Parent = bola

	tween(bola, tempo, { CFrame = CFrame.new(b) }, Enum.EasingStyle.Linear)
	registrar(bola, tempo + 0.1)
	task.delay(tempo, function()
		if bola and bola.Parent then bola.Parent = nil end
	end)
	camadaFlash(a, c, 3 * e)
end

function Efeitos.IO_IMPACTO(d)
	local p, e = pos(d), escala(d)
	local raioQueima = (d and d.raio) or 12
	local c = cor(d, CFG.COR_BRASA)
	camadaEstouro(p, c, 1 * e, 22)
	camadaPoeira(p, CFG.COR_FERRO, 1.1 * e, 14)
	camadaFlash(p, branco(c, 0.4), 6 * e)
	pk("Shockwave_Explosion", p, 0.4, 1.6 * e, raioQueima * e, c,
		branco(c, 0.5))
end

--- O eclipse: a sombra que cai por cima. Um disco ESCURO — é o único efeito
--- do conjunto que subtrai luz em vez de somar.
function Efeitos.ECLIPSE(d)
	local p, e = pos(d), escala(d)
	local raioSombra = (d and d.raio) or 24
	local c = cor(d, CFG.COR_VACUO)

	local sombra = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, raioSombra * 0.4, raioSombra * 0.4),
		Color = Color3.fromRGB(24, 20, 32),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.15,
		CFrame = CFrame.new(p + Vector3.new(0, 0.6, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(sombra, 0.7, {
		Size = Vector3.new(0.4, raioSombra * 2, raioSombra * 2),
	}, Enum.EasingStyle.Quint)
	tween(sombra, 2, { Transparency = 1 })
	registrar(sombra, 2.2)

	local coroa = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, raioSombra * 0.5, raioSombra * 0.5),
		Color = branco(c, 0.6),
		Transparency = 0.2,
		CFrame = CFrame.new(p + Vector3.new(0, 0.9, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(coroa, 0.8, {
		Size = Vector3.new(0.05, raioSombra * 2.3, raioSombra * 2.3),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(coroa, 1.1)

	camadaPonto(p + Vector3.new(0, 3, 0), branco(c, 0.7), 9 * e)
	camadaFaixa(p, c, raioSombra * 0.8, 5)
end

-- ── CINTURAO DE RADIACAO ────────────────────────────────────────────

--- O cinturão em volta de quem conjurou. Fica de pé com id, e o `MOVER` o
--- acompanha quando o dono anda.
function Efeitos.CINTURAO(d)
	local p, e = pos(d), escala(d)
	local raioCinto = (d and d.raio) or 14
	local vida = (d and d.vida) or 6
	local c = cor(d, CFG.COR_RAD)

	for i = 1, 2 do
		local anel = novaParte({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3 * e, raioCinto * 2 * (i == 1 and 1 or 0.72),
				raioCinto * 2 * (i == 1 and 1 or 0.72)),
			Color = c,
			Transparency = 0.55,
			CFrame = CFrame.new(p + Vector3.new(0, (i == 1 and 0.4 or 2.2), 0))
				* CFrame.Angles(0, 0, math.rad(90)),
		})
		registrar(anel, vida + 0.4)
		guardarPeca(d, anel, p)
	end

	local ancora = camadaAura(p, c, 18 * e, vida)
	guardarPeca(d, ancora, p)

	camadaFlash(p, c, 4 * e)
end

--- O pulso: o cinturão inteiro joga para fora de uma vez.
function Efeitos.PULSO_RAD(d)
	local p, e = pos(d), escala(d)
	local raioPulso = (d and d.raio) or 20
	local c = cor(d, CFG.COR_RAD)
	camadaFaixa(p, c, raioPulso, 6)
	camadaFaiscas(p, c, 1.3 * e, 22)
	camadaFlash(p, branco(c, 0.4), 6 * e)
	pk("Sonar_Ring", CFrame.new(p), 0.6, 1, raioPulso * 2 * e, 2.4, 0.3,
		c, branco(c, 0.6))
end

--- A blindagem: a magnetosfera. Cúpula com id, apagada por `APAGAR` quando o
--- prazo acaba ou quando a Tool é guardada no meio.
function Efeitos.BLINDAGEM(d)
	local p, e = pos(d), escala(d)
	local raioEscudo = (d and d.raio) or 7
	local vida = (d and d.vida) or 5
	local c = cor(d, CFG.COR_RAD)

	local domo = cupula(p, c, raioEscudo * e, 0.62)
	registrar(domo, vida + 0.4)
	guardarPeca(d, domo, p)

	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1) * raioEscudo * 2.2 * e,
		Color = branco(c, 0.5),
		Transparency = 0.88,
		CFrame = CFrame.new(p),
	})
	registrar(casca, vida + 0.4)
	guardarPeca(d, casca, p)

	camadaAnel(p, c, raioEscudo * 1.6 * e, 0.45)
	camadaFlash(p, c, 4 * e)
end

-- ── ESPADA DE PRESSAO ───────────────────────────────────────────────

--- O corte. Sai do pack da Stella — `Small_Slash` toma `CF`, `Size` NÚMERO,
--- `Duration`, e duas cores; passar Vector3 no `Size` estoura dentro do pcall
--- e o corte some sem avisar.
function Efeitos.CORTE(d)
	local e = escala(d)
	local q = quadro(d)
	local c = cor(d, CFG.COR_RAIO)
	pk("Small_Slash", q, 9 * e, 0.22, branco(c, 0.5), c)
	camadaFaiscas(q.Position, c, 0.9 * e, 12)
	camadaFlash(q.Position, c, 3 * e)
end

--- A onda de pressão que sai do corte. É o que faz a espada bater LONGE.
function Efeitos.ONDA_PRESSAO(d)
	local e = escala(d)
	local q = quadro(d)
	local alcance = (d and d.alcance) or 22
	local c = cor(d, CFG.COR_RAIO)

	local lamina = novaParte({
		Size = Vector3.new(11 * e, 0.7 * e, 1.6 * e),
		Color = branco(c, 0.4),
		Transparency = 0.2,
		CFrame = q,
	})
	tween(lamina, 0.34, {
		CFrame = q + q.LookVector * alcance,
		Size = Vector3.new(17 * e, 0.2 * e, 1.6 * e),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(lamina, 0.6)
	camadaFaixa(q.Position, c, 10 * e, 3)
end

--- A estocada: uma linha reta, fina e longa. `Laser_Shot` toma dois Vector3 e
--- as espessuras como NÚMERO.
function Efeitos.ESTOCADA(d)
	local a = (d and d.de) or pos(d)
	local b = (d and d.para) or pos(d)
	local e = escala(d)
	local c = cor(d, CFG.COR_RAIO)
	pk("Laser_Shot", a, b, 0.7 * e, 0.2 * e, 8, branco(c, 0.5), c,
		"Cylinder", 0.3)
	camadaPonto(b, c, 5 * e)
	camadaFaiscas(b, c, 1 * e, 14)
end

--- O corte gigante. Mesmo desenho do `CORTE`, na escala em que ele lê como
--- outra habilidade: a lâmina desce inteira e leva a onda junto.
function Efeitos.CORTE_GIGANTE(d)
	local e = escala(d)
	local q = quadro(d)
	local alcance = (d and d.alcance) or 34
	local c = cor(d, CFG.COR_CREME)

	local corte = novaParte({
		Size = Vector3.new(26 * e, 1.4 * e, 2.4 * e),
		Color = branco(c, 0.4),
		Transparency = 0.05,
		CFrame = q * CFrame.Angles(0, 0, math.rad(28)),
	})
	tween(corte, 0.4, {
		CFrame = (q + q.LookVector * alcance) * CFrame.Angles(0, 0, math.rad(-18)),
		Size = Vector3.new(38 * e, 0.3 * e, 2.4 * e),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(corte, 0.7)

	pk("Small_Slash", q, 20 * e, 0.3, branco(c, 0.5), CFG.COR_MANCHA)
	camadaPlasma(q.Position, CFG.COR_RAIO, 1.1 * e, 16)
	camadaFaixa(q.Position, CFG.COR_MANCHA, 18 * e, 5)
end

-- ── QUEDA DO GIGANTE ────────────────────────────────────────────────

--- O planeta parado no alto. Ele NÃO cai aqui — cai no `QUEDA`. Entre os dois
--- ele fica de pé com id, e o `MOVER` o leva se o dono andar.
function Efeitos.PLANETA(d)
	local p, e = pos(d), escala(d)
	local tamanho = (d and d.tamanho) or 16
	local vida = (d and d.vida) or 8

	local bola = planeta(p, tamanho * e, 0.05)
	registrar(bola, vida + 0.6)
	guardarPeca(d, bola, p)

	local faixa = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5 * e, tamanho * 1.15 * e, tamanho * 1.15 * e),
		Color = CFG.COR_MANCHA,
		Transparency = 0.45,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(faixa, vida + 0.6)
	guardarPeca(d, faixa, p)

	local ancora = camadaAura(p, CFG.COR_OCRE, tamanho * 2 * e, vida)
	guardarPeca(d, ancora, p)

	camadaFlash(p, CFG.COR_CREME, 8 * e)
end

--- A presença: a sombra que o planeta joga no chão, e o peso que ela é. Fica
--- de pé com id, junto do planeta.
function Efeitos.PRESENCA(d)
	local p, e = pos(d), escala(d)
	local raioPeso = (d and d.raio) or 26
	local vida = (d and d.vida) or 5

	local marca = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raioPeso * 2, raioPeso * 2),
		Color = CFG.COR_OCRE,
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.6,
		CFrame = CFrame.new(p + Vector3.new(0, 0.4, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(marca, vida + 0.4)
	guardarPeca(d, marca, p)

	camadaFaixa(p, CFG.COR_MANCHA, raioPeso * 0.8, 5)
	camadaPoeira(p, CFG.COR_FERRO, 1 * e, 12)
end

--- A queda. O planeta que estava no alto vem inteiro para o ponto — e esta é
--- a única coisa deste módulo que anda mais de 40 studs num tween só.
function Efeitos.QUEDA(d)
	local p, e = pos(d), escala(d)
	local tamanho = (d and d.tamanho) or 16
	local tempo = (d and d.tempo) or 0.7
	local altura = (d and d.altura) or 70

	local bola = planeta(p + Vector3.new(0, altura * e, 0), tamanho * e, 0)
	tween(bola, tempo, { CFrame = CFrame.new(p) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	registrar(bola, tempo + 0.1)
	task.delay(tempo, function()
		if bola and bola.Parent then bola.Parent = nil end
	end)
	camadaAura(p + Vector3.new(0, altura * 0.5 * e, 0), CFG.COR_MANCHA,
		tamanho * 2 * e, tempo)
end

--- O impacto. É o efeito mais caro do conjunto, e é de propósito: é a única
--- habilidade das 21 com recarga de 40 segundos.
function Efeitos.IMPACTO_JOVE(d)
	local p, e = pos(d), escala(d)
	local raioCratera = (d and d.raio) or 34
	local c = cor(d, CFG.COR_MANCHA)

	camadaPonto(p, CFG.COR_CREME, 14 * e)
	camadaEstouro(p, c, 1.6 * e, 34)
	camadaPlasma(p, CFG.COR_BRASA, 1.5 * e, 22)
	camadaPoeira(p, CFG.COR_FERRO, 2 * e, 30)
	camadaFaixa(p, c, raioCratera, 10)
	camadaFlash(p, branco(c, 0.5), 14 * e)

	pk("Floor_Crack", CFrame.new(p), raioCratera * 0.7 * e, 5,
		CFG.COR_OCRE)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.6,
		Vector3.new(8, 3, 8) * e,
		Vector3.new(raioCratera, 5, raioCratera) * e,
		c, branco(c, 0.6), Enum.EasingStyle.Quint)
	pk("Smoky_Explosion", p, 2.4, 9 * e, c, CFG.COR_FERRO)
end

-- ── COMPARTILHADOS ──────────────────────────────────────────────────

--- O choque preso ao ALVO. É o único emissor do módulo com `LockedToPart`:
--- ele anda junto com quem levou, em vez de ficar no ponto onde bateu.
---
--- A peça vem no payload como instância. `RemoteEvent` carrega instância sem
--- problema, e é mais barato que mandar posição a cada tique só para o efeito
--- acompanhar.
function Efeitos.CHOQUE(d)
	local peca = d and d.peca
	if not (peca and peca:IsA("BasePart")) then return end
	camadaChoque(peca, cor(d, CFG.COR_RAIO), escala(d), (d and d.vida) or 1.2)
end

--- MOVER — leva o que está registrado sob um id para outra posição.
---
--- É como as luas, o cinturão e o planeta andam. O passo vem por TIQUE do
--- servidor, nunca por quadro: uma mensagem a cada 0.3 s, e o cliente faz o
--- meio do caminho com um tween linear.
function Efeitos.MOVER(d)
	local reg = d and d.id and PorId[d.id]
	if not reg then return end
	local destino = pos(d)
	local tempo = (d and d.tempo) or 0.3
	local raioOrbita = (d and d.raio) or 0
	for indice, inst in ipairs(reg.partes) do
		if inst and inst.Parent and inst:IsA("BasePart") then
			local alvo
			if raioOrbita > 0 then
				-- as luas: cada uma no seu ângulo, e o ângulo ANDA a cada
				-- tique, que é o que faz a órbita girar sem quadro a quadro
				local a = angulo(indice) + ((d and d.fase) or 0)
				alvo = CFrame.new(destino + Vector3.new(math.cos(a),
					jitter(indice) * 0.35, math.sin(a)) * raioOrbita)
			else
				local desvio = (reg.desvios and reg.desvios[indice])
					or Vector3.new()
				alvo = CFrame.new(destino + desvio)
					* (inst.CFrame - inst.CFrame.Position)
			end
			tween(inst, tempo, { CFrame = alvo }, Enum.EasingStyle.Linear)
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[" .. script.Name .. "/Jupiter] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
			if inst:IsA("ParticleEmitter") then inst.Enabled = false end
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
end

return VFX
