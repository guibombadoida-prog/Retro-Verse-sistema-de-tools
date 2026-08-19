-- VFXModule_Maria_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto MARIA
--
-- ONDE RODA: CLIENTE, EM TODOS ELES.
--
-- O ANDAIME VEM DO JODRO, QUE VEIO DO GUEST
--
--   `novaParte`, `tween`, `registrar`, `angulo`, `registroDe`, as cinco
--   `camada*` e o `pk` do pack Stella já estavam escritos e testados. Uma
--   terceira cópia de cada um seria uma terceira versão de cada bug.
--
--   O que é novo são os EFEITOS: 22, um ou mais por habilidade das 28.
--
-- O MOLDE DE CADA CAJADO VEM DA ORIGEM
--
--   `Beam` (Curador) · `Orb` + `Shadows` + `Trail` (Escuridão) · `Mesh` +
--   `Particle` (Estrelas) · `Particle` (Meteoro) · `Mesh` (Relâmpago).
--   `molde(nome)` devolve `nil` no que a Tool não trouxer, e o desenho cai na
--   primitiva — a Tool sozinha num place vazio continua funcionando.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

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
		warn("[" .. script.Name .. "/Maria] pack " .. tostring(nome) .. ": " .. tostring(err))
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
-- EFEITOS — 7 cajados, 28 habilidades
--
-- O molde de cada Tool vem da ORIGEM: o `Beam` do Curador, o `Orb` mais
-- `Shadows` mais `Trail` da Escuridão, o `Mesh` e o `Particle` das Estrelas e
-- do Meteoro, o `Mesh` do Relâmpago. `molde(nome)` devolve `nil` no que a Tool
-- não trouxer, e o desenho cai na primitiva — a Tool sozinha num place vazio
-- continua funcionando, que é o teste da Regra nº 1.
--═══════════════════════════════════════════════════════════════

local COR_CURA = Color3.fromRGB(120, 235, 170)
local COR_SOMBRA = Color3.fromRGB(64, 40, 96)
local COR_ESTRELA = Color3.fromRGB(255, 236, 160)
local COR_GELO = Color3.fromRGB(150, 220, 255)
local COR_METEORO = Color3.fromRGB(255, 128, 48)
local COR_RAIO = Color3.fromRGB(180, 220, 255)
local COR_ILUSAO = Color3.fromRGB(196, 150, 255)

--- O feixe entre duas pontas. É o desenho do Curador e do Roubador — os dois
--- da origem usam a mesma `Beam` presa numa `Attachment` no alvo.
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

-- ── CURADOR ─────────────────────────────────────────────────────────

function Efeitos.CURA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	feixe(origem, destino, COR_CURA, 0.9, (d and d.duracao) or 1)
	camadaSubida(destino, COR_CURA, 0.7, 14)
	pk("Small_Nova", destino, 0.3, 0, 5, branco(COR_CURA, 0.6), COR_CURA)
end

function Efeitos.ROUBO(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	-- o feixe do roubo corre do ALVO para quem rouba: a direção conta a história
	feixe(destino, origem, Color3.fromRGB(196, 42, 88), 0.8,
		(d and d.duracao) or 1)
	camadaSubida(origem, COR_CURA, 0.5, 8)
end

function Efeitos.BENCAO(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 18
	camadaAnel(p - Vector3.new(0, 2.2, 0), COR_CURA, raio * e, 0.5)
	camadaSubida(p, COR_CURA, 0.9 * e, 22)
	pk("Sonar_Ring", CFrame.new(p), 0.7, 2 * e, raio * e, 0.7, 0.1,
		COR_CURA, branco(COR_CURA, 0.5))
end

function Efeitos.RESSURGIR(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, branco(COR_CURA, 0.5), 8 * e)
	camadaSubida(p, COR_CURA, 1.2 * e, 30)
	pk("Shockwave_Explosion", p - Vector3.new(0, 2, 0), 0.6, 2 * e, 16 * e,
		COR_CURA, branco(COR_CURA, 0.6))
end

-- ── ESCURIDÃO ───────────────────────────────────────────────────────

--- O orbe teleguiado. Usa o `Orb` (SpecialMesh) e o `Shadows` (emissor) que
--- vieram da origem, quando a Tool os traz.
function Efeitos.ORBE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local e = escala(d)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 4, 4) * e,
		Color = COR_SOMBRA, Transparency = 0.05,
		CFrame = CFrame.new(origem),
	})
	local malha = molde("Orb")
	if malha then malha.Parent = bola end
	local fumaca = molde("Shadows")
	if fumaca then
		fumaca.Parent = bola
		fumaca.Enabled = true
	end
	tween(bola, (d and d.tempo) or 0.5, { CFrame = CFrame.new(destino) },
		Enum.EasingStyle.Quad)
	registrar(bola, ((d and d.tempo) or 0.5) + 0.15)
	camadaFlash(origem, COR_SOMBRA, 2.4 * e)
end

function Efeitos.ORBE_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, COR_SOMBRA, 5 * e)
	camadaFaiscas(p, COR_SOMBRA, 0.8 * e, 14)
	pk("Small_Nova", p, 0.26, 0, 7 * e, branco(COR_SOMBRA, 0.4), COR_SOMBRA)
end

function Efeitos.CEGUEIRA(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 4
	local reg = registroDe(d)
	local nuvem = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3) * e,
		Color = COR_SOMBRA, Material = Enum.Material.Glass, Transparency = 0.4,
		CFrame = CFrame.new(p),
	})
	tween(nuvem, 0.5, { Size = Vector3.new(14, 14, 14) * e, Transparency = 0.62 },
		Enum.EasingStyle.Quint)
	registrar(nuvem, vida)
	if reg then table.insert(reg, nuvem) end
	pk("Smoky_Explosion", p, 1.2, 5 * e, COR_SOMBRA, Color3.fromRGB(30, 20, 44))
end

function Efeitos.MANTO(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 6
	local reg = registroDe(d)
	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6) * e,
		Color = COR_SOMBRA, Material = Enum.Material.ForceField,
		Transparency = 0.45, CFrame = CFrame.new(p),
	})
	registrar(casca, vida)
	if reg then table.insert(reg, casca) end
	camadaSubida(p, COR_SOMBRA, 0.7 * e, 14)
end

-- ── ILUSÃO ──────────────────────────────────────────────────────────

--- A isca. Na origem era um CLONE do personagem, com `Animate` e `Wander`
--- próprios — 505 linhas de script e um `Humanoid` a mais no servidor por uso.
--- Aqui é geometria do cliente com prazo: a Tool invoca, move e dispensa.
function Efeitos.ISCA(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 8
	local reg = registroDe(d)
	local corpo = novaParte({
		Size = Vector3.new(2, 4, 1) * e,
		Color = COR_ILUSAO, Material = Enum.Material.ForceField,
		Transparency = 0.35, CFrame = CFrame.new(p),
	})
	local cabeca = novaParte({
		Size = Vector3.new(1.4, 1.4, 1.4) * e,
		Color = COR_ILUSAO, Material = Enum.Material.ForceField,
		Transparency = 0.35, CFrame = CFrame.new(p + Vector3.new(0, 2.6, 0)),
	})
	for _, peca in ipairs({ corpo, cabeca }) do
		registrar(peca, vida)
		if reg then table.insert(reg, peca) end
	end
	camadaFlash(p, COR_ILUSAO, 3 * e)
end

function Efeitos.ISCA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, branco(COR_ILUSAO, 0.4), 5 * e)
	camadaFaiscas(p, COR_ILUSAO, 0.7 * e, 12)
end

-- ── ESTRELAS ────────────────────────────────────────────────────────

function Efeitos.ESTRELA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local e = escala(d)
	local corpo = novaParte({
		Size = Vector3.new(16, 5.2, 16) * e * 0.25,
		Color = COR_ESTRELA, Transparency = 0.1,
		CFrame = CFrame.new(origem),
	})
	local malha = molde("Mesh")
	if malha then malha.Parent = corpo end
	local faisca = molde("Particle")
	if faisca then
		faisca.Parent = corpo
		faisca.Enabled = true
	end
	tween(corpo, (d and d.tempo) or 0.55, {
		CFrame = CFrame.new(destino) * CFrame.Angles(0, math.rad(540), 0),
	}, Enum.EasingStyle.Quad)
	registrar(corpo, ((d and d.tempo) or 0.55) + 0.15)
end

function Efeitos.ESTRELA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, branco(COR_ESTRELA, 0.5), 6 * e)
	camadaFaiscas(p, COR_ESTRELA, 0.9 * e, 18)
	pk("Small_Nova", p, 0.28, 0, 8 * e, branco(COR_ESTRELA, 0.6), COR_ESTRELA)
end

function Efeitos.CONSTELACAO(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 6
	local reg = registroDe(d)
	local marca = novaParte({
		Size = Vector3.new(1.2, 1.2, 1.2) * e,
		Color = COR_ESTRELA, Transparency = 0.15,
		CFrame = CFrame.new(p + Vector3.new(0, 4, 0))
			* CFrame.Angles(math.rad(45), 0, math.rad(45)),
	})
	tween(marca, vida, {
		CFrame = marca.CFrame * CFrame.Angles(0, math.rad(1440), 0),
	}, Enum.EasingStyle.Linear)
	registrar(marca, vida)
	if reg then table.insert(reg, marca) end
end

-- ── GELO ────────────────────────────────────────────────────────────

--- O bloco de gelo. Na origem ele vinha com `HumanoidRootPart.Anchored = true`
--- — aqui o congelamento é `prender()` no servidor, e isto é só o desenho.
function Efeitos.GELO(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 3
	local reg = registroDe(d)
	local bloco = novaParte({
		Size = Vector3.new(6, 6, 3) * e,
		Color = COR_GELO, Material = Enum.Material.Glass, Transparency = 0.45,
		CFrame = CFrame.new(p),
	})
	registrar(bloco, vida)
	if reg then table.insert(reg, bloco) end
	camadaFaiscas(p, COR_GELO, 0.6 * e, 10)
	camadaFlash(p, branco(COR_GELO, 0.4), 3 * e)
end

function Efeitos.GELO_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFaiscas(p, COR_GELO, 1.1 * e, 22)
	pk("Small_Nova", p, 0.24, 0, 6 * e, branco(COR_GELO, 0.6), COR_GELO)
end

function Efeitos.TRILHA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 14
	local vida = (d and d.duracao) or 6
	local reg = registroDe(d)
	local chao = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, raio * 2, raio * 2) * e,
		Color = COR_GELO, Material = Enum.Material.Glass, Transparency = 0.5,
		CFrame = CFrame.new(p - Vector3.new(0, 2.6, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(chao, vida)
	if reg then table.insert(reg, chao) end
	camadaAnel(p - Vector3.new(0, 2.5, 0), COR_GELO, raio * e, 0.4)
end

-- ── METEORO ─────────────────────────────────────────────────────────

function Efeitos.METEORO(d)
	local p, e = pos(d), escala(d)
	local queda = (d and d.queda) or 0.8
	local alto = p + Vector3.new(0, 90, 0)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(13, 13, 13) * e,
		Color = COR_METEORO, Material = Enum.Material.Neon, Transparency = 0.05,
		CFrame = CFrame.new(alto),
	})
	local faisca = molde("Particle")
	if faisca then
		faisca.Parent = bola
		faisca.Enabled = true
	end
	tween(bola, queda, { CFrame = CFrame.new(p) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	registrar(bola, queda + 0.1)
	task.delay(queda, function()
		if bola and bola.Parent then bola.Parent = nil end
	end)
end

function Efeitos.METEORO_FIM(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 16
	camadaFlash(p, branco(COR_METEORO, 0.4), 10 * e)
	camadaPoeira(p, CFG.COR_PEDRA, 1.3 * e, 26)
	pk("Shockwave_Explosion", p, 0.55, 3 * e, raio * e, COR_METEORO,
		branco(COR_METEORO, 0.5))
end

function Efeitos.CRATERA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 14
	local vida = (d and d.duracao) or 6
	local reg = registroDe(d)
	local chao = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, raio * 2, raio * 2) * e,
		Color = COR_METEORO, Material = Enum.Material.Neon, Transparency = 0.55,
		CFrame = CFrame.new(p - Vector3.new(0, 2.6, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	registrar(chao, vida)
	if reg then table.insert(reg, chao) end
	camadaSubida(p, COR_METEORO, 0.8 * e, 16)
end

-- ── RELÂMPAGO ───────────────────────────────────────────────────────

--- Um raio: do céu até o ponto, reto e fino. A origem desenhava quatro por uso,
--- com `RopeLength` calculado — o número foi mantido.
function Efeitos.RAIO(d)
	local p, e = pos(d), escala(d)
	local altura = (d and d.altura) or 60
	local risco = novaParte({
		Size = Vector3.new(0.6 * e, altura, 0.6 * e),
		Color = branco(COR_RAIO, 0.6), Material = Enum.Material.Neon,
		Transparency = 0,
		CFrame = CFrame.new(p + Vector3.new(0, altura * 0.5, 0)),
	})
	local malha = molde("Mesh")
	if malha then malha.Parent = risco end
	tween(risco, 0.18, { Size = Vector3.new(0.05, altura, 0.05),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(risco, 0.35)
	camadaFlash(p, branco(COR_RAIO, 0.5), 4 * e)
	camadaFaiscas(p, COR_RAIO, 0.8 * e, 12)
end

function Efeitos.RAIO_FIM(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 10
	camadaFlash(p, branco(COR_RAIO, 0.6), 7 * e)
	pk("Shockwave_Explosion", p, 0.4, 1.5 * e, raio * e, COR_RAIO,
		branco(COR_RAIO, 0.6))
end

--- A corrente que salta entre alvos: um risco por pulo.
function Efeitos.CORRENTE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	feixe(origem, destino, COR_RAIO, 0.5, 0.22)
	camadaFaiscas(destino, COR_RAIO, 0.6, 8)
end

function Efeitos.PARARAIOS(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.duracao) or 5
	local reg = registroDe(d)
	local haste = novaParte({
		Size = Vector3.new(0.35, 7, 0.35) * e,
		Color = branco(COR_RAIO, 0.4), Material = Enum.Material.Neon,
		Transparency = 0.2,
		CFrame = CFrame.new(p + Vector3.new(0, 4.5, 0)),
	})
	registrar(haste, vida)
	if reg then table.insert(reg, haste) end
	camadaFlash(p, COR_RAIO, 3 * e)
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
		warn("[" .. script.Name .. "/Maria] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
