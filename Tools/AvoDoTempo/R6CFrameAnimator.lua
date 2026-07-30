--[[
	R6CFrameAnimator  V2  —  ModuleScript, filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 (animação autoral) + §10.11.7 (acumulador dt)

	V1 → V2: quadro pode declarar `absoluto = true`, e então as CFrames da tabela são
	a C0 FINAL da junta, não um offset sobre a base. É o que permite importar pose de
	terceiro sem reinterpretar a convenção de base de quem a escreveu (§12.12.1).

	Modo padrão continua sendo OFFSET — V1 e V2 convivem sem quebrar Tool existente.

	Animação R6 é CFrame PROCEDURAL sobre as juntas Motor6D. Proibido Animation/LoadAnimation.
	O tempo acumula a partir de ZERO, localmente: tick() e os.time() nunca alimentam CFrame.

	USO
		local animador = Animator.novo(personagem)
		animador:tocar(sequencia)
		animador:parar()
		animador:restaurar()

	QUADRO
		{
			duracao = 0.18,
			easing  = "quadOut",
			absoluto = true,                          -- opcional
			juntas  = { ["Right Shoulder"] = CFrame.new(...) },
		}
--]]

local RunService = game:GetService("RunService")

local Animator = {}
Animator.__index = Animator

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	DURACAO_PADRAO   = 0.30,
	EASING_PADRAO    = "quadOut",
	RETORNO_PADRAO   = 0.20,
	TOLERANCIA_FIM   = 0.0001,

	-- Respiração do Idle: jitter senoidal por contador, no lugar de math.random
	RESPIRO_AMPLITUDE = 0.03,
	RESPIRO_PERIODO   = 1.9,
}

local JUNTAS = {
	["Neck"]           = { pai = "Torso",            base = CFrame.new(0, 1, 0) * CFrame.Angles(-math.pi / 2, 0, math.pi) },
	["Right Shoulder"] = { pai = "Torso",            base = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.pi / 2, 0) },
	["Left Shoulder"]  = { pai = "Torso",            base = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -math.pi / 2, 0) },
	["Right Hip"]      = { pai = "Torso",            base = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.pi / 2, 0) },
	["Left Hip"]       = { pai = "Torso",            base = CFrame.new(-1, -1, 0) * CFrame.Angles(0, -math.pi / 2, 0) },
	["RootJoint"]      = { pai = "HumanoidRootPart", base = CFrame.new(0, 0, 0) * CFrame.Angles(-math.pi / 2, 0, math.pi) },
}

--==============================================================================
-- EASING — funções puras de alpha (0..1)
--==============================================================================

local EASING = {}

function EASING.linear(a)
	return a
end

function EASING.quadIn(a)
	return a * a
end

function EASING.quadOut(a)
	return 1 - (1 - a) * (1 - a)
end

function EASING.quadInOut(a)
	if a < 0.5 then
		return 2 * a * a
	end
	return 1 - ((-2 * a + 2) ^ 2) / 2
end

function EASING.cubicOut(a)
	return 1 - (1 - a) ^ 3
end

function EASING.backOut(a)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * ((a - 1) ^ 3) + c1 * ((a - 1) ^ 2)
end

local function resolverEasing(nome)
	local funcao = EASING[nome or CFG.EASING_PADRAO]
	if funcao then
		return funcao
	end
	return EASING.linear
end

--==============================================================================
-- CONSTRUÇÃO
--==============================================================================

function Animator.novo(personagem)
	if not personagem then
		return nil
	end

	local self = setmetatable({}, Animator)
	self.personagem = personagem
	self.motores = {}
	self.conexao = nil
	self.tocando = false
	self.respirando = false

	for nome, info in pairs(JUNTAS) do
		local pai = personagem:FindFirstChild(info.pai)
		if pai then
			local motor = pai:FindFirstChild(nome)
			if motor and motor:IsA("Motor6D") then
				self.motores[nome] = {
					motor = motor,
					base = info.base,
					repouso = motor.C0,
				}
			end
		end
	end

	return self
end

--==============================================================================
-- REPRODUÇÃO
--==============================================================================

function Animator:_desconectar()
	if self.conexao then
		self.conexao:Disconnect()
		self.conexao = nil
	end
	self.tocando = false
end

function Animator:_alvo(registro, destino, absoluto)
	if absoluto then
		return destino
	end
	return registro.base * destino
end

function Animator:_aplicar(quadro, de, alpha)
	local absoluto = quadro.absoluto == true
	for nome, destino in pairs(quadro.juntas or {}) do
		local registro = self.motores[nome]
		if registro then
			local origem = de[nome] or registro.base
			registro.motor.C0 = origem:Lerp(self:_alvo(registro, destino, absoluto), alpha)
		end
	end
end

function Animator:tocar(sequencia, aoTerminar)
	if not sequencia or #sequencia == 0 then
		return
	end

	self:_desconectar()
	self.tocando = true

	local indice = 1
	local t = 0                    -- acumulador dt, a partir de ZERO (§10.11.7)
	local origem = {}

	local function prepararQuadro()
		origem = {}
		for nome, registro in pairs(self.motores) do
			origem[nome] = registro.motor.C0
		end
	end

	prepararQuadro()

	self.conexao = RunService.Heartbeat:Connect(function(dt)
		if not self.tocando then
			return
		end
		if not self.personagem.Parent then
			self:_desconectar()
			return
		end

		local quadro = sequencia[indice]
		if not quadro then
			self:_desconectar()
			return
		end

		local duracao = quadro.duracao or CFG.DURACAO_PADRAO
		t = t + dt

		local alpha = duracao > 0 and math.clamp(t / duracao, 0, 1) or 1
		local suave = resolverEasing(quadro.easing)(alpha)

		self:_aplicar(quadro, origem, suave)

		if alpha >= 1 - CFG.TOLERANCIA_FIM then
			indice = indice + 1
			t = 0
			if sequencia[indice] then
				prepararQuadro()
			else
				self:_desconectar()
				if type(aoTerminar) == "function" then
					aoTerminar()
				end
			end
		end
	end)
end

function Animator:parar()
	self:_desconectar()
end

function Animator:restaurar()
	self:_desconectar()

	local t = 0
	local origem = {}
	for nome, registro in pairs(self.motores) do
		origem[nome] = registro.motor.C0
	end

	local conexao
	conexao = RunService.Heartbeat:Connect(function(dt)
		if not self.personagem.Parent then
			conexao:Disconnect()
			return
		end

		t = t + dt
		local alpha = math.clamp(t / CFG.RETORNO_PADRAO, 0, 1)
		local suave = EASING.quadOut(alpha)

		for nome, registro in pairs(self.motores) do
			local de = origem[nome] or registro.repouso
			registro.motor.C0 = de:Lerp(registro.repouso, suave)
		end

		if alpha >= 1 - CFG.TOLERANCIA_FIM then
			conexao:Disconnect()
		end
	end)
end

return Animator
