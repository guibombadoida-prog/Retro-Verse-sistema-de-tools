--[[
	EscudoSalvador_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Convertido de `Salvador`, do modelo Danilo_Escudos.

	O QUE MUDOU NA CONVERSÃO — e é o caso mais grave do modelo
		A origem fazia isto, dentro de um HealthChanged do aliado:

			targetHumanoid.Health = oldHealth        -- desfaz o dano do aliado
			humanoid:TakeDamage(damageTaken)         -- e joga em você

		Escrever `Health` direto ignora ForceField, ignora qualquer redução
		registrada, e briga com todo outro sistema de dano do place. Pior:
		`oldHealth` era lido DEPOIS do dano em alguns caminhos, então às vezes
		curava o aliado acima do que ele tinha.

		Aqui o mesmo efeito sai pelo Núcleo: `registrarReducao` no aliado leva
		a redução a 100% (ele não toma nada), e `aoAplicarDano` avisa quanto
		seria — esse valor é aplicado no portador por `registrarAtaque`. O dano
		nunca chega a assentar no aliado, então não há o que desfazer.

		Números da origem preservados: 7 s de duração, 50 de distância máxima,
		10 s de recarga.

	PRIMÁRIA (Tool.Activated)  vincula ao aliado mais próximo. Por 7 s, o dano
	                           que ele tomaria vem para você
	Sem Extra — a Tool tem um propósito e ele é caro o bastante.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "SALVADOR"

local CFG = {
	NOME = "EscudoSalvador",

	DURACAO       = 7.0,
	RECARGA       = 10,
	DISTANCIA_MAXIMA = 50,

	-- O vínculo quebra se o aliado se afastar demais. Sem isso, dava para
	-- proteger alguém do outro lado do mapa.
	VERIFICACAO_INTERVALO = 0.3,

	-- Escudo que flutua sobre o aliado, marcando o vínculo.
	MARCA_ALTURA  = 3.0,
	MARCA_VOLTAS  = 0.48,
	MARCA_TAMANHO = Vector3.new(1.8, 1.8, 0.2),

	COR_VFX     = Color3.fromRGB(255, 50, 50),
	COR_VINCULO = Color3.fromRGB(255, 120, 120),
	ESCALA_VFX  = 1.0,

	SFX_VINCULO       = "Vinculo",
	SFX_TRANSFERENCIA = "Transferencia",

	CHAVE_PRIMARIA = "EscudoSalvador_Primaria",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local vinculo = nil     -- { alvo, marca, conexao, cancelamentos }

local function tocarSequencia(nome)
	if not animador or not nome then
		return
	end
	animador:PlaySequence(nome)
end

--==============================================================================
-- AUXILIARES
--==============================================================================

local function tocarSom(nome, posicao)
	local original = pastaSFX:FindFirstChild(nome)
	if not original then
		return
	end

	local som = original:Clone()
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.CFrame = CFrame.new(posicao)
	ancora.Parent = workspace

	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora, som.TimeLength + 0.5)
end

local function transmitir(tipo, posicao, escala, cor, frente)
	local payload = {
		posicao = posicao,
		escala = escala or CFG.ESCALA_VFX,
		cor = cor or CFG.COR_VFX,
		frente = frente,
	}
	if _G.Combate and _G.Combate.transmitirVFX then
		_G.Combate.transmitirVFX(VFXRemote, tipo, payload)
		return
	end
	VFXRemote:FireAllClients(tipo, payload)
end

-- Aliado mais próximo: mesma equipe, vivo, dentro da distância. Nunca você.
local function escolherAliado(jogador, personagem, raiz)
	local melhor, melhorDistancia = nil, math.huge
	for _, outro in ipairs(Players:GetPlayers()) do
		if outro ~= jogador then
			local mesmaEquipe = (jogador.Team ~= nil and outro.Team ~= nil
				and jogador.Team == outro.Team)
			if mesmaEquipe then
				local alvoPersonagem = outro.Character
				local alvoHum = alvoPersonagem
					and alvoPersonagem:FindFirstChildOfClass("Humanoid")
				local alvoRaiz = alvoPersonagem
					and alvoPersonagem:FindFirstChild("HumanoidRootPart")
				if alvoHum and alvoRaiz and alvoHum.Health > 0 then
					local distancia = (alvoRaiz.Position - raiz.Position).Magnitude
					if distancia <= CFG.DISTANCIA_MAXIMA and distancia < melhorDistancia then
						melhor, melhorDistancia = alvoHum, distancia
					end
				end
			end
		end
	end
	return melhor
end

--==============================================================================
-- O VÍNCULO
--==============================================================================

local function romper()
	if not vinculo then
		return
	end
	if vinculo.conexao then
		vinculo.conexao:Disconnect()
		vinculo.conexao = nil
	end
	for _, cancelar in ipairs(vinculo.cancelamentos or {}) do
		pcall(cancelar)
	end
	if vinculo.marca then
		vinculo.marca.Parent = nil
	end
	vinculo = nil
end

local function vincular(jogador, personagem, humanoide, raiz)
	local aliado = escolherAliado(jogador, personagem, raiz)
	if not aliado then
		return false
	end

	romper()

	local aliadoRaiz = aliado.Parent and aliado.Parent:FindFirstChild("HumanoidRootPart")
	if not aliadoRaiz then
		return false
	end

	local marca = Instance.new("Part")
	marca.Name = "MarcaDoSalvador"
	marca.Anchored = true
	marca.CanCollide = false
	marca.CanQuery = false
	marca.CanTouch = false
	marca.CastShadow = false
	marca.Material = Enum.Material.Neon
	marca.Color = CFG.COR_VINCULO
	marca.Transparency = 0.25
	marca.Size = CFG.MARCA_TAMANHO
	marca.Parent = workspace

	vinculo = { alvo = aliado, marca = marca, cancelamentos = {} }

	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_VINCULO, raiz.Position)
	transmitir("CLARAO_ESCUDO", raiz.Position + Vector3.new(0, 2, 0), 1.2)
	transmitir("AURA", aliadoRaiz.Position + Vector3.new(0, 2, 0), 1.3)
	transmitir("ESTILHACO_ESTELAR", aliadoRaiz.Position, 1.0)

	-- 1. O aliado para de tomar dano: redução total, pelo Núcleo.
	if _G.Combate and _G.Combate.registrarReducao then
		table.insert(vinculo.cancelamentos, _G.Combate.registrarReducao(
			aliado, 1.0, CFG.DURACAO, "Escudo_Salvador"))
	end

	-- 2. O que ele TERIA tomado vem para o portador. O Núcleo avisa o valor
	--    antes de a vida assentar — não há dano para desfazer depois.
	if _G.Combate and _G.Combate.aoAplicarDano then
		table.insert(vinculo.cancelamentos, _G.Combate.aoAplicarDano(aliado, function(entrada)
			if not vinculo then
				return
			end
			local valor = entrada and entrada.valor or 0
			if valor <= 0 then
				return
			end
			if _G.Combate and _G.Combate.registrarAtaque then
				_G.Combate.registrarAtaque(entrada.atacanteJogador or jogador,
					humanoide, valor, ARQUETIPO)
			else
				humanoide:TakeDamage(valor)
			end
			tocarSom(CFG.SFX_TRANSFERENCIA, raiz.Position)
			transmitir("IMPACTO_ESCUDO", raiz.Position + Vector3.new(0, 1.5, 0), 0.7)
		end))
	end

	local t = 0
	local desdeVerificacao = 0

	vinculo.conexao = RunService.Heartbeat:Connect(function(dt)
		if not vinculo then
			return
		end
		t = t + dt
		if t >= CFG.DURACAO then
			romper()
			if animador then
				animador:PlaySequence(Poses.repouso())
			end
			return
		end

		local vivoAliado = vinculo.alvo and vinculo.alvo.Parent
			and vinculo.alvo.Parent:FindFirstChild("HumanoidRootPart")
		if not (vivoAliado and raiz and raiz.Parent and humanoide.Health > 0) then
			romper()
			return
		end

		-- Marca flutuando e girando sobre o aliado.
		local centro = vivoAliado.Position + Vector3.new(0, CFG.MARCA_ALTURA, 0)
		vinculo.marca.CFrame = CFrame.new(centro)
			* CFrame.Angles(0, t * CFG.MARCA_VOLTAS * math.pi * 2, 0)

		desdeVerificacao = desdeVerificacao + dt
		if desdeVerificacao < CFG.VERIFICACAO_INTERVALO then
			return
		end
		desdeVerificacao = 0

		-- Longe demais: o vínculo cai. Sem isto, dava para proteger alguém do
		-- outro lado do mapa e nunca correr risco.
		if (vivoAliado.Position - raiz.Position).Magnitude > CFG.DISTANCIA_MAXIMA then
			transmitir("ESTILHACO_ESCUDO", centro, 0.9)
			romper()
		end
	end)

	return true
end

--==============================================================================
-- LIGAÇÃO COM A TOOL
--==============================================================================

local function contexto()
	local personagem = tool.Parent
	local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	local jogador = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz and jogador) then
		return nil
	end
	if humanoide.Health <= 0 then
		return nil
	end
	return jogador, personagem, humanoide, raiz
end

tool.Activated:Connect(function()
	if not tool.Enabled then
		return
	end
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador then
		return
	end

	-- Sem aliado no alcance, a Tool não gasta recarga: o vínculo é a habilidade.
	if not vincular(jogador, personagem, humanoide, raiz) then
		return
	end

	if _G.Combate and _G.Combate.recargaGlobal then
		_G.Combate.recargaGlobal(jogador, CFG.CHAVE_PRIMARIA, CFG.RECARGA)
	end

	tool.Enabled = false
	task.delay(CFG.RECARGA, function()
		tool.Enabled = true
	end)
end)

local function desmontar()
	romper()
	if animador then
		animador:Destroy()
		animador = nil
	end
end

tool.Equipped:Connect(function()
	local personagem = tool.Parent
	if not personagem then
		return
	end
	animador = Animator.new(personagem, CFG.NOME, Poses.POSES, Poses.SEQUENCIAS)
	if animador then
		animador:PlaySequence(Poses.repouso())
	end

	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then
		humanoide.Died:Connect(desmontar)
	end
end)

tool.Unequipped:Connect(desmontar)
tool.Destroying:Connect(desmontar)
