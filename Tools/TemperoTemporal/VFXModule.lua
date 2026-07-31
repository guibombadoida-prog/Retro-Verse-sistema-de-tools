--[[
	VFXModule — Guardião do Tempo
	ModuleScript, filho direto da Tool. Roda no CLIENTE.
	Retro-Verse / Studios  ·  §12.11 (o servidor transmite, nunca emite) · Regra nº 1

	Reescrita conforme dos efeitos do modelo `guardiao_do_tempo.rbxmx`:

		WACKYEFFECT "Wave"    → ONDA_TEMPORAL
		WACKYEFFECT "Sphere"  → ESFERA_TEMPORAL
		ClockEffect           → MOSTRADOR_TEMPORAL
		Debree                → DETRITOS
		CamShake (LocalScript)→ TREMOR

	Corrigido no passe §12.12.2:
		math.random          → ângulo áureo (Vogel) e jitter senoidal por contador
		wait() / Swait()     → acumulador dt em RenderStepped
		SINE global          → t local, a partir de zero
		:remove()            → Parent = nil / Debris
		ColorCorrectionEffect→ removido (o efeito vive só no mundo 3D)
		ScreenGui            → removido

	Regra nº 1: mesh, MeshPart, textura e emitter vêm de Tool/Efeitos/. Nada de fora.

	V2 — ACRESCENTADOS (os cinco de cima continuam intactos):

		RAIO_TEMPORAL      Plasma + clarão, do gerador de raio do Jupiter Great Sword
		ESTILHACO_ESTELAR  Estrelas + cintilar, do Sword of Cosmic Entity
		BRASA              Brasa + fumaça, do Sword of Cosmic Entity
		FAISCA             Faísca + anel de impacto, dos dois modelos
		AURA               Aura presa ao Handle, do Jupiter

	Estes cinco usam ParticleEmitter DE VERDADE, que moram em Tool/Efeitos/<TIPO>.
	O molde é clonado, posicionado e ligado por `Enabled` — nunca por `:Emit()`,
	que é a correção prescrita no §12.12.2. Sem o molde, o efeito não acontece e
	a Tool segue funcionando: degrada, não quebra.

	Depositado em ACERVO_RETROVERSE/Guardiao_Do_Tempo/VFX/
--]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local tool = script.Parent
local pastaEfeitos = tool:FindFirstChild("Efeitos")

local VFX = {}

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	ANGULO_AUREO    = 2.39996322972865332,   -- rad — substitui math.random na dispersão

	COR_PADRAO      = Color3.fromRGB(154, 205, 50),   -- BASECOLOR do modelo
	ESCALA_PADRAO   = 1.0,

	ONDA_VIDA       = 1.25,
	ONDA_ALTURA     = 0.35,
	ONDA_CRESCE     = 3.4,

	ESFERA_VIDA     = 0.90,
	ESFERA_CRESCE   = 2.6,
	ESFERA_TRANSP   = 0.55,

	MOSTRADOR_VIDA  = 1.60,
	MOSTRADOR_MARCAS = 12,          -- as 12 horas do mostrador
	MOSTRADOR_RAIO  = 1.0,
	MOSTRADOR_GIRO  = 2.2,          -- rad/s

	DETRITOS_PECAS  = 10,
	DETRITOS_VIDA   = 1.60,
	DETRITOS_SUBIDA = 14.0,
	DETRITOS_RAIO   = 1.0,

	TREMOR_VIDA     = 0.55,
	TREMOR_ALCANCE  = 90,
	TREMOR_FORCA    = 0.55,
	TREMOR_FREQ_A   = 37.0,         -- frequências primas entre si: o jitter não repete padrão
	TREMOR_FREQ_B   = 43.0,
	TREMOR_FREQ_C   = 29.0,

	-- Efeitos por emissor (V2)
	EMISSAO_CURTA   = 0.12,        -- s de Enabled num estouro
	EMISSAO_MEDIA   = 0.30,
	EMISSAO_LONGA   = 0.60,
	VIDA_MOLDE      = 6.0,         -- s até o molde sair de cena, já apagado
	AURA_DURACAO    = 2.5,

	MARGEM_DEBRIS   = 0.5,
}

--==============================================================================
-- AUXILIARES
--==============================================================================

local contador = 0

-- Molde de dentro da Tool. nil → o efeito cai no procedural e a Tool não quebra.
local function molde(nome)
	if not pastaEfeitos then
		return nil
	end
	local original = pastaEfeitos:FindFirstChild(nome)
	if not original then
		return nil
	end
	return original:Clone()
end

-- Dispersão determinística: mesma leitura visual do random, sem random.
local function direcaoVogel(indice, total)
	local angulo = indice * CFG.ANGULO_AUREO
	local raio = math.sqrt(indice / math.max(total, 1))
	return Vector3.new(math.cos(angulo) * raio, 0, math.sin(angulo) * raio)
end

local function novaParte(cor, tamanho, cframe, material)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.CanTouch = false
	parte.CastShadow = false
	parte.Material = material or Enum.Material.Neon
	parte.Color = cor
	parte.Size = tamanho
	parte.CFrame = cframe
	return parte
end

local function lerCor(payload)
	if typeof(payload.cor) == "Color3" then
		return payload.cor
	end
	return CFG.COR_PADRAO
end

local function lerEscala(payload)
	if type(payload.escala) == "number" and payload.escala > 0 then
		return payload.escala
	end
	return CFG.ESCALA_PADRAO
end

-- Laço de vida por acumulador dt. Devolve o cancelamento.
local function animar(duracao, passo, aoFim)
	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / duracao, 0, 1)
		passo(alpha, t)
		if alpha >= 1 then
			conexao:Disconnect()
			if aoFim then
				aoFim()
			end
		end
	end)
	return function()
		conexao:Disconnect()
	end
end

--==============================================================================
-- ONDA_TEMPORAL — WACKYEFFECT "Wave"
--==============================================================================

function VFX.ONDA_TEMPORAL(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)

	local onda = molde("ONDA_TEMPORAL")
	if onda then
		onda.CFrame = CFrame.new(payload.posicao)
	else
		onda = novaParte(cor, Vector3.new(1, CFG.ONDA_ALTURA, 1), CFrame.new(payload.posicao))
		onda.Shape = Enum.PartType.Cylinder
		onda.Orientation = Vector3.new(0, 0, 90)
	end
	onda.Parent = workspace

	local giro = 0
	animar(CFG.ONDA_VIDA, function(alpha)
		local raio = 1 + (CFG.ONDA_CRESCE * escala - 1) * (1 - (1 - alpha) ^ 3)
		onda.Size = Vector3.new(CFG.ONDA_ALTURA * escala, raio, raio)
		onda.Transparency = 0.2 + 0.8 * alpha
		giro = giro + 0.08
		onda.CFrame = CFrame.new(payload.posicao) * CFrame.Angles(0, giro, math.pi / 2)
	end, function()
		onda.Parent = nil
	end)

	Debris:AddItem(onda, CFG.ONDA_VIDA + CFG.MARGEM_DEBRIS)
end

--==============================================================================
-- ESFERA_TEMPORAL — WACKYEFFECT "Sphere"
--==============================================================================

function VFX.ESFERA_TEMPORAL(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)

	local esfera = molde("ESFERA_TEMPORAL")
	if esfera then
		esfera.CFrame = CFrame.new(payload.posicao)
	else
		esfera = novaParte(cor, Vector3.new(1, 1, 1), CFrame.new(payload.posicao))
		esfera.Shape = Enum.PartType.Ball
	end
	esfera.Parent = workspace

	animar(CFG.ESFERA_VIDA, function(alpha)
		local d = (1 + (CFG.ESFERA_CRESCE * escala - 1) * (1 - (1 - alpha) ^ 2)) * 2
		esfera.Size = Vector3.new(d, d, d)
		esfera.Transparency = CFG.ESFERA_TRANSP + (1 - CFG.ESFERA_TRANSP) * alpha
	end, function()
		esfera.Parent = nil
	end)

	Debris:AddItem(esfera, CFG.ESFERA_VIDA + CFG.MARGEM_DEBRIS)
end

--==============================================================================
-- MOSTRADOR_TEMPORAL — ClockEffect
--==============================================================================

function VFX.MOSTRADOR_TEMPORAL(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao

	local pasta = Instance.new("Folder")
	pasta.Name = "VFX_MOSTRADOR_TEMPORAL"
	pasta.Parent = workspace

	-- As 12 marcas de hora, em posições fixas — nada de sorteio
	local marcas = {}
	local indice = 1
	while indice <= CFG.MOSTRADOR_MARCAS do
		local angulo = (indice / CFG.MOSTRADOR_MARCAS) * math.pi * 2
		local marca = molde("MOSTRADOR_MARCA")
		if not marca then
			marca = novaParte(cor, Vector3.new(0.18, 0.05, 0.9) * escala, CFrame.new(origem))
		end
		marca.Parent = pasta
		table.insert(marcas, { parte = marca, angulo = angulo })
		indice = indice + 1
	end

	local ponteiro = molde("MOSTRADOR_PONTEIRO")
	if not ponteiro then
		ponteiro = novaParte(cor, Vector3.new(0.12, 0.05, 3.0) * escala, CFrame.new(origem))
	end
	ponteiro.Parent = pasta

	animar(CFG.MOSTRADOR_VIDA, function(alpha, t)
		local raio = CFG.MOSTRADOR_RAIO * escala * 4 * (0.3 + 0.7 * (1 - (1 - alpha) ^ 2))
		local transp = 0.15 + 0.85 * alpha

		for _, m in ipairs(marcas) do
			local deslocamento = Vector3.new(math.cos(m.angulo) * raio, 0, math.sin(m.angulo) * raio)
			m.parte.CFrame = CFrame.new(origem + deslocamento) * CFrame.Angles(0, -m.angulo, 0)
			m.parte.Transparency = transp
		end

		ponteiro.CFrame = CFrame.new(origem) * CFrame.Angles(0, t * CFG.MOSTRADOR_GIRO, 0)
			* CFrame.new(0, 0, -raio * 0.5)
		ponteiro.Transparency = transp
	end, function()
		pasta.Parent = nil
	end)

	Debris:AddItem(pasta, CFG.MOSTRADOR_VIDA + CFG.MARGEM_DEBRIS)
end

--==============================================================================
-- DETRITOS — Debree
--==============================================================================

function VFX.DETRITOS(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao

	local pasta = Instance.new("Folder")
	pasta.Name = "VFX_DETRITOS"
	pasta.Parent = workspace

	local pecas = {}
	local indice = 1
	while indice <= CFG.DETRITOS_PECAS do
		local direcao = direcaoVogel(indice, CFG.DETRITOS_PECAS)
		local peca = molde("DETRITO")
		if not peca then
			local lado = (0.4 + 0.25 * (indice % 3)) * escala
			peca = novaParte(cor, Vector3.new(lado, lado, lado), CFrame.new(origem), Enum.Material.Slate)
		end
		peca.Parent = pasta
		-- fase por índice: cada detrito gira diferente, sem sorteio
		table.insert(pecas, { parte = peca, direcao = direcao, fase = indice * CFG.ANGULO_AUREO })
		indice = indice + 1
	end

	animar(CFG.DETRITOS_VIDA, function(alpha)
		-- parábola: sobe e cai
		local altura = CFG.DETRITOS_SUBIDA * escala * alpha * (1 - alpha) * 4
		for _, p in ipairs(pecas) do
			local avanco = p.direcao * CFG.DETRITOS_RAIO * escala * (2 + alpha * 8)
			p.parte.CFrame = CFrame.new(origem + avanco + Vector3.new(0, altura, 0))
				* CFrame.Angles(p.fase + alpha * 6, p.fase * 0.5 + alpha * 4, p.fase * 0.25)
			p.parte.Transparency = alpha * alpha
		end
	end, function()
		pasta.Parent = nil
	end)

	Debris:AddItem(pasta, CFG.DETRITOS_VIDA + CFG.MARGEM_DEBRIS)
end

--==============================================================================
-- TREMOR — CamShake, sem math.random e sem ColorCorrection
--==============================================================================

function VFX.TREMOR(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local jogador = Players.LocalPlayer
	if not jogador then
		return
	end

	local personagem = jogador.Character
	if not personagem then
		return
	end

	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem:FindFirstChild("HumanoidRootPart")
	if not humanoide or not raiz then
		return
	end

	-- Só treme para quem está perto o bastante para sentir
	local distancia = (raiz.Position - payload.posicao).Magnitude
	local alcance = CFG.TREMOR_ALCANCE * lerEscala(payload)
	if distancia > alcance then
		return
	end

	local proximidade = 1 - (distancia / alcance)
	local forca = CFG.TREMOR_FORCA * lerEscala(payload) * proximidade

	animar(CFG.TREMOR_VIDA, function(alpha, t)
		-- Jitter senoidal por contador: três frequências primas entre si.
		-- Determinístico, e visualmente indistinguível do sorteio original.
		local decaimento = 1 - alpha
		humanoide.CameraOffset = Vector3.new(
			math.sin(t * CFG.TREMOR_FREQ_A) * forca * decaimento,
			math.sin(t * CFG.TREMOR_FREQ_B) * forca * decaimento,
			math.sin(t * CFG.TREMOR_FREQ_C) * forca * decaimento
		)
	end, function()
		if humanoide.Parent then
			humanoide.CameraOffset = Vector3.new(0, 0, 0)
		end
	end)
end


--==============================================================================
-- V2 — EFEITOS POR EMISSOR
-- Molde de Tool/Efeitos/, ligado por Enabled. Zero :Emit() (§12.12.2).
--==============================================================================

-- Liga os emissores de um molde por `duracao`, depois desliga e recolhe.
-- Desligar antes de recolher deixa as partículas já emitidas viverem até o fim
-- do Lifetime delas — recolher direto cortaria o efeito no meio.
local function dispararMolde(nome, posicao, escala, duracao, prender)
	local peca = molde(nome)
	if not peca then
		return nil
	end

	peca.Name = "VFX_" .. nome
	peca.CFrame = CFrame.new(posicao)
	peca.Size = Vector3.new(0.4, 0.4, 0.4) * math.max(escala, 0.1)
	peca.Parent = workspace

	local emissores = {}
	for _, filho in ipairs(peca:GetChildren()) do
		if filho:IsA("ParticleEmitter") then
			table.insert(emissores, filho)
			filho.Enabled = true
		end
	end

	task.delay(duracao, function()
		for _, emissor in ipairs(emissores) do
			emissor.Enabled = false
		end
	end)

	if not prender then
		Debris:AddItem(peca, CFG.VIDA_MOLDE)
	end
	return peca
end

-- "RAIO_TEMPORAL" — plasma + clarão. O raio do Jupiter, na cor do Guardião.
function VFX.RAIO_TEMPORAL(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end
	dispararMolde("RAIO_TEMPORAL", payload.posicao, lerEscala(payload),
		CFG.EMISSAO_CURTA, false)
end

-- "ESTILHACO_ESTELAR" — estrelas abrindo, do Sword of Cosmic Entity
function VFX.ESTILHACO_ESTELAR(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end
	dispararMolde("ESTILHACO_ESTELAR", payload.posicao, lerEscala(payload),
		CFG.EMISSAO_MEDIA, false)
end

-- "BRASA" — brasa subindo + fumaça
function VFX.BRASA(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end
	dispararMolde("BRASA", payload.posicao, lerEscala(payload),
		CFG.EMISSAO_LONGA, false)
end

-- "FAISCA" — faísca rasante + anel de impacto
function VFX.FAISCA(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end
	dispararMolde("FAISCA", payload.posicao, lerEscala(payload),
		CFG.EMISSAO_CURTA, false)
end

-- "AURA" — fica presa no ponto por alguns segundos, não é estouro
function VFX.AURA(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local peca = dispararMolde("AURA", payload.posicao, lerEscala(payload),
		CFG.AURA_DURACAO, true)
	if peca then
		Debris:AddItem(peca, CFG.AURA_DURACAO + CFG.VIDA_MOLDE)
	end
end

--==============================================================================
-- DESPACHO — chamado pelo Client ao receber VFXRemote
--==============================================================================

function VFX.executar(tipo, payload)
	if tipo == "executar" then
		return
	end

	local efeito = VFX[tipo]
	if type(efeito) ~= "function" then
		return
	end

	contador = contador + 1
	local ok, erro = pcall(efeito, payload or {})
	if not ok then
		warn("[VFXModule] efeito '" .. tostring(tipo) .. "' falhou: " .. tostring(erro))
	end
end

return VFX
