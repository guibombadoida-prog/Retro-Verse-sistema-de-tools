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
	
	Modularized Pseudoprojectile for convenience.
	
	
]]

	--// Variables;
local TweenService = game:FindService("TweenService") or game:GetService("TweenService") 
local Debris = game:FindService("Debris") or game:GetService("Debris") 
local Workspace = game:FindService("Workspace") or game:GetService("Workspace") 

local Instant = Instance.new   -- [RV] Foreach e random eram mortos

local IsA,FindFirstChild,FindFirstChildOfClass,WaitForChild,GetChildren,GetDescendants,DescendantOf,Destroy,Clone,SetAttribute,GetAttribute = script.IsA,script.FindFirstChild,script.FindFirstChildOfClass,script.WaitForChild,script.GetChildren,script.GetDescendants,script.IsDescendantOf,script.Destroy,script.Clone,script.SetAttribute,script.GetAttribute

local CF,Vec3,RGB,Mat,TweenInfo_new = CFrame.new,Vector3.new,Color3.fromRGB,Enum.Material,TweenInfo.new

return function(Start_Position, EndPosition, Thickness_A, Thickness_B, Length, Color_A, Color_B, Shape, Duration)
	
	Start_Position = Start_Position or Vector3.new(0,5,0)
	EndPosition = EndPosition or Vector3.new(0,100,0);
	Thickness_A = Thickness_A or 0.2;
	Thickness_B = Thickness_B or Thickness_A;
	Length = Length or 10
	Color_A = Color_A or Color3.fromRGB(255, 255, 255);
	Color_B = Color_B or Color_A;
	Shape = Shape or "Cylinder"
	Duration = Duration or (Start_Position - EndPosition).Magnitude * 0.005;
	
	local Tween_Create = TweenInfo_new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0);
	

	local Distance = (Start_Position - EndPosition).Magnitude;

	local Laser = Instant("Part");
	Laser.Name = "Laser";
	Laser.Locked = true;
	Laser.Anchored = true;
	Laser.CanCollide = false;
	Laser.Material = Mat.Neon;
	Laser.Size = Vec3(1,1,1) * 0.05;

	local Mesh = Instant("SpecialMesh");
	Mesh.Scale = (Vec3(Length, Thickness_A, Thickness_A)) * 20;
	Mesh.MeshType = Enum.MeshType.Brick;
	Mesh.Parent = Laser;

	Laser.Color = Color3.fromRGB(255, 217, 0);

	Laser.CFrame = CF(Start_Position, EndPosition) * CFrame.Angles(0,math.pi/2,0) * CF(0, 0, -(Mesh.Scale.Z / 40) );
	Debris:AddItem(Laser, 1);
	Laser.Parent = Workspace;

	TweenService:Create(Mesh,Tween_Create,{Scale = Vec3(Length,Thickness_B,Thickness_B) * 20}):Play();
	TweenService:Create(Laser,Tween_Create,{Position = EndPosition,Color = Color_B,Transparency = 1}):Play();
	
end

