-- {objeto}.lua
-- Script de servidor — {tool}  (Xester, Forma {forma})
--
--═══════════════════════════════════════════════════════════════
-- ESTA TOOL: {rotulo_m1}
--
{origem}--
-- A DISTRIBUIÇÃO
--
--   Forma 1 tem OITO habilidades e vira SETE Tools: `The Final Deal` entra
--   como Extra em `Xester Eclipse Deck`, que é a outra habilidade de clímax
--   dela. Forma 2 tem SEIS e vira SEIS Tools, uma por habilidade. É a
--   `REGRA_DISTRIBUICAO_DE_TOOLS` aplicada ao pé da letra.
--
-- A TROCA DE FORMA, SEM ALCANÇAR NINGUÉM
--
--   `F` transforma, e a Tool que transforma NÃO procura a Tool da outra forma
--   — procurar seria referência para fora, e a Regra nº 1 vence tudo.
--
--   O que ela faz é escrever um Attribute no Character: `XesterForma = 2`.
--   Quem lê, lê sob guarda e com padrão. É estado opcional compartilhado:
--   estado opcional compartilhado, não caminho de instância, não depósito de
--   asset.
--
--   Arraste ESTA Tool sozinha para um place vazio: o atributo não existe, ela
--   o cria com o padrão dela, e a habilidade sai igual.
--
-- A PASSIVA ATRAVESSA AS SETE, PELO MESMO CAMINHO
--
--   A cada TRÊS habilidades da Forma 1 nasce a Carta Coringa, e a próxima sai
--   com dano × 1.6 e raio × 1.25. O contador é `XesterUsos` no Character, e
--   mora no SERVIDOR porque é ele que aplica o dano — deixar o multiplicador
--   no cliente seria deixá-lo com quem pode mentir.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_xester_v3.py. Editar aqui à mão faz as
-- treze derivarem; edite o gerador.
--═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))
{remotes}
--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "{arquetipo}"

--- A forma a que esta Tool pertence. Ela NÃO bloqueia nada: uma Tool da Forma 2
--- na mão de quem está na Forma 1 funciona igual. O número serve para a
--- passiva, que só conta na Forma 1, e para o cajado.
local MINHA_FORMA = {forma}

local CFG = {{
	ALCANCE_MIRA   = 60,

	-- ── a passiva, igual nas sete da Forma 1 ──────────────────
	PASSO_CORINGA  = 3,
	BONUS_DANO     = 1.6,
	BONUS_RAIO     = 1.25,
	VIDA_CORINGA   = 30,

{cfg}
}}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA. `Vector3.new(0/0, 0/0, 0/0)` é um
--    `Vector3` legítimo para o `typeof`; um cliente modificado manda isso,
--    `.Unit` devolve NaN, e força NaN envenena a assembly do alvo. Nenhum
--    `pcall` pega, porque não há erro — a conta só não tem resultado.
--
--    `n ~= n` é o único teste de NaN em Lua: NaN é o único valor que não é
--    igual a si mesmo.
--
-- E RATE LIMIT É DO SERVIDOR. O `Client` limita a 20 Hz e isso não vale nada:
-- quem manda o pacote é o cliente.
--═══════════════════════════════════════════════════════════════

local MIRA_MAX = 400
local PEDIDOS_POR_SEG = 30

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > MIRA_MAX then
		return raiz.Position + delta.Unit * MIRA_MAX
	end
	return v
end

local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= PEDIDOS_POR_SEG
end
local ocupado = false
local ativos = {{}}
local semente, idEfeito = 0, 0
local ultimoM1, ultimoExtra = 0, 0

--- A geração corta laço velho: cada habilidade com prazo incrementa a sua, e o
--- laço confere antes de cada passo. Sem isso, usar a habilidade duas vezes
--- deixa dois laços vivos escrevendo no mesmo `id`.
local geracao = {{}}

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso virariam globais. `limparTudo`
--- e `segundaEtapa` entram na lista porque o corpo de cada Tool as define e o
--- rodapé as chama — sem a declaração, as duas viveriam no ambiente global e
--- duas Tools na mesma sessão brigariam pelo mesmo nome.
local primaria, extra, limparTudo, segundaEtapa
local beatCena, comecarCena, acabarCena
{estado}
