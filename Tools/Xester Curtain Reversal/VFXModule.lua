-- VFXModule_Xester_V1.lua
-- ModuleScript "VFXModule" — executor de VFX da Tool Xester
--
-- ONDE RODA: CLIENTE, EM TODOS ELES.
--
--   O `Client` é `Script` com `RunContext = Client`, e o servidor manda por
--   `VFXRemote:FireAllClients`. LocalScript dentro de Tool só roda para quem a
--   segura, e o efeito apareceria só para o portador — foi o conserto que este
--   repositório já pagou uma vez.
--
--   A CUTSCENE é a exceção deliberada: ela chega por `CutsceneRemote` com
--   `FireClient` para o DONO, porque o pedido foi explícito — a cutscene não
--   pode ser forçada nos outros jogadores. O VFX dela, não: esse é
--   `FireAllClients`, para quem está por perto ver o Xester se transformar.
--
-- O ANDAIME VEM DA MARIA, QUE VEIO DO JODRO, QUE VEIO DO GUEST
--
--   `novaParte`, `tween`, `registrar`, `angulo`, `registroDe`, `molde`, as
--   cinco `camada*` e o `pk` do pack Stella já estavam escritos, verificados e
--   em uso. Uma quarta cópia de cada um seria uma quarta versão de cada bug.
--
--   `molde` é o que faltava no módulo da Maria e só o console do jogo pegou.
--   Ele entra aqui pronto.
--
--   O que é NOVO são os efeitos: 40, para as 13 habilidades das duas formas,
--   a passiva e as três cutscenes.
local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_IMPACTO  = Color3.fromRGB(255, 214, 122),
	COR_METAL    = Color3.fromRGB(214, 226, 240),
	COR_CURA     = Color3.fromRGB(120, 235, 170),
	COR_PEDRA    = Color3.fromRGB(150, 146, 138),
	COR_POLVORA  = Color3.fromRGB(255, 176, 62),
	COR_ZOMBA    = Color3.fromRGB(255, 96, 176),
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA   = "rbxasset://textures/particles/smoke_main.dds",
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
--- 137.507764° nunca repete alinhamento, então 7 pombos nunca ficam empilhados.
local function angulo(i)
	return (i or proximo()) * CFG.ANGULO_AUREO
end

--- O registro por `id`, para o servidor poder mandar `APAGAR` e `MOVER` depois.
---
--- Sem isto, efeito com prazo (a cadeia, a revoada, o coro) não teria como ser
--- desfeito antes da hora — e a Tool guardada no meio deixaria lixo na tela.
local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id].partes
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
	-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois.
	-- A segunda não é redundância — num place vazio ninguém montou depósito
	-- nenhum, e até o primeiro `Equipped` o molde ainda está aqui dentro.
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

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Xester] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

--- O contato. 0.06 s — mais que isso e vira explosão, que não é o que é.

--- Clona um molde que veio DA ORIGEM, de qualquer lugar dentro da Tool.
---
--- ⚠️ ESTA FUNÇÃO FALTAVA, E O CONSOLE MOSTROU.
---
---     `attempt to call a nil value` em `METEORO` e `RAIO`. O andaime deste
---     módulo veio do Guest, que desenha só com primitiva e nunca precisou de
---     `molde`. Os efeitos da Maria precisam: o `Beam` do Curador, o `Orb` e o
---     `Shadows` da Escuridão, o `Mesh` e o `Particle` das Estrelas, do Meteoro
---     e do Relâmpago vieram todos do `mariatools.rbxmx`.
---
---     Chamada a função inexistente vira `nil` e só estoura NA HORA DE CHAMAR —
---     dentro do `pcall` do `VFX.Executar`, que transforma em `warn`. O jogo não
---     trava, o efeito some, e nada no verificador estático pegava.
---
--- A busca é RECURSIVA porque os moldes não estão todos no mesmo nível: o
--- `Beam` do Curador mora dentro do `Handle`, e os da Escuridão são filhos
--- diretos da Tool.
---
--- Devolve `nil` quando a Tool não traz aquele molde, e cada efeito cai no
--- desenho primitivo — a Tool sozinha num place vazio continua funcionando.
local pastaMoldes, moldeProcurado = nil, false

local function acharTool()
	local no = script
	while no do
		if no:IsA("Tool") then return no end
		no = no.Parent
	end
	return nil
end

local function molde(nome, props)
	if not moldeProcurado then
		moldeProcurado = true
		pastaMoldes = acharTool()
	end
	if not pastaMoldes then return nil end

	local base = pastaMoldes:FindFirstChild(nome, true)
	if not base then return nil end

	local copia = base:Clone()
	-- emissor autorado entra DESLIGADO: quem acende é quem usa, com o `Rate`
	-- do autor. `:Emit()` ignoraria a curva que ele escreveu.
	if copia:IsA("ParticleEmitter") or copia:IsA("Trail") or copia:IsA("Beam") then
		copia.Enabled = false
	end
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	return copia
end

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
	return (d and d.cor) or padrao or CFG.COR_IMPACTO
end

local function quadro(d)
	if d and d.cframe then return d.cframe end
	return CFrame.new(pos(d))
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS — 13 habilidades, 2 formas, 3 cutscenes
--
-- A PALETA CONTA A FORMA
--
--   Forma 1 é PALCO: branco de holofote, roxo de veludo, dourado de baralho
--   caro. Nada quente — o mestre do baralho não queima, ele apresenta.
--
--   Forma 2 é BRASA: laranja, vermelho e o branco-azulado do sopro. É a mesma
--   pessoa, e a virada de temperatura é o que faz a transformação ler.
--
-- O MOLDE VEM DA ORIGEM, E O DESENHO CAI NA PRIMITIVA SE ELE FALTAR
--
--   `Carta1..4` e os quatro `As*` vieram do `cards` do modelo; `Mascara`,
--   `Anel`, `Onda` e `Tempestade` são `SpecialMesh` com o `MeshId` que as 14
--   Tools anteriores já usavam. `molde(nome)` devolve `nil` no que faltar, e
--   cada efeito continua desenhando com `Part` — o teste do place vazio.
--
-- TUDO NASCE APAGADO E ACENDE NA EXECUÇÃO
--
--   O molde dentro da Tool está com `Transparency = 1` e `Enabled = false`
--   (o `preparar_xester_v2.py` apaga). Quem acende é a CÓPIA, aqui, no
--   momento da habilidade. Foi pedido explícito, e é o que faz a Tool parada
--   na mochila não brilhar.
--═══════════════════════════════════════════════════════════════

-- ── Forma 1, o palco ──
local COR_CARTA   = Color3.fromRGB(244, 240, 232)
local COR_VELUDO  = Color3.fromRGB(122, 62, 176)
local COR_OURO    = Color3.fromRGB(236, 196, 96)
local COR_ESPADAS = Color3.fromRGB(150, 196, 255)
local COR_PAUS    = Color3.fromRGB(126, 224, 150)
local COR_OUROS   = Color3.fromRGB(255, 186, 84)
local COR_COPAS   = Color3.fromRGB(255, 116, 148)
local COR_SOMBRA  = Color3.fromRGB(38, 26, 58)

-- ── Forma 2, a brasa ──
local COR_BRASA   = Color3.fromRGB(255, 132, 42)
local COR_SANGUE  = Color3.fromRGB(206, 48, 40)
local COR_SOPRO   = Color3.fromRGB(255, 226, 180)
local COR_CEU     = Color3.fromRGB(180, 220, 255)

--- O naipe, por nome. Uma porta só: se a cor de um naipe mudar, muda aqui.
local NAIPES = {
	ESPADAS = { cor = COR_ESPADAS, molde = "AsEspadas" },
	PAUS    = { cor = COR_PAUS,    molde = "AsPaus" },
	OUROS   = { cor = COR_OUROS,   molde = "AsOuros" },
	COPAS   = { cor = COR_COPAS,   molde = "AsCopas" },
}

--- O feixe entre duas pontas: corpo largo e núcleo fino, os dois somem.
local function feixe(origem, destino, c, grossura, tempo)
	local delta = destino - origem
	if delta.Magnitude < 0.2 then return end
	local corpo = novaParte({
		Size = Vector3.new(grossura, grossura, delta.Magnitude),
		Color = c, Transparency = 0.2,
		CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
	})
	local nucleo = novaParte({
		Size = Vector3.new(grossura * 0.35, grossura * 0.35, delta.Magnitude),
		Color = branco(c, 0.6), Transparency = 0,
		CFrame = corpo.CFrame,
	})
	tween(corpo, tempo, { Transparency = 1 }, Enum.EasingStyle.Sine)
	tween(nucleo, tempo * 0.8, { Transparency = 1 }, Enum.EasingStyle.Sine)
	registrar(corpo, tempo + 0.2)
	registrar(nucleo, tempo + 0.2)
end

--- Uma carta no mundo. Usa a `Carta1..4` da origem quando existe; a `Part`
--- chapada é o fallback, e ela sozinha já lê como carta pela proporção.
local function carta(cframe, tamanho, c, vida, indice)
	local qual = "Carta" .. tostring(1 + ((indice or proximo()) % 4))
	local peca = molde(qual, { Anchored = true, CanCollide = false,
		CanQuery = false, CanTouch = false, Transparency = 0 })
	if peca and peca:IsA("BasePart") then
		peca.Size = tamanho
		peca.CFrame = cframe
		for _, filho in ipairs(peca:GetDescendants()) do
			if filho:IsA("Decal") or filho:IsA("Texture") then
				filho.Transparency = 0
			elseif filho:IsA("PointLight") or filho:IsA("SpotLight") then
				filho.Enabled = true
			end
		end
		peca.Parent = workspace
	else
		peca = novaParte({ Size = tamanho, Color = c, Transparency = 0.05,
			Material = Enum.Material.SmoothPlastic, CFrame = cframe })
	end
	registrar(peca, vida)
	return peca
end

--- A máscara do Xester. `Mascara` é `SpecialMesh` com o MeshId do modelo.
local function mascara(cframe, escalaMascara, c, vida)
	local base = molde("Mascara", { Anchored = true, CanCollide = false,
		CanQuery = false, CanTouch = false, Transparency = 0 })
	if base and base:IsA("BasePart") then
		base.Size = Vector3.new(1, 1, 1) * escalaMascara
		base.CFrame = cframe
		base.Color = c
		base.Material = Enum.Material.Neon
		base.Parent = workspace
	else
		base = novaParte({ Size = Vector3.new(1.6, 2.2, 0.5) * escalaMascara,
			Color = c, Transparency = 0.05, CFrame = cframe })
	end
	registrar(base, vida)
	return base
end

--- O anel plano no chão. É o desenho de área desta Tool inteira.
local function anelChao(p, c, raio, tempo)
	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio * 0.4, raio * 0.4),
		Color = branco(c, 0.4), Transparency = 0.3,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(disco, tempo, { Size = Vector3.new(0.06, raio * 2, raio * 2),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(disco, tempo + 0.2)
	return disco
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — Q  Curtain Call
--
-- Ele se desfaz em cartas, deixa uma cópia falsa e some por 1.5 s. A cópia é
-- efeito, não personagem: uma silhueta de cartas paradas. Ela não tem
-- `Humanoid`, então nada mira nela e nada a machuca — quem responde por ela é
-- o Server, que só a usa como PONTO do estouro.
--═══════════════════════════════════════════════════════════════

function Efeitos.CURTAIN_SOME(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, COR_VELUDO, 5 * e)
	local i = 1
	while i <= 14 do
		local ang = angulo(i)
		local alvo = p + Vector3.new(math.cos(ang) * 6 * e,
			1.5 + (i % 5), math.sin(ang) * 6 * e)
		local peca = carta(CFrame.new(p + Vector3.new(0, 2, 0)),
			Vector3.new(1.6, 0.12, 1.1), COR_CARTA, 0.9, i)
		tween(peca, 0.7, { CFrame = CFrame.new(alvo)
			* CFrame.Angles(ang, ang * 1.7, 0), Transparency = 1 },
			Enum.EasingStyle.Quint)
		i = i + 1
	end
	pk("Small_Nova", p, 0.3, 0, 6 * e, branco(COR_VELUDO, 0.5), COR_VELUDO)
end

--- A cópia falsa. Fica de pé enquanto o `id` viver — `VFX.Parar(id)` a apaga,
--- e o Server chama isso no fim do 1.5 s OU quando a Tool é guardada.
function Efeitos.CURTAIN_COPIA(d)
	local p = pos(d)
	local reg = registroDe(d)
	local vida = (d and d.duracao) or 1.6
	-- silhueta: seis cartas em pé formando um corpo
	local alturas = { 0.6, 1.4, 2.2, 3.0, 3.6, 4.2 }
	for indice, alto in ipairs(alturas) do
		local largura = (indice <= 2) and 1.1 or (indice >= 5 and 1.0 or 1.8)
		local peca = carta(
			CFrame.new(p + Vector3.new(0, alto, 0))
				* CFrame.Angles(0, angulo(indice) * 0.1, 0),
			Vector3.new(largura, 0.7, 0.16), COR_CARTA, vida + 0.3, indice)
		peca.Transparency = 0.25
		if reg then table.insert(reg, peca) end
	end
	local rosto = mascara(CFrame.new(p + Vector3.new(0, 4.8, 0)), 0.9,
		COR_VELUDO, vida + 0.3)
	if reg then table.insert(reg, rosto) end
	camadaFlash(p + Vector3.new(0, 2.5, 0), COR_CARTA, 3)
end

function Efeitos.CURTAIN_ESTOURA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 12
	camadaFlash(p + Vector3.new(0, 2, 0), COR_VELUDO, 8 * e)
	anelChao(p, COR_VELUDO, raio, 0.5)
	camadaFaiscas(p + Vector3.new(0, 2, 0), COR_CARTA, 1.1 * e, 22)
	local i = 1
	while i <= 18 do
		local ang = angulo(i)
		local peca = carta(CFrame.new(p + Vector3.new(0, 2.4, 0)),
			Vector3.new(1.5, 0.12, 1.05), COR_CARTA, 0.8, i)
		tween(peca, 0.6, {
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * raio,
				1 + (i % 4) * 1.2, math.sin(ang) * raio))
				* CFrame.Angles(ang * 2, ang, 0),
			Transparency = 1 }, Enum.EasingStyle.Quint)
		i = i + 1
	end
	pk("Shockwave_Explosion", p, 0.5, 2 * e, raio * e,
		COR_VELUDO, branco(COR_CARTA, 0.4))
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — E  Four Suits Arsenal
--
-- Oito cartas orbitando. Elas ACOMPANHAM o portador: o Server manda `MOVER`
-- com o `id` a cada passo, e o `MOVER` compartilhado leva o registro inteiro.
--═══════════════════════════════════════════════════════════════

function Efeitos.ARSENAL_ANEL(d)
	local p = pos(d)
	local raio = (d and d.raio) or 5
	local quantas = (d and d.cartas) or 8
	local vida = (d and d.duracao) or 12
	local reg = registroDe(d)
	local i = 1
	while i <= quantas do
		local ang = (i / quantas) * math.pi * 2
		local peca = carta(
			CFrame.new(p + Vector3.new(math.cos(ang) * raio, 2.6,
				math.sin(ang) * raio)) * CFrame.Angles(0, -ang, math.rad(18)),
			Vector3.new(1.7, 0.14, 1.2), COR_CARTA, vida + 0.4, i)
		if reg then table.insert(reg, peca) end
		i = i + 1
	end
	camadaAnel(p + Vector3.new(0, 2.4, 0), COR_OURO, raio * 1.4, 0.5)
	camadaFlash(p + Vector3.new(0, 2.6, 0), COR_OURO, 3.4)
end

--- Um naipe disparado. O `naipe` chega por nome — o Server decide de quem é a
--- vez, porque é ele que guarda o contador.
function Efeitos.NAIPE_ATIRA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local qual = NAIPES[(d and d.naipe) or "ESPADAS"] or NAIPES.ESPADAS
	local voo = (d and d.voo) or 0.22

	local peca = molde(qual.molde, { Anchored = true, CanCollide = false,
		CanQuery = false, CanTouch = false, Transparency = 0 })
	if peca and peca:IsA("BasePart") then
		peca.CFrame = CFrame.lookAt(origem, destino)
		peca.Color = qual.cor
		for _, filho in ipairs(peca:GetDescendants()) do
			if filho:IsA("Decal") then filho.Transparency = 0 end
		end
		peca.Parent = workspace
	else
		peca = novaParte({ Size = Vector3.new(1.6, 0.12, 1.1),
			Color = qual.cor, Transparency = 0.05,
			CFrame = CFrame.lookAt(origem, destino) })
	end
	tween(peca, voo, { CFrame = CFrame.lookAt(destino, destino
		+ (destino - origem)) * CFrame.Angles(0, 0, math.pi * 2) },
		Enum.EasingStyle.Linear)
	registrar(peca, voo + 0.1)
	feixe(origem, destino, qual.cor, 0.28, voo + 0.12)
	camadaFlash(destino, qual.cor, 2.6)
	camadaFaiscas(destino, qual.cor, 0.6, 8)
end

--- Copas recupera vida: o desenho SOBE, e é o único que sobe. É assim que o
--- jogador sabe qual naipe saiu sem ler número nenhum.
function Efeitos.NAIPE_COPAS_CURA(d)
	local p = pos(d)
	camadaSubida(p, COR_COPAS, 0.8, 16)
	camadaFlash(p + Vector3.new(0, 2, 0), COR_COPAS, 3.2)
	pk("Small_Nova", p, 0.3, 0, 5, branco(COR_COPAS, 0.6), COR_COPAS)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — R  Joker's Labyrinth
--═══════════════════════════════════════════════════════════════

function Efeitos.LABIRINTO_SOBE(d)
	local p = pos(d)
	local raio = (d and d.raio) or 22
	local quantas = (d and d.paredes) or 10
	local vida = (d and d.duracao) or 4
	local reg = registroDe(d)
	local i = 1
	while i <= quantas do
		local ang = (i / quantas) * math.pi * 2
		local onde = p + Vector3.new(math.cos(ang) * raio, -8,
			math.sin(ang) * raio)
		local peca = carta(
			CFrame.new(onde) * CFrame.Angles(0, -ang, math.rad(90)),
			Vector3.new(14, 0.5, 9), COR_VELUDO, vida + 0.5, i)
		tween(peca, 0.45, { CFrame = CFrame.new(onde
			+ Vector3.new(0, 15, 0)) * CFrame.Angles(0, -ang, math.rad(90)) },
			Enum.EasingStyle.Back)
		if reg then table.insert(reg, peca) end
		i = i + 1
	end
	anelChao(p, COR_VELUDO, raio, 0.6)
end

--- O embaralhar: um par de estouros no lugar de onde cada um saiu e no lugar
--- para onde foi. Quem troca de fato é o Server; aqui é a leitura da troca.
function Efeitos.LABIRINTO_EMBARALHA(d)
	local a = (d and d.origem) or pos(d)
	local b = (d and d.destino) or a
	camadaFlash(a + Vector3.new(0, 2, 0), COR_VELUDO, 4)
	camadaFlash(b + Vector3.new(0, 2, 0), COR_OURO, 4)
	feixe(a + Vector3.new(0, 2, 0), b + Vector3.new(0, 2, 0),
		COR_VELUDO, 0.5, 0.3)
	camadaFaiscas(b + Vector3.new(0, 2, 0), COR_CARTA, 0.7, 10)
end

function Efeitos.LABIRINTO_FECHA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 22
	local reg = d and d.id and PorId[d.id]
	if reg then
		for _, peca in ipairs(reg) do
			if peca and peca.Parent and peca:IsA("BasePart") then
				tween(peca, 0.35, {
					CFrame = CFrame.new(p + Vector3.new(0, 6, 0))
						* (peca.CFrame - peca.Position),
					Transparency = 1 }, Enum.EasingStyle.Quint)
			end
		end
	end
	camadaFlash(p + Vector3.new(0, 4, 0), COR_VELUDO, 10 * e)
	anelChao(p, COR_OURO, raio * 0.7, 0.45)
	pk("Shockwave_Explosion", p, 0.55, 2 * e, raio * 0.8 * e,
		COR_VELUDO, branco(COR_OURO, 0.4))
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — T  Ace Gate
--═══════════════════════════════════════════════════════════════

function Efeitos.AS_VOA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local voo = (d and d.voo) or 0.3
	local peca = carta(CFrame.lookAt(origem, destino),
		Vector3.new(2.2, 0.16, 1.5), COR_OURO, voo + 0.1, 1)
	tween(peca, voo, { CFrame = CFrame.lookAt(destino, destino
		+ (destino - origem)) * CFrame.Angles(0, 0, math.pi * 3) },
		Enum.EasingStyle.Linear)
	feixe(origem, destino, COR_OURO, 0.22, voo + 0.1)
end

--- O Ás cravado. Fica de pé até o portão ser usado — por isso tem `id`.
function Efeitos.AS_CRAVA(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 10
	local reg = registroDe(d)
	local peca = carta(CFrame.new(p + Vector3.new(0, 1.6, 0))
		* CFrame.Angles(0, angulo(1), math.rad(6)),
		Vector3.new(2.4, 0.18, 1.6), COR_OURO, vida + 0.4, 1)
	if reg then table.insert(reg, peca) end
	local luz = anelChao(p, COR_OURO, 4, 0.45)
	if reg then table.insert(reg, luz) end
	camadaFlash(p + Vector3.new(0, 1.4, 0), COR_OURO, 3.6)
	camadaFaiscas(p, COR_OURO, 0.6, 10)
end

function Efeitos.AS_PORTAO(d)
	local a = (d and d.origem) or pos(d)
	local b = (d and d.destino) or a
	camadaFlash(a + Vector3.new(0, 2.5, 0), COR_VELUDO, 6)
	camadaFlash(b + Vector3.new(0, 2.5, 0), COR_OURO, 6)
	feixe(a + Vector3.new(0, 2.5, 0), b + Vector3.new(0, 2.5, 0),
		COR_OURO, 0.7, 0.3)
	local i = 1
	while i <= 8 do
		local ang = angulo(i)
		local peca = carta(CFrame.new(a + Vector3.new(0, 2.5, 0)),
			Vector3.new(1.4, 0.12, 1), COR_CARTA, 0.5, i)
		tween(peca, 0.4, { CFrame = CFrame.new(b
			+ Vector3.new(math.cos(ang) * 3, 2.5, math.sin(ang) * 3)),
			Transparency = 1 }, Enum.EasingStyle.Quint)
		i = i + 1
	end
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — Y  House Collapse
--═══════════════════════════════════════════════════════════════

function Efeitos.CASTELO_SOBE(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 12
	local andares = (d and d.andares) or 4
	local reg = registroDe(d)
	local andar = 1
	while andar <= andares do
		local quantas = (andares - andar + 1) * 2
		local raio = 3.2 + (andares - andar) * 1.6
		local alto = 1.6 + (andar - 1) * 3.4
		local i = 1
		while i <= quantas do
			local ang = (i / quantas) * math.pi * 2
			local onde = p + Vector3.new(math.cos(ang) * raio, alto,
				math.sin(ang) * raio)
			local peca = carta(
				CFrame.new(onde) * CFrame.Angles(0, -ang, math.rad(74)),
				Vector3.new(3.4, 0.22, 2.4), COR_CARTA, vida + 0.6, i + andar)
			peca.Transparency = 1
			tween(peca, 0.3, { Transparency = 0.05 }, Enum.EasingStyle.Quad)
			if reg then table.insert(reg, peca) end
			i = i + 1
		end
		andar = andar + 1
	end
	anelChao(p, COR_OURO, 9, 0.5)
	camadaPoeira(p, COR_CARTA, 0.7, 8)
end

--- As paredes desabam NA DIREÇÃO do mouse. `direcao` é unitária e vem do
--- Server, que a calculou a partir do ponto mirado.
function Efeitos.CASTELO_DESABA(d)
	local p, e = pos(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, 1)
	local alcance = (d and d.alcance) or 26
	local reg = d and d.id and PorId[d.id]
	if reg then
		for indice, peca in ipairs(reg) do
			if peca and peca.Parent and peca:IsA("BasePart") then
				local espalha = ((indice % 5) - 2) * 2.4
				local lado = Vector3.new(-dir.Z, 0, dir.X)
				tween(peca, 0.5, {
					CFrame = CFrame.new(p + dir * alcance + lado * espalha
						+ Vector3.new(0, 0.6, 0))
						* CFrame.Angles(angulo(indice), angulo(indice) * 0.6,
							math.rad(90)),
					Transparency = 1 }, Enum.EasingStyle.Quint)
			end
		end
	end
	camadaFlash(p + Vector3.new(0, 3, 0), COR_OURO, 9 * e)
	camadaPoeira(p, COR_CARTA, 1.2 * e, 16)
	anelChao(p, COR_OURO, 12 * e, 0.5)
	pk("Shockwave_Explosion", p, 0.5, 2 * e, 14 * e,
		COR_OURO, branco(COR_CARTA, 0.4))
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — U  Eclipse Deck
--═══════════════════════════════════════════════════════════════

function Efeitos.ECLIPSE_ABRE(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 6
	local alto = (d and d.altura) or 46
	local reg = registroDe(d)
	local carta_negra = novaParte({
		Size = Vector3.new(52, 1.2, 36), Color = COR_SOMBRA,
		Material = Enum.Material.SmoothPlastic, Transparency = 1,
		CFrame = CFrame.new(p + Vector3.new(0, alto + 20, 0))
			* CFrame.Angles(0, angulo(1) * 0.05, 0),
	})
	tween(carta_negra, 0.7, {
		CFrame = CFrame.new(p + Vector3.new(0, alto, 0)),
		Transparency = 0.06 }, Enum.EasingStyle.Back)
	registrar(carta_negra, vida + 0.6)
	if reg then table.insert(reg, carta_negra) end

	local borda = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 56, 56), Color = COR_VELUDO,
		Transparency = 0.4,
		CFrame = CFrame.new(p + Vector3.new(0, alto - 1.2, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(borda, vida + 0.6)
	if reg then table.insert(reg, borda) end
	camadaFlash(p + Vector3.new(0, alto, 0), COR_VELUDO, 20)
end

--- A marca sombria sobre um alvo. Um `id` POR ALVO: assim o Server pode
--- apagar a de quem morreu sem derrubar as outras.
function Efeitos.ECLIPSE_MARCA(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 5
	local reg = registroDe(d)
	local peca = carta(CFrame.new(p + Vector3.new(0, 5.2, 0))
		* CFrame.Angles(math.rad(90), 0, 0),
		Vector3.new(2.4, 0.18, 1.7), COR_SOMBRA, vida + 0.3, 2)
	peca.Color = COR_SOMBRA
	peca.Material = Enum.Material.Neon
	if reg then table.insert(reg, peca) end
	camadaFlash(p + Vector3.new(0, 5, 0), COR_VELUDO, 2.6)
end

function Efeitos.ECLIPSE_RETORNA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 26
	local vindos = (d and d.marcados) or {}
	for _, onde in ipairs(vindos) do
		if typeof(onde) == "Vector3" then
			local peca = carta(CFrame.new(onde + Vector3.new(0, 5, 0)),
				Vector3.new(2.2, 0.16, 1.5), COR_SOMBRA, 0.6, 3)
			peca.Color = COR_SOMBRA
			tween(peca, 0.4, { CFrame = CFrame.new(p + Vector3.new(0, 3, 0)),
				Transparency = 1 }, Enum.EasingStyle.Quint)
			feixe(onde + Vector3.new(0, 4, 0), p + Vector3.new(0, 3, 0),
				COR_VELUDO, 0.4, 0.4)
		end
	end
	camadaFlash(p + Vector3.new(0, 3, 0), COR_VELUDO, 16 * e)
	anelChao(p, COR_SOMBRA, raio, 0.6)
	camadaFaiscas(p + Vector3.new(0, 3, 0), COR_VELUDO, 1.4 * e, 28)
	pk("Shockwave_Explosion", p, 0.65, 3 * e, raio * e,
		COR_SOMBRA, COR_VELUDO)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — P  Royal Guard
--═══════════════════════════════════════════════════════════════

function Efeitos.GUARDA_SOBE(d)
	local p = pos(d)
	local raio = (d and d.raio) or 4.4
	local vida = (d and d.duracao) or 14
	local reg = registroDe(d)
	local i = 1
	while i <= 4 do
		local ang = (i / 4) * math.pi * 2
		local onde = p + Vector3.new(math.cos(ang) * raio, 2.8,
			math.sin(ang) * raio)
		local peca = carta(CFrame.new(onde) * CFrame.Angles(0, -ang, 0),
			Vector3.new(2.6, 0.24, 3.8), COR_OURO, vida + 0.5, i)
		peca.Color = COR_OURO
		if reg then table.insert(reg, peca) end
		i = i + 1
	end
	camadaAnel(p + Vector3.new(0, 1, 0), COR_OURO, raio * 1.6, 0.5)
	camadaFlash(p + Vector3.new(0, 2.8, 0), COR_OURO, 4)
end

function Efeitos.GUARDA_LANCA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local voo = (d and d.voo) or 0.26
	local peca = carta(CFrame.lookAt(origem, destino),
		Vector3.new(2.6, 0.24, 3.8), COR_OURO, voo + 0.2, 1)
	peca.Color = COR_OURO
	tween(peca, voo, { CFrame = CFrame.lookAt(destino,
		destino + (destino - origem)), Transparency = 0.6 },
		Enum.EasingStyle.Quad)
	camadaFlash(destino, COR_OURO, 4.4)
	camadaFaiscas(destino, COR_OURO, 0.8, 12)
	pk("Small_Nova", destino, 0.28, 0, 6, branco(COR_OURO, 0.5), COR_OURO)
end

function Efeitos.GUARDA_BAQUE(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 14
	local reg = d and d.id and PorId[d.id]
	if reg then
		for _, peca in ipairs(reg) do
			if peca and peca.Parent and peca:IsA("BasePart") then
				local plano = Vector3.new(peca.Position.X, p.Y + 0.4,
					peca.Position.Z)
				tween(peca, 0.22, { CFrame = CFrame.new(plano)
					* CFrame.Angles(0, angulo(1), math.rad(90)) },
					Enum.EasingStyle.Quint)
			end
		end
	end
	camadaFlash(p, COR_OURO, 8 * e)
	anelChao(p, COR_OURO, raio, 0.45)
	camadaPoeira(p, COR_CARTA, 1.1 * e, 14)
	pk("Shockwave_Explosion", p, 0.45, 2 * e, raio * e,
		COR_OURO, branco(COR_CARTA, 0.35))
end

--═══════════════════════════════════════════════════════════════
-- FORMA 1 — a passiva: a Carta Coringa
--
-- A cada três habilidades, uma carta dourada nasce e fica girando acima da
-- cabeça. Ela ACOMPANHA por `MOVER`, e some quando a próxima habilidade a
-- gasta. É o único aviso que o jogador tem, e por isso é visual — GUI dentro
-- de Tool é proibido pela diretriz base.
--═══════════════════════════════════════════════════════════════

function Efeitos.CORINGA_NASCE(d)
	local p = pos(d)
	local reg = registroDe(d)
	local vida = (d and d.duracao) or 30
	local peca = carta(CFrame.new(p + Vector3.new(0, 5.4, 0)),
		Vector3.new(1.9, 0.16, 1.3), COR_OURO, vida + 0.5, 4)
	peca.Color = COR_OURO
	peca.Material = Enum.Material.Neon
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = COR_OURO, 4, 14
	luz.Parent = peca
	if reg then table.insert(reg, peca) end
	camadaFlash(p + Vector3.new(0, 5.4, 0), COR_OURO, 3.2)
	camadaFaiscas(p + Vector3.new(0, 5.4, 0), COR_OURO, 0.5, 10)
end

function Efeitos.CORINGA_GASTA(d)
	local p = pos(d)
	camadaFlash(p + Vector3.new(0, 5.2, 0), branco(COR_OURO, 0.5), 5.4)
	camadaFaiscas(p + Vector3.new(0, 5.2, 0), COR_OURO, 0.9, 18)
	pk("Small_Nova", p + Vector3.new(0, 5.2, 0), 0.26, 0, 6,
		branco(COR_OURO, 0.6), COR_OURO)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — G  Wyrm Sparks
--═══════════════════════════════════════════════════════════════

function Efeitos.WYRM_VOA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local voo = (d and d.voo) or 0.45
	local cabeca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2), Color = COR_BRASA,
		Transparency = 0.1, CFrame = CFrame.new(origem),
	})
	local rosto = molde("Mascara", { Transparency = 0 })
	if rosto and rosto:IsA("BasePart") then
		rosto.Size = Vector3.new(2.4, 2.4, 2.4)
		rosto.Color = COR_SANGUE
		rosto.Material = Enum.Material.Neon
		rosto.Anchored, rosto.CanCollide = true, false
		rosto.CFrame = CFrame.lookAt(origem, destino)
		rosto.Parent = workspace
		tween(rosto, voo, { CFrame = CFrame.lookAt(destino,
			destino + (destino - origem)), Transparency = 1 },
			Enum.EasingStyle.Sine)
		registrar(rosto, voo + 0.2)
	end
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = COR_BRASA, 5, 16
	luz.Parent = cabeca
	tween(cabeca, voo, { CFrame = CFrame.new(destino), Transparency = 1 },
		Enum.EasingStyle.Sine)
	registrar(cabeca, voo + 0.2)
	camadaFaiscas(origem, COR_BRASA, 0.7, 10)
	camadaFlash(destino, COR_BRASA, 4)
end

--- A marca flamejante que fica no chão. Tem `id` para o Server poder apagar.
function Efeitos.WYRM_MARCA(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 5
	local raio = (d and d.raio) or 6
	local reg = registroDe(d)
	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.24, raio * 2, raio * 2), Color = COR_BRASA,
		Transparency = 0.45,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(disco, vida + 0.3)
	if reg then table.insert(reg, disco) end
	camadaSubida(p, COR_BRASA, 0.6, 10)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — H  Crown of Cinders
--═══════════════════════════════════════════════════════════════

function Efeitos.COROA_SOL(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 8
	local reg = registroDe(d)
	local alto = (d and d.altura) or 22
	local sol = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2), Color = COR_BRASA, Transparency = 0.05,
		CFrame = CFrame.new(p + Vector3.new(0, alto, 0)),
	})
	local nucleo = molde("Orbe", { Transparency = 0 })
	if nucleo and nucleo:IsA("BasePart") then
		nucleo.Size = Vector3.new(1, 1, 1)
		nucleo.Anchored, nucleo.CanCollide = true, false
		nucleo.Color = COR_SOPRO
		nucleo.Material = Enum.Material.Neon
		nucleo.CFrame = sol.CFrame
		nucleo.Parent = workspace
		tween(nucleo, 0.6, { Size = Vector3.new(9, 9, 9) },
			Enum.EasingStyle.Back)
		registrar(nucleo, vida + 0.4)
		if reg then table.insert(reg, nucleo) end
	end
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = COR_BRASA, 8, 60
	luz.Parent = sol
	tween(sol, 0.6, { Size = Vector3.new(14, 14, 14) }, Enum.EasingStyle.Back)
	registrar(sol, vida + 0.4)
	if reg then table.insert(reg, sol) end

	-- a coroa: oito cartas em pé em volta do sol, é o que faz o Coringa
	local i = 1
	while i <= 8 do
		local ang = (i / 8) * math.pi * 2
		local peca = carta(
			CFrame.new(p + Vector3.new(math.cos(ang) * 11, alto,
				math.sin(ang) * 11)) * CFrame.Angles(0, -ang, math.rad(90)),
			Vector3.new(6, 0.3, 4), COR_OURO, vida + 0.4, i)
		peca.Color = COR_OURO
		if reg then table.insert(reg, peca) end
		i = i + 1
	end
	camadaFlash(p + Vector3.new(0, alto, 0), COR_BRASA, 18)
end

function Efeitos.COROA_FRAGMENTO(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local voo = (d and d.voo) or 0.5
	local brasa = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4), Color = COR_BRASA,
		Transparency = 0.08, CFrame = CFrame.new(origem),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = COR_BRASA, 4, 18
	luz.Parent = brasa
	tween(brasa, voo, { CFrame = CFrame.new(destino) },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(brasa, voo + 0.1)
	task.delay(voo, function()
		camadaFlash(destino, COR_BRASA, 6)
		camadaFaiscas(destino, COR_BRASA, 1, 14)
		camadaPoeira(destino, COR_SANGUE, 0.8, 8)
		pk("Smoky_Explosion", destino, 0.5, 6, COR_BRASA, COR_SANGUE)
	end)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — J  Dragon's Requiem
--
-- A carga desenha o dragão espectral enrolado no personagem, e o `id` deixa o
-- Server apagá-lo se a Tool for guardada no meio. O sopro é CURVADO: o Server
-- manda os pontos do arco e aqui cada um vira um nó de chama.
--═══════════════════════════════════════════════════════════════

function Efeitos.REQUIEM_CARGA(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 3
	local reg = registroDe(d)
	local voltas = (d and d.voltas) or 3
	local nos = (d and d.nos) or 18
	local i = 1
	while i <= nos do
		local t = i / nos
		local ang = t * math.pi * 2 * voltas
		local raio = 3.4 + math.sin(t * math.pi) * 1.6
		local anel = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * (1.4 - t * 0.7),
			Color = COR_BRASA, Transparency = 0.15,
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * raio,
				0.6 + t * 5, math.sin(ang) * raio)),
		})
		registrar(anel, vida + 0.3)
		if reg then table.insert(reg, anel) end
		i = i + 1
	end
	local cabeca = mascara(CFrame.new(p + Vector3.new(0, 6.4, 0)), 1.6,
		COR_SANGUE, vida + 0.3)
	if reg then table.insert(reg, cabeca) end
	camadaSubida(p, COR_BRASA, 0.8, 14)
end

--- O sopro. `arco` é uma lista de Vector3 que o Server calculou: a curva é
--- decisão de gameplay (é ela que define quem é atingido), então quem a
--- calcula é quem aplica o dano.
function Efeitos.REQUIEM_SOPRO(d)
	local arco = (d and d.arco) or {}
	local largura = (d and d.largura) or 6
	local anterior = nil
	for indice, onde in ipairs(arco) do
		if typeof(onde) == "Vector3" then
			local t = indice / math.max(#arco, 1)
			local bola = novaParte({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1, 1, 1) * (largura * (0.35 + t * 0.9)),
				Color = COR_BRASA:Lerp(COR_SOPRO, 1 - t),
				Transparency = 0.2,
				CFrame = CFrame.new(onde),
			})
			tween(bola, 0.45, {
				Size = Vector3.new(1, 1, 1) * (largura * (0.6 + t * 1.3)),
				Transparency = 1 }, Enum.EasingStyle.Sine)
			registrar(bola, 0.7)
			if anterior then
				feixe(anterior, onde, COR_BRASA, largura * 0.28, 0.4)
			end
			anterior = onde
		end
	end
	if anterior then
		camadaFlash(anterior, COR_SOPRO, largura * 1.6)
		camadaFaiscas(anterior, COR_BRASA, 1.2, 22)
	end
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — K  Xester Prism
--
-- Três máscaras no ar disparando feixes que se cruzam no ponto mirado. O
-- ponto ANDA: o Server manda `PRISMA_MIRA` a cada passo com o `id`, e os três
-- feixes são redesenhados. Redesenhar é mais barato que animar `Size` num
-- `Part` esticado, e não deixa rastro se um passo se perder.
--═══════════════════════════════════════════════════════════════

function Efeitos.PRISMA_MASCARAS(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 6
	local raio = (d and d.raio) or 7
	local alto = (d and d.altura) or 7
	local reg = registroDe(d)
	local i = 1
	while i <= 3 do
		local ang = (i / 3) * math.pi * 2
		local onde = p + Vector3.new(math.cos(ang) * raio, alto,
			math.sin(ang) * raio)
		local rosto = mascara(CFrame.new(onde) * CFrame.Angles(0, -ang, 0),
			1.3, COR_CEU, vida + 0.4)
		if reg then table.insert(reg, rosto) end
		camadaFlash(onde, COR_CEU, 3)
		i = i + 1
	end
end

--- Os três feixes no ponto da vez. Sem `id`: eles duram um passo e somem.
function Efeitos.PRISMA_MIRA(d)
	local alvo = pos(d)
	local reg = d and d.id and PorId[d.id]
	if not reg then return end
	for _, rosto in ipairs(reg) do
		if rosto and rosto.Parent and rosto:IsA("BasePart") then
			feixe(rosto.Position, alvo, COR_CEU, 0.5, 0.28)
		end
	end
	camadaFlash(alvo, branco(COR_CEU, 0.4), 3.6)
end

function Efeitos.PRISMA_ESTOURA(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, COR_CEU, 9 * e)
	camadaFaiscas(p, COR_CEU, 1.1 * e, 20)
	pk("Small_Nova", p, 0.3, 0, 8 * e, branco(COR_CEU, 0.6), COR_CEU)
end

--═══════════════════════════════════════════════════════════════
-- FORMA 2 — L  The Final Page of Heaven
--═══════════════════════════════════════════════════════════════

function Efeitos.PAGINA_PARA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 34
	-- o mundo perde as cores: aqui é um anel BRANCO que passa por tudo. Não é
	-- `ColorCorrectionEffect` — pós-processamento é global e vaza para fora da
	-- Tool, o que a diretriz base proíbe.
	anelChao(p, Color3.new(1, 1, 1), raio, 0.8)
	camadaAnel(p + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), raio * 0.8, 0.7)
	camadaFlash(p + Vector3.new(0, 3, 0), Color3.new(1, 1, 1), 12 * e)
end

--- O relógio de naipes no céu: doze cartas em mostrador. É a leitura de
--- "o tempo parou" sem tocar em pós-processamento.
function Efeitos.PAGINA_RELOGIO(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 3
	local alto = (d and d.altura) or 30
	local reg = registroDe(d)
	local i = 1
	while i <= 12 do
		local ang = (i / 12) * math.pi * 2
		local peca = carta(
			CFrame.new(p + Vector3.new(math.cos(ang) * 16, alto,
				math.sin(ang) * 16)) * CFrame.Angles(math.rad(90), -ang, 0),
			Vector3.new(3.4, 0.2, 2.4), COR_CEU, vida + 0.4, i)
		peca.Color = COR_CEU
		peca.Material = Enum.Material.Neon
		if reg then table.insert(reg, peca) end
		i = i + 1
	end
	local ponteiro = novaParte({
		Size = Vector3.new(0.6, 0.6, 14), Color = COR_SOPRO,
		Transparency = 0.1,
		CFrame = CFrame.new(p + Vector3.new(0, alto, 7)),
	})
	registrar(ponteiro, vida + 0.4)
	if reg then table.insert(reg, ponteiro) end
	camadaFlash(p + Vector3.new(0, alto, 0), COR_CEU, 14)
end

--- Um dos três pontos escolhidos pelo jogador.
function Efeitos.PAGINA_PONTO(d)
	local p = pos(d)
	local vida = (d and d.duracao) or 6
	local reg = registroDe(d)
	local marca = carta(CFrame.new(p + Vector3.new(0, 0.6, 0))
		* CFrame.Angles(math.rad(90), angulo(1), 0),
		Vector3.new(4.2, 0.2, 3), COR_CEU, vida + 0.3, 2)
	marca.Color = COR_CEU
	marca.Material = Enum.Material.Neon
	if reg then table.insert(reg, marca) end
	local pilar = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(24, 3, 3), Color = COR_CEU, Transparency = 0.6,
		CFrame = CFrame.new(p + Vector3.new(0, 12, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(pilar, vida + 0.3)
	if reg then table.insert(reg, pilar) end
	camadaFlash(p, COR_CEU, 5)
end

--- O dragão celestial atravessa os três pontos. `rota` vem do Server, na
--- ordem em que o jogador escolheu.
function Efeitos.PAGINA_DRAGAO(d)
	local rota = (d and d.rota) or {}
	local e = escala(d)
	local anterior = nil
	for _, onde in ipairs(rota) do
		if typeof(onde) == "Vector3" then
			if anterior then
				feixe(anterior + Vector3.new(0, 3, 0),
					onde + Vector3.new(0, 3, 0), COR_CEU, 3.4 * e, 0.6)
				local corpo = mascara(
					CFrame.lookAt(anterior + Vector3.new(0, 3, 0),
						onde + Vector3.new(0, 3, 0)), 3.2, COR_SOPRO, 0.9)
				tween(corpo, 0.55, {
					CFrame = CFrame.lookAt(onde + Vector3.new(0, 3, 0),
						onde + (onde - anterior)), Transparency = 1 },
					Enum.EasingStyle.Sine)
			end
			camadaFlash(onde + Vector3.new(0, 2, 0), COR_CEU, 14 * e)
			camadaFaiscas(onde + Vector3.new(0, 2, 0), COR_SOPRO, 1.4 * e, 26)
			anelChao(onde, COR_CEU, 16 * e, 0.6)
			pk("Shockwave_Explosion", onde, 0.6, 3 * e, 18 * e,
				COR_CEU, COR_SOPRO)
			anterior = onde
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- A AURA DA FORMA 2
--
-- Fica ligada o tempo todo enquanto a Forma 2 estiver de pé. É o que diz, sem
-- texto, em qual forma o Xester está — e por isso ela tem `id` e é apagada por
-- `VFX.Parar` na volta, no `Unequipped` e no `Destroying`.
--═══════════════════════════════════════════════════════════════

function Efeitos.AURA_DRAGAO(d)
	local p = pos(d)
	local reg = registroDe(d)
	local vida = (d and d.duracao) or 120
	local i = 1
	while i <= 6 do
		local ang = (i / 6) * math.pi * 2
		local chama = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.1, 1.1, 1.1), Color = COR_BRASA,
			Transparency = 0.35,
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * 2.6, 1.4,
				math.sin(ang) * 2.6)),
		})
		registrar(chama, vida)
		if reg then table.insert(reg, chama) end
		i = i + 1
	end
	local luz = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p + Vector3.new(0, 3, 0)) })
	local ponto = Instance.new("PointLight")
	ponto.Color, ponto.Brightness, ponto.Range = COR_BRASA, 3, 22
	ponto.Parent = luz
	registrar(luz, vida)
	if reg then table.insert(reg, luz) end
end

--═══════════════════════════════════════════════════════════════
-- CUTSCENE — os seis beats de `The Final Deal`
--
-- SEM TÍTULO ESCRITO, E O MOTIVO É REGRA
--
--   O roteiro pede o título "XESTER — HEAVENBREAKER" na tela. Texto em 3D no
--   Roblox só existe por `BillboardGui` ou `SurfaceGui`, e a diretriz base
--   proíbe as duas dentro de uma Tool — `ScreenGui`/`BillboardGui` é sistema
--   de jogo, não é Tool.
--
--   O beat `TITULO` existe e é o clímax: a máscara nasce em tamanho grande, um
--   anel dourado abre atrás dela e a luz estoura. O que não existe é a LETRA.
--   Se o título escrito for obrigatório, ele tem de morar no sistema de UI do
--   jogo, do lado de fora, ouvindo o `CutsceneRemote`.
--═══════════════════════════════════════════════════════════════

function Efeitos.CENA_MAO(d)
	local p = pos(d)
	local peca = carta(CFrame.new(p + Vector3.new(0, 3.4, 0))
		* CFrame.Angles(math.rad(70), 0, 0),
		Vector3.new(2.2, 0.16, 1.5), COR_CARTA, 3.4, 1)
	peca.Color = COR_CARTA
	camadaFlash(p + Vector3.new(0, 3.4, 0), COR_CARTA, 2.4)
end

function Efeitos.CENA_NAIPES(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 3.6, 0)
	local ordem = { "ESPADAS", "PAUS", "OUROS", "COPAS" }
	for indice, nome in ipairs(ordem) do
		task.delay((indice - 1) * 0.09, function()
			local naipe = NAIPES[nome]
			camadaFlash(onde, naipe.cor, 2.2)
			camadaFaiscas(onde, naipe.cor, 0.4, 6)
		end)
	end
end

function Efeitos.CENA_CORINGA(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 3.7, 0)
	local peca = carta(CFrame.new(onde) * CFrame.Angles(math.rad(70), 0, 0),
		Vector3.new(2.4, 0.18, 1.7), COR_OURO, 1.6, 4)
	peca.Color = COR_OURO
	peca.Material = Enum.Material.Neon
	tween(peca, 1.4, { Color = COR_BRASA }, Enum.EasingStyle.Sine)
	camadaFlash(onde, COR_OURO, 4)
	camadaSubida(onde, COR_BRASA, 0.5, 12)
end

--- As cartas CONGELAM no ar enquanto o dragão espectral circula.
function Efeitos.CENA_CONGELA(d)
	local p = pos(d)
	local i = 1
	while i <= 16 do
		local ang = angulo(i)
		local raio = 4 + (i % 4)
		local peca = carta(
			CFrame.new(p + Vector3.new(math.cos(ang) * raio,
				1.4 + (i % 6) * 0.9, math.sin(ang) * raio))
				* CFrame.Angles(ang, ang * 1.3, ang * 0.4),
			Vector3.new(1.7, 0.14, 1.2), COR_CARTA, 1.4, i)
		i = i + 1
	end
	-- o dragão: uma espiral de nós subindo em volta do personagem
	local n = 1
	while n <= 20 do
		local t = n / 20
		local ang = t * math.pi * 2 * 2.5
		local no = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1) * (1.5 - t * 0.8),
			Color = COR_BRASA, Transparency = 0.2,
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * 3.4,
				0.6 + t * 6.5, math.sin(ang) * 3.4)),
		})
		tween(no, 1.1, { Transparency = 1 }, Enum.EasingStyle.Sine)
		registrar(no, 1.3)
		n = n + 1
	end
	mascara(CFrame.new(p + Vector3.new(0, 7.4, 0)), 1.8, COR_SANGUE, 1.3)
end

--- 5. Xester RASGA a carta: metade vira máscara, metade vira aura.
function Efeitos.CENA_RASGA(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 3.8, 0)
	camadaFlash(onde, branco(COR_BRASA, 0.4), 8)
	camadaFaiscas(onde, COR_BRASA, 1.2, 26)

	-- a metade que vira MÁSCARA, subindo para o rosto
	local rosto = mascara(CFrame.new(onde), 1.1, COR_SANGUE, 1.6)
	tween(rosto, 0.5, { CFrame = CFrame.new(p + Vector3.new(0, 4.9, 0)),
		Size = rosto.Size * 0.7 }, Enum.EasingStyle.Back)

	-- a metade que vira AURA, descendo e abrindo em volta do corpo
	local i = 1
	while i <= 10 do
		local ang = angulo(i)
		local chama = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2), Color = COR_BRASA,
			Transparency = 0.1, CFrame = CFrame.new(onde),
		})
		tween(chama, 0.55, {
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * 3, 1.4,
				math.sin(ang) * 3)), Transparency = 0.55 },
			Enum.EasingStyle.Quint)
		registrar(chama, 1.4)
		i = i + 1
	end
	pk("Shockwave_Explosion", p, 0.5, 2, 12, COR_BRASA, COR_SANGUE)
end

--- 6. O clímax. Máscara grande, anel dourado atrás, e o estouro de luz.
function Efeitos.CENA_TITULO(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 5.6, 0)
	local rosto = mascara(CFrame.new(onde), 3.4, COR_SANGUE, 1.6)
	rosto.Transparency = 1
	tween(rosto, 0.35, { Transparency = 0 }, Enum.EasingStyle.Back)
	tween(rosto, 1.4, { Size = rosto.Size * 1.3 }, Enum.EasingStyle.Sine)

	local aro = molde("Anel", { Transparency = 0 })
	if aro and aro:IsA("BasePart") then
		aro.Size = Vector3.new(4, 4, 4)
		aro.Color = COR_OURO
		aro.Material = Enum.Material.Neon
		aro.Anchored, aro.CanCollide = true, false
		aro.CFrame = CFrame.new(onde)
		aro.Parent = workspace
		tween(aro, 0.8, { Size = Vector3.new(26, 26, 3), Transparency = 1 },
			Enum.EasingStyle.Quint)
		registrar(aro, 1.2)
	else
		camadaAnel(onde, COR_OURO, 16, 0.8)
	end
	camadaFlash(onde, branco(COR_BRASA, 0.5), 22)
	camadaFaiscas(onde, COR_OURO, 1.6, 34)
	anelChao(p, COR_BRASA, 20, 0.7)
	pk("Shockwave_Explosion", p, 0.7, 3, 22, COR_BRASA, COR_OURO)
end

--═══════════════════════════════════════════════════════════════
-- CUTSCENE — os três beats de `Curtain Reversal`
--═══════════════════════════════════════════════════════════════

function Efeitos.CENA_ABSORVE(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 3.6, 0)
	local peca = carta(CFrame.new(onde) * CFrame.Angles(math.rad(70), 0, 0),
		Vector3.new(2.4, 0.18, 1.7), COR_OURO, 1.4, 4)
	peca.Color = COR_BRASA
	tween(peca, 0.8, { Color = COR_CARTA }, Enum.EasingStyle.Sine)
	-- o dragão é sugado PARA a carta: os nós convergem, ao contrário do CONGELA
	local i = 1
	while i <= 16 do
		local ang = angulo(i)
		local no = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2), Color = COR_BRASA,
			Transparency = 0.2,
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * 4,
				1 + (i % 5) * 1.2, math.sin(ang) * 4)),
		})
		tween(no, 0.55, { CFrame = CFrame.new(onde),
			Size = Vector3.new(0.2, 0.2, 0.2) }, Enum.EasingStyle.Quint)
		registrar(no, 0.8)
		i = i + 1
	end
	camadaFlash(onde, COR_BRASA, 6)
end

function Efeitos.CENA_APAGA(d)
	local p = pos(d)
	camadaPoeira(p + Vector3.new(0, 2, 0), COR_SANGUE, 0.7, 12)
	camadaFlash(p + Vector3.new(0, 3.4, 0), COR_CARTA, 4.4)
end

function Efeitos.CENA_FECHA(d)
	local p = pos(d)
	local onde = p + Vector3.new(0, 3.2, 0)
	local i = 1
	while i <= 8 do
		local ang = angulo(i)
		local peca = carta(
			CFrame.new(p + Vector3.new(math.cos(ang) * 4, 2 + (i % 4),
				math.sin(ang) * 4)),
			Vector3.new(1.7, 0.14, 1.2), COR_CARTA, 0.8, i)
		tween(peca, 0.5, { CFrame = CFrame.new(onde)
			* CFrame.Angles(math.rad(70), 0, 0), Transparency = 1 },
			Enum.EasingStyle.Quint)
		i = i + 1
	end
	camadaFlash(onde, COR_VELUDO, 4)
	anelChao(p, COR_VELUDO, 8, 0.5)
end

--═══════════════════════════════════════════════════════════════
-- COMUM ÀS DUAS FORMAS
--═══════════════════════════════════════════════════════════════

--- O M1 padrão: uma carta jogada (Forma 1) ou um corte de chama (Forma 2). A
--- cor decide qual, e quem manda a cor é o Server, que sabe a forma.
function Efeitos.GOLPE_SIMPLES(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local quente = (d and d.quente) == true
	local c = quente and COR_BRASA or COR_CARTA
	if quente then
		feixe(origem, destino, c, 1.1, 0.28)
		camadaFaiscas(destino, COR_BRASA, 0.8, 12)
	else
		local peca = carta(CFrame.lookAt(origem, destino),
			Vector3.new(1.7, 0.14, 1.2), c, 0.5, 1)
		tween(peca, 0.24, { CFrame = CFrame.lookAt(destino,
			destino + (destino - origem)) * CFrame.Angles(0, 0, math.pi * 2),
			Transparency = 1 }, Enum.EasingStyle.Linear)
	end
	camadaFlash(destino, c, 3)
end

--- O cajado acendendo e apagando na troca de forma. Ele é uma peça REAL,
--- soldada ao braço pelo Server; aqui só entra a faísca que o acompanha.
function Efeitos.CAJADO_ACENDE(d)
	local p = pos(d)
	camadaFlash(p, COR_BRASA, 5)
	camadaFaiscas(p, COR_BRASA, 0.9, 16)
end
-- ── COMPARTILHADOS ──────────────────────────────────────────────────

function Efeitos.MOVER(d)
	local reg = d and d.id and PorId[d.id]
	if not reg then return end
	local destino = pos(d)
	local tempo = (d and d.tempo) or 0.3
	for indice, inst in ipairs(reg.partes) do
		if inst and inst.Parent and inst:IsA("BasePart") then
			local alto = (indice > 1) and 2.6 or 0
			tween(inst, tempo, {
				CFrame = CFrame.new(destino + Vector3.new(0, alto, 0)),
			}, Enum.EasingStyle.Linear)
		end
	end
end

--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[" .. script.Name .. "/Xester] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
