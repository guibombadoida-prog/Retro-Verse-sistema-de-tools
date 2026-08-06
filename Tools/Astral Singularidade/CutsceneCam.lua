-- CutsceneCam.lua — LocalScript da Astral Singularidade
--
-- REGRA_CAMERA_DE_CUTSCENE, as duas metades:
--
--   1. A câmera é 100% CLIENTE. `workspace.CurrentCamera` é singleton por
--      cliente, como `Players.LocalPlayer` — não existe "a câmera do jogo".
--      O servidor manda BEAT NOMEADO; quem enquadra é este arquivo.
--   2. Câmera presa é SEMPRE devolvida. `CameraType` e `FieldOfView` voltam
--      ao valor guardado em `Unequipped`, `Destroying` e na morte. Câmera
--      travada é bug sem saída para o jogador.
--
-- O pulo é só visual: solta a câmera e devolve o controle. NÃO encurta a
-- linha do tempo do servidor — se encurtasse, pular viraria vantagem.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")

local Tool           = script.Parent
local Jogador        = Players.LocalPlayer
local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")

--═══════════════════════════════════════════════════════════════
-- ENQUADRAMENTOS, por beat
--═══════════════════════════════════════════════════════════════

local FOV_BASE = 70

-- offset relativo ao portador, alvo do olhar, FOV e tempo de acomodação
local BEATS = {
	INICIO = { de = Vector3.new(6, 3.5, 8),   olhar = "alvo",     fov = 62, suave = 0.35 },
	ABRE   = { de = Vector3.new(-7, 2.5, 6),  olhar = "alvo",     fov = 54, suave = 0.30 },
	PUXA   = { de = Vector3.new(3, 6.5, -6),  olhar = "alvo",     fov = 46, suave = 0.28 },
	RASGA  = { de = Vector3.new(2.2, 2.2, 3.4), olhar = "alvo",   fov = 38, suave = 0.16 },
	FIM    = { de = Vector3.new(9, 5, 10),    olhar = "portador", fov = 96, suave = 0.22 },
}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local camera = workspace.CurrentCamera
local guardado = nil        -- { tipo, fov } do que havia antes
local ligacao, escuta = nil, nil
local nomePortador, nomeAlvo = nil, nil
local beatAtual = nil
local misturado = 0

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
	if ligacao then
		ligacao:Disconnect()
		ligacao = nil
	end
	if escuta then
		escuta:Disconnect()
		escuta = nil
	end
	beatAtual = nil

	camera = workspace.CurrentCamera
	if camera and guardado then
		camera.CameraType  = guardado.tipo
		camera.FieldOfView = guardado.fov
		local personagem = Jogador.Character
		local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
		if humanoide then camera.CameraSubject = humanoide end
	end
	guardado = nil
end

--═══════════════════════════════════════════════════════════════
-- TOMAR A CÂMERA
--═══════════════════════════════════════════════════════════════

local function tomar()
	camera = workspace.CurrentCamera
	if not camera then return false end
	if not guardado then
		guardado = { tipo = camera.CameraType, fov = camera.FieldOfView }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	return true
end

local function seguir()
	if ligacao then return end
	misturado = 0
	ligacao = RunService.RenderStepped:Connect(function(dt)
		if not beatAtual then return end
		camera = workspace.CurrentCamera
		if not camera then return end

		local portador = parteDe(nomePortador)
		local alvo     = parteDe(nomeAlvo) or portador
		if not portador then
			devolver()
			return
		end

		local foco = (beatAtual.olhar == "alvo" and alvo) or portador
		local base = portador.CFrame
		local de   = base:PointToWorldSpace(beatAtual.de)
		local para = foco.Position

		-- acumulador de dt a partir de zero, nunca tick(): tick() alimentando
		-- CFrame dá salto quando o cliente entra no meio da cena.
		misturado = math.min(1, misturado + dt / math.max(beatAtual.suave, 0.01))
		local alvoCF = CFrame.new(de, para)
		camera.CFrame = camera.CFrame:Lerp(alvoCF, misturado)
		camera.FieldOfView = camera.FieldOfView
			+ (beatAtual.fov - camera.FieldOfView) * math.min(1, dt * 8)
	end)
end

local function pular()
	if escuta then return end
	escuta = UserInput.InputBegan:Connect(function(entrada, digitando)
		if digitando then return end
		if entrada.KeyCode == Enum.KeyCode.Space
			or entrada.UserInputType == Enum.UserInputType.MouseButton2 then
			-- só visual: a linha do tempo do servidor segue igual
			devolver()
		end
	end)
end

--═══════════════════════════════════════════════════════════════
-- BEATS DO SERVIDOR
--═══════════════════════════════════════════════════════════════

CutsceneRemote.OnClientEvent:Connect(function(evento, dados)
	dados = dados or {}

	if evento == "INICIO" then
		-- só o portador entra no trilho; os demais continuam na câmera deles
		local personagem = Jogador.Character
		if not personagem or personagem.Name ~= dados.portador then return end

		nomePortador, nomeAlvo = dados.portador, dados.alvoNome
		if not tomar() then return end
		beatAtual = BEATS.INICIO
		misturado = 0
		seguir()
		pular()
		return
	end

	if evento == "BEAT" then
		local novo = BEATS[dados.nome]
		if novo and ligacao then
			beatAtual = novo
			misturado = 0
		end
		return
	end

	if evento == "FIM" then
		devolver()
	end
end)

--═══════════════════════════════════════════════════════════════
-- SAÍDAS OBRIGATÓRIAS — as três
--═══════════════════════════════════════════════════════════════

Tool.Unequipped:Connect(devolver)
Tool.Destroying:Connect(devolver)
Jogador.CharacterRemoving:Connect(devolver)

local function ligarMorte(personagem)
	local humanoide = personagem:FindFirstChildOfClass("Humanoid")
	if humanoide then humanoide.Died:Connect(devolver) end
end

if Jogador.Character then ligarMorte(Jogador.Character) end
Jogador.CharacterAdded:Connect(ligarMorte)
