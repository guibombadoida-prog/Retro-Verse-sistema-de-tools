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
	
	Modularized Lightning effect for convenience.
	
	
]]
local TweenService = game:FindService("TweenService") or game:GetService("TweenService")
local Debris = game:FindService("Debris") or game:GetService("Debris")


return function(CF, Lifetime, Size_Start, Size_End, Thickness_Start, Thickness_End, Color_A, Color_B)
	
	CF = CF or CFrame.new(Vector3.new())
	Lifetime = Lifetime or 1;
	Thickness_Start = Thickness_Start or 2;
	Thickness_End = Thickness_End or Thickness_Start;
	Size_Start = Size_Start or 0;
	Size_End = Size_End or 75;
	Color_A = Color_A or Color3.fromRGB(255, 176, 0);
	Color_B = Color_B or Color_A;
	
	local Ring = script.Ring:Clone()
	Ring.CFrame = CF * CFrame.Angles(-math.pi/2,0,0);
	Ring.Size = Vector3.new(Size_Start,Size_Start,Thickness_Start);
	Ring.Color = Color_A;
	Ring.Parent = workspace;
	
	Debris:AddItem(Ring,Lifetime)
	
	TweenService:Create(Ring,TweenInfo.new(Lifetime),{Size = Vector3.new(Size_End,Size_End,Thickness_End),Transparency = 1,Color = Color_B}):Play();
	
	
end
