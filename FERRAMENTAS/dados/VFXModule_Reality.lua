-- VFXModule_Reality_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto REALITY GUI
--
-- ONDE RODA: CLIENTE, EM TODOS ELES.
--
--   O servidor transmite por `VFXRemote:FireAllClients` e o `Client` é `Script`
--   com `RunContext = Client`, que roda em TODO cliente. Quem desenha é quem
--   vê — e todos veem.
--
-- OS MOLDES DESTE CONJUNTO, E O QUE CADA TOOL REALMENTE TRAZ
--
--   | Tool | `Tool/Moldes/` | classe |
--   |---|---|---|
--   | `Lapada Seca` | `Hand` | `MeshPart` |
--   | `Arvore Maligna` | `tree` | **`Model`** — 5 `UnionOperation` |
--   | `Gato Ajudante Boss` | `Gravity Cat Not Amused` | **`Model`** |
--   | as outras quatro | — | desenham só com primitiva |
--
--   `molde(nome)` devolve `nil` para tudo que a Tool não trouxer, e cada efeito
--   cai no seu desenho primitivo. É de propósito: a Regra nº 1 diz que a Tool
--   sozinha num place vazio funciona por inteiro, e uma Tool que ficasse muda
--   por não achar um molde estaria dependendo de coisa de fora.
--
--   ⚠️ DOIS DOS TRÊS SÃO `Model`. Ver o comentário de `molde()`: `Model` não
--      tem `Anchored`, `Transparency` nem `CFrame`, e a versão anterior
--      escrevia os três. O `pcall` do `VFX.Executar` engolia o erro, e o gato
--      nunca aparecia.
--
-- EMISSOR AUTORADO SE LIGA POR `Enabled` + `Rate`, NUNCA POR `:Emit()`
--
--   `:Emit(n)` dispara uma leva fixa e IGNORA o `Rate` que o autor escreveu —
--   a curva de emissão se perde e o efeito fica com outra cara. É a regra que
--   o `_INDICE.md` fixou para os 10 emissores do Acervo, e vale aqui para todo
--   `ParticleEmitter` que vier dentro de um molde.
--
--   O molde fica com `Enabled = false` dentro da Tool. Quem acende é o clone.
--
-- Zero math.random: a origem tinha 21. Aqui é ângulo áureo e jitter senoidal
-- por contador — com todos os clientes desenhando, um sorteio faria cada um ver
-- uma cena diferente, o que lê como lag.
--
-- Gerado por FERRAMENTAS/gerar_servers_reality.py.
--
-- ⛔ Nenhuma linha veio do `reality_tools.rbxmx`. Aquele arquivo está em
--    quarentena por causa do backdoor; o que este conjunto usa dele é
--    geometria, som e KeyframeSequence — dado, nunca código.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_VAZIO    = Color3.fromRGB(196, 42, 58),
	COR_BORDA    = Color3.fromRGB(255, 236, 190),
	COR_BRASA    = Color3.fromRGB(255, 176, 48),
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

local function assentar(peca)
	peca.Anchored = true
	peca.CanCollide = false
	peca.CanTouch = false
	peca.CanQuery = false
	peca.Massless = true
	peca.CastShadow = false
end

--- Clona um molde e o torna visível. `nil` se a Tool não trouxer aquele.
---
--- ⚠️ MOLDE PODE SER `Model`, E ISSO NÃO É DETALHE.
---
---     Dois dos três moldes deste conjunto são `Model`: a `tree` da
---     `Arvore Maligna` (5 `UnionOperation`) e o corpo do gato. `Model` não tem
---     `Anchored`, não tem `Transparency` e não tem `CFrame` — escrever
---     qualquer um dos três nele **lança**, e o `pcall` do `VFX.Executar`
---     engolia o erro em silêncio. O resultado era um `warn` no console e
---     nenhum gato na tela.
---
---     Num `Model`, quem recebe as propriedades são as `BasePart` de dentro, e
---     quem posiciona é `PivotTo`. E as propriedades de APARÊNCIA (`Color`,
---     `Material`, `Transparency`) são ignoradas de propósito: pintar a árvore
---     inteira de uma cor só apagaria o modelo que se quis usar.
local function molde(nome, props, visivel)
	local pasta = moldes()
	local base = pasta and pasta:FindFirstChild(nome)
	if not base then return nil end
	local copia = base:Clone()

	if copia:IsA("Model") then
		for _, parte in ipairs(copia:GetDescendants()) do
			if parte:IsA("BasePart") then
				assentar(parte)
				if visivel == false then parte.Transparency = 1 end
			end
		end
		copia.Parent = workspace
		if props and props.CFrame then
			copia:PivotTo(props.CFrame)
		end
		return copia
	end

	assentar(copia)
	if visivel ~= false then copia.Transparency = 0 end
	for chave, valor in pairs(props or {}) do
		copia[chave] = valor
	end
	copia.Parent = workspace
	return copia
end

--- Leva uma peça OU um `Model` até um `CFrame`, com tween.
---
--- `TweenService` não anima `Model`: ela não tem a propriedade. O jeito é
--- tweenar um `CFrameValue` e repicar o `PivotTo` no `Changed` — uma alocação
--- por movimento, contra um `PivotTo` por quadro escrito à mão.
local function levar(inst, destino, tempo, estilo)
	if not (inst and inst.Parent) then return end
	if inst:IsA("BasePart") then
		tween(inst, tempo, { CFrame = destino },
			estilo or Enum.EasingStyle.Linear)
		return
	end
	if not inst:IsA("Model") then return end

	local proxy = Instance.new("CFrameValue")
	proxy.Value = inst:GetPivot()
	local conexao
	conexao = proxy.Changed:Connect(function(valor)
		if inst and inst.Parent then
			inst:PivotTo(valor)
		end
	end)
	local t = tween(proxy, tempo, { Value = destino },
		estilo or Enum.EasingStyle.Linear)
	t.Completed:Connect(function()
		if conexao then conexao:Disconnect() end
		proxy.Parent = nil
	end)
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

--- A ÁRVORE que caça. Some por `Parar`, e ANDA por `MOVER`.
---
--- O molde certo é a `tree` da origem — o `Model` com as 5 `UnionOperation`.
--- A versão anterior pedia `VoidCrystal`, que esta Tool não traz: `molde`
--- devolvia `nil`, o fallback desenhava uma bola roxa, e o modelo que se tinha
--- carregado para dentro da Tool nunca aparecia.
function Efeitos.BURACO(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local vida = (d and d.duracao) or 4

	local nucleo = molde("tree", { CFrame = CFrame.new(p) })
	if not nucleo then
		nucleo = molde("VoidCrystal", {
			CFrame = CFrame.new(p),
			Color = CFG.COR_VAZIO,
			Transparency = 0.05,
		})
	end
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
	if nucleo:IsA("BasePart") then
		tween(nucleo, vida, {
			CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(1080), 0),
		}, Enum.EasingStyle.Linear)
	end
	registrar(nucleo, vida)
	if reg then table.insert(reg, nucleo) end

	sopro("VoidMagic", p, vida, 1.2)
end

--- MOVER — o servidor mandou a coisa registrada mudar de lugar.
---
--- É como a árvore anda. O passo vem por TIQUE de 0.35 s, nunca por quadro: o
--- servidor manda a posição nova e o cliente faz o meio do caminho com tween.
--- Uma mensagem a cada 0.35 s no lugar de trinta por segundo.
function Efeitos.MOVER(d)
	local reg = d and d.id and PorId[d.id]
	if not reg then return end
	local destino = pos(d)
	local tempo = (d and d.tempo) or 0.35
	local olhar = d and d.olhar

	local alvo = CFrame.new(destino)
	if olhar then
		local plano = Vector3.new(olhar.X, destino.Y, olhar.Z)
		if (plano - destino).Magnitude > 0.1 then
			alvo = CFrame.lookAt(destino, plano)
		end
	end

	for _, inst in ipairs(reg.partes) do
		levar(inst, alvo, tempo)
	end
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

--- Impacto de golpe: clarão, cacos e faíscas no ponto de contato.
function Efeitos.IMPACTO(d)
	local p, e = pos(d), escala(d)
	camadaFlash(p, CFG.COR_VAZIO, 2.4 * e)
	camadaCristais(p, "MiniVoidCrystal", 4, 1.6 * e, 0.6 * e, 0.5)
end

--- A entidade invocada: o gato do `Gato Ajudante Boss`.
---
--- O molde é o corpo dele, que entrou como GEOMETRIA — sem `Humanoid`, sem
--- `Motor6D`. Some por `VFX.Parar`; quem manda é a Tool.
function Efeitos.ENTIDADE(d)
	local p, e = pos(d), escala(d)
	local reg = registroDe(d)
	local vida = (d and d.duracao) or 10

	-- ele SOBE ao ser chamado, como na origem (12 passos de 1 stud). Nasce
	-- embaixo e é levado para o ponto.
	local baixo = p - Vector3.new(0, 6, 0)

	local corpo = molde("Gravity Cat Not Amused", { CFrame = CFrame.new(baixo) })
	if not corpo then
		corpo = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3.4, 3.4, 3.4) * e,
			Color = CFG.COR_VAZIO,
			Transparency = 0.1,
			CFrame = CFrame.new(baixo),
		})
	end
	levar(corpo, CFrame.new(p), 0.6, Enum.EasingStyle.Back)
	registrar(corpo, vida)
	if reg then table.insert(reg, corpo) end

	sopro("VoidMagic", p, vida, 1)
	camadaFlash(p, CFG.COR_BORDA, 3 * e)
end

--- A BOMBA do gato: a bola preta que espera antes de estourar.
---
--- `attack1` da origem — `Part` bola cor 0.192157 (RGB 49), som, 0.8 s, e só
--- então a `Explosion`. A espera é a mecânica: dá para sair de baixo. O anel
--- que cresce é a leitura do raio, para saber DE ONDE sair.
function Efeitos.BOMBA(d)
	local p, e = pos(d), escala(d)
	local espera = (d and d.espera) or 0.8
	local raio = (d and d.raio) or 7

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(49, 49, 49),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0,
		CFrame = CFrame.new(p + Vector3.new(0, raio * 0.5, 0)),
	})
	tween(bola, espera, {
		Size = Vector3.new(3.4, 3.4, 3.4) * e,
		CFrame = CFrame.new(p),
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(bola, espera + 0.05)

	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 1, 1),
		Color = CFG.COR_BRASA,
		Transparency = 0.55,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, espera, {
		Size = Vector3.new(0.2, raio * 2, raio * 2),
		Transparency = 0.9,
	}, Enum.EasingStyle.Linear)
	registrar(anel, espera + 0.05)

	sopro("VoidMagic", p, espera, 0.8)
end

--- A RADIAÇÃO do canhão: a cratera que continua queimando.
---
--- O LOIC solta 29 esferas `Neon` e 100 esferas `Glass` expandindo pelos ~12 s
--- que seguem o tiro. Não é decoração: é o que faz o ponto ficar intransitável
--- depois do feixe, e o servidor cobra por tique enquanto ela está de pé.
---
--- As levas são agendadas de uma vez, e cada uma desiste se o domo já foi
--- apagado por `Parar` — assim a Tool guardada leva a radiação junto.
function Efeitos.RADIACAO(d)
	local p = pos(d)
	local raio = (d and d.raio) or 26
	local duracao = (d and d.duracao) or 10
	local reg = registroDe(d)

	local domo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.4,
		Color = CFG.COR_BRASA,
		Material = Enum.Material.Glass,
		Transparency = 0.78,
		CFrame = CFrame.new(p),
	})
	tween(domo, 1.2, {
		Size = Vector3.new(raio, raio, raio) * 2,
		Transparency = 0.88,
	}, Enum.EasingStyle.Quint)
	registrar(domo, duracao)
	if reg then table.insert(reg, domo) end

	local levas = math.max(1, math.floor(duracao / 0.8))
	for i = 1, levas do
		task.delay(i * 0.8, function()
			if not (domo and domo.Parent) then return end
			local onda = novaParte({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2, 2, 2),
				Color = CFG.COR_BRASA,
				Transparency = 0.45,
				CFrame = CFrame.new(p),
			})
			tween(onda, 1.4, {
				Size = Vector3.new(raio, raio, raio) * 2,
				Transparency = 1,
			}, Enum.EasingStyle.Quad)
			registrar(onda, 1.6)
		end)
	end

	sopro("VoidExplode2", p, duracao, 0.7)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Reality] falha em " .. tostring(tipo) .. ": " .. tostring(err))
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
