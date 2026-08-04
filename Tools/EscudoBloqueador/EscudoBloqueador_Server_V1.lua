--[[
	EscudoBloqueador_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Convertido de `Escudo Bloqueador`, do modelo Danilo_Escudos.

	O QUE A ORIGEM FAZIA, E O QUE MUDOU
		A origem conectava HealthChanged e CORRIGIA a vida para cima quando o
		dano passava: `hum.Health = math.min(MaxHealth, hp + reducedDamage)`.
		Isso é escrever vida direto, ignora ForceField e briga com qualquer
		outro sistema de dano do place. Aqui a redução é REGISTRADA no Núcleo
		(§12.5), que a aplica antes de a vida assentar — o mesmo efeito, pela
		porta certa.

		Números da origem preservados: 25% de redução ao portador, 15% de
		reflexão ao atacante, 15% para aliados no raio 10, e a barreira ativa
		com 52% de reflexão, raio 15, empurrão 90, recarga 8 s.

	PRIMÁRIA (Tool.Activated)  postura de bloqueio: reduz o dano recebido e
	                           devolve parte ao atacante enquanto durar
	EXTRA (X, via AcaoRemote)  barreira em cúpula: protege aliados no raio e
	                           empurra quem estiver colado
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:WaitForChild("AcaoRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "DEFENSOR"

local CFG = {
	NOME = "EscudoBloqueador",

	-- PRIMÁRIA — postura de bloqueio
	BLOQUEIO_DURACAO   = 4.0,
	BLOQUEIO_REDUCAO   = 0.25,   -- 25% — o valor da origem
	BLOQUEIO_REFLEXO   = 0.15,   -- 15% do dano volta para quem bateu
	BLOQUEIO_RECARGA   = 1.2,

	-- ALIADOS — o escudo cobre quem está perto
	ALIADO_ALCANCE     = 10,
	ALIADO_REDUCAO     = 0.15,

	-- EXTRA — barreira em cúpula
	BARREIRA_ALCANCE   = 15,
	BARREIRA_DURACAO   = 4.0,
	BARREIRA_REDUCAO   = 0.52,   -- 52% — o valor da origem
	BARREIRA_EMPURRAO  = 90,
	BARREIRA_RECARGA   = 8,

	COR_VFX      = Color3.fromRGB(0, 122, 190),
	COR_REFLEXO  = Color3.fromRGB(255, 90, 40),
	ESCALA_VFX   = 1.0,

	SFX_BLOQUEIO = "Bloqueio",
	SFX_REFLEXO  = "Reflexo",
	SFX_BARREIRA = "Barreira",

	CHAVE_EXTRA  = "EscudoBloqueador_X",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local cancelamentos = {}
local bloqueando = false
local ultimaBarreira = 0

-- O V2 encadeia a sequência sozinho, por Tween.Completed. Passar o NOME da
-- sequência é o contrato; encadear com task.wait aqui somaria ~1 frame por beat.
local function tocarSequencia(nome)
	if not animador or not nome then
		return
	end
	animador:PlaySequence(nome)
end

local function guardarCancelamento(cancelar)
	if type(cancelar) == "function" then
		table.insert(cancelamentos, cancelar)
	end
end

local function limparCancelamentos()
	for _, cancelar in ipairs(cancelamentos) do
		pcall(cancelar)
	end
	table.clear(cancelamentos)
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

local function transmitir(tipo, posicao, escala, cor)
	if _G.Combate and _G.Combate.transmitirVFX then
		_G.Combate.transmitirVFX(VFXRemote, tipo, {
			posicao = posicao,
			escala = escala or CFG.ESCALA_VFX,
			cor = cor or CFG.COR_VFX,
		})
		return
	end
	-- Sem o Núcleo, a Tool ainda desenha: transmite para todo mundo.
	VFXRemote:FireAllClients(tipo, {
		posicao = posicao,
		escala = escala or CFG.ESCALA_VFX,
		cor = cor or CFG.COR_VFX,
	})
end

local function humanoidesEmArea(posicao, raio, meuPersonagem)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(posicao, raio, meuPersonagem) or {}
	end

	-- Fallback sem Núcleo: varredura por Players, sem ler o workspace.
	local achados = {}
	for _, outro in ipairs(Players:GetPlayers()) do
		local personagem = outro.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
		if humanoide and raiz and humanoide.Health > 0 and personagem ~= meuPersonagem then
			if (raiz.Position - posicao).Magnitude <= raio then
				table.insert(achados, humanoide)
			end
		end
	end
	return achados
end

local function ehAliado(jogador, humanoide)
	local personagem = humanoide.Parent
	local outro = personagem and Players:GetPlayerFromCharacter(personagem)
	if not outro then
		return false
	end
	if outro == jogador then
		return true
	end
	if jogador.Team ~= nil and outro.Team ~= nil then
		return jogador.Team == outro.Team
	end
	return false
end

--==============================================================================
-- PRIMÁRIA — postura de bloqueio
--==============================================================================

local function bloquear(jogador, personagem, humanoide, raiz)
	if bloqueando then
		return
	end
	bloqueando = true

	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_BLOQUEIO, raiz.Position)
	transmitir("ESCUDO", raiz.Position + Vector3.new(0, 1, 0), CFG.ESCALA_VFX)
	transmitir("CLARAO_ESCUDO", raiz.Position + Vector3.new(0, 1, 0), CFG.ESCALA_VFX)

	-- A redução vai pelo Núcleo, que a aplica ANTES de a vida assentar (§12.5).
	-- A origem corrigia a vida para cima depois do dano; isso ignora ForceField.
	if _G.Combate and _G.Combate.registrarReducao then
		guardarCancelamento(_G.Combate.registrarReducao(
			humanoide, CFG.BLOQUEIO_REDUCAO, CFG.BLOQUEIO_DURACAO, "Escudo_Bloqueio"))
	end

	-- Reflexão: o Núcleo avisa quando o portador toma dano, e devolvemos parte.
	if _G.Combate and _G.Combate.aoAplicarDano then
		guardarCancelamento(_G.Combate.aoAplicarDano(humanoide, function(entrada)
			if not bloqueando then
				return
			end
			local atacante = entrada and entrada.atacante
			if not atacante or atacante == humanoide then
				return
			end
			local devolvido = (entrada.valor or 0) * CFG.BLOQUEIO_REFLEXO
			if devolvido <= 0 then
				return
			end
			if _G.Combate and _G.Combate.registrarAtaque then
				_G.Combate.registrarAtaque(jogador, atacante, devolvido, ARQUETIPO)
			else
				atacante:TakeDamage(devolvido)
			end
			local alvoRaiz = atacante.Parent
				and atacante.Parent:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				tocarSom(CFG.SFX_REFLEXO, alvoRaiz.Position)
				transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.8, CFG.COR_REFLEXO)
			end
		end))
	end

	-- Aliados no raio ganham uma fração da mesma redução.
	if _G.Combate and _G.Combate.registrarReducao then
		for _, alvo in ipairs(humanoidesEmArea(raiz.Position, CFG.ALIADO_ALCANCE, personagem)) do
			if ehAliado(jogador, alvo) then
				guardarCancelamento(_G.Combate.registrarReducao(
					alvo, CFG.ALIADO_REDUCAO, CFG.BLOQUEIO_DURACAO, "Escudo_Aliado"))
			end
		end
	end

	task.delay(CFG.BLOQUEIO_DURACAO, function()
		bloqueando = false
		limparCancelamentos()
		if animador then
			animador:PlaySequence(Poses.repouso())
		end
	end)
end

--==============================================================================
-- EXTRA — barreira em cúpula
--==============================================================================

local function barreira(jogador, personagem, humanoide, raiz)
	local agora = os.clock()
	if agora - ultimaBarreira < CFG.BARREIRA_RECARGA then
		return
	end

	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_EXTRA, CFG.BARREIRA_RECARGA) then
			return
		end
	end
	ultimaBarreira = agora

	tocarSequencia(Poses.extra())
	tocarSom(CFG.SFX_BARREIRA, raiz.Position)
	transmitir("ONDA_ESCUDO", raiz.Position, 1.4)
	transmitir("AURA", raiz.Position + Vector3.new(0, 2, 0), 1.6)
	transmitir("ESCUDO", raiz.Position + Vector3.new(0, 3, 0), 2.2)

	for _, alvo in ipairs(humanoidesEmArea(raiz.Position, CFG.BARREIRA_ALCANCE, personagem)) do
		if ehAliado(jogador, alvo) then
			if _G.Combate and _G.Combate.registrarReducao then
				guardarCancelamento(_G.Combate.registrarReducao(
					alvo, CFG.BARREIRA_REDUCAO, CFG.BARREIRA_DURACAO, "Escudo_Barreira"))
			end
		else
			-- Inimigo colado leva empurrão. Sem dano: a barreira é defensiva.
			local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
			if alvoRaiz then
				local direcao = alvoRaiz.Position - raiz.Position
				if direcao.Magnitude > 0.001 then
					local empurrao = Instance.new("BodyVelocity")
					empurrao.MaxForce = Vector3.new(1e5, 1e5, 1e5)
					empurrao.Velocity = direcao.Unit * CFG.BARREIRA_EMPURRAO
						+ Vector3.new(0, 20, 0)
					empurrao.Parent = alvoRaiz
					Debris:AddItem(empurrao, 0.18)
					transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.9)
				end
			end
		end
	end

	-- A redução do portador também sobe durante a barreira.
	if _G.Combate and _G.Combate.registrarReducao then
		guardarCancelamento(_G.Combate.registrarReducao(
			humanoide, CFG.BARREIRA_REDUCAO, CFG.BARREIRA_DURACAO, "Escudo_Barreira"))
	end
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

	tool.Enabled = false
	bloquear(jogador, personagem, humanoide, raiz)
	task.delay(CFG.BLOQUEIO_RECARGA, function()
		tool.Enabled = true
	end)
end)

acaoRemote.OnServerEvent:Connect(function(quemPediu)
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador or quemPediu ~= jogador then
		return
	end
	barreira(jogador, personagem, humanoide, raiz)
end)

local function desmontar()
	bloqueando = false
	limparCancelamentos()
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
