-- VFXModule_Noob_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto NOOB
--
-- ONDE RODA: CLIENTE, EM TODOS ELES.
--
--   O servidor transmite por `VFXRemote:FireAllClients` e o `Client` é `Script`
--   com `RunContext = Client`, que roda em TODO cliente. Quem desenha é quem
--   vê — e todos veem.
--
-- ESTE CONJUNTO TEM EMISSOR DE VERDADE, E ISSO MUDA A REGRA
--
--   Os outros `VFXModule` daqui desenham com `Part` primitiva esticada, e o
--   FAKER com malha de modelo. Este é o primeiro com **`ParticleEmitter`
--   autorado**: 13 deles, em 9 moldes, vindos do `noob_despertado.rbxmx`.
--
--   Emissor autorado se liga por **`Enabled` + `Rate`**, nunca por `:Emit()`.
--   `:Emit(n)` dispara uma leva fixa e IGNORA o `Rate` que o autor escreveu —
--   a curva de emissão se perde e o efeito fica com outra cara. É a regra que
--   o `_INDICE.md` fixou para os 10 emissores do Acervo, e vale igual aqui.
--
--   O molde fica com `Enabled = false` dentro da Tool. Quem acende é o clone.
--
-- OS MOLDES
--
--     VoidCrystal        cristal 2.2 × 14.9 × 2.2   o pilar
--     SmallVoidCrystal   1.34 × 9.1 × 1.34          o médio
--     MiniVoidCrystal    0.4 × 2.7 × 0.4            o estilhaço
--     VoidMagic          Attachment · 2 emissores   conjuração
--     VoidExplode        Attachment · 2 emissores   estouro
--     VoidExplode2       Attachment · 2 emissores   estouro grande
--     Stun               Attachment · 1 emissor     atordoamento
--     Bomb               13.7³                       a lua
--     Lava               900 × 20 × 900 -> 24        a laje
--
--   Os três cristais são o MESMO molde em três tamanhos. É escala pronta — o
--   tipo de coisa que este repositório vinha resolvendo com `Size` no tween.
--
--   A `Lava` da origem tem 900 studs de lado, o mesmo 900 do
--   `ApplyAoE(..., 900, ...)`: a peça É o raio. Ela entrou cortada em 24, e o
--   raio de dano foi trazido para a faixa junto — os dois eram o mesmo número.
--
-- PALETA: ROXO DE VAZIO COM BORDA BRANCA
--
--   O FAKER é preto com contorno branco; este é roxo. Os dois são "vazio", e
--   precisam se distinguir de longe: o Faker é buraco, o Noob é nebulosa.
--
-- Zero math.random: a origem tinha 21. Aqui é ângulo áureo e jitter senoidal
-- por contador — com todos os clientes desenhando, um sorteio faria cada um ver
-- uma cena diferente, o que lê como lag.
--
-- Gerado por FERRAMENTAS/gerar_servers_noob.py.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_VAZIO    = Color3.fromRGB(64, 22, 112),
	COR_BORDA    = Color3.fromRGB(226, 210, 255),
	COR_BRASA    = Color3.fromRGB(255, 96, 64),
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
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
-- OS MOLDES — dentro da Tool, invisíveis e com o emissor DESLIGADO
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

--- Acende todo `ParticleEmitter` dentro de uma peça.
---
--- `Enabled = true` e o `Rate` do autor, nunca `:Emit()`. Quem quiser uma leva
--- curta desliga depois, por prazo — assim a curva continua sendo a dele.
local function acender(peca, fator)
	for _, filho in ipairs(peca:GetDescendants()) do
		if filho:IsA("ParticleEmitter") then
			filho.Enabled = true
			if fator and fator ~= 1 then
				filho.Rate = filho.Rate * fator
			end
		end
	end
end

local function apagar(peca)
	if not peca then return end
	for _, filho in ipairs(peca:GetDescendants()) do
		if filho:IsA("ParticleEmitter") then filho.Enabled = false end
	end
end

--- Clona um molde e o torna visível. `nil` se a Tool não trouxer aquele.
local function molde(nome, props, visivel)
	local pasta = moldes()
	local base = pasta and pasta:FindFirstChild(nome)
	if not base then return nil end
	local copia = base:Clone()
	copia.Anchored = true
	copia.CanCollide = false
	copia.CanTouch = false
	copia.CanQuery = false
	if visivel ~= false then copia.Transparency = 0 end
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	copia.Parent = workspace
	return copia
end

--- Solta um sopro de emissor no ponto, com prazo.
---
--- A peça-âncora é invisível de propósito: o que aparece é a partícula, e o
--- `Attachment` de origem vem dentro dela.
local function sopro(nome, posicao, duracao, fator)
	local peca = molde(nome, {
		CFrame = CFrame.new(posicao),
		Transparency = 1,
	}, false)
	if not peca then return nil end
	acender(peca, fator)
	task.delay(duracao or 0.5, function()
		apagar(peca)
	end)
	registrar(peca, (duracao or 0.5) + 2.5)
	return peca
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

local function camadaFlash(p, cor, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.5,
		Color = cor,
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = CFG.COR_BORDA, 7, raio * 4
	luz.Parent = bola
	tween(bola, 0.07, { Size = Vector3.new(raio, raio, raio) * 1.6,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.26)
end

--- Os cristais em anel. Usa o molde de verdade quando a Tool o traz.
local function camadaCristais(p, qual, quantos, raio, escala, vida)
	for i = 1, (quantos or 6) do
		local a = angulo(i)
		local onde = p + Vector3.new(math.cos(a), 0, math.sin(a)) * raio
		local peca = molde(qual, {
			CFrame = CFrame.new(onde) * CFrame.Angles(0, a, math.rad(jitter(i) * 12)),
			Color = CFG.COR_VAZIO,
			Transparency = 0.1,
		})
		if not peca then
			peca = novaParte({
				Size = Vector3.new(0.6, 3.2, 0.6) * escala,
				Color = CFG.COR_VAZIO,
				Transparency = 0.15,
				CFrame = CFrame.new(onde) * CFrame.Angles(0, a, 0),
			})
		else
			peca.Size = peca.Size * escala
		end
		local borda = Instance.new("SelectionBox")
		borda.Adornee = peca
		borda.Color3 = CFG.COR_BORDA
		borda.LineThickness = 0.03
		borda.Transparency = 0.2
		borda.Parent = peca
		acender(peca)
		tween(peca, vida or 0.8, { Transparency = 1,
			CFrame = peca.CFrame * CFrame.new(0, 2.4 * escala, 0) },
			Enum.EasingStyle.Quint)
		registrar(peca, (vida or 0.8) + 0.3)
	end
end

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
		Size = Vector3.new(grossura * 0.4, grossura * 0.4, delta.Magnitude),
		Color = CFG.COR_BORDA,
		Transparency = 0,
		CFrame = meio,
	})
	tween(corpo, tempo or 0.22, { Transparency = 1,
		Size = Vector3.new(grossura * 2.2, grossura * 2.2, delta.Magnitude) })
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

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id].partes
end

--- O feixe do `Shot`, que na origem BANIA o alvo.
function Efeitos.FEIXE(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	camadaFeixe(origem, destino, (d and d.grossura) or 1.2, 0.22)
	sopro("VoidExplode", destino, 0.25, 1)
	camadaFlash(destino, CFG.COR_VAZIO, 2.4 * escala(d))
end

--- O disparo pesado: o feixe grosso do `BlastShoot`.
function Efeitos.DISPARO(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	camadaFeixe(origem, destino, (d and d.grossura) or 3.4, 0.34)
	sopro("VoidExplode", destino, 0.5, 1.6)
	camadaFlash(destino, CFG.COR_BORDA, 6 * escala(d))
	camadaCristais(destino, "MiniVoidCrystal", 6, 3.4 * escala(d),
		escala(d), 0.7)
end

--- A conjuração: o sopro de `VoidMagic` na mão.
function Efeitos.CONJURA(d)
	sopro("VoidMagic", pos(d), (d and d.duracao) or 0.6, 1)
	camadaFlash(pos(d), CFG.COR_VAZIO, 1.8 * escala(d))
end

--- A laje de lava subindo. A peça de origem tem 900 studs de lado; entrou
--- cortada em 24, e o raio de dano veio junto — eram o mesmo número.
function Efeitos.LAVA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 26
	local reg = registroDe(d)

	local laje = molde("Lava", {
		CFrame = CFrame.new(p - Vector3.new(0, 12, 0)),
		Color = CFG.COR_BRASA,
		Material = Enum.Material.Neon,
		Transparency = 1,
	})
	if laje then
		laje.Size = Vector3.new(raio * 2, 2, raio * 2)
		tween(laje, 0.9, { CFrame = CFrame.new(p - Vector3.new(0, 1.2, 0)),
			Transparency = 0.15 }, Enum.EasingStyle.Quint)
		registrar(laje, (d and d.duracao) or 5)
		if reg then table.insert(reg, laje) end
	end

	sopro("VoidExplode2", p, 1.2, 1.4)
	camadaFlash(p, CFG.COR_BRASA, 10 * e)
end

function Efeitos.LAVA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BRASA, 14 * e)
	sopro("VoidExplode2", p, 0.8, 2)
	camadaCristais(p, "MiniVoidCrystal", 10, 8 * e, 1.4 * e, 1)
end

--- A parada do tempo: o atordoamento por cima de cada alvo.
function Efeitos.PARAR(d)
	local p, e = pos(d), escala(d)
	sopro("Stun", p + Vector3.new(0, 3, 0), (d and d.duracao) or 2.5, 1)
	camadaFlash(p, CFG.COR_BORDA, 3 * e)
end

--- O relógio que estoura.
function Efeitos.RELOGIO(d)
	local p, e = pos(d), escala(d)
	local anel = molde("Bomb", {
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.2,
	})
	if anel then
		anel.Size = Vector3.new(2, 2, 2) * e
		tween(anel, 0.5, { Size = Vector3.new(9, 9, 9) * e, Transparency = 1 },
			Enum.EasingStyle.Quint)
		registrar(anel, 0.8)
	end
	sopro("VoidMagic", p, 0.5, 1.3)
	camadaFlash(p, CFG.COR_BORDA, 5 * e)
	camadaCristais(p, "MiniVoidCrystal", 8, 4 * e, e, 0.8)
end

--- O buraco: o pilar de cristal com o sopro em volta. Some por `Parar`.
function Efeitos.BURACO(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)

	local nucleo = molde("VoidCrystal", {
		CFrame = CFrame.new(p),
		Color = CFG.COR_VAZIO,
		Transparency = 0.05,
	})
	if not nucleo then
		nucleo = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 4, 4) * e,
			Color = CFG.COR_VAZIO,
			Transparency = 0.1,
			CFrame = CFrame.new(p),
		})
	end
	acender(nucleo)
	tween(nucleo, (d and d.duracao) or 4, {
		CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(1080), 0),
	}, Enum.EasingStyle.Linear)
	registrar(nucleo, (d and d.duracao) or 4)
	if reg then table.insert(reg, nucleo) end

	sopro("VoidMagic", p, (d and d.duracao) or 4, 1.2)
end

function Efeitos.BURACO_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 9 * e)
	sopro("VoidExplode2", p, 0.7, 1.8)
	camadaCristais(p, "SmallVoidCrystal", 8, 5 * e, e, 0.9)
end

--- O colar: o atordoamento na altura do pescoço, e o dreno.
function Efeitos.COLAR(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)

	local elo = molde("MiniVoidCrystal", {
		CFrame = CFrame.new(p + Vector3.new(0, 1.4, 0)),
		Color = CFG.COR_VAZIO,
		Transparency = 0.1,
	})
	if elo then
		acender(elo)
		tween(elo, (d and d.duracao) or 2.5, {
			CFrame = CFrame.new(p + Vector3.new(0, 1.4, 0))
				* CFrame.Angles(0, math.rad(720), 0),
		}, Enum.EasingStyle.Linear)
		registrar(elo, (d and d.duracao) or 2.5)
		if reg then table.insert(reg, elo) end
	end
	sopro("Stun", p + Vector3.new(0, 2.4, 0), (d and d.duracao) or 2.5, 1)
end

function Efeitos.DRENO(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	camadaFeixe(origem, destino, 0.7, 0.3)
	sopro("VoidExplode", origem, 0.3, 1)
end

--- A lua: a bomba caindo do céu.
function Efeitos.LUA(d)
	local p, e = pos(d), escala(d)
	local alto = p + Vector3.new(0, (d and d.altura) or 70, 0)

	local lua = molde("Bomb", {
		CFrame = CFrame.new(alto),
		Color = CFG.COR_BORDA,
		Transparency = 0.1,
	})
	if not lua then
		lua = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(12, 12, 12) * e,
			Color = CFG.COR_BORDA,
			Transparency = 0.1,
			CFrame = CFrame.new(alto),
		})
	end
	lua.Size = lua.Size * e
	acender(lua)
	tween(lua, (d and d.queda) or 0.55, { CFrame = CFrame.new(p) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	registrar(lua, ((d and d.queda) or 0.55) + 0.35)

	task.delay((d and d.queda) or 0.55, function()
		if lua and lua.Parent then
			apagar(lua)
			lua.Parent = nil
		end
	end)
end

function Efeitos.LUA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 12 * e)
	sopro("VoidExplode", p, 0.8, 1.8)
	camadaCristais(p, "MiniVoidCrystal", 10, 6 * e, 1.2 * e, 0.9)
end

--- A coroa que desce sobre o portador.
function Efeitos.COROA(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)

	local pilar = molde("VoidCrystal", {
		CFrame = CFrame.new(p + Vector3.new(0, 8, 0)),
		Color = CFG.COR_VAZIO,
		Transparency = 0.25,
	})
	if pilar then
		acender(pilar)
		tween(pilar, (d and d.duracao) or 3, {
			CFrame = CFrame.new(p + Vector3.new(0, 8, 0))
				* CFrame.Angles(0, math.rad(540), 0),
		}, Enum.EasingStyle.Linear)
		registrar(pilar, (d and d.duracao) or 3)
		if reg then table.insert(reg, pilar) end
	end

	camadaCristais(p, "SmallVoidCrystal", 6, 5 * e, e, (d and d.duracao) or 3)
	sopro("VoidMagic", p, (d and d.duracao) or 3, 1.4)
end

function Efeitos.COROA_FIM(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_BORDA, 16 * e)
	sopro("VoidExplode2", p, 1, 2.2)
	camadaCristais(p, "VoidCrystal", 8, 9 * e, e, 1.2)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Noob] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
			apagar(inst)
			inst.Parent = nil
		end
	end
	PorId[id] = nil
end

function VFX.LimparTudo()
	for id in pairs(PorId) do VFX.Parar(id) end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then
			apagar(inst)
			inst.Parent = nil
		end
	end
	table.clear(Vivos)
end

return VFX
