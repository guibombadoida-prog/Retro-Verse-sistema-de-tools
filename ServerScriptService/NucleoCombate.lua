--[[
	NucleoCombate  —  Script (NÃO ModuleScript) em ServerScriptService
	Retro-Verse / Studios  ·  REGRA 12 V3

	O Núcleo OBSERVA a Tool. A Tool não conhece o Núcleo.
	Nenhuma Tool precisa de require, de ModuleScript ou de qualquer edição de código:
	instalado este Script, toda Tool passa a receber crédito de abate, aumento, redução,
	escudo, recarga global e desconto de energia automaticamente (§12.3).

	A porta pública é _G.Combate, e toda chamada é OPCIONAL — a Tool sempre usa guarda:
		local final = _G.Combate and _G.Combate.calcular(jogador, alvo, 40) or 40

	NOME DO OBJETO: "NucleoCombate", SEM versão (§12.15). Os sistemas o procuram por esse nome.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--==============================================================================
-- CFG — bloco único no topo. Número mágico espalhado pelo corpo é violação (§12.10)
--==============================================================================

local VERSAO = "v3"

local CFG = {
	-- Atribuição de dano no modo observado (§12.8)
	JANELA_ATAQUE       = 1.20,   -- s desde Tool.Activated em que o dano ainda é atribuído
	ALCANCE_ATRIBUICAO  = 60,     -- studs entre atacante e alvo para o crédito valer

	-- Pipeline de dano (§12.5)
	TETO_AUMENTO        = 3.00,   -- +300% — aditivo
	TETO_REDUCAO        = 0.90,   -- −90%  — multiplicativo
	EPSILON             = 0.001,  -- ruído de ponto flutuante ao comparar vida

	-- Casamento do modo preciso (§12.6)
	JANELA_PRECISO      = 0.75,   -- s de validade de um dano pré-calculado
	TOLERANCIA_PRECISO  = 0.05,   -- diferença aceita entre o previsto e o observado

	-- Detecção em área (§12.6)
	LIMITE_ALVOS        = 25,

	-- Declarações da Tool (§12.4)
	CLASSE_PADRAO       = "Melee",
	NOME_ENERGIA        = "Energia",  -- NumberValue/IntValue no Player, leaderstats ou Character

	-- Manutenção
	INTERVALO_LIMPEZA   = 10,     -- s entre varreduras de registros expirados
}

--==============================================================================
-- ESTADO
--==============================================================================

local fraco = { __mode = "k" }

local estados     = setmetatable({}, fraco)  -- [Humanoid]   = { vida, corrigindo, conexoes }
local pendentes   = setmetatable({}, fraco)  -- [Humanoid]   = { {valor, contexto, expira} }
local ataques     = setmetatable({}, fraco)  -- [Player]     = { momento, tool, classe, personagem }
local escudos     = setmetatable({}, fraco)  -- [Character]  = { {pontos, expira} }
local reducoes    = setmetatable({}, fraco)  -- [Character]  = { [id] = {fracao, expira} }
local aumentos    = setmetatable({}, fraco)  -- [Character]  = { [id] = {fracao, expira} }
local recargas    = setmetatable({}, fraco)  -- [Player]     = { [chave] = expiraEm }
local travas      = setmetatable({}, fraco)  -- [Player]     = { [chave] = {conexoes de Tool} }
local toolsVistas = setmetatable({}, fraco)  -- [Tool]       = true

local modificadores = {}   -- [nome] = função(contexto) -> contribuição de aumento
local ouvintesDano  = {}   -- [id]   = função(contexto, danoFinal)

local proximoId = 0

local function novoId()
	proximoId = proximoId + 1
	return proximoId
end

local function agora()
	-- os.clock() é monotônico e nunca alimenta CFrame (§12.9 / §10.11.7)
	return os.clock()
end

--==============================================================================
-- UTILITÁRIOS DE PERSONAGEM
--==============================================================================

local function personagemDe(humanoide)
	if not humanoide then
		return nil
	end
	return humanoide.Parent
end

local function jogadorDe(humanoide)
	local personagem = personagemDe(humanoide)
	if not personagem then
		return nil
	end
	return Players:GetPlayerFromCharacter(personagem)
end

local function raizDe(personagem)
	if not personagem then
		return nil
	end
	return personagem:FindFirstChild("HumanoidRootPart")
end

local function temForceField(personagem)
	if not personagem then
		return false
	end
	return personagem:FindFirstChildOfClass("ForceField") ~= nil
end

--==============================================================================
-- §12.6 — REGISTROS (escudo, redução, aumento). Todo registro devolve o cancelamento
--==============================================================================

local function listaDe(tabela, personagem)
	local lista = tabela[personagem]
	if not lista then
		lista = {}
		tabela[personagem] = lista
	end
	return lista
end

local function registrarEscudo(personagem, pontos, duracao)
	if not personagem or type(pontos) ~= "number" or pontos <= 0 then
		return function() end
	end

	local entrada = {
		pontos = pontos,
		expira = duracao and (agora() + duracao) or nil,
	}
	local lista = listaDe(escudos, personagem)
	table.insert(lista, entrada)

	local cancelado = false
	return function()
		if cancelado then
			return
		end
		cancelado = true
		for indice = #lista, 1, -1 do
			if lista[indice] == entrada then
				table.remove(lista, indice)
			end
		end
	end
end

local function registrarFracao(tabela, personagem, fracao, duracao)
	if not personagem or type(fracao) ~= "number" or fracao == 0 then
		return function() end
	end

	local mapa = listaDe(tabela, personagem)
	local id = novoId()
	mapa[id] = {
		fracao = fracao,
		expira = duracao and (agora() + duracao) or nil,
	}

	local cancelado = false
	return function()
		if cancelado then
			return
		end
		cancelado = true
		mapa[id] = nil
	end
end

local function registrarReducao(personagem, fracao, duracao)
	return registrarFracao(reducoes, personagem, fracao, duracao)
end

local function registrarAumento(personagem, fracao, duracao)
	return registrarFracao(aumentos, personagem, fracao, duracao)
end

local function somarAumentos(personagem)
	local mapa = aumentos[personagem]
	if not mapa then
		return 0
	end

	local total = 0
	local instante = agora()
	for id, entrada in pairs(mapa) do
		if entrada.expira and instante >= entrada.expira then
			mapa[id] = nil
		else
			total = total + entrada.fracao
		end
	end
	return total
end

local function acumularReducao(personagem)
	-- Multiplicativo: três reduções de 40% dão 78,4%, nunca 120% (§12.5)
	local mapa = reducoes[personagem]
	if not mapa then
		return 0
	end

	local restante = 1
	local instante = agora()
	for id, entrada in pairs(mapa) do
		if entrada.expira and instante >= entrada.expira then
			mapa[id] = nil
		else
			local fracao = math.clamp(entrada.fracao, 0, 1)
			restante = restante * (1 - fracao)
		end
	end

	local reducao = 1 - restante
	if reducao > CFG.TETO_REDUCAO then
		reducao = CFG.TETO_REDUCAO
	end
	return reducao
end

local function consumirEscudo(personagem, dano)
	-- Escudo é HP paralelo: consome pontos em ordem, antes de a vida assentar (§12.5)
	local lista = escudos[personagem]
	if not lista or #lista == 0 or dano <= 0 then
		return dano
	end

	local instante = agora()
	local restante = dano
	local indice = 1

	while indice <= #lista do
		local entrada = lista[indice]
		if entrada.expira and instante >= entrada.expira then
			table.remove(lista, indice)
		else
			if restante <= 0 then
				indice = indice + 1
			else
				if entrada.pontos > restante then
					entrada.pontos = entrada.pontos - restante
					restante = 0
					indice = indice + 1
				else
					restante = restante - entrada.pontos
					table.remove(lista, indice)
				end
			end
		end
	end

	return restante
end

--==============================================================================
-- §12.5 — MODIFICADORES E OUVINTES. Registrados por SISTEMAS, nunca por Tool
--==============================================================================

local function registrarModificador(nome, funcao)
	if type(nome) ~= "string" or type(funcao) ~= "function" then
		warn("[NucleoCombate] registrarModificador exige (nome: string, funcao: function)")
		return function() end
	end
	if modificadores[nome] then
		warn("[NucleoCombate] modificador '" .. nome .. "' substituído")
	end

	modificadores[nome] = funcao
	return function()
		if modificadores[nome] == funcao then
			modificadores[nome] = nil
		end
	end
end

local function somarModificadores(contexto)
	local total = 0
	for nome, funcao in pairs(modificadores) do
		local ok, valor = pcall(funcao, contexto)
		if ok then
			if type(valor) == "number" then
				total = total + valor
			end
		else
			warn("[NucleoCombate] modificador '" .. nome .. "' falhou: " .. tostring(valor))
		end
	end
	return total
end

local function aoAplicarDano(funcao)
	if type(funcao) ~= "function" then
		return function() end
	end

	local id = novoId()
	ouvintesDano[id] = funcao
	return function()
		ouvintesDano[id] = nil
	end
end

local function avisarOuvintes(contexto, danoFinal)
	for id, funcao in pairs(ouvintesDano) do
		local ok, erro = pcall(funcao, contexto, danoFinal)
		if not ok then
			warn("[NucleoCombate] ouvinte de dano falhou: " .. tostring(erro))
		end
	end
end

--==============================================================================
-- §12.5 — PIPELINE DE DANO
--==============================================================================

local function montarContexto(jogador, humanoideAlvo, danoBruto)
	local ataque = jogador and ataques[jogador] or nil
	local personagemAtacante = ataque and ataque.personagem or (jogador and jogador.Character) or nil

	return {
		jogador            = jogador,
		personagemAtacante = personagemAtacante,
		humanoideAtacante  = personagemAtacante and personagemAtacante:FindFirstChildOfClass("Humanoid") or nil,
		humanoideAlvo      = humanoideAlvo,
		personagemAlvo     = personagemDe(humanoideAlvo),
		jogadorAlvo        = jogadorDe(humanoideAlvo),
		tool               = ataque and ataque.tool or nil,
		classe             = ataque and ataque.classe or CFG.CLASSE_PADRAO,
		danoBruto          = danoBruto,
	}
end

local function aplicarPipeline(contexto, danoBruto)
	if danoBruto <= 0 then
		return 0
	end

	-- 1. aumento: aditivo, com teto
	local aumento = 0
	if contexto.personagemAtacante then
		aumento = somarAumentos(contexto.personagemAtacante)
	end
	aumento = aumento + somarModificadores(contexto)
	if aumento > CFG.TETO_AUMENTO then
		aumento = CFG.TETO_AUMENTO
	end
	if aumento < -1 then
		aumento = -1
	end

	local dano = danoBruto * (1 + aumento)

	-- 2. redução do alvo: multiplicativa, com teto
	if contexto.personagemAlvo then
		local reducao = acumularReducao(contexto.personagemAlvo)
		dano = dano * (1 - reducao)
	end

	-- 3. escudo: consome pontos antes de a vida assentar
	if contexto.personagemAlvo then
		dano = consumirEscudo(contexto.personagemAlvo, dano)
	end

	if dano < 0 then
		dano = 0
	end
	return dano
end

--==============================================================================
-- §12.7 — CRÉDITO DE ABATE. A ORDEM DAS PROPRIEDADES NÃO É ESTILO
--==============================================================================

local function marcarCredito(humanoide, jogador)
	if not humanoide or not jogador then
		return
	end

	local anterior = humanoide:FindFirstChild("creator")
	if anterior then
		anterior.Parent = nil
	end

	local credito = Instance.new("ObjectValue")
	credito.Name = "creator"      -- 1º
	credito.Value = jogador       -- 2º
	credito.Parent = humanoide    -- 3º, SEMPRE por último

	Debris:AddItem(credito, CFG.JANELA_ATAQUE * 2)
end

--==============================================================================
-- §12.6 — MODO PRECISO
--==============================================================================

local function registrarPendente(humanoide, valor, contexto)
	local lista = pendentes[humanoide]
	if not lista then
		lista = {}
		pendentes[humanoide] = lista
	end

	table.insert(lista, {
		valor = valor,
		contexto = contexto,
		expira = agora() + CFG.JANELA_PRECISO,
	})
end

local function retirarPendente(humanoide, queda, morreu)
	local lista = pendentes[humanoide]
	if not lista then
		return nil
	end

	local instante = agora()
	local escolhido = nil
	local indice = 1

	while indice <= #lista do
		local entrada = lista[indice]
		if instante >= entrada.expira then
			table.remove(lista, indice)
		else
			-- No golpe fatal a vida trava em 0: a queda observada é MENOR que o valor
			-- previsto. Sem esta segunda condição, o abate no modo preciso não casaria,
			-- cairia no modo observado e a vida seria "corrigida" para cima.
			local casa = math.abs(entrada.valor - queda) <= CFG.TOLERANCIA_PRECISO
			if not casa and morreu then
				casa = entrada.valor >= queda - CFG.TOLERANCIA_PRECISO
			end

			if not escolhido and casa then
				escolhido = entrada
				table.remove(lista, indice)
			else
				indice = indice + 1
			end
		end
	end

	return escolhido
end

local function calcular(jogador, humanoideAlvo, danoBruto)
	if type(danoBruto) ~= "number" or danoBruto <= 0 then
		return 0
	end
	if not humanoideAlvo or not humanoideAlvo:IsA("Humanoid") then
		return danoBruto
	end

	local contexto = montarContexto(jogador, humanoideAlvo, danoBruto)
	local final = aplicarPipeline(contexto, danoBruto)

	-- O observador verá esta queda e não vai recalcular nem corrigir a vida.
	registrarPendente(humanoideAlvo, final, contexto)
	return final
end

--==============================================================================
-- ATRIBUIÇÃO DE ATACANTE — modo observado (§12.8)
--==============================================================================

local function podeCausarDano(jogador, humanoideAlvo, humanoideDono)
	if not humanoideAlvo or not humanoideAlvo:IsA("Humanoid") then
		return false
	end
	if humanoideAlvo.Health <= 0 then
		return false
	end
	if humanoideDono and humanoideAlvo == humanoideDono then
		return false
	end

	local personagemAlvo = personagemDe(humanoideAlvo)
	if not personagemAlvo then
		return false
	end
	if temForceField(personagemAlvo) then
		return false
	end

	local jogadorAlvo = Players:GetPlayerFromCharacter(personagemAlvo)
	if jogador and jogadorAlvo then
		if jogador == jogadorAlvo then
			return false
		end
		-- Times: aliado não recebe dano, salvo time Neutral
		if jogador.Team and jogadorAlvo.Team and jogador.Team == jogadorAlvo.Team then
			if not jogador.Neutral and not jogadorAlvo.Neutral then
				return false
			end
		end
	end

	return true
end

local function registrarAtaque(jogador, tool, classe)
	if not jogador then
		return
	end

	ataques[jogador] = {
		momento = agora(),
		tool = tool,
		classe = classe or CFG.CLASSE_PADRAO,
		personagem = jogador.Character,
	}
end

local function atribuirAtacante(humanoideAlvo)
	local personagemAlvo = personagemDe(humanoideAlvo)
	local raizAlvo = raizDe(personagemAlvo)
	if not raizAlvo then
		return nil
	end

	local instante = agora()
	local melhor = nil
	local melhorMomento = -math.huge

	for jogador, ataque in pairs(ataques) do
		if instante - ataque.momento <= CFG.JANELA_ATAQUE then
			local raizAtacante = raizDe(ataque.personagem)
			if raizAtacante and podeCausarDano(jogador, humanoideAlvo, nil) then
				local distancia = (raizAtacante.Position - raizAlvo.Position).Magnitude
				if distancia <= CFG.ALCANCE_ATRIBUICAO and ataque.momento > melhorMomento then
					melhor = jogador
					melhorMomento = ataque.momento
				end
			end
		end
	end

	return melhor
end

--==============================================================================
-- OBSERVAÇÃO DE HUMANOIDS — o Núcleo observa e corrige (§12.8)
--==============================================================================

local function finalizar(contexto, danoFinal)
	if contexto.jogador and contexto.humanoideAlvo then
		marcarCredito(contexto.humanoideAlvo, contexto.jogador)
	end
	avisarOuvintes(contexto, danoFinal)
end

local function aoMudarVida(humanoide, vidaNova)
	local estado = estados[humanoide]
	if not estado then
		return
	end

	if estado.corrigindo then
		estado.vida = vidaNova
		return
	end

	local vidaAntes = estado.vida
	estado.vida = vidaNova

	if vidaNova >= vidaAntes - CFG.EPSILON then
		return -- cura, ou a própria correção assentando
	end

	local queda = vidaAntes - vidaNova

	-- Modo preciso: a Tool já pediu o cálculo, a queda é o valor final. Só creditar e avisar.
	local pendente = retirarPendente(humanoide, queda, vidaNova <= 0)
	if pendente then
		finalizar(pendente.contexto, queda)
		return
	end

	-- Modo observado: descobrir quem foi, recalcular e corrigir a vida.
	local jogador = atribuirAtacante(humanoide)
	if not jogador then
		return -- dano ambiental, queda, NPC sem dono: o Núcleo não interfere
	end

	local contexto = montarContexto(jogador, humanoide, queda)
	local final = aplicarPipeline(contexto, queda)

	local alvo = math.clamp(vidaAntes - final, 0, humanoide.MaxHealth)
	if math.abs(alvo - vidaNova) > CFG.EPSILON then
		-- A vida já caiu: não há ForceField em jogo aqui, e este é o único caminho
		-- possível para corrigir para cima. Matar continua sendo só por TakeDamage (§12.7).
		estado.corrigindo = true
		humanoide.Health = alvo
		estado.corrigindo = false
		estado.vida = alvo
	end

	finalizar(contexto, final)
end

local function observarHumanoide(humanoide)
	if estados[humanoide] then
		return
	end

	local estado = {
		vida = humanoide.Health,
		corrigindo = false,
		conexoes = {},
	}
	estados[humanoide] = estado

	table.insert(estado.conexoes, humanoide.HealthChanged:Connect(function(vidaNova)
		aoMudarVida(humanoide, vidaNova)
	end))

	table.insert(estado.conexoes, humanoide.Died:Connect(function()
		local personagem = personagemDe(humanoide)
		if personagem then
			escudos[personagem] = nil
			reducoes[personagem] = nil
			aumentos[personagem] = nil
		end
	end))

	table.insert(estado.conexoes, humanoide.Destroying:Connect(function()
		for _, conexao in ipairs(estado.conexoes) do
			conexao:Disconnect()
		end
		estados[humanoide] = nil
		pendentes[humanoide] = nil
	end))
end

--==============================================================================
-- §12.9 — RECARGA GLOBAL. Registrada no JOGADOR, imune a clone na mochila
--==============================================================================

local function chaveDaTool(tool)
	local valor = tool:FindFirstChild("ChaveRecarga")
	if valor and valor:IsA("StringValue") and valor.Value ~= "" then
		return valor.Value
	end
	return tool.Name
end

local function recargaGlobal(jogador, chave, segundos)
	if not jogador or type(chave) ~= "string" then
		return true, 0
	end

	local mapa = recargas[jogador]
	if not mapa then
		mapa = {}
		recargas[jogador] = mapa
	end

	local instante = agora()
	local expira = mapa[chave]

	if expira and instante < expira then
		return false, expira - instante
	end

	if type(segundos) == "number" and segundos > 0 then
		mapa[chave] = instante + segundos
	end
	return true, 0
end

local function toolsComChave(jogador, chave)
	local encontradas = {}

	local function varrer(container)
		if not container then
			return
		end
		for _, filho in ipairs(container:GetChildren()) do
			if filho:IsA("Tool") and chaveDaTool(filho) == chave then
				table.insert(encontradas, filho)
			end
		end
	end

	varrer(jogador:FindFirstChildOfClass("Backpack"))
	varrer(jogador.Character)
	return encontradas
end

local function travarTools(jogador, chave, segundos)
	-- Trava o Enabled de TODAS as cópias e o mantém travado, mesmo que a Tool
	-- reabilite sozinha no debounce dela.
	local mapaTravas = travas[jogador]
	if not mapaTravas then
		mapaTravas = {}
		travas[jogador] = mapaTravas
	end
	if mapaTravas[chave] then
		return -- já travado
	end

	local conexoes = {}
	mapaTravas[chave] = conexoes

	local alvos = toolsComChave(jogador, chave)
	for _, tool in ipairs(alvos) do
		tool.Enabled = false
		table.insert(conexoes, tool:GetPropertyChangedSignal("Enabled"):Connect(function()
			if tool.Enabled then
				tool.Enabled = false
			end
		end))
	end

	task.delay(segundos, function()
		for _, conexao in ipairs(conexoes) do
			conexao:Disconnect()
		end
		mapaTravas[chave] = nil

		for _, tool in ipairs(toolsComChave(jogador, chave)) do
			if tool.Parent then
				tool.Enabled = true
			end
		end
	end)
end

--==============================================================================
-- CUSTO DE ENERGIA (§12.3)
--==============================================================================

local function fonteDeEnergia(jogador)
	local candidatos = {
		jogador,
		jogador:FindFirstChild("leaderstats"),
		jogador.Character,
	}

	for _, container in ipairs(candidatos) do
		if container then
			local valor = container:FindFirstChild(CFG.NOME_ENERGIA)
			if valor and (valor:IsA("NumberValue") or valor:IsA("IntValue")) then
				return valor
			end
		end
	end
	return nil
end

local function descontarEnergia(jogador, custo)
	if type(custo) ~= "number" or custo <= 0 then
		return
	end

	local valor = fonteDeEnergia(jogador)
	if not valor then
		return -- sem sistema de energia no place: nada a descontar
	end

	local novo = valor.Value - custo
	if novo < 0 then
		novo = 0
	end
	valor.Value = novo
end

--==============================================================================
-- DESCOBERTA DE TOOLS (§12.3) — pega gear de InsertService também
--==============================================================================

local function lerNumero(tool, nome)
	local valor = tool:FindFirstChild(nome)
	if valor and (valor:IsA("NumberValue") or valor:IsA("IntValue")) then
		return valor.Value
	end
	return nil
end

local function lerClasse(tool)
	local valor = tool:FindFirstChild("DamageClass")
	if valor and valor:IsA("StringValue") and valor.Value ~= "" then
		return valor.Value
	end
	return CFG.CLASSE_PADRAO
end

local function registrarTool(tool, jogador)
	if toolsVistas[tool] then
		return
	end
	toolsVistas[tool] = true

	local conexoes = {}

	table.insert(conexoes, tool.Activated:Connect(function()
		local dono = Players:GetPlayerFromCharacter(tool.Parent) or jogador
		if not dono then
			return
		end

		registrarAtaque(dono, tool, lerClasse(tool))

		local custo = lerNumero(tool, "EnergyCost")
		if custo then
			descontarEnergia(dono, custo)
		end

		local recarga = lerNumero(tool, "RecargaGlobal")
		if recarga and recarga > 0 then
			local chave = chaveDaTool(tool)
			local liberado = recargaGlobal(dono, chave, recarga)
			if liberado then
				travarTools(dono, chave, recarga)
			end
		end
	end))

	table.insert(conexoes, tool.Destroying:Connect(function()
		for _, conexao in ipairs(conexoes) do
			conexao:Disconnect()
		end
		toolsVistas[tool] = nil
	end))
end

local function observarContainer(container, jogador)
	if not container then
		return
	end

	for _, filho in ipairs(container:GetChildren()) do
		if filho:IsA("Tool") then
			registrarTool(filho, jogador)
		end
	end

	container.ChildAdded:Connect(function(filho)
		if filho:IsA("Tool") then
			registrarTool(filho, jogador)
		end
	end)
end

local function observarJogador(jogador)
	local backpack = jogador:FindFirstChildOfClass("Backpack")
	if backpack then
		observarContainer(backpack, jogador)
	end

	jogador.ChildAdded:Connect(function(filho)
		if filho:IsA("Backpack") then
			observarContainer(filho, jogador)
		end
	end)

	local function aoNascer(personagem)
		observarContainer(personagem, jogador)

		local humanoide = personagem:FindFirstChildOfClass("Humanoid")
		if not humanoide then
			humanoide = personagem:WaitForChild("Humanoid", 5)
		end
		if humanoide then
			observarHumanoide(humanoide)
		end

		-- Personagem novo: registros do anterior morrem com ele
		ataques[jogador] = nil
	end

	if jogador.Character then
		aoNascer(jogador.Character)
	end
	jogador.CharacterAdded:Connect(aoNascer)

	jogador.CharacterRemoving:Connect(function(personagem)
		escudos[personagem] = nil
		reducoes[personagem] = nil
		aumentos[personagem] = nil
	end)
end

--==============================================================================
-- §12.6 — DETECÇÃO EM ÁREA. Substitui Instance.new("Explosion")
--==============================================================================

local function detectarHumanoides(posicao, raio, ignorar, jogador, humanoideDono, limite)
	local encontrados = {}
	if typeof(posicao) ~= "Vector3" or type(raio) ~= "number" or raio <= 0 then
		return encontrados
	end

	local parametros = OverlapParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Exclude
	if typeof(ignorar) == "Instance" then
		parametros.FilterDescendantsInstances = { ignorar }
	elseif type(ignorar) == "table" then
		parametros.FilterDescendantsInstances = ignorar
	end

	local teto = limite or CFG.LIMITE_ALVOS
	local partes = workspace:GetPartBoundsInRadius(posicao, raio, parametros)
	local jaVistos = {}

	for _, parte in ipairs(partes) do
		if #encontrados < teto then
			local modelo = parte:FindFirstAncestorOfClass("Model")
			if modelo then
				local humanoide = modelo:FindFirstChildOfClass("Humanoid")
				if humanoide and not jaVistos[humanoide] then
					jaVistos[humanoide] = true
					if podeCausarDano(jogador, humanoide, humanoideDono) then
						table.insert(encontrados, humanoide)
					end
				end
			end
		end
	end

	return encontrados
end

--==============================================================================
-- §12.11 — VFX: O SERVIDOR TRANSMITE, NUNCA EMITE
--==============================================================================

local function payloadLimpo(payload, profundidade)
	if type(payload) ~= "table" then
		return true
	end
	if profundidade > 2 then
		return true
	end

	for chave, valor in pairs(payload) do
		if typeof(valor) == "Instance" then
			warn("[NucleoCombate] transmitirVFX: payload contém Instance em '" .. tostring(chave) ..
				"'. Payload é DADO, nunca Instance (§12.11). Campo removido.")
			payload[chave] = nil
		elseif type(valor) == "table" then
			payloadLimpo(valor, profundidade + 1)
		end
	end
	return true
end

local function transmitirVFX(remote, tipo, payload)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[NucleoCombate] transmitirVFX exige um RemoteEvent")
		return
	end
	if type(tipo) ~= "string" then
		warn("[NucleoCombate] transmitirVFX exige um tipo string, ex.: \"IMPACTO_NOVA\"")
		return
	end

	local dados = payload or {}
	payloadLimpo(dados, 1)
	remote:FireAllClients(tipo, dados)
end

--==============================================================================
-- MANUTENÇÃO
--==============================================================================

local function limpar()
	local instante = agora()

	for jogador, mapa in pairs(recargas) do
		for chave, expira in pairs(mapa) do
			if instante >= expira then
				mapa[chave] = nil
			end
		end
		if jogador.Parent == nil then
			recargas[jogador] = nil
		end
	end

	for jogador, ataque in pairs(ataques) do
		if instante - ataque.momento > CFG.JANELA_ATAQUE then
			ataques[jogador] = nil
		end
	end

	for humanoide, lista in pairs(pendentes) do
		for indice = #lista, 1, -1 do
			if instante >= lista[indice].expira then
				table.remove(lista, indice)
			end
		end
		if #lista == 0 then
			pendentes[humanoide] = nil
		end
	end
end

--==============================================================================
-- PORTA PÚBLICA — _G.Combate (§12.2)
--==============================================================================

_G.Combate = {
	versao = VERSAO,

	-- §12.6 modo preciso
	calcular            = calcular,
	podeCausarDano      = podeCausarDano,
	detectarHumanoides  = detectarHumanoides,

	-- §12.9 recarga
	recargaGlobal       = recargaGlobal,

	-- §12.6 registros — todos devolvem a função de cancelamento
	registrarEscudo     = registrarEscudo,
	registrarReducao    = registrarReducao,
	registrarAumento    = registrarAumento,

	-- §12.5 regra global — para SISTEMAS, nunca para Tools
	registrarModificador = registrarModificador,
	aoAplicarDano        = aoAplicarDano,

	-- §12.8 dano de habilidade que não passa por Tool.Activated
	registrarAtaque     = registrarAtaque,

	-- §12.11 VFX
	transmitirVFX       = transmitirVFX,
}

--==============================================================================
-- INICIALIZAÇÃO
--==============================================================================

for _, jogador in ipairs(Players:GetPlayers()) do
	observarJogador(jogador)
end
Players.PlayerAdded:Connect(observarJogador)

Players.PlayerRemoving:Connect(function(jogador)
	ataques[jogador] = nil
	recargas[jogador] = nil
	travas[jogador] = nil
end)

-- Humanoids de NPC e de qualquer modelo que entre no workspace
for _, descendente in ipairs(workspace:GetDescendants()) do
	if descendente:IsA("Humanoid") then
		observarHumanoide(descendente)
	end
end

workspace.DescendantAdded:Connect(function(descendente)
	if descendente:IsA("Humanoid") then
		observarHumanoide(descendente)
	end
end)

task.spawn(function()
	while true do
		task.wait(CFG.INTERVALO_LIMPEZA)
		limpar()
	end
end)

print("[NucleoCombate] _G.Combate pronto — " .. VERSAO)
