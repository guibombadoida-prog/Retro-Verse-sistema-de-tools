-- CutsceneCam.lua
-- Script com RunContext = Client — conjunto REALITY GUI
--
-- POR QUE NÃO É LocalScript
--
--   `GRAMATICA_CUTSCENE.md`, regra 2: **enquadramento POR ESPECTADOR**.
--   LocalScript dentro de Tool só roda para quem a segura, então o alvo nunca
--   executaria este arquivo e a metade da cena que é dele não existiria.
--   `RunContext = Client` roda em TODO cliente, e nada saiu de dentro da Tool.
--
-- A CENA DESTE CONJUNTO É DE AFASTAMENTO, NÃO DE APROXIMAÇÃO
--
--   O conjunto DRAMA fecha a câmera na cara do alvo: `Corte Frio` é execução a
--   dois passos, e o quadro mais apertado dele tem FOV 44. Aqui é o oposto, e
--   o motivo está no tamanho das malhas do próprio modelo:
--
--     Mushroom   522 × 543 × 522 studs
--     Ring       500 ×  48 × 500 studs
--
--   São duas ordens de grandeza acima de qualquer coisa que já entrou neste
--   repositório. Fechar a câmera num cogumelo de 522 studs mostra uma parede
--   preta — o efeito só existe se couber no quadro. Por isso o beat `DETONA`
--   joga a câmera para 42 studs de distância e abre o FOV para 100.
--
--   Isto não contradiz a regra 1 ("o FOV é a técnica principal"): ela continua
--   valendo, só que a direção do estouro é para FORA. Fecha na carga (48),
--   estoura na detonação (100). A amplitude é 52, a mesma do `Corte Frio`.
--
-- OLHAR PARA CIMA É O TERCEIRO ALVO DE FOCO
--
--   O DRAMA tinha dois: `alvo` e `eu`. Aqui há um terceiro, `cima` — o foco
--   sobe uma altura declarada acima do ancoradouro. É o que faz a câmera
--   acompanhar o cogumelo subindo e a entidade nascendo, sem precisar de uma
--   `Part` no mundo para mirar.
--
-- AS OUTRAS REGRAS, IGUAIS AO RESTO DO REPOSITÓRIO
--
--   3. Aproximação EXPONENCIAL, nunca Tween bloqueante:
--      `k = 1 - math.exp(-VELOC * dt)`. Independente de FPS e interrompível.
--   4. Estágio troca por TEMPO dentro do RenderStepped, não por espera.
--   5. Tremor com ENVELOPE, e só na janela do golpe. Duas frequências que não
--      são múltiplas (24 e 41). Zero `math.random` — um sorteio aqui faria a
--      cena tremer diferente para cada espectador, o que lê como lag.
--   6. Pular é obrigatório, e é SÓ visual: segurar E por 1.5 s solta a câmera.
--      O servidor segue no tempo dele — pular não adianta o dano.
--
--   O PRAZO é maior que o do DRAMA (16 s contra 12 s) porque a sequência mais
--   longa daqui tem 7.20 s e a cena precisa sobreviver a ela com folga.
--
-- E A SEXTA PORTA
--
--   A câmera é devolvida por: `Unequipped`, `Destroying`, `CharacterRemoving`,
--   `Died`, prazo estourado, e o pulo. A de prazo existe porque o servidor pode
--   morrer no meio da cena e nunca mandar o `FIM`.
--
-- Gerado por FERRAMENTAS/gerar_servers_reality.py.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")

local Tool           = script.Parent
local jogador        = Players.LocalPlayer
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local CFG = {
	FOV_BASE   = 70,
	VELOC_CAM  = 3.2,     -- da regra 3, medida no molde do YorrSlayer
	VELOC_FOV  = 6.0,
	SKIP_HOLD  = 1.5,     -- da regra 6
	PRAZO      = 16,      -- teto de segurança; a maior sequência daqui tem 7.85 s
	TREMOR_A   = 24,      -- as duas frequências da regra 5: não são múltiplas
	TREMOR_B   = 41,
}

--═══════════════════════════════════════════════════════════════
-- OS ENQUADRAMENTOS, POR PAPEL E POR BEAT
--
-- `de` é offset no espaço do ANCORADOURO daquele papel:
--   invocador -> ancora no portador
--   alvo      -> ancora em SI MESMO
--
-- `olhar` diz para onde a câmera aponta:
--   "portador"  o corpo de quem conjurou
--   "eu"        o próprio corpo do espectador
--   "cima"      `alto` studs ACIMA do portador — o cogumelo, a entidade
--
-- Os beats vêm das duas sequências com cena:
--   Canhao Satelite   CAMERA · MARCA · CARGA · SEGURA · DESCE · GOLPE
--
-- A cena do NOOB acompanha o portador, não um alvo: as duas ultimates nascem
-- em cima dele — a laje sobe sob os pés, a coroa desce sobre a cabeça. Por isso
-- o `INVOCADOR` fica mais perto aqui que no FAKER, e o beat `GOLPE` abre em
-- vez de fechar.

local QUADROS = {
	INVOCADOR = {
		CAMERA = { de = Vector3.new(6, 3, 9),      olhar = "portador", fov = 64, tremor = false },
		MARCA  = { de = Vector3.new(7, 3.2, 10),   olhar = "portador", fov = 60, tremor = false },
		CARGA  = { de = Vector3.new(4.5, 4.5, 7.5), olhar = "cima", alto = 9, fov = 54, tremor = false },
		SEGURA = { de = Vector3.new(4, 5.5, 7),    olhar = "cima", alto = 14, fov = 48, tremor = true },
		DESCE  = { de = Vector3.new(5.5, 3, 8.5),  olhar = "portador", fov = 56, tremor = false },
		-- o estouro joga a câmera para fora: o efeito só existe se couber
		GOLPE  = { de = Vector3.new(20, 14, 30),   olhar = "portador", fov = 96, tremor = true },
	},
	ALVO = {
		CAMERA = { de = Vector3.new(-4, 3, 9),      olhar = "eu",       fov = 68, tremor = false },
		MARCA  = { de = Vector3.new(-4, 3.2, 8.5),  olhar = "eu",       fov = 62, tremor = false },
		CARGA  = { de = Vector3.new(-3.2, 3.6, 7.5), olhar = "portador", fov = 56, tremor = false },
		SEGURA = { de = Vector3.new(-2.8, 3.8, 6.5), olhar = "portador", fov = 50, tremor = true },
		DESCE  = { de = Vector3.new(-3, 3.2, 7.5),  olhar = "portador", fov = 56, tremor = false },
		GOLPE  = { de = Vector3.new(-7, 5.5, 14),   olhar = "portador", fov = 98, tremor = true },
	},
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local camera = workspace.CurrentCamera
local guardado = nil
local ligacao, escuta, escutaSolta = nil, nil, nil
local papel, nomePortador, nomeAlvo = nil, nil, nil
local quadroAtual = nil
local posAtual, focoAtual = nil, nil
local relogio, desdeBeat = 0, 0
local segurando = 0

local function parteDe(nome)
	if type(nome) ~= "string" or nome == "" then return nil end
	local modelo = workspace:FindFirstChild(nome)
	if not modelo then return nil end
	return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso")
end

--═══════════════════════════════════════════════════════════════
-- DEVOLVER A CÂMERA — o caminho que não pode falhar
--═══════════════════════════════════════════════════════════════

local function devolver()
	if ligacao then ligacao:Disconnect() ligacao = nil end
	if escuta then escuta:Disconnect() escuta = nil end
	if escutaSolta then escutaSolta:Disconnect() escutaSolta = nil end
	quadroAtual, papel = nil, nil
	posAtual, focoAtual = nil, nil
	segurando = 0

	camera = workspace.CurrentCamera
	if camera and guardado then
		camera.CameraType  = guardado.tipo
		camera.FieldOfView = guardado.fov
		local personagem = jogador.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		if humanoide then camera.CameraSubject = humanoide end
	end
	guardado = nil
end

local function tomar()
	camera = workspace.CurrentCamera
	if not camera then return false end
	if not guardado then
		guardado = { tipo = camera.CameraType, fov = camera.FieldOfView }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	return true
end

--═══════════════════════════════════════════════════════════════
-- REGRA 5 — tremor com envelope, e só na janela do golpe
--═══════════════════════════════════════════════════════════════

local function tremor(t, idade)
	local env = math.clamp(1 - idade * 1.6, 0, 1)
	if env <= 0 then return Vector3.new() end
	return Vector3.new(
		math.sin(t * CFG.TREMOR_A) * 0.30 * env,
		math.sin(t * CFG.TREMOR_B) * 0.16 * env,
		math.sin(t * (CFG.TREMOR_A + 7)) * 0.12 * env)
end

--═══════════════════════════════════════════════════════════════
-- O TRILHO — regra 3: aproximação exponencial, nunca Tween bloqueante
--═══════════════════════════════════════════════════════════════

local function seguir()
	if ligacao then return end
	relogio, desdeBeat = 0, 0
	ligacao = RunService.RenderStepped:Connect(function(dt)
		relogio = relogio + dt
		desdeBeat = desdeBeat + dt

		-- regra 4: o estágio troca por TEMPO, e o prazo fecha a cena mesmo se
		-- o servidor nunca mandar o FIM
		if relogio > CFG.PRAZO then
			devolver()
			return
		end
		if not quadroAtual then return end

		camera = workspace.CurrentCamera
		if not camera then return end

		local eu = jogador.Character
			and (jogador.Character:FindFirstChild("HumanoidRootPart")
				or jogador.Character:FindFirstChild("Torso"))
		local portador = parteDe(nomePortador)
		local alvo = parteDe(nomeAlvo)

		local ancora = (papel == "ALVO" and (eu or alvo)) or portador
		if not ancora then
			devolver()
			return
		end

		local metaPos = ancora.CFrame:PointToWorldSpace(quadroAtual.de)
		local metaFoco

		if quadroAtual.olhar == "cima" then
			-- o terceiro alvo de foco: `alto` studs acima de quem conjurou. É
			-- assim que a câmera acompanha o cogumelo sem uma Part no mundo.
			local base = portador or ancora
			metaFoco = base.Position + Vector3.new(0, quadroAtual.alto or 12, 0)
		elseif quadroAtual.olhar == "eu" then
			metaFoco = (eu or ancora).Position
		else
			metaFoco = (portador or alvo or ancora).Position
		end

		posAtual = posAtual or metaPos
		focoAtual = focoAtual or metaFoco

		local k = 1 - math.exp(-CFG.VELOC_CAM * dt)
		posAtual = posAtual:Lerp(metaPos, k)
		focoAtual = focoAtual:Lerp(metaFoco, k)

		local sacode = quadroAtual.tremor
			and tremor(relogio, desdeBeat) or Vector3.new()

		camera.CFrame = CFrame.new(posAtual + sacode, focoAtual)

		-- regra 1: o FOV é a técnica. Também exponencial, e mais rápido que a
		-- posição — o estouro tem de chegar antes da câmera terminar de andar.
		local kf = 1 - math.exp(-CFG.VELOC_FOV * dt)
		camera.FieldOfView = camera.FieldOfView
			+ (quadroAtual.fov - camera.FieldOfView) * kf
	end)
end

--═══════════════════════════════════════════════════════════════
-- REGRA 6 — pular é obrigatório, e é SÓ visual
--═══════════════════════════════════════════════════════════════

local function pular()
	if escuta then return end
	escuta = UserInput.InputBegan:Connect(function(entrada, digitando)
		if digitando then return end
		if entrada.KeyCode ~= Enum.KeyCode.E then return end
		segurando = os.clock()
		task.delay(CFG.SKIP_HOLD, function()
			-- só solta se o E continuou pressionado o tempo todo
			if segurando > 0 and os.clock() - segurando >= CFG.SKIP_HOLD - 0.05 then
				devolver()
			end
		end)
	end)
	escutaSolta = UserInput.InputEnded:Connect(function(entrada)
		if entrada.KeyCode == Enum.KeyCode.E then segurando = 0 end
	end)
end

--═══════════════════════════════════════════════════════════════
-- BEATS DO SERVIDOR
--
-- Um `FireClient` por espectador, com o PAPEL dele no payload. O servidor sabe
-- quem invocou e quem está no raio; o cliente só desenha o que lhe cabe.
--═══════════════════════════════════════════════════════════════

CutsceneRemote.OnClientEvent:Connect(function(evento, dados)
	dados = dados or {}

	if evento == "INICIO" then
		papel = (dados.papel == "ALVO") and "ALVO" or "INVOCADOR"
		nomePortador, nomeAlvo = dados.portador, dados.alvoNome
		if not tomar() then return end
		quadroAtual = QUADROS[papel][dados.nome or "CAMERA"]
			or QUADROS[papel].CAMERA
		posAtual, focoAtual = nil, nil
		desdeBeat = 0
		seguir()
		pular()
		return
	end

	if evento == "BEAT" then
		if not (ligacao and papel) then return end
		local novo = QUADROS[papel][dados.nome]
		if novo then
			quadroAtual = novo
			desdeBeat = 0
		end
		return
	end

	if evento == "FIM" then
		devolver()
	end
end)

--═══════════════════════════════════════════════════════════════
-- AS PORTAS DE SAÍDA
--═══════════════════════════════════════════════════════════════

Tool.Unequipped:Connect(devolver)
Tool.Destroying:Connect(devolver)
jogador.CharacterRemoving:Connect(devolver)

local function ligarMorte(personagem)
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then humanoide.Died:Connect(devolver) end
end

if jogador.Character then ligarMorte(jogador.Character) end
jogador.CharacterAdded:Connect(ligarMorte)
