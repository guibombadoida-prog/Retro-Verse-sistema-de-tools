-- VFXModule_Drama_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto DRAMA
--
-- ONDE RODA: CLIENTE. O servidor transmite o tipo pelo VFXRemote; quem desenha
-- é quem vê (§12.11). Por isso `:Emit()` aqui é legítimo — não há replicação.
--
-- LINGUAGEM VISUAL DESTE CONJUNTO
--
--   Bomba é volume. Telecinese é direção. **Briga é o QUADRO DO CONTATO.**
--
--   O que faz um soco parecer soco não é o tamanho do clarão — é ele durar
--   pouco e o resto durar menos ainda. Todo impacto daqui é montado assim:
--
--     FLASH   0.05 s   o contato, e nada mais
--     RASGO   0.14 s   a linha por onde a mão passou
--     FAISCA  0.30 s   o estilhaço
--
--   Nada aqui passa de 0.35 s, exceto `AURA` e as duas cutscenes — que são os
--   três casos em que o efeito É o estado, não o instante.
--
-- DUAS PALETAS, E A DIFERENÇA IMPORTA
--
--   CARMESIM  a briga: soco, gancho, chute, empurrão, aura, olhos
--   GELO      só o `Corte Frio` e o finalizador do `TryHard`
--
--   Um "corte frio" desenhado na cor do soco não é corte frio, é mais um soco.
--   A troca de paleta é o que diz ao espectador que aquele golpe é de outra
--   natureza — e é a única leitura que ele tem, porque dano não tem cor.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador.
--
-- Gerado por FERRAMENTAS/gerar_servers_drama.py.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_CARMESIM = Color3.fromRGB(255, 74, 74),
	COR_BRASA    = Color3.fromRGB(255, 176, 92),
	COR_GELO     = Color3.fromRGB(150, 220, 255),
	COR_GELO_FUN = Color3.fromRGB(66, 122, 190),
	COR_AURA     = Color3.fromRGB(255, 120, 40),
	COR_POEIRA   = Color3.fromRGB(132, 124, 112),
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

local function angulo(i)
	return (i or proximo()) * CFG.ANGULO_AUREO
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
-- ATENÇÃO AO TIPO: cinco dos dez efeitos do pack tomam tamanho como NÚMERO e
-- dois como Vector3, e o nome não avisa qual é qual. `verificar_pack_vfx.py`.
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
		warn("[VFXModule_Drama] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

--- 0.05 s. É o quadro do contato, e ele é curto porque contato é curto.
local function camadaFlash(p, c, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.45,
		Color = branco(c, 0.4),
		Transparency = 0.08,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 7, raio * 4
	luz.Parent = bola
	tween(bola, 0.05, { Size = Vector3.new(raio, raio, raio) * 1.35,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.2)
end

--- A linha por onde a mão passou. 0.14 s.
local function camadaRasgo(cf, c, comprimento, largura, tempo)
	local rasgo = novaParte({
		Size = Vector3.new(largura, 0.08, comprimento),
		Color = branco(c, 0.55),
		Transparency = 0.15,
		CFrame = cf,
	})
	tween(rasgo, tempo or 0.14, {
		Size = Vector3.new(largura * 0.15, 0.02, comprimento * 1.35),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(rasgo, (tempo or 0.14) + 0.15)
end

local function camadaFaiscas(p, c, forca, quantidade, subida)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.3), c)
	em.LightEmission = 1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.18, 0.44)
	em.Speed = NumberRange.new(16 * forca, 36 * forca)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Acceleration = Vector3.new(0, subida or -18, 0)
	em.Rotation = NumberRange.new(0, 360)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 12)
	registrar(ancora, 1)
end

local function camadaAnel(p, c, raio, tempo, espessura)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(espessura or 0.3, raio * 0.4, raio * 0.4),
		Color = branco(c, 0.4),
		Transparency = 0.22,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, tempo, { Size = Vector3.new((espessura or 0.3) * 0.2,
		raio * 2.3, raio * 2.3), Transparency = 1 }, Enum.EasingStyle.Quint)
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
	em.LightEmission = 0.12
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2 * forca),
		NumberSequenceKeypoint.new(1, 3.6 * forca),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.7, 1.4)
	em.Speed = NumberRange.new(3 * forca, 9 * forca)
	em.SpreadAngle = Vector2.new(70, 70)
	em.RotSpeed = NumberRange.new(-26, 26)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 8)
	registrar(ancora, 2.2)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

local function pos(d) return (d and d.posicao) or Vector3.new() end
local function escala(d) return (d and d.escala) or 1 end
local function cor(d, padrao) return (d and d.cor) or padrao or CFG.COR_CARMESIM end
local function quadro(d)
	if d and d.cframe then return d.cframe end
	return CFrame.new(pos(d))
end

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id].partes
end

--- Soco. Curto e seco.
function Efeitos.SOCO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaFlash(p, c, 2 * e)
	camadaFaiscas(p, c, 0.5 * e, 10 + math.floor(e * 4))
	pk("Small_Nova", p, 0.22, 0, 5.5 * e, branco(c, 0.55), c)
end

--- Gancho: mesma forma, faísca SUBINDO. É a única diferença, e basta.
function Efeitos.GANCHO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaFlash(p, c, 2.4 * e)
	camadaFaiscas(p, c, 0.6 * e, 14, 12)
	camadaRasgo(CFrame.new(p) * CFrame.Angles(math.rad(70), 0, 0),
		c, 5 * e, 0.7 * e)
end

--- Chute rodado: o rasgo é horizontal e longo, porque a perna varre.
function Efeitos.CHUTE(d)
	local e, c = escala(d), cor(d)
	local cf = quadro(d)
	camadaFlash(cf.Position, c, 2.6 * e)
	camadaRasgo(cf * CFrame.Angles(0, math.rad(12), 0), c, 9 * e, 1.1 * e, 0.18)
	camadaFaiscas(cf.Position, c, 0.65 * e, 14)
	pk("Small_Slash", cf, 9 * e, 0.22, branco(c, 0.55), c)
end

--- Empurrão: cone à frente, sem faísca. Empurrão não fere, desloca.
function Efeitos.EMPURRAO(d)
	local e, c = escala(d), cor(d)
	local cf = quadro(d)
	for i = 1, 3 do
		local frente = cf * CFrame.new(0, 0, -i * 2.6 * e)
		task.delay((i - 1) * 0.03, function()
			camadaAnel(frente.Position, c, (2 + i * 1.6) * e, 0.26, 0.22)
		end)
	end
	camadaPoeira(cf.Position - Vector3.new(0, 2.2, 0), CFG.COR_POEIRA, 0.5 * e, 6)
end

--- Esquiva: rastro no lugar de onde o corpo saiu. Sem dano, sem faísca.
function Efeitos.ESQUIVA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local reg = registroDe(d)
	local rastro = novaParte({
		Size = Vector3.new(2, 5, 1) * e,
		Color = branco(c, 0.3),
		Transparency = 0.62,
		CFrame = (d and d.cframe) or CFrame.new(p),
	})
	tween(rastro, 0.42, { Transparency = 1,
		Size = Vector3.new(2.6, 5.6, 1.2) * e }, Enum.EasingStyle.Quad)
	registrar(rastro, 0.6)
	if reg then table.insert(reg, rastro) end
	camadaFaiscas(p, c, 0.3 * e, 6, 4)
end

--- Corte de lâmina. PALETA GELO — este é o `Corte Frio`.
function Efeitos.CORTE(d)
	local e = escala(d)
	local c = cor(d, CFG.COR_GELO)
	local cf = quadro(d)
	camadaFlash(cf.Position, c, 2.2 * e)
	camadaRasgo(cf, c, 11 * e, 0.55 * e, 0.16)
	camadaFaiscas(cf.Position, c, 0.5 * e, 12, -6)
	pk("Small_Slash", cf, 11 * e, 0.24, branco(c, 0.65), c)
end

--- A execução: cristal que fecha em volta do alvo e estilhaça.
function Efeitos.EXECUCAO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_GELO)
	local reg = registroDe(d)

	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1),
		Color = CFG.COR_GELO_FUN,
		Material = Enum.Material.Ice,
		Transparency = 0.42,
		CFrame = CFrame.new(p),
	})
	tween(casca, 0.3, { Size = Vector3.new(5.6, 6.4, 5.6) * e },
		Enum.EasingStyle.Back)
	registrar(casca, (d and d.duracao) or 3)
	if reg then table.insert(reg, casca) end

	-- lascas em ângulo áureo, paradas no ar: é o que faz ler como GELO e não
	-- como fumaça azul
	for i = 1, 9 do
		local a = angulo(i)
		local raio = (3.4 + (i % 3) * 0.8) * e
		local lasca = novaParte({
			Size = Vector3.new(0.22, 0.22 + (i % 4) * 0.5, 0.22) * e,
			Color = branco(c, 0.35),
			Material = Enum.Material.Ice,
			Transparency = 0.25,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a) * raio,
				((i % 5) - 2) * 0.9, math.sin(a) * raio))
				* CFrame.Angles(a * 0.6, a, a * 0.3),
		})
		registrar(lasca, (d and d.duracao) or 3)
		if reg then table.insert(reg, lasca) end
	end
	pk("Sonar_Ring", CFrame.new(p), 0.7, 0, 8 * e, 1.2, 0.15, branco(c, 0.6), c)
end

--- O estilhaço do gelo quando a execução fecha.
function Efeitos.ESTILHACO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_GELO)
	camadaFlash(p, c, 4 * e)
	camadaFaiscas(p, c, 0.9 * e, 24, -22)
	camadaAnel(p, c, 6 * e, 0.36, 0.35)
	pk("Small_Nova", p, 0.35, 0, 12 * e, branco(c, 0.6), c)
end

--- Rachadura no chão.
function Efeitos.RACHA(d)
	local p, e, c = pos(d), escala(d), cor(d, CFG.COR_BRASA)
	camadaFlash(p, c, 3 * e)
	camadaAnel(p, c, 5 * e, 0.32, 0.45)
	camadaPoeira(p, CFG.COR_POEIRA, 0.9 * e, 12)
	camadaFaiscas(p, c, 0.8 * e, 18, -14)
	pk("Floor_Crack", CFrame.new(p), 9 * e, 3, c)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.5,
		Vector3.new(5 * e, 1.4, 5 * e), Vector3.new(19 * e, 0.35, 19 * e),
		branco(c, 0.5), c)
end

--- Aura ligada. É o único efeito PERSISTENTE do conjunto, e some por `Parar`.
function Efeitos.AURA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_AURA)
	local reg = registroDe(d)

	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.45), c)
	em.LightEmission = 0.95
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.7 * e),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.7, 1.3)
	em.Rate = 46
	em.Speed = NumberRange.new(7, 13)
	em.SpreadAngle = Vector2.new(26, 26)
	em.Acceleration = Vector3.new(0, 9, 0)
	em.EmissionDirection = Enum.NormalId.Top
	em.Parent = att

	-- O emissor é ligado por `Rate`, e o registro segue o portador: quem move a
	-- âncora é o Server, pelo beat. Aqui ela nasce onde o beat mandou.
	registrar(ancora, (d and d.duracao) or 12)
	if reg then table.insert(reg, ancora) end
	camadaAnel(p - Vector3.new(0, 2.6, 0), c, 4 * e, 0.5, 0.2)
end

--- O pulso que a aura solta.
function Efeitos.AURA_PULSO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_AURA)
	camadaFlash(p, c, 3.4 * e)
	camadaAnel(p, c, 6 * e, 0.34, 0.4)
	camadaFaiscas(p, c, 0.85 * e, 20, 6)
	pk("Shockwave_2", CFrame.new(p), CFrame.new(p), 0.45,
		Vector3.new(4 * e, 1.4, 4 * e), Vector3.new(17 * e, 0.35, 17 * e),
		branco(c, 0.5), c)
end

--- Feixe dos olhos. Nasce na CABEÇA — quem passa a origem é o Server.
function Efeitos.FEIXE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local e, c = escala(d), cor(d)
	if not pk("Laser_Shot", origem, destino, 0.2, 0.05, 7,
			branco(c, 0.6), c) then
		local delta = destino - origem
		if delta.Magnitude < 0.1 then return end
		local feixe = novaParte({
			Size = Vector3.new(0.22 * e, 0.22 * e, delta.Magnitude),
			Color = branco(c, 0.5),
			Transparency = 0.2,
			CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
		})
		tween(feixe, 0.16, { Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(feixe, 0.3)
	end
	camadaFaiscas(origem, c, 0.3 * e, 5, 2)
	camadaFlash(destino, c, 1.8 * e)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Drama] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
			for _, filho in ipairs(inst:GetDescendants()) do
				if filho:IsA("ParticleEmitter") then filho.Enabled = false end
			end
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
