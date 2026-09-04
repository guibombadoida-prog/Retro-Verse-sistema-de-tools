#!/usr/bin/env python3
"""
gerar_servers_magnetismo.py — Retro-Verse / Studios

Escreve o `Server`, o `Client`, o `VFXModule`, o `R6CFrameAnimator`, o
`DepositoVFX` e — no `Colapso Magnetico` — a `CutsceneCam` das 7 Tools do
conjunto MAGNETISMO.

    python3 FERRAMENTAS/preparar_magnetismo.py      # antes
    python3 FERRAMENTAS/gerar_poses_magnetismo.py   # antes
    python3 FERRAMENTAS/gerar_servers_magnetismo.py

TRÊS HABILIDADES POR TOOL — M1 + `R` + `T`. 21 no conjunto.

════════════════════════════════════════════════════════════════════════
O BLOCO DE FÍSICA É IMPORTADO, NÃO COPIADO
════════════════════════════════════════════════════════════════════════

    `BLOCO_FISICA` vem de `gerar_servers_reality_v2.py`. Ele é a família nova
    de constraint — `LinearVelocity`, `AlignPosition`, `AlignOrientation`,
    `VectorForce`, `AngularVelocity`, `RopeConstraint`, `BallSocketConstraint`
    — e magnetismo é literalmente o tema dele.

    Copiar em vez de importar faria duas cópias divergirem em silêncio, e o
    `desabar()`/`levantar()` que mora lá é reversível por construção: uma cópia
    que receba o conserto e outra que não é ragdoll permanente em metade das
    Tools.

════════════════════════════════════════════════════════════════════════
A POLARIDADE — O QUE NENHUM CONJUNTO ANTERIOR TEM
════════════════════════════════════════════════════════════════════════

    As sete Tools se falam. Quem é atingido fica CARREGADO, `NORTE` ou `SUL`,
    por um prazo — e a carga muda o que as OUTRAS seis fazem com ele:

      mesma polaridade   →  repele: o empurrão sai `CFG.BONUS_IGUAL` mais forte
      polaridade oposta  →  atrai:  o puxão sai `CFG.BONUS_OPOSTO` mais forte
      sem carga          →  o efeito normal

    A carga mora num `Attribute` no `Humanoid` do alvo. NÃO é depósito nem
    global: é marca de ENTIDADE EM CAMPO, a mesma natureza e o mesmo lugar da
    tag `creator` que o repositório já usa para creditar abate — e que a regra
    nº 1 sempre permitiu.

    E ela VENCE. `RV_MagPolExpira` guarda o `os.clock()` do fim; quem lê
    confere antes de acreditar. Marca que não vence é modificador permanente, e
    isso é a mesma família do ragdoll que não volta.

════════════════════════════════════════════════════════════════════════
`quando` — O BEAT NO MEIO DO PASSO
════════════════════════════════════════════════════════════════════════

    O `onBeat` do animator dispara no INÍCIO do passo (conferido no
    `R6CFrameAnimator`, linha do `if onBeat then onBeat(kf, index) end`, que
    vem antes do `TweenService:Create`).

    Então `quando` — a fração do passo — é um ATRASO: `time * quando`. O
    despachante daqui é o primeiro do repositório a implementá-lo.

    É o achado nº 4 da triagem, e ele resolve um problema real: até aqui um som
    que devia tocar no meio de um quadro de 0.9 s virava um passo extra só para
    ter onde pendurar a marca.
"""

import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(RAIZ, "Tools")
FERR = os.path.dirname(os.path.abspath(__file__))
DADOS = os.path.join(FERR, "dados")

sys.path.insert(0, FERR)
sys.path.insert(0, DADOS)

# O bloco de física é IMPORTADO do conjunto REALITY, não copiado.
from gerar_servers_reality_v2 import BLOCO_FISICA        # noqa: E402

DOADORA = os.path.join(TOOLS, "Bomba Orbital")
VFX_MAG = os.path.join(DADOS, "VFXModule_Magnetismo.lua")
CUTSCENE = os.path.join(DADOS, "CutsceneCam_Magnetismo.lua")


PREAMBULO = '''-- {objeto}.lua
-- Script de servidor — {tool}  (conjunto MAGNETISMO)
--
--   M1   {rotulo_m1}
--   R    {rotulo_r}   (Extra 1)
--   T    {rotulo_t}   (Extra 2)
--
-- CONJUNTO AUTORAL — o quinto. Não sai de modelo nenhum: a geometria é
-- primitiva soldada, e os SoundId saem do catálogo do Acervo (id de som não se
-- inventa: id chutado é som mudo que nenhum verificador estático pega).
--
--═══════════════════════════════════════════════════════════════
-- O QUE ESTE CONJUNTO TEM QUE NENHUM OUTRO TINHA
--═══════════════════════════════════════════════════════════════
--
--   1. POLARIDADE, e ela ATRAVESSA as sete Tools. Quem é atingido fica
--      carregado NORTE ou SUL por um prazo, e a carga mede o que as outras
--      seis fazem com ele: mesma polaridade repele mais forte, oposta atrai
--      mais forte. É o primeiro conjunto do repositório em que uma Tool
--      depende do que outra fez.
--
--   2. GRUPO DE VARIAÇÃO DE SFX. `Tool/SFX/<PAPEL>` é uma `Folder` quando há
--      mais de uma gravação, e `tocar()` sorteia com peso. A `Bobina de Tesla`
--      tem SEIS gravações de raio no `ARCO`.
--
--   3. `quando` no keyframe: o beat cai no MEIO do passo, não na borda.
--
--   Os três saem de FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_magnetismo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito   = require(Tool:WaitForChild("DepositoVFX"))
{extra_require}
--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "{arquetipo}"

local CFG = {{
	--- 🔒 A fronteira do remote. `MIRA_MAX` corta mira absurda; o teto de
	--- pedidos é o do SERVIDOR — o do cliente não vale nada, porque é o
	--- cliente que manda o pacote.
	MIRA_MAX = 400,
	PEDIDOS_POR_SEG = 30,
	--- Força por unidade de massa, e ela é FINITA. `BodyPosition` com
	--- `maxForce` infinito arrasta um prédio como arrasta um cubo, e por isso
	--- nada feito com ele tem peso.
	FORCA_POR_MASSA = 260,
	TORQUE_POR_MASSA = 90,
	G_PADRAO = 196.2,
	PASSOS_MAX = 600,

	--- POLARIDADE — quanto a carga muda a força.
	---
	--- Mesma polaridade repele; oposta atrai. Os dois bônus são maiores que 1
	--- porque a carga tem de RECOMPENSAR quem montou a combinação: sem isso
	--- ela é enfeite, e ninguém troca de Tool para usá-la.
	CARGA_DURA = 8.0,
	BONUS_IGUAL = 1.55,
	BONUS_OPOSTO = 1.75,

	--- Teto de peças de servidor SIMULTÂNEAS desta Tool. Sem ele um jogador
	--- assenta trinta trilhos e todos ficam.
	TETO_PECAS = 10,

{cfg}
}}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig

--═══════════════════════════════════════════════════════════════
-- 🔒 A FRONTEIRA DO REMOTE — o que chega do cliente é HOSTIL
--
-- ⚠️ `typeof(v) == "Vector3"` NÃO BASTA, e o repositório inteiro dependia
--    dele: eram 217 pontos que conferiam só o TIPO.
--
--    `Vector3.new(0/0, 0/0, 0/0)` é um `Vector3` legítimo para o `typeof`.
--    Um cliente modificado manda isso, `.Unit` devolve NaN, e força NaN
--    aplicada a uma peça envenena a assembly dela — o alvo trava, voa para
--    coordenada absurda, ou o solver do motor engasga. Nenhum `pcall` pega,
--    porque não há erro: a conta simplesmente não tem resultado.
--
--    `n ~= n` é o único teste de NaN que funciona em Lua: NaN é o único valor
--    que não é igual a si mesmo. O teto de 1e6 corta Inf e coordenada absurda
--    na mesma linha.
--
-- E RATE LIMIT É DO SERVIDOR, não do cliente.
--
--    O `Client` já limita a 20 Hz, e isso não vale nada: quem manda o pacote
--    é o cliente, e cliente modificado manda a 2 000 Hz. O limite que conta
--    é o daqui.
--═══════════════════════════════════════════════════════════════

local function numeroFinito(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function miraValida(v)
	if typeof(v) ~= "Vector3" then return false end
	return numeroFinito(v.X) and numeroFinito(v.Y) and numeroFinito(v.Z)
end

--- A mira SANEADA: finita, e dentro do alcance. `nil` se não presta.
---
--- O corte por alcance não é só anticheat: mira a 5 000 studs faria o
--- `noChao()` varrer 400 studs de raycast a partir de um ponto onde não há
--- mapa, e a habilidade nasceria no vazio.
local function sanearMira(v)
	if not miraValida(v) then return nil end
	if not raiz then return nil end
	local delta = v - raiz.Position
	local dist = delta.Magnitude
	if not numeroFinito(dist) then return nil end
	if dist < 0.001 then return v end
	if dist > CFG.MIRA_MAX then
		return raiz.Position + delta.Unit * CFG.MIRA_MAX
	end
	return v
end

--- Janela deslizante de um segundo. Estourou, o pacote é DESCARTADO em
--- silêncio — responder a quem está abusando é ensinar o que passou.
local janelaAbriu, naJanela = 0, 0

local function taxaOk()
	local agora = os.clock()
	if agora - janelaAbriu >= 1 then
		janelaAbriu = agora
		naJanela = 0
	end
	naJanela = naJanela + 1
	return naJanela <= CFG.PEDIDOS_POR_SEG
end
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {{}}
local semente = 0
local idEfeito = 0
local passeAtual = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT
{estado}

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function anguloDe(i)
	return (i or proximo()) * 2.399963
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--═══════════════════════════════════════════════════════════════
-- SOM — GRUPO DE VARIAÇÃO
--
-- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre) OU uma `Folder` com
-- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight").
--
-- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: `tocar()` clona e
-- parenteia no `Handle` PELO SERVIDOR, então a INSTÂNCIA replica e todo mundo
-- ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons diferentes para
-- o mesmo golpe.
--═══════════════════════════════════════════════════════════════

local function sortearNoGrupo(pasta)
	local candidatos, total = {{}}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, {{ som = filho, peso = peso }})
			total = total + peso
		end
	end
	if #candidatos == 0 then return nil end
	if #candidatos == 1 then return candidatos[1].som end

	local sorteio = math.random() * total
	for _, c in ipairs(candidatos) do
		if sorteio < c.peso then return c.som end
		sorteio = sorteio - c.peso
	end
	--- ⚠️ Não é paranoia: `math.random() * total` pode sobrar por
	---    arredondamento e cair fora do laço. A implementação de onde a ideia
	---    veio devolve `nil` aí — um som mudo, calado, de vez em quando.
	return candidatos[#candidatos].som
end

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- Toca numa ÂNCORA PRÓPRIA. Um `Sound` só toca enquanto tem pai no
--- DataModel, e a peça que o carrega pode sair do mundo antes do fim.
local function tocarEm(nome, posicao, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- A GUARDA — O QUE É MEU NÃO É ALVO
--
-- Toda função abaixo consulta ESTA, e nenhuma repete a checagem. Filtro
-- copiado é um lugar a mais para esquecer, e num conjunto que ATRAI esquecer
-- significa o jogador se puxar para dentro do próprio campo.
--═══════════════════════════════════════════════════════════════

local function ehMinha(inst)
	if not inst then return true end
	if personagem and inst:IsDescendantOf(personagem) then return true end
	if inst:IsDescendantOf(Tool) then return true end
	if inst:FindFirstAncestorOfClass("Tool") then return true end
	return false
end

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- `TakeDamage` respeita `ForceField`; escrever em `Health` fura. A tag
-- `creator` é o que credita o abate, e o `Name` vem ANTES do `Parent`.
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	local marca = alvoHum:FindFirstChild("creator")
	if marca then marca.Parent = nil end
	marca = Instance.new("ObjectValue")
	marca.Name = "creator"
	marca.Value = jogador
	marca.Parent = alvoHum
	Debris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	if alvoHum == humanoide then return 0 end
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

local function alvosEm(posicao, raio, limite)
	local achados, vistos = {{}}, {{}}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum ~= humanoide and not vistos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um campo para a frente pega quem está atrás de quem o abriu.
local function alvosNoCone(origem, direcao, alcance, cosseno, limite)
	local achados = {{}}
	for _, alvo in ipairs(alvosEm(origem, alcance, (limite or 12) * 2)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - origem
			if delta.Magnitude > 0.01
					and delta.Unit:Dot(direcao.Unit) >= cosseno then
				table.insert(achados, alvo)
				if #achados >= (limite or 12) then break end
			end
		end
	end
	return achados
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or 20)
end

local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = {{ personagem }}
	local batida = workspace:Raycast(ponto + Vector3.new(0, 8, 0),
		Vector3.new(0, -400, 0), filtro)
	return batida and batida.Position or ponto
end

'''


BLOCO_POLARIDADE = '''
--═══════════════════════════════════════════════════════════════
-- 🧲 A POLARIDADE — o eixo que atravessa as sete Tools
--
-- Nenhum conjunto anterior tem uma mecânica em que uma Tool depende do que
-- OUTRA fez. Esta tem, e é a razão de o conjunto existir como conjunto em vez
-- de sete Tools soltas com o mesmo tema.
--
-- ONDE A CARGA MORA, E POR QUE ALI
--
--   Num `Attribute` do `Humanoid` do alvo. Não é depósito de asset e não é
--   global: é marca de ENTIDADE EM CAMPO, a mesma natureza e o mesmo lugar da
--   tag `creator` que o repositório já usa para creditar abate. Escrever no
--   mundo é saída, e a regra nº 1 sempre permitiu.
--
--   As sete Tools leem e escrevem os MESMOS dois atributos, e isso é de
--   propósito: é o que faz a combinação existir. Nenhuma delas precisa
--   alcançar a outra — elas se falam através do alvo.
--
-- E ELA VENCE
--
--   `RV_MagPolExpira` guarda o `os.clock()` do fim, e quem lê confere antes de
--   acreditar. Marca que não vence é modificador permanente, e isso é a mesma
--   família do ragdoll que não volta.
--═══════════════════════════════════════════════════════════════

local ATRIB_POLO = "RV_MagPolaridade"
local ATRIB_ATE = "RV_MagPolExpira"

--- A polaridade VÁLIDA de um alvo, ou `nil`. Vencida conta como `nil`, e o
--- atributo é limpo na hora — atributo velho pendurado num jogador é dado
--- errado esperando alguém acreditar nele.
local function polaridadeDe(alvoHum)
	if not (alvoHum and alvoHum.Parent) then return nil end
	local polo = alvoHum:GetAttribute(ATRIB_POLO)
	if polo ~= "NORTE" and polo ~= "SUL" then return nil end
	local ate = alvoHum:GetAttribute(ATRIB_ATE)
	if type(ate) ~= "number" or os.clock() > ate then
		alvoHum:SetAttribute(ATRIB_POLO, nil)
		alvoHum:SetAttribute(ATRIB_ATE, nil)
		return nil
	end
	return polo
end

--- Carrega o alvo. Recarregar RENOVA o prazo — carga não empilha em força,
--- só em duração, senão bater dez vezes viraria dano multiplicado por dez.
local function carregar(alvoHum, polo, ponto)
	if not (alvoHum and alvoHum.Parent) or alvoHum == humanoide then return end
	if polo ~= "NORTE" and polo ~= "SUL" then return end
	alvoHum:SetAttribute(ATRIB_POLO, polo)
	alvoHum:SetAttribute(ATRIB_ATE, os.clock() + CFG.CARGA_DURA)
	local alvoRaiz = raizDe(alvoHum)
	vfx("CARGA", {
		ponto = ponto or (alvoRaiz and alvoRaiz.Position) or Vector3.new(),
		polaridade = polo,
	})
end

--- O MULTIPLICADOR. `meu` é a polaridade que ESTA habilidade emite.
---
---   igual   → repele → o EMPURRÃO ganha bônus
---   oposto  → atrai  → o PUXÃO ganha bônus
---   nenhuma → 1
---
--- `atraindo` diz o que a habilidade está fazendo, e é o que decide qual dos
--- dois bônus vale. Sem esse parâmetro, uma habilidade de atração ganharia
--- bônus por repulsão, que é o oposto do que a física diz.
local function fatorDe(alvoHum, meu, atraindo)
	local dele = polaridadeDe(alvoHum)
	if not dele then return 1 end
	local igual = (dele == meu)
	if atraindo then
		return igual and 1 or CFG.BONUS_OPOSTO
	end
	return igual and CFG.BONUS_IGUAL or 1
end

--- Todos os carregados num raio, com a polaridade de cada um. É o que a
--- `Bobina de Tesla` e o `Colapso Magnetico` consomem.
local function carregadosEm(ponto, raio, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(ponto, raio, (limite or 10) * 2)) do
		local polo = polaridadeDe(alvo)
		if polo then
			table.insert(achados, { hum = alvo, polo = polo })
			if #achados >= (limite or 10) then break end
		end
	end
	return achados
end

--- Descarrega TODOS os que esta Tool carregou. Chamado no `desmontar()`.
---
--- Sem isto, um jogador guarda a Tool e o alvo fica com carga fantasma por
--- oito segundos — e a carga muda o que as outras seis Tools fazem com ele.
--- Efeito de status que sobrevive a quem o aplicou é a mesma família do
--- ragdoll que não volta.
local carregados = setmetatable({}, { __mode = "k" })

local function descarregarTudo()
	for alvoHum in pairs(carregados) do
		if alvoHum and alvoHum.Parent then
			alvoHum:SetAttribute(ATRIB_POLO, nil)
			alvoHum:SetAttribute(ATRIB_ATE, nil)
		end
	end
	table.clear(carregados)
end

--- O `carregar` que ANOTA, e é o que as habilidades usam.
local function marcar(alvoHum, polo, ponto)
	carregar(alvoHum, polo, ponto)
	if alvoHum and polaridadeDe(alvoHum) then
		carregados[alvoHum] = true
	end
end

'''


BLOCO_REGISTRO = '''
--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É POSTO NO MUNDO É RECOLHIDO
--
-- Quatro das sete Tools põem `Part` DE SERVIDOR no mundo: o trilho, a bobina,
-- a bola de sucata e a malha. Peça de servidor que fica é lixo permanente no
-- mapa, e `Instance.new` + `Debris:AddItem` NÃO basta — o `Debris` não roda se
-- a thread morrer antes de chamá-lo, e a Tool destruída no meio deixa o
-- trilho no chão até o servidor cair.
--
-- Nada é posto fora de `criar()`. O registro tem TETO e TRÊS saídas: o prazo,
-- o `Unequipped` e o `Destroying`. É o mesmo desenho do conjunto CRIAÇÃO, que
-- foi o primeiro a precisar dele.
--═══════════════════════════════════════════════════════════════

local criadas = {}

local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
		reg.peca.CanCollide = false
		reg.peca.Parent = nil
	end
	reg.peca = nil
end

local function recolherTudo()
	for _, reg in ipairs(criadas) do
		recolher(reg)
	end
	table.clear(criadas)
end

--- Põe uma peça no mundo e a REGISTRA. Única porta.
---
--- `ancorada = false` é para o que tem de ser movido por constraint (a bola de
--- sucata). Peça ancorada cujo `CFrame` o servidor escreve por quadro replica
--- a ~20 Hz e SEM interpolação — é a proibição "servidor não move geometria
--- por frame", e é por isso que a bola é solta e puxada, nunca teleportada.
local function criar(quadro, tamanho, props, vida, ancorada)
	while #criadas >= CFG.TETO_PECAS do
		recolher(table.remove(criadas, 1))
	end

	local p = Instance.new("Part")
	p.Anchored = (ancorada ~= false)
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = tamanho
	p.CFrame = quadro
	p.Material = Enum.Material.Metal
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace

	local reg = { peca = p, ate = os.clock() + vida }
	table.insert(criadas, reg)
	task.delay(vida, function()
		local i = table.find(criadas, reg)
		if i then
			table.remove(criadas, i)
			recolher(reg)
		end
	end)
	return p
end

--- O VIGIA. Cada peça tem prazo próprio e o `task.delay` do `criar` o cobra no
--- caso normal; este laço é a rede embaixo, para quando a thread morrer.
local function vigiar()
	guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		local i = #criadas
		while i >= 1 do
			local reg = criadas[i]
			if agora > reg.ate then
				table.remove(criadas, i)
				recolher(reg)
			end
			i = i - 1
		end
	end))
end
'''


DESPACHANTE = '''
--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — com `quando`
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` NO INÍCIO do
-- passo, antes de o tween começar (conferido no `R6CFrameAnimator`: o
-- `if onBeat then` vem antes do `TweenService:Create`).
--
-- Então `kf.quando` — a fração do passo — é um ATRASO de `time * quando`.
--
-- ⚙️ Este é o primeiro despachante do repositório a implementar isso, e é o
--    achado nº 4 da triagem. Até aqui a marca só podia cair na BORDA de um
--    passo: um som que devia tocar no meio de um quadro de 0.9 s virava um
--    passo extra só para ter onde ser pendurado.
--
--    E o beat ANDA JUNTO com a duração. Mudou o passo de 0.9 para 0.6 e a
--    marca acompanha, porque ela é fração e não segundo.
--
-- ⚠️ O ATRASO PRECISA DE TOKEN. `task.delay` sobrevive ao cancelamento da
--    sequência: sem o `passe`, trocar de habilidade no meio faria o beat da
--    anterior disparar em cima da nova. `passeAtual` sobe a cada sequência, e
--    o disparo confere.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	passeAtual = passeAtual + 1
	local meuPasse = passeAtual

	local function disparar(kf, passo)
		if meuPasse ~= passeAtual then return end
		if not (personagem and personagem.Parent) then return end
		if kf.cam and beatCena then beatCena(passo.marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end

	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end

		local atraso = 0
		if type(passo) == "table" and passo.quando and passo.time then
			atraso = passo.time * math.clamp(passo.quando, 0, 1)
		end
		if atraso <= 0 then
			disparar(kf, passo)
		else
			task.delay(atraso, function() disparar(kf, passo) end)
		end
	end
end

'''


BLOCO_CENA = '''
--═══════════════════════════════════════════════════════════════
-- A CENA — quem assiste, e o que cada um vê
--
-- NÃO é `Players:GetPlayers()`. Quem está do outro lado do mapa não perde a
-- câmera por causa de um ímã alheio. Assistem: quem abriu o colapso, e quem
-- estiver DENTRO do raio.
--═══════════════════════════════════════════════════════════════

local emCena = false

local function abrirCena(ponto, raioCena, nomeBeat)
	if not (jogador and personagem) then return end
	emCena = true

	CutsceneRemote:FireClient(jogador, "INICIO", {
		papel = "INVOCADOR", nome = nomeBeat,
		portador = personagem.Name, ponto = ponto,
	})

	for _, alvo in ipairs(alvosEm(ponto, raioCena, 8)) do
		local corpo = alvo.Parent
		local outro = corpo and Players:GetPlayerFromCharacter(corpo)
		if outro and outro ~= jogador then
			CutsceneRemote:FireClient(outro, "INICIO", {
				papel = "ALVO", nome = nomeBeat,
				portador = personagem.Name, ponto = ponto,
			})
		end
	end
end

local function beatCena(nome, ponto)
	if not emCena then return end
	CutsceneRemote:FireAllClients("BEAT", { nome = nome, ponto = ponto })
end

--- Fechar a cena é caminho que não pode falhar: no fim da sequência, no
--- `desmontar()`, e por prazo do lado do cliente.
local function fecharCena()
	if not emCena then return end
	emCena = false
	CutsceneRemote:FireAllClients("FIM", {})
end
'''

SEM_CENA = '''
--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil
'''


RODAPE = '''
--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e DUAS Extras
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador then return end
	-- 🔒 taxa PRIMEIRO: descartar cedo é o que impede um cliente modificado
	--    de gastar CPU do servidor com trabalho que vai ser jogado fora.
	if not taxaOk() then return end
	mira = sanearMira(mira) or frente()
	if not podeAgir() then return end

	if tecla == "R" then
		if not pronto(ultimoR, CFG.RECARGA_R) then return end
		ultimoR = os.clock()
		extraR(mira)
	elseif tecla == "T" then
		if not pronto(ultimoT, CFG.RECARGA_T) then return end
		ultimoT = os.clock()
		extraT(mira)
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "{sufixo}", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	-- 🔒 o prefixo das constraints passa a carregar o UserId do dono: sem
	--    isso, dois jogadores com a MESMA Tool arrancam as constraints um do
	--    outro na mesma peça. Vem do BLOCO_FISICA, importado do Reality.
	fixarPrefixo()
	vigiar()
{ao_equipar}end)

--- AS DUAS PORTAS, e a terceira coisa que elas fazem: DESCARREGAR.
---
--- Carga que sobrevive a quem a aplicou é modificador permanente num jogador
--- que não tem como tirá-lo — a mesma família do ragdoll que não volta. Some
--- a isso o `passeAtual`, que invalida qualquer beat atrasado ainda na fila.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	passeAtual = passeAtual + 1
	descarregarTudo()
	recolherTudo()
	levantarTodos()
{ao_guardar}	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- NINGUÉM a apaga: ela é do MODELO, e outro jogador pode estar com a irmã.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
'''


CLIENTE = '''-- Client.lua
-- Script com RunContext = Client — {tool}  (conjunto MAGNETISMO)
--
-- LocalScript dentro de uma Tool só roda para o jogador cujo Character a
-- contém. `RunContext = Client` roda em TODO cliente, e nada saiu de dentro
-- da Tool. É por isso que o efeito aparece para o servidor inteiro.
--
-- A animação NÃO está aqui: o rig é do servidor, porque `Weld` criado no
-- cliente não replica.
--
-- DOIS BOTÕES DE CELULAR, EM ALTURAS DIFERENTES
--
--   Com a mesma altura os dois empilham e o de baixo fica inalcançável.
--
-- Gerado por FERRAMENTAS/gerar_servers_magnetismo.py.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local jogador = Players.LocalPlayer

local Tool       = script.Parent
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local VFX        = require(Tool:WaitForChild("VFXModule"))

local ACAO_R = "Magnetismo_{sufixo}_R"
local ACAO_T = "Magnetismo_{sufixo}_T"
local ALCANCE_MIRA = {alcance_mira}

local equipado = false
local rato = nil

--══════════════════════════════════════════════════════════════
-- DESENHO — este trecho roda em TODOS os clientes
--══════════════════════════════════════════════════════════════

VFXRemote.OnClientEvent:Connect(function(tipo, dados)
	if tipo == "APAGAR" or tipo == "PARAR" then
		VFX.Parar(dados and dados.id)
		return
	end
	VFX.Executar(tipo, dados or {{}})
end)

--══════════════════════════════════════════════════════════════
-- MIRA E ENTRADA — só o dono
--══════════════════════════════════════════════════════════════

local function souODono()
	local pai = Tool.Parent
	if not pai then return false end
	if not pai:FindFirstChildOfClass("Humanoid") then return false end
	return Players:GetPlayerFromCharacter(pai) == jogador
end

--- Onde o jogador aponta, limitado ao alcance. A mira viaja JUNTO do pedido,
--- num sentido só: `RemoteFunction` do servidor para o cliente trava a thread
--- do servidor até o cliente responder, e cliente que não responde a trava até
--- o timeout.
local function mira()
	local personagem = jogador.Character
	local origem = personagem and personagem:FindFirstChild("HumanoidRootPart")
	rato = rato or jogador:GetMouse()
	local alvo = rato and rato.Hit and rato.Hit.Position
	if not origem then return alvo or Vector3.new() end
	if not alvo then return origem.Position + origem.CFrame.LookVector * 20 end
	local delta = alvo - origem.Position
	if delta.Magnitude > ALCANCE_MIRA then
		return origem.Position + delta.Unit * ALCANCE_MIRA
	end
	return alvo
end

local function ligarEntrada()
	ContextActionService:BindAction(ACAO_R, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("R", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonR1)
	ContextActionService:SetTitle(ACAO_R, "{rotulo_botao_r}")
	ContextActionService:SetPosition(ACAO_R, UDim2.new(1, -150, 1, -190))

	ContextActionService:BindAction(ACAO_T, function(_nome, estado)
		if estado ~= Enum.UserInputState.Begin then return end
		if not equipado then return end
		AcaoRemote:FireServer("T", mira())
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.T, Enum.KeyCode.ButtonL1)
	ContextActionService:SetTitle(ACAO_T, "{rotulo_botao_t}")
	ContextActionService:SetPosition(ACAO_T, UDim2.new(1, -150, 1, -120))
end

local function desligarEntrada()
	ContextActionService:UnbindAction(ACAO_R)
	ContextActionService:UnbindAction(ACAO_T)
end

Tool.Equipped:Connect(function()
	if not souODono() then return end
	equipado = true
	ligarEntrada()
end)

Tool.Unequipped:Connect(function()
	equipado = false
	desligarEntrada()
	VFX.LimparTudo()
end)

Tool.Activated:Connect(function()
	if not souODono() then return end
	VFXRemote:FireServer(mira())
end)
'''


def main():
    from servers_magnetismo import CONJUNTO

    animator = os.path.join(DOADORA, "R6CFrameAnimator.lua")
    deposito = os.path.join(DOADORA, "DepositoVFX.lua")
    for c in (animator, deposito, VFX_MAG, CUTSCENE):
        if not os.path.exists(c):
            print("falta %s" % os.path.relpath(c, RAIZ))
            return 1

    fonte_animator = open(animator, encoding="utf-8").read()
    fonte_deposito = open(deposito, encoding="utf-8").read()
    fonte_vfx = open(VFX_MAG, encoding="utf-8").read()
    fonte_cut = open(CUTSCENE, encoding="utf-8").read()

    total = 0
    for tool, d in CONJUNTO.items():
        pasta = os.path.join(TOOLS, tool)
        if not os.path.isdir(pasta):
            print("sem pasta Tools/%s — rode preparar_magnetismo.py antes" % tool)
            return 1

        tem_cena = d.get("cutscene", False)
        corpo = (PREAMBULO.format(**d)
                 + BLOCO_FISICA
                 + BLOCO_POLARIDADE
                 + BLOCO_REGISTRO
                 + (BLOCO_CENA if tem_cena else SEM_CENA)
                 + DESPACHANTE
                 + d["corpo"]
                 + RODAPE.format(**d))
        with open(os.path.join(pasta, "%s.lua" % d["objeto"]), "w",
                  encoding="utf-8") as f:
            f.write(corpo)

        with open(os.path.join(pasta, "Client.lua"), "w", encoding="utf-8") as f:
            f.write(CLIENTE.format(**d))

        for alvo, fonte in (("R6CFrameAnimator.lua", fonte_animator),
                            ("DepositoVFX.lua", fonte_deposito),
                            ("VFXModule.lua", fonte_vfx)):
            with open(os.path.join(pasta, alvo), "w", encoding="utf-8") as f:
                f.write(fonte)
        if tem_cena:
            with open(os.path.join(pasta, "CutsceneCam.lua"), "w",
                      encoding="utf-8") as f:
                f.write(fonte_cut.replace("{tool}", tool))

        total = total + 3
        print("  %-20s %5d linhas · M1 + R + T%s"
              % (tool, len(corpo.splitlines()), " · CENA" if tem_cena else ""))

    print("")
    print("7 Tool(s), %d habilidade(s) — a polaridade atravessa as sete." % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
