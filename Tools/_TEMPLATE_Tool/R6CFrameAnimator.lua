--[[
	R6CFrameAnimator  —  ModuleScript, filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 (animação autoral) + §10.11.7 (acumulador dt)

	Animação R6 é CFrame PROCEDURAL sobre as juntas Motor6D. Proibido Animation/LoadAnimation.

	O tempo acumula a partir de ZERO, localmente. tick() e os.time() nunca alimentam CFrame:
	são valores absolutos e grandes, e a perda de precisão em ponto flutuante faz tremer.

	USO
		local animador = Animator.novo(personagem)
		animador:tocar(sequencia)   -- lista de quadros; ver Poses.lua
		animador:parar()            -- interrompe onde está
		animador:restaurar()        -- interrompe e devolve as juntas ao repouso
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
	RETORNO_PADRAO   = 0.20,   -- s da volta ao repouso em restaurar()
	TOLERANCIA_FIM   = 0.0001,
}

-- Juntas R6. O nome é o do Motor6D; o pai é Torso, salvo RootJoint (HumanoidRootPart).
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

-- Aplica um quadro instantaneamente. `juntas` mapeia nome -> CFrame de OFFSET sobre a base.
function Animator:_aplicar(juntas, de, alpha)
	for nome, destino in pairs(juntas) do
		local registro = self.motores[nome]
		if registro then
			local origem = de[nome] or registro.base
			registro.motor.C0 = origem:Lerp(registro.base * destino, alpha)
		end
	end
end

--[[
	sequencia = {
		{ duracao = 0.12, easing = "quadOut", juntas = { ["Right Shoulder"] = CFrame.Angles(...) } },
		{ duracao = 0.20, easing = "backOut",  juntas = { ... } },
	}
--]]
function Animator:tocar(sequencia)
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

		self:_aplicar(quadro.juntas or {}, origem, suave)

		if alpha >= 1 - CFG.TOLERANCIA_FIM then
			indice = indice + 1
			t = 0
			if sequencia[indice] then
				prepararQuadro()
			else
				self:_desconectar()
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
