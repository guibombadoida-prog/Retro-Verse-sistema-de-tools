--[[
	EscudoCiclone_Server_V1  —  Script, filho direto da Tool
	Retro-Verse / Studios  ·  REGRA 12 V3 · Regra nº 1

	Habilidade AUTORAL. Não vem de modelo nenhum — foi pedida assim:
	"invocar 5 escudos em volta do personagem que fica girando puxando os
	jogadores."

	PRIMÁRIA (Tool.Activated)  cinco escudos orbitam o portador e PUXAM para
	                           dentro quem entrar no raio, por 8 s
	EXTRA (X, via AcaoRemote)  colapsa o ciclone: os cinco convergem no centro
	                           de uma vez, com dano em área

	COMO O PUXÃO FUNCIONA, E POR QUE ASSIM
		Puxar é escrever velocidade no alvo todo frame. Fazer isso com
		`AssemblyLinearVelocity` direto briga com o Humanoid do alvo, que
		também escreve — o mesmo erro de dois donos que bugou a animação R6.
		Aqui o puxão é um BodyVelocity de vida curta, renovado a cada pulso:
		o Humanoid continua dono do movimento, e o puxão é uma força somada.

		O puxão é RADIAL e não vertical. Levantar o alvo do chão tiraria o
		controle dele por completo; puxar no plano deixa ele lutando contra,
		que é o que faz a habilidade ser interessante em vez de ser um stun.

	POSIÇÃO DOS CINCO
		Ângulo fixo de 72° entre escudos (360/5), com a fase avançando por
		acumulador dt. Sem math.random: dois usos seguidos dão a mesma órbita.
--]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local tool = script.Parent
local Poses = require(tool:WaitForChild("Poses"))
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))
local VFXRemote = tool:WaitForChild("VFXRemote")
local acaoRemote = tool:WaitForChild("AcaoRemote")
local pastaSFX = tool:WaitForChild("SFX")

--==============================================================================
-- CFG — número mágico solto no corpo do script é violação (§10)
--==============================================================================

local ARQUETIPO = "CONTROLADOR"

local CFG = {
	NOME = "EscudoCiclone",

	-- OS CINCO
	ESCUDOS         = 5,
	ORBITA_RAIO     = 7.5,
	ORBITA_ALTURA   = 2.5,
	ORBITA_VOLTAS   = 1.15,   -- voltas por segundo
	ESCUDO_TAMANHO  = Vector3.new(3.0, 3.0, 0.26),

	-- DURAÇÃO E PUXÃO
	DURACAO         = 8.0,
	PUXAO_ALCANCE   = 22,
	PUXAO_FORCA     = 46,
	PUXAO_INTERVALO = 0.20,   -- de quanto em quanto tempo o puxão é renovado
	PUXAO_VIDA      = 0.26,   -- > INTERVALO, para o puxão não piscar entre pulsos
	PUXAO_MINIMO    = 3.5,    -- dentro disso não puxa: o alvo já chegou

	-- ROÇAR NO ESCUDO
	ROCAR_RAIO      = 3.2,
	ROCAR_DANO      = 9,
	ROCAR_ESPERA    = 0.7,    -- recarga por alvo, para não virar moedor

	-- EXTRA — colapso
	COLAPSO_DANO     = 62,
	COLAPSO_ALCANCE  = 14,
	COLAPSO_EMPURRAO = 70,
	COLAPSO_RECARGA  = 14,

	RECARGA_BASE = 1.0,

	COR_VFX     = Color3.fromRGB(0, 122, 190),
	COR_COLAPSO = Color3.fromRGB(96, 205, 255),
	ESCALA_VFX  = 1.0,

	SFX_CICLONE  = "Ciclone",
	SFX_PUXAO    = "Puxao",
	SFX_COLAPSO  = "Colapso",

	CHAVE_PRIMARIA = "EscudoCiclone_Primaria",
	CHAVE_EXTRA    = "EscudoCiclone_X",
}

--==============================================================================
-- ESTADO LOCAL DA TOOL
--==============================================================================

local animador = nil
local ciclone = nil        -- { pasta, escudos, conexao, ativo }
local ultimaCarga = {}     -- humanoide -> os.clock() do último roçar
local ultimoColapso = 0

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

local function humanoidesEmArea(posicao, raio, meuPersonagem)
	if _G.Combate and _G.Combate.detectarHumanoides then
		return _G.Combate.detectarHumanoides(posicao, raio, meuPersonagem) or {}
	end

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

local function podeAtingir(jogador, alvo)
	if _G.Combate and _G.Combate.podeCausarDano then
		return _G.Combate.podeCausarDano(jogador, alvo)
	end
	return true
end

local function aplicarDano(jogador, alvo, valor)
	if not podeAtingir(jogador, alvo) then
		return
	end
	if _G.Combate and _G.Combate.registrarAtaque then
		_G.Combate.registrarAtaque(jogador, alvo, valor, ARQUETIPO)
		return
	end
	alvo:TakeDamage(valor)
end

--==============================================================================
-- OS CINCO ESCUDOS
--==============================================================================

local function novoEscudo(indice)
	local escudo = Instance.new("Part")
	escudo.Name = "EscudoOrbital" .. indice
	escudo.Anchored = true
	escudo.CanCollide = false
	escudo.CanQuery = false
	escudo.CanTouch = false
	escudo.CastShadow = false
	escudo.Material = Enum.Material.Metal
	escudo.Color = CFG.COR_VFX
	escudo.Reflectance = 0.35
	escudo.Transparency = 0.1
	escudo.Size = CFG.ESCUDO_TAMANHO

	local aro = Instance.new("Part")
	aro.Name = "Aro"
	aro.Anchored = true
	aro.CanCollide = false
	aro.CanQuery = false
	aro.CanTouch = false
	aro.CastShadow = false
	aro.Material = Enum.Material.Neon
	aro.Color = CFG.COR_COLAPSO
	aro.Transparency = 0.35
	aro.Size = CFG.ESCUDO_TAMANHO + Vector3.new(0.45, 0.45, -0.12)
	aro.Parent = escudo

	return escudo, aro
end

local function desmontarCiclone()
	if not ciclone then
		return
	end
	if ciclone.conexao then
		ciclone.conexao:Disconnect()
		ciclone.conexao = nil
	end
	if ciclone.pasta then
		ciclone.pasta.Parent = nil
	end
	ciclone.ativo = false
	ciclone = nil
	table.clear(ultimaCarga)
end

local function girarCiclone(jogador, personagem, raiz)
	desmontarCiclone()

	local pasta = Instance.new("Folder")
	pasta.Name = "CicloneDeEscudos"
	pasta.Parent = workspace

	local escudos = {}
	for i = 1, CFG.ESCUDOS do
		local escudo, aro = novoEscudo(i)
		escudo.Parent = pasta
		-- Fase fixa: 360/5 = 72° entre escudos. Determinístico por construção.
		table.insert(escudos, {
			parte = escudo,
			aro = aro,
			fase = (i - 1) * (math.pi * 2 / CFG.ESCUDOS),
		})
	end

	ciclone = { pasta = pasta, escudos = escudos, ativo = true }

	local t = 0
	local desdeUltimoPulso = 0

	ciclone.conexao = RunService.Heartbeat:Connect(function(dt)
		if not ciclone or not ciclone.ativo then
			return
		end
		if not (raiz and raiz.Parent) then
			desmontarCiclone()
			return
		end

		t = t + dt
		if t >= CFG.DURACAO then
			desmontarCiclone()
			return
		end

		local centro = raiz.Position
		local volta = t * CFG.ORBITA_VOLTAS * math.pi * 2

		for _, escudo in ipairs(ciclone.escudos) do
			local angulo = volta + escudo.fase
			local desloca = Vector3.new(
				math.cos(angulo) * CFG.ORBITA_RAIO,
				CFG.ORBITA_ALTURA,
				math.sin(angulo) * CFG.ORBITA_RAIO
			)
			local pos = centro + desloca
			-- O escudo olha para fora: a face vai para quem chega, não para o dono.
			local cf = CFrame.lookAt(pos, pos + (pos - centro).Unit)
			escudo.parte.CFrame = cf
			escudo.aro.CFrame = cf
		end

		-- PUXÃO — em pulsos, não todo frame. Renovar BodyVelocity a 60 Hz
		-- entope a rede e não melhora nada: o corpo já segue por inércia.
		desdeUltimoPulso = desdeUltimoPulso + dt
		if desdeUltimoPulso < CFG.PUXAO_INTERVALO then
			return
		end
		desdeUltimoPulso = 0

		local agora = os.clock()
		for _, alvo in ipairs(humanoidesEmArea(centro, CFG.PUXAO_ALCANCE, personagem)) do
			if podeAtingir(jogador, alvo) then
				local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
				if alvoRaiz then
					local vetor = centro - alvoRaiz.Position
					local distancia = vetor.Magnitude

					if distancia > CFG.PUXAO_MINIMO then
						-- Puxão só no plano: subir o alvo tiraria o controle dele.
						local plano = Vector3.new(vetor.X, 0, vetor.Z)
						if plano.Magnitude > 0.001 then
							local puxao = Instance.new("BodyVelocity")
							puxao.MaxForce = Vector3.new(1e5, 0, 1e5)
							puxao.Velocity = plano.Unit * CFG.PUXAO_FORCA
							puxao.Parent = alvoRaiz
							Debris:AddItem(puxao, CFG.PUXAO_VIDA)
						end
					end

					-- Roçar num escudo: dano leve, com recarga por alvo.
					if distancia <= CFG.ORBITA_RAIO + CFG.ROCAR_RAIO
						and distancia >= CFG.ORBITA_RAIO - CFG.ROCAR_RAIO then
						local ultimo = ultimaCarga[alvo] or 0
						if agora - ultimo >= CFG.ROCAR_ESPERA then
							ultimaCarga[alvo] = agora
							aplicarDano(jogador, alvo, CFG.ROCAR_DANO)
							tocarSom(CFG.SFX_PUXAO, alvoRaiz.Position)
							transmitir("IMPACTO_ESCUDO", alvoRaiz.Position, 0.7)
						end
					end
				end
			end
		end
	end)
end

--==============================================================================
-- PRIMÁRIA — levantar o ciclone
--==============================================================================

local function invocar(jogador, personagem, humanoide, raiz)
	tocarSequencia(Poses.primaria())
	tocarSom(CFG.SFX_CICLONE, raiz.Position)
	transmitir("ONDA_ESCUDO", raiz.Position, 1.2)
	transmitir("POEIRA_ESCUDO", raiz.Position, 1.4)
	transmitir("AURA", raiz.Position + Vector3.new(0, 2, 0), 1.5)

	girarCiclone(jogador, personagem, raiz)
end

--==============================================================================
-- EXTRA — colapsar o ciclone no centro
--==============================================================================

local function colapsar(jogador, personagem, humanoide, raiz)
	if not (ciclone and ciclone.ativo) then
		return
	end

	local agora = os.clock()
	if agora - ultimoColapso < CFG.COLAPSO_RECARGA then
		return
	end
	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_EXTRA, CFG.COLAPSO_RECARGA) then
			return
		end
	end
	ultimoColapso = agora

	local centro = raiz.Position
	tocarSequencia(Poses.extra())
	tocarSom(CFG.SFX_COLAPSO, centro)

	-- Os cinco convergem: um ESTILHACO por escudo, na posição em que ele estava.
	if ciclone.escudos then
		for _, escudo in ipairs(ciclone.escudos) do
			if escudo.parte and escudo.parte.Parent then
				transmitir("IMPACTO_ESCUDO", escudo.parte.Position, 0.9, CFG.COR_COLAPSO)
			end
		end
	end

	transmitir("ONDA_ESCUDO", centro, 2.0, CFG.COR_COLAPSO)
	transmitir("CLARAO_ESCUDO", centro + Vector3.new(0, 2, 0), 1.6, CFG.COR_COLAPSO)
	transmitir("ESTILHACOS", centro, 1.3, CFG.COR_COLAPSO)

	for _, alvo in ipairs(humanoidesEmArea(centro, CFG.COLAPSO_ALCANCE, personagem)) do
		aplicarDano(jogador, alvo, CFG.COLAPSO_DANO)
		local alvoRaiz = alvo.Parent and alvo.Parent:FindFirstChild("HumanoidRootPart")
		if alvoRaiz then
			local direcao = alvoRaiz.Position - centro
			if direcao.Magnitude > 0.001 then
				local empurrao = Instance.new("BodyVelocity")
				empurrao.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				empurrao.Velocity = direcao.Unit * CFG.COLAPSO_EMPURRAO
					+ Vector3.new(0, 28, 0)
				empurrao.Parent = alvoRaiz
				Debris:AddItem(empurrao, 0.2)
			end
		end
	end

	desmontarCiclone()
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

	if _G.Combate and _G.Combate.recargaGlobal then
		if not _G.Combate.recargaGlobal(jogador, CFG.CHAVE_PRIMARIA, CFG.DURACAO) then
			return
		end
	end

	tool.Enabled = false
	invocar(jogador, personagem, humanoide, raiz)
	task.delay(CFG.RECARGA_BASE, function()
		tool.Enabled = true
	end)
end)

acaoRemote.OnServerEvent:Connect(function(quemPediu)
	local jogador, personagem, humanoide, raiz = contexto()
	if not jogador or quemPediu ~= jogador then
		return
	end
	colapsar(jogador, personagem, humanoide, raiz)
end)

local function desmontar()
	desmontarCiclone()
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
