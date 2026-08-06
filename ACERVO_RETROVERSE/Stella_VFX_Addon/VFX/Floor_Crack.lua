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
	["Crack"] = { e = false },
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
	
	local Crack = _rv_clone(script.Crack)
	Crack.Color = ColorSequence.new(Color)
	Crack.Size = NumberSequence.new(Size);
	Crack.Lifetime = NumberRange.new(Lasting);
	
	Crack.Parent = Attachment;
	Attachment.Parent = Terrain;
	Crack:Emit(1)
	
	Debris:AddItem(Attachment,Lasting + 5);
	
	
	
end