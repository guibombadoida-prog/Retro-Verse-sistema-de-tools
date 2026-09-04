--[[ CONFORMADO §12.12.2 — Retro-Verse
	Origem: Stella's VFX Addon (Stellabotrus). Módulo copiado PARA DENTRO da
	Tool: sem require, sem ReplicatedStorage, sem depósito externo.
	Alterações estão marcadas com [RV] no corpo.
]]

local _rv_n = 0
local function _rv_passo()
	_rv_n = _rv_n + 1
	if _rv_n > 100000 then _rv_n = 1 end
	return _rv_n
end

-- [RV] dispersão por ângulo áureo, no lugar de math.random(-360,360)
local function _rv_angulo()
	return (_rv_passo() * 137.507764) % 360
end

-- [RV] jitter determinístico em [-1,1], no lugar de math.random(-100,100)/100
local function _rv_jitter()
	return math.sin(_rv_passo() * 2.399963)
end


-- [RV] valores originais do molde, por caminho dentro deste ModuleScript
local _RV_VISIVEL = {
	["SpiralTrail"] = { e = true },
}

local function _rv_caminho(inst)
	local partes, no = {}, inst
	while no and no ~= script do
		table.insert(partes, 1, no.Name)
		no = no.Parent
	end
	return table.concat(partes, "/")
end

local function _rv_acender(copia, caminho)
	local dados = _RV_VISIVEL[caminho]
	if dados then
		if dados.t then copia.Transparency = dados.t end
		if dados.e ~= nil then copia.Enabled = dados.e end
	end
	for _, filho in ipairs(copia:GetChildren()) do
		local abaixo = filho.Name
		if caminho ~= "" then abaixo = caminho .. "/" .. filho.Name end
		_rv_acender(filho, abaixo)
	end
end

-- [RV] clona e ACENDE: o molde fica apagado na Tool, o clone nasce visível
local function _rv_clone(molde)
	local copia = molde:Clone()
	_rv_acender(copia, _rv_caminho(molde))
	return copia
end

--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Sprial effect for convenience.
	
	
]]
local TweenService = game:FindService("TweenService") or game:GetService("TweenService")
local Debris = game:FindService("Debris") or game:GetService("Debris")
local RunService = game:FindService("RunService") or game:GetService("RunService")

return function(Position,Size,Color,Iterations,Radius,Distance)
	
	Position = Position or Vector3.new(0,5,0);
	Size = Size or 1
	Iterations = Iterations or 300
	Distance = Distance or 3
	Color = Color or Color3.fromRGB(255, 255, 255)
	Radius = Radius or 10
	
	local x = 0

	local t = Instance.new("Part")
	t.Size = Vector3.new(Size, Size, Size)
	t.Anchored = true
	t.Color = Color;
	t.CanCollide = false;
	t.CastShadow = false;
	t.CanQuery = false;
	t.Material = Enum.Material.Neon
	t.Shape = Enum.PartType.Ball
	t.Transparency = 1

	local A1 = Instance.new("Attachment")
	A1.Position = Vector3.new(0,Size/2,0)
	A1.Parent = t;

	local A2 = Instance.new("Attachment")
	A2.Position = Vector3.new(0,-Size/2,0)
	A2.Parent = t;
	
	local Trail = _rv_clone(script.SpiralTrail)
	Trail.Attachment0 = A1;
	Trail.Attachment1 = A2;
	Trail.Color = ColorSequence.new(Color)
	Trail.Parent = t;

	Debris:AddItem(t,30)

	for j = 1, 2*Radius/(Distance*Iterations) + 1 do
		for i = 1, Iterations do
		--[[local t = Instance.new("Part")
		t.Size = Vector3.new(size, size, size)
		t.Anchored = true
		t.Color = color;
		t.CanCollide = false;
		t.CastShadow = false;
		t.CanQuery = false;
		t.Material = Enum.Material.Neon]]
		if t then
			t.CFrame = (CFrame.fromEulerAnglesXYZ(0,x,0) + Position +Vector3.new(Radius*math.sin(x),Distance*2*x,Radius*math.cos(x)))
			local Increment = 250 * RunService.Heartbeat:Wait()
			x = x + math.rad(Size*Increment)
			--TweenService:Create(t,TweenInfo.new(1),{Size = Vector3.new(),Transparency = 1}):Play()
			--Debris:AddItem(t,1)
			t.Parent = workspace.CurrentCamera
		end

		end
	end

	Debris:AddItem(t,5)
	Trail.Enabled = false;

	if t then
		t.Transparency = 1;
	end
end