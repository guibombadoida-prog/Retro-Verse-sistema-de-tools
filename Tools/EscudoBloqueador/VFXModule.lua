--[[
	VFXModule  —  ModuleScript, filho direto da Tool. Roda no CLIENTE.
	Retro-Verse / Studios  ·  §12.11 — o servidor TRANSMITE, nunca emite

	O servidor manda apenas DADOS por VFXRemote. Quem cria as partículas é o cliente.
	Zero :Emit() no servidor. Zero Instance no payload.

	Dois tipos de efeito convivem aqui:

	  MOLDE      liga os ParticleEmitter que já vivem em Tool/Efeitos/<TIPO>.
	             As curvas são as extraídas do modelo de origem — ligar por
	             Enabled + Rate preserva a curva; :Emit() a jogaria fora.
	  PROCEDURAL monta a geometria em código, sem molde. Serve para escudo,
	             lâmina e anel, que são forma, não partícula.

	Proibições ativas aqui:
		:Destroy() em part          → Parent = nil / Debris
		math.random em gameplay     → ângulo áureo (Vogel) por índice sequencial
		tick()                      → acumulador dt a partir de zero
		ScreenGui/ColorCorrection   → o efeito vive só no mundo 3D
--]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Este ModuleScript é filho da Tool. TUDO que ele usa vem daqui para dentro (Regra nº 1):
-- meshes, MeshParts, texturas, ParticleEmitters e Beams moram em Tool/Efeitos/.
local tool = script.Parent
local pastaEfeitos = tool:FindFirstChild("Efeitos")

local VFX = {}

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	ANGULO_AUREO = 2.39996322972865332,  -- rad — substitui math.random na distribuição

	-- Molde: quanto tempo o emissor fica LIGADO, e quanto a partícula já solta
	-- ainda tem de vida depois de desligar. O segundo é o Lifetime máximo do
	-- emissor — cortar antes disso apaga partícula no ar.
	RAJADA_LIGADA  = 0.16,
	RAJADA_RESIDUO = 1.0,
	CONTINUO_LIGADO = 1.10,
	CONTINUO_RESIDUO = 2.5,

	VIDA_ESCUDO  = 0.85,
	VIDA_LAMINA  = 0.55,
	VIDA_ANEL    = 0.90,

	ANEL_RAIO_FIM = 3.4,   -- multiplicador da escala
	ANEL_ALTURA   = 0.5,

	COR_PADRAO    = Color3.fromRGB(0, 122, 190),
	ESCALA_PADRAO = 1.0,

	-- Movimento contínuo: rodado AQUI, no cliente, a 60 Hz.
	--
	-- Part ancorada movida por script de SERVIDOR replica a ~20 Hz e o cliente
	-- não interpola: o que sai é um passo discreto por atualização. Era isso que
	-- deixava a órbita e o voo "não fluidos". A posição é matemática pura e
	-- determinística, então o cliente reproduz o mesmo movimento sem nenhum
	-- pacote por frame — e o servidor segue dono do dano, com a mesma fórmula.
	SEGURANCA_VIDA = 14,
}

--==============================================================================
-- AUXILIARES
--==============================================================================

local contador = 0

-- Distribuição determinística: ângulo áureo. Mesma dispersão visual do random, sem random.
local function direcaoVogel(indice, total)
	local angulo = indice * CFG.ANGULO_AUREO
	local raio = math.sqrt(indice / math.max(total, 1))
	return Vector3.new(math.cos(angulo) * raio, 0, math.sin(angulo) * raio)
end

-- Molde de dentro da Tool. Devolve nil se não existir — o efeito cai no procedural,
-- e a Tool nunca quebra por falta de asset.
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

--==============================================================================
-- EFEITOS DE MOLDE — emissores que já vivem dentro da Tool
--==============================================================================

-- Liga os ParticleEmitter de um molde de Tool/Efeitos por um tempo e desliga.
--
-- Por Enabled + Rate, NUNCA por :Emit(). O :Emit() dispara uma leva fixa e
-- ignora o Rate autorado no emissor; a curva extraída do modelo de origem se
-- perde, e o efeito fica com outra cara.
--
-- Depois de desligar, a Part fica viva mais RESIDUO segundos: partícula já
-- solta continua no ar, e remover o pai na hora apagaria todas de uma vez.
local function ligarMolde(nomeMolde, payload, ligada, residuo, tingir)
	if typeof(payload.posicao) ~= "Vector3" then
		return false
	end

	local ancora = molde(nomeMolde)
	if not ancora then
		return false
	end

	ancora.Anchored = true
	ancora.CFrame = CFrame.new(payload.posicao)
	ancora.Parent = workspace

	local cor = lerCor(payload)
	local emissores = {}
	for _, filho in ipairs(ancora:GetChildren()) do
		if filho:IsA("ParticleEmitter") then
			-- `tingir` false preserva a cor autorada do emissor. A poeira e o
			-- estilhaço têm cor própria que faz parte do efeito; tingir de azul
			-- transformaria fumaça cinza em fumaça azul, que lê como magia.
			if tingir ~= false then
				filho.Color = ColorSequence.new(cor)
			end
			filho.Enabled = true
			table.insert(emissores, filho)
		end
	end

	if #emissores == 0 then
		ancora.Parent = nil
		return false
	end

	task.delay(ligada, function()
		for _, emissor in ipairs(emissores) do
			if emissor.Parent then
				emissor.Enabled = false
			end
		end
	end)

	Debris:AddItem(ancora, ligada + residuo)
	return true
end

-- "CLARAO_ESCUDO" — flash que abre e fecha girando. Saitama / Normal Uppercut.
function VFX.CLARAO_ESCUDO(payload)
	ligarMolde("CLARAO_ESCUDO", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO)
end

-- "IMPACTO_ESCUDO" — rajada curta e presa ao ponto. Saitama / Death Counter.
function VFX.IMPACTO_ESCUDO(payload)
	if ligarMolde("IMPACTO_ESCUDO", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO) then
		return
	end
	VFX.ANEL(payload)
end

-- "ESTILHACO_ESCUDO" — caco de escudo quebrando. Saitama / Death Counter.
-- Não tinge: o estilhaço é escuro de propósito, e é isso que faz ler como metal.
function VFX.ESTILHACO_ESCUDO(payload)
	ligarMolde("ESTILHACO_ESCUDO", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO, false)
end

-- "ONDA_ESCUDO" — anel de choque que abre até 120 studs. Saitama / Serious Punch.
function VFX.ONDA_ESCUDO(payload)
	ligarMolde("ONDA_ESCUDO", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO)
end

-- "POEIRA_ESCUDO" — poeira pesada que cai. Saitama / Serious Mode.
-- Não tinge: o cinza 100,102,115 é o do original.
function VFX.POEIRA_ESCUDO(payload)
	ligarMolde("POEIRA_ESCUDO", payload, CFG.CONTINUO_LIGADO, CFG.CONTINUO_RESIDUO, false)
end

-- "AURA" — véu contínuo em volta do ponto. Molde do Jupiter.
function VFX.AURA(payload)
	ligarMolde("AURA", payload, CFG.CONTINUO_LIGADO, CFG.CONTINUO_RESIDUO)
end

-- "FAISCA" — fagulhas curtas. Molde do Cosmic + Jupiter.
function VFX.FAISCA(payload)
	ligarMolde("FAISCA", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO)
end

-- "ESTILHACO_ESTELAR" — estrelas. Molde do Cosmic Entity.
function VFX.ESTILHACO_ESTELAR(payload)
	ligarMolde("ESTILHACO_ESTELAR", payload, CFG.RAJADA_LIGADA, CFG.RAJADA_RESIDUO)
end

--==============================================================================
-- EFEITOS PROCEDURAIS — forma, não partícula
--==============================================================================

-- "ESCUDO" — disco que aparece, gira e some. É a forma do escudo, e serve tanto
-- para o ciclone quanto para o bloqueio.
function VFX.ESCUDO(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao
	local frente = payload.frente
	if typeof(frente) ~= "Vector3" or frente.Magnitude < 0.001 then
		frente = Vector3.new(0, 0, 1)
	end

	local base = CFrame.lookAt(origem, origem + frente.Unit)
	local disco = novaParte(cor, Vector3.new(3.2 * escala, 3.2 * escala, 0.28 * escala),
		base, Enum.Material.Metal)
	disco.Transparency = 0.15
	disco.Reflectance = 0.3
	disco.Parent = workspace

	local aro = novaParte(cor, Vector3.new(3.6 * escala, 3.6 * escala, 0.16 * escala), base)
	aro.Transparency = 0.4
	aro.Parent = workspace

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_ESCUDO, 0, 1)
		local giro = CFrame.Angles(0, 0, alpha * math.pi * 2)

		disco.CFrame = base * giro
		aro.CFrame = base * giro
		disco.Transparency = 0.15 + alpha * 0.85
		aro.Transparency = 0.4 + alpha * 0.6

		if alpha >= 1 then
			conexao:Disconnect()
			disco.Parent = nil
			aro.Parent = nil
		end
	end)

	Debris:AddItem(disco, CFG.VIDA_ESCUDO + 0.5)
	Debris:AddItem(aro, CFG.VIDA_ESCUDO + 0.5)
end

-- "LAMINA" — risco de corte. Fino, comprido, e some rápido. É o traço que fica
-- no ar depois do golpe, não o projétil.
function VFX.LAMINA(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao
	local frente = payload.frente
	if typeof(frente) ~= "Vector3" or frente.Magnitude < 0.001 then
		frente = Vector3.new(0, 0, 1)
	end

	-- `giroCorte` varia por índice sequencial, não por random: cortes seguidos
	-- saem em ângulos diferentes, e o mesmo golpe sai igual toda vez.
	contador = contador + 1
	local passo = ((contador - 1) % 4) + 1
	local giroCorte = (passo * 45) - 90

	local base = CFrame.lookAt(origem, origem + frente.Unit)
		* CFrame.Angles(0, 0, math.rad(giroCorte))

	local risco = novaParte(cor, Vector3.new(14 * escala, 0.22 * escala, 0.22 * escala), base)
	risco.Transparency = 0.05
	risco.Parent = workspace

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_LAMINA, 0, 1)

		risco.Size = Vector3.new(
			14 * escala * (1 + alpha * 0.4),
			0.22 * escala * (1 - alpha),
			0.22 * escala * (1 - alpha)
		)
		risco.Transparency = 0.05 + alpha * 0.95

		if alpha >= 1 then
			conexao:Disconnect()
			risco.Parent = nil
		end
	end)

	Debris:AddItem(risco, CFG.VIDA_LAMINA + 0.5)
end

-- "ANEL" — anel de choque no plano do chão. Fallback de tudo que precisa de
-- impacto e não achou molde.
function VFX.ANEL(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao

	local anel = novaParte(cor, Vector3.new(CFG.ANEL_ALTURA, 1, 1), CFrame.new(origem))
	anel.Shape = Enum.PartType.Cylinder
	anel.Orientation = Vector3.new(0, 0, 90)
	anel.Parent = workspace

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_ANEL, 0, 1)
		local raio = 1 + (CFG.ANEL_RAIO_FIM * escala - 1) * (1 - (1 - alpha) ^ 3)

		anel.Size = Vector3.new(CFG.ANEL_ALTURA, raio, raio)
		anel.Transparency = alpha

		if alpha >= 1 then
			conexao:Disconnect()
			anel.Parent = nil
		end
	end)

	Debris:AddItem(anel, CFG.VIDA_ANEL + 0.5)
end

-- "ESTILHACOS" — cacos voando do ponto, em ângulo áureo. Complementa o molde
-- ESTILHACO_ESCUDO com geometria, para o escudo partido ter peso.
function VFX.ESTILHACOS(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao
	local total = 10

	local pasta = Instance.new("Folder")
	pasta.Name = "EstilhacosEscudo"
	pasta.Parent = workspace

	local pecas = {}
	for i = 1, total do
		local direcao = direcaoVogel(i, total)
		local caco = novaParte(cor,
			Vector3.new(0.5 * escala, 0.16 * escala, 0.42 * escala),
			CFrame.new(origem), Enum.Material.Metal)
		caco.Reflectance = 0.3
		caco.Parent = pasta
		table.insert(pecas, {
			parte = caco,
			-- a componente Y sobe com o índice: os primeiros rasgam rente ao
			-- chão, os últimos sobem. Sem random, e sem todos iguais.
			direcao = (direcao + Vector3.new(0, 0.35 + i * 0.06, 0)).Unit,
			velocidade = 22 + i * 1.5,
		})
	end

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_ESCUDO, 0, 1)

		for i, peca in ipairs(pecas) do
			if peca.parte.Parent then
				local queda = Vector3.new(0, -38 * t * t * 0.5, 0)
				peca.parte.CFrame = CFrame.new(
					origem + peca.direcao * peca.velocidade * t + queda
				) * CFrame.Angles(t * (2 + i * 0.3), t * (3 + i * 0.2), 0)
				peca.parte.Transparency = alpha
			end
		end

		if alpha >= 1 then
			conexao:Disconnect()
			pasta.Parent = nil
		end
	end)

	Debris:AddItem(pasta, CFG.VIDA_ESCUDO + 0.5)
end

--==============================================================================
-- MOVIMENTO CONTÍNUO — desenhado no cliente, a 60 Hz
--==============================================================================

-- O payload traz `userId`, não o Character: Instance não viaja em payload
-- (§12.11), e resolver o jogador por serviço não é ler o mundo (Regra nº 1).
local function raizDoJogador(userId)
	if type(userId) ~= "number" then
		return nil
	end
	local jogador = Players:GetPlayerByUserId(userId)
	local personagem = jogador and jogador.Character
	return personagem and personagem:FindFirstChild("HumanoidRootPart") or nil
end

local function novoDisco(cor, tamanho)
	local disco = novaParte(cor, tamanho, CFrame.new(), Enum.Material.Metal)
	disco.Reflectance = 0.35
	disco.Transparency = 0.1

	local aro = novaParte(CFG.COR_PADRAO, tamanho + Vector3.new(0.45, 0.45, -0.12), CFrame.new())
	aro.Transparency = 0.4
	aro.Parent = disco

	return disco, aro
end

--[[
	"ORBITA_ESCUDOS" — N discos girando em volta de um personagem.

	Serve o Ciclone (5 discos) e a Proteção (1). O servidor manda os parâmetros
	UMA vez; daqui em diante o cliente desenha sozinho, seguindo o portador
	quadro a quadro. Zero pacote por frame, e 60 Hz de verdade.
]]
function VFX.ORBITA_ESCUDOS(payload)
	local raiz = raizDoJogador(payload.userId)
	if not raiz then
		return
	end

	local cor = lerCor(payload)
	local quantos = math.clamp(tonumber(payload.quantidade) or 1, 1, 12)
	local raio = tonumber(payload.raio) or 6
	local altura = tonumber(payload.altura) or 2
	local voltas = tonumber(payload.voltas) or 1
	local duracao = math.min(tonumber(payload.duracao) or 4, CFG.SEGURANCA_VIDA)
	local tamanho = payload.tamanho
	if typeof(tamanho) ~= "Vector3" then
		tamanho = Vector3.new(3.0, 3.0, 0.26)
	end

	local pasta = Instance.new("Folder")
	pasta.Name = "OrbitaDeEscudos"
	pasta.Parent = workspace

	local pecas = {}
	for i = 1, quantos do
		local disco, aro = novoDisco(cor, tamanho)
		disco.Parent = pasta
		table.insert(pecas, {
			disco = disco,
			aro = aro,
			fase = (i - 1) * (math.pi * 2 / quantos),
		})
	end

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local vivo = raizDoJogador(payload.userId)
		if not vivo or t >= duracao then
			conexao:Disconnect()
			pasta.Parent = nil
			return
		end

		local centro = vivo.Position
		local volta = t * voltas * math.pi * 2
		-- Fecha nos últimos 0,35 s em vez de sumir de uma vez.
		local saida = math.clamp((duracao - t) / 0.35, 0, 1)

		for _, peca in ipairs(pecas) do
			local angulo = volta + peca.fase
			local pos = centro + Vector3.new(
				math.cos(angulo) * raio, altura, math.sin(angulo) * raio)
			local cf = CFrame.lookAt(pos, pos + (pos - centro).Unit)
			peca.disco.CFrame = cf
			peca.aro.CFrame = cf
			peca.disco.Transparency = 0.1 + (1 - saida) * 0.9
			peca.aro.Transparency = 0.4 + (1 - saida) * 0.6
		end
	end)

	Debris:AddItem(pasta, duracao + 1)
end

--[[
	"DISCO_VOO" — o escudo arremessado.

	Trajetória determinística: origem, direção, velocidade, alcance. O cliente
	reproduz exatamente o que o servidor calcula para o dano, sem receber
	posição nenhuma. `volta = true` traz o disco de volta à mão.
]]
function VFX.DISCO_VOO(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end
	local frente = payload.frente
	if typeof(frente) ~= "Vector3" or frente.Magnitude < 0.001 then
		return
	end
	frente = frente.Unit

	local cor = lerCor(payload)
	local velocidade = tonumber(payload.velocidade) or 80
	local alcance = tonumber(payload.alcance) or 50
	local volta = payload.volta == true
	local tamanho = payload.tamanho
	if typeof(tamanho) ~= "Vector3" then
		tamanho = Vector3.new(3.0, 3.0, 0.26)
	end

	local disco, aro = novoDisco(cor, tamanho)
	disco.CFrame = CFrame.lookAt(payload.posicao, payload.posicao + frente)
	disco.Parent = workspace

	local percorrido = 0
	local giro = 0
	local voltando = false
	local conexao

	conexao = RunService.RenderStepped:Connect(function(dt)
		if not disco.Parent then
			conexao:Disconnect()
			return
		end

		local passo = velocidade * dt
		giro = giro + dt * 14
		local destino

		if not voltando then
			percorrido = percorrido + passo
			destino = disco.Position + frente * passo
			if percorrido >= alcance then
				if volta then
					voltando = true
				else
					conexao:Disconnect()
					VFX.ESTILHACO_ESCUDO({ posicao = disco.Position, cor = cor })
					disco.Parent = nil
					return
				end
			end
		else
			local mao = raizDoJogador(payload.userId)
			if not mao then
				conexao:Disconnect()
				disco.Parent = nil
				return
			end
			local paraMao = (mao.Position + Vector3.new(0, 1.2, 0)) - disco.Position
			if paraMao.Magnitude <= 3.0 then
				conexao:Disconnect()
				disco.Parent = nil
				return
			end
			destino = disco.Position + paraMao.Unit * passo
		end

		local cf = CFrame.lookAt(destino, destino + frente) * CFrame.Angles(0, 0, giro)
		disco.CFrame = cf
		aro.CFrame = cf
	end)

	Debris:AddItem(disco, (alcance / velocidade) * 3 + 1)
end

--[[
	"MARCA_ORBITAL" — o selo que flutua sobre o aliado vinculado.
	Mesma razão de estar aqui: girar isso no servidor entrega ~20 Hz.
]]
function VFX.MARCA_ORBITAL(payload)
	local raiz = raizDoJogador(payload.userId)
	if not raiz then
		return
	end

	local cor = lerCor(payload)
	local altura = tonumber(payload.altura) or 3
	local voltas = tonumber(payload.voltas) or 0.5
	local duracao = math.min(tonumber(payload.duracao) or 7, CFG.SEGURANCA_VIDA)

	local marca = novaParte(cor, Vector3.new(1.8, 1.8, 0.2), CFrame.new())
	marca.Transparency = 0.25
	marca.Parent = workspace

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local vivo = raizDoJogador(payload.userId)
		if not vivo or t >= duracao then
			conexao:Disconnect()
			marca.Parent = nil
			return
		end
		-- Bob senoidal por acumulador dt, nunca tick().
		local sobe = math.sin(t * 2.2) * 0.25
		marca.CFrame = CFrame.new(vivo.Position + Vector3.new(0, altura + sobe, 0))
			* CFrame.Angles(0, t * voltas * math.pi * 2, 0)
	end)

	Debris:AddItem(marca, duracao + 1)
end

--==============================================================================
-- DESPACHO — chamado pelo Client ao receber VFXRemote
--==============================================================================

function VFX.executar(tipo, payload)
	local efeito = VFX[tipo]
	if type(efeito) ~= "function" or tipo == "executar" then
		return
	end

	local ok, erro = pcall(efeito, payload or {})
	if not ok then
		warn("[VFXModule] efeito '" .. tostring(tipo) .. "' falhou: " .. tostring(erro))
	end
end

return VFX
