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

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")


return function(CF, Size, Lasting, Color)
	
	CF = CF or CFrame.new()
	Size = Size or 10;
	Lasting = Lasting or 4;
	Color = Color or Color3.fromRGB(255, 255, 255)
	
	
	local Terrain = workspace.Terrain
	local Attachment = Instance.new("Attachment")
	Attachment.WorldCFrame = CF;
	
	local Crack = script.Crack:Clone()
	Crack.Color = ColorSequence.new(Color)
	Crack.Size = NumberSequence.new(Size);
	Crack.Lifetime = NumberRange.new(Lasting);
	
	Crack.Parent = Attachment;
	Attachment.Parent = Terrain;
	Crack:Emit(1)
	
	Debris:AddItem(Attachment,Lasting + 5);
	
	
	
end