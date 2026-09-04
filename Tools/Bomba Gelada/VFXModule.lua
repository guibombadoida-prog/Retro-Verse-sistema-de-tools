-- VFXModule_Bombas_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto BOMBAS
--
-- ONDE RODA: CLIENTE. O servidor transmite o tipo pelo VFXRemote; quem desenha
-- é quem vê (§12.11). Por isso `:Emit()` aqui é legítimo — não há replicação.
--
-- LINGUAGEM VISUAL: explosão é lida em camadas de tempos diferentes —
--   FLASH 0.08 s (aconteceu agora) · BOLA 0.35 s (o volume) ·
--   ANEL 0.5 s (a escala) · FUMAÇA 1.4 s (o peso que fica).
-- Camadas com a mesma duração leem como borrão, não como explosão.
--
-- O original animava a explosão num `while tick() - startTime < duration` com
-- `Heartbeat:Wait()`, no SERVIDOR. Duas coisas erradas: `tick()` alimentando
-- geometria, e geometria movida por frame no servidor (replica a ~20 Hz, sem
-- interpolação). Aqui a expansão é Tween, no cliente.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_FOGO     = Color3.fromRGB(255, 151, 0),
	COR_NUCLEO   = Color3.fromRGB(255, 245, 214),
	COR_GELO     = Color3.fromRGB(150, 220, 255),
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA   = "rbxasset://textures/particles/smoke_main.dds",
	LIMITE_VIVOS = 240,
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
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(tempo,
		style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), alvo)
	t:Play()
	return t
end

local function cor(d) return (d and d.cor) or CFG.COR_FOGO end
local function pos(d) return (d and d.posicao) or Vector3.new() end
local function escala(d) return (d and d.escala) or 1 end
local function branco(c, t) return Color3.new(1, 1, 1):Lerp(c, t) end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- Regra nº 1, sem exceção: os módulos são filhos deste ModuleScript. O reforço
-- vem DEPOIS do efeito próprio e dentro de pcall — pack faltando é Tool
-- empobrecida, não quebrada.
--
-- O original fazia `require(8199013483)` — id numérico, execução de código
-- remoto. Isso não entra em Tool nenhuma. O pack aqui é o Stella conformado
-- pelo §12.12.2, copiado para dentro.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function deposito()
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

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[VFXModule_Bombas] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

local function camadaFlash(p, c, raio, brilho)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio),
		Color = branco(c, 0.15),
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, brilho or 10, raio * 5
	luz.Parent = bola
	tween(bola, 0.08, { Size = Vector3.new(raio, raio, raio) * 1.9,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.25)
end

-- O volume da explosão: bola que cresce e some
local function camadaBola(p, c, raio, tempo)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 0.4, raio * 0.4, raio * 0.4),
		Color = c,
		Transparency = 0.1,
		CFrame = CFrame.new(p),
	})
	tween(bola, tempo, { Size = Vector3.new(raio, raio, raio) * 1.8,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, tempo + 0.2)
end

local function camadaAnel(p, c, raio, tempo)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, raio * 0.5, raio * 0.5),
		Color = branco(c, 0.5),
		Transparency = 0.2,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, tempo, { Size = Vector3.new(0.06, raio * 2.6, raio * 2.6),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, tempo + 0.2)
end

local function camadaFaiscas(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.25), c)
	em.LightEmission = 1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.35, 0.8)
	em.Speed = NumberRange.new(18 * forca, 40 * forca)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Acceleration = Vector3.new(0, -70, 0)
	em.Rate, em.Enabled = 0, false
	em.Parent = att
	em:Emit(quantidade or 30)
	registrar(ancora, 1.5)
end

local function camadaFumaca(p, c, raio, subir)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FUMACA
	em.Color = ColorSequence.new(branco(c, 0.7), Color3.fromRGB(60, 55, 50))
	em.LightEmission = 0.2
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, raio * 0.4),
		NumberSequenceKeypoint.new(1, raio * 1.5),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.9, 1.4)
	em.Speed = NumberRange.new(6, 16)
	em.SpreadAngle = Vector2.new(180, 180)
	if subir then em.Acceleration = Vector3.new(0, 14, 0) end
	em.Rate, em.Enabled = 0, false
	em.Parent = att
	em:Emit(26)
	registrar(ancora, 2.2)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

-- Explosão comum. `escala` vem do servidor: 2 na principal, 0.6 na mini —
-- os mesmos números do modelo original.
function Efeitos.EXPLOSAO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, CFG.COR_NUCLEO, 3 * e, 12 * e)
	camadaBola(p, c, 8 * e, 0.35)
	camadaAnel(p, c, 6 * e, 0.5)
	camadaFaiscas(p, c, e, math.floor(24 * e) + 8)
	camadaFumaca(p, c, 5 * e, false)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.42,
		Vector3.new(3, 0.35, 3) * e, Vector3.new(20, 0.35, 20) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quint)
	pk("Smoky_Explosion", p, 0.9, 5 * e, branco(c, 0.6), c)
	pk("Floor_Crack", CFrame.new(p), 8 * e, 2.5, c)
end

function Efeitos.EXPLOSAO_MINI(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, CFG.COR_NUCLEO, 1.4 * e, 6)
	camadaBola(p, c, 4 * e, 0.28)
	camadaFaiscas(p, c, 0.7 * e, 16)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.26,
		Vector3.new(1.5, 0.3, 1.5) * e, Vector3.new(9, 0.3, 9) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quint)
end

-- Nuke: o cogumelo é a assinatura. Haste, chapéu e três anéis em tempos
-- diferentes — é a diferença entre "explosão grande" e "nuclear".
function Efeitos.NUKE(d)
	local p, c, e = pos(d), cor(d), escala(d)

	camadaFlash(p, CFG.COR_NUCLEO, 10 * e, 40)
	camadaBola(p, c, 22 * e, 0.5)

	local i = 0
	while i < 3 do
		local atraso = i * 0.18
		task.delay(atraso, function()
			camadaAnel(p + Vector3.new(0, 1 + i * 2, 0), c, (16 + i * 10) * e, 0.7)
		end)
		i = i + 1
	end

	-- haste
	local haste = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4 * e, 5 * e, 5 * e),
		Color = branco(c, 0.5),
		Transparency = 0.25,
		CFrame = CFrame.new(p + Vector3.new(0, 4 * e, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(haste, 1.1, {
		Size = Vector3.new(46 * e, 11 * e, 11 * e),
		CFrame = CFrame.new(p + Vector3.new(0, 26 * e, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
	}, Enum.EasingStyle.Quad)
	registrar(haste, 1.6)

	-- chapéu
	task.delay(0.35, function()
		local chapeu = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(8 * e, 8 * e, 8 * e),
			Color = c,
			Transparency = 0.2,
			CFrame = CFrame.new(p + Vector3.new(0, 30 * e, 0)),
		})
		tween(chapeu, 1.3, { Size = Vector3.new(44 * e, 26 * e, 44 * e),
			Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(chapeu, 1.8)
		camadaFumaca(p + Vector3.new(0, 30 * e, 0), c, 16 * e, true)
	end)

	camadaFaiscas(p, c, 2.2 * e, 90)
	camadaFumaca(p, c, 14 * e, true)
	pk("Small_Nova", p, 0.7, 0, 70 * e, CFG.COR_NUCLEO, c, Enum.EasingStyle.Quint)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.9,
		Vector3.new(4, 0.4, 4) * e, Vector3.new(120, 0.4, 120) * e,
		branco(c, 0.5), c, Enum.EasingStyle.Quad)
	pk("Floor_Crack", CFrame.new(p), 40 * e, 5, c)
end

-- Meteoro caindo: risco incandescente na diagonal, do céu ao ponto
function Efeitos.METEORO(d)
	local de = (d and d.origem) or Vector3.new()
	local para = pos(d)
	local c, e = cor(d), escala(d)
	local duracao = (d and d.duracao) or 1

	local dist = (para - de).Magnitude
	if dist < 0.1 then return end

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6 * e, 6 * e, 6 * e),
		Color = c,
		Transparency = 0.05,
		CFrame = CFrame.new(de),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 14, 40
	luz.Parent = bola

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 2.5 * e, 0)
	a0.Parent = bola
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -2.5 * e, 0)
	a1.Parent = bola
	local rastro = Instance.new("Trail")
	rastro.Attachment0, rastro.Attachment1 = a0, a1
	rastro.FaceCamera = true
	rastro.Lifetime = 0.45
	rastro.Color = ColorSequence.new(CFG.COR_NUCLEO, c)
	rastro.LightEmission = 1
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.WidthScale = NumberSequence.new(1, 0)
	rastro.Parent = bola

	tween(bola, duracao, { CFrame = CFrame.new(para) },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(bola, duracao + 0.4)
end

-- Quique do basquete: anel raso e poeira, sem estourar
function Efeitos.QUICA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaAnel(p, c, 3 * e, 0.3)
	camadaFaiscas(p, c, 0.4 * e, 8)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.22,
		Vector3.new(1.2, 0.25, 1.2) * e, Vector3.new(6, 0.25, 6) * e,
		branco(c, 0.5), c, Enum.EasingStyle.Quint)
end

-- Gelo: estilhaço frio, sem fogo
function Efeitos.GELO(d)
	local p, e = pos(d), escala(d)
	local c = (d and d.cor) or CFG.COR_GELO
	camadaFlash(p, branco(c, 0.4), 2.4 * e, 8)
	camadaAnel(p, c, 6 * e, 0.55)

	local i = 0
	while i < 9 do
		local ang = i * CFG.ANGULO_AUREO
		local raio = (2 + jitter(i) * 1.5) * e
		local lasca = novaParte({
			Size = Vector3.new(0.5 * e, (2.6 + jitter(i + 3)) * e, 0.5 * e),
			Color = c,
			Material = Enum.Material.Ice,
			Transparency = 0.25,
			CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * raio, 0,
				math.sin(ang) * raio))
				* CFrame.Angles(math.rad(jitter(i) * 22), ang, math.rad(jitter(i + 5) * 22)),
		})
		lasca.Size = Vector3.new(lasca.Size.X, 0.2, lasca.Size.Z)
		tween(lasca, 0.22, { Size = Vector3.new(0.5 * e, (3 + jitter(i)) * e, 0.5 * e) },
			Enum.EasingStyle.Back)
		tween(lasca, 1.6, { Transparency = 1 })
		registrar(lasca, 1.9)
		i = i + 1
	end
	camadaFaiscas(p, c, 0.6 * e, 14)
end

-- Chão de gelo: disco que fica, com id para o servidor apagar depois
function Efeitos.CHAO_GELO(d)
	local p, e = pos(d), escala(d)
	local c = (d and d.cor) or CFG.COR_GELO
	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 1, 1),
		Color = c,
		Material = Enum.Material.Ice,
		Transparency = 0.45,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(disco, 0.3, { Size = Vector3.new(0.4, 2 * e, 2 * e) },
		Enum.EasingStyle.Back)
	registrar(disco, (d and d.duracao) or 8)
	if d and d.id then
		PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
		table.insert(PorId[d.id].partes, disco)
	end
	pk("Sonar_Ring", CFrame.new(p), 0.6, 2, 2 * e, 1.2, 0.2, branco(c, 0.5), c)
end

-- A bomba-NPC ficando brava: aura que aperta conforme a raiva sobe
function Efeitos.RAIVA(d)
	local p, e = pos(d), escala(d)
	local nivel = math.clamp((d and d.nivel) or 0, 0, 1)
	local c = Color3.fromRGB(255, 151, 0):Lerp(Color3.fromRGB(255, 40, 30), nivel)
	camadaAnel(p, c, (1.6 + nivel * 2.4) * e, 0.34)
	camadaFaiscas(p, c, 0.35 + nivel * 0.5, 6 + math.floor(nivel * 10))
end

function Efeitos.RASTRO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFaiscas(p, c, 0.3 * e, 5)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Bombas] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
