-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto CRIAÇÃO
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: O ANDAIME VEM PRIMEIRO, E A POEIRA VEM DEPOIS
--═══════════════════════════════════════════════════════════════
--
--   Este é o primeiro conjunto do repositório cujo verbo é CRIAR, e isso
--   impõe uma regra visual que nenhum outro precisou:
--
--     Coisa que aparece pronta lê como BUG. Coisa que se desenha lê como
--     construída.
--
--   Uma muralha que simplesmente existe no quadro seguinte é indistinguível
--   de um erro de replicação — o jogador não sabe se aquilo veio de uma
--   habilidade ou se o servidor engasgou. O que separa uma coisa da outra são
--   três tempos, e eles são o conjunto inteiro:
--
--     1. o ANDAIME, em 0.18 s — a silhueta em fio, antes de haver matéria
--     2. a MATÉRIA, em 0.35 s — ela preenche de baixo para cima
--     3. o PÓ, em 0.9 s — o que sobra da coisa que subiu
--
--   E no fim, quando o prazo vence, o `RECOLHER`: a peça volta a ser andaime
--   e some. É o simétrico exato do nascimento, e é o que faz o jogador
--   entender que aquilo era temporário — em vez de achar que sumiu por bug.
--
--   As camadas:
--
--     `camadaAndaime`      a silhueta em fio, aresta por aresta
--     `camadaMaterializa`  o preenchimento de baixo para cima
--     `camadaPo`           a poeira do que subiu
--     `camadaFaisca`       as fagulhas do martelo
--     `camadaBroto`        os talos que rasgam o chão
--     `camadaTraco`        o risco de projeto, azul e reto
--     `camadaRecolher`     o desmanche — o nascimento ao contrário
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `math.random` — ângulo áureo, para que todos os clientes desenhem a
--   MESMA construção. Numa Tool que cria coisa com que se COLIDE, isso deixa
--   de ser preferência: se cada cliente desenhasse o andaime num lugar, o
--   jogador miraria onde a peça não está.
--
--   Zero `:Destroy()` — `Parent = nil` e `Debris`. Zero `tick()`. Zero
--   `ScreenGui`, `ColorCorrection` e `Sky`.

local Debris       = game:GetService("Debris")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Deposito = require(script.Parent:WaitForChild("DepositoVFX"))

local VFX = {}

--═══════════════════════════════════════════════════════════════
-- CFG
--═══════════════════════════════════════════════════════════════

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	LIMITE_VIVOS = 260,

	FERRO     = Color3.fromRGB(96, 100, 110),
	BRASA     = Color3.fromRGB(255, 138, 46),
	PEDRA     = Color3.fromRGB(150, 146, 138),
	TIJOLO    = Color3.fromRGB(168, 88, 66),
	VERDE     = Color3.fromRGB(96, 168, 84),
	SEIVA     = Color3.fromRGB(180, 220, 120),
	TINTA     = Color3.fromRGB(64, 120, 208),
	PAPEL     = Color3.fromRGB(232, 236, 242),
	LUZ       = Color3.fromRGB(255, 244, 200),
	OURO      = Color3.fromRGB(255, 208, 96),
	TERRA     = Color3.fromRGB(122, 96, 68),

	--- os três tempos do nascimento
	T_ANDAIME     = 0.18,
	T_MATERIA     = 0.35,
	T_PO          = 0.9,

	TREMOR_FORCA = 0.4,
	TREMOR_TEMPO = 0.7,
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

local function registroDe(d)
	if not (d and d.id) then return nil end
	PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
	return PorId[d.id]
end

local function anotar(d, inst, conexao)
	local reg = registroDe(d)
	if not reg then return inst end
	if inst then table.insert(reg.partes, inst) end
	if conexao then table.insert(reg.conexoes, conexao) end
	return inst
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
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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

local function acima(p, quanto)
	return (p or Vector3.new()) + Vector3.new(0, quanto or 1.6, 0)
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function acharPack()
	if packProcurado then return raizPack end
	packProcurado = true
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

--- `pk` de nome que não existe no pack devolve false EM SILÊNCIO. Os dez nomes
--- reais são Floor_Crack, Laser_Shot, Shockwave, Shockwave_2,
--- Shockwave_Explosion, Small_Nova, Small_Slash, Smoky_Explosion, Sonar_Ring
--- e Spiral_Effect.
local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Criacao] pack " .. tostring(nome) .. ": "
			.. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA
--
-- `workspace.CurrentCamera` é singleton por cliente, e este módulo roda em
-- cliente. O tremor é multiplicação relativa e some sozinho — nada aqui
-- escreve `CameraType`.
--═══════════════════════════════════════════════════════════════

local tremorAtivo = nil

local function tremor(forca, duracao)
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
	if not workspace.CurrentCamera then return end

	local passado = 0
	tremorAtivo = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not workspace.CurrentCamera then
			if tremorAtivo then
				tremorAtivo:Disconnect()
				tremorAtivo = nil
			end
			return
		end
		local restante = 1 - (passado / duracao)
		local a = forca * restante
		-- ruído senoidal por acumulador de dt, nunca tick()
		local x = math.sin(passado * 61.3) * a
		local y = math.sin(passado * 47.7 + 1.3) * a
		local z = math.sin(passado * 53.1 + 2.6) * a * 0.4
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(
			math.rad(x), math.rad(y), math.rad(z))
	end)
end

--═══════════════════════════════════════════════════════════════
-- AS CAMADAS
--═══════════════════════════════════════════════════════════════

--- TEMPO 1: O ANDAIME — a silhueta em fio, antes de haver matéria.
---
--- Doze arestas de uma caixa, finas e acesas. É o que anuncia que ali VAI
--- haver coisa, e é o único momento em que o jogador ainda pode sair.
local function camadaAndaime(quadro, tamanho, cor, vida)
	local mx, my, mz = tamanho.X * 0.5, tamanho.Y * 0.5, tamanho.Z * 0.5
	local fio = 0.14

	-- (deslocamento, tamanho da aresta) — as 12 de uma caixa
	local arestas = {
		{ Vector3.new(0, my, mz), Vector3.new(tamanho.X, fio, fio) },
		{ Vector3.new(0, my, -mz), Vector3.new(tamanho.X, fio, fio) },
		{ Vector3.new(0, -my, mz), Vector3.new(tamanho.X, fio, fio) },
		{ Vector3.new(0, -my, -mz), Vector3.new(tamanho.X, fio, fio) },
		{ Vector3.new(mx, 0, mz), Vector3.new(fio, tamanho.Y, fio) },
		{ Vector3.new(mx, 0, -mz), Vector3.new(fio, tamanho.Y, fio) },
		{ Vector3.new(-mx, 0, mz), Vector3.new(fio, tamanho.Y, fio) },
		{ Vector3.new(-mx, 0, -mz), Vector3.new(fio, tamanho.Y, fio) },
		{ Vector3.new(mx, my, 0), Vector3.new(fio, fio, tamanho.Z) },
		{ Vector3.new(mx, -my, 0), Vector3.new(fio, fio, tamanho.Z) },
		{ Vector3.new(-mx, my, 0), Vector3.new(fio, fio, tamanho.Z) },
		{ Vector3.new(-mx, -my, 0), Vector3.new(fio, fio, tamanho.Z) },
	}

	for _, a in ipairs(arestas) do
		local aresta = novaParte({
			Size = a[2],
			Color = branco(cor, 0.6),
			Transparency = 0.1,
			CFrame = quadro * CFrame.new(a[1]),
		})
		registrar(aresta, (vida or CFG.T_ANDAIME) + 0.4)
		tween(aresta, vida or CFG.T_ANDAIME, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
end

--- TEMPO 2: A MATÉRIA — ela preenche DE BAIXO PARA CIMA.
---
--- A direção não é enfeite: coisa que se constrói sobe do chão. Preencher de
--- cima para baixo leria como algo caindo, que é o oposto do verbo.
local function camadaMaterializa(quadro, tamanho, cor, material, vida)
	local corpo = novaParte({
		Size = Vector3.new(tamanho.X, 0.1, tamanho.Z),
		Color = cor,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = 0.55,
		CFrame = quadro * CFrame.new(0, -tamanho.Y * 0.5, 0),
	})
	registrar(corpo, (vida or CFG.T_MATERIA) + 0.5)
	tween(corpo, vida or CFG.T_MATERIA, {
		Size = tamanho,
		Transparency = 0.15,
		CFrame = quadro,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return corpo
end

--- TEMPO 3: O PÓ — o que sobra da coisa que subiu.
local function camadaPo(p, cor, raio, quantidade, vida)
	local n = quantidade or 16
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.25 + (i / n) * 0.75)
		local onde = p + Vector3.new(math.cos(a) * alcance, 0.3,
			math.sin(a) * alcance)
		local lado = raio * (0.1 + math.abs(jitter(a)) * 0.14)
		local grao = novaParte({
			Size = Vector3.new(lado, lado, lado),
			Color = cor,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.35,
			CFrame = CFrame.new(onde),
		})
		registrar(grao, (vida or CFG.T_PO) + 0.3)
		tween(grao, vida or CFG.T_PO, {
			Transparency = 1,
			Size = Vector3.new(lado * 1.8, lado * 1.8, lado * 1.8),
			CFrame = CFrame.new(onde + Vector3.new(
				math.cos(a) * raio * 0.2,
				raio * (0.3 + math.abs(jitter(a + 1)) * 0.4),
				math.sin(a) * raio * 0.2)),
		}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end
end

--- AS FAGULHAS DO MARTELO. Curtas e para cima: fagulha de forja não voa longe.
local function camadaFaisca(p, cor, forca, quantidade, vida)
	local n = quantidade or 14
	for i = 1, n do
		local a = angulo(i)
		local direcao = Vector3.new(math.cos(a) * 0.6,
			0.7 + math.abs(jitter(a)) * 0.8, math.sin(a) * 0.6).Unit
		local lado = 0.12 + math.abs(jitter(a + 0.7)) * 0.16
		local faisca = novaParte({
			Size = Vector3.new(lado, lado, lado * 2),
			Color = branco(cor, 0.5),
			Transparency = 0.05,
			CFrame = CFrame.lookAt(p, p + direcao),
		})
		registrar(faisca, (vida or 0.45) + 0.2)
		tween(faisca, vida or 0.45, {
			Transparency = 1,
			CFrame = CFrame.lookAt(p + direcao * forca, p + direcao * forca * 2),
			Size = Vector3.new(lado * 0.3, lado * 0.3, lado * 0.6),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
end

--- OS TALOS que rasgam o chão. Eles CRESCEM: nascem baixos e sobem.
local function camadaBroto(p, raio, quantidade, cor, altura, vida)
	local n = quantidade or 12
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.2 + (i / n) * 0.8)
		local onde = p + Vector3.new(math.cos(a) * alcance, 0,
			math.sin(a) * alcance)
		local alto = altura * (0.5 + math.abs(jitter(a)) * 0.9)
		local talo = novaParte({
			Size = Vector3.new(0.3, 0.2, 0.3),
			Color = (i % 3 == 0) and cor or CFG.VERDE,
			Material = Enum.Material.Grass,
			Transparency = 0.05,
			CFrame = CFrame.new(onde) * CFrame.Angles(
				math.rad(jitter(a) * 14), a, math.rad(jitter(a + 1) * 14)),
		})
		registrar(talo, (vida or 1.2) + 0.4)
		tween(talo, 0.3, {
			Size = Vector3.new(0.3, alto, 0.3),
			CFrame = CFrame.new(onde + Vector3.new(0, alto * 0.5, 0))
				* CFrame.Angles(math.rad(jitter(a) * 14), a,
					math.rad(jitter(a + 1) * 14)),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(talo, vida or 1.2, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
end

--- O RISCO DE PROJETO — azul, reto, e com as marcas de cota nas pontas.
local function camadaTraco(a, b, cor, vida)
	local delta = b - a
	local comprimento = delta.Magnitude
	if comprimento < 0.2 then return nil end

	local linha = novaParte({
		Size = Vector3.new(0.16, 0.16, comprimento),
		Color = cor or CFG.TINTA,
		Transparency = 0.1,
		CFrame = CFrame.lookAt(a + delta * 0.5, b),
	})
	registrar(linha, (vida or 0.5) + 0.3)
	tween(linha, vida or 0.5, { Transparency = 1 })

	-- as duas cotas: o que faz o risco ler como DESENHO e não como raio
	for _, ponta in ipairs({ a, b }) do
		local cota = novaParte({
			Size = Vector3.new(0.12, 1.4, 0.12),
			Color = branco(cor or CFG.TINTA, 0.5),
			Transparency = 0.2,
			CFrame = CFrame.lookAt(ponta, ponta + delta.Unit),
		})
		registrar(cota, (vida or 0.5) + 0.3)
		tween(cota, vida or 0.5, { Transparency = 1 })
	end
	return linha
end

--- O DESMANCHE — o nascimento ao contrário.
---
--- Sem ele o jogador vê a muralha sumir e não sabe se ela acabou ou se
--- quebrou. Com ele, ela volta a ser andaime e apaga — que é a única leitura
--- possível de "o prazo venceu".
local function camadaRecolher(quadro, tamanho, cor)
	camadaAndaime(quadro, tamanho, cor, 0.3)
	local casca = novaParte({
		Size = tamanho,
		Color = cor,
		Material = Enum.Material.ForceField,
		Transparency = 0.6,
		CFrame = quadro,
	})
	registrar(casca, 0.6)
	tween(casca, 0.3, {
		Transparency = 1,
		Size = Vector3.new(tamanho.X * 0.2, tamanho.Y * 0.2, tamanho.Z * 0.2),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
end

--═══════════════════════════════════════════════════════════════
-- O NASCIMENTO COMPLETO — os três tempos, na ordem
--
-- Esta é a função que quase todo efeito daqui chama. Ela existe para que a
-- ordem seja escrita UMA vez: espalhada por 21 habilidades, mais cedo ou mais
-- tarde uma nasceria sem andaime, e aquela Tool leria como bug.
--═══════════════════════════════════════════════════════════════

local function nascer(quadro, tamanho, cor, material, corPo)
	camadaAndaime(quadro, tamanho, cor, CFG.T_ANDAIME)
	task.delay(CFG.T_ANDAIME * 0.7, function()
		camadaMaterializa(quadro, tamanho, cor, material, CFG.T_MATERIA)
	end)
	task.delay(CFG.T_ANDAIME + CFG.T_MATERIA * 0.4, function()
		camadaPo(quadro.Position - Vector3.new(0, tamanho.Y * 0.5, 0),
			corPo or CFG.TERRA, math.max(tamanho.X, tamanho.Z) * 0.7, 14,
			CFG.T_PO)
	end)
end

--═══════════════════════════════════════════════════════════════
-- LEITURA DO PAYLOAD
--═══════════════════════════════════════════════════════════════

local function pos(d)
	return (d and typeof(d.posicao) == "Vector3") and d.posicao or Vector3.new()
end

local function dir(d)
	local v = d and d.direcao
	if typeof(v) ~= "Vector3" or v.Magnitude < 0.01 then
		return Vector3.new(0, 0, -1)
	end
	return v.Unit
end

local function quadroDe(d)
	if d and typeof(d.quadro) == "CFrame" then return d.quadro end
	return CFrame.new(pos(d))
end

local function tamanhoDe(d, padrao)
	return (d and typeof(d.tamanho) == "Vector3") and d.tamanho or padrao
end

local function raioDe(d, padrao)
	return (d and tonumber(d.raio)) or padrao
end

local function corDe(d, padrao)
	return (d and typeof(d.cor) == "Color3") and d.cor or padrao
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

--- O desmanche, comum às sete: o servidor manda quando o prazo vence.
function Efeitos.RECOLHER(d)
	camadaRecolher(quadroDe(d), tamanhoDe(d, Vector3.new(4, 4, 4)),
		corDe(d, CFG.PEDRA))
end

-- ── 1. FORJA ─────────────────────────────────────────────────────────────

function Efeitos.MARTELO(d)
	local p = acima(pos(d), 1.4)
	local c = corDe(d, CFG.BRASA)
	camadaFaisca(p, c, 6, 16, 0.45)
	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Color = branco(c, 0.7),
		Transparency = 0.2,
		CFrame = CFrame.new(p),
	})
	registrar(clarao, 0.3)
	tween(clarao, 0.14, { Transparency = 1, Size = Vector3.new(4, 4, 4) })
	pk("Shockwave_Explosion", p, 0.4, 2, raioDe(d, 8), c, branco(c, 0.6))
end

--- R: a bigorna cai. Ela NASCE no ar e desce — a queda é o dano.
function Efeitos.BIGORNA(d)
	local destino = pos(d)
	local alto = destino + Vector3.new(0, 26, 0)
	local tam = tamanhoDe(d, Vector3.new(5, 3.4, 3))
	local duracao = math.max((d and tonumber(d.duracao)) or 0.55, 0.1)

	camadaAndaime(CFrame.new(alto), tam, CFG.FERRO, CFG.T_ANDAIME)

	local bigorna = novaParte({
		Size = tam,
		Color = CFG.FERRO,
		Material = Enum.Material.Metal,
		Transparency = 0.1,
		CFrame = CFrame.new(alto),
	})
	anotar(d, bigorna)
	registrar(bigorna, duracao + 0.8)
	tween(bigorna, duracao, { CFrame = CFrame.new(destino
		+ Vector3.new(0, tam.Y * 0.5, 0)) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	task.delay(duracao, function()
		camadaPo(destino, CFG.TERRA, 12, 20, CFG.T_PO)
		camadaFaisca(acima(destino, 1), CFG.BRASA, 9, 18, 0.6)
		tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
		-- Floor_Crack(CF, Size, Lasting, Color)
		pk("Floor_Crack", CFrame.new(destino), raioDe(d, 14) * 0.5, 2.5,
			CFG.FERRO)
		if bigorna.Parent then
			tween(bigorna, 0.5, { Transparency = 1 })
		end
	end)
end

--- T: a placa temperada em volta de quem forjou.
function Efeitos.TEMPERA(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 6
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)

	local placa = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(7, 8, 7),
		Color = CFG.FERRO,
		Material = Enum.Material.ForceField,
		Transparency = 0.55,
		CFrame = CFrame.new(onde),
	})
	anotar(d, placa)
	registrar(placa, duracao + 0.6)

	camadaFaisca(onde, CFG.BRASA, 5, 12, 0.5)

	if not (peca and peca:IsA("BasePart")) then return end
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not (placa.Parent and peca.Parent) then
			laco:Disconnect()
			if placa.Parent then tween(placa, 0.3, { Transparency = 1 }) end
			return
		end
		placa.CFrame = peca.CFrame
		-- a placa esfria: o brilho da brasa some ao longo do prazo
		placa.Color = CFG.BRASA:Lerp(CFG.FERRO, passado / duracao)
	end)
	anotar(d, nil, laco)
end

-- ── 2. ALVENARIA ─────────────────────────────────────────────────────────

function Efeitos.TIJOLO(d)
	local p = acima(pos(d), 1.4)
	camadaPo(p, CFG.TIJOLO, raioDe(d, 6), 12, 0.7)
	camadaFaisca(p, CFG.TIJOLO, 5, 8, 0.4)
end

--- R: a muralha. O andaime desenha as três seções ANTES de haver pedra.
function Efeitos.MURALHA(d)
	local quadro = quadroDe(d)
	local tam = tamanhoDe(d, Vector3.new(18, 9, 1.6))
	local secoes = (d and tonumber(d.secoes)) or 3

	local largura = tam.X / secoes
	for i = 0, secoes - 1 do
		local desvio = -tam.X * 0.5 + largura * (i + 0.5)
		local q = quadro * CFrame.new(desvio, 0, 0)
		local t = Vector3.new(largura * 0.96, tam.Y, tam.Z)
		-- as seções nascem em SEQUÊNCIA, do centro para fora: muralha que
		-- nasce inteira de uma vez lê como teletransporte de cenário
		task.delay(i * 0.06, function()
			nascer(q, t, CFG.PEDRA, Enum.Material.Concrete, CFG.TERRA)
		end)
	end
	tremor(CFG.TREMOR_FORCA * 0.6, CFG.TREMOR_TEMPO * 0.6)
end

--- T: a torre que abre debaixo do alvo.
function Efeitos.TORRE(d)
	local base = pos(d)
	local altura = (d and tonumber(d.altura)) or 16
	local raio = raioDe(d, 4)
	local tam = Vector3.new(raio * 2, altura, raio * 2)
	local quadro = CFrame.new(base + Vector3.new(0, altura * 0.5, 0))

	nascer(quadro, tam, CFG.PEDRA, Enum.Material.Slate, CFG.TERRA)
	camadaPo(base, CFG.TERRA, raio * 3, 22, CFG.T_PO * 1.3)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
	pk("Floor_Crack", CFrame.new(base), raio * 3, 3, CFG.PEDRA)
end

-- ── 3. SEMENTE ───────────────────────────────────────────────────────────

function Efeitos.BROTO(d)
	local p = pos(d)
	camadaBroto(p, raioDe(d, 7), 14, CFG.SEIVA, 3.2, 1.0)
	camadaPo(p, CFG.TERRA, 5, 10, 0.7)
end

--- R: o cipó. Ele SOBE pelo alvo, não nasce em volta dele.
function Efeitos.CIPO(d)
	local peca = d and d.peca
	local duracao = (d and tonumber(d.duracao)) or 3
	local onde = (peca and peca:IsA("BasePart")) and peca.Position or pos(d)

	for i = 1, 6 do
		local a = angulo(i)
		local raio = 1.8
		local base = onde + Vector3.new(math.cos(a) * raio, -2.4,
			math.sin(a) * raio)
		local cipo = novaParte({
			Size = Vector3.new(0.4, 0.4, 0.4),
			Color = CFG.VERDE,
			Material = Enum.Material.Grass,
			Transparency = 0.05,
			CFrame = CFrame.new(base) * CFrame.Angles(0, a, 0),
		})
		anotar(d, cipo)
		registrar(cipo, duracao + 0.6)
		tween(cipo, 0.35, {
			Size = Vector3.new(0.4, 5.2, 0.4),
			CFrame = CFrame.new(base + Vector3.new(0, 2.6, 0))
				* CFrame.Angles(math.rad(jitter(a) * 12), a, 0),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(cipo, duracao, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end
	camadaBroto(onde - Vector3.new(0, 2.6, 0), 3, 8, CFG.SEIVA, 1.8, duracao)
end

--- T: a árvore. Tronco e copa, com o tronco subindo primeiro.
function Efeitos.ARVORE(d)
	local base = pos(d)
	local altura = (d and tonumber(d.altura)) or 22
	local raio = raioDe(d, 12)

	local tronco = Vector3.new(3.4, altura, 3.4)
	nascer(CFrame.new(base + Vector3.new(0, altura * 0.5, 0)), tronco,
		CFG.TERRA, Enum.Material.Wood, CFG.TERRA)

	-- a copa vem DEPOIS do tronco: árvore não cresce de cima
	task.delay(CFG.T_ANDAIME + CFG.T_MATERIA * 0.6, function()
		local copa = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2, 2, 2),
			Color = CFG.VERDE,
			Material = Enum.Material.Grass,
			Transparency = 0.1,
			CFrame = CFrame.new(base + Vector3.new(0, altura, 0)),
		})
		registrar(copa, 3.5)
		tween(copa, 0.5, {
			Size = Vector3.new(raio * 1.6, raio * 1.2, raio * 1.6),
		}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(copa, 3.0, { Transparency = 1 },
			Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	end)

	camadaBroto(base, raio, 20, CFG.SEIVA, 4, 2.0)
	camadaPo(base, CFG.TERRA, raio * 0.8, 22, CFG.T_PO * 1.4)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO * 1.2)
end

-- ── 4. PROJETO ───────────────────────────────────────────────────────────

function Efeitos.TRACO(d)
	local p = acima(pos(d), 2)
	local destino = (d and typeof(d.destino) == "Vector3") and d.destino
		or (p + dir(d) * raioDe(d, 22))
	camadaTraco(p, destino, CFG.TINTA, 0.45)
	camadaFaisca(destino, CFG.TINTA, 5, 8, 0.35)
end

--- R: o esboço. A zona desenhada em planta baixa, e ela DURA.
function Efeitos.ESBOCO(d)
	local centro = pos(d)
	local raio = raioDe(d, 22)
	local duracao = (d and tonumber(d.duracao)) or 8

	local chao = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.24, raio * 2, raio * 2),
		Color = CFG.TINTA,
		Transparency = 0.7,
		CFrame = CFrame.new(centro + Vector3.new(0, 0.28, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
	})
	anotar(d, chao)
	registrar(chao, duracao + 0.6)

	-- a grade da planta baixa: oito riscos cruzando o círculo
	for i = 0, 7 do
		local a = math.rad(i * 22.5)
		local ponta = centro + Vector3.new(math.cos(a) * raio, 0.3,
			math.sin(a) * raio)
		local outra = centro - Vector3.new(math.cos(a) * raio, -0.3,
			math.sin(a) * raio)
		camadaTraco(ponta, outra, CFG.TINTA, duracao * 0.5)
	end

	local passado, proximaGrade = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not chao.Parent then
			laco:Disconnect()
			if chao.Parent then tween(chao, 0.4, { Transparency = 1 }) end
			return
		end
		if passado < proximaGrade then return end
		proximaGrade = passado + 1.2
		local a = angulo()
		camadaTraco(centro + Vector3.new(math.cos(a) * raio, 0.3,
				math.sin(a) * raio),
			centro - Vector3.new(math.cos(a) * raio, -0.3, math.sin(a) * raio),
			CFG.TINTA, 1.1)
	end)
	anotar(d, nil, laco)
end

--- T: materializar. O que estava desenhado vira sólido.
function Efeitos.MATERIALIZAR(d)
	local centro = pos(d)
	local raio = raioDe(d, 22)

	-- seis blocos nascendo em volta, por ângulo áureo
	for i = 1, 6 do
		local a = angulo(i)
		local onde = centro + Vector3.new(math.cos(a) * raio * 0.6, 2.5,
			math.sin(a) * raio * 0.6)
		task.delay(i * 0.05, function()
			nascer(CFrame.new(onde), Vector3.new(3, 5, 3), CFG.PAPEL,
				Enum.Material.SmoothPlastic, CFG.TINTA)
		end)
	end

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = branco(CFG.TINTA, 0.6),
		Transparency = 0.15,
		CFrame = CFrame.new(acima(centro, 2)),
	})
	registrar(clarao, 0.8)
	tween(clarao, 0.45, { Transparency = 1,
		Size = Vector3.new(raio * 1.6, raio * 1.6, raio * 1.6) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tremor(CFG.TREMOR_FORCA * 0.9, CFG.TREMOR_TEMPO)
end

-- ── 5. PROTOTIPO ─────────────────────────────────────────────────────────

function Efeitos.PECA(d)
	local p = acima(pos(d), 1.5)
	camadaAndaime(CFrame.new(p), Vector3.new(2, 2, 2), CFG.PAPEL, 0.2)
	camadaPo(p, CFG.PAPEL, raioDe(d, 6), 10, 0.6)
end

--- R: o molde. Um boneco em fio que fica de pé no lugar.
function Efeitos.MOLDE(d)
	local quadro = quadroDe(d)
	local duracao = (d and tonumber(d.duracao)) or 6

	camadaAndaime(quadro * CFrame.new(0, 2.5, 0), Vector3.new(2.4, 5.4, 1.6),
		CFG.TINTA, 0.28)

	local corpo = novaParte({
		Size = Vector3.new(2, 5, 1),
		Color = CFG.PAPEL,
		Material = Enum.Material.ForceField,
		Transparency = 0.45,
		CFrame = quadro * CFrame.new(0, 2.5, 0),
	})
	anotar(d, corpo)
	registrar(corpo, duracao + 0.6)

	-- ele PISCA cada vez mais rápido: é o único aviso de que vai estourar
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not corpo.Parent then
			laco:Disconnect()
			return
		end
		local fracao = passado / duracao
		local hz = 2 + fracao * 9
		corpo.Transparency = (math.sin(passado * hz * math.pi * 2) > 0)
			and 0.35 or 0.7
	end)
	anotar(d, nil, laco)
end

--- T: a série. Três moldes estourando.
function Efeitos.SERIE(d)
	local p = acima(pos(d), 1.5)
	local raio = raioDe(d, 18)
	local c = CFG.TINTA

	camadaAndaime(CFrame.new(p), Vector3.new(raio, raio, raio), c, 0.24)
	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = branco(c, 0.7),
		Transparency = 0.1,
		CFrame = CFrame.new(p),
	})
	registrar(clarao, 0.7)
	tween(clarao, 0.35, { Transparency = 1,
		Size = Vector3.new(raio * 1.5, raio * 1.5, raio * 1.5) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	camadaPo(pos(d), CFG.PAPEL, raio * 0.6, 18, 0.9)
	pk("Smoky_Explosion", p, 0.7, raio * 0.4, c, CFG.PAPEL)
	tremor(CFG.TREMOR_FORCA * 0.8, CFG.TREMOR_TEMPO)
end

-- ── 6. GENESE ────────────────────────────────────────────────────────────

function Efeitos.FAISCA(d)
	local p = acima(pos(d), 2)
	local destino = (d and typeof(d.destino) == "Vector3") and d.destino
		or (p + dir(d) * raioDe(d, 16))
	camadaTraco(p, destino, CFG.LUZ, 0.35)
	camadaFaisca(destino, CFG.LUZ, 6, 12, 0.4)
end

--- R: a matéria condensa e estoura. Ela ENCOLHE antes de abrir.
function Efeitos.MATERIA(d)
	local p = acima(pos(d), 2)
	local raio = raioDe(d, 26)

	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 0.9, raio * 0.9, raio * 0.9),
		Color = CFG.LUZ,
		Transparency = 0.72,
		CFrame = CFrame.new(p),
	})
	registrar(bola, 1.2)
	-- encolhe primeiro: matéria que se condensa é o oposto de uma explosão, e
	-- é o encolher que faz o estouro seguinte ler como CRIAÇÃO
	tween(bola, 0.28, {
		Size = Vector3.new(1.2, 1.2, 1.2),
		Transparency = 0.05,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

	task.delay(0.28, function()
		tween(bola, 0.4, {
			Size = Vector3.new(raio * 1.4, raio * 1.4, raio * 1.4),
			Transparency = 1,
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		camadaFaisca(p, CFG.LUZ, raio * 0.4, 22, 0.7)
		camadaPo(pos(d), CFG.OURO, raio * 0.5, 16, 0.9)
		tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
		pk("Small_Nova", p, 0.7, 3, raio, CFG.LUZ, CFG.OURO)
	end)
end

--- T: o primeiro instante.
function Efeitos.PRIMEIRO(d)
	local p = acima(pos(d), 2)
	local raio = raioDe(d, 42)

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.5, 1.5, 1.5),
		Color = Color3.new(1, 1, 1),
		Transparency = 0.02,
		CFrame = CFrame.new(p),
	})
	registrar(clarao, 1.6)
	tween(clarao, 0.6, { Transparency = 1,
		Size = Vector3.new(raio * 1.8, raio * 1.8, raio * 1.8) },
		Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- e a matéria nova caindo em volta: doze blocos por ângulo áureo
	for i = 1, 12 do
		local a = angulo(i)
		local alcance = raio * (0.3 + (i / 12) * 0.6)
		local onde = pos(d) + Vector3.new(math.cos(a) * alcance, 3,
			math.sin(a) * alcance)
		task.delay(0.2 + i * 0.03, function()
			nascer(CFrame.new(onde), Vector3.new(2.6, 6, 2.6), CFG.OURO,
				Enum.Material.Neon, CFG.LUZ)
		end)
	end

	camadaPo(pos(d), CFG.OURO, raio * 0.5, 26, CFG.T_PO * 1.5)
	tremor(CFG.TREMOR_FORCA * 1.5, CFG.TREMOR_TEMPO * 1.6)
end

-- ── 7. DEMIURGO ──────────────────────────────────────────────────────────

function Efeitos.MOLDE_MUNDO(d)
	local p = acima(pos(d), 2)
	local direcao = dir(d)
	local raio = raioDe(d, 20)
	local base = CFrame.lookAt(p, p + direcao)

	-- o traço do molde é um ARCO, não uma reta: quem molda um mundo o faz em
	-- volta, não à frente
	for i = 0, 8 do
		local fracao = i / 8
		local a = math.rad(-70 + 140 * fracao)
		local pa = (base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -raio)).Position
		local pb = (base * CFrame.Angles(0, a + math.rad(17), 0)
			* CFrame.new(0, 0, -raio)).Position
		camadaTraco(pa, pb, CFG.OURO, 0.4 + fracao * 0.2)
	end
	camadaFaisca(p + direcao * (raio * 0.5), CFG.OURO, 6, 10, 0.4)
end

--- R: o continente. Placas subindo do chão.
function Efeitos.CONTINENTE(d)
	local centro = pos(d)
	local raio = raioDe(d, 30)

	for i = 1, 5 do
		local a = angulo(i)
		local alcance = raio * (0.3 + (i / 5) * 0.55)
		local onde = centro + Vector3.new(math.cos(a) * alcance, 0,
			math.sin(a) * alcance)
		local alto = 5 + math.abs(jitter(a)) * 6
		task.delay(i * 0.07, function()
			nascer(CFrame.new(onde + Vector3.new(0, alto * 0.5, 0)),
				Vector3.new(9, alto, 9), CFG.TERRA, Enum.Material.Slate,
				CFG.TERRA)
		end)
	end
	camadaPo(centro, CFG.TERRA, raio * 0.7, 24, CFG.T_PO * 1.3)
	tremor(CFG.TREMOR_FORCA * 1.2, CFG.TREMOR_TEMPO * 1.3)
end

--- T: a Criação. A ultimate.
function Efeitos.CRIACAO(d)
	local centro = pos(d)
	local p = acima(centro, 2)
	local raio = raioDe(d, 52)

	-- o mundo que se forma acima, e desce
	local mundo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = CFG.VERDE,
		Material = Enum.Material.Grass,
		Transparency = 0.1,
		CFrame = CFrame.new(centro + Vector3.new(0, 34, 0)),
	})
	registrar(mundo, 2.6)
	tween(mundo, 0.6, { Size = Vector3.new(16, 16, 16) },
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(mundo, 1.6, { Transparency = 1 }, Enum.EasingStyle.Sine,
		Enum.EasingDirection.In)

	local oceano = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Color = CFG.TINTA,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		CFrame = CFrame.new(centro + Vector3.new(0, 34, 0)),
	})
	registrar(oceano, 2.6)
	tween(oceano, 0.6, { Size = Vector3.new(17, 17, 17) },
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(oceano, 1.6, { Transparency = 1 })

	-- e o chão inteiro nascendo em volta
	for i = 1, 10 do
		local a = angulo(i)
		local alcance = raio * (0.25 + (i / 10) * 0.65)
		local onde = centro + Vector3.new(math.cos(a) * alcance, 0,
			math.sin(a) * alcance)
		local alto = 6 + math.abs(jitter(a)) * 9
		task.delay(0.25 + i * 0.04, function()
			nascer(CFrame.new(onde + Vector3.new(0, alto * 0.5, 0)),
				Vector3.new(8, alto, 8), CFG.TERRA, Enum.Material.Slate,
				CFG.TERRA)
		end)
	end

	local i = 0
	while i < 3 do
		local atraso = 0.15 * i
		task.delay(atraso, function()
			local anel = novaParte({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.3, 3, 3),
				Color = branco(CFG.OURO, i * 0.25),
				Transparency = 0.25,
				CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
			})
			registrar(anel, 1.4)
			tween(anel, 0.8 + i * 0.2, {
				Transparency = 1,
				Size = Vector3.new(0.08, raio * (1 + i * 0.3) * 2,
					raio * (1 + i * 0.3) * 2),
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end)
		i = i + 1
	end

	camadaPo(centro, CFG.TERRA, raio * 0.6, 30, CFG.T_PO * 1.6)
	camadaBroto(centro, raio * 0.5, 24, CFG.SEIVA, 5, 2.2)
	tremor(CFG.TREMOR_FORCA * 1.8, CFG.TREMOR_TEMPO * 2)
	-- Sonar_Ring(CF, Lifetime, Size_Start, Size_End, Thickness_Start,
	--            Thickness_End, Color_A, Color_B)
	pk("Sonar_Ring", CFrame.new(p), 1.3, 6, raio * 2, 1.6, 0.1,
		CFG.OURO, CFG.VERDE)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Criacao] falha em " .. tostring(tipo)
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
			if inst:IsA("ParticleEmitter") or inst:IsA("Trail") then
				inst.Enabled = false
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
	if tremorAtivo then
		tremorAtivo:Disconnect()
		tremorAtivo = nil
	end
end

return VFX
