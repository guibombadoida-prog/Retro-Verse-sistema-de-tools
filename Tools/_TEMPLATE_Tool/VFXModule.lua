--[[
	VFXModule  —  ModuleScript, filho direto da Tool. Roda no CLIENTE.
	Retro-Verse / Studios  ·  §12.11 — o servidor TRANSMITE, nunca emite

	O servidor manda apenas DADOS por VFXRemote. Quem cria as partículas é o cliente.
	Zero :Emit() no servidor. Zero Instance no payload.

	Proibições ativas aqui:
		:Destroy() em part          → Parent = nil / Debris
		math.random em gameplay     → ângulo áureo (Vogel) por índice sequencial
		tick()                      → acumulador dt a partir de zero
		ScreenGui/ColorCorrection   → o efeito vive só no mundo 3D

	Ao finalizar a Tool, este arquivo é depositado no Acervo:
		ACERVO_RETROVERSE/[Modelo_De_Origem]/VFX/[NOME_DO_EFEITO]/
--]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local VFX = {}

--==============================================================================
-- CFG
--==============================================================================

local CFG = {
	ANGULO_AUREO   = 2.39996322972865332,  -- rad — substitui math.random na distribuição
	VIDA_PARTE     = 1.2,
	VIDA_ONDA      = 0.9,

	IMPACTO_PECAS  = 8,
	IMPACTO_RAIO   = 2.0,
	IMPACTO_SUBIDA = 6.0,

	NOVA_RAIO_FIM  = 3.2,   -- multiplicador da escala
	NOVA_ALTURA    = 0.6,

	COR_PADRAO     = Color3.fromRGB(140, 90, 255),
	ESCALA_PADRAO  = 1.0,
}

--==============================================================================
-- AUXILIARES
--==============================================================================

local contador = 0

-- Distribuição determinística: ângulo áureo. Mesma dispersão visual do random, sem random.
local function direcaoVogel(indice, total)
	local angulo = indice * CFG.ANGULO_AUREO
	local raio = math.sqrt(indice / math.max(total, 1))
	return Vector3.new(math.cos(angulo) * raio, 0, math.sin(angulo) * raio)
end

local function novaParte(cor, tamanho, cframe)
	local parte = Instance.new("Part")
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.CanTouch = false
	parte.CastShadow = false
	parte.Material = Enum.Material.Neon
	parte.Color = cor
	parte.Size = tamanho
	parte.CFrame = cframe
	return parte
end

local function lerCor(payload)
	if typeof(payload.cor) == "Color3" then
		return payload.cor
	end
	return CFG.COR_PADRAO
end

local function lerEscala(payload)
	if type(payload.escala) == "number" and payload.escala > 0 then
		return payload.escala
	end
	return CFG.ESCALA_PADRAO
end

--==============================================================================
-- EFEITOS
--==============================================================================

-- "IMPACTO" — estilhaços curtos subindo do ponto de contato
function VFX.IMPACTO(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao

	local pasta = Instance.new("Folder")
	pasta.Name = "VFX_IMPACTO"
	pasta.Parent = workspace

	local pecas = {}
	local indice = 1
	while indice <= CFG.IMPACTO_PECAS do
		local direcao = direcaoVogel(indice, CFG.IMPACTO_PECAS)
		local parte = novaParte(
			cor,
			Vector3.new(0.2, 0.2, 0.9) * escala,
			CFrame.new(origem + direcao * CFG.IMPACTO_RAIO * escala)
		)
		parte.Parent = pasta
		table.insert(pecas, { parte = parte, direcao = direcao })
		indice = indice + 1
	end

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_PARTE, 0, 1)

		for _, peca in ipairs(pecas) do
			local avanco = peca.direcao * CFG.IMPACTO_RAIO * escala * (1 + alpha * 2)
			local altura = Vector3.new(0, CFG.IMPACTO_SUBIDA * escala * alpha * (1 - alpha) * 4, 0)
			peca.parte.CFrame = CFrame.new(origem + avanco + altura)
			peca.parte.Transparency = alpha
		end

		if alpha >= 1 then
			conexao:Disconnect()
			pasta.Parent = nil
		end
	end)

	Debris:AddItem(pasta, CFG.VIDA_PARTE + 0.5)
end

-- "IMPACTO_NOVA" — anel de choque expandindo no plano do chão
function VFX.IMPACTO_NOVA(payload)
	if typeof(payload.posicao) ~= "Vector3" then
		return
	end

	local cor = lerCor(payload)
	local escala = lerEscala(payload)
	local origem = payload.posicao

	local anel = novaParte(
		cor,
		Vector3.new(1, CFG.NOVA_ALTURA, 1),
		CFrame.new(origem)
	)
	anel.Shape = Enum.PartType.Cylinder
	anel.Orientation = Vector3.new(0, 0, 90)
	anel.Parent = workspace

	local t = 0
	local conexao
	conexao = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local alpha = math.clamp(t / CFG.VIDA_ONDA, 0, 1)
		local raio = 1 + (CFG.NOVA_RAIO_FIM * escala - 1) * (1 - (1 - alpha) ^ 3)

		anel.Size = Vector3.new(CFG.NOVA_ALTURA, raio, raio)
		anel.Transparency = alpha

		if alpha >= 1 then
			conexao:Disconnect()
			anel.Parent = nil
		end
	end)

	Debris:AddItem(anel, CFG.VIDA_ONDA + 0.5)
end

--==============================================================================
-- DESPACHO — chamado pelo Client ao receber VFXRemote
--==============================================================================

function VFX.executar(tipo, payload)
	local efeito = VFX[tipo]
	if type(efeito) ~= "function" or tipo == "executar" then
		return
	end

	contador = contador + 1
	local ok, erro = pcall(efeito, payload or {})
	if not ok then
		warn("[VFXModule] efeito '" .. tostring(tipo) .. "' falhou: " .. tostring(erro))
	end
end

return VFX
