-- VFXModule_Gravidade_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto GRAVIDADE
--
-- ONDE RODA: CLIENTE. O servidor transmite o tipo pelo VFXRemote; quem desenha
-- é quem vê (§12.11). Por isso `:Emit()` aqui é legítimo — não há replicação.
--
-- LINGUAGEM VISUAL DESTE CONJUNTO
--
--   Bomba é volume. Porrada é contato. **Gravidade é DIREÇÃO.**
--
--   O que faz uma pessoa entender que aquilo é telecinese, e não uma explosão
--   roxa, é para onde as coisas vão. Por isso quase todo efeito daqui tem um
--   eixo declarado, e ele é o oposto do que a física faria sozinha:
--
--     LEVITA / CAMPO_INVERSO   partícula SOBE, e acelera subindo
--     ESMAGA / PUXAO           partícula DESCE ou converge para o centro
--     ONDA / RACHADURA         corre no plano do chão, para fora
--
--   Um efeito de gravidade com partícula caindo para os lados lê como poeira.
--   `Acceleration` é a propriedade que mais importa neste módulo.
--
-- A PALETA É VIOLETA, E ISSO NÃO É ENFEITE
--
--   O repositório já tem laranja (bomba), quente (porrada) e verde (cura). Num
--   servidor com as três, um quarto poder precisa de cor própria ou vira
--   ruído. Violeta com núcleo branco é o que sobrou, e é o que a leitura de
--   "força invisível" pede.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador.
--
-- Gerado por FERRAMENTAS/gerar_servers_gravidade.py.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_CAMPO    = Color3.fromRGB(168, 118, 255),
	COR_NUCLEO   = Color3.fromRGB(236, 222, 255),
	COR_PESO     = Color3.fromRGB(96, 62, 190),
	COR_TERRA    = Color3.fromRGB(138, 128, 116),
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

--- Jitter determinístico em [-1,1]. No lugar dos 18 `math.random` do modelo de
--- origem: mesma variedade, e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice — dispersão que não repete e não sorteia.
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
-- ATENÇÃO AO TIPO DO ARGUMENTO. Cinco dos dez efeitos do pack tomam tamanho
-- como NÚMERO e dois como Vector3, e o nome não avisa qual é qual
-- (`Size_A` × `Vector_Size_A`). `TESTES/verificar_pack_vfx.py` confere isso.
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
		warn("[VFXModule_Gravidade] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

--- Motes com eixo declarado. É a camada que define o conjunto: `subida` positiva
--- sobe (campo invertido), negativa desce (esmagamento).
local function camadaEixo(p, c, forca, quantidade, subida, raio)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.45), c)
	em.LightEmission = 0.9
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 0.55 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.6, 1.2)
	em.Speed = NumberRange.new(math.abs(subida) * 0.5, math.abs(subida))
	em.SpreadAngle = Vector2.new(raio or 26, raio or 26)
	em.Acceleration = Vector3.new(0, subida * 1.6, 0)
	em.EmissionDirection = subida >= 0 and Enum.NormalId.Top or Enum.NormalId.Bottom
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 16)
	registrar(ancora, 2.4)
end

--- Anel no plano do chão. A direção aqui é PARA FORA.
local function camadaAnel(p, c, raio, tempo, espessura)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(espessura or 0.3, raio * 0.4, raio * 0.4),
		Color = branco(c, 0.4),
		Transparency = 0.22,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, tempo, { Size = Vector3.new((espessura or 0.3) * 0.2,
		raio * 2.4, raio * 2.4), Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, tempo + 0.2)
end

local function camadaFlash(p, c, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.5,
		Color = branco(c, 0.4),
		Transparency = 0.1,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 8, raio * 5
	luz.Parent = bola
	tween(bola, 0.1, { Size = Vector3.new(raio, raio, raio) * 1.6,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.28)
end

local function camadaPoeira(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FUMACA
	em.Color = ColorSequence.new(c, branco(c, 0.25))
	em.LightEmission = 0.1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4 * forca),
		NumberSequenceKeypoint.new(1, 4.0 * forca),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.8, 1.6)
	em.Speed = NumberRange.new(3 * forca, 9 * forca)
	em.SpreadAngle = Vector2.new(70, 70)
	em.RotSpeed = NumberRange.new(-24, 24)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 10)
	registrar(ancora, 2.4)
end

--- Cacos orbitando um ponto. É o que faz telecinese parecer telecinese: peça
--- SÓLIDA no ar, parada onde não deveria estar.
local function camadaCacos(p, c, raio, quantos, vida, registro)
	for i = 1, (quantos or 8) do
		local a = angulo(i)
		local altura = ((i % 3) - 1) * raio * 0.35
		local caco = novaParte({
			Size = Vector3.new(0.5 + math.abs(jitter(i)) * 0.7,
				0.4 + math.abs(jitter(i + 9)) * 0.6,
				0.5 + math.abs(jitter(i + 3)) * 0.7),
			Color = CFG.COR_TERRA,
			Material = Enum.Material.Slate,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a) * raio, altura,
				math.sin(a) * raio)) * CFrame.Angles(a, a * 0.7, a * 1.3),
		})
		local halo = Instance.new("SelectionBox")
		halo.Adornee = caco
		halo.Color3 = c
		halo.LineThickness = 0.03
		halo.Transparency = 0.4
		halo.Parent = caco
		tween(caco, vida or 1.2, {
			CFrame = CFrame.new(p + Vector3.new(math.cos(a + 1.2) * raio * 0.7,
				altura + 0.6, math.sin(a + 1.2) * raio * 0.7))
				* CFrame.Angles(a * 1.4, a, a * 0.5),
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		registrar(caco, (vida or 1.2) + 0.2)
		if registro then table.insert(registro, caco) end
	end
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

local function pos(d) return (d and d.posicao) or Vector3.new() end
local function escala(d) return (d and d.escala) or 1 end
local function cor(d, padrao) return (d and d.cor) or padrao or CFG.COR_CAMPO end

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id].partes
end

--- Onda de tremor: corre para fora, no plano do chão.
function Efeitos.ONDA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaAnel(p, c, 5 * e, 0.45)
	camadaPoeira(p, CFG.COR_TERRA, 0.7 * e, 10)
	camadaEixo(p, c, 0.5 * e, 12, 9, 60)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.5,
		Vector3.new(5 * e, 1.2, 5 * e), Vector3.new(20 * e, 0.3, 20 * e),
		branco(c, 0.5), c)
end

--- Pulso sustentado — o beat repetido do tremor.
function Efeitos.PULSO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaAnel(p, c, 3.4 * e, 0.34, 0.2)
	camadaEixo(p, c, 0.35 * e, 8, 7, 55)
end

--- Campo de gravidade invertida: tudo SOBE. É o efeito assinatura do conjunto.
function Efeitos.CAMPO_INVERSO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local reg = registroDe(d)
	local domo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1),
		Color = c,
		Transparency = 0.82,
		CFrame = CFrame.new(p),
	})
	tween(domo, 0.3, { Size = Vector3.new(2, 2, 2) * (d and d.raio or 14) },
		Enum.EasingStyle.Back)
	registrar(domo, (d and d.duracao) or 5)
	if reg then table.insert(reg, domo) end

	camadaEixo(p, c, 0.8 * e, 26, 16, 45)
	camadaAnel(p, c, 5 * e, 0.5)
	pk("Sonar_Ring", CFrame.new(p), 0.8, 0, 9 * e, 1.4, 0.2, branco(c, 0.5), c)
end

--- Esmagamento: tudo DESCE. É o CAMPO_INVERSO ao contrário, e de propósito.
function Efeitos.ESMAGA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_PESO)
	camadaFlash(p, c, 3 * e)
	camadaEixo(p + Vector3.new(0, 8 * e, 0), c, 0.75 * e, 22, -20, 30)
	camadaAnel(p, c, 6 * e, 0.36, 0.45)
	camadaPoeira(p, CFG.COR_TERRA, 0.9 * e, 12)
	pk("Shockwave_2", CFrame.new(p), CFrame.new(p), 0.45,
		Vector3.new(4 * e, 1.6, 4 * e), Vector3.new(18 * e, 0.4, 18 * e),
		branco(c, 0.4), c)
end

--- O alvo erguido: anel embaixo dele e motes subindo. Some por `Parar`.
function Efeitos.LEVITA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local reg = registroDe(d)
	camadaEixo(p - Vector3.new(0, 2.4, 0), c, 0.55 * e, 16, 12, 22)

	local disco = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.16, 1, 1),
		Color = branco(c, 0.35),
		Transparency = 0.35,
		CFrame = CFrame.new(p - Vector3.new(0, 2.6, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(disco, 0.28, { Size = Vector3.new(0.16, 6 * e, 6 * e) },
		Enum.EasingStyle.Back)
	registrar(disco, (d and d.duracao) or 4)
	if reg then table.insert(reg, disco) end
	pk("Sonar_Ring", CFrame.new(p), 0.5, 0, 5 * e, 1, 0.12, branco(c, 0.6), c)
end

--- Levitação do próprio corpo.
function Efeitos.FLUTUA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaEixo(p - Vector3.new(0, 2.6, 0), c, 0.5 * e, 14, 13, 28)
	camadaAnel(p - Vector3.new(0, 2.8, 0), c, 3.4 * e, 0.5, 0.18)
end

--- A "mão" invisível: feixe curto do portador ao alvo.
function Efeitos.AGARRA(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local c = cor(d)
	if not pk("Laser_Shot", origem, destino, 0.22, 0.04, 6,
			branco(c, 0.55), c) then
		local delta = destino - origem
		if delta.Magnitude < 0.1 then return end
		local feixe = novaParte({
			Size = Vector3.new(0.2, 0.2, delta.Magnitude),
			Color = branco(c, 0.4),
			Transparency = 0.35,
			CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
		})
		tween(feixe, 0.22, { Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(feixe, 0.4)
	end
	camadaEixo(destino, c, 0.4, 8, 6, 60)
end

--- Cacos parados no ar em volta de um ponto. Some por `Parar`.
function Efeitos.CACOS(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaCacos(p, c, 4.5 * e, (d and d.quantos) or 8,
		(d and d.duracao) or 1.2, registroDe(d))
end

--- Rastro de destroço arremessado.
function Efeitos.DESTROCO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaEixo(p, c, 0.3 * e, 6, 4, 90)
end

--- Batida de asa: dois leques de motes para trás, e o empurrão.
function Efeitos.ASA(d)
	local e, c = escala(d), cor(d)
	local cf = (d and d.cframe) or CFrame.new(pos(d))
	for lado = -1, 1, 2 do
		local ponto = cf.Position + cf.RightVector * (2.4 * lado * e)
			+ cf.UpVector * 0.6
		camadaEixo(ponto, c, 0.55 * e, 12, 10, 48)
	end
	camadaAnel(cf.Position - Vector3.new(0, 1.2, 0), c, 4 * e, 0.4, 0.2)
	pk("Small_Slash", cf * CFrame.Angles(0, 0, math.rad(90)), 8 * e, 0.24,
		branco(c, 0.6), c)
end

--- Impacto de mergulho.
function Efeitos.MERGULHO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaFlash(p, c, 3.4 * e)
	camadaAnel(p, c, 7 * e, 0.4, 0.4)
	camadaPoeira(p, CFG.COR_TERRA, 1 * e, 14)
	camadaEixo(p, c, 0.7 * e, 18, 11, 70)
	pk("Floor_Crack", CFrame.new(p), 8 * e, 3, c)
end

--- Rachadura que corre à frente. `direcao` decide para onde.
function Efeitos.RACHADURA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local direcao = (d and d.direcao) or Vector3.new(0, 0, -1)
	if direcao.Magnitude < 0.01 then direcao = Vector3.new(0, 0, -1) end
	direcao = direcao.Unit
	local passos = (d and d.passos) or 6
	for i = 1, passos do
		local onde = p + direcao * (i * 4 * e)
		local atraso = (i - 1) * 0.05
		task.delay(atraso, function()
			camadaPoeira(onde, CFG.COR_TERRA, 0.5 * e, 5)
			camadaEixo(onde, c, 0.35 * e, 6, 8, 30)
		end)
	end
	pk("Floor_Crack", CFrame.lookAt(p, p + direcao), 10 * e, 4, c)
end

--- O ultimate. Carga longa: domo que aperta, cacos subindo, tremor.
function Efeitos.COLAPSO_CARGA(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local reg = registroDe(d)
	local domo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2) * (d and d.raio or 26),
		Color = c,
		Transparency = 0.9,
		CFrame = CFrame.new(p),
	})
	tween(domo, (d and d.duracao) or 5, {
		Size = Vector3.new(2, 2, 2) * ((d and d.raio or 26) * 0.55),
		Transparency = 0.68,
	}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	registrar(domo, ((d and d.duracao) or 5) + 0.5)
	if reg then table.insert(reg, domo) end

	camadaCacos(p, c, 10 * e, 14, (d and d.duracao) or 5, reg)
	camadaEixo(p, c, 0.9 * e, 30, 14, 70)
end

--- O ultimate estourando.
function Efeitos.COLAPSO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_PESO)
	camadaFlash(p, c, 8 * e)
	for i = 1, 3 do
		local raio = (8 + i * 6) * e
		task.delay((i - 1) * 0.09, function()
			camadaAnel(p, c, raio, 0.5 + i * 0.06, 0.6)
		end)
	end
	camadaEixo(p, c, 1.1 * e, 40, 26, 80)
	camadaPoeira(p, CFG.COR_TERRA, 1.4 * e, 20)
	pk("Shockwave_Explosion", p, 1.2, 4 * e, 30 * e, branco(c, 0.5), c)
	pk("Floor_Crack", CFrame.new(p), 22 * e, 6, c)
end

--- Puxão: motes convergem PARA o ponto. É o inverso de toda explosão.
function Efeitos.PUXAO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local raio = (d and d.raio) or 18
	for i = 1, 10 do
		local a = angulo(i)
		local borda = p + Vector3.new(math.cos(a) * raio, 1.5 + (i % 3),
			math.sin(a) * raio)
		local mote = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.7, 0.7, 0.7) * e,
			Color = branco(c, 0.35),
			Transparency = 0.2,
			CFrame = CFrame.new(borda),
		})
		tween(mote, 0.42, { CFrame = CFrame.new(p),
			Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 },
			Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		registrar(mote, 0.6)
	end
	camadaAnel(p, c, raio * 0.5, 0.4, 0.2)
	pk("Sonar_Ring", CFrame.new(p), 0.6, raio, 0, 1.6, 0.2, branco(c, 0.6), c)
end

--- A singularidade: esfera que aperta e some. Some por `Parar`.
function Efeitos.SINGULARIDADE(d)
	local p, e, c = pos(d), escala(d), cor(d)
	local reg = registroDe(d)
	local nucleo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6) * e,
		Color = CFG.COR_PESO,
		Transparency = 0.15,
		CFrame = CFrame.new(p),
	})
	tween(nucleo, (d and d.duracao) or 1.1,
		{ Size = Vector3.new(1.2, 1.2, 1.2) * e },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	registrar(nucleo, ((d and d.duracao) or 1.1) + 0.3)
	if reg then table.insert(reg, nucleo) end
	camadaCacos(p, c, 6 * e, 10, (d and d.duracao) or 1.1, reg)
	pk("Spiral_Effect", p, 1.6 * e, c, 3, 6 * e, 5 * e)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Gravidade] falha em " .. tostring(tipo)
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
