-- DepositoVFX.lua
-- ModuleScript "DepositoVFX" — filho da Tool, em TODAS elas
--
-- Implementa a REGRA Nº 2 (`DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md`):
--
--   Na ENTREGA, os moldes de geometria são filhos da Tool.
--   Ao chegar ao jogador — mochila OU mão —, eles saem da Tool e vão para
--   `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`.
--   Quando a Tool é destruída, `_refs` desce; zerou, a pasta some.
--
-- POR QUE UM MÓDULO E NÃO CÓDIGO COLADO EM 94 SERVERS
--
--   Porque isto tem três partes que têm de combinar: quem instala, quem
--   desinstala e quem lê. Espalhar as três por 94 arquivos é garantir que uma
--   delas fique para trás em algum deles — e o modo de falhar é silencioso, que
--   é a família de defeito que mais custou neste repositório.
--
--   O módulo é filho da Tool como o `Poses` e o `R6CFrameAnimator`. A Regra
--   nº 1 continua satisfeita: ele veio dentro dela.
--
-- QUEM INSTALA É O SERVIDOR, SEMPRE
--
--   `ReplicatedStorage` replica do servidor para os clientes. Um cliente que
--   mova instância para lá move SÓ PARA ELE — os outros não veem nada, e o
--   efeito volta a ser local. Esse bug já custou uma leva inteira aqui, e é por
--   isso que `instalar` sai cedo quando não está rodando no servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Deposito = {}

local RAIZ = "RetroVerse_VFX"
--- O que sai da Tool. `Efeitos` e `Moldes` são as pastas de geometria; `Pack`
--- é o pack de VFX, que mora dentro do `VFXModule` e não na raiz da Tool.
local PASTAS = { "Efeitos", "Moldes" }
local PACK_EM_MODULO = { "VFXModule", "Pack" }

local ligadas = {}

--- A chave é do MODELO, não da instância.
---
--- Duas pessoas com a mesma Tool compartilham UMA pasta. Se a chave fosse por
--- instância, o depósito teria oito cópias do mesmo `MeshPart` e não teríamos
--- resolvido nada — que é exatamente o problema que a regra nº 2 existe para
--- resolver.
---
--- Nome de Tool não serve sozinho: dois modelos podem se chamar `Aura`.
local function chaveDe(tool)
	local valor = tool:FindFirstChild("ChaveVFX")
	if valor and valor:IsA("StringValue") and valor.Value ~= "" then
		return valor.Value
	end
	return tool.Name
end

local function raizDoDeposito(criar)
	local raiz = ReplicatedStorage:FindFirstChild(RAIZ)
	if raiz or not criar then return raiz end
	raiz = Instance.new("Folder")
	raiz.Name = RAIZ
	raiz.Parent = ReplicatedStorage
	return raiz
end

--- A pasta desta Tool no depósito, se existir. Nunca cria.
function Deposito.pasta(tool)
	local raiz = raizDoDeposito(false)
	if not (raiz and tool) then return nil end
	return raiz:FindFirstChild(chaveDe(tool))
end

--═══════════════════════════════════════════════════════════════
-- LER — DUAS PORTAS, NESTA ORDEM
--═══════════════════════════════════════════════════════════════

--- Acha uma pasta de molde: primeiro no depósito, depois dentro da Tool.
---
--- A segunda porta NÃO é redundância defensiva. É o que mantém verdadeiro o
--- teste da Regra nº 1: num place vazio ninguém montou depósito nenhum, e até
--- o primeiro `Equipped` o molde ainda está dentro da Tool. É de lá que ele
--- tem de sair, e a Tool tem de funcionar por inteiro assim.
---
--- `de` é o script que está perguntando — dele sai a Tool por ancestral.
function Deposito.achar(de, nome)
	local tool = de and de:FindFirstAncestorOfClass("Tool")
	if not tool then return nil end

	local minha = Deposito.pasta(tool)
	local achado = minha and minha:FindFirstChild(nome)
	if achado then return achado end

	-- porta 2: ainda dentro da Tool
	achado = tool:FindFirstChild(nome)
	if achado then return achado end

	-- e o `Pack`, que mora dentro do `VFXModule`
	local modulo = tool:FindFirstChild(PACK_EM_MODULO[1])
	return modulo and modulo:FindFirstChild(nome) or nil
end

--═══════════════════════════════════════════════════════════════
-- INSTALAR E DESINSTALAR
--═══════════════════════════════════════════════════════════════

local function mover(tool, minha)
	for _, nome in ipairs(PASTAS) do
		local pasta = tool:FindFirstChild(nome)
		if pasta then pasta.Parent = minha end
	end
	local modulo = tool:FindFirstChild(PACK_EM_MODULO[1])
	local pack = modulo and modulo:FindFirstChild(PACK_EM_MODULO[2])
	if pack then pack.Parent = minha end
end

function Deposito.instalar(tool)
	if not (tool and RunService:IsServer()) then return end
	local estado = ligadas[tool]
	if not estado or estado.instalado then return end
	estado.instalado = true

	local raiz = raizDoDeposito(true)
	local chave = chaveDe(tool)
	local minha = raiz:FindFirstChild(chave)

	if not minha then
		minha = Instance.new("Folder")
		minha.Name = chave
		local refs = Instance.new("IntValue")
		refs.Name = "_refs"
		refs.Value = 0
		refs.Parent = minha
		mover(tool, minha)
		minha.Parent = raiz
	end

	local refs = minha:FindFirstChild("_refs")
	if refs then refs.Value = refs.Value + 1 end
end

--- Desconta uma referência. Zerou, a pasta some.
---
--- `_refs` não é enfeite. A regra diz "a Tool é destruída, os moldes vão
--- junto". Com UM jogador isso é literal; com DOIS, apagar no primeiro
--- `Destroying` arrancaria o molde debaixo do segundo — a Tool dele
--- continuaria viva e pararia de desenhar. "Vão junto com a Tool" quer dizer
--- com a ÚLTIMA.
function Deposito.desinstalar(tool)
	if not (tool and RunService:IsServer()) then return end
	local estado = ligadas[tool]
	if not (estado and estado.instalado) then return end
	estado.instalado = false

	local raiz = raizDoDeposito(false)
	local minha = raiz and raiz:FindFirstChild(chaveDe(tool))
	if not minha then return end

	local refs = minha:FindFirstChild("_refs")
	if refs then refs.Value = refs.Value - 1 end

	if not refs or refs.Value <= 0 then
		minha.Parent = nil
		if #raiz:GetChildren() == 0 then
			raiz.Parent = nil
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- LIGAR — a única linha que o Server precisa escrever
--═══════════════════════════════════════════════════════════════

--- Liga o ciclo inteiro: instala quando a Tool chega ao jogador, desinstala
--- quando ela morre.
---
--- O gatilho é a TROCA DE PAI, não `Tool.Equipped`: a regra diz "mochila OU
--- mão", e uma Tool que fica a partida toda na mochila sem ser equipada
--- também precisa dos moldes no lugar — o dono não é o único que desenha.
---
--- `GetPropertyChangedSignal("Parent")` e não `AncestryChanged`: a proibição
--- do `AncestryChanged` é para CLEANUP, e cleanup aqui é `Tool.Destroying`,
--- que é o que a regra manda usar.
function Deposito.ligar(tool)
	if not (tool and RunService:IsServer()) then return end
	if ligadas[tool] then return end
	ligadas[tool] = { instalado = false }

	local function aoTrocarDePai()
		local pai = tool.Parent
		if not pai then return end
		if pai:IsA("Backpack") or pai:FindFirstChildOfClass("Humanoid") then
			Deposito.instalar(tool)
		end
	end

	tool:GetPropertyChangedSignal("Parent"):Connect(aoTrocarDePai)
	tool.Destroying:Connect(function()
		Deposito.desinstalar(tool)
		ligadas[tool] = nil
	end)

	aoTrocarDePai()
end

return Deposito
