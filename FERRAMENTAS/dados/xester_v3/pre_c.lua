
--═══════════════════════════════════════════════════════════════
-- A FORMA E A PASSIVA — estado no CHARACTER, não em outra Tool
--
-- `SetAttribute` / `GetAttribute` no personagem é escrita e leitura de ESTADO,
-- não de instância: nenhum caminho, nenhum asset, nenhum script fora da Tool.
-- É estado opcional compartilhado, lido sempre com guarda e com padrão, e
-- padrão — sozinha num place vazio, a Tool cria o atributo e segue.
--═══════════════════════════════════════════════════════════════

local ATR_FORMA   = "XesterForma"
local ATR_USOS    = "XesterUsos"
local ATR_CORINGA = "XesterCoringa"

local function lerAtributo(nome, padrao)
	if not personagem then return padrao end
	local valor = personagem:GetAttribute(nome)
	if valor == nil then return padrao end
	return valor
end

local function escreverAtributo(nome, valor)
	if not personagem then return end
	personagem:SetAttribute(nome, valor)
end

local function formaAtual()
	local valor = lerAtributo(ATR_FORMA, 1)
	if valor ~= 1 and valor ~= 2 then return 1 end
	return valor
end

--═══════════════════════════════════════════════════════════════
-- O CAJADO — a peça que diz em qual forma o Xester está
--
-- O Handle NÃO pode trocar: `RequiresHandle` exige que ele exista o tempo
-- todo, e mexer na geometria dele desmonta o `Grip` do `Humanoid`.
--
-- O cajado mora no CHARACTER, não na Tool. É por isso que ele sobrevive à
-- troca de Tool na mochila — o jogador vira dragão com o `Eclipse Deck` e
-- saca o `Wyrm Sparks` sem perder o cajado — e é por isso que ele não precisa
-- de limpeza: morre com o respawn, junto do personagem.
--
-- `Weld` criado no SERVIDOR replica; criado no cliente, não — os outros
-- jogadores veriam o Xester de mãos vazias.
--═══════════════════════════════════════════════════════════════

local function acharCajado()
	if not personagem then return nil end
	return personagem:FindFirstChild("CajadoDoXester")
end

local function tirarCajado()
	local velho = acharCajado()
	if velho then velho.Parent = nil end
end

local function porCajado()
	if acharCajado() then return end
	local moldes = Tool:FindFirstChild("Moldes")
	local base = moldes and moldes:FindFirstChild("Cajado")
	local braco = personagem and personagem:FindFirstChild("Right Arm")
	if not (base and base:IsA("BasePart") and braco) then return end

	local copia = base:Clone()
	copia.Name = "CajadoDoXester"
	copia.Anchored = false
	copia.CanCollide = false
	copia.CanQuery = false
	copia.CanTouch = false
	copia.Massless = true
	copia.Transparency = 0
	for _, filho in ipairs(copia:GetDescendants()) do
		if filho:IsA("BasePart") then
			filho.Transparency = 0
			filho.CanCollide = false
			filho.Massless = true
		elseif filho:IsA("Decal") or filho:IsA("Texture") then
			filho.Transparency = 0
		elseif filho:IsA("PointLight") or filho:IsA("SpotLight") then
			filho.Enabled = true
		end
	end
	copia.CFrame = braco.CFrame
	copia.Parent = personagem

	local solda = Instance.new("Weld")
	solda.Part0 = braco
	solda.Part1 = copia
	solda.C0 = CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(90), 0, 0)
	solda.Parent = copia
end

--- A aura de brasas da Forma 2. Tem `id` e é apagada por quem a acendeu.
local auraId = nil

local function apagarAura()
	apagarEfeito(auraId)
	auraId = nil
end

local function ligarAura()
	if not raiz then return end
	apagarAura()
	auraId = novoId("AURA")
	vfx("AURA_DRAGAO", { posicao = raiz.Position, id = auraId })
end

--═══════════════════════════════════════════════════════════════
-- A PASSIVA — a Carta Coringa
--
-- O contador atravessa as SETE Tools da Forma 1 pelo atributo. Numa Tool
-- sozinha ele conta só os usos dela, e a carta nasce do mesmo jeito — o
-- comportamento degrada, não quebra.
--═══════════════════════════════════════════════════════════════

local coringaId = nil
local bonusAtivo = false

local function apagarCoringa()
	apagarEfeito(coringaId)
	coringaId = nil
	escreverAtributo(ATR_CORINGA, false)
end

--- Chamada NO COMEÇO de toda habilidade.
local function abrirHabilidade()
	bonusAtivo = false
	if lerAtributo(ATR_CORINGA, false) == true then
		bonusAtivo = true
		if raiz then
			vfx("CORINGA_GASTA", { posicao = raiz.Position })
			tocarEm("CORINGA", raiz.Position, 1.35)
		end
		apagarCoringa()
	end
	if formaAtual() ~= 1 then return end
	local usos = lerAtributo(ATR_USOS, 0) + 1
	if usos < CFG.PASSO_CORINGA then
		escreverAtributo(ATR_USOS, usos)
		return
	end
	escreverAtributo(ATR_USOS, 0)
	if not raiz then return end
	apagarCoringa()
	coringaId = novoId("CORINGA")
	escreverAtributo(ATR_CORINGA, true)
	vfx("CORINGA_NASCE", { posicao = raiz.Position,
		duracao = CFG.VIDA_CORINGA, id = coringaId })
	tocarEm("CORINGA", raiz.Position, 1.25)
end

--- Chamada no FIM de toda habilidade, pelo callback do `PlaySequence`.
local function fecharHabilidade()
	ocupado = false
	bonusAtivo = false
end

local function comBonus(valor)
	if bonusAtivo then return valor * CFG.BONUS_RAIO end
	return valor
end
