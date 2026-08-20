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
	-- Se o Server mandou a PEÇA, o emissor mora nela e a aura anda junto. Sem
	-- peça, ele nasce numa âncora parada no ponto — que é o que a versão
	-- anterior fazia, e por isso o portador saía de dentro da própria aura.
	local peca = (d and d.peca)
	local ancora = (peca and peca:IsA("BasePart")) and peca or novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
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
	-- Se o Server mandou a PEÇA, o emissor mora nela e a aura anda junto. Sem
	-- peça, ele nasce numa âncora parada no ponto — que é o que a versão
	-- anterior fazia, e por isso o portador saía de dentro da própria aura.
	local peca = (d and d.peca)
	local ancora = (peca and peca:IsA("BasePart")) and peca or novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
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

	-- Se o Server mandou a PEÇA, o emissor mora nela e a aura anda junto. Sem
	-- peça, ele nasce numa âncora parada no ponto — que é o que a versão
	-- anterior fazia, e por isso o portador saía de dentro da própria aura.
	local peca = (d and d.peca)
	local ancora = (peca and peca:IsA("BasePart")) and peca or novaParte({
		Size = Vector3.new(0.2, 0.2, 0.2),
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
	local prazo = (d and (d.vida or d.duracao)) or 12
	-- a peça é do PERSONAGEM: quem some é o emissor, nunca ela. Registrar o
	-- HumanoidRootPart no `Debris` apagaria o jogador junto com a aura.
	if ancora == peca then
		Debris:AddItem(att, prazo)
		if reg then table.insert(reg, att) end
	else
		registrar(ancora, prazo)
		if reg then table.insert(reg, ancora) end
	end
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
--- O feixe. Ele agora é SEGURADO e chega a ~8 pacotes por segundo, então o
--- desenho tem de ser barato: um cilindro, um clarão no fim, e nada mais.
--- `posicao`/`para` são os nomes que o Server usa; `origem`/`destino` ficam
--- porque a versão anterior mandava assim e trocar os dois lados de uma vez é
--- como se perde um efeito em silêncio.
function Efeitos.FEIXE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or (d and d.para) or origem
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
-- O REFAZIMENTO — 12 efeitos das habilidades redesenhadas
--
-- Onde já havia forma equivalente, ela foi REUSADA em vez de recriada:
-- `SOCO`, `CORTE`, `EMPURRAO`, `ESQUIVA`, `RACHA`, `AURA`, `AURA_PULSO`,
-- `ESTILHACO`, `EXECUCAO` e `FEIXE` entraram intactos. O que está abaixo é o
-- que não existia — e cada um existe porque a habilidade nova tem uma LEITURA
-- que nenhuma das antigas dá.
--═══════════════════════════════════════════════════════════════

-- ── COMBATE · o counter ─────────────────────────────────────────────

--- A janela aberta: um anel raso em volta do portador, que PULSA devagar.
--- Devagar é o ponto — quem está do outro lado precisa ver que a guarda está
--- de pé e decidir não bater. Counter que não avisa é armadilha, não counter.
function Efeitos.CONTRA_ABRE(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.vida) or 1
	local c = cor(d, CFG.COR_BRASA)
	camadaAnel(p - Vector3.new(0, 2.4, 0), c, 5 * e, math.min(vida, 0.5), 0.3)
	camadaFlash(p, c, 1.6 * e)
	camadaFaiscas(p, c, 0.25 * e, 5, 3)
end

--- A devolvida: rasgo do portador PARA o agressor, e estouro nele. O rasgo é
--- o que diz de onde veio — sem ele o agressor só vê dano do nada.
function Efeitos.CONTRA_DEVOLVE(d)
	local p, e = pos(d), escala(d)
	local de = (d and d.de) or p
	local c = cor(d, CFG.COR_BRASA)
	local delta = p - de
	if delta.Magnitude > 0.5 then
		camadaRasgo(CFrame.lookAt(de + delta * 0.5, p),
			c, delta.Magnitude, 0.7 * e, 0.2)
	end
	camadaFlash(p, c, 3 * e)
	camadaFaiscas(p, c, 0.8 * e, 18, 6)
	pk("Small_Nova", p, 0.26, 0, 7 * e, branco(c, 0.6), c)
end

--- Pegou o golpe e não achou quem deu. O gesto sai, o dano não — e o desenho
--- diz isso: clarão sem rasgo e sem estouro.
function Efeitos.CONTRA_VAZIO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_POEIRA)
	camadaFlash(p, c, 2 * e)
	camadaAnel(p, c, 3.4 * e, 0.3, 0.18)
end

-- ── DESVIAR · os i-frames ───────────────────────────────────────────

--- A invencibilidade tem de ser VISÍVEL. `ForceField.Visible = false` esconde
--- o brilho padrão do Roblox — que é feio e não combina com nada aqui —, e
--- este efeito põe no lugar uma casca curta que diz a mesma coisa.
--- Invencibilidade que não se vê é o adversário achando que o jogo bugou.
function Efeitos.IMUNE(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.vida) or 0.42
	local c = cor(d, CFG.COR_GELO)
	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6) * e,
		Color = c,
		Material = Enum.Material.ForceField,
		Transparency = 0.55,
		CFrame = CFrame.new(p),
	})
	tween(casca, vida, { Transparency = 1,
		Size = Vector3.new(7.4, 7.4, 7.4) * e }, Enum.EasingStyle.Quad)
	registrar(casca, vida + 0.1)
end

-- ── CORTE FRIO · a série ────────────────────────────────────────────

--- A marca de gelo em quem foi cortado. Fica um pouco, porque a lentidão
--- também fica: efeito que some antes do que ele representa é mentira visual.
function Efeitos.GELO(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.vida) or 1.8
	local c = cor(d, CFG.COR_GELO)
	for i = 1, 4 do
		local a = angulo(i)
		local lasca = novaParte({
			Size = Vector3.new(0.34, 2.2 + i * 0.3, 0.34) * e,
			Color = c,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a), -0.6,
				math.sin(a)) * (1.5 * e))
				* CFrame.Angles(math.rad(jitter(i) * 22), a,
					math.rad(jitter(i + 3) * 22)),
		})
		tween(lasca, vida, { Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(lasca, vida + 0.2)
	end
	camadaFlash(p, CFG.COR_GELO_FUN, 1.4 * e)
end

--- Um corte da série. O ÂNGULO vem do servidor, tirado do ângulo áureo por
--- ordem: seis cortes, seis inclinações que não se repetem. Sem isso os seis
--- cairiam sobrepostos e a série leria como um corte só piscando.
function Efeitos.CORTE_SERIE(d)
	local p, e = pos(d), escala(d)
	local ang = (d and d.angulo) or angulo()
	local ordem = (d and d.ordem) or 1
	local c = cor(d, CFG.COR_GELO)
	local cf = CFrame.new(p) * CFrame.Angles(0, ang, math.rad(28 + ordem * 14))
	camadaRasgo(cf, c, (7 + ordem * 0.7) * e, 0.5 * e, 0.14)
	camadaFlash(p, branco(c, 0.4), 1.7 * e)
	camadaFaiscas(p, c, 0.4 * e, 8, -4)
	pk("Small_Slash", cf, (8 + ordem) * e, 0.18, branco(c, 0.7), c)
end

-- ── IMPACTO FORTE · o soco sério ────────────────────────────────────

--- A carga do punho. Ela existe para o adversário ter o que ler: 0.62 s de
--- aviso antes de um golpe que arremessa 90 studs.
function Efeitos.CARREGA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_BRASA)
	camadaFlash(p, c, 1.5 * e)
	camadaFaiscas(p, c, 0.35 * e, 8, 5)
	camadaAnel(p, c, 2.6 * e, 0.34, 0.2)
end

--- O CORREDOR. É a forma inteira desta habilidade: uma faixa reta e longa, não
--- uma esfera. Esfera lê como explosão; faixa lê como sopro, e era a faixa que
--- estava sendo pedida.
---
--- Os anéis descem a reta com atraso crescente — é o que faz o corredor ser
--- percorrido em vez de aparecer inteiro de uma vez.
function Efeitos.SOCO_SERIO(d)
	local origem = pos(d)
	local destino = (d and d.para) or origem
	local largura = (d and d.largura) or 7
	local e = escala(d)
	local c = cor(d, CFG.COR_BRASA)

	local delta = destino - origem
	if delta.Magnitude < 1 then return end
	local direcao = delta.Unit
	local olhar = CFrame.lookAt(origem, destino)

	local tubo = novaParte({
		Size = Vector3.new(largura * e, largura * e, delta.Magnitude),
		Color = branco(c, 0.45),
		Transparency = 0.55,
		CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
	})
	tween(tubo, 0.34, { Transparency = 1,
		Size = Vector3.new(largura * 0.3 * e, largura * 0.3 * e,
			delta.Magnitude) }, Enum.EasingStyle.Quint)
	registrar(tubo, 0.5)

	for i = 1, 6 do
		local fracao = i / 6
		local onde = origem + direcao * (delta.Magnitude * fracao)
		task.delay((i - 1) * 0.035, function()
			camadaAnel(onde, c, (largura * 0.6 + i * 0.8) * e, 0.28, 0.26)
		end)
	end

	camadaFlash(origem + direcao * 3, c, 4 * e)
	camadaPoeira(origem - Vector3.new(0, 2.4, 0), CFG.COR_POEIRA, 1.1 * e, 16)
	pk("Small_Nova", origem + direcao * 3, 0.3, 0, 9 * e, branco(c, 0.6), c)
	pk("Shockwave", olhar, olhar, 0.4,
		Vector3.new(largura, 2, largura) * e,
		Vector3.new(largura * 2.4, 3, largura * 2.4) * e,
		c, branco(c, 0.5), Enum.EasingStyle.Quint)
end

-- ── AURA · a reflexão ───────────────────────────────────────────────

--- O estalo de quem devolveu. Curto — ele acontece TODA vez que o portador
--- apanha, e um efeito longo aqui viraria uma parede de luz numa troca de
--- tiros.
function Efeitos.AURA_DEVOLVE(d)
	local p, e = pos(d), escala(d)
	local de = (d and d.de) or nil
	local c = cor(d, CFG.COR_AURA)
	if de and (p - de).Magnitude > 0.5 then
		local delta = p - de
		camadaRasgo(CFrame.lookAt(de + delta * 0.5, p),
			c, delta.Magnitude, 0.4 * e, 0.16)
	end
	camadaFlash(p, c, 2.2 * e)
	camadaFaiscas(p, c, 0.5 * e, 10, 4)
end

-- ── OLHOS LASER · a sobrecarga ──────────────────────────────────────

--- A carga nos olhos, antes do estouro.
function Efeitos.SOBRECARGA_CARGA(d)
	local p, e = pos(d), escala(d)
	local vida = (d and d.vida) or 0.9
	local c = cor(d, CFG.COR_CARMESIM)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.3, 0.3, 0.3) * e,
		Color = branco(c, 0.5),
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 6, 12 * e
	luz.Parent = bola
	tween(bola, vida, { Size = Vector3.new(2.4, 2.4, 2.4) * e },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(bola, vida + 0.1)
	task.delay(vida, function()
		if bola and bola.Parent then bola.Parent = nil end
	end)
	camadaFaiscas(p, c, 0.3 * e, 6, 3)
end

--- O estouro: núcleo e borda, com o rasgo que liga os olhos ao ponto.
function Efeitos.SOBRECARGA(d)
	local p, e = pos(d), escala(d)
	local de = (d and d.de) or p
	local raio = (d and d.raio) or 22
	local c = cor(d, CFG.COR_CARMESIM)

	local delta = p - de
	if delta.Magnitude > 1 then
		local viga = novaParte({
			Size = Vector3.new(1.4 * e, 1.4 * e, delta.Magnitude),
			Color = branco(c, 0.6),
			Transparency = 0.1,
			CFrame = CFrame.lookAt(de + delta * 0.5, p),
		})
		tween(viga, 0.3, { Transparency = 1,
			Size = Vector3.new(0.2 * e, 0.2 * e, delta.Magnitude) },
			Enum.EasingStyle.Quint)
		registrar(viga, 0.45)
	end

	camadaFlash(p, branco(c, 0.4), 6 * e)
	camadaFaiscas(p, c, 1.2 * e, 24, 8)
	camadaPoeira(p, CFG.COR_POEIRA, 1 * e, 12)
	pk("Small_Nova", p, 0.34, 0, raio * e, branco(c, 0.6), c)
	pk("Shockwave_Explosion", p, 0.42, 2 * e, raio * e, c, branco(c, 0.5))
end

-- ── CORTADA FATAL ───────────────────────────────────────────────────

--- A cortada: rasgo VERTICAL, e a onda que corre pelo chão à frente. O
--- vertical é o que a separa do corte lateral do `Corte Frio` — a mesma lâmina
--- com outro arco tem de ler diferente.
function Efeitos.CORTADA(d)
	local p, e = pos(d), escala(d)
	local alcance = (d and d.alcance) or 26
	local cf = quadro(d)
	local c = cor(d, CFG.COR_CARMESIM)

	camadaRasgo(cf * CFrame.new(0, 1.6, -2) * CFrame.Angles(0, 0, math.rad(90)),
		c, 12 * e, 0.8 * e, 0.18)
	camadaFlash(p, c, 3 * e)
	camadaFaiscas(p, c, 0.8 * e, 16, -8)

	-- a onda no chão: seis anéis descendo a reta, com atraso crescente
	local chao = cf.Position - Vector3.new(0, 2.2, 0)
	for i = 1, 6 do
		local onde = chao + cf.LookVector * (alcance * i / 6)
		task.delay((i - 1) * 0.03, function()
			camadaAnel(onde, c, (2.4 + i * 0.9) * e, 0.26, 0.22)
		end)
	end
	camadaPoeira(chao, CFG.COR_POEIRA, 0.8 * e, 10)
	pk("Small_Slash", cf * CFrame.new(0, 1.4, -2), 13 * e, 0.24,
		branco(c, 0.6), c)
end

--- A marca da execução, no alvo, antes do golpe cair. Ela é o aviso de que a
--- cena vai terminar em alguma coisa — cutscene sem marca é cutscene em que o
--- espectador não sabe onde olhar.
function Efeitos.FATAL_MARCA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_CARMESIM)
	for i = 1, 3 do
		task.delay((i - 1) * 0.12, function()
			camadaAnel(p, c, (7 - i * 1.6) * e, 0.34, 0.3)
		end)
	end
	camadaFlash(p + Vector3.new(0, 2, 0), c, 2.4 * e)
end

--- E o golpe. É o efeito mais caro do conjunto, e é de propósito: ele fecha
--- uma cutscene de 6 s com 26 s de recarga.
function Efeitos.FATAL(d)
	local p, e = pos(d), escala(d)
	local cf = quadro(d)
	local c = cor(d, CFG.COR_CARMESIM)

	camadaRasgo(CFrame.new(p) * CFrame.Angles(0, cf and 0 or 0, math.rad(90)),
		c, 18 * e, 1.4 * e, 0.24)
	camadaFlash(p, branco(c, 0.5), 8 * e)
	camadaFaiscas(p, c, 1.5 * e, 30, -10)
	camadaPoeira(p - Vector3.new(0, 2, 0), CFG.COR_POEIRA, 1.4 * e, 20)
	for i = 1, 3 do
		task.delay((i - 1) * 0.07, function()
			camadaAnel(p - Vector3.new(0, 2.2, 0), c, (6 + i * 4) * e,
				0.36, 0.34)
		end)
	end
	pk("Small_Nova", p, 0.4, 0, 16 * e, branco(c, 0.65), c)
	pk("Shockwave_Explosion", p, 0.5, 3 * e, 20 * e, c, branco(c, 0.5))
	pk("Floor_Crack", CFrame.new(p - Vector3.new(0, 2.4, 0)), 14 * e, 5,
		CFG.COR_POEIRA)
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
