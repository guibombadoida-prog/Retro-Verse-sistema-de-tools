-- VFXModule_Escudos_V2.lua
-- ModuleScript "VFXModule" — executor de VFX da família ESCUDOS
--
-- ONDE RODA: CLIENTE. O LocalScript "Client" da Tool escuta o VFXRemote e
-- chama VFX.Executar(tipo, dados). O servidor NUNCA chama este módulo e
-- NUNCA emite partícula (§12.11 / §4.3 das DIRETRIZES_VFX).
--
-- Por isso :Emit() aqui é legítimo: não há replicação envolvida — o burst
-- nasce e morre na máquina de quem vê.
--
-- LINGUAGEM VISUAL (referência: pack Saitama)
--   O impacto do pack é lido em 4 camadas sobrepostas, sempre nesta ordem:
--     1. FLASH   — clarão branco de 1 frame, some em ~0.08 s
--     2. DISCO   — onda de choque achatada, cresce e afina
--     3. LINHAS  — estrias radiais finas que saem do ponto (velocidade)
--     4. DETRITO — faíscas + poeira, a única camada que persiste
--   Nenhum efeito usa math.random: dispersão por ÂNGULO ÁUREO (137.507°) e
--   jitter senoidal por contador. Zero ScreenGui, zero ColorCorrection.
--
-- V2 — MATERIAL IMPORTADO (§12.12, ver bloco marcado mais abaixo)
--   [JC] Judgement Cut End .......... GRADE_CORTES, TEMPO_PARADO, DESTROCOS,
--                                     RAJADA, ZOOM, presets de TREMOR, texturas
--   [DE] Domain Expansion(Elemental)  CORTE_X, DOMO
--
-- LIMPEZA: tudo nasce sob workspace.Terrain (não polui a árvore de Models),
-- é registrado em Vivos e removido por Debris/Parent=nil. VFX.LimparTudo()
-- é chamado pelo Client em Tool.Destroying e no Humanoid.Died do portador.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

--═══════════════════════════════════════════════════════════════
-- CONSTANTES
--═══════════════════════════════════════════════════════════════

local CFG = {
	ANGULO_AUREO   = math.rad(137.507764),
	PAI            = workspace,   -- efeitos nascem direto no workspace
	COR_PADRAO     = Color3.fromRGB(90, 190, 255),
	TEX_FAISCA     = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA     = "rbxasset://textures/particles/smoke_main.dds",
	VIDA_CURTA     = 1.2,
	VIDA_MEDIA     = 2.5,
	LIMITE_VIVOS   = 220,   -- teto de instâncias simultâneas por cliente
}

-- Registro de efeitos vivos (para limpeza e para efeitos com id)
local Vivos     = {}   -- lista simples de Instances
local PorId     = {}   -- [id] = { partes = {}, conexoes = {} }
local contador  = 0    -- contador determinístico (substitui math.random)

--═══════════════════════════════════════════════════════════════
-- INFRAESTRUTURA
--═══════════════════════════════════════════════════════════════

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

-- jitter determinístico em [-1, 1], varia a cada chamada
local function jitter(fase)
	local n = proximo()
	return math.sin(n * 2.399963 + (fase or 0))
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
	p.CastShadow   = false
	p.Material     = Enum.Material.Neon
	p.TopSurface   = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	p.Parent = CFG.PAI
	return p
end

-- Indexar um Enum com nome inválido ERRA no Roblox (não devolve nil).
-- Por isso todo estilo passa por uma tabela branca antes de virar TweenInfo.
local ESTILOS = {
	Linear = Enum.EasingStyle.Linear,
	Sine = Enum.EasingStyle.Sine,
	Back = Enum.EasingStyle.Back,
	Quad = Enum.EasingStyle.Quad,
	Quart = Enum.EasingStyle.Quart,
	Quint = Enum.EasingStyle.Quint,
	Cubic = Enum.EasingStyle.Cubic,
	Circular = Enum.EasingStyle.Circular,
	Bounce = Enum.EasingStyle.Bounce,
	Elastic = Enum.EasingStyle.Elastic,
	Exponential = Enum.EasingStyle.Exponential,
}

local function estiloValido(style)
	if typeof(style) == "EnumItem" then return style end
	if type(style) == "string" then return ESTILOS[style] end
	return nil
end

local function tween(inst, tempo, alvo, style, dir)
	local ok, tw = pcall(function()
		local ti = TweenInfo.new(
			tempo,
			estiloValido(style) or Enum.EasingStyle.Quint,
			(typeof(dir) == "EnumItem" and dir) or Enum.EasingDirection.Out
		)
		local t = TweenService:Create(inst, ti, alvo)
		t:Play()
		return t
	end)
	if not ok then
		warn("[VFXModule_Escudos] tween invalido: " .. tostring(tw))
		return nil
	end
	return tw
end

local function cor(d)
	return (d and d.cor) or CFG.COR_PADRAO
end

local function pos(d)
	return (d and d.posicao) or Vector3.new()
end

local function escala(d)
	return (d and d.escala) or 1
end

--═══════════════════════════════════════════════════════════════
-- CAMADA 1 — FLASH (clarão de 1 frame)
--═══════════════════════════════════════════════════════════════

local function camadaFlash(p, c, raio, brilho)
	local bola = novaParte({
		Shape        = Enum.PartType.Ball,
		Size         = Vector3.new(raio, raio, raio),
		Color        = Color3.new(1, 1, 1):Lerp(c, 0.25),
		Transparency = 0.05,
		CFrame       = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color      = c
	luz.Brightness = brilho or 8
	luz.Range      = raio * 3
	luz.Parent     = bola

	tween(bola, 0.09, { Size = Vector3.new(raio * 2.4, raio * 2.4, raio * 2.4), Transparency = 1 })
	tween(luz, 0.14, { Brightness = 0, Range = 0 })
	registrar(bola, 0.35)
	return bola
end

--═══════════════════════════════════════════════════════════════
-- CAMADA 2 — DISCO / ANEL de choque
--═══════════════════════════════════════════════════════════════

local function camadaDisco(p, c, raio, tempo, inclinacao)
	local disco = novaParte({
		Shape        = Enum.PartType.Cylinder,
		Size         = Vector3.new(0.35, raio * 0.35, raio * 0.35),
		Color        = c,
		Transparency = 0.25,
		CFrame       = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)) * (inclinacao or CFrame.new()),
	})
	tween(disco, tempo or 0.55, {
		Size         = Vector3.new(0.06, raio * 3.2, raio * 3.2),
		Transparency = 1,
	})
	registrar(disco, (tempo or 0.55) + 0.3)
	return disco
end

local function camadaAnel(p, c, raio, tempo, normal)
	local anel = novaParte({
		Shape        = Enum.PartType.Cylinder,
		Size         = Vector3.new(0.6, raio * 0.5, raio * 0.5),
		Color        = c,
		Transparency = 0.4,
		CFrame       = CFrame.new(p, p + (normal or Vector3.new(0, 1, 0))) * CFrame.Angles(0, math.rad(90), 0),
	})
	tween(anel, tempo or 0.45, {
		Size         = Vector3.new(0.08, raio * 2.6, raio * 2.6),
		Transparency = 1,
	})
	registrar(anel, (tempo or 0.45) + 0.3)
	return anel
end

--═══════════════════════════════════════════════════════════════
-- CAMADA 3 — LINHAS DE VELOCIDADE (estrias radiais)
--═══════════════════════════════════════════════════════════════

local function camadaLinhas(p, c, quantidade, comprimento, tempo, achatado)
	quantidade = quantidade or 10
	for i = 1, quantidade do
		local ang = i * CFG.ANGULO_AUREO
		local elev = achatado and 0 or (math.sin(i * 1.7) * 0.55)
		local dir = Vector3.new(math.cos(ang), elev, math.sin(ang)).Unit
		local comp = comprimento * (0.65 + 0.35 * math.abs(math.sin(i * 2.3)))

		local linha = novaParte({
			Size         = Vector3.new(0.14, 0.14, 0.8),
			Color        = c,
			Transparency = 0.15,
			CFrame       = CFrame.new(p + dir * (comp * 0.25), p + dir * comp),
		})
		tween(linha, tempo or 0.32, {
			Size         = Vector3.new(0.02, 0.02, comp * 1.6),
			CFrame       = CFrame.new(p + dir * (comp * 1.15), p + dir * comp * 2),
			Transparency = 1,
		}, Enum.EasingStyle.Quart)
		registrar(linha, (tempo or 0.32) + 0.25)
	end
end

--═══════════════════════════════════════════════════════════════
-- CAMADA 4 — DETRITO (faíscas + poeira)
--═══════════════════════════════════════════════════════════════

local function camadaFaiscas(p, c, forca, quantidade)
	local base = novaParte({
		Size         = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame       = CFrame.new(p),
	})
	local att = Instance.new("Attachment")
	att.Parent = base

	local pe = Instance.new("ParticleEmitter")
	pe.Texture      = CFG.TEX_FAISCA
	pe.Color        = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.35, c),
		ColorSequenceKeypoint.new(1, c),
	})
	pe.LightEmission = 1
	pe.LightInfluence = 0
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9 * (forca or 1)),
		NumberSequenceKeypoint.new(0.7, 0.35 * (forca or 1)),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.75, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime     = NumberRange.new(0.35, 0.8)
	pe.Speed        = NumberRange.new(14 * (forca or 1), 30 * (forca or 1))
	pe.SpreadAngle  = Vector2.new(180, 180)
	pe.Drag         = 4
	pe.Acceleration = Vector3.new(0, -42, 0)
	pe.Rate         = 0
	pe.Enabled      = false
	pe.Parent       = att
	pe:Emit(quantidade or 26)

	registrar(base, 1.4)
end

local function camadaPoeira(p, c, raio)
	local base = novaParte({
		Size         = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame       = CFrame.new(p),
	})
	local att = Instance.new("Attachment")
	att.Parent = base

	local pe = Instance.new("ParticleEmitter")
	pe.Texture       = CFG.TEX_FUMACA
	pe.Color         = ColorSequence.new(Color3.new(1, 1, 1):Lerp(c, 0.35))
	pe.LightEmission = 0.15
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, raio * 0.5),
		NumberSequenceKeypoint.new(1, raio * 2.1),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime    = NumberRange.new(0.7, 1.3)
	pe.Speed       = NumberRange.new(raio * 1.6, raio * 3.2)
	pe.SpreadAngle = Vector2.new(180, 8)
	pe.Drag        = 6
	pe.Rotation    = NumberRange.new(-120, 120)
	pe.RotSpeed    = NumberRange.new(-40, 40)
	pe.Rate        = 0
	pe.Enabled     = false
	pe.Parent      = att
	pe:Emit(math.clamp(math.floor(raio * 2.5), 8, 40))

	registrar(base, 2.2)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS PÚBLICOS
--═══════════════════════════════════════════════════════════════

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL
--
-- REGRA Nº 1, SEM EXCEÇÃO. Os módulos do pack são filhos deste ModuleScript,
-- em `VFXModule/Pack/`. Nada é lido de ReplicatedStorage, de ServerStorage
-- nem do Acervo. O teste do place vazio vale inteiro, VFX incluído.
--
-- POR QUE ISTO ESTAVA ERRADO ANTES
--
--   Eu tinha posto o pack em ReplicatedStorage e chamado de "exceção
--   declarada", com o argumento de que ele não cabia dentro. O argumento
--   valia para o `MainModule` — que se muda para lá sozinho e manda requerer
--   por id — e eu generalizei do loader para o pack inteiro.
--
--   Os MÓDULOS DE EFEITO não dependem de nada: nenhum require, nenhum
--   ReplicatedStorage, nenhum Takeo. Conferido nos 10 que esta Tool usa.
--   Cabiam dentro desde o começo.
--
-- O QUE CONTINUA VALENDO
--
--   1. NUNCA YIELDA.  FindFirstChild, jamais WaitForChild.
--   2. NUNCA DERRUBA O EFEITO PRÓPRIO.  O efeito da Tool roda primeiro e
--      inteiro; o reforço vem depois, dentro de pcall. Módulo faltando ou
--      quebrado = a Tool empobrece, não quebra.
--   3. NÃO IMPORTA REGRA DE JOGO.  Daqui só sai forma, cor e tempo.
--
-- Os 10 passaram pelo passe §12.12.2 antes de entrar (FERRAMENTAS/
-- conformar_pack_vfx.py): 9 math.random viraram ângulo áureo e jitter
-- senoidal, um WaitForChild por módulo virou acesso direto, e o
-- workspace:FindFirstChild("Terrain") do Floor_Crack virou workspace.Terrain.
--
-- EFEITOS DO PACK QUE FICARAM DE FORA, E POR QUÊ  (a lista não é preguiça,
-- foi lida no código de cada módulo):
--
--   Flung_Debris, Particle_Debris .. criam Part não-ancorada com
--                                    AssemblyLinearVelocity e CanCollide
--                                    (o parâmetro CanCollide é inerte: o
--                                    módulo faz `CanCollide or true`).
--                                    Detrito sólido no cliente empurra o
--                                    próprio personagem — VFX não mexe em
--                                    gameplay.
--   Impact_Frame ................... troca o Sky, liga ColorCorrection e põe
--                                    ScreenGui. As três são proibidas dentro
--                                    de Tool (efeito só no mundo 3D).
--   Sharp_Crater, Smooth_Crater .... varrem workspace:GetDescendants() a cada
--                                    chamada. Numa arena cheia isso é engasgo
--                                    de frame no impacto — justo onde não pode.
--   Wind_Effect, Wind_Spiral ....... exigem uma Instance de fora como âncora.
--   Fire_Circle .................... contrato quebrado no próprio pack: usa
--                                    Size como Vector3 e depois chama
--                                    :Emit(Size), que espera número.
--
-- O que sobrou é o que é ancorado, movido a Tween e fechado nos argumentos.
--═══════════════════════════════════════════════════════════════

local PACK = {
	LIGADO = true,     -- desligue aqui para voltar só ao VFX próprio da Tool
	PASTA  = "Pack",   -- filha DESTE módulo, dentro da Tool
}

local raizPack        = nil
local raizProcurada   = false
local moduloDoPack    = {}   -- [nome] = função | false (já falhou, não insiste)

local function deposito()
	if raizProcurada then return raizPack end
	raizProcurada = true
	-- script é o VFXModule, filho da Tool. Daqui não se sai da Tool.
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
	if not raiz then
		moduloDoPack[nome] = false
		return nil
	end

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

-- pk: chama um efeito do pack sem deixar erro dele encostar no efeito da Tool.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[VFXModule_Escudos] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- REFORÇO — o que o pack acrescenta a cada tipo
--
-- Reforço é CAMADA NOVA, não repetição: cada entrada aqui existe porque o
-- efeito próprio da Tool não desenha aquilo. O IMPACTO próprio faz flash,
-- anel, linhas e faíscas — e nenhum disco; é o disco que entra. As durações
-- são deliberadamente diferentes das camadas próprias: duas camadas com o
-- mesmo tempo de vida leem como borrão, não como impacto.
--═══════════════════════════════════════════════════════════════

local Reforco = {}

local function branco(c, t)
	return Color3.new(1, 1, 1):Lerp(c, t)
end

-- DISCO — o IMPACTO próprio só tem anel fino
function Reforco.IMPACTO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Shockwave",
		CFrame.new(p), CFrame.new(p), 0.26,
		Vector3.new(2, 0.35, 2) * e, Vector3.new(9, 0.35, 9) * e,
		branco(c, 0.35), c, Enum.EasingStyle.Quint)
end

-- Golpe pesado: núcleo + dois discos em tempos separados + fumaça que fica
function Reforco.IMPACTO_NOVA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Small_Nova", p, 0.5, 0, 26 * e, Color3.new(1, 1, 1), c,
		Enum.EasingStyle.Quint)
	pk("Shockwave_2",
		CFrame.new(p), CFrame.new(p), 0.30,
		Vector3.new(3, 0.4, 3) * e, Vector3.new(16, 0.4, 16) * e,
		branco(c, 0.5), c, Enum.EasingStyle.Quint)
	pk("Shockwave",
		CFrame.new(p), CFrame.new(p), 0.55,
		Vector3.new(2, 0.3, 2) * e, Vector3.new(30, 0.3, 30) * e,
		c, c, Enum.EasingStyle.Quad)
	pk("Smoky_Explosion", p, 0.9, 7 * e, branco(c, 0.7), c)
end

function Reforco.ONDA_CHOQUE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Shockwave",
		CFrame.new(p), CFrame.new(p), 0.5,
		Vector3.new(3, 0.3, 3) * e, Vector3.new(34, 0.3, 34) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quad)
end

function Reforco.RACHADURA_SOLO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Floor_Crack", CFrame.new(p), 9 * e, 2.6, c)
end

function Reforco.CORTE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local giro = (d and d.giro) or 0
	local dir  = (d and d.direcao) or Vector3.new(0, 0, -1)
	pk("Small_Slash",
		CFrame.new(p, p + dir) * CFrame.Angles(0, 0, giro),
		9 * e, 0.22, branco(c, 0.25), c)
end

-- Retalho: cortes espalhados por ângulo áureo, nunca por math.random
function Reforco.RETALHO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	local i = 0
	while i < 3 do
		pk("Small_Slash",
			CFrame.new(p, p + dir) * CFrame.Angles(0, 0, i * CFG.ANGULO_AUREO),
			(7 + i * 2) * e, 0.18 + i * 0.05, branco(c, 0.3), c)
		i = i + 1
	end
end

function Reforco.CORTE_X(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	pk("Small_Slash", CFrame.new(p, p + dir) * CFrame.Angles(0, 0, math.rad(45)),
		12 * e, 0.24, branco(c, 0.3), c)
	pk("Small_Slash", CFrame.new(p, p + dir) * CFrame.Angles(0, 0, math.rad(-45)),
		12 * e, 0.3, branco(c, 0.3), c)
end

function Reforco.GRADE_CORTES(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local i = 0
	while i < 5 do
		local desvio = jitter(i) * 3 * e
		pk("Small_Slash",
			CFrame.new(p + Vector3.new(desvio, desvio * 0.5, 0))
				* CFrame.Angles(0, i * CFG.ANGULO_AUREO, math.rad(90)),
			10 * e, 0.2 + i * 0.03, branco(c, 0.4), c)
		i = i + 1
	end
end

function Reforco.DESTROCOS(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Smoky_Explosion", p, 1.1, 6 * e, branco(c, 0.6), c)
	pk("Floor_Crack", CFrame.new(p), 7 * e, 3, c)
end

function Reforco.FEIXE(d)
	local a = (d and d.origem) or Vector3.new()
	local b = (d and d.destino) or Vector3.new()
	local c = cor(d)
	if (b - a).Magnitude < 0.1 then return end
	pk("Laser_Shot", a, b, 0.6 * escala(d), 0.05, (b - a).Magnitude,
		branco(c, 0.5), c, "Cylinder", (d and d.duracao) or 0.35)
end

function Reforco.BLOQUEIO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Sonar_Ring", CFrame.new(p), 0.45, 1, 18 * e, 1.4, 0.1,
		branco(c, 0.4), c)
end

-- Tração: o anel vem de fora para dentro (fim menor que começo)
function Reforco.PULSO_TRACAO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Sonar_Ring", CFrame.new(p), 0.6, 26 * e, 2, 0.2, 1.6, c, branco(c, 0.5))
end

function Reforco.AURA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Spiral_Effect", p, 0.5 * e, c, 40, 4 * e, 2.5)
end

function Reforco.CICLONE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Spiral_Effect", p, 0.7 * e, c, 60, 7 * e, 4)
	pk("Sonar_Ring", CFrame.new(p), 0.8, 22 * e, 3, 0.8, 0.2, c, branco(c, 0.5))
end

function Reforco.DOMO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Shockwave_Explosion", p, 1.2, 2 * e, 30 * e, branco(c, 0.5), c)
end

function Reforco.POEIRA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Smoky_Explosion", p, 1.3, 5 * e, branco(c, 0.8), c)
end

function Reforco.TEMPO_PARADO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	pk("Sonar_Ring", CFrame.new(p), 1.6, 2, 90 * e, 2.4, 0.2, branco(c, 0.6), c)
end

function Reforco.RAJADA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	pk("Shockwave",
		CFrame.new(p, p + dir) * CFrame.Angles(math.rad(90), 0, 0),
		CFrame.new(p + dir * 4, p + dir * 5) * CFrame.Angles(math.rad(90), 0, 0),
		0.34,
		Vector3.new(1.5, 0.3, 1.5) * e, Vector3.new(11, 0.3, 11) * e,
		branco(c, 0.4), c, Enum.EasingStyle.Quint)
end

local Efeitos = {}

-- Impacto leve (hit de melee, bloqueio, ricochete)
function Efeitos.IMPACTO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 1.6 * e, 6)
	camadaAnel(p, c, 3.2 * e, 0.4, d and d.normal)
	camadaLinhas(p, c, 7, 4.5 * e, 0.28)
	camadaFaiscas(p, c, 0.8 * e, 18)
end

-- Impacto pesado (arremesso carregado, explosão de retorno, golpe mortal)
function Efeitos.IMPACTO_NOVA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 3.2 * e, 14)
	camadaDisco(p, c, 6 * e, 0.6)
	camadaAnel(p, c, 5 * e, 0.5)
	camadaAnel(p, Color3.new(1, 1, 1):Lerp(c, 0.5), 3.4 * e, 0.34)
	camadaLinhas(p, c, 16, 11 * e, 0.4)
	camadaFaiscas(p, c, 1.6 * e, 46)
	camadaPoeira(p, c, 5 * e)
end

-- Onda de choque rasteira (no chão)
function Efeitos.ONDA_CHOQUE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaDisco(p + Vector3.new(0, 0.25, 0), c, 8 * e, 0.7)
	camadaLinhas(p + Vector3.new(0, 0.3, 0), c, 14, 12 * e, 0.42, true)
	camadaPoeira(p, c, 7 * e)
end

-- Estrias de velocidade puras (sem impacto) — dash, arranque, ciclone
function Efeitos.LINHAS_VELOCIDADE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaLinhas(p, c, (d and d.quantidade) or 12, 9 * e, 0.3)
end

-- Rachaduras no solo em leque (ângulo áureo, sem math.random)
function Efeitos.RACHADURA_SOLO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local n = (d and d.quantidade) or 9
	for i = 1, n do
		local ang = i * CFG.ANGULO_AUREO
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local comp = (6 + 5 * math.abs(math.sin(i * 1.31))) * e
		local fenda = novaParte({
			Size         = Vector3.new(0.5 * e, 0.35, 0.5),
			Color        = c,
			Material     = Enum.Material.Neon,
			Transparency = 0.2,
			CFrame       = CFrame.new(p + Vector3.new(0, 0.15, 0) + dir * 1.2, p + dir * 10)
				* CFrame.Angles(0, 0, math.rad(jitter(i) * 8)),
		})
		tween(fenda, 0.22, { Size = Vector3.new(0.5 * e, 0.35, comp) }, Enum.EasingStyle.Exponential)
		tween(fenda, 0.9, { Transparency = 1 })
		registrar(fenda, 1.2)
	end
	camadaPoeira(p, c, 4 * e)
end

-- Arco de corte (lâmina / escudo cortante)
function Efeitos.CORTE(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local giro = (d and d.giro) or 0
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)

	local arco = novaParte({
		Size         = Vector3.new(0.25, 7 * e, 0.9 * e),
		Color        = Color3.new(1, 1, 1):Lerp(c, 0.3),
		Transparency = 0.1,
		CFrame       = CFrame.new(p, p + dir) * CFrame.Angles(0, 0, giro),
	})
	tween(arco, 0.18, {
		Size   = Vector3.new(0.05, 12 * e, 0.15 * e),
		CFrame = arco.CFrame * CFrame.Angles(0, 0, math.rad(28)),
	}, Enum.EasingStyle.Exponential)
	tween(arco, 0.3, { Transparency = 1 })
	registrar(arco, 0.6)

	camadaFlash(p, c, 1.1 * e, 5)
	camadaLinhas(p, c, 5, 5 * e, 0.22)
end

-- Retalho: muitos cortes de uma vez (cutscene de execução)
function Efeitos.RETALHO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local n = (d and d.quantidade) or 8
	for i = 1, n do
		local ang = i * CFG.ANGULO_AUREO
		local dir = Vector3.new(math.cos(ang), math.sin(i * 2.1) * 0.4, math.sin(ang)).Unit
		Efeitos.CORTE({
			posicao = p + dir * (1.4 * e),
			cor     = c,
			escala  = e * (0.8 + 0.3 * math.abs(math.sin(i * 1.9))),
			giro    = ang,
			direcao = dir,
		})
	end
	camadaFaiscas(p, c, 1.2 * e, 34)
end

-- Clarão branco no mundo (sem ScreenGui)
function Efeitos.FLASH(d)
	local p, c, e = pos(d), cor(d), escala(d)
	camadaFlash(p, c, 5 * e, 22)
end

-- Poeira / rastro de pé (skate, corrida)
function Efeitos.POEIRA(d)
	camadaPoeira(pos(d), cor(d), 3 * escala(d))
end

-- Feixe entre dois pontos (vínculo do Salvador, tração do Cyclone)
function Efeitos.FEIXE(d)
	local a = (d and d.origem) or Vector3.new()
	local b = (d and d.destino) or Vector3.new()
	local c = cor(d)
	local dist = (b - a).Magnitude
	if dist < 0.1 then return end

	local feixe = novaParte({
		Size         = Vector3.new(0.3 * escala(d), 0.3 * escala(d), dist),
		Color        = c,
		Transparency = 0.25,
		CFrame       = CFrame.new(a:Lerp(b, 0.5), b),
	})
	tween(feixe, (d and d.duracao) or 0.35, {
		Size         = Vector3.new(0.02, 0.02, dist),
		Transparency = 1,
	})
	registrar(feixe, ((d and d.duracao) or 0.35) + 0.3)
end

-- Pulso de tração: partículas convergindo para o centro
function Efeitos.PULSO_TRACAO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local raio = (d and d.raio) or 18

	local base = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = base

	local pe = Instance.new("ParticleEmitter")
	pe.Texture       = CFG.TEX_FAISCA
	pe.Color         = ColorSequence.new(c)
	pe.LightEmission = 1
	pe.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4 * e),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime    = NumberRange.new(0.45, 0.7)
	pe.Speed       = NumberRange.new(-raio * 1.8, -raio * 1.1)  -- negativo = para dentro
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Shape       = Enum.ParticleEmitterShape.Sphere
	pe.Rate        = 0
	pe.Enabled     = false
	pe.Parent      = att
	pe:Emit(60)

	camadaAnel(p, c, raio * 0.55, 0.45)
	registrar(base, 1.2)
end

-- Explosão de bloqueio (escudo aparando dano)
function Efeitos.BLOQUEIO(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local hex = novaParte({
		Shape        = Enum.PartType.Ball,
		Size         = Vector3.new(4 * e, 4 * e, 4 * e),
		Color        = c,
		Transparency = 0.55,
		Material     = Enum.Material.ForceField,
		CFrame       = CFrame.new(p),
	})
	tween(hex, 0.35, { Size = Vector3.new(6.5 * e, 6.5 * e, 6.5 * e), Transparency = 1 })
	registrar(hex, 0.7)
	camadaAnel(p, c, 3 * e, 0.3)
	camadaFaiscas(p, c, 0.6 * e, 12)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS PERSISTENTES (com id) — AURA e CICLONE
--═══════════════════════════════════════════════════════════════

local function abrirId(id)
	if PorId[id] then VFX.Parar(id) end
	PorId[id] = { partes = {}, conexoes = {} }
	return PorId[id]
end

-- Aura contínua presa a uma part (personagem, escudo orbital)
function Efeitos.AURA(d)
	local id   = d and d.id
	local alvo = d and d.alvo
	if not id or not alvo or not alvo:IsA("BasePart") then return end
	local c = cor(d)
	local reg = abrirId(id)

	local att = Instance.new("Attachment")
	att.Parent = alvo
	table.insert(reg.partes, att)

	local pe = Instance.new("ParticleEmitter")
	pe.Texture       = CFG.TEX_FAISCA
	pe.Color         = ColorSequence.new(c)
	pe.LightEmission = 0.9
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 1.1 * escala(d)),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime    = NumberRange.new(0.6, 1.1)
	pe.Speed       = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate        = (d and d.intensidade) or 34
	pe.Drag        = 2
	pe.Enabled     = true
	pe.Parent      = att

	local luz = Instance.new("PointLight")
	luz.Color      = c
	luz.Brightness = 3
	luz.Range      = 12 * escala(d)
	luz.Parent     = alvo
	table.insert(reg.partes, luz)
end

-- Coluna de vórtice + estrias orbitais (Escudo Cyclone)
function Efeitos.CICLONE(d)
	local id   = d and d.id
	local alvo = d and d.alvo
	if not id or not alvo or not alvo:IsA("BasePart") then return end
	local c   = cor(d)
	local e   = escala(d)
	local raio = (d and d.raio) or 14
	local reg = abrirId(id)

	-- Coluna central
	local coluna = novaParte({
		Shape        = Enum.PartType.Cylinder,
		Size         = Vector3.new(20 * e, raio * 0.5, raio * 0.5),
		Color        = c,
		Material     = Enum.Material.ForceField,
		Transparency = 0.85,
		CFrame       = alvo.CFrame * CFrame.Angles(0, 0, math.rad(90)),
	})
	table.insert(reg.partes, coluna)

	-- Emissor de vórtice
	local att = Instance.new("Attachment")
	att.Parent = alvo
	table.insert(reg.partes, att)

	local pe = Instance.new("ParticleEmitter")
	pe.Texture       = CFG.TEX_FUMACA
	pe.Color         = ColorSequence.new(c)
	pe.LightEmission = 0.6
	pe.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, raio * 0.35),
		NumberSequenceKeypoint.new(1, raio * 0.1),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime     = NumberRange.new(0.8, 1.3)
	pe.Speed        = NumberRange.new(-raio, -raio * 0.4)
	pe.SpreadAngle  = Vector2.new(180, 25)
	pe.Acceleration = Vector3.new(0, 26, 0)
	pe.Rotation     = NumberRange.new(-180, 180)
	pe.RotSpeed     = NumberRange.new(-180, 180)
	pe.Rate         = 55
	pe.Drag         = 1.5
	pe.Enabled      = true
	pe.Parent       = att

	-- Giro da coluna por acumulador dt (nunca tick())
	local t = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not (coluna.Parent and alvo.Parent) then return end
		t = t + dt
		coluna.CFrame = CFrame.new(alvo.Position)
			* CFrame.Angles(0, t * 6, 0)
			* CFrame.Angles(0, 0, math.rad(90))
	end)
	table.insert(reg.conexoes, conn)
end

--═══════════════════════════════════════════════════════════════
-- BLOCO IMPORTADO — §12.12 / §12.16
--
-- Modelos de origem:
--   [JC] "Judgement Cut End"        — grade de cortes, tempo parado,
--                                     destroços, presets de tremor
--   [DE] "Domain Expansion(Elemental)" — cúpula de domínio, corte duplo
--                                     em X, gongo de abertura
--
-- PASSE DE CONFORMIDADE EXECUTADO (§12.12.2)
--   :Emit(500) / :Emit(10) no servidor .... reescrito: burst só no cliente
--   math.random em 14 pontos ............... ângulo áureo + i*24° + jitter senoidal
--   wait() / spawn() / :Destroy() .......... task.* + Parent=nil + Debris
--   ColorCorrectionEffect (BlackandWhite) .. REMOVIDO — proibido §12.12.1
--   Animation JMCN / 9744147373 / 9744151747 REMOVIDO — proibido §10
--   MuchachoHitbox / StunHandlerV2 / GoodSignal REMOVIDO — lógica de combate
--   Clone de ServerStorage / ReplicatedStorage REMOVIDO — Tool autocontida
--   Meshes KatanaV2 / Stone / Shrine ....... não copiados (IP de terceiro);
--                                            silhueta recriada com primitivas
--
-- O QUE ENTROU DE FATO: parâmetros de emissor, IDs de áudio, números dos
-- presets de tremor e a COREOGRAFIA (ordem e ritmo dos beats). Nenhuma
-- geometria e nenhuma regra de jogo alheia.
--═══════════════════════════════════════════════════════════════

-- Texturas herdadas dos emissores do [JC]
local TEX = {
	FAGULHA_FLIP = "rbxassetid://7994629137",   -- [JC] emissor "TP", grade 2x2
	ANEL         = "rbxassetid://7216848832",   -- [JC] emissor "10"
	BRILHO       = "rbxassetid://2866648598",   -- [JC] emissor de núcleo
	DISCO        = "rbxassetid://3916186365",   -- [JC] disco girando
	AURA_LENTA   = "rbxassetid://6250126210",   -- [JC] aura de rotação lenta
}

--── [JC] emissor "TP": rajada cônica de fagulhas em flipbook ──
local function emissorTP(pai, c, escalaTP)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture        = TEX.FAGULHA_FLIP
	pe.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
	pe.LightEmission  = 1
	pe.LightInfluence = 0.35
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, c),
		ColorSequenceKeypoint.new(1, c),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.194, 3.06 * escalaTP),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime    = NumberRange.new(0.1, 0.8)
	pe.Speed       = NumberRange.new(10, 350 * escalaTP)
	pe.Drag        = 10
	pe.SpreadAngle = Vector2.new(0, 0)
	pe.EmissionDirection = Enum.NormalId.Front
	pe.Rate        = 0
	pe.Enabled     = false
	pe.Parent      = pai
	return pe
end

--── [JC] emissor "10": anel de choque plano ──
local function emissorAnel(pai, c, escalaAnel)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture        = TEX.ANEL
	pe.LightEmission  = 1
	pe.LightInfluence = 0.35
	pe.Color          = ColorSequence.new(c)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 3.94 * escalaAnel),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.05, 0.35)
	pe.Speed    = NumberRange.new(0.1, 0.1)
	pe.Rotation = NumberRange.new(-180, 180)
	pe.Drag     = 5
	pe.Rate     = 0
	pe.Enabled  = false
	pe.Parent   = pai
	return pe
end

--── [JC] disco de aura girando (usado no domo e no ciclone) ──
local function emissorDisco(pai, c, tamanho)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture        = TEX.DISCO
	pe.LightEmission  = 1
	pe.LightInfluence = 0
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0, 0.07, 1):Lerp(c, 0.5)),
		ColorSequenceKeypoint.new(0.848, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, c),
	})
	pe.Size         = NumberSequence.new(tamanho)
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.06, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime          = NumberRange.new(0.3, 1)
	pe.Speed             = NumberRange.new(0.1, 0.1)
	pe.Rotation          = NumberRange.new(-180, 180)
	pe.RotSpeed          = NumberRange.new(-360, 1000)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Rate              = 20
	pe.Enabled           = true
	pe.Parent            = pai
	return pe
end

--═══════════════════════════════════════════════════════════════
-- [JC] GRADE DE CORTES — planos de vidro que ficam suspensos e colapsam
--═══════════════════════════════════════════════════════════════

-- No original: 30 planos com math.random de posição e orientação.
-- Aqui: espiral de Vogel no plano + altura senoidal + orientação derivada
-- do índice. Mesma sensação de dispersão, resultado idêntico em todo cliente.
function Efeitos.GRADE_CORTES(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local n     = (d and d.quantidade) or 22
	local raio  = (d and d.raio) or 30
	local espera = (d and d.espera) or 1.4

	for i = 1, n do
		local ang = i * CFG.ANGULO_AUREO
		local r   = raio * math.sqrt(i / n)
		local alt = 2 + math.abs(math.sin(i * 1.31)) * 10
		local centro = p + Vector3.new(math.cos(ang) * r, alt, math.sin(ang) * r)

		local largura = 20 + math.abs(math.sin(i * 2.17)) * 20
		local plano = novaParte({
			Size         = Vector3.new(largura * e, 0.35, largura * e),
			Color        = Color3.new(1, 1, 1),
			Material     = Enum.Material.Glass,
			Transparency = 0.9,
			Reflectance  = 0.35,
			CFrame       = CFrame.new(centro) * CFrame.Angles(
				math.rad(math.sin(i * 1.7) * 50),
				ang,
				math.rad(math.cos(i * 2.3) * 50)
			),
		})

		-- fio luminoso no corte, na cor do efeito
		local fio = novaParte({
			Size         = Vector3.new(largura * e * 1.02, 0.08, 0.4),
			Color        = c,
			Transparency = 0.15,
			CFrame       = plano.CFrame,
		})

		local atraso = espera + (i / n) * 0.35
		task.delay(atraso, function()
			if plano.Parent then
				tween(plano, 0.5, { Size = Vector3.new(0.2, 0.35, largura * e), Transparency = 1 })
			end
			if fio.Parent then
				tween(fio, 0.35, { Size = Vector3.new(0.2, 0.02, 0.4), Transparency = 1 })
			end
		end)

		registrar(plano, atraso + 1.2)
		registrar(fio, atraso + 1.2)
	end
end

--═══════════════════════════════════════════════════════════════
-- [JC] TEMPO PARADO — sem ColorCorrection (proibido)
--   O original desaturava a tela inteira. Aqui o efeito é feito NO MUNDO:
--   Highlight branco nos alvos + queda de FOV + poeira suspensa.
--═══════════════════════════════════════════════════════════════

local fovConn = nil

local function pulsoFOV(alvoFov, subida, descida)
	local cam = workspace.CurrentCamera
	if not cam then return end
	if fovConn then
		fovConn:Disconnect()
		fovConn = nil
	end
	local original = cam.FieldOfView
	tween(cam, subida or 0.2, { FieldOfView = alvoFov }, Enum.EasingStyle.Sine)
	task.delay((subida or 0.2) + (descida or 0.4), function()
		if workspace.CurrentCamera then
			tween(workspace.CurrentCamera, 0.35, { FieldOfView = original }, Enum.EasingStyle.Quad)
		end
	end)
end

function Efeitos.TEMPO_PARADO(d)
	local p, c = pos(d), cor(d)
	local id   = (d and d.id) or "TEMPO_PARADO"
	local raio = (d and d.raio) or 40
	local reg  = abrirId(id)

	pulsoFOV(42, 0.18, (d and d.duracao) or 1.8)

	-- Realce nos personagens dentro do raio (visual, não altera estado)
	for _, modelo in ipairs(workspace:GetChildren()) do
		if modelo:IsA("Model") and modelo:FindFirstChildOfClass("Humanoid") then
			local raiz = modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
			if raiz and (raiz.Position - p).Magnitude <= raio then
				local hl = Instance.new("Highlight")
				hl.FillColor        = Color3.new(1, 1, 1)
				hl.FillTransparency = 0.65
				hl.OutlineColor     = c
				hl.OutlineTransparency = 0
				hl.DepthMode        = Enum.HighlightDepthMode.Occluded
				hl.Parent           = modelo
				table.insert(reg.partes, hl)
			end
		end
	end

	-- Poeira suspensa: partículas que quase não se movem
	local base = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = base
	local pe = Instance.new("ParticleEmitter")
	pe.Texture       = TEX.BRILHO
	pe.Color         = ColorSequence.new(Color3.new(1, 1, 1))
	pe.LightEmission = 1
	pe.Size          = NumberSequence.new(0.55)
	pe.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime    = NumberRange.new(1.4, 2.2)
	pe.Speed       = NumberRange.new(0.4, 1.2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Shape       = Enum.ParticleEmitterShape.Sphere
	pe.Drag        = 12
	pe.Rate        = 0
	pe.Enabled     = false
	pe.Parent      = att
	pe:Emit(90)
	table.insert(reg.partes, base)
end

--═══════════════════════════════════════════════════════════════
-- [JC] DESTROÇOS — anel de fragmentos que sobem e caem
--   Origem: Rock.RockSpawn — o CFrame.Angles(0, rad(i*24), 0) do original
--   já era determinístico; só o tamanho usava math.random.
--═══════════════════════════════════════════════════════════════

function Efeitos.DESTROCOS(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local n    = (d and d.quantidade) or 15
	local raio = (d and d.raio) or 24

	for i = 1, n do
		local ang = math.rad(i * 24)
		local tamanho = 1.5 + math.abs(math.sin(i * 1.9)) * 1.0
		local origem = p + Vector3.new(math.cos(ang) * raio, 1.5, math.sin(ang) * raio)

		local pedra = novaParte({
			Size         = Vector3.new(4 * e, tamanho * e, tamanho * e),
			Color        = Color3.new(0.35, 0.33, 0.32):Lerp(c, 0.2),
			Material     = Enum.Material.Slate,
			Transparency = 0.05,
			CFrame       = CFrame.new(origem)
				* CFrame.Angles(0, ang, 0)
				* CFrame.Angles(math.rad(35), 0, math.rad(math.sin(i * 2.4) * 25)),
		})

		local subida = 3 + math.abs(math.cos(i * 1.4)) * 4
		tween(pedra, 0.35, {
			CFrame = pedra.CFrame * CFrame.new(0, subida, 0),
		}, Enum.EasingStyle.Quart)

		task.delay(0.5 + i * 0.02, function()
			if pedra.Parent then
				tween(pedra, 1.1, {
					CFrame = pedra.CFrame * CFrame.new(0, -subida - 2, 0),
					Transparency = 1,
				}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			end
		end)
		registrar(pedra, 2.4)
	end

	camadaPoeira(p, c, 6 * e)
end

--═══════════════════════════════════════════════════════════════
-- [DE] CORTE EM X — dois planos cruzados sobre a vítima
--   Origem: Domain Expansion, os dois loops de Slash a +45° e -45°.
--═══════════════════════════════════════════════════════════════

function Efeitos.CORTE_X(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local giro = (d and d.giro) or 0

	for _, sinal in ipairs({ 1, -1 }) do
		local lamina = novaParte({
			Size         = Vector3.new(0.18, 14 * e, 2.4 * e),
			Color        = Color3.new(1, 1, 1):Lerp(c, 0.25),
			Transparency = 0.08,
			CFrame       = CFrame.new(p)
				* CFrame.Angles(0, giro, 0)
				* CFrame.Angles(0, 0, math.rad(45 * sinal)),
		})
		tween(lamina, 0.22, {
			Size         = Vector3.new(0.04, 20 * e, 0.2 * e),
			Transparency = 1,
		}, Enum.EasingStyle.Exponential)
		registrar(lamina, 0.6)
	end

	camadaFlash(p, c, 1.4 * e, 7)
	camadaFaiscas(p, c, 1.1 * e, 22)
end

--═══════════════════════════════════════════════════════════════
-- [DE] DOMO — cúpula de domínio que se abre e se fecha
--   Origem: Blacball + Cage do Domain Expansion.
--   Aqui é uma esfera ForceField + esfera interna escura + discos girando.
--═══════════════════════════════════════════════════════════════

function Efeitos.DOMO(d)
	local id   = d and d.id
	local alvo = d and d.alvo
	if not (id and alvo and alvo:IsA("BasePart")) then return end
	local c    = cor(d)
	local raio = (d and d.raio) or 50
	local reg  = abrirId(id)

	-- Casca externa
	local casca = novaParte({
		Shape        = Enum.PartType.Ball,
		Size         = Vector3.new(2, 2, 2),
		Color        = c,
		Material     = Enum.Material.ForceField,
		Transparency = 0.55,
		CFrame       = CFrame.new(alvo.Position),
	})
	table.insert(reg.partes, casca)
	tween(casca, 1, { Size = Vector3.new(raio, raio, raio) }, Enum.EasingStyle.Quint)

	-- Núcleo escuro
	local nucleo = novaParte({
		Shape        = Enum.PartType.Ball,
		Size         = Vector3.new(1, 1, 1),
		Color        = Color3.new(0.03, 0.02, 0.05),
		Material     = Enum.Material.Neon,
		Transparency = 0.35,
		CFrame       = CFrame.new(alvo.Position),
	})
	table.insert(reg.partes, nucleo)
	tween(nucleo, 1.1, {
		Size         = Vector3.new(raio * 0.92, raio * 0.92, raio * 0.92),
		Transparency = 0.82,
	}, Enum.EasingStyle.Quint)

	-- Discos girando na base
	local base = novaParte({
		Size         = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame       = CFrame.new(alvo.Position),
	})
	table.insert(reg.partes, base)
	local att = Instance.new("Attachment")
	att.Parent = base
	emissorDisco(att, c, raio * 0.4)

	local luz = Instance.new("PointLight")
	luz.Color      = c
	luz.Brightness = 6
	luz.Range      = raio * 0.8
	luz.Parent     = base
	table.insert(reg.partes, luz)

	-- Acompanha o portador
	local conn = RunService.Heartbeat:Connect(function()
		if not (casca.Parent and alvo.Parent) then return end
		local cf = CFrame.new(alvo.Position)
		casca.CFrame  = cf
		nucleo.CFrame = cf
		base.CFrame   = cf
	end)
	table.insert(reg.conexoes, conn)
end

--═══════════════════════════════════════════════════════════════
-- [JC] RAJADA — burst cônico com os emissores importados
--═══════════════════════════════════════════════════════════════

function Efeitos.RAJADA(d)
	local p, c, e = pos(d), cor(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 1, 0)

	local base = novaParte({
		Size         = Vector3.new(0.4, 0.4, 0.4),
		Transparency = 1,
		CFrame       = CFrame.new(p, p + dir),
	})
	emissorTP(base, c, e):Emit(math.floor(120 * e))
	emissorAnel(base, c, e):Emit(6)
	registrar(base, 1.6)

	camadaFlash(p, c, 2 * e, 10)
end

--═══════════════════════════════════════════════════════════════
-- [JC] ZOOM — pulso de FOV (CameraShaker "Zoom" do Cam.lua)
--═══════════════════════════════════════════════════════════════

function Efeitos.ZOOM(d)
	pulsoFOV((d and d.fov) or 45, (d and d.subida) or 0.2, (d and d.espera) or 0.4)
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA — presets herdados do [JC]
--
-- O modelo original usava o CameraShaker do Crazyman32 (3 ModuleScripts
-- + Perlin). O que interessava eram os NÚMEROS dos presets; a máquina foi
-- reescrita aqui em ~40 linhas, aditiva, determinística e sem dependência
-- externa. Assinatura do preset: magnitude, aspereza, fadeIn, fadeOut,
-- influência de posição, influência de rotação.
--═══════════════════════════════════════════════════════════════

local PRESETS = {
	BUMP           = { 2.5,  4.0, 0.10, 0.75, 0.15, 1.0 },
	BUMP_GRANDE    = { 2.5,  4.0, 0.10, 0.75, 0.80, 1.0 },
	BUMP_PEQUENO   = { 2.5,  4.0, 0.10, 0.75, 0.01, 0.5 },
	BUMP_REMADE    = { 2.0,  5.0, 0.00, 1.00, 0.20, 3.0 },
	EXPLOSAO       = { 5.0, 10.0, 0.00, 1.50, 0.25, 4.0 },
	EXPLOSAO_GRANDE = { 20.0, 40.0, 0.00, 2.00, 0.55, 5.0 },
	EXPLOSAO_ENORME = { 30.0, 50.0, 0.00, 1.50, 1.00, 5.0 },
	EXPLOSAO_PEQUENA = { 5.0, 10.0, 0.00, 1.50, 0.15, 4.0 },
	TERREMOTO      = { 0.6,  3.5, 2.00, 10.0, 0.25, 1.0 },
	VIBRACAO       = { 0.4, 20.0, 2.00, 2.00, 0.15, 1.25 },
	MAO_LIVRE      = { 1.0, 0.25, 5.00, 10.0, 0.00, 1.0 },
}

local tremorConn = nil

-- Ruído determinístico em [-1, 1]: soma de senoides incomensuráveis.
local function ruido(t, semente)
	return (
		math.sin(t * 1.000 + semente * 1.7)
		+ math.sin(t * 1.618 + semente * 3.1) * 0.7
		+ math.sin(t * 2.718 + semente * 5.3) * 0.4
	) / 2.1
end

function Efeitos.TREMOR(d)
	local cam = workspace.CurrentCamera
	if not cam then return end

	local preset = PRESETS[(d and d.preset) or ""] or PRESETS.BUMP
	local magnitude   = (d and d.intensidade) and (d.intensidade * 4) or preset[1]
	local aspereza    = preset[2]
	local fadeIn      = preset[3]
	local fadeOut     = (d and d.duracao) or preset[4]
	local infPosicao  = preset[5]
	local infRotacao  = preset[6]

	if tremorConn then
		tremorConn:Disconnect()
		tremorConn = nil
	end

	local t = 0
	local total = fadeIn + fadeOut
	tremorConn = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		if t >= total or not workspace.CurrentCamera then
			if tremorConn then
				tremorConn:Disconnect()
				tremorConn = nil
			end
			return
		end

		local envelope
		if t < fadeIn and fadeIn > 0 then
			envelope = t / fadeIn
		else
			local restante = total - t
			envelope = math.clamp(restante / fadeOut, 0, 1)
		end
		envelope = envelope * envelope

		local f = t * aspereza
		local a = magnitude * envelope * 0.06

		local px = ruido(f, 1) * a * infPosicao
		local py = ruido(f, 2) * a * infPosicao
		local pz = ruido(f, 3) * a * infPosicao * 0.5
		local rx = ruido(f, 4) * a * infRotacao * 0.012
		local ry = ruido(f, 5) * a * infRotacao * 0.012
		local rz = ruido(f, 6) * a * infRotacao * 0.012

		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
			* CFrame.new(px, py, pz)
			* CFrame.Angles(rx, ry, rz)
	end)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Escudos] falha em " .. tostring(tipo) .. ": " .. tostring(err))
	end

	-- Reforço do pack compartilhado. Vem DEPOIS e é opcional por construção:
	-- num place sem o pack nada aqui acha nada, e o efeito próprio acima já
	-- aconteceu por inteiro. É esta ordem que faz a Tool empobrecer em vez de
	-- quebrar quando a exceção da Regra nº 1 não está instalada.
	local extra = Reforco[tipo]
	if extra then
		local okReforco, erroReforco = pcall(extra, dados)
		if not okReforco then
			warn("[VFXModule_Escudos] reforço de " .. tostring(tipo)
				.. ": " .. tostring(erroReforco))
		end
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
	for id in pairs(PorId) do
		VFX.Parar(id)
	end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then inst.Parent = nil end
	end
	table.clear(Vivos)
	if tremorConn then
		tremorConn:Disconnect()
		tremorConn = nil
	end
end

return VFX
