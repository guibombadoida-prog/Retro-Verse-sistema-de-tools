# -*- coding: utf-8 -*-
"""
servers_reality_v2.py — Retro-Verse / Studios

O CORPO das 7 habilidades do conjunto REALITY. O preâmbulo, o bloco de física,
o despachante e o rodapé estão em FERRAMENTAS/gerar_servers_reality_v2.py; aqui
fica só o que é próprio de cada Tool.

UMA HABILIDADE POR TOOL, E ELA É NO CLIQUE — instrução em pé para este conjunto.

O MAPA ORIGEM → MECÂNICA, que é o que o pedido cobrava ("estudar a lógica"):

  | Tool | Origem | O que a origem fazia | O que fica, e o que muda |
  |---|---|---|---|
  | `Lapada Seca` | `SLAP` | dano de contato | impulso + GIRO, e o desabamento |
  | `Canhao Satelite` | `LowOrbitIonCannon` | feixe + `Explosion` | feixe por raycast + onda por massa |
  | `Arvore Maligna` | `tre` | `Kill` no toque | tronco ancorado + cipó que AMARRA |
  | `Gato Ajudante Boss` | `gravity cat` | NPC com `Humanoid` | corpo físico puxado por `AlignPosition` |
  | `Samsungus` | `samsung` | pancada de contato | arremesso que QUICA (ricochete real) |
  | `Arma de Fisica` | `Physics Gun` | `BodyPosition` infinito | `AlignPosition` com força por massa |
  | `Indutor de Gravidade` | `Gravity Inducer` | `BodyPosition` + APAGAVA peça | `VectorForce` por massa, e NADA é apagado |

O QUE FOI DEIXADO PARA TRÁS DE PROPÓSITO, e por quê:

  · `Gravity Inducer` apagava toda peça solta que tocasse a singularidade, e a
    `Physics Gun` tinha uma tecla que sumia com a peça segurada. Proibido:
    "as habilidades não podem destruir partes".
  · `ClassicSuperball` chamava `humanoid:Destroy()` e clonava o script de
    ragdoll SEIS vezes no mesmo alvo. `desabar()` faz uma vez e VOLTA.
  · `Hot Potato` matava QUEM SEGURAVA. Proibido: "não ferir o próprio jogador".
  · `moller` clonava a peça de verdade e apagava a original. O destroço deste
    conjunto é cosmético e desenhado pelo cliente.
"""

CONJUNTO = {}


# ═══════════════════════════════════════════════════════════════
# 1 · LAPADA SECA — o tapa que joga girando
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Lapada Seca"] = dict(
    objeto="LapadaSeca_Server_V1",
    tool="Lapada Seca",
    sufixo="LapadaSeca",
    arquetipo="Lapada",
    rotulo="tapa em cone; o alvo sai GIRANDO e desaba",
    origem="SLAP",
    alcance_mira=60,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem era dano de contato puro: `Touched` no `Hand`, `TakeDamage`, "
        "e nada mais. O tapa não empurrava — o alvo levava dano e continuava "
        "exatamente onde estava, o que faz um tapa parecer um arranhão.\n"
        "--   Aqui ele tem as duas coisas que faltavam: IMPULSO e GIRO. O giro é "
        "o que separa um tapa de um empurrão; sem `AngularVelocity` o alvo\n"
        "--   desliza para trás em pé, e isso lê como escorregão."),
    cfg="""	RECARGA = 4.0,
	DANO = 26,
	ALCANCE = 13,
	--- cos(50°) — meio cone de 50 graus para cada lado
	COSSENO = 0.64,
	LIMITE = 4,

	EMPURRAO = 78,
	--- Radianos por segundo. 14 é quase dois giros por segundo: dá para ver
	--- o alvo rodar sem virar borrão.
	GIRO = 14,
	SUBIDA = 0.42,
	DESABA = 1.7,
""",
    estado="",
    ao_equipar="",
    ao_guardar="",
    trata_acao="",
    habilidade='''
--══════════════════════════════════════════════════════════════
-- M1 — a lapada
--
-- O beat é UM só, e ele faz três coisas na ordem em que a física acontece:
-- dano, impulso e giro. O `desabar` vem por último de propósito — ragdoll
-- ANTES do impulso amortece o empurrão, porque um corpo mole absorve a força
-- nas juntas em vez de sair inteiro.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CARGA = { sfx = { "CHICOTE", 1.1 } },

		TAPA = {
			sfx = { "TAPA", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.55)

				vfx("TAPA", {
					ponto = centro,
					quadro = CFrame.new(centro, centro + direcao),
				})

				local pegos = alvosNoCone(raiz.Position, direcao, CFG.ALCANCE,
					CFG.COSSENO, CFG.LIMITE)
				for _, alvo in ipairs(pegos) do
					aplicarDano(alvo, CFG.DANO)

					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						-- o tapa levanta um pouco: sem componente vertical o
						-- alvo raspa no chão e o atrito come o empurrão
						local para = (direcao + Vector3.new(0, CFG.SUBIDA, 0)).Unit
						empurrar(alvo, para, CFG.EMPURRAO, 0.24)

						-- e RODA. O eixo é a vertical mais um pouco do lado,
						-- para o giro não ser um pião perfeito.
						giro(alvoRaiz,
							Vector3.new(jitter(1) * 0.3, 1, jitter(2) * 0.3),
							CFG.GIRO, 0.8)

						vfx("GIRO", { ponto = alvoRaiz.Position })
					end

					-- por último: corpo mole absorve força, então o ragdoll
					-- entra DEPOIS de o impulso já estar aplicado
					desabar(alvo, CFG.DESABA)
				end

				-- `ESTOURO` para o acerto, `SEQUENCIA` (o `slaps` da
				-- origem, no plural) quando o cone pega mais de um. O asset
				-- existia e estava mudo; o nome dele já dizia para que era.
				if #pegos >= 2 then
					tocar("SEQUENCIA", 1)
				elseif #pegos > 0 then
					tocar("ESTOURO", 1.05)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 2 · CANHAO SATELITE — o feixe de órbita
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Canhao Satelite"] = dict(
    objeto="CanhaoSatelite_Server_V1",
    tool="Canhao Satelite",
    sufixo="CanhaoSatelite",
    arquetipo="Canhao",
    rotulo="marca o ponto, e a órbita descarrega nele",
    origem="LowOrbitIonCannon",
    alcance_mira=220,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem marcava o ponto e criava um `Explosion` — que é a instância "
        "que o repositório proíbe, porque ela quebra junta e derruba mapa sem "
        "pedir licença.\n"
        "--   O que fica é a FORMA: marca, espera, feixe. O que muda é o miolo. O "
        "feixe desce por RAYCAST, então ele bate no primeiro teto que\n"
        "--   encontrar em vez de atravessar o prédio, e a onda empurra por MASSA "
        "em vez de aplicar `BlastPressure` fixo em tudo."),
    cfg="""	RECARGA = 26.0,
	DANO = 62,
	RAIO = 15,
	ALTURA = 300,

	--- A espera entre a marca e o feixe. É o que dá tempo de sair — e é o que
	--- faz esta ser uma ultimate jogável em vez de um clique que mata.
	ESPERA = 0.9,

	ONDA = 130,
	ONDA_PECA = 90,
	TETO_PECAS = 24,
	DESABA = 2.2,
""",
    estado="",
    ao_equipar="",
    ao_guardar="",
    trata_acao="",
    habilidade='''
--══════════════════════════════════════════════════════════════
-- M1 — o feixe de órbita
--
-- Três tempos, e o do meio é o que importa: MARCA · espera · FEIXE.
--
-- ⛔ NADA AQUI É `Instance.new("Explosion")`. A instância nativa quebra junta
--    (`DestroyJointRadiusPercent`) e derruba geometria do mapa, que são as
--    duas coisas proibidas neste conjunto. A onda é feita à mão, e ela empurra
--    proporcional à MASSA de cada coisa — caixote voa, prédio ancorado não.
--══════════════════════════════════════════════════════════════

--- A onda: empurra para FORA, com a força caindo com a distância.
---
--- Personagem vai pela raiz (nunca por membro, que é como se arranca braço);
--- peça solta vai por `impulso`, com a massa dela mandando no resultado.
local function onda(centro)
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 12)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - centro
			local dist = math.max(delta.Magnitude, 0.5)
			local queda = math.clamp(1 - (dist / CFG.RAIO), 0.15, 1)
			local para = (delta.Unit + Vector3.new(0, 0.7, 0)).Unit

			aplicarDano(alvo, math.floor(CFG.DANO * queda + 0.5))
			empurrar(alvo, para, CFG.ONDA * queda, 0.3)
			desabar(alvo, CFG.DESABA)
		end
	end

	for _, peca in ipairs(pecasEm(centro, CFG.RAIO, CFG.TETO_PECAS)) do
		local delta = peca.Position - centro
		local dist = math.max(delta.Magnitude, 0.5)
		local queda = math.clamp(1 - (dist / CFG.RAIO), 0.1, 1)
		impulso(peca, (delta.Unit + Vector3.new(0, 0.5, 0)).Unit,
			CFG.ONDA_PECA * queda, 0.35)
		giro(peca, Vector3.new(jitter(1), jitter(2), jitter(3)), 6, 0.6)
	end
end

--- O feixe DESCE por raycast, e para no primeiro teto.
---
--- A origem punha o dano na posição mirada e pronto. Com raycast, quem está
--- debaixo de uma laje não leva — que é a diferença entre uma ultimate e uma
--- planilha de dano.
local function pousoDoFeixe(alvo)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(alvo + Vector3.new(0, CFG.ALTURA, 0),
		Vector3.new(0, -(CFG.ALTURA + 40), 0), filtro)
	return batida and batida.Position or alvo
end

function primaria(mira)
	if not (rig and raiz) then return end
	local alvo = noChao(typeof(mira) == "Vector3" and mira or frente(40))

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CHAMA = { sfx = { "CHAMADA", 1 } },

		MARCA = {
			sfx = { "CARGA", 1 },
			faz = function()
				vfx("MARCA", { ponto = alvo, raio = CFG.RAIO,
					vida = CFG.ESPERA })
			end,
		},

		FEIXE = {
			sfx = { "FEIXE", 0.92 },
			faz = function()
				task.delay(CFG.ESPERA, function()
					if not (personagem and personagem.Parent) then return end
					local pouso = pousoDoFeixe(alvo)
					vfx("FEIXE", { ponto = pouso, raio = CFG.RAIO })
					tocarEm("ECO", pouso, 0.88)
					onda(pouso)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 3 · ARVORE MALIGNA — o tronco ancorado, e os cipós que amarram
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Arvore Maligna"] = dict(
    objeto="ArvoreMaligna_Server_V1",
    tool="Arvore Maligna",
    sufixo="ArvoreMaligna",
    arquetipo="Arvore",
    rotulo="ergue a árvore, e os cipós AMARRAM quem chega perto",
    origem="tre",
    alcance_mira=70,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem tinha a árvore com um `Touched` que matava, e ela ficava "
        "SOLTA — caía, rolava, e às vezes matava o próprio dono ao tombar.\n"
        "--   Duas coisas foram pedidas explicitamente sobre esta Tool: "
        "**ancorar a árvore**, e **não ferir o próprio jogador**. As duas estão\n"
        "--   cumpridas aqui — o tronco é ancorado e o `ehMinha()` filtra o dono. "
        "O que entra de novo é a corda: `RopeConstraint` de verdade, e é a\n"
        "--   primeira Tool do repositório a usar uma. Quem é amarrado corre, "
        "estica, e volta em arco — não desliza em linha reta."),
    cfg="""	RECARGA = 22.0,
	DANO_TIQUE = 9,
	RAIO = 17,
	VIDA = 6.0,

	--- Comprimento da corda. Menor que o raio de propósito: quem é laçado na
	--- borda é PUXADO para dentro antes de a corda ficar frouxa.
	CORDA = 11,
	TETO_AMARRAS = 6,

	PERIODO = 0.55,
	PUXAO = 34,
""",
    estado="""local amarras = {}
local tronco = nil""",
    ao_equipar="",
    ao_guardar="\tdesamarrarTudo()\n\trecolherTronco()\n",
    trata_acao="",
    habilidade='''
--══════════════════════════════════════════════════════════════
-- ⛔ O TRONCO É ANCORADO, E ELE É A ÚNICA PEÇA DE SERVIDOR DESTA TOOL
--
-- Foi pedido nestas palavras: "ancora a tre". A origem deixava a árvore solta,
-- e ela tombava — em cima de quem estivesse por perto, inclusive o dono.
--
-- Ancorada, ela é um obstáculo: bloqueia tiro, dá cobertura, e as pessoas
-- correm em volta dela. É melhor de jogar E cumpre o pedido.
--
-- E ela é RECOLHIDA por três portas — o prazo, o `Unequipped` e o
-- `Destroying`. Peça de servidor esquecida no mapa fica até o servidor cair.
--══════════════════════════════════════════════════════════════

local function recolherTronco()
	if tronco and tronco.Parent then
		tronco.CanCollide = false
		tronco.Parent = nil
	end
	tronco = nil
end

local function erguerTronco(centro)
	recolherTronco()

	local p = Instance.new("Part")
	p.Name = PREFIXO .. "_Tronco"
	p.Anchored = true                 -- ⛔ o pedido, em uma linha
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = Vector3.new(3.2, 11, 3.2)
	p.Material = Enum.Material.Wood
	p.Color = Color3.fromRGB(84, 62, 44)
	p.CFrame = CFrame.new(centro + Vector3.new(0, 5.5, 0))
	p.Parent = workspace
	tronco = p

	task.delay(CFG.VIDA, function()
		if tronco == p then recolherTronco() end
	end)
	return p
end

--══════════════════════════════════════════════════════════════
-- OS CIPÓS — `RopeConstraint`, e é a primeira do repositório
--
-- `amarrar()` devolve a função que desamarra, e ela é OBRIGATÓRIA de guardar.
-- Corda pendurada num jogador cuja Tool sumiu é um jogador preso a um ponto do
-- mapa para sempre, e não há tecla que resolva isso do lado dele.
--══════════════════════════════════════════════════════════════

local function desamarrarTudo()
	for _, reg in ipairs(amarras) do
		if reg.desamarrar then reg.desamarrar() end
	end
	table.clear(amarras)
end

local function jaAmarrado(alvoHum)
	for _, reg in ipairs(amarras) do
		if reg.hum == alvoHum then return true end
	end
	return false
end

local function lacar(alvoHum, ancora)
	if #amarras >= CFG.TETO_AMARRAS then return end
	if jaAmarrado(alvoHum) then return end

	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return end

	local desamarrar = amarrar(alvoRaiz, ancora, CFG.CORDA, 0.3)
	table.insert(amarras, { hum = alvoHum, desamarrar = desamarrar })

	vfx("CIPO", { de = ancora.Position, ate = alvoRaiz.Position,
		vida = CFG.VIDA })
	tocarEm("GALHO", alvoRaiz.Position, 1)

	-- o puxão inicial: a corda sozinha só IMPEDE de sair, ela não traz para
	-- dentro. O impulso é o que faz o laço parecer um laço.
	local para = ancora.Position - alvoRaiz.Position
	if para.Magnitude > 1 then
		empurrar(alvoHum, (para.Unit + Vector3.new(0, 0.3, 0)).Unit,
			CFG.PUXAO, 0.25)
	end
end

--══════════════════════════════════════════════════════════════
-- M1 — plantar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(12))

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		PLANTA = {
			sfx = { "GALHO", 1.15 },
			faz = function()
				vfx("ARVORE", { ponto = centro, vida = CFG.VIDA })
				erguerTronco(centro)
			end,
		},

		RAIZ = {
			faz = function()
				local ancora = tronco
				if not (ancora and ancora.Parent) then return end

				--- O laço não é um tique de dano com nome bonito: ele roda por
				--- prazo, laça QUEM CHEGA (não só quem já estava), e o dano é
				--- pequeno. Quem fica preso perto da árvore sangra devagar; a
				--- ameaça é ficar preso, não o número.
				local ate = os.clock() + CFG.VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					if not (ancora and ancora.Parent) then return end
					acumulado = acumulado + dt
					if acumulado < CFG.PERIODO then return end
					acumulado = 0

					for _, alvo in ipairs(alvosEm(ancora.Position, CFG.RAIO, 8)) do
						lacar(alvo, ancora)
						aplicarDano(alvo, CFG.DANO_TIQUE)
					end
				end))

				task.delay(CFG.VIDA, desamarrarTudo)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 4 · GATO AJUDANTE BOSS — o corpo físico que persegue
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Gato Ajudante Boss"] = dict(
    objeto="GatoAjudanteBoss_Server_V1",
    tool="Gato Ajudante Boss",
    sufixo="GatoAjudanteBoss",
    arquetipo="Gato",
    rotulo="invoca o gato, que persegue POR FÍSICA até o prazo",
    origem="gravity cat not amused",
    alcance_mira=60,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem era um spawner de NPC: `Humanoid`, seis `Motor6D`, script de "
        "`Animate` de 483 linhas e uma IA própria. O `CLAUDE.md` põe NPC fora "
        "de escopo, e com razão — manter sistema de NPC não é habilidade de Tool.\n"
        "--   O que fica é a INVOCAÇÃO, e ela ganha o que a origem não tinha: o "
        "gato é um corpo FÍSICO. Ele não teleporta atrás do alvo por CFrame; ele\n"
        "--   é puxado por `AlignPosition`, então ele colide, atrasa nas curvas, "
        "bate nas coisas e pode ser empurrado. E é isto que resolve a proibição\n"
        "--   mais dura do repositório: **servidor não move geometria por quadro**. "
        "Quem move o gato é o solver, e a replicação sai de graça."),
    cfg="""	RECARGA = 30.0,
	VIDA = 12.0,
	DANO = 15,

	--- A que distância do alvo o gato tenta ficar. Zero faria ele entrar
	--- dentro da pessoa e o motor o expulsaria para um lado qualquer.
	PARADA = 4.0,
	BUSCA = 55,
	ALTURA = 2.6,

	--- O toque tem carência: sem ela, um gato encostado dá dano por quadro.
	CARENCIA = 0.8,
	EMPURRAO = 46,
""",
    estado="""local gato = nil
local ultimoToque = 0""",
    ao_equipar="",
    ao_guardar="\tdispensarGato()\n",
    trata_acao="",
    habilidade='''
--══════════════════════════════════════════════════════════════
-- O GATO — um corpo físico, e NÃO um NPC
--
-- ⛔ ESTA É A PROIBIÇÃO MAIS CARA DO REPOSITÓRIO, e é onde ela morde:
--
--    **servidor não move geometria por quadro.** Peça ancorada cujo `CFrame` o
--    servidor escreve replica a ~20 Hz e SEM interpolação — na tela dos outros
--    o gato pisca de um lugar para outro.
--
--    A saída não é escrever mais rápido. É não escrever: o gato é solto, e
--    quem o move é `AlignPosition`. O servidor só diz PARA ONDE, e o solver
--    faz o resto — de graça, e com colisão.
--
-- O corpo é o `Torso` do molde da origem, solto e visível. O resto do gato é
-- soldado nele com `WeldConstraint`, então a montagem inteira tem uma massa só
-- e se move como um corpo.
--══════════════════════════════════════════════════════════════

local function dispensarGato()
	if gato and gato.Parent then
		gato.Parent = nil
	end
	gato = nil
end

--- Monta o gato a partir do molde. `nil` se o molde não vier junto — e nesse
--- caso a habilidade não acontece, em vez de invocar uma caixa sem nome.
local function montarGato(onde)
	local base = Deposito.achar(script, "Moldes")
	local modelo = base and base:FindFirstChild("Gravity Cat Not Amused")
	if not modelo then return nil end

	local copia = modelo:Clone()
	local corpo = copia:FindFirstChild("Torso")
	if not corpo or not corpo:IsA("BasePart") then
		copia:Destroy()   -- é MINHA cópia, criada linhas acima: não é peça do mapa
		return nil
	end

	corpo.Anchored = false
	corpo.CanCollide = true
	corpo.Transparency = 0

	for _, d in ipairs(copia:GetDescendants()) do
		if d:IsA("BasePart") and d ~= corpo then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			d.Transparency = 0
			local w = Instance.new("WeldConstraint")
			w.Part0 = corpo
			w.Part1 = d
			w.Parent = corpo
		end
	end

	copia.Name = PREFIXO .. "_Gato"
	corpo.CFrame = CFrame.new(onde + Vector3.new(0, CFG.ALTURA, 0))
	copia.Parent = workspace

	-- e ele FLUTUA: `AlignPosition` sozinho puxa para o ponto, mas sem
	-- orientação o gato roda no eixo e fica de cabeça para baixo
	local ao = Instance.new("AlignOrientation")
	ao.Name = PREFIXO .. "_AO"
	ao.Attachment0 = pontoDe(corpo, "Cabeca")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.MaxTorque = math.max(corpo.AssemblyMass, 0.1) * CFG.TORQUE_POR_MASSA * 4
	ao.Responsiveness = 18
	ao.Parent = corpo

	return copia, corpo
end

--- O alvo mais próximo do gato, ou `nil`. Nunca o dono: `alvosEm` já filtra o
--- `personagem`, e `ehMinha` cobre o resto.
local function presaDe(corpo)
	local melhor, menor = nil, math.huge
	for _, alvo in ipairs(alvosEm(corpo.Position, CFG.BUSCA, 10)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local d = (alvoRaiz.Position - corpo.Position).Magnitude
			if d < menor then melhor, menor = alvo, d end
		end
	end
	return melhor
end

--══════════════════════════════════════════════════════════════
-- M1 — chamar o gato
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end
	local onde = noChao(typeof(mira) == "Vector3" and mira or frente(8))

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		ASSOBIO = { sfx = { "MIADO", 1.2 } },

		SOLTA = {
			sfx = { "MIADO", 0.9 },
			faz = function()
				dispensarGato()
				local copia, corpo = montarGato(onde)
				if not copia then return end
				gato = copia

				vfx("GATO", { ponto = onde })

				--- A PERSEGUIÇÃO. Repare no que este laço NÃO faz: ele não
				--- escreve `CFrame` em lugar nenhum. Ele só atualiza o destino
				--- do `AlignPosition`, uma propriedade — e o solver move.
				local ate = os.clock() + CFG.VIDA
				guardar(RunService.Heartbeat:Connect(function()
					if os.clock() > ate then
						if gato == copia then dispensarGato() end
						return
					end
					if not (corpo and corpo.Parent) then return end

					local presa = presaDe(corpo)
					if not presa then
						-- sem alvo, ele volta para perto de quem o chamou
						if raiz then
							segurar(corpo, raiz.Position
								+ raiz.CFrame.LookVector * 5
								+ Vector3.new(0, CFG.ALTURA, 0))
						end
						return
					end

					local presaRaiz = raizDe(presa)
					if not presaRaiz then return end

					local delta = presaRaiz.Position - corpo.Position
					local dist = delta.Magnitude
					local destino = presaRaiz.Position
						- delta.Unit * CFG.PARADA
						+ Vector3.new(0, CFG.ALTURA * 0.5, 0)
					segurar(corpo, destino)

					if dist <= CFG.PARADA + 1.5
							and os.clock() - ultimoToque >= CFG.CARENCIA then
						ultimoToque = os.clock()
						aplicarDano(presa, CFG.DANO)
						empurrar(presa,
							(delta.Unit + Vector3.new(0, 0.4, 0)).Unit,
							CFG.EMPURRAO, 0.2)
						tocarEm("MIADO", corpo.Position, 1.3)
					end
				end))

				task.delay(CFG.VIDA, function()
					if gato == copia then dispensarGato() end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 5 · SAMSUNGUS — o arremesso que quica
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Samsungus"] = dict(
    objeto="Samsungus_Server_V1",
    tool="Samsungus",
    sufixo="Samsungus",
    arquetipo="Samsungus",
    rotulo="arremessa o aparelho, que QUICA e estoura no fim",
    origem="samsung",
    alcance_mira=140,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem era pancada de contato com o aparelho na mão. O que ela tem "
        "de aproveitável não está nela: está na `ClassicSuperball` do MESMO "
        "arquivo, que arremessava uma peça com `Elasticity = 1` e\n"
        "--   `Friction = 0` — uma bola que ricocheteia de verdade. Só que o "
        "jeito dela era `missile.Velocity = direction * 200`, e a 60 Hz isso é\n"
        "--   um salto de 3,3 studs por quadro: a peça atravessa parede fina e o "
        "`Touched` nunca dispara.\n"
        "--   Aqui o quique é REAL e não atravessa nada: o projétil é integrado à "
        "mão e entre dois passos vai um raycast, com reflexão v' = v - 2(v·n)n."),
    cfg="""	RECARGA = 9.0,
	DANO = 34,
	DANO_QUIQUE = 16,

	VELOCIDADE = 105,
	QUIQUES = 3,
	--- Quanto da velocidade sobra depois de bater. 0.86 dá três quiques que
	--- ainda vão a algum lugar; acima de 0.95 o aparelho vira pinball eterno.
	PERDA = 0.86,
	VIDA_VOO = 3.6,

	RAIO_ESTOURO = 11,
	ONDA = 96,
	TETO_PECAS = 20,
	DESABA = 1.6,
""",
    estado="",
    ao_equipar="",
    ao_guardar='\tguardarAparelho()\n',
    trata_acao="",
    habilidade='''
--- O `unequip` da origem, que é o som de guardar o aparelho no bolso. Ele
--- existia no modelo e não era tocado por nada — asset depositado e mudo.
local function guardarAparelho()
	tocar("GUARDA", 1)
end

--══════════════════════════════════════════════════════════════
-- M1 — o arremesso
--
-- O aparelho voa em ARCO (a aceleração é a gravidade do `workspace`), QUICA
-- em parede e chão, e estoura no fim — por prazo, por acertar alguém, ou por
-- gastar os quiques.
--
-- Nada disso é uma `Part` física. O que voa é um ponto, e o cliente desenha o
-- rastro. É o método do FastCast, e o motivo é o parágrafo do cabeçalho.
--══════════════════════════════════════════════════════════════

local function estourar(ponto)
	vfx("ESTOURO", { ponto = ponto, raio = CFG.RAIO_ESTOURO })
	tocarEm("IMPACTO", ponto, 0.95)

	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_ESTOURO, 10)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - ponto
			local queda = math.clamp(
				1 - (delta.Magnitude / CFG.RAIO_ESTOURO), 0.2, 1)
			aplicarDano(alvo, math.floor(CFG.DANO * queda + 0.5))
			empurrar(alvo, (delta.Unit + Vector3.new(0, 0.6, 0)).Unit,
				CFG.ONDA * queda, 0.26)
			desabar(alvo, CFG.DESABA)
		end
	end

	for _, peca in ipairs(pecasEm(ponto, CFG.RAIO_ESTOURO, CFG.TETO_PECAS)) do
		local delta = peca.Position - ponto
		local queda = math.clamp(1 - (delta.Magnitude / CFG.RAIO_ESTOURO), 0.15, 1)
		impulso(peca, (delta.Unit + Vector3.new(0, 0.4, 0)).Unit,
			CFG.ONDA * 0.7 * queda, 0.3)
	end
end

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CARGA = { sfx = { "GIRO", 1.1 } },

		ARREMESSA = {
			sfx = { "BATE", 1 },
			faz = function()
				if not raiz then return end
				local saida = raiz.Position + raiz.CFrame.LookVector * 2.4
					+ Vector3.new(0, 1.6, 0)

				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - saida
					if delta.Magnitude > 2 then
						-- um pouco para cima: arremesso reto cai antes do alvo,
						-- porque a gravidade age o voo inteiro
						direcao = (delta.Unit + Vector3.new(0, 0.22, 0)).Unit
					end
				end

				local acabou = false
				local function fim(ponto)
					if acabou then return end
					acabou = true
					estourar(ponto)
				end

				dispararProjetil(saida, direcao, CFG.VELOCIDADE, {
					quiques = CFG.QUIQUES,
					perda = CFG.PERDA,
					vida = CFG.VIDA_VOO,
					raio = 0.6,

					aoAndar = function(pos)
						vfx("LINHA", { de = pos, ate = pos
							+ Vector3.new(0, 0.4, 0), massa = 4 })
					end,

					--- `true` para PARAR, `false` para QUICAR. Bateu em gente,
					--- acabou; bateu em parede, ricocheteia.
					aoBater = function(batida, _vel, restantes)
						local modelo = batida.Instance
							and batida.Instance:FindFirstAncestorOfClass("Model")
						local hum = modelo
							and modelo:FindFirstChildOfClass("Humanoid")

						if hum and hum ~= humanoide and hum.Health > 0 then
							return true
						end

						if restantes > 0 then
							vfx("QUIQUE", { ponto = batida.Position,
								normal = batida.Normal })
							tocarEm("QUICA", batida.Position, 1.15)
							return false
						end
						return true
					end,

					aoFim = fim,
				})
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 6 · ARMA DE FISICA — a garra
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Arma de Fisica"] = dict(
    objeto="ArmadeFisica_Server_V1",
    tool="Arma de Fisica",
    sufixo="ArmadeFisica",
    arquetipo="ArmaFisica",
    rotulo="segura a peça no ar; solta com a velocidade que ela tinha",
    origem="Physics Gun",
    alcance_mira=90,
    garra=True,
    hz=20,
    nota_origem=(
        "A origem é a Tool do PRIMEIRO vetor do backdoor — o `qPerfectionWeld` "
        "que busca em `assetimport.org` e passa para `require()`. Nada dela "
        "atravessou; a mecânica foi lida e reescrita.\n"
        "--   E a mecânica valia a leitura: `BodyPosition` na peça mirada, "
        "mantida a uma distância do cano, seguindo o mouse. O problema é que o\n"
        "--   `maxForce` dela era `math.huge*math.huge` — força infinita, que "
        "arrasta um prédio com a mesma facilidade que um cubo. Nada tinha peso.\n"
        "--   Aqui é `AlignPosition` com `MaxForce ∝ massa` e `Responsiveness` que "
        "CAI com a massa: a peça pesada chega atrasada, balança, e bate nas\n"
        "--   coisas no caminho. E ao soltar ela sai com a velocidade que já "
        "tinha, que é o que transforma a garra numa arma."),
    cfg="""	RECARGA = 0.35,
	ALCANCE = 85,

	--- A distância a que a peça flutua do cano. A origem deixava o jogador
	--- mudá-la com Q/E; este conjunto é só clique, então ela sai da distância
	--- em que a peça foi pega — e é isso que dá controle sem uma tecla.
	MIN_DIST = 6,
	MAX_DIST = 60,

	--- Peça pesada demais não é segurável. Sem teto, um jogador anda com um
	--- pedaço de prédio pendurado e o servidor simula isso o tempo todo.
	MASSA_MAX = 900,

	--- O arremesso: a peça sai com a velocidade que tinha, MAIS este empurrão
	--- na direção da mira.
	ARREMESSO = 90,
""",
    estado="""local presa = nil
local distancia = 0
local alvoAtual = nil""",
    ao_equipar="",
    ao_guardar="\tlargar(false)\n",
    trata_acao='''	if acao == "PEGA" then
		if not podeAgir() then return end
		if not pronto(ultimoUso, CFG.RECARGA) then return end
		ultimoUso = os.clock()
		primaria(mira)
		return
	elseif acao == "MIRA" then
		apontar(mira)
		return
	elseif acao == "SOLTA" then
		largar(true)
		return
	end
''',
    habilidade='''
--══════════════════════════════════════════════════════════════
-- A GARRA — pegar, sustentar, largar
--
-- ⛔ O QUE A ORIGEM FAZIA E NÃO ATRAVESSOU: ela tinha uma tecla que fazia
--    `object.Parent = nil` na peça segurada, e outra que criava um `Explosion`
--    em cima dela. As duas destroem peça do mapa, e isso está proibido.
--
--    Esta garra é reversível por construção: `soltarPeca()` tira SÓ o que esta
--    Tool pendurou, e a peça volta a ser exatamente o que era.
--══════════════════════════════════════════════════════════════

--- A peça que o raio da mira encontra, se ela puder ser pega.
---
--- Ancorada não pode (é cenário, e forçá-la seria mover o mapa). Peça de
--- personagem não pode (arrancar alguém pelo braço não é física, é bug). Minha
--- não pode. Pesada demais não pode.
local function candidata(mira)
	if not raiz then return nil end
	local de = raiz.Position + Vector3.new(0, 1.4, 0)
	local delta = mira - de
	if delta.Magnitude < 0.5 then return nil end

	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }

	local batida = workspace:Raycast(de,
		delta.Unit * math.min(delta.Magnitude, CFG.ALCANCE), filtro)
	if not batida then return nil end

	local peca = batida.Instance
	if not (peca and peca:IsA("BasePart")) then return nil end
	if peca.Anchored or ehMinha(peca) then return nil end

	local modelo = peca:FindFirstAncestorOfClass("Model")
	if modelo and modelo:FindFirstChildOfClass("Humanoid") then return nil end
	if peca.AssemblyMass > CFG.MASSA_MAX then return nil end

	return peca, batida.Position
end

--- Onde a peça deve flutuar: na linha da mira, à distância em que foi pega.
local function pontoDeSustento(mira)
	if not raiz then return nil end
	local de = raiz.Position + Vector3.new(0, 1.4, 0)
	local delta = mira - de
	if delta.Magnitude < 0.5 then return nil end
	return de + delta.Unit * distancia
end

--- Larga. `arremessar` decide se ela sai empurrada ou só cai.
---
--- Chamado de TRÊS lugares — o botão subindo, o `Unequipped` e o `desmontar`.
--- Peça com `AlignPosition` órfã fica puxando para um ponto no vazio até o
--- servidor cair, e por isso a saída não pode depender só do jogador soltar.
local function largar(arremessar)
	local peca = presa
	presa = nil
	if not (peca and peca.Parent) then return end

	soltarPeca(peca)

	if arremessar and raiz then
		local para = (alvoAtual or frente(20)) - peca.Position
		if para.Magnitude > 1 then
			-- ela já tem a velocidade que a garra lhe deu; isto é o SOMA
			impulso(peca, para.Unit, CFG.ARREMESSO, 0.18)
		end
		vfx("SOLTA", { ponto = peca.Position, massa = peca.AssemblyMass,
			direcao = para.Magnitude > 1 and para.Unit or Vector3.new(0, 1, 0) })
		tocar("SOLTA", 1.05)
	end

	if rig then
		rig:PlaySequence("SOLTAR", despachar({
			SOLTA = { sfx = { "SOLTA", 1.1 } },
		}))
	end
end

--- Atualiza o destino enquanto o botão está apertado.
---
--- Repare: ele NÃO escreve `CFrame`. Ele muda uma propriedade do
--- `AlignPosition`, e o solver move a peça — com colisão, com atraso, e com o
--- balanço que faz o jogador sentir o peso.
local function apontar(mira)
	alvoAtual = mira
	local peca = presa
	if not (peca and peca.Parent) then
		presa = nil
		return
	end
	if peca.Anchored then
		largar(false)
		return
	end

	local destino = pontoDeSustento(mira)
	if not destino then return end
	segurar(peca, destino)

	if raiz then
		vfx("LINHA", {
			de = raiz.Position + Vector3.new(0, 1.4, 0),
			ate = peca.Position,
			massa = peca.AssemblyMass,
		})
	end
end

--══════════════════════════════════════════════════════════════
-- M1 (botão descendo) — travar na peça
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end
	if typeof(mira) ~= "Vector3" then return end

	-- já segurando: o clique novo troca de peça, e a antiga é largada limpa
	if presa then largar(false) end

	local peca, onde = candidata(mira)
	if not peca then return end

	presa = peca
	alvoAtual = mira
	distancia = math.clamp(
		(onde - (raiz.Position + Vector3.new(0, 1.4, 0))).Magnitude,
		CFG.MIN_DIST, CFG.MAX_DIST)

	rig:PlaySequence("PRIMARIA", despachar({
		TRAVA = {
			sfx = { "TRAVA", 1 },
			faz = function()
				vfx("TRAVA", { ponto = onde })
			end,
		},
	}))

	apontar(mira)
end
''')


# ═══════════════════════════════════════════════════════════════
# 7 · INDUTOR DE GRAVIDADE — o poço
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Indutor de Gravidade"] = dict(
    objeto="IndutordeGravidade_Server_V1",
    tool="Indutor de Gravidade",
    sufixo="IndutordeGravidade",
    arquetipo="Indutor",
    rotulo="abre um poço: a força sobe com a MASSA de cada peça",
    origem="Gravity Inducer",
    alcance_mira=170,
    garra=False,
    hz=20,
    nota_origem=(
        "A origem tinha a ideia certa e duas execuções erradas. A ideia: força "
        "proporcional à massa (`massforce = item:GetMass() * force`), que é a "
        "única forma de um poço parecer gravidade.\n"
        "--   Os erros: primeiro, `BodyPosition` — força de mola para um PONTO, "
        "então a peça chega, para, e fica colada no centro como um ímã. Poço\n"
        "--   de verdade acelera, e a coisa PASSA do centro e volta. Segundo, e "
        "pior: a singularidade tinha um `Touched` que APAGAVA toda peça solta\n"
        "--   que a tocasse, e a Tool ainda destruía o membro do alvo que "
        "acertasse. As duas coisas estão proibidas aqui, e nenhuma atravessou.\n"
        "--   E a origem varria `workspace:GetDescendants()` RECURSIVAMENTE a "
        "cada 0.25 s por 3.5 s — o place inteiro, quatorze vezes."),
    cfg="""	RECARGA = 20.0,
	RAIO = 19,
	VIDA = 2.4,
	DANO_TIQUE = 7,

	--- Força por unidade de massa, no CENTRO. Cai linearmente até a borda.
	FORCA = 210,
	PUXAO_HUM = 40,
	PERIODO = 0.18,
	TETO_PECAS = 30,

	--- O colapso, quando o poço fecha: o que sobrou é cuspido para fora.
	COLAPSO = 118,
	DESABA = 1.9,
""",
    estado="""local tocadas = {}""",
    ao_equipar="",
    ao_guardar="\tliberarTocadas()\n",
    trata_acao="",
    habilidade='''
--══════════════════════════════════════════════════════════════
-- O POÇO — `VectorForce` por massa, e NADA é apagado
--
-- ⛔ AS DUAS PROIBIÇÕES DO CONJUNTO ESTÃO AS DUAS NESTA TOOL, e é por isso que
--    ela é a última do arquivo:
--
--    1. a origem APAGAVA toda peça solta que tocasse a singularidade, e ainda
--       destruía o membro do alvo acertado. Aqui nada é apagado: o que o poço
--       faz com uma peça é pendurar uma `VectorForce` nela, e `liberarTocadas`
--       tira essa força de volta. A peça sai exatamente como entrou.
--
--    2. o poço puxa TUDO num raio, e "tudo" inclui quem o abriu. `ehMinha()`
--       é consultado dentro de `atrairPeca` e de `empurrar`, e `alvosEm` já
--       exclui o `personagem` pelo `OverlapParams`. Três camadas, porque esta
--       é a Tool onde esquecer significa o jogador não conseguir mais sair.
--══════════════════════════════════════════════════════════════

--- Devolve toda peça que o poço pendurou. Chamado no fim do poço E no
--- `desmontar()`: força órfã é uma peça que continua sendo puxada para um
--- ponto onde não há mais nada.
local function liberarTocadas()
	for _, peca in ipairs(tocadas) do
		if peca and peca.Parent then soltarPeca(peca) end
	end
	table.clear(tocadas)
end

local function anotarPeca(peca)
	for _, p in ipairs(tocadas) do
		if p == peca then return end
	end
	table.insert(tocadas, peca)
end

--- O colapso: o que sobrou é cuspido para fora, e o poço fecha.
---
--- Sem ele o efeito termina com as coisas paradas no centro, o que lê como
--- "acabou a bateria". Com ele, o poço tem um fim.
local function colapsar(centro)
	vfx("COLAPSO", { ponto = centro, raio = CFG.RAIO })
	tocarEm("COLAPSO", centro, 0.9)

	for _, peca in ipairs(tocadas) do
		if peca and peca.Parent and not peca.Anchored then
			local delta = peca.Position - centro
			if delta.Magnitude > 0.5 then
				impulso(peca, (delta.Unit + Vector3.new(0, 0.5, 0)).Unit,
					CFG.COLAPSO, 0.3)
			end
		end
	end

	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - centro
			if delta.Magnitude > 0.5 then
				empurrar(alvo, (delta.Unit + Vector3.new(0, 0.7, 0)).Unit,
					CFG.COLAPSO, 0.28)
				desabar(alvo, CFG.DESABA)
			end
		end
	end

	liberarTocadas()
end

--══════════════════════════════════════════════════════════════
-- M1 — abrir o poço
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end
	local centro = (typeof(mira) == "Vector3" and mira or frente(24))
		+ Vector3.new(0, 3, 0)

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		ABRE = { sfx = { "TRAVA", 1.1 } },

		POCO = {
			sfx = { "POCO", 1 },
			faz = function()
				vfx("POCO", { ponto = centro, raio = CFG.RAIO,
					vida = CFG.VIDA })

				local ate = os.clock() + CFG.VIDA
				local acumulado = 0
				local aoDano = 0

				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					if acumulado < CFG.PERIODO then return end
					acumulado = 0

					--- PEÇAS: `VectorForce` proporcional à massa, com queda
					--- linear até a borda. A força é REESCRITA a cada período,
					--- não empilhada — `atrairPeca` reusa a mesma constraint.
					for _, peca in ipairs(pecasEm(centro, CFG.RAIO,
							CFG.TETO_PECAS)) do
						if atrairPeca(peca, centro, CFG.FORCA, CFG.RAIO) then
							anotarPeca(peca)
						end
					end

					--- PERSONAGENS: pela RAIZ, sempre. Puxar um membro é como
					--- se arranca um braço, e foi o que a origem fazia.
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							local delta = centro - alvoRaiz.Position
							local dist = math.max(delta.Magnitude, 0.5)
							local queda = math.clamp(1 - (dist / CFG.RAIO), 0.1, 1)
							empurrar(alvo, delta.Unit,
								CFG.PUXAO_HUM * queda, CFG.PERIODO + 0.05)
						end
					end

					--- O dano é lento de propósito: o poço não é um golpe, é
					--- um lugar de onde é difícil sair. Um tique por segundo.
					aoDano = aoDano + CFG.PERIODO
					if aoDano >= 1 then
						aoDano = 0
						for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
							aplicarDano(alvo, CFG.DANO_TIQUE)
						end
					end
				end))

				task.delay(CFG.VIDA, function()
					if personagem and personagem.Parent then
						colapsar(centro)
					else
						liberarTocadas()
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')
