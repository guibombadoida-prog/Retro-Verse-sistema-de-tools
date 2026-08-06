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

local Explosion = script.Explosion

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")


return function(Position, Duration, Size_A, Size_B, Color_A, Color_B)

	Position = Position or Vector3.new();
	Size_A = Size_A or 0;
	Size_B = Size_B or 0;
	Color_A = Color_A or Color3.fromRGB(0, 0, 0)
	Color_B = Color_B or Color_A

	local ExplosionModel = Explosion:Clone()
	ExplosionModel.Parent = workspace
	
	ExplosionModel:PivotTo(CFrame.new(Position))
	
	Debris:AddItem(ExplosionModel,Duration + 2);
	
	ExplosionModel.Core.Color = Color_A;
	ExplosionModel.Core.Size = Vector3.new(1,1,1) * Size_A;
	
	ExplosionModel.Outer.Color = Color_A;
	ExplosionModel.Outer.Size = Vector3.new(1.3,1.3,1.3) * Size_A
	
	TweenService:Create(ExplosionModel.Core,TweenInfo.new(Duration,Enum.EasingStyle.Exponential),{Size = Vector3.new(1,1,1) * Size_B,Color = Color_B}):Play()
	TweenService:Create(ExplosionModel.Outer,TweenInfo.new(Duration,Enum.EasingStyle.Back),{Size = Vector3.new(1.3,1.3,1.3) * Size_B,Color = Color_B}):Play()

	TweenService:Create(ExplosionModel.Core,TweenInfo.new(Duration),{Transparency = 1}):Play()
	TweenService:Create(ExplosionModel.Outer,TweenInfo.new(Duration),{Transparency = 1}):Play()
	
	

end