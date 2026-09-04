-- VFXModule_Jodro_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto JODRO
--
-- ONDE RODA: CLIENTE, EM TODOS ELES. O servidor transmite por
-- `VFXRemote:FireAllClients` e o `Client` é `Script` com `RunContext = Client`.
--
-- O ANDAIME É O MESMO DO GUEST, E ISSO É DE PROPÓSITO
--
--   `novaParte`, `tween`, `registrar`, `camadaFlash`, `camadaFaiscas`,
--   `camadaAnel`, `camadaPoeira`, `camadaSubida` e o `pk` do pack Stella já
--   estavam escritos e testados. Reescrever tudo para um conjunto novo seria
--   criar uma segunda versão de cada bug já consertado.
--
--   O que muda são os EFEITOS: 19 novos, um ou mais por habilidade das 7.
--
-- CONJUNTO SEM MODELO DE ORIGEM
--
--   Não há malha nem emissor de terceiro aqui. Tudo é `Part` primitiva com cor,
--   forma e tween — que é o que o repositório já fazia nos conjuntos sem pack.
--   A única forma nova é a `seta` do `Deu Ruim`: haste mais ponta girada 45°.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador. Com todos os
-- clientes desenhando, um sorteio faria cada um ver uma cena diferente.

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
		warn("[" .. script.Name .. "/Jodro] pack " .. tostring(nome) .. ": " .. tostring(err))
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
-- EFEITOS — 7 Tools, 3 habilidades cada
--═══════════════════════════════════════════════════════════════

--- Uma seta apontando para cima ou para baixo. É o desenho do `Deu Ruim`, e
--- é a única forma nova deste módulo: duas peças, haste e ponta.
local function seta(p, c, altura, paraCima, vida)
    local sinal = paraCima and 1 or -1
    local haste = novaParte({
        Size = Vector3.new(0.7, altura, 0.7),
        Color = c, Transparency = 0.1,
        CFrame = CFrame.new(p + Vector3.new(0, sinal * altura * 0.5, 0)),
    })
    local ponta = novaParte({
        Shape = Enum.PartType.Block,
        Size = Vector3.new(1.9, 1.9, 1.9),
        Color = branco(c, 0.35), Transparency = 0.05,
        CFrame = CFrame.new(p + Vector3.new(0, sinal * altura, 0))
            * CFrame.Angles(0, math.rad(45), math.rad(45)),
    })
    for _, peca in ipairs({ haste, ponta }) do
        tween(peca, vida, {
            CFrame = peca.CFrame + Vector3.new(0, sinal * 3, 0),
            Transparency = 1,
        }, Enum.EasingStyle.Quint)
        registrar(peca, vida + 0.2)
    end
end

--- Elos de corrente em anel, para a Cadeia do Bonk.
local function corrente(p, c, raio, quantos, vida)
    for i = 1, quantos do
        local a = angulo(i)
        local onde = p + Vector3.new(math.cos(a), 0.6 + jitter(i) * 0.3,
            math.sin(a)) * raio
        local elo = novaParte({
            Size = Vector3.new(0.9, 0.28, 0.28),
            Color = c, Transparency = 0.05,
            CFrame = CFrame.new(onde) * CFrame.Angles(0, a, math.rad(90)),
        })
        tween(elo, vida, { Transparency = 1 }, Enum.EasingStyle.Sine)
        registrar(elo, vida + 0.2)
    end
end

-- ── BONK ────────────────────────────────────────────────────────────

function Efeitos.BONK(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_IMPACTO)
    camadaFlash(p, c, 2.6 * e)
    camadaFaiscas(p, c, 0.7 * e, 12)
    pk("Small_Nova", p, 0.22, 0, 5 * e, branco(c, 0.6), c)
end

function Efeitos.MEGA_BONK(d)
    local p, e = pos(d), escala(d)
    local raio = (d and d.raio) or 14
    local c = cor(d, CFG.COR_IMPACTO)
    camadaFlash(p, branco(c, 0.4), 7 * e)
    camadaAnel(p - Vector3.new(0, 2.4, 0), c, raio * e, 0.36)
    camadaPoeira(p - Vector3.new(0, 2.6, 0), CFG.COR_PEDRA, 1.1 * e, 22)
    pk("Shockwave_Explosion", p - Vector3.new(0, 2.2, 0), 0.5,
        2 * e, raio * e, c, branco(c, 0.6))
end

function Efeitos.CADEIA(d)
    local p, e = pos(d), escala(d)
    local vida = (d and d.duracao) or 3
    local reg = registroDe(d)
    local c = cor(d, CFG.COR_METAL)
    corrente(p, c, 2.2 * e, 8, vida)
    local poste = novaParte({
        Size = Vector3.new(0.5, 5.5, 0.5) * e,
        Color = branco(c, 0.2), Transparency = 0.2,
        CFrame = CFrame.new(p + Vector3.new(0, 1.4, 0)),
    })
    tween(poste, vida, { Transparency = 1 }, Enum.EasingStyle.Sine)
    registrar(poste, vida + 0.2)
    if reg then table.insert(reg, poste) end
    camadaFlash(p, c, 3 * e)
end

-- ── CHINELO VOADOR ──────────────────────────────────────────────────

function Efeitos.TAPA(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_ZOMBA)
    camadaFlash(p, c, 2.2 * e)
    pk("Small_Slash", quadro(d), 8 * e, 0.2, branco(c, 0.5), c)
end

--- O chinelo teleguiado: o risco de ida e o de volta, no mesmo efeito.
function Efeitos.CHINELO_VOA(d)
    local origem = (d and d.origem) or pos(d)
    local destino = (d and d.destino) or origem
    local c = cor(d, CFG.COR_ZOMBA)
    local delta = destino - origem
    if delta.Magnitude < 0.2 then return end
    local risco = novaParte({
        Size = Vector3.new(0.6, 0.25, delta.Magnitude),
        Color = c, Transparency = 0.1,
        CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
    })
    tween(risco, 0.3, { Transparency = 1,
        Size = Vector3.new(0.1, 0.05, delta.Magnitude) }, Enum.EasingStyle.Quint)
    registrar(risco, 0.5)
    camadaFaiscas(destino, c, 0.6, 8)
end

function Efeitos.AURA_BRAVA(d)
    local p, e = pos(d), escala(d)
    local vida = (d and d.duracao) or 4
    local reg = registroDe(d)
    local c = cor(d, CFG.COR_ZOMBA)
    local domo = novaParte({
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(3, 3, 3) * e,
        Color = c, Material = Enum.Material.ForceField, Transparency = 0.55,
        CFrame = CFrame.new(p),
    })
    tween(domo, 0.6, { Size = Vector3.new(11, 11, 11) * e, Transparency = 0.82 },
        Enum.EasingStyle.Quint)
    registrar(domo, vida)
    if reg then table.insert(reg, domo) end
    camadaSubida(p, c, 0.8 * e, 16)
end

-- ── SUSSY ───────────────────────────────────────────────────────────

function Efeitos.FACADA(d)
    local e = escala(d)
    local c = cor(d, Color3.fromRGB(214, 42, 58))
    pk("Small_Slash", quadro(d), 10 * e, 0.22, branco(c, 0.4), c)
    camadaFaiscas(pos(d), c, 0.55 * e, 10)
end

--- O vent: fumaça nos DOIS pontos, porque o teleporte tem saída e chegada. Sem
--- a fumaça na origem, quem estava olhando não entende para onde a pessoa foi.
function Efeitos.VENT(d)
    local origem = (d and d.origem) or pos(d)
    local destino = (d and d.destino) or origem
    local e = escala(d)
    local c = cor(d, CFG.COR_PEDRA)
    for _, onde in ipairs({ origem, destino }) do
        pk("Smoky_Explosion", onde, 1.0, 3.4 * e, c, Color3.fromRGB(90, 88, 84))
        camadaPoeira(onde, c, 0.8 * e, 14)
    end
end

function Efeitos.REUNIAO(d)
    local p, e = pos(d), escala(d)
    local raio = (d and d.raio) or 26
    local c = cor(d, Color3.fromRGB(214, 42, 58))
    for i = 1, 3 do
        task.delay((i - 1) * 0.12, function()
            camadaAnel(p - Vector3.new(0, 2, 0), c, raio * e * (1 - i * 0.22), 0.4)
        end)
    end
    pk("Sonar_Ring", CFrame.new(p), 0.6, 2 * e, raio * e, 0.6, 0.1, c, branco(c, 0.5))
    camadaFlash(p, c, 4 * e)
end

-- ── CAIXA DE SOM ────────────────────────────────────────────────────

function Efeitos.ONDA_SOM(d)
    local p, e = pos(d), escala(d)
    local raio = (d and d.raio) or 18
    local c = cor(d, CFG.COR_CURA)
    for i = 1, 3 do
        task.delay((i - 1) * 0.08, function()
            pk("Sonar_Ring", CFrame.new(p), 0.5, 1.5 * e, raio * e * (0.6 + i * 0.16),
                0.7, 0.08, c, branco(c, 0.5))
        end)
    end
    camadaFlash(p, branco(c, 0.3), 3 * e)
end

--- As notas: o que dá a leitura de "está tocando". Sobem em espiral e somem.
function Efeitos.NOTA(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_CURA)
    for i = 1, 5 do
        local a = angulo(i)
        local nota = novaParte({
            Size = Vector3.new(0.35, 0.5, 0.12) * e,
            Color = c, Transparency = 0.1,
            CFrame = CFrame.new(p + Vector3.new(math.cos(a), 0.4, math.sin(a)) * 1.2)
                * CFrame.Angles(0, a, math.rad(jitter(i) * 20)),
        })
        local haste = novaParte({
            Size = Vector3.new(0.1, 0.9, 0.1) * e,
            Color = c, Transparency = 0.1,
            CFrame = nota.CFrame * CFrame.new(0.16, 0.6, 0),
        })
        for _, peca in ipairs({ nota, haste }) do
            tween(peca, 1.1, {
                CFrame = peca.CFrame + Vector3.new(jitter(i) * 1.5, 5, jitter(i + 2) * 1.5),
                Transparency = 1,
            }, Enum.EasingStyle.Sine)
            registrar(peca, 1.3)
        end
    end
end

function Efeitos.TROCA(d)
    local origem = (d and d.origem) or pos(d)
    local destino = (d and d.destino) or origem
    local c = cor(d, CFG.COR_METAL)
    pk("Laser_Shot", origem, destino, 0.5, 0.05, 1, branco(c, 0.5), c)
    for _, onde in ipairs({ origem, destino }) do
        camadaFlash(onde, branco(c, 0.4), 4)
        pk("Small_Nova", onde, 0.26, 0, 6, branco(c, 0.6), c)
    end
end

-- ── PRIVADA SONORA ──────────────────────────────────────────────────

function Efeitos.JATO(d)
    local origem = (d and d.origem) or pos(d)
    local destino = (d and d.destino) or origem
    local e = escala(d)
    local c = cor(d, Color3.fromRGB(120, 190, 235))
    local delta = destino - origem
    if delta.Magnitude < 0.2 then return end
    local jorro = novaParte({
        Size = Vector3.new(1.6 * e, 1.6 * e, delta.Magnitude),
        Color = c, Material = Enum.Material.Glass, Transparency = 0.35,
        CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
    })
    tween(jorro, 0.34, { Transparency = 1,
        Size = Vector3.new(3.4 * e, 3.4 * e, delta.Magnitude) },
        Enum.EasingStyle.Quad)
    registrar(jorro, 0.55)
    camadaFaiscas(destino, c, 0.8 * e, 14)
    camadaFlash(destino, branco(c, 0.4), 3 * e)
end

function Efeitos.DESCARGA(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, Color3.fromRGB(120, 190, 235))
    pk("Spiral_Effect", p, 1.6 * e, c, 3, 6 * e, 5 * e)
    camadaAnel(p - Vector3.new(0, 2.2, 0), c, 12 * e, 0.4)
    camadaFlash(p, branco(c, 0.35), 5 * e)
end

--- O coro: as três cabeças invocadas. São GEOMETRIA do cliente, com prazo — a
--- Tool manda invocar e dispensar, e ninguém vira NPC.
function Efeitos.CORO(d)
    local p, e = pos(d), escala(d)
    local vida = (d and d.duracao) or 8
    local reg = registroDe(d)
    local c = cor(d, CFG.COR_METAL)
    for i = 1, 3 do
        local a = angulo(i)
        local onde = p + Vector3.new(math.cos(a), 2.4, math.sin(a)) * 4
        local cabeca = novaParte({
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(1.8, 1.8, 1.8) * e,
            Color = c, Transparency = 0.05, Material = Enum.Material.SmoothPlastic,
            CFrame = CFrame.new(onde - Vector3.new(0, 4, 0)),
        })
        tween(cabeca, 0.5, { CFrame = CFrame.new(onde) }, Enum.EasingStyle.Back)
        registrar(cabeca, vida)
        if reg then table.insert(reg, cabeca) end
    end
    camadaFlash(p, branco(c, 0.4), 4 * e)
end

-- ── POMBO CORREIO ───────────────────────────────────────────────────

function Efeitos.BICADA(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_METAL)
    camadaFlash(p, c, 1.8 * e)
    camadaFaiscas(p, c, 0.45 * e, 7)
end

--- A revoada: o enxame que persegue. Some por `Parar` e anda por `MOVER`.
function Efeitos.REVOADA(d)
    local p, e = pos(d), escala(d)
    local vida = (d and d.duracao) or 6
    local reg = registroDe(d)
    local c = cor(d, CFG.COR_METAL)
    for i = 1, 7 do
        local a = angulo(i)
        local ave = novaParte({
            Size = Vector3.new(0.8, 0.3, 1.2) * e,
            Color = c, Transparency = 0.1,
            CFrame = CFrame.new(p + Vector3.new(math.cos(a), jitter(i) * 1.4,
                math.sin(a)) * (2.4 + i * 0.2)) * CFrame.Angles(0, a, 0),
        })
        registrar(ave, vida)
        if reg then table.insert(reg, ave) end
    end
    camadaFlash(p, branco(c, 0.3), 2.6 * e)
end

function Efeitos.ENCOMENDA(d)
    local p, e = pos(d), escala(d)
    local queda = (d and d.queda) or 0.7
    local alto = p + Vector3.new(0, 60, 0)
    local caixa = novaParte({
        Size = Vector3.new(3, 3, 3) * e,
        Color = Color3.fromRGB(168, 128, 78),
        Material = Enum.Material.Fabric, Transparency = 0,
        CFrame = CFrame.new(alto),
    })
    tween(caixa, queda, { CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(220), 0) },
        Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    registrar(caixa, queda + 0.1)
    task.delay(queda, function()
        if caixa and caixa.Parent then caixa.Parent = nil end
    end)
end

function Efeitos.ENCOMENDA_FIM(d)
    local p, e = pos(d), escala(d)
    local raio = (d and d.raio) or 12
    local c = cor(d, CFG.COR_IMPACTO)
    camadaFlash(p, branco(c, 0.4), 6 * e)
    camadaPoeira(p, CFG.COR_PEDRA, 1 * e, 20)
    pk("Shockwave_Explosion", p, 0.45, 2 * e, raio * e, c, branco(c, 0.5))
end

-- ── DEU RUIM ────────────────────────────────────────────────────────

function Efeitos.DEDO(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_ZOMBA)
    camadaFlash(p, c, 2 * e)
    pk("Small_Nova", p, 0.2, 0, 4 * e, branco(c, 0.6), c)
end

function Efeitos.STONKS(d)
    local p, e = pos(d), escala(d)
    local c = cor(d, CFG.COR_CURA)
    seta(p + Vector3.new(0, 3, 0), c, 4 * e, true, 1.2)
    camadaSubida(p, c, 0.9 * e, 18)
    camadaFlash(p, branco(c, 0.4), 4 * e)
end

function Efeitos.NOT_STONKS(d)
    local p, e = pos(d), escala(d)
    local raio = (d and d.raio) or 16
    local c = cor(d, Color3.fromRGB(214, 42, 58))
    seta(p + Vector3.new(0, 7, 0), c, 4 * e, false, 1.2)
    camadaAnel(p - Vector3.new(0, 2.2, 0), c, raio * e, 0.42)
    camadaFlash(p, c, 4 * e)
end

-- ── COMPARTILHADOS ──────────────────────────────────────────────────

--- MOVER — leva o que está registrado sob um id para outra posição.
---
--- É como a revoada e o coro andam. O passo vem por TIQUE do servidor, nunca
--- por quadro: uma mensagem a cada 0.3 s, e o cliente faz o meio do caminho.
function Efeitos.MOVER(d)
    local reg = d and d.id and PorId[d.id]
    if not reg then return end
    local destino = pos(d)
    local tempo = (d and d.tempo) or 0.3
    for indice, inst in ipairs(reg.partes) do
        if inst and inst.Parent and inst:IsA("BasePart") then
            local a = angulo(indice)
            local desvio = Vector3.new(math.cos(a), jitter(indice) * 1.2,
                math.sin(a)) * (2.4 + indice * 0.2)
            tween(inst, tempo, { CFrame = CFrame.new(destino + desvio)
                * CFrame.Angles(0, a, 0) }, Enum.EasingStyle.Linear)
        end
    end
end

-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[" .. script.Name .. "/Jodro] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
