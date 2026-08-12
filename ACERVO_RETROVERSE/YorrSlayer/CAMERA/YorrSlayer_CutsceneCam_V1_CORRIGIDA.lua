-- YorrSlayer_CutsceneCam_V1 (LocalScript "CutsceneCam" dentro da Tool)
-- CORREÇÃO (§12.12.2) do handler "Cutsen" de Client.lua — mesma ideia visual,
-- violações da REGRA_CAMERA_DE_CUTSCENE fechadas.
--
-- O QUE VEIO do original, e é o valor real deste modelo: câmera DIFERENTE por
-- espectador. Quem invoca vê o dragão de frente; quem é o alvo vê a própria
-- cara de perto. O molde da casa (SeriousMode_CutsceneCam_V1) só tem câmera
-- única — essa diferenciação por Player não existe nele.
--
-- O QUE NÃO VEIO, e por quê:
--   math.random() no shake            → shake tem que ser reproduzível;
--                                        virou acumulador senoidal (§ técnica
--                                        do molde), duas frequências que não
--                                        se repetem, sem números aleatórios.
--   tick() alimentando o elapsed       → acumulador `dt` do RenderStepped,
--                                        do zero, como toda câmera da casa.
--   task.wait() em sequência dentro do → bloqueava o LocalScript inteiro e
--   handler do RemoteEvent               não dava pra interromper limpo; virou
--                                        state machine por RenderStepped.
--   sem tecla de pulo                  → adicionada (E, segurar 1,5 s). Só
--                                        solta a câmera — o servidor já roda
--                                        a invocação no próprio tempo dele,
--                                        então pular não afeta o dano.
--   sem devolver em Unequipped/        → adicionado. Testei: o original não
--   /Destroying                          manda nada pro cliente se o jogador
--                                        desequipar no meio — é exatamente o
--                                        bug que a regra chama de "o pior do
--                                        repertório" (câmera presa pro resto
--                                        da partida).
--   sem restaurar FieldOfView          → restaura, e ganhou o contraste de
--                                        FOV que é a técnica principal do
--                                        molde (fecha um pouco na aproximação,
--                                        estoura no golpe do invocador).
--
-- FORA DO ESCOPO desta correção: o handler "GreenScreen" do Client.lua
-- original (efeito separado, não é a cutscene) ainda cria ColorCorrectionEffect
-- e continua violando a regra. Não mexido aqui — é outro efeito, outra Tool.
--
-- CONTRATO COM O SERVIDOR (inalterado): Remote2:FireClient(jogador, "Cutsen",
-- { Dragon, Target, Duration, Summoner }), um por espectador — o servidor já
-- manda pro invocador e pro alvo separadamente. Duration é teto de segurança;
-- se a cutscene não tiver decidido nada até lá, ela se fecha sozinha.

local Players      = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local CAS           = game:GetService("ContextActionService")

local Tool   = script.Parent
local Remote = Tool:WaitForChild("Remote2")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FOV_BASE  = 70
local FOV_CLOSE = 52   -- fecha um pouco na aproximação (tensão)
local FOV_PUNCH = 86   -- estoura no golpe do invocador — contraste é o que vende
local SKIP_HOLD = 1.5
local VELOC_CAM = 3.2  -- quão rápido a câmera alcança o alvo do estágio atual

local active    = false
local camConn   = nil
local savedType = nil
local savedSubj = nil
local holdAccum = 0
local holding   = false
local elapsed   = 0
local etapa     = 1
local d         = nil
local curPos, curLook = nil, nil

-- Jitter determinístico — duas frequências que não se repetem, cresce e
-- some sozinho dentro da janela (§ técnica do molde). Zero math.random.
local function tremorEm(t, janelaT)
	local env = math.clamp(1 - janelaT, 0, 1)
	return (math.sin(t * 24) * 0.35 + math.sin(t * 41) * 0.14) * env
end

local function stopCutscene()
	if not active then return end
	active = false
	if camConn then camConn:Disconnect() camConn = nil end
	CAS:UnbindAction("YorrCutsceneSkip")
	TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = FOV_BASE }):Play()
	camera.CameraType    = savedType or Enum.CameraType.Custom
	camera.CameraSubject = savedSubj
	savedType, savedSubj = nil, nil
	holdAccum, holding = 0, false
	elapsed, etapa = 0, 1
	curPos, curLook = nil, nil
	d = nil
end

local function onSkip(_, state)
	if state == Enum.UserInputState.Begin then
		holding = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		holding, holdAccum = false, 0
	end
	return Enum.ContextActionResult.Sink
end

-- Plano do ALVO: 15 studs atrás de si mesmo, altura de olho — vendo a
-- própria cara chegando perto.
local function planoAlvo(alvoRaiz, alvoCabeca)
	local frente = alvoRaiz.CFrame.LookVector
	local pos = alvoRaiz.Position - frente * 15 + Vector3.new(0, 5, 0)
	local olhar = (alvoCabeca and alvoCabeca.Position)
		or (alvoRaiz.Position + Vector3.new(0, 1.5, 0))
	return pos, olhar
end

-- Plano do INVOCADOR: 30 studs na frente do dragão. Estágio 1 olha pro
-- dragão; estágio 2 vira pro alvo — o corte que o original fazia com dois
-- tweenCamera separados.
local function planoInvocador(dragaoRaiz, alvoRaiz, alvoCabeca, est)
	local frente = dragaoRaiz.CFrame.LookVector
	local pos = dragaoRaiz.Position + frente * 30 + Vector3.new(0, 6, 0)
	if est == 1 then
		return pos, dragaoRaiz.Position + Vector3.new(0, 3, 0)
	end
	local olharAlvo = (alvoCabeca and alvoCabeca.Position)
		or (alvoRaiz.Position + Vector3.new(0, 1.5, 0))
	return pos, olharAlvo
end

local function startCutscene(dados)
	local dragaoRaiz = dados.Dragon
		and (dados.Dragon:FindFirstChild("Torso") or dados.Dragon:FindFirstChild("HumanoidRootPart"))
	local alvoRaiz = dados.Target and dados.Target:FindFirstChild("HumanoidRootPart")
	if not (dragaoRaiz and alvoRaiz) then return end
	stopCutscene()

	d = dados
	d.ehAlvo = (player.Character == dados.Target)
	d.alvoCabeca = dados.Target:FindFirstChild("Head")

	savedType, savedSubj = camera.CameraType, camera.CameraSubject
	camera.CameraType = Enum.CameraType.Scriptable
	active, elapsed, etapa = true, 0, 1
	curPos, curLook = camera.CFrame.Position, (camera.CFrame.Position + camera.CFrame.LookVector)
	CAS:BindAction("YorrCutsceneSkip", onSkip, true, Enum.KeyCode.E)

	local duracao = dados.Duration or 4

	TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ FieldOfView = FOV_CLOSE }):Play()

	camConn = RunService.RenderStepped:Connect(function(dt)
		if not active then return end

		local dragaoAtual, alvoAtual = d.Dragon, d.Target
		if not (dragaoAtual and dragaoAtual.Parent and alvoAtual and alvoAtual.Parent) then
			stopCutscene()
			return
		end
		local dR = dragaoAtual:FindFirstChild("Torso") or dragaoAtual:FindFirstChild("HumanoidRootPart")
		local aR = alvoAtual:FindFirstChild("HumanoidRootPart")
		if not (dR and aR) then stopCutscene() return end

		elapsed = elapsed + dt
		if elapsed > 1.5 then etapa = 2 end

		local metaPos, metaOlhar
		if d.ehAlvo then
			metaPos, metaOlhar = planoAlvo(aR, d.alvoCabeca)
		else
			metaPos, metaOlhar = planoInvocador(dR, aR, d.alvoCabeca, etapa)
		end

		-- aproximação exponencial ao alvo do estágio — suave e interrompível,
		-- ao contrário do TweenService:Create(...).Completed:Wait() original
		local k = 1 - math.exp(-VELOC_CAM * dt)
		curPos  = curPos:Lerp(metaPos, k)
		curLook = curLook:Lerp(metaOlhar, k)

		-- tremor só no golpe do invocador (~2,5 s a 4,5 s), some sozinho
		local tremor = Vector3.new()
		if not d.ehAlvo and elapsed > 2.5 and elapsed < 4.5 then
			local j = tremorEm(elapsed, (elapsed - 2.5) / 2)
			tremor = Vector3.new(j, j * 0.5, 0)
		end

		camera.CFrame = CFrame.lookAt(curPos + tremor, curLook)

		-- estouro de FOV no instante do golpe do invocador
		if not d.ehAlvo and elapsed >= 2.5 and elapsed < 2.5 + dt then
			camera.FieldOfView = FOV_PUNCH
			TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ FieldOfView = FOV_BASE }):Play()
		end

		if holding then
			holdAccum = holdAccum + dt
			if holdAccum >= SKIP_HOLD then
				stopCutscene() -- puramente visual: NÃO afeta o tempo do servidor
			end
		end

		if elapsed >= duracao then
			stopCutscene()
		end
	end)
end

Remote.OnClientEvent:Connect(function(action, dados)
	if action == "Cutsen" and typeof(dados) == "table" then
		startCutscene(dados)
	end
	-- "GreenScreen" é outro efeito, fora do escopo desta correção
end)

Tool.Unequipped:Connect(stopCutscene)
Tool.Destroying:Connect(stopCutscene)
