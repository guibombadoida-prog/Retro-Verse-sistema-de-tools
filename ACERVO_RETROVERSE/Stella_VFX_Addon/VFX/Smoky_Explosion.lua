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

--[[ 
	
	Made by Stellabotrus. (7/8/2022)
	
	Modularized Smoky Explosion for convenience.
	
	Could be used to make a Explosion which obscures vision
	
	OLD
	
]]

local Debris = (game:FindService("Debris") or game:GetService("Debris"))
local TweenService = (game:FindService("TweenService") or game:GetService("TweenService"))

local Effect = script.VFX;
Effect.Parent = nil;

return function(Position, Duration, Size, Color, Smoke_Color)
	
	Position = Position or Vector3.new();
	Duration = Duration or 2
	Size = Size or 5;
	Color = Color or Color3.fromRGB(170, 85, 0);
	Smoke_Color = Smoke_Color or Color3.fromRGB(99, 95, 98);
	
	local Explosion_Effect = Effect:Clone();
	Explosion_Effect.Parent = workspace;
	Explosion_Effect:SetPrimaryPartCFrame(CFrame.new(Position) * CFrame.Angles(math.rad(_rv_angulo()),math.rad(_rv_angulo()),math.rad(_rv_angulo())))
	
	Debris:AddItem(Explosion_Effect,Duration + 2)
	
	local Sphere_1 = Explosion_Effect:FindFirstChild("Sphere_1");
	local Sphere_2 = Explosion_Effect:FindFirstChild("Sphere_2");
	
	local Shockwaves = Explosion_Effect:FindFirstChild("Shockwaves");
	
	local Core = Explosion_Effect:FindFirstChild("Core");
	local Smoke = Explosion_Effect:FindFirstChild("Smoke")
	
	Sphere_1.Color = Color;
	Sphere_2.Color = Color;
	Core.Color = Color;
	
	Smoke.Color = Smoke_Color;
	
	Sphere_1.Size = Vector3.new(Size/10, Size * 2, Size * 2)
	Sphere_2.Size = Vector3.new(Size/10, Size * 2, Size * 2)

	
	TweenService:Create(Sphere_1,TweenInfo.new(Duration - .5,Enum.EasingStyle.Sine),{Size = Vector3.new(Size * 10, Size/2, Size/2),Transparency = 1}):Play();
	TweenService:Create(Sphere_2,TweenInfo.new(Duration - .5,Enum.EasingStyle.Sine),{Size = Vector3.new(Size * 10, Size/2, Size/2),Transparency = 1}):Play();
	
	TweenService:Create(Core,TweenInfo.new(Duration,Enum.EasingStyle.Quad),{Size = ((Core.Size * 4) * Size) + Vector3.new(_rv_jitter(),_rv_jitter(),_rv_jitter())}):Play()
	TweenService:Create(Smoke,TweenInfo.new(Duration,Enum.EasingStyle.Quad),{Size = ((Smoke.Size * 4) * Size) + Vector3.new(_rv_jitter(),_rv_jitter(),_rv_jitter())}):Play()
	
	task.delay(Duration,function()
		TweenService:Create(Core,TweenInfo.new(.5,Enum.EasingStyle.Sine),{Transparency = 1}):Play()
		TweenService:Create(Smoke,TweenInfo.new(.5,Enum.EasingStyle.Sine),{Transparency = 1}):Play()

	end)
	
	TweenService:Create(Shockwaves,TweenInfo.new(Duration - .7,Enum.EasingStyle.Sine),{Size = Smoke.Size * (10 * Size),Transparency = 1}):Play()
	
	
end
