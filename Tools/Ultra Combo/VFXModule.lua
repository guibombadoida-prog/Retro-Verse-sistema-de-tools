-- VFXModule_Faker_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto FAKER
--
-- ONDE RODA: CLIENTE, EM TODOS ELES.
--
--   Isto não é detalhe de implementação neste conjunto — é o conserto. O modelo
--   de origem punha 796 linhas de VFX em dois **LocalScript**, e LocalScript
--   dentro de Tool só roda para o jogador cujo Character a contém. O efeito
--   acontecia **só na tela de quem segurava a Tool**: para o resto do servidor
--   a habilidade era invisível, e como o `Shoot` de servidor tinha 40 linhas e
--   nenhum `TakeDamage`, ela também não fazia nada.
--
--   Aqui o servidor transmite por `VFXRemote:FireAllClients` e o `Client` é
--   `Script` com `RunContext = Client`, que roda em TODO cliente. Quem desenha
--   é quem vê — e todos veem.
--
-- A LINGUAGEM VISUAL SAI DAS MALHAS DO PRÓPRIO MODELO
--
--   Os outros conjuntos deste repositório desenham com `Part` primitiva
--   esticada. Este não: o `faker_tools.rbxmx` traz **sete malhas**, e cinco
--   delas o código de origem nunca ligou. Elas são o vocabulário.
--
--     E           disco chato 9.9 × 1.0 × 9.9   anel de impacto
--     Erlo        bloco 5³                       parede de prisão
--     Sphere      esfera 4³                      núcleo
--     Spiral      espiral 33 × 17 × 40           ilusão, funil
--     WindSphere  domo 9.9³                      a sala
--     Ring        anel 500 × 48 × 500            a onda que corre longe
--     Mushroom    cogumelo 522 × 543 × 522       o fim de uma era
--
--   `Ring` e `Mushroom` são duas ordens de grandeza maiores que o resto. Não
--   são efeito de golpe: são efeito de EVENTO, e por isso só a `Era Do Fim` e o
--   `Abismo Profundo` os usam.
--
-- PALETA: PRETO COM CONTORNO BRANCO
--
--   É a assinatura do original — `Color3.new(0,0,0)` no corpo do laser e
--   `Color3.new(1,1,1)` no núcleo. Nenhum outro conjunto do repositório é
--   preto, então ele se distingue sem precisar de cor.
--
-- Zero math.random: o original tinha 67. Aqui é ângulo áureo e jitter senoidal
-- por contador — e neste conjunto isso importa mais que nos outros, porque com
-- todos os clientes desenhando, um sorteio faria cada um ver uma cena
-- diferente. Isso lê como lag, não como efeito.
--
-- Gerado por FERRAMENTAS/gerar_servers_faker.py.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_VAZIO    = Color3.fromRGB(10, 8, 14),
	COR_BORDA    = Color3.fromRGB(255, 255, 255),
	COR_FALHA    = Color3.fromRGB(176, 96, 255),
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

local function tween(inst, tempo, alvo, estilo, direcao)
	local info = TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad,
		direcao or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, alvo)
	t:Play()
	return t
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

--═══════════════════════════════════════════════════════════════
-- OS MOLDES — as malhas do próprio modelo, dentro da Tool
--
-- Elas vivem em `Tool/Moldes/`, invisíveis (`Transparency = 1`). O clone é que
-- aparece: é a regra que o usuário fixou — *"deixar os vfx invisível dentro da
-- tool, e visível na execução da habilidade"*.
--
-- Se o molde não estiver lá, cada efeito cai num fallback com `Part`
-- primitiva. A Tool sozinha num place vazio continua funcionando.
--═══════════════════════════════════════════════════════════════

local pastaMoldes = nil
local procurada = false

local function moldes()
	if procurada then return pastaMoldes end
	procurada = true
	local tool = script.Parent
	-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois.
	-- O depósito MOVE `Moldes` para fora da Tool quando ela chega ao jogador;
	-- sem a primeira porta estas Tools parariam de achar a própria malha.
	pastaMoldes = Deposito.achar(script, "Moldes")
		or (tool and tool:FindFirstChild("Moldes"))
	return pastaMoldes
end

--- Clona um molde e o acende. `nil` se a Tool não trouxer aquela malha.
local function molde(nome, props)
	local pasta = moldes()
	local base = pasta and pasta:FindFirstChild(nome)
	if not base then return nil end
	local copia = base:Clone()
	copia.Anchored = true
	copia.CanCollide = false
	copia.CanTouch = false
	copia.CanQuery = false
	copia.Transparency = 0
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	copia.Parent = workspace
	return copia
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

local function camadaFlash(p, c, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.5,
		Color = c,
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = CFG.COR_BORDA, 8, raio * 4
	luz.Parent = bola
	tween(bola, 0.06, { Size = Vector3.new(raio, raio, raio) * 1.5,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.24)
end

--- Cacos quadrados que giram e somem. É a assinatura do original: ele fazia
--- dois `StartSquare`/`EndSquare` com `Orientation` sorteada. Aqui são seis,
--- em ângulo áureo, e o giro é por índice — todos veem o mesmo.
local function camadaCacos(p, escala, quantos)
	for i = 1, (quantos or 6) do
		local a = angulo(i)
		local caco = novaParte({
			Size = Vector3.new(0.3, 0.3, 0.3) * escala,
			Color = CFG.COR_VAZIO,
			Transparency = 0.05,
			CFrame = CFrame.new(p) * CFrame.Angles(a, a * 0.7, a * 1.3),
		})
		local borda = Instance.new("SelectionBox")
		borda.Adornee = caco
		borda.Color3 = CFG.COR_BORDA
		borda.LineThickness = 0.035
		borda.Transparency = 0.15
		borda.Parent = caco
		tween(caco, 0.7, {
			Size = Vector3.new(2, 2, 2) * escala,
			Transparency = 1,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a), 0.6, math.sin(a))
				* (3 * escala)) * CFrame.Angles(a * 2.1, a * 1.4, a * 0.9),
		}, Enum.EasingStyle.Quint)
		registrar(caco, 0.9)
	end
end

local function camadaFaiscas(p, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(CFG.COR_BORDA, CFG.COR_FALHA)
	em.LightEmission = 1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.2, 0.55)
	em.Speed = NumberRange.new(14 * forca, 34 * forca)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Rotation = NumberRange.new(0, 360)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 12)
	registrar(ancora, 1.2)
end

--- O laser do original: corpo PRETO grosso e núcleo BRANCO fino, na mesma
--- linha. É o que dá a leitura de "buraco no ar" em vez de "raio colorido".
local function camadaFeixe(origem, destino, grossura, tempo)
	local delta = destino - origem
	if delta.Magnitude < 0.1 then return end
	local meio = CFrame.lookAt(origem + delta * 0.5, destino)

	local corpo = novaParte({
		Size = Vector3.new(grossura, grossura, delta.Magnitude),
		Color = CFG.COR_VAZIO,
		Transparency = 0.15,
		CFrame = meio,
	})
	local nucleo = novaParte({
		Size = Vector3.new(grossura * 0.45, grossura * 0.45, delta.Magnitude),
		Color = CFG.COR_BORDA,
		Transparency = 0,
		CFrame = meio,
	})
	tween(corpo, tempo or 0.22, { Transparency = 1,
		Size = Vector3.new(grossura * 2, grossura * 2, delta.Magnitude) })
	tween(nucleo, (tempo or 0.22) * 0.7, { Transparency = 1,
		Size = Vector3.new(0.02, 0.02, delta.Magnitude) })
	registrar(corpo, (tempo or 0.22) + 0.2)
	registrar(nucleo, (tempo or 0.22) + 0.2)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

local function pos(d) return (d and d.posicao) or Vector3.new() end
local function escala(d) return (d and d.escala) or 1 end
local function quadro(d)
	if d and d.cframe then return d.cframe end
	return CFrame.new(pos(d))
end

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id].partes
end

--- Impacto de golpe: o disco `E` deitado no chão, mais cacos.
function Efeitos.IMPACTO(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_VAZIO, 2.4 * e)
	camadaCacos(p, 0.7 * e, 5)
	camadaFaiscas(p, 0.5 * e, 10)

	local disco = molde("E", {
		Size = Vector3.new(2, 0.2, 2) * e,
		CFrame = CFrame.new(p) * CFrame.Angles(0, angulo(), 0),
		Color = CFG.COR_VAZIO,
	})
	if disco then
		tween(disco, 0.34, { Size = Vector3.new(10, 0.06, 10) * e,
			Transparency = 1 }, Enum.EasingStyle.Quint)
		registrar(disco, 0.5)
	end
end

--- O cogumelo. `Mushroom` tem 522 studs de origem: a escala aqui é FRAÇÃO
--- dele, nunca múltiplo — o molde já é grande demais.
function Efeitos.COGUMELO(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 14 * e)

	local cog = molde("Mushroom", {
		Size = Vector3.new(20, 21, 20) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.1,
	})
	if cog then
		tween(cog, 1.8, {
			Size = Vector3.new(130, 136, 130) * e,
			CFrame = CFrame.new(p + Vector3.new(0, 60 * e, 0)),
			Transparency = 1,
		}, Enum.EasingStyle.Quint)
		registrar(cog, 2.2)
	end
	camadaCacos(p, 2.4 * e, 12)
	camadaFaiscas(p, 1.4 * e, 30)
end

--- O anel que corre. `Ring` tem 500 studs: aqui ele NASCE pequeno e cresce.
function Efeitos.ANEL(d)
	local p, e = pos(d), escala(d)
	local anel = molde("Ring", {
		Size = Vector3.new(8, 1.2, 8) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.05,
	})
	if anel then
		tween(anel, (d and d.duracao) or 0.9, {
			Size = Vector3.new(180, 0.4, 180) * e,
			Transparency = 1,
		}, Enum.EasingStyle.Quint)
		registrar(anel, ((d and d.duracao) or 0.9) + 0.3)
	else
		local disco = novaParte({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 8 * e, 8 * e),
			Color = CFG.COR_VAZIO,
			Transparency = 0.15,
			CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
		})
		tween(disco, 0.9, { Size = Vector3.new(0.05, 180 * e, 180 * e),
			Transparency = 1 }, Enum.EasingStyle.Quint)
		registrar(disco, 1.2)
	end
	camadaFaiscas(p, 0.9 * e, 16)
end

--- A sala: o domo `WindSphere` fecha em volta. Some por `Parar`.
function Efeitos.SALA(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local raio = (d and d.raio) or 26

	local domo = molde("WindSphere", {
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.25,
	})
	if not domo then
		domo = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1),
			Color = CFG.COR_VAZIO,
			Transparency = 0.35,
			CFrame = CFrame.new(p),
		})
	end
	tween(domo, 0.45, { Size = Vector3.new(2, 2, 2) * raio },
		Enum.EasingStyle.Back)
	registrar(domo, (d and d.duracao) or 8)
	if reg then table.insert(reg, domo) end

	camadaCacos(p, 1.6 * e, 10)
	camadaFaiscas(p, 0.8 * e, 18)
end

--- A sala implodindo.
function Efeitos.SALA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 8 * e)
	camadaCacos(p, 2.2 * e, 16)
	camadaFaiscas(p, 1.2 * e, 26)
end

--- A espiral. `Spiral` tem 33 × 17 × 40: ela GIRA, e o giro é por tween de
--- `CFrame`, não por laço no servidor.
function Efeitos.ESPIRAL(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local espiral = molde("Spiral", {
		Size = Vector3.new(10, 5, 12) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_FALHA,
		Transparency = 0.3,
	})
	if espiral then
		tween(espiral, (d and d.duracao) or 1.6, {
			Size = Vector3.new(34, 17, 40) * e,
			CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(720), 0),
			Transparency = 1,
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		registrar(espiral, ((d and d.duracao) or 1.6) + 0.3)
		if reg then table.insert(reg, espiral) end
	end
	camadaFaiscas(p, 0.7 * e, 14)
end

--- A prisão: quatro paredes `Erlo` em volta do alvo, e o núcleo `Sphere`.
function Efeitos.PRISAO(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local raio = (d and d.raio) or 4.5

	for i = 1, 4 do
		local a = (i - 1) * math.pi / 2
		local parede = molde("Erlo", {
			Size = Vector3.new(0.4, 9, 9) * e,
			CFrame = CFrame.new(p + Vector3.new(math.cos(a) * raio, 0,
				math.sin(a) * raio)) * CFrame.Angles(0, -a, 0),
			Color = CFG.COR_VAZIO,
			Transparency = 0.2,
		})
		if not parede then
			parede = novaParte({
				Size = Vector3.new(0.4, 9, 9) * e,
				Color = CFG.COR_VAZIO,
				Transparency = 0.3,
				CFrame = CFrame.new(p + Vector3.new(math.cos(a) * raio, 0,
					math.sin(a) * raio)) * CFrame.Angles(0, -a, 0),
			})
		end
		local borda = Instance.new("SelectionBox")
		borda.Adornee = parede
		borda.Color3 = CFG.COR_BORDA
		borda.LineThickness = 0.05
		borda.Transparency = 0.1
		borda.Parent = parede
		registrar(parede, (d and d.duracao) or 4)
		if reg then table.insert(reg, parede) end
	end

	local nucleo = molde("Sphere", {
		Size = Vector3.new(1.4, 1.4, 1.4) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_FALHA,
		Transparency = 0.35,
	})
	if nucleo then
		registrar(nucleo, (d and d.duracao) or 4)
		if reg then table.insert(reg, nucleo) end
	end
	camadaFaiscas(p, 0.6 * e, 12)
end

--- A prisão estilhaçando.
function Efeitos.PRISAO_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 5 * e)
	camadaCacos(p, 1.4 * e, 14)
	camadaFaiscas(p, 1 * e, 22)
end

--- A entidade: núcleo `Sphere` com o disco `E` girando em volta. Some por
--- `Parar` — ela vive enquanto a habilidade durar.
function Efeitos.ENTIDADE(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)

	local corpo = molde("Sphere", {
		Size = Vector3.new(1, 1, 1) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.05,
	})
	if not corpo then
		corpo = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 4, 4) * e,
			Color = CFG.COR_VAZIO,
			Transparency = 0.1,
			CFrame = CFrame.new(p),
		})
	end
	tween(corpo, 0.3, { Size = Vector3.new(5, 5, 5) * e }, Enum.EasingStyle.Back)
	registrar(corpo, (d and d.duracao) or 10)
	if reg then table.insert(reg, corpo) end

	local halo = molde("E", {
		Size = Vector3.new(9, 0.5, 9) * e,
		CFrame = CFrame.new(p),
		Color = CFG.COR_FALHA,
		Transparency = 0.25,
	})
	if halo then
		tween(halo, (d and d.duracao) or 10, {
			CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(1440), 0),
		}, Enum.EasingStyle.Linear)
		registrar(halo, (d and d.duracao) or 10)
		if reg then table.insert(reg, halo) end
	end
	camadaFaiscas(p, 0.7 * e, 14)
end

--- O poço. `Ring` deitado, e o funil `Spiral` puxando para baixo.
function Efeitos.POCO(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local raio = (d and d.raio) or 22

	local boca = molde("Ring", {
		Size = Vector3.new(4, 1, 4),
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.1,
	})
	if boca then
		tween(boca, 0.5, { Size = Vector3.new(raio * 2, 1.4, raio * 2) },
			Enum.EasingStyle.Back)
		registrar(boca, (d and d.duracao) or 6)
		if reg then table.insert(reg, boca) end
	end

	local funil = molde("Spiral", {
		Size = Vector3.new(raio, raio * 0.6, raio) ,
		CFrame = CFrame.new(p - Vector3.new(0, raio * 0.3, 0)),
		Color = CFG.COR_FALHA,
		Transparency = 0.45,
	})
	if funil then
		tween(funil, (d and d.duracao) or 6, {
			CFrame = CFrame.new(p - Vector3.new(0, raio * 0.3, 0))
				* CFrame.Angles(0, math.rad(2160), 0),
		}, Enum.EasingStyle.Linear)
		registrar(funil, (d and d.duracao) or 6)
		if reg then table.insert(reg, funil) end
	end

	-- motes que DESCEM: é a direção que diz "poço" e não "torre"
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p + Vector3.new(0, 10 * e, 0)) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(CFG.COR_BORDA, CFG.COR_FALHA)
	em.LightEmission = 0.9
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6 * e),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.8, 1.4)
	em.Speed = NumberRange.new(14, 26)
	em.SpreadAngle = Vector2.new(48, 48)
	em.Acceleration = Vector3.new(0, -28, 0)
	em.EmissionDirection = Enum.NormalId.Bottom
	em.Enabled = false
	em.Parent = att
	em:Emit(28)
	registrar(ancora, 2.4)
end

--- O feixe preto-e-branco. É a assinatura do original.
function Efeitos.FEIXE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	camadaFeixe(origem, destino, (d and d.grossura) or 1.4, 0.24)
	camadaFlash(destino, CFG.COR_VAZIO, 2.6 * escala(d))
	camadaCacos(destino, 0.6 * escala(d), 4)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Faker] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
