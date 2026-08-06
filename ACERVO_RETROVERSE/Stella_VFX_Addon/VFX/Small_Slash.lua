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
	
	Modularized Slash effect for convenience.
	
	
]]
local TweenService = game:FindService("TweenService") or game:GetService("TweenService")
local Debris = game:FindService("Debris") or game:GetService("Debris")

return function(CF, Size, Duration, Color_A, Color_B)
	
	CF = CF or CFrame.new(Vector3.new(0,5,0))
	Size = Size or 10;
	Duration = Duration or .2;
	Color_A = Color_A or Color3.fromRGB(255, 255, 255);
	Color_B = Color_B or Color_A
	
	local SlashPart = Instance.new("Part")
	SlashPart.Size = Vector3.new()
	SlashPart.Color = Color_A;
	SlashPart.Material = Enum.Material.Neon;
	SlashPart.CanTouch = false;
	SlashPart.Size = Vector3.new(1,1,1) * Size
	SlashPart.Anchored = true;
	SlashPart.CanCollide = false
	SlashPart.Name = "Slash"
	SlashPart.CFrame = CF

	local SlashMesh = Instance.new("SpecialMesh")
	SlashMesh.MeshType = Enum.MeshType.Sphere;
	SlashMesh.Name = "SlashMesh"
	SlashMesh.Scale = Vector3.new(1,1,1)
	SlashMesh.Parent = SlashPart


	SlashPart.Parent = workspace

	TweenService:Create(SlashMesh,TweenInfo.new(Duration,Enum.EasingStyle.Linear),{Scale = Vector3.new(0,Size,0)}):Play()
	TweenService:Create(SlashPart,TweenInfo.new(Duration,Enum.EasingStyle.Linear),{Transparency = 1,Color = Color_B}):Play()

	Debris:AddItem(SlashPart,Duration + .8)

end