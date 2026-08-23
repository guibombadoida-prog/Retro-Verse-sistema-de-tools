-- VFXModule_Astral_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto ASTRAL
--
-- ONDE RODA: CLIENTE. O LocalScript "Client" escuta o VFXRemote e chama
-- VFX.Executar(tipo, dados). O servidor NUNCA chama este módulo e NUNCA emite
-- partícula (§12.11): ele transmite o tipo, quem desenha é quem vê.
--
-- Por isso :Emit() aqui é legítimo — não há replicação envolvida, o burst
-- nasce e morre na máquina de quem assiste.
--
-- ORIGEM DO MATERIAL
--   Tool/Moldes/  — resgatado do AstralPeriastron original: Pulsar, OrbCore,
--                   OrbOutline, os emissores de Astral Pulsar e o
--                   CelestialCircle. Tudo dentro da Tool (Regra nº 1).
--   VFXModule/Pack/ — 10 efeitos do Stella's VFX Addon, conformados §12.12.2.
--
-- MOLDE GUARDADO NÃO RENDERIZA
--   Tool equipada vive em workspace: todo BasePart descendente dela aparece.
--   Os moldes ficam guardados APAGADOS (Transparency 1, emissor Enabled
--   false) e quem acende é o CLONE, na execução. Apagar por propriedade e não
--   por script é o que faz isso valer para os outros jogadores também — eles
--   não rodam LocalScript da minha Tool.
--
-- LINGUAGEM VISUAL — o impacto é lido em camadas de tempos diferentes:
--   FLASH 0.08s (aconteceu agora) · DISCO 0.26s (escala) ·
--   LINHAS 0.18s (velocidade) · DETRITO 0.75s (peso).
--   Camadas com a mesma duração leem como borrão, não como impacto.
--
-- Zero math.random: dispersão por ÂNGULO ÁUREO e jitter senoidal por contador.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

--═══════════════════════════════════════════════════════════════
-- CONSTANTES
--═══════════════════════════════════════════════════════════════

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_ASTRAL   = Color3.fromRGB(138, 150, 255),
	COR_QUENTE   = Color3.fromRGB(255, 128, 253),
	COR_NUCLEO   = Color3.fromRGB(255, 255, 255),
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA   = "rbxasset://textures/particles/smoke_main.dds",
	LIMITE_VIVOS = 240,
}

-- Paleta do original: 9 cores sorteadas para cada orbe. Aqui o índice é
-- SEQUENCIAL, não sorteado — mesma variedade, e reprodutível entre clientes.
local PALETA = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(170, 0, 255),
	Color3.fromRGB(255, 128, 253),
	Color3.fromRGB(255, 119, 0),
	Color3.fromRGB(0, 136, 255),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(8, 0, 255),
	Color3.fromRGB(92, 255, 130),
	Color3.fromRGB(103, 255, 212),
}

local Vivos    = {}
local PorId    = {}
local contador = 0

--═══════════════════════════════════════════════════════════════
-- INFRAESTRUTURA
--═══════════════════════════════════════════════════════════════

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function corDaVez()
	return PALETA[((proximo() - 1) % #PALETA) + 1]
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
	p.Anchored     = true
	p.CanCollide   = false
	p.CanTouch     = false
	p.CanQuery     = false
	p.Massless     = true
	p.Material     = Enum.Material.Neon
	p.TopSurface   = Enum.SurfaceType.Smooth
	p.BottomSurface= Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, style, dir)
	local info = TweenInfo.new(tempo, style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, alvo)
	t:Play()
	return t
end

local function cor(d)  return (d and d.cor) or CFG.COR_ASTRAL end
local function pos(d)  return (d and d.posicao) or Vector3.new() end
local function escala(d) return (d and d.escala) or 1 end

local function branco(c, t) return Color3.new(1, 1, 1):Lerp(c, t) end

--═══════════════════════════════════════════════════════════════
-- MOLDES DA TOOL — guardados apagados, acesos no clone
--═══════════════════════════════════════════════════════════════

-- Valores originais, por caminho dentro de Tool/Moldes. Gerado por
-- FERRAMENTAS/preparar_astral.py; se o molde mudar, o número muda aqui.
local MOLDES = {
	["AstralPeriEssentials/Pulsar"] = { t = 0 },
	["AstralPeriEssentials/Pulsar/Sparkles"] = { e = false },
	["AstralPeriEssentials/Pulsar/BodyStars"] = { e = false },
	["AstralPeriEssentials/Pulsar/TopTrail/Pulse"] = { e = false },
	["AstralPeriEssentials/Pulsar/TopTrail/HeartBeat"] = { e = false },
	["AstralPeriEssentials/Pulsar/EnergyBurst"] = { e = false },
	["AstralPeriEssentials/Pulsar/BodyRings"] = { e = false },
	["AstralPeriEssentials/Pulsar/Trail"] = { e = true },
	["AstralPeriEssentials/OrbCore"] = { t = 0 },
	["AstralPeriEssentials/OrbCore/Trail"] = { e = true },
	["AstralPeriEssentials/OrbOutline"] = { t = 0 },
	["Particles/Astral Pulsar/RootSparkles"] = { e = false },
	["Particles/Astral Pulsar/AstralSparks"] = { e = false },
	["OrbSpawns"] = { e = false },
}

local raizMoldes, moldesProcurados = nil, false

local function pastaMoldes()
	if moldesProcurados then return raizMoldes end
	moldesProcurados = true
	-- script é o VFXModule; script.Parent é a Tool. Daqui não se sai da Tool.
	local tool = script.Parent
	if tool then raizMoldes = tool:FindFirstChild("Moldes") end
	return raizMoldes
end

-- Acha um molde por caminho ("AstralPeriEssentials/Pulsar"), sem yield.
local function molde(caminho)
	local no = pastaMoldes()
	if not no then return nil end
	for pedaco in string.gmatch(caminho, "[^/]+") do
		no = no:FindFirstChild(pedaco)
		if not no then return nil end
	end
	return no
end

local function acender(copia, caminho)
	local dados = MOLDES[caminho]
	if dados then
		if dados.t then copia.Transparency = dados.t end
		if dados.e ~= nil then copia.Enabled = dados.e end
	end
	for _, filho in ipairs(copia:GetChildren()) do
		local abaixo = filho.Name
		if caminho ~= "" then abaixo = caminho .. "/" .. filho.Name end
		acender(filho, abaixo)
	end
end

-- Clona um molde da Tool JÁ ACESO. Devolve nil se o molde não estiver lá —
-- todo chamador trata nil e cai no efeito procedural.
local function clonarMolde(caminho)
	local base = molde(caminho)
	if not base then return nil end
	local copia = base:Clone()
	acender(copia, caminho)
	return copia
end

local function tocar(caminho, onde, pitch)
	local som = clonarMolde(caminho)
	if not som or not som:IsA("Sound") then return nil end
	som.PlaybackSpeed = pitch or 1
	som.Parent = onde or workspace
	som:Play()
	Debris:AddItem(som, (som.TimeLength > 0 and som.TimeLength or 4) + 1)
	return som
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- Regra nº 1, sem exceção: os módulos são filhos deste ModuleScript. Nada é
-- lido de ReplicatedStorage nem do Acervo. O reforço vem DEPOIS do efeito
-- próprio e dentro de pcall — pack faltando é Tool empobrecida, não quebrada.
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
		warn("[VFXModule_Astral] pack " .. tostring(nome) .. ": " .. tostring(err))
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
		Color = branco(c, 0.2),
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, brilho or 8, raio * 4
	luz.Parent = bola
	tween(bola, 0.08, { Size = Vector3.new(raio * 1.9, raio * 1.9, raio * 1.9),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.2)
end

local function camadaDisco(p, c, raio, tempo, inclinacao)
	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, raio * 0.4, raio * 0.4),
		Color = c,
		Transparency = 0.3,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90))
			* CFrame.Angles(0, inclinacao or 0, 0),
	})
	tween(disco, tempo, { Size = Vector3.new(0.05, raio * 2.4, raio * 2.4),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(disco, tempo + 0.2)
end

local function camadaAnel(p, c, raio, tempo, normal)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio, raio),
		Color = branco(c, 0.5),
		Transparency = 0.15,
		CFrame = CFrame.new(p, p + (normal or Vector3.new(0, 1, 0)))
			* CFrame.Angles(0, math.rad(90), 0),
	})
	tween(anel, tempo, { Size = Vector3.new(0.05, raio * 2.6, raio * 2.6),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, tempo + 0.2)
end

local function camadaLinhas(p, c, quantidade, comprimento, tempo)
	local i = 0
	while i < quantidade do
		local ang = i * CFG.ANGULO_AUREO
		local dir = Vector3.new(math.cos(ang), jitter(i) * 0.35, math.sin(ang)).Unit
		local risco = novaParte({
			Size = Vector3.new(0.14, 0.14, comprimento * 0.4),
			Color = branco(c, 0.35),
			Transparency = 0.1,
			CFrame = CFrame.new(p + dir * (comprimento * 0.25), p + dir * comprimento),
		})
		tween(risco, tempo, {
			Size = Vector3.new(0.02, 0.02, comprimento * 0.9),
			CFrame = CFrame.new(p + dir * (comprimento * 0.75), p + dir * comprimento),
			Transparency = 1,
		}, Enum.EasingStyle.Exponential)
		registrar(risco, tempo + 0.2)
		i = i + 1
	end
end

local function camadaFaiscas(p, c, forca, quantidade)
	local ancora = novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(p),
	})
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture      = CFG.TEX_FAISCA
	em.Color        = ColorSequence.new(branco(c, 0.3), c)
	em.LightEmission= 1
	em.Size         = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime     = NumberRange.new(0.35, 0.75)
	em.Speed        = NumberRange.new(16 * forca, 34 * forca)
	em.SpreadAngle  = Vector2.new(180, 180)
	em.Acceleration = Vector3.new(0, -60, 0)
	em.Rate         = 0
	em.Enabled      = false
	em.Parent       = att
	em:Emit(quantidade or 24)
	registrar(ancora, 1.4)
end

local function camadaPoeira(p, c, raio)
	local ancora = novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(p),
	})
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture      = CFG.TEX_FUMACA
	em.Color        = ColorSequence.new(branco(c, 0.75), c)
	em.LightEmission= 0.25
	em.Size         = NumberSequence.new({
		NumberSequenceKeypoint.new(0, raio * 0.35),
		NumberSequenceKeypoint.new(1, raio * 1.3),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime     = NumberRange.new(0.6, 0.95)
	em.Speed        = NumberRange.new(4, 11)
	em.SpreadAngle  = Vector2.new(180, 180)
	em.Rate         = 0
	em.Enabled      = false
	em.Parent       = att
	em:Emit(20)
	registrar(ancora, 1.8)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

-- Rastro do golpe da lâmina
function Efeitos.GOLPE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	local arco = novaParte({
		Size = Vector3.new(0.3, 8 * e, 1.1 * e),
		Color = branco(c, 0.25),
		Transparency = 0.1,
		CFrame = CFrame.new(p, p + dir) * CFrame.Angles(0, 0, (d and d.giro) or 0),
	})
	tween(arco, 0.18, {
		Size = Vector3.new(0.04, 13 * e, 0.2 * e),
		CFrame = arco.CFrame * CFrame.Angles(0, 0, math.rad(30)),
	}, Enum.EasingStyle.Exponential)
	tween(arco, 0.3, { Transparency = 1 })
	registrar(arco, 0.6)
	camadaFlash(p, c, 1.1 * e, 5)
	camadaLinhas(p, c, 5, 5 * e, 0.2)
	pk("Small_Slash", CFrame.new(p, p + dir) * CFrame.Angles(0, 0, (d and d.giro) or 0),
		9 * e, 0.22, branco(c, 0.3), c)
end

function Efeitos.IMPACTO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 1.6 * e, 6)
	camadaAnel(p, c, 3.2 * e, 0.4, d and d.normal)
	camadaLinhas(p, c, 7, 4.5 * e, 0.28)
	camadaFaiscas(p, c, 0.8 * e, 18)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.26,
		Vector3.new(2, 0.35, 2) * e, Vector3.new(9, 0.35, 9) * e,
		branco(c, 0.35), c, Enum.EasingStyle.Quint)
end

function Efeitos.IMPACTO_NOVA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 3.2 * e, 14)
	camadaDisco(p, c, 6 * e, 0.6)
	camadaAnel(p, c, 5 * e, 0.5)
	camadaAnel(p, branco(c, 0.5), 3.4 * e, 0.34)
	camadaLinhas(p, c, 16, 11 * e, 0.4)
	camadaFaiscas(p, c, 1.6 * e, 46)
	camadaPoeira(p, c, 5 * e)
	pk("Small_Nova", p, 0.5, 0, 26 * e, CFG.COR_NUCLEO, c, Enum.EasingStyle.Quint)
	pk("Shockwave_2", CFrame.new(p), CFrame.new(p), 0.30,
		Vector3.new(3, 0.4, 3) * e, Vector3.new(16, 0.4, 16) * e,
		branco(c, 0.5), c, Enum.EasingStyle.Quint)
	pk("Smoky_Explosion", p, 0.9, 7 * e, branco(c, 0.7), c)
end

-- Orbe astral: o molde do modelo original, aceso
function Efeitos.ORBE(d)
	local p, e = pos(d), escala(d)
	local c = (d and d.cor) or corDaVez()

	local nucleo = clonarMolde("AstralPeriEssentials/OrbCore")
	if nucleo then
		nucleo.Color    = c
		nucleo.Anchored = true
		nucleo.CanCollide, nucleo.CanTouch, nucleo.CanQuery = false, false, false
		nucleo.CFrame   = CFrame.new(p)
		nucleo.Size     = nucleo.Size * e
		nucleo.Parent   = workspace
		registrar(nucleo, (d and d.duracao) or 25)

		local casca = clonarMolde("AstralPeriEssentials/OrbOutline")
		if casca then
			casca.Color    = branco(c, 0.4)
			casca.Anchored = true
			casca.CanCollide, casca.CanTouch, casca.CanQuery = false, false, false
			casca.CFrame   = nucleo.CFrame
			casca.Size     = casca.Size * e
			casca.Parent   = nucleo
			tween(casca, 0.3, { Size = casca.Size * 1.25 }, Enum.EasingStyle.Back)
		end

		if d and d.id then
			PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
			table.insert(PorId[d.id].partes, nucleo)
		end
	else
		-- sem o molde a Tool empobrece, não quebra
		camadaFlash(p, c, 1.4 * e, 6)
	end

	local faisca = clonarMolde("OrbSpawns")
	if faisca then
		local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
			Transparency = 1, CFrame = CFrame.new(p) })
		local att = Instance.new("Attachment")
		att.Parent = ancora
		faisca.Parent = att
		faisca:Emit(24)
		registrar(ancora, 2)
	end
end

function Efeitos.ORBE_DETONA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 2.4 * e, 11)
	camadaAnel(p, c, 4.2 * e, 0.42)
	camadaLinhas(p, c, 12, 8 * e, 0.32)
	camadaFaiscas(p, c, 1.2 * e, 34)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.34,
		Vector3.new(2, 0.3, 2) * e, Vector3.new(14, 0.3, 14) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quint)
	pk("Floor_Crack", CFrame.new(p), 7 * e, 2.4, c)
end

-- Pulsar Astral: o mesh do original, suspenso, com anéis e raio
function Efeitos.PULSAR(d)
	local p, c = pos(d), cor(d)
	local corpo = clonarMolde("AstralPeriEssentials/Pulsar")
	if corpo then
		corpo.Anchored = true
		corpo.CanCollide, corpo.CanTouch, corpo.CanQuery = false, false, false
		corpo.CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(180), math.rad(180))
		corpo.Parent = workspace
		registrar(corpo, (d and d.duracao) or 30)
		if d and d.id then
			PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
			table.insert(PorId[d.id].partes, corpo)
		end
		local respiro = clonarMolde("Particles/Astral Pulsar/AstralSparks")
		if respiro then
			respiro.Parent = corpo
			respiro:Emit(respiro.Rate > 0 and respiro.Rate or 40)
		end
	else
		camadaFlash(p, c, 5, 20)
	end
	camadaAnel(p, c, 12, 0.7)
	camadaAnel(p, branco(c, 0.5), 8, 0.5)
	tocar("Sounds/Astral Pulsar/Bam", corpo or workspace)
	pk("Sonar_Ring", CFrame.new(p), 1.1, 3, 60, 2.2, 0.2, branco(c, 0.5), c)
end

function Efeitos.PULSAR_TICK(d)
	local p, c = pos(d), cor(d)
	camadaAnel(p, c, 7, 0.4)
	pk("Sonar_Ring", CFrame.new(p), 0.7, 2, 26, 1.2, 0.1, branco(c, 0.4), c)
end

-- Nova Estelar (Astral Nova)
function Efeitos.NOVA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, CFG.COR_NUCLEO, 4 * e, 18)
	camadaDisco(p, c, 9 * e, 0.5)
	camadaLinhas(p, c, 20, 15 * e, 0.36)
	camadaFaiscas(p, c, 1.8 * e, 52)
	pk("Small_Nova", p, 0.55, 0, 34 * e, CFG.COR_NUCLEO, c, Enum.EasingStyle.Quint)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.5,
		Vector3.new(3, 0.3, 3) * e, Vector3.new(30, 0.3, 30) * e, c, c,
		Enum.EasingStyle.Quad)
end

-- Colapso Anão: o anel vem de FORA para dentro (fim menor que começo)
function Efeitos.COLAPSO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Sonar_Ring", CFrame.new(p), 0.65, 30 * e, 2, 0.2, 1.8, c, branco(c, 0.5))
	camadaAnel(p, c, 3 * e, 0.5)
	local i = 0
	while i < 10 do
		local ang = i * CFG.ANGULO_AUREO
		local raio = (9 + jitter(i) * 3) * e
		local de = p + Vector3.new(math.cos(ang) * raio, jitter(i + 7) * 3, math.sin(ang) * raio)
		local caco = novaParte({
			Size = Vector3.new(0.5, 0.5, 0.5) * e,
			Color = branco(c, 0.3),
			Transparency = 0.15,
			CFrame = CFrame.new(de),
		})
		tween(caco, 0.45, { CFrame = CFrame.new(p), Size = Vector3.new(0.05, 0.05, 0.05),
			Transparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		registrar(caco, 0.8)
		i = i + 1
	end
end

-- Cometa (Astral Cometa) — cabeça incandescente com cauda
function Efeitos.COMETA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, branco(c, 0.2), 1.8 * e, 9)
	camadaFaiscas(p, c, 1.1 * e, 26)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	pk("Laser_Shot", p - dir * 12 * e, p, 0.9 * e, 0.05, 12 * e,
		branco(c, 0.5), c, "Cylinder", 0.3)
end

function Efeitos.CHUVA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaAnel(p, c, 10 * e, 0.6, Vector3.new(0, 1, 0))
	pk("Floor_Crack", CFrame.new(p), 12 * e, 3, c)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.4,
		Vector3.new(2, 0.3, 2) * e, Vector3.new(18, 0.3, 18) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quint)
end

-- Horizonte de Eventos (Astral Singularidade)
function Efeitos.HORIZONTE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.4, 0.4, 0.4),
		Color = Color3.new(0, 0, 0),
		Material = Enum.Material.Glass,
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	tween(bola, 0.4, { Size = Vector3.new(7, 7, 7) * e }, Enum.EasingStyle.Back)
	tween(bola, (d and d.duracao) or 4, { Transparency = 1 })
	registrar(bola, ((d and d.duracao) or 4) + 0.5)
	if d and d.id then
		PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
		table.insert(PorId[d.id].partes, bola)
	end
	camadaAnel(p, c, 9 * e, 0.7)
	pk("Sonar_Ring", CFrame.new(p), 0.9, 24 * e, 3, 0.2, 1.4, c, branco(c, 0.5))
end

function Efeitos.ESPAGUETE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local i = 0
	while i < 6 do
		local fio = novaParte({
			Size = Vector3.new(0.2, 0.2, 3),
			Color = branco(c, 0.4),
			Transparency = 0.1,
			CFrame = CFrame.new(p) * CFrame.Angles(0, i * CFG.ANGULO_AUREO, 0)
				* CFrame.new(0, jitter(i) * 2, 0),
		})
		tween(fio, 0.35, { Size = Vector3.new(0.02, 0.02, 26 * e), Transparency = 1 },
			Enum.EasingStyle.Exponential)
		registrar(fio, 0.8)
		i = i + 1
	end
	camadaFlash(p, CFG.COR_NUCLEO, 3 * e, 16)
	pk("Small_Slash", CFrame.new(p) * CFrame.Angles(0, 0, math.rad(45)),
		14 * e, 0.24, CFG.COR_NUCLEO, c)
	pk("Small_Slash", CFrame.new(p) * CFrame.Angles(0, 0, math.rad(-45)),
		14 * e, 0.3, CFG.COR_NUCLEO, c)
end

-- Traço Sideral (Astral Constelacao) — a marca que fica no alvo
function Efeitos.TRACO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local marca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.7, 0.7, 0.7) * e,
		Color = branco(c, 0.4),
		Transparency = 0.25,
		CFrame = CFrame.new(p),
	})
	tween(marca, 0.25, { Size = Vector3.new(1.1, 1.1, 1.1) * e }, Enum.EasingStyle.Back)
	registrar(marca, (d and d.duracao) or 8)
	if d and d.id then
		PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
		table.insert(PorId[d.id].partes, marca)
	end
	camadaFlash(p, c, 0.9 * e, 4)
end

-- Sentença: liga as marcas duas a duas e apaga
function Efeitos.SENTENCA(d)
	local c = cor(d)
	local pontos = (d and d.pontos) or {}
	local i = 1
	while i < #pontos do
		local a, b = pontos[i], pontos[i + 1]
		local dist = (b - a).Magnitude
		if dist > 0.1 then
			local linha = novaParte({
				Size = Vector3.new(0.22, 0.22, dist),
				Color = branco(c, 0.45),
				Transparency = 0.1,
				CFrame = CFrame.new(a:Lerp(b, 0.5), b),
			})
			tween(linha, 0.4, { Size = Vector3.new(0.02, 0.02, dist),
				Transparency = 1 }, Enum.EasingStyle.Exponential)
			registrar(linha, 0.8)
		end
		i = i + 1
	end
	for _, ponto in ipairs(pontos) do
		camadaFlash(ponto, CFG.COR_NUCLEO, 1.6, 9)
		pk("Small_Nova", ponto, 0.4, 0, 12, CFG.COR_NUCLEO, c, Enum.EasingStyle.Quint)
	end
end

function Efeitos.ONDA_CHOQUE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaDisco(p, c, 8 * e, 0.5)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.5,
		Vector3.new(3, 0.3, 3) * e, Vector3.new(34, 0.3, 34) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quad)
end

function Efeitos.POEIRA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaPoeira(p, c, 5 * e)
	pk("Smoky_Explosion", p, 1.3, 5 * e, branco(c, 0.8), c)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Astral] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
