-- DepositoVFX.lua
-- ModuleScript "DepositoVFX" — filho da Tool, em TODAS elas
--
-- Implementa a REGRA Nº 2 (`DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md`):
--
--   Na ENTREGA, os moldes de geometria são filhos da Tool.
--   Ao chegar ao jogador — mochila OU mão —, eles saem da Tool e vão para
--   `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`.
--   A pasta CRIA ou REUTILIZA, e fica lá até o servidor ser desligado.
--
-- POR QUE UM MÓDULO E NÃO CÓDIGO COLADO EM 94 SERVERS
--
--   Porque isto tem duas partes que têm de combinar: quem instala e quem lê.
--   Espalhar as duas por 94 arquivos é garantir que uma delas fique para trás
--   em algum deles — e o modo de falhar é silencioso, que é a família de
--   defeito que mais custou neste repositório.
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

--- Chave fraca: uma Tool destruída sai desta tabela sozinha, sem precisar de
--- um `Destroying` só para limpar entrada.
local ligadas = setmetatable({}, { __mode = "k" })

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
--- a primeira Tool chegar ao jogador o molde ainda está dentro dela. É de lá
--- que ele tem de sair, e a Tool tem de funcionar por inteiro assim.
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
-- INSTALAR — CRIAR OU REUTILIZAR
--
-- ⚠️ NÃO EXISTE `desinstalar`, E ISSO É DE PROPÓSITO.
--
--    A pasta não é da Tool: é do MODELO. Dois jogadores com a mesma Tool
--    dependem da mesma pasta, e o instante em que um deles guarda ou morre não
--    diz nada sobre o outro. Apagar ali arrancaria o molde debaixo de quem
--    ainda está com ela na mão, e o sintoma é a Tool parar de desenhar em
--    silêncio.
--
--    A pasta fica no `ReplicatedStorage` até o servidor ser desligado, e some
--    com ele. O teto de quanto isso ocupa é o número de MODELOS de Tool que
--    apareceram na partida — não o de jogadores, nem o de Tools equipadas. Um
--    servidor com 30 pessoas usando as mesmas 7 Tools tem 7 pastas.
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

--- Cria a pasta do modelo, ou reutiliza a que já está lá.
---
--- A primeira Tool daquele modelo monta e move os moldes; da segunda em
--- diante, a pasta já existe e a Tool só encontra pronto. É por isso que a
--- segunda porta do `achar` importa mesmo depois da instalação: a Tool que
--- reutiliza continua com os MOLDES DELA dentro de si, intocados — quem moveu
--- foi a primeira.
function Deposito.instalar(tool)
	if not (tool and RunService:IsServer()) then return nil end
	if ligadas[tool] then return Deposito.pasta(tool) end
	ligadas[tool] = true

	local raiz = raizDoDeposito(true)
	local chave = chaveDe(tool)
	local minha = raiz:FindFirstChild(chave)

	if minha then
		-- REUTILIZA. Os moldes desta instância ficam onde estão: já há uma
		-- cópia no depósito, e mover a segunda por cima não acrescenta nada.
		return minha
	end

	minha = Instance.new("Folder")
	minha.Name = chave
	mover(tool, minha)
	minha.Parent = raiz
	return minha
end

--═══════════════════════════════════════════════════════════════
-- LIGAR — a única linha que o Server precisa escrever
--═══════════════════════════════════════════════════════════════

--- Instala quando a Tool chega ao jogador.
---
--- O gatilho é a TROCA DE PAI, não `Tool.Equipped`: a regra diz "mochila OU
--- mão", e uma Tool que fica a partida toda na mochila sem ser equipada também
--- precisa dos moldes no lugar — o dono não é o único que desenha.
---
--- `GetPropertyChangedSignal("Parent")` e não `AncestryChanged`: a proibição
--- do `AncestryChanged` é para CLEANUP, e aqui não há cleanup nenhum para
--- fazer — a pasta fica até o servidor cair.
function Deposito.ligar(tool)
	if not (tool and RunService:IsServer()) then return end

	local function aoTrocarDePai()
		local pai = tool.Parent
		if not pai then return end
		if pai:IsA("Backpack") or pai:FindFirstChildOfClass("Humanoid") then
			Deposito.instalar(tool)
		end
	end

	tool:GetPropertyChangedSignal("Parent"):Connect(aoTrocarDePai)
	aoTrocarDePai()
end

return Deposito
