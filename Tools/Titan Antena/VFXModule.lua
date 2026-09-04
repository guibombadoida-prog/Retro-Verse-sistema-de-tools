-- VFXModule.lua
-- ModuleScript "VFXModule" — conjunto TITAN (TV Man Titan)
--
-- TODO EFEITO DAS 7 TOOLS DESENHA AQUI, E DESENHA NO CLIENTE.
--
--═══════════════════════════════════════════════════════════════
-- A LINGUAGEM VISUAL: TUBO DE RAIOS CATÓDICOS
--═══════════════════════════════════════════════════════════════
--
--   Um conjunto sobre uma televisão precisa de um vocabulário próprio, senão
--   ele vira o mesmo clarão-e-onda de todos os outros. As cinco camadas
--   daqui são a gramática do CRT:
--
--     `camadaVarredura`  barras finas e claras descendo — a linha de
--                        varredura. É o que assina o conjunto: nenhuma outra
--                        Tool do repositório tem isto.
--     `camadaChuvisco`   cubinhos piscando em volume — a estática. Cada um
--                        vive um tempo diferente, por ângulo áureo, e é a
--                        DESSINCRONIA que faz parecer ruído em vez de enfeite.
--     `camadaFeixe`      um cilindro fino de A até B — o raio catódico.
--     `camadaAnelSom`    anéis chatos abrindo — a onda do alto-falante.
--     `camadaFaisca`     cubinhos arremessados para fora — o curto-circuito.
--
--   E o `brilhoTela`, que é a moldura acesa: um `Part` Neon com halo. Aparece
--   sempre que a tela do Titan faz alguma coisa.
--
--═══════════════════════════════════════════════════════════════
-- O QUE NÃO ESTÁ AQUI, E POR QUÊ
--═══════════════════════════════════════════════════════════════
--
--   `ScreenGui`. A tentação óbvia de um personagem com tela na cabeça é
--   desenhar o chuvisco POR CIMA da câmera de quem levou. `ScreenGui`,
--   `ColorCorrection` e `Sky` são os três proibidos dentro de Tool, e o
--   motivo é o mesmo nos três: são estado de INTERFACE, não do mundo. Uma
--   Tool que suma no meio deixa a tela do jogador coberta e sem saída.
--
--   O chuvisco daqui é volume no mundo 3D, à frente de quem levou. Ele
--   atrapalha porque ESTÁ LÁ, e some sozinho porque tem `Debris`.
--
--═══════════════════════════════════════════════════════════════
-- PROIBIÇÕES RESPEITADAS
--═══════════════════════════════════════════════════════════════
--
--   Zero `math.random`. O ângulo áureo (137.507764°) distribui cubinho de
--   chuvisco, faísca e raio do leque sem sorteio — e é isso que faz todos os
--   clientes desenharem a MESMA cena. Sorteio por cliente, com todo mundo
--   desenhando, lê como lag.
--
--   Zero `:Destroy()` — `Parent = nil` e `Debris`. Zero `tick()` — acumulador
--   de `dt` a partir de zero. Nada de `Instance.new("Explosion")`.

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
	LIMITE_VIVOS = 240,

	TELA         = Color3.fromRGB(226, 240, 255),
	VARREDURA    = Color3.fromRGB(120, 200, 255),
	CROMADO      = Color3.fromRGB(198, 202, 210),
	ALERTA       = Color3.fromRGB(255, 72, 72),
	BRASA        = Color3.fromRGB(255, 148, 62),
	GABINETE     = Color3.fromRGB(28, 28, 32),

	TREMOR_FORCA = 0.4,
	TREMOR_TEMPO = 0.7,
}

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

--- Jitter determinístico em [-1,1]. No lugar do `math.random`: mesma
--- variedade, e todos os clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

--- Ângulo áureo por índice. 137.507764° nunca repete alinhamento, então os
--- cubinhos do chuvisco nunca ficam empilhados numa linha só.
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

--- Sobe um pouco: quase todo efeito nasce na cintura, não no pé.
local function acima(p, quanto)
	return (p or Vector3.new()) + Vector3.new(0, quanto or 2.4, 0)
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- O pack do Acervo viaja como filho deste módulo, não em ReplicatedStorage: a
-- Regra nº 1 não abre exceção para pack. Se ele não estiver lá, cada efeito
-- daqui continua desenhando sozinho — `pk` só devolve false.
--
-- DUAS PORTAS (Regra nº 2): o depósito primeiro, o interior depois. A segunda
-- não é redundância — num place vazio ninguém montou depósito nenhum, e até o
-- primeiro `Equipped` o molde ainda está aqui dentro.
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

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[" .. script.Name .. "/Titan] pack " .. tostring(nome) .. ": "
			.. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- TREMOR DE CÂMERA
--
-- `workspace.CurrentCamera` é singleton por cliente, e este módulo roda em
-- cliente: é acesso de serviço, não depósito de asset. O tremor é aplicado
-- por MULTIPLICAÇÃO relativa e some sozinho quando o tempo acaba — a câmera
-- nunca fica presa, porque nada aqui escreve `CameraType`.
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

--- A moldura acesa: a tela do Titan fazendo alguma coisa.
local function brilhoTela(p, c, largura, vida)
	local tela = novaParte({
		Size = Vector3.new(largura, largura * 0.8, 0.12),
		Color = branco(c, 0.4),
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	registrar(tela, vida or 0.4)
	tween(tela, vida or 0.4, {
		Transparency = 1,
		Size = Vector3.new(largura * 1.7, largura * 1.4, 0.02),
	})

	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 5, largura * 3
	luz.Parent = tela
	return tela
end

--- A LINHA DE VARREDURA — a assinatura do conjunto.
---
--- Barras finas que descem de cima até embaixo do volume, uma atrás da outra,
--- e apagam. O intervalo entre elas é o que faz ler como varredura em vez de
--- persiana: elas nascem juntas, mas cada uma começa a apagar num tempo
--- diferente.
local function camadaVarredura(p, c, largura, altura, quantidade, vida)
	local n = quantidade or 7
	local passo = altura / n
	for i = 0, n - 1 do
		local y = -altura * 0.5 + passo * i
		local barra = novaParte({
			Size = Vector3.new(largura, 0.14, largura),
			Color = branco(c, 0.55),
			Transparency = 0.35,
			CFrame = CFrame.new(p + Vector3.new(0, y, 0)),
		})
		registrar(barra, (vida or 0.6) + 0.3)
		-- cada barra sobe até o topo e apaga com atraso próprio
		tween(barra, (vida or 0.6) * (0.6 + i / n), {
			Transparency = 1,
			CFrame = CFrame.new(p + Vector3.new(0, y + altura, 0)),
			Size = Vector3.new(largura * 1.3, 0.04, largura * 1.3),
		}, Enum.EasingStyle.Linear)
	end
end

--- O CHUVISCO — estática em volume.
---
--- O que faz ler como ruído é a DESSINCRONIA: cada cubinho tem posição,
--- tamanho e prazo próprios, todos por ângulo áureo. Cubinhos iguais piscando
--- juntos leem como enfeite; desencontrados leem como sinal ruim.
local function camadaChuvisco(p, c, raio, quantidade, vida)
	local n = quantidade or 26
	for i = 1, n do
		local a = angulo(i)
		local alcance = raio * (0.25 + (i / n) * 0.75)
		local altura = jitter(a) * raio * 0.7
		local onde = p + Vector3.new(math.cos(a) * alcance, altura,
			math.sin(a) * alcance)
		local lado = 0.3 + math.abs(jitter(a + 1.1)) * 0.7
		local cubo = novaParte({
			Size = Vector3.new(lado, lado, lado),
			Color = (i % 3 == 0) and branco(c, 0.8) or c,
			Transparency = 0.15 + math.abs(jitter(a + 2.2)) * 0.4,
			CFrame = CFrame.new(onde) * CFrame.Angles(a, a * 0.7, a * 0.3),
		})
		local prazo = (vida or 0.9) * (0.35 + (i % 5) * 0.16)
		registrar(cubo, prazo + 0.2)
		tween(cubo, prazo, {
			Transparency = 1,
			Size = Vector3.new(lado * 0.2, lado * 0.2, lado * 0.2),
		}, Enum.EasingStyle.Linear)
	end
end

--- O FEIXE — um cilindro fino de A até B.
local function camadaFeixe(a, b, c, espessura, vida)
	local delta = b - a
	local comprimento = delta.Magnitude
	if comprimento < 0.1 then return nil end

	local feixe = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(comprimento, espessura, espessura),
		Color = branco(c, 0.5),
		Transparency = 0.1,
		CFrame = CFrame.lookAt(a + delta * 0.5, b)
			* CFrame.Angles(0, math.rad(90), 0),
	})
	registrar(feixe, (vida or 0.35) + 0.2)
	tween(feixe, vida or 0.35, {
		Transparency = 1,
		Size = Vector3.new(comprimento, espessura * 2.6, espessura * 2.6),
	})

	-- o halo em volta, mais largo e mais apagado
	local halo = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(comprimento, espessura * 3, espessura * 3),
		Color = c,
		Transparency = 0.7,
		CFrame = feixe.CFrame,
	})
	registrar(halo, (vida or 0.35) + 0.2)
	tween(halo, (vida or 0.35) * 1.2, { Transparency = 1 })
	return feixe
end

--- O ANEL DE SOM — um cilindro chato que abre.
local function camadaAnelSom(p, c, raioFinal, vida, inclinacao)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 2, 2),
		Color = c,
		Transparency = 0.3,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90))
			* CFrame.Angles(0, 0, inclinacao or 0),
	})
	registrar(anel, (vida or 0.55) + 0.2)
	tween(anel, vida or 0.55, {
		Transparency = 1,
		Size = Vector3.new(0.06, raioFinal * 2, raioFinal * 2),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return anel
end

--- A FAÍSCA — cubinhos arremessados para fora.
local function camadaFaisca(p, c, forca, quantidade, vida)
	local n = quantidade or 12
	for i = 1, n do
		local a = angulo(i)
		local direcao = Vector3.new(math.cos(a), 0.3 + math.abs(jitter(a)) * 0.9,
			math.sin(a)).Unit
		local lado = 0.16 + math.abs(jitter(a + 0.7)) * 0.22
		local faisca = novaParte({
			Size = Vector3.new(lado, lado, lado * 3),
			Color = branco(c, 0.6),
			Transparency = 0.05,
			CFrame = CFrame.lookAt(p, p + direcao),
		})
		registrar(faisca, (vida or 0.45) + 0.2)
		tween(faisca, vida or 0.45, {
			Transparency = 1,
			CFrame = CFrame.lookAt(p + direcao * forca, p + direcao * forca * 2),
			Size = Vector3.new(lado * 0.3, lado * 0.3, lado),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
end

--- A FENDA — uma linha de lascas no chão, do ponto para a frente.
local function camadaFenda(origem, direcao, c, comprimento, vida)
	local n = math.clamp(math.floor(comprimento / 4), 3, 14)
	for i = 0, n do
		local fracao = i / n
		local onde = origem + direcao * (comprimento * fracao)
		local a = angulo(i)
		local altura = (1 - fracao) * 3.2 + 0.6
		local lasca = novaParte({
			Size = Vector3.new(0.5 + jitter(a) * 0.2, altura, 0.5),
			Color = c,
			Transparency = 0.15,
			Material = Enum.Material.Neon,
			CFrame = CFrame.new(onde + Vector3.new(0, altura * 0.3, 0))
				* CFrame.Angles(math.rad(jitter(a) * 16), a,
					math.rad(jitter(a + 1) * 16)),
		})
		registrar(lasca, (vida or 0.9) + 0.3)
		tween(lasca, (vida or 0.9) * (0.6 + fracao * 0.5), {
			Transparency = 1,
			Size = Vector3.new(0.1, altura * 0.2, 0.1),
		})
	end
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

local function raioDe(d, padrao)
	return (d and tonumber(d.raio)) or padrao
end

local function corDe(d, padrao)
	return (d and typeof(d.cor) == "Color3") and d.cor or padrao
end

--═══════════════════════════════════════════════════════════════
-- OS EFEITOS — 22, mais o PARAR
--
-- `TESTES/verificar_vfx_chamadas.py` confere que toda porta chamada pelos
-- Servers existe aqui. Efeito transmitido sem definição não desenha e nada
-- avisa — foi assim que um conjunto inteiro saiu sem VFX.
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

-- ── 1. TITAN ESTATICA ────────────────────────────────────────────────────

--- M1: a batida de gabinete. A tela pisca no contato e solta faísca.
function Efeitos.TELA_IMPACTO(d)
	local p = acima(pos(d), 1.6)
	local c = corDe(d, CFG.TELA)
	brilhoTela(p, c, 3.2, 0.3)
	camadaFaisca(p, CFG.VARREDURA, 7, 10, 0.4)
	camadaAnelSom(p, c, 6, 0.35, math.rad(90))
	-- Shockwave_Explosion(Position, Duration, Size_A, Size_B, Color_A, Color_B)
	pk("Shockwave_Explosion", p, 0.45, 2, 11, c, branco(c, 0.6))
end

--- R: o chuvisco. Volume de estática à frente de quem levou.
function Efeitos.CHUVISCO(d)
	local p = acima(pos(d), 2.6)
	local c = corDe(d, CFG.VARREDURA)
	local raio = raioDe(d, 14)
	camadaChuvisco(p, c, raio, 40, 1.4)
	camadaVarredura(p, c, raio * 0.9, raio * 1.2, 9, 1.0)
	brilhoTela(p, CFG.TELA, raio * 0.5, 0.8)
end

--- T: o espelho ligado. Uma casca em volta de quem ergueu.
function Efeitos.ESPELHO(d)
	local p = acima(pos(d), 2.2)
	local c = corDe(d, CFG.TELA)
	local raio = raioDe(d, 6)

	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio * 2, raio * 2, raio * 2),
		Color = c,
		Transparency = 0.82,
		Material = Enum.Material.Glass,
		Reflectance = 0.5,
		CFrame = CFrame.new(p),
	})
	anotar(d, casca)
	registrar(casca, (d and d.duracao or 6) + 1)
	camadaVarredura(p, CFG.VARREDURA, raio * 1.6, raio * 2.2, 8, 1.2)
end

--- E o instante em que ele DEVOLVE: a casca pisca no ponto do golpe.
function Efeitos.ESPELHO_DEVOLVE(d)
	local p = acima(pos(d), 2.0)
	local c = corDe(d, CFG.TELA)
	brilhoTela(p, c, 4.4, 0.28)
	camadaAnelSom(p, branco(c, 0.7), 9, 0.4, math.rad(90))
	camadaFaisca(p, CFG.VARREDURA, 9, 14, 0.4)
end

-- ── 2. TITAN RAIO CATODICO ───────────────────────────────────────────────

--- M1: a faísca curta do tubo.
function Efeitos.FAISCA(d)
	local p = acima(pos(d), 2.0)
	local direcao = dir(d)
	local c = corDe(d, CFG.VARREDURA)
	camadaFeixe(p, p + direcao * raioDe(d, 9), c, 0.6, 0.22)
	camadaFaisca(p + direcao * 2, c, 6, 8, 0.3)
end

--- R: o feixe reto, longo.
function Efeitos.FEIXE(d)
	local p = acima(pos(d), 2.4)
	local destino = (d and typeof(d.destino) == "Vector3") and d.destino
		or (p + dir(d) * raioDe(d, 80))
	local c = corDe(d, CFG.VARREDURA)

	camadaFeixe(p, destino, c, 1.5, 0.6)
	brilhoTela(p, CFG.TELA, 3.6, 0.5)
	camadaFaisca(destino, c, 10, 16, 0.55)
	camadaAnelSom(destino, c, 10, 0.5, math.rad(90))
	tremor(CFG.TREMOR_FORCA * 0.6, CFG.TREMOR_TEMPO * 0.6)
end

--- T: o leque. Cinco feixes abrindo, distribuídos por ângulo áureo em torno
--- da direção — nunca sorteados, para todo mundo ver o mesmo leque.
function Efeitos.LEQUE(d)
	local p = acima(pos(d), 2.4)
	local direcao = dir(d)
	local c = corDe(d, CFG.VARREDURA)
	local alcance = raioDe(d, 48)
	local n = (d and tonumber(d.quantidade)) or 5

	local base = CFrame.lookAt(p, p + direcao)
	for i = 0, n - 1 do
		local abertura = math.rad(-42 + (84 / math.max(n - 1, 1)) * i)
		local ponta = (base * CFrame.Angles(0, abertura, 0)
			* CFrame.new(0, 0, -alcance)).Position
		camadaFeixe(p, ponta, c, 0.9, 0.5)
		camadaFaisca(ponta, c, 6, 6, 0.4)
	end
	brilhoTela(p, CFG.TELA, 4.4, 0.55)
end

-- ── 3. TITAN ANTENA ──────────────────────────────────────────────────────

--- M1: o chicote. Um arco de lascas ao longo do golpe.
function Efeitos.CHICOTE(d)
	local p = acima(pos(d), 2.2)
	local direcao = dir(d)
	local c = corDe(d, CFG.CROMADO)
	local raio = raioDe(d, 12)

	local base = CFrame.lookAt(p, p + direcao)
	for i = 0, 9 do
		local fracao = i / 9
		local a = math.rad(-70 + 140 * fracao)
		local ponto = (base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -raio)).Position
		local lasca = novaParte({
			Size = Vector3.new(0.22, 0.22, 2.2),
			Color = branco(c, 0.4),
			Transparency = 0.1,
			CFrame = CFrame.lookAt(ponto, ponto + direcao),
		})
		registrar(lasca, 0.4)
		tween(lasca, 0.24, {
			Transparency = 1,
			Size = Vector3.new(0.04, 0.04, 3.0),
		})
	end
end

--- R: a torre de sinal cravada no chão.
function Efeitos.TORRE(d)
	local p = pos(d)
	local c = corDe(d, CFG.ALERTA)
	local raio = raioDe(d, 34)
	local duracao = (d and tonumber(d.duracao)) or 8

	local mastro = novaParte({
		Size = Vector3.new(0.5, 12, 0.5),
		Color = CFG.CROMADO,
		Material = Enum.Material.Metal,
		Transparency = 0,
		CFrame = CFrame.new(p + Vector3.new(0, 6, 0)),
	})
	anotar(d, mastro)
	registrar(mastro, duracao + 1)

	local ponta = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.2, 1.2, 1.2),
		Color = c,
		Transparency = 0.05,
		CFrame = CFrame.new(p + Vector3.new(0, 12, 0)),
	})
	anotar(d, ponta)
	registrar(ponta, duracao + 1)

	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 6, 30
	luz.Parent = ponta

	-- o pulso: um anel a cada volta, por acumulador de dt
	local passado, proximoAnel = 0, 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not ponta.Parent then
			laco:Disconnect()
			return
		end
		if passado < proximoAnel then return end
		proximoAnel = passado + 1.1
		camadaAnelSom(p + Vector3.new(0, 1, 0), c, raio, 1.0, math.rad(90))
	end)
	anotar(d, nil, laco)
	camadaFaisca(p, c, 6, 10, 0.5)
end

--- Quem está marcado carrega isto em cima da cabeça.
function Efeitos.MARCA(d)
	local peca = d and d.peca
	if not (peca and peca:IsA("BasePart")) then return end
	local c = corDe(d, CFG.ALERTA)
	local duracao = (d and tonumber(d.duracao)) or 6

	local sinal = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.9, 0.9, 0.9),
		Color = c,
		Transparency = 0.1,
		CFrame = peca.CFrame * CFrame.new(0, 4, 0),
	})
	anotar(d, sinal)
	registrar(sinal, duracao + 0.5)

	-- segue a peça no cliente, a 60 Hz: o servidor não move geometria por
	-- quadro em lugar nenhum deste repositório
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not (sinal.Parent and peca.Parent) then
			laco:Disconnect()
			if sinal.Parent then sinal.Parent = nil end
			return
		end
		sinal.CFrame = peca.CFrame * CFrame.new(0, 4 + math.sin(passado * 4) * 0.3, 0)
	end)
	anotar(d, nil, laco)
end

--- T: a interferência. Chuvisco largo e baixo, cobrindo a área.
function Efeitos.INTERFERENCIA(d)
	local p = acima(pos(d), 1.6)
	local c = corDe(d, CFG.VARREDURA)
	local raio = raioDe(d, 26)
	camadaChuvisco(p, c, raio, 52, 1.8)
	camadaAnelSom(p, c, raio, 0.9, math.rad(90))
	camadaVarredura(p, c, raio * 1.2, 8, 6, 1.2)
end

-- ── 4. TITAN ALTO FALANTE ────────────────────────────────────────────────

--- M1: a batida sônica.
function Efeitos.BATIDA(d)
	local p = acima(pos(d), 2.0)
	local c = corDe(d, CFG.TELA)
	camadaAnelSom(p, c, 7, 0.32, math.rad(90))
	camadaFaisca(p, CFG.CROMADO, 6, 8, 0.3)
	pk("Shockwave_Explosion", p, 0.5, 2, 13, c, branco(c, 0.6))
end

--- R: o cone de choque. Anéis abrindo AO LONGO da direção, não em volta.
function Efeitos.CONE(d)
	local p = acima(pos(d), 2.2)
	local direcao = dir(d)
	local c = corDe(d, CFG.TELA)
	local alcance = raioDe(d, 34)

	for i = 0, 5 do
		local fracao = i / 5
		local onde = p + direcao * (alcance * fracao)
		local anel = novaParte({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 2, 2),
			Color = c,
			Transparency = 0.25 + fracao * 0.35,
			CFrame = CFrame.lookAt(onde, onde + direcao)
				* CFrame.Angles(0, math.rad(90), 0),
		})
		registrar(anel, 0.8)
		tween(anel, 0.4 + fracao * 0.3, {
			Transparency = 1,
			Size = Vector3.new(0.08, 4 + fracao * 22, 4 + fracao * 22),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
	brilhoTela(p, c, 3.4, 0.4)
	tremor(CFG.TREMOR_FORCA * 0.5, CFG.TREMOR_TEMPO * 0.5)
end

--- T: o grito. Anéis radiais e chuvisco, tudo de uma vez.
function Efeitos.GRITO(d)
	local p = acima(pos(d), 2.4)
	local c = corDe(d, CFG.TELA)
	local raio = raioDe(d, 30)

	for i = 0, 3 do
		camadaAnelSom(p, c, raio * (0.55 + i * 0.16), 0.5 + i * 0.14,
			math.rad(90))
	end
	camadaChuvisco(p, CFG.VARREDURA, raio * 0.5, 30, 0.9)
	camadaFaisca(p, CFG.CROMADO, 14, 18, 0.6)
	brilhoTela(p, branco(c, 0.6), 6, 0.6)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
end

-- ── 5. TITAN LAMINA ──────────────────────────────────────────────────────

--- M1: o corte. Um arco de lascas, com o índice do combo inclinando o plano.
function Efeitos.CORTE(d)
	local p = acima(pos(d), 2.0)
	local direcao = dir(d)
	local c = corDe(d, CFG.VARREDURA)
	local raio = raioDe(d, 8)
	local giro = (d and tonumber(d.giro)) or 0

	local base = CFrame.lookAt(p, p + direcao) * CFrame.Angles(0, 0, giro)
	for i = 0, 10 do
		local fracao = i / 10
		local a = math.rad(-78 + 156 * fracao)
		local ponto = base * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, -raio)
		local lasca = novaParte({
			Size = Vector3.new(0.3, 1.4, 2.8),
			Color = branco(c, 0.5),
			Transparency = 0.08,
			CFrame = ponto * CFrame.Angles(0, 0, math.rad(90)),
		})
		registrar(lasca, 0.45)
		tween(lasca, 0.26, {
			Transparency = 1,
			Size = Vector3.new(0.05, 0.3, 3.6),
		})
	end
	-- Small_Slash(CF, Size, Duration, Color_A, Color_B)
	pk("Small_Slash", base, raio, 0.3, c, branco(c, 0.5))
end

--- R: a estocada. Um feixe curto e grosso à frente.
function Efeitos.ESTOCADA(d)
	local p = acima(pos(d), 2.2)
	local direcao = dir(d)
	local c = corDe(d, CFG.VARREDURA)
	local alcance = raioDe(d, 22)

	camadaFeixe(p, p + direcao * alcance, c, 2.2, 0.34)
	camadaFaisca(p + direcao * alcance, c, 8, 12, 0.4)
	camadaAnelSom(p + direcao * 2, c, 5, 0.3, math.rad(90))
end

--- T: o corte descendente, que abre o chão.
function Efeitos.FENDA(d)
	local p = pos(d)
	local direcao = dir(d)
	local c = corDe(d, CFG.ALERTA)
	local comprimento = raioDe(d, 40)

	camadaFenda(p, direcao, c, comprimento, 1.0)
	camadaAnelSom(acima(p, 0.8), CFG.VARREDURA, 12, 0.6, math.rad(90))
	camadaFaisca(acima(p, 1), CFG.BRASA, 12, 16, 0.6)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
end

-- ── 6. TITAN PROPULSOR ───────────────────────────────────────────────────

--- M1: a investida. Rastro de brasa atrás de quem avança.
function Efeitos.INVESTIDA(d)
	local p = acima(pos(d), 1.8)
	local direcao = dir(d)
	local c = corDe(d, CFG.BRASA)
	local alcance = raioDe(d, 26)

	local n = math.clamp(math.floor(alcance / 4), 3, 12)
	for i = 0, n do
		local fracao = i / n
		local onde = p + direcao * (alcance * fracao)
		local sopro = novaParte({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 1.8, 1.8),
			Color = (i % 2 == 0) and branco(c, 0.5) or c,
			Transparency = 0.35,
			CFrame = CFrame.new(onde),
		})
		registrar(sopro, 0.8)
		tween(sopro, 0.3 + fracao * 0.3, {
			Transparency = 1,
			Size = Vector3.new(0.3, 0.3, 0.3),
		})
	end
	camadaAnelSom(p, c, 6, 0.3, math.rad(90))
end

--- R, fase 1: a subida. A turbina acesa embaixo.
function Efeitos.VOO(d)
	local peca = d and d.peca
	local c = corDe(d, CFG.BRASA)
	local duracao = (d and tonumber(d.duracao)) or 1.4

	local origem = pos(d)
	local chama = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4),
		Color = c,
		Transparency = 0.25,
		CFrame = CFrame.new(origem),
	})
	anotar(d, chama)
	registrar(chama, duracao + 0.6)

	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 5, 18
	luz.Parent = chama

	-- segue quem está voando, no cliente
	local passado = 0
	local laco
	laco = RunService.RenderStepped:Connect(function(dt)
		passado = passado + dt
		if passado >= duracao or not chama.Parent then
			laco:Disconnect()
			if chama.Parent then chama.Parent = nil end
			return
		end
		if peca and peca:IsA("BasePart") and peca.Parent then
			chama.CFrame = peca.CFrame * CFrame.new(0, -2.6, 0)
		end
	end)
	anotar(d, nil, laco)
end

--- R, fase 2: o pouso.
function Efeitos.POUSO(d)
	local p = pos(d)
	local c = corDe(d, CFG.BRASA)
	local raio = raioDe(d, 20)

	camadaAnelSom(acima(p, 0.6), c, raio, 0.6, math.rad(90))
	camadaAnelSom(acima(p, 0.3), CFG.CROMADO, raio * 0.6, 0.45, math.rad(90))
	camadaFaisca(acima(p, 0.8), c, 12, 18, 0.6)
	camadaFenda(p, dir(d), CFG.BRASA, raio * 0.7, 0.8)
	tremor(CFG.TREMOR_FORCA * 0.8, CFG.TREMOR_TEMPO * 0.8)
end

--- T: o desvio lateral. Um vulto que fica para trás.
function Efeitos.DESVIO(d)
	local p = acima(pos(d), 2.0)
	local c = corDe(d, CFG.VARREDURA)

	camadaVarredura(p, c, 3.2, 5.4, 6, 0.5)
	camadaFaisca(p, CFG.BRASA, 5, 8, 0.3)
end

-- ── 7. TITAN SOBRECARGA ──────────────────────────────────────────────────

--- M1: a descarga na mão.
function Efeitos.DESCARGA(d)
	local p = acima(pos(d), 2.2)
	local direcao = dir(d)
	local c = corDe(d, CFG.ALERTA)

	camadaFeixe(p, p + direcao * raioDe(d, 14), c, 1.1, 0.28)
	camadaFaisca(p + direcao * 3, branco(c, 0.5), 7, 12, 0.35)
	brilhoTela(p, c, 2.6, 0.3)
end

--- R: a sobrecarga do campo.
function Efeitos.SOBRECARGA(d)
	local p = acima(pos(d), 2.4)
	local c = corDe(d, CFG.ALERTA)
	local raio = raioDe(d, 32)

	local nucleo = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Color = branco(c, 0.6),
		Transparency = 0.05,
		CFrame = CFrame.new(p),
	})
	registrar(nucleo, 0.9)
	tween(nucleo, 0.5, {
		Transparency = 1,
		Size = Vector3.new(raio * 1.4, raio * 1.4, raio * 1.4),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	for i = 0, 2 do
		camadaAnelSom(p, c, raio * (0.6 + i * 0.2), 0.5 + i * 0.12, math.rad(90))
	end
	camadaFaisca(p, CFG.BRASA, 16, 22, 0.7)
	camadaChuvisco(p, CFG.VARREDURA, raio * 0.4, 26, 0.8)
	tremor(CFG.TREMOR_FORCA, CFG.TREMOR_TEMPO)
	-- Smoky_Explosion(Position, Duration, Size, Color, Smoke_Color)
	pk("Smoky_Explosion", p, 0.9, raio * 0.45, c, CFG.GABINETE)
end

--- T: o reinício. A tela apaga, varre, e volta branca.
function Efeitos.REINICIO(d)
	local p = acima(pos(d), 2.6)
	local c = corDe(d, CFG.TELA)
	local raio = raioDe(d, 46)

	-- a varredura sobe alta e larga: é a tela do mundo inteiro reiniciando
	camadaVarredura(p, CFG.VARREDURA, raio * 0.8, raio * 1.1, 14, 1.6)
	camadaChuvisco(p, CFG.VARREDURA, raio * 0.55, 60, 1.6)

	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = Color3.new(1, 1, 1),
		Transparency = 0.02,
		CFrame = CFrame.new(p),
	})
	registrar(clarao, 1.4)
	tween(clarao, 0.7, {
		Transparency = 1,
		Size = Vector3.new(raio * 1.8, raio * 1.8, raio * 1.8),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	for i = 0, 4 do
		camadaAnelSom(p, branco(c, i * 0.15), raio * (0.5 + i * 0.14),
			0.6 + i * 0.12, math.rad(90))
	end
	camadaFaisca(p, CFG.ALERTA, 20, 26, 0.9)
	tremor(CFG.TREMOR_FORCA * 1.4, CFG.TREMOR_TEMPO * 1.6)
	pk("Smoky_Explosion", p, 1.2, raio * 0.55, Color3.new(1, 1, 1), CFG.GABINETE)
	-- Sonar_Ring(CF, Lifetime, Size_Start, Size_End, Thickness_Start,
	--            Thickness_End, Color_A, Color_B)
	pk("Sonar_Ring", CFrame.new(p), 1.1, 4, raio * 1.6, 1.2, 0.1,
		CFG.VARREDURA, c)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados or {})
	if not ok then
		warn("[" .. script.Name .. "/Titan] falha em " .. tostring(tipo)
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
