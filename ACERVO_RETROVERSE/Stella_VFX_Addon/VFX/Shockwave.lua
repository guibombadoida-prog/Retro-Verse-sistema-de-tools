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
	["Shockwave"] = { t = 0 },
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
	
	Modularized Shockwave Effect for convenience.
	
	
]]
local TweenService = game:FindService("TweenService") or game:GetService("TweenService")
local Debris = game:FindService("Debris") or game:GetService("Debris")


local Shockwave = script.Shockwave
Shockwave.Parent = nil


return function(StartCFrame, EndCFrame, Duration, Vector_Size_A, Vector_Size_B, Color_A, Color_B, Easing_Style)
	
	StartCFrame = StartCFrame or CFrame.new(Vector3.new(0,5,0))
	EndCFrame = EndCFrame or StartCFrame;
	Duration = Duration or 1
	Vector_Size_A = Vector_Size_A or Vector3.new(10.775, 2.3, 10.505)
	Vector_Size_B = Vector_Size_B or (Vector_Size_A * 3)
	Color_A = Color_A or Color3.fromRGB(255, 255, 255);
	Color_B = Color_B or Color_A
	Easing_Style = Easing_Style or Enum.EasingStyle.Linear
	
	local Shockwave = _rv_clone(Shockwave)
	Shockwave.CFrame = StartCFrame;
	Shockwave.Size = Vector_Size_A;
	Shockwave.Color = Color_A;
	Shockwave.Parent = workspace
	
	TweenService:Create(Shockwave,TweenInfo.new(Duration,Easing_Style),{Size = Vector_Size_B,Color = Color_B}):Play()
	TweenService:Create(Shockwave,TweenInfo.new(Duration),{Transparency = 1}):Play()
	
	Debris:AddItem(Shockwave,Duration + 1)
	
end