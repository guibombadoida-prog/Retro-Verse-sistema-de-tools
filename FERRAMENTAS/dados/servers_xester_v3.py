"""
servers_xester_v3.py — as 13 habilidades do Xester, uma por Tool.

Lido por `FERRAMENTAS/gerar_servers_xester_v3.py`.

O CONTRATO DE CADA CORPO

    Define `primaria(mira)` — sempre — e `extra(mira)` quando a Tool tem uma
    habilidade Extra. Define também `limparTudo()`, que o rodapé chama nas
    portas de saída e na morte: efeito com prazo que ninguém desfaz é lixo na
    tela de todo mundo.

    `segundaEtapa()` é opcional. Quando existe, ela diz se o clique atual é a
    metade de trás da mesma habilidade — o portão do Ás, o desabamento do
    castelo, o naipe do arsenal, o estilhaço da coroa. A segunda etapa NÃO paga
    recarga nova: cobrar duas vezes tornaria a segunda metade inalcançável na
    prática.

O QUE O PREÂMBULO JÁ DÁ

    `abrirHabilidade` · `fecharHabilidade` · `comBonus` · `aplicarDano` ·
    `alvosEm` · `maisPerto` · `raizDe` · `frente` · `empurrar` · `puxar` ·
    `prender` · `tombar` · `afrouxar` · `golpearArea` · `curar` · `vfx` ·
    `apagarEfeito` · `novoId` · `novaGeracao` · `tocar` · `tocarEm` ·
    `despachar` · `anguloDe` · `jitter` · `naFaixa` · `formaAtual` ·
    `porCajado` · `tirarCajado` · `ligarAura` · `apagarAura` ·
    `beatCena` · `comecarCena` · `acabarCena`.
"""

CONJUNTO = {}


def T(nome, forma, **kw):
    kw["forma"] = forma
    kw.setdefault("extra", None)
    kw.setdefault("rotulo_extra", None)
    kw.setdefault("estado", "")
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("cutscene", False)
    kw.setdefault("guarda_m1", None)
    CONJUNTO[nome] = kw


R = "═" * 62

#: o guarda padrão do M1: uma recarga, sem segunda etapa
GUARDA_SIMPLES = """	if not pronto(ultimoM1, CFG.RECARGA) then return end
	ultimoM1 = os.clock()
"""

#: o guarda de quem tem segunda etapa — ela não paga recarga nova
GUARDA_DUPLO = """	-- a segunda etapa é a metade de trás da MESMA habilidade: cobrar recarga
	-- de novo por ela a tornaria inalcançável na prática.
	if not segundaEtapa() then
		if not pronto(ultimoM1, CFG.RECARGA) then return end
		ultimoM1 = os.clock()
	end
"""


# ═══════════════════════════════════════════════════════════════
# FORMA 1 — MESTRE DO BARALHO
# ═══════════════════════════════════════════════════════════════

T("Xester Curtain Call", 1,
  objeto="XesterCurtainCall_Server_V1", sufixo="XesterCortina",
  arquetipo="ESPECTRAL",
  rotulo_m1="some em cartas, deixa uma copia e reaparece atras",
  origem=["Q na Forma 1. Cartas do `cards` do modelo, som `1898092341`",
          "(SELA) e `1894958339` (SOME), os dois já em uso no repositório."],
  cfg="""	RECARGA        = 14,
	INVISIVEL      = 1.5,
	TRANSPARENCIA  = 0.85,
	RAIO           = 12,
	DANO           = 32,
	ATORDOA        = 1.6,
	EMPURRAO       = 46,
	ATRAS          = 5,""",
  estado="local copiaId = nil\nlocal transparenciaAntes = nil",
  corpo='''
--''' + R + '''
-- A INVISIBILIDADE GUARDA O QUE HAVIA, E DEVOLVE AQUILO
--
-- Devolver `0` chutado apagaria acessório transparente de propósito e peça
-- semi-transparente de personagem. E `0.85` em vez de `1`: sumir por completo
-- é injogável para quem está do outro lado.
--''' + R + '''

local function aparecer()
	if not transparenciaAntes then return end
	for peca, valor in pairs(transparenciaAntes) do
		if peca and peca.Parent then peca.Transparency = valor end
	end
	transparenciaAntes = nil
end

local function sumir()
	aparecer()
	if not personagem then return end
	transparenciaAntes = {}
	for _, peca in ipairs(personagem:GetDescendants()) do
		if peca:IsA("BasePart") and peca.Name ~= "HumanoidRootPart" then
			transparenciaAntes[peca] = peca.Transparency
			peca.Transparency = math.max(peca.Transparency, CFG.TRANSPARENCIA)
		end
	end
	transparenciaAntes[Handle] = Handle.Transparency
	Handle.Transparency = math.max(Handle.Transparency, CFG.TRANSPARENCIA)
end

function limparTudo()
	novaGeracao("Q")
	apagarEfeito(copiaId)
	copiaId = nil
	aparecer()
end

--''' + R + '''
-- M1 — Curtain Call
--
-- A cópia falsa NÃO tem `Humanoid`, e é de propósito: um boneco com Humanoid
-- entraria na consulta de alvo de todo mundo, inclusive na sua. Ela é
-- silhueta de cartas, e serve como PONTO — o estouro acontece onde o inimigo
-- achava que você estava, não onde você reapareceu.
--''' + R + '''

function primaria(mira)
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("CURTAIN_CALL", despachar({
		CARGA = { sfx = { "CORTINA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ondeSumiu = raiz.Position
			local minha = novaGeracao("Q")

			apagarEfeito(copiaId)
			copiaId = novoId("COPIA")
			vfx("CURTAIN_SOME", { posicao = ondeSumiu })
			vfx("CURTAIN_COPIA", { posicao = ondeSumiu,
				duracao = CFG.INVISIVEL + 0.2, id = copiaId })
			tocarEm("CORTINA", ondeSumiu, 0.95)
			sumir()

			task.delay(CFG.INVISIVEL, function()
				if geracao.Q ~= minha then return end
				aparecer()
				apagarEfeito(copiaId)
				copiaId = nil
				if not (personagem and raiz and raiz.Parent) then return end

				local alvo = maisPerto(ondeSumiu, CFG.RAIO)
				local alvoRaiz = alvo and raizDe(alvo)
				if alvoRaiz then
					local atras = alvoRaiz.Position
						- alvoRaiz.CFrame.LookVector * CFG.ATRAS
					raiz.CFrame = CFrame.new(atras + Vector3.new(0, 1, 0),
						alvoRaiz.Position)
				end

				vfx("CURTAIN_ESTOURA", { posicao = ondeSumiu,
					raio = comBonus(CFG.RAIO) })
				tocarEm("VOLTA", raiz.Position, 1.3)
				tocarEm("CORTINA", ondeSumiu, 0.8)
				for _, quem in ipairs(alvosEm(ondeSumiu,
						comBonus(CFG.RAIO), 12)) do
					aplicarDano(quem, CFG.DANO)
					tombar(quem, CFG.ATORDOA)
					local quemRaiz = raizDe(quem)
					if quemRaiz then
						empurrar(quem, (quemRaiz.Position - ondeSumiu)
							+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.28)
					end
				end
			end)
		end },
	}), fecharHabilidade)
end
''')


T("Xester Four Suits Arsenal", 1,
  objeto="XesterFourSuitsArsenal_Server_V1", sufixo="XesterArsenal",
  arquetipo="ARCANO",
  rotulo_m1="oito cartas orbitando; o clique seguinte dispara o naipe",
  guarda_m1=GUARDA_DUPLO,
  origem=["E na Forma 1. Os quatro Ases saem dos decais do próprio modelo",
          "(1880203893 · 1881287656 · 1881287420 · 1881288034)."],
  cfg="""	RECARGA        = 16,
	DURACAO        = 12,
	CARTAS         = 8,
	ORBITA         = 5,
	PASSO          = 0.25,
	ALCANCE        = 55,
	VOO            = 0.2,
	RAIO           = 6,
	DANO           = 22,
	PERFURA        = 1.45,
	EMPURRAO       = 78,
	RICOCHETES     = 2,
	CURA           = 9,""",
  estado="local arsenalId = nil\nlocal proximoNaipe = 0",
  corpo='''
--''' + R + '''
-- OS QUATRO NAIPES, EM ORDEM FIXA
--
--   Espadas   perfura      dano × 1.45, e ninguém sai do lugar
--   Paus      empurra      dano cheio mais impulso forte
--   Ouros     ricocheteia  pega o alvo, depois o próximo, duas vezes
--   Copas     recupera     bate menos e devolve vida a quem lançou
--
-- A ordem é FIXA, não sorteada: o jogador precisa poder planejar qual sai. É a
-- diferença entre uma habilidade e uma roleta.
--''' + R + '''

local ORDEM_NAIPES = { "ESPADAS", "PAUS", "OUROS", "COPAS" }

function limparTudo()
	novaGeracao("E")
	apagarEfeito(arsenalId)
	arsenalId = nil
	proximoNaipe = 0
end

function segundaEtapa()
	return arsenalId ~= nil
end

--- O anel ACOMPANHA o portador: `MOVER` a cada passo, com o `id`. Guardar a
--- posição de partida deixaria as cartas para trás no primeiro passo dado.
local function seguirArsenal()
	local minha = novaGeracao("E")
	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		while geracao.E == minha and os.clock() < ate do
			if not (personagem and raiz and raiz.Parent
					and humanoide and humanoide.Health > 0) then
				break
			end
			vfx("MOVER", { id = arsenalId, posicao = raiz.Position,
				tempo = CFG.PASSO })
			task.wait(CFG.PASSO)
		end
		if geracao.E == minha then
			apagarEfeito(arsenalId)
			arsenalId = nil
		end
	end)
end

local function erguerAnel()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("ARSENAL", despachar({
		CARGA = { sfx = { "ARSENAL", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(arsenalId)
			arsenalId = novoId("ARSENAL")
			proximoNaipe = 0
			vfx("ARSENAL_ANEL", { posicao = raiz.Position,
				raio = CFG.ORBITA, cartas = CFG.CARTAS,
				duracao = CFG.DURACAO, id = arsenalId })
			tocarEm("ARSENAL", raiz.Position, 1)
			seguirArsenal()
		end },
	}), fecharHabilidade)
end

local function atirarNaipe(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("DISPARA_NAIPE", despachar({
		CARGA = { sfx = { "NAIPE", 1.1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			proximoNaipe = (proximoNaipe % #ORDEM_NAIPES) + 1
			local naipe = ORDEM_NAIPES[proximoNaipe]
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.ALCANCE)

			vfx("NAIPE_ATIRA", { origem = origem, destino = ponto,
				naipe = naipe, voo = CFG.VOO })
			tocarEm("NAIPE", ponto, 1.05)

			local raio = comBonus(CFG.RAIO)
			if naipe == "ESPADAS" then
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.DANO * CFG.PERFURA)
				end
			elseif naipe == "PAUS" then
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.DANO)
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						empurrar(alvo, (alvoRaiz.Position - origem)
							+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.3)
					end
				end
			elseif naipe == "OUROS" then
				-- `jaBatidos` impede o quique de voltar em quem já levou
				local jaBatidos = {}
				local ondeEstou = ponto
				local salto = 0
				while salto <= CFG.RICOCHETES do
					local achado = nil
					for _, alvo in ipairs(alvosEm(ondeEstou, raio * 2.6, 10)) do
						if not jaBatidos[alvo] then
							achado = alvo
							break
						end
					end
					if not achado then break end
					jaBatidos[achado] = true
					local achadoRaiz = raizDe(achado)
					local proxima = achadoRaiz and achadoRaiz.Position
						or ondeEstou
					if salto > 0 then
						vfx("NAIPE_ATIRA", { origem = ondeEstou,
							destino = proxima, naipe = "OUROS",
							voo = CFG.VOO })
					end
					aplicarDano(achado, CFG.DANO)
					ondeEstou = proxima
					salto = salto + 1
				end
			else
				for _, alvo in ipairs(alvosEm(ponto, raio, 8)) do
					aplicarDano(alvo, CFG.DANO * 0.7)
				end
				if curar(CFG.CURA) > 0 then
					vfx("NAIPE_COPAS_CURA", { posicao = raiz.Position })
				end
			end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		atirarNaipe(mira)
	else
		erguerAnel()
	end
end
''')


T("Xester Jokers Labyrinth", 1,
  objeto="XesterJokersLabyrinth_Server_V1", sufixo="XesterLabirinto",
  arquetipo="ARCANO",
  rotulo_m1="cerca a area, embaralha os inimigos e fecha no centro",
  origem=["R na Forma 1. Cartas gigantes do `cards`, som `342337569`",
          "(ARRANCA) e `1888686669` (PUXA)."],
  cfg="""	RECARGA        = 24,
	RAIO           = 22,
	PAREDES        = 10,
	ESPERA         = 0.9,
	DURACAO        = 3.6,
	DANO_FECHA     = 54,
	BORDA_FECHA    = 27,
	NUCLEO         = 8,
	TOMBO          = 1.5,
	PUXAO          = 40,""",
  estado="local labirintoId = nil",
  corpo='''
--''' + R + '''
-- O EMBARALHAR É UMA PERMUTAÇÃO EM CICLO
--
-- Cada um vai para o lugar do seguinte, e o último para o do primeiro. As
-- posições são lidas TODAS antes de qualquer escrita — ler e escrever no mesmo
-- laço faria o segundo aparecer onde o primeiro já não estava.
--''' + R + '''

function limparTudo()
	novaGeracao("R")
	apagarEfeito(labirintoId)
	labirintoId = nil
end

function primaria(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("LABIRINTO", despachar({
		CARGA  = { sfx = { "LABIRINTO", 0.9 } },
		SEGURA = { faz = function()
			local centro = destino or frente(CFG.RAIO)
			apagarEfeito(labirintoId)
			labirintoId = novoId("LABIRINTO")
			vfx("LABIRINTO_SOBE", { posicao = centro,
				raio = comBonus(CFG.RAIO), paredes = CFG.PAREDES,
				duracao = CFG.DURACAO, id = labirintoId })
			tocarEm("LABIRINTO", centro, 0.85)
		end },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.RAIO)
			local raio = comBonus(CFG.RAIO)
			local minha = novaGeracao("R")
			local meu = labirintoId

			local presos = alvosEm(centro, raio, 12)
			local posicoes = {}
			for indice, alvo in ipairs(presos) do
				local alvoRaiz = raizDe(alvo)
				posicoes[indice] = alvoRaiz and alvoRaiz.CFrame or nil
			end
			if #presos >= 2 then
				tocarEm("EMBARALHA", centro, 0.95)
				for indice, alvo in ipairs(presos) do
					local seguinte = (indice % #presos) + 1
					local vaiPara = posicoes[seguinte]
					local alvoRaiz = raizDe(alvo)
					if vaiPara and alvoRaiz then
						vfx("LABIRINTO_EMBARALHA", {
							origem = alvoRaiz.Position,
							destino = vaiPara.Position })
						alvoRaiz.CFrame = CFrame.new(
							vaiPara.Position + Vector3.new(0, 1, 0),
							vaiPara.Position + vaiPara.LookVector)
					end
				end
			end

			task.delay(CFG.ESPERA, function()
				if geracao.R ~= minha then return end
				vfx("LABIRINTO_FECHA", { posicao = centro, raio = raio,
					id = meu })
				tocarEm("LABIRINTO", centro, 0.7)
				golpearArea(centro, raio, CFG.NUCLEO, CFG.DANO_FECHA,
					CFG.BORDA_FECHA, nil, CFG.TOMBO)
				for _, alvo in ipairs(alvosEm(centro, raio, 14)) do
					puxar(alvo, centro, CFG.PUXAO, 0.4)
				end
				task.delay(0.4, function()
					if geracao.R ~= minha then return end
					apagarEfeito(meu)
					if labirintoId == meu then labirintoId = nil end
				end)
			end)
		end },
	}), fecharHabilidade)
end
''')


T("Xester Ace Gate", 1,
  objeto="XesterAceGate_Server_V1", sufixo="XesterAs",
  arquetipo="ESPECTRAL",
  rotulo_m1="crava o As; o clique seguinte teleporta ate ele",
  guarda_m1=GUARDA_DUPLO,
  origem=["T na Forma 1. Som `1843578719` (CRAVA) e `1894958339` (SOME)."],
  cfg="""	RECARGA        = 10,
	ALCANCE        = 60,
	VOO            = 0.28,
	VIDA_AS        = 10,
	RAIO           = 7,
	DANO           = 26,
	ATRAS          = 5,
	DANO_PORTAO    = 18,
	ALTURA_SAIDA   = 3,""",
  estado="local asId, asOnde = nil, nil",
  corpo='''
--''' + R + '''
-- A CHEGADA É ATRÁS DO ALVO
--
-- `-LookVector` DELE, não do portador: chegar na frente seria só um teleporte,
-- e a habilidade é sobre chegar onde ninguém esperava.
--''' + R + '''

function limparTudo()
	novaGeracao("T")
	apagarEfeito(asId)
	asId, asOnde = nil, nil
end

function segundaEtapa()
	return asOnde ~= nil
end

local function cravarAs(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("ACE_GATE", despachar({
		CARGA = { sfx = { "AS", 1.05 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.4, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("AS_VOA", { origem = origem, destino = ponto,
				voo = CFG.VOO })

			local minha = novaGeracao("T")
			task.delay(CFG.VOO, function()
				if geracao.T ~= minha then return end
				apagarEfeito(asId)
				asId = novoId("AS")
				asOnde = ponto
				vfx("AS_CRAVA", { posicao = ponto, duracao = CFG.VIDA_AS,
					id = asId })
				tocarEm("AS", ponto, 0.95)
				for _, alvo in ipairs(alvosEm(ponto, comBonus(CFG.RAIO), 8)) do
					aplicarDano(alvo, CFG.DANO)
				end
				local meu = asId
				task.delay(CFG.VIDA_AS, function()
					if asId ~= meu then return end
					apagarEfeito(meu)
					asId, asOnde = nil, nil
				end)
			end)
		end },
	}), fecharHabilidade)
end

local function usarPortao()
	ocupado = true
	local ponto = asOnde
	rig:PlaySequence("ACE_PORTAO", despachar({
		CARGA = { sfx = { "PORTAO", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent and ponto) then return end
			local partida = raiz.Position
			local alvo = maisPerto(ponto, CFG.RAIO * 1.6)
			local alvoRaiz = alvo and raizDe(alvo)
			local chegada = ponto

			if alvoRaiz then
				chegada = alvoRaiz.Position
					- alvoRaiz.CFrame.LookVector * CFG.ATRAS
				raiz.CFrame = CFrame.new(chegada + Vector3.new(0, 1, 0),
					alvoRaiz.Position)
				aplicarDano(alvo, CFG.DANO_PORTAO)
			else
				raiz.CFrame = CFrame.new(
					chegada + Vector3.new(0, CFG.ALTURA_SAIDA, 0),
					chegada + raiz.CFrame.LookVector)
			end

			vfx("AS_PORTAO", { origem = partida, destino = chegada })
			tocarEm("PORTAO", partida, 0.95)
			tocarEm("PORTAO", chegada, 1.1)
			apagarEfeito(asId)
			asId, asOnde = nil, nil
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		usarPortao()
	else
		cravarAs(mira)
	end
end
''')


T("Xester House Collapse", 1,
  objeto="XesterHouseCollapse_Server_V1", sufixo="XesterCastelo",
  arquetipo="EXPLOSIVO",
  rotulo_m1="ergue o castelo; o clique seguinte derruba na direcao do mouse",
  guarda_m1=GUARDA_DUPLO,
  origem=["Y na Forma 1. Som `236989198` (ERGUE) e `765590102` (BATE)."],
  cfg="""	RECARGA        = 20,
	DURACAO        = 12,
	ANDARES        = 4,
	ALCANCE        = 26,
	LARGURA        = 10,
	DANO_PAREDE    = 34,
	EMPURRAO       = 96,
	RAIO_CENTRO    = 13,
	DANO_CENTRO    = 52,
	BORDA_CENTRO   = 26,
	TOMBO          = 1.6,""",
  estado="local casteloId, casteloOnde = nil, nil",
  corpo='''
--''' + R + '''
-- O CORREDOR, E DEPOIS O CENTRO
--
-- As paredes caem NA DIREÇÃO do mouse e machucam quem está na faixa entre o
-- castelo e o alcance — projeção no eixo mais distância lateral, não um raio.
-- Um raio simples pegaria quem está atrás, e a habilidade é direcional.
--''' + R + '''

function limparTudo()
	novaGeracao("Y")
	apagarEfeito(casteloId)
	casteloId, casteloOnde = nil, nil
end

function segundaEtapa()
	return casteloOnde ~= nil
end

local function erguerCastelo()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("CASTELO", despachar({
		CARGA  = { sfx = { "CASTELO", 0.9 } },
		SEGURA = { sfx = { "CASTELO", 1.05 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(casteloId)
			casteloId = novoId("CASTELO")
			casteloOnde = raiz.Position
			vfx("CASTELO_SOBE", { posicao = casteloOnde,
				andares = CFG.ANDARES, duracao = CFG.DURACAO,
				id = casteloId })
			tocarEm("CASTELO", casteloOnde, 0.85)

			local minha = novaGeracao("Y")
			local meu = casteloId
			task.delay(CFG.DURACAO, function()
				if geracao.Y ~= minha then return end
				apagarEfeito(meu)
				if casteloId == meu then casteloId, casteloOnde = nil, nil end
			end)
		end },
	}), fecharHabilidade)
end

local function derrubar(mira)
	ocupado = true
	local destino = mira
	local centro = casteloOnde
	local meu = casteloId
	rig:PlaySequence("DESABA", despachar({
		CARGA  = { sfx = { "DESABA", 0.95 } },
		SEGURA = { sfx = { "CASTELO", 0.8 } },
		GOLPE  = { faz = function()
			if not centro then return end
			local ponto = destino or (centro + Vector3.new(0, 0, 1))
			local delta = Vector3.new(ponto.X - centro.X, 0, ponto.Z - centro.Z)
			local dir = (delta.Magnitude > 0.5) and delta.Unit
				or Vector3.new(0, 0, 1)
			local alcance = comBonus(CFG.ALCANCE)

			vfx("CASTELO_DESABA", { posicao = centro, direcao = dir,
				alcance = alcance, id = meu })
			tocarEm("DESABA", centro, 0.85)

			for _, alvo in ipairs(alvosEm(centro, alcance + CFG.LARGURA, 16)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local rel = alvoRaiz.Position - centro
					local aoLongo = rel:Dot(dir)
					local lateral = (rel - dir * aoLongo).Magnitude
					if aoLongo >= -2 and aoLongo <= alcance
							and lateral <= CFG.LARGURA then
						aplicarDano(alvo, CFG.DANO_PAREDE)
						empurrar(alvo, dir + Vector3.new(0, 0.35, 0),
							CFG.EMPURRAO, 0.34)
					end
				end
			end

			golpearArea(centro, comBonus(CFG.RAIO_CENTRO),
				CFG.RAIO_CENTRO * 0.4, CFG.DANO_CENTRO, CFG.BORDA_CENTRO,
				nil, CFG.TOMBO)

			apagarEfeito(meu)
			if casteloId == meu then casteloId, casteloOnde = nil, nil end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		derrubar(mira)
	else
		erguerCastelo()
	end
end
''')


T("Xester Eclipse Deck", 1,
  objeto="XesterEclipseDeck_Server_V1", sufixo="XesterEclipse",
  arquetipo="ARCANO", cutscene=True,
  rotulo_m1="carta negra no ceu que marca e traz todos ao centro",
  extra="F", rotulo_extra="The Final Deal",
  origem=["U na Forma 1, mais o F como Extra. `The Final Deal` foi para cá",
          "porque as duas são o CLÍMAX da Forma 1 — é o agrupamento que a",
          "regra de distribuição pede, e ele fica declarado aqui."],
  cfg="""	RECARGA        = 34,
	RAIO_MARCA     = 40,
	ALTURA         = 46,
	ESPERA         = 1.4,
	DURACAO        = 5,
	LIMITE         = 10,
	RAIO_FINAL     = 26,
	NUCLEO         = 9,
	DANO           = 66,
	BORDA          = 33,
	PUXAO          = 92,
	TOMBO          = 2,

	RECARGA_EXTRA  = 30,
	PRAZO_CENA     = 8,""",
  estado="local eclipseId = nil\nlocal marcasEclipse = {}",
  corpo='''
--''' + R + '''
-- M1 — Eclipse Deck
--
-- A marca guarda o ALVO, não a posição: quem foi marcado é puxado de onde
-- estiver quando o retorno acontecer. Guardar a posição premiaria quem ficou
-- parado, que é o contrário do que a habilidade quer.
--''' + R + '''

function limparTudo()
	novaGeracao("U")
	novaGeracao("F")
	apagarEfeito(eclipseId)
	eclipseId = nil
	for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
	marcasEclipse = {}
end

function primaria(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("ECLIPSE", despachar({
		CARGA  = { sfx = { "ECLIPSE", 0.75 } },
		SEGURA = { sfx = { "ECLIPSE", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = destino or frente(CFG.RAIO_MARCA * 0.5)
			local minha = novaGeracao("U")

			apagarEfeito(eclipseId)
			for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
			marcasEclipse = {}

			eclipseId = novoId("ECLIPSE")
			vfx("ECLIPSE_ABRE", { posicao = centro, altura = CFG.ALTURA,
				duracao = CFG.DURACAO, id = eclipseId })
			tocarEm("ECLIPSE", centro, 0.7)

			local marcados = alvosEm(centro, comBonus(CFG.RAIO_MARCA),
				CFG.LIMITE)
			for _, alvo in ipairs(marcados) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local id = novoId("MARCA")
					table.insert(marcasEclipse, id)
					vfx("ECLIPSE_MARCA", { posicao = alvoRaiz.Position,
						duracao = CFG.ESPERA + 0.4, id = id })
				end
			end

			local meu = eclipseId
			task.delay(CFG.ESPERA, function()
				if geracao.U ~= minha then return end
				local onde = {}
				for _, alvo in ipairs(marcados) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz and alvo.Health > 0 then
						table.insert(onde, alvoRaiz.Position)
						puxar(alvo, centro, CFG.PUXAO, 0.45)
					end
				end
				vfx("ECLIPSE_RETORNA", { posicao = centro,
					raio = comBonus(CFG.RAIO_FINAL), marcados = onde })
				tocarEm("RETORNO", centro, 0.8)

				task.delay(0.45, function()
					if geracao.U ~= minha then return end
					golpearArea(centro, comBonus(CFG.RAIO_FINAL), CFG.NUCLEO,
						CFG.DANO, CFG.BORDA, nil, CFG.TOMBO)
					apagarEfeito(meu)
					for _, id in ipairs(marcasEclipse) do apagarEfeito(id) end
					marcasEclipse = {}
					if eclipseId == meu then eclipseId = nil end
				end)
			end)
		end },
	}), fecharHabilidade)
end

--''' + R + '''
-- EXTRA — F  ·  The Final Deal
--
-- A cutscene É a sequência de animação: os beats saem do `Poses.lua` e viram
-- beat de câmera pelo `cam = true`. Quem manda o `FIM` é o callback do fim da
-- sequência, não um `task.wait` paralelo que poderia dessincronizar dela.
--
-- Ela NÃO procura a Tool da Forma 2. Escreve `XesterForma = 2` no Character e
-- acabou — quem estiver com uma Tool da Forma 2 na mochila já vai sacá-la
-- dragão, e quem não estiver fica com o cajado e a aura do mesmo jeito.
--
-- SEM TÍTULO ESCRITO: o roteiro pede "XESTER — HEAVENBREAKER" na tela, e texto
-- em 3D no Roblox só existe por `BillboardGui`/`SurfaceGui`, que a diretriz
-- base proíbe dentro de Tool. O beat `TITULO` existe e é o clímax — máscara
-- grande, anel dourado, estouro de luz. O que não existe é a LETRA, e ela
-- teria de morar no sistema de UI do jogo, ouvindo o `CutsceneRemote`.
--''' + R + '''

function extra(_mira)
	abrirHabilidade()
	ocupado = true
	limparTudo()
	comecarCena("TRANSFORMAR")
	local onde = raiz and raiz.Position or Vector3.new()

	rig:PlaySequence("TRANSFORMAR", despachar({
		MAO     = { cam = true, faz = function()
			vfx("CENA_MAO", { posicao = raiz and raiz.Position or onde })
		end },
		NAIPES  = { cam = true, sfx = { "NAIPES", 0.8 }, faz = function()
			vfx("CENA_NAIPES", { posicao = raiz and raiz.Position or onde })
		end },
		CORINGA = { cam = true, sfx = { "QUEIMA", 0.95 }, faz = function()
			vfx("CENA_CORINGA", { posicao = raiz and raiz.Position or onde })
		end },
		CONGELA = { cam = true, faz = function()
			vfx("CENA_CONGELA", { posicao = raiz and raiz.Position or onde })
		end },
		RASGA   = { cam = true, sfx = { "RASGA", 1.1 }, faz = function()
			vfx("CENA_RASGA", { posicao = raiz and raiz.Position or onde })
			porCajado()
			vfx("CAJADO_ACENDE", { posicao = raiz and raiz.Position or onde })
		end },
		TITULO  = { cam = true, sfx = { "TITULO", 1 }, faz = function()
			local aqui = raiz and raiz.Position or onde
			vfx("CENA_TITULO", { posicao = aqui })
			tocarEm("TITULO", aqui, 0.95)
			escreverAtributo(ATR_FORMA, 2)
			escreverAtributo(ATR_USOS, 0)
			ligarAura()
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
end
''')


T("Xester Royal Guard", 1,
  objeto="XesterRoyalGuard_Server_V1", sufixo="XesterGuarda",
  arquetipo="SUPORTE",
  rotulo_m1="quatro Reis de guarda; o clique seguinte lanca um",
  extra="R", rotulo_extra="Baque dos Reis",
  guarda_m1=GUARDA_DUPLO,
  origem=["P na Forma 1. O baque dos quatro é a metade de trás da MESMA",
          "habilidade — combo na mesma entrada conta como uma —, mas ele",
          "precisa de uma entrada própria porque o clique já é o lançamento."],
  cfg="""	RECARGA        = 18,
	DURACAO        = 14,
	ORBITA         = 4.4,
	ALCANCE        = 42,
	VOO            = 0.24,
	RAIO_REI       = 8,
	DANO_REI       = 30,
	EMPURRAO       = 104,

	RECARGA_EXTRA  = 2,
	RAIO_BAQUE     = 14,
	NUCLEO_BAQUE   = 6,
	DANO_BAQUE     = 46,
	BORDA_BAQUE    = 23,
	TOMBO          = 1.8,""",
  estado="local guardaId = nil",
  corpo='''
function limparTudo()
	novaGeracao("P")
	apagarEfeito(guardaId)
	guardaId = nil
end

function segundaEtapa()
	return guardaId ~= nil
end

--- Os Reis ACOMPANHAM o portador: eles são guarda, e guarda que fica para trás
--- não guarda nada.
local function seguirGuarda()
	local minha = novaGeracao("P")
	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		while geracao.P == minha and os.clock() < ate do
			if not (personagem and raiz and raiz.Parent
					and humanoide and humanoide.Health > 0) then
				break
			end
			vfx("MOVER", { id = guardaId, posicao = raiz.Position,
				tempo = 0.3 })
			task.wait(0.3)
		end
		if geracao.P == minha then
			apagarEfeito(guardaId)
			guardaId = nil
		end
	end)
end

local function levantarGuarda()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("GUARDA_REAL", despachar({
		CARGA = { sfx = { "GUARDA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(guardaId)
			guardaId = novoId("GUARDA")
			vfx("GUARDA_SOBE", { posicao = raiz.Position,
				raio = CFG.ORBITA, duracao = CFG.DURACAO, id = guardaId })
			tocarEm("GUARDA", raiz.Position, 1)
			seguirGuarda()
		end },
	}), fecharHabilidade)
end

local function lancarRei(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("REI_LANCA", despachar({
		CARGA = { sfx = { "REI", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("GUARDA_LANCA", { origem = origem, destino = ponto,
				voo = CFG.VOO })
			tocarEm("REI", ponto, 1.05)
			for _, alvo in ipairs(alvosEm(ponto, comBonus(CFG.RAIO_REI), 10)) do
				aplicarDano(alvo, CFG.DANO_REI)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - origem)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.32)
				end
			end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		lancarRei(mira)
	else
		levantarGuarda()
	end
end

--- Extra: os quatro batem no chão de uma vez, e a guarda ACABA. É o preço —
--- quem quer o estouro abre mão da proteção.
function extra(_mira)
	if not guardaId then return end
	abrirHabilidade()
	ocupado = true
	local meu = guardaId
	rig:PlaySequence("REI_BAQUE", despachar({
		CARGA  = { sfx = { "REI", 0.9 } },
		SEGURA = { sfx = { "GUARDA", 0.85 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position
			vfx("GUARDA_BAQUE", { posicao = centro,
				raio = comBonus(CFG.RAIO_BAQUE), id = meu })
			tocarEm("REI", centro, 0.85)
			golpearArea(centro, comBonus(CFG.RAIO_BAQUE), CFG.NUCLEO_BAQUE,
				CFG.DANO_BAQUE, CFG.BORDA_BAQUE, CFG.EMPURRAO * 0.6,
				CFG.TOMBO)
			novaGeracao("P")
			apagarEfeito(meu)
			if guardaId == meu then guardaId = nil end
		end },
	}), fecharHabilidade)
end
''')


# ═══════════════════════════════════════════════════════════════
# FORMA 2 — HEAVENBREAKER
#
# Seis habilidades, seis Tools. De 3 a 7 a regra manda uma Tool por
# habilidade, e é o que está aqui — nenhum agrupamento, nenhuma Extra.
# ═══════════════════════════════════════════════════════════════

T("Xester Wyrm Sparks", 2,
  objeto="XesterWyrmSparks_Server_V1", sufixo="XesterWyrm",
  arquetipo="CEIFA",
  rotulo_m1="tres cabecas de fogo que perseguem e marcam o chao",
  origem=["G na Forma 2. Som `842332424` (FOGO), já em uso no repositório."],
  cfg="""	RECARGA        = 8,
	CABECAS        = 3,
	ALCANCE        = 55,
	INTERVALO      = 0.12,
	VOO            = 0.42,
	ESPALHA        = 4,
	RAIO           = 7,
	DANO           = 24,
	MARCA_VIDA     = 5,
	MARCA_RAIO     = 6,
	MARCA_PASSO    = 0.7,
	MARCA_DANO     = 6,""",
  estado="local marcas = {}",
  corpo='''
--''' + R + '''
-- A CABEÇA PERSEGUE
--
-- Se houver alvo perto do ponto mirado, ela corrige a rota para ele. É o que
-- separa "três projéteis" de "três cabeças de dragão": elas procuram.
--''' + R + '''

function limparTudo()
	novaGeracao("G")
	for _, id in ipairs(marcas) do apagarEfeito(id) end
	marcas = {}
end

function primaria(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("WYRM", despachar({
		CARGA = { sfx = { "WYRM", 1.15 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2.6, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			local minha = novaGeracao("G")
			local i = 1
			while i <= CFG.CABECAS do
				local indice = i
				task.delay(indice * CFG.INTERVALO, function()
					if geracao.G ~= minha or not personagem then return end
					local ang = anguloDe(indice)
					local perto = maisPerto(ponto, CFG.ESPALHA * 3)
					local pertoRaiz = perto and raizDe(perto)
					local chegada = pertoRaiz and pertoRaiz.Position
						or (ponto + Vector3.new(
							math.cos(ang) * CFG.ESPALHA, 0,
							math.sin(ang) * CFG.ESPALHA))

					vfx("WYRM_VOA", { origem = origem, destino = chegada,
						voo = CFG.VOO })
					task.delay(CFG.VOO, function()
						if geracao.G ~= minha or not personagem then return end
						tocarEm("WYRM", chegada, 1.1)
						for _, alvo in ipairs(alvosEm(chegada,
								comBonus(CFG.RAIO), 8)) do
							aplicarDano(alvo, CFG.DANO)
						end

						local id = novoId("MARCA_WYRM")
						table.insert(marcas, id)
						vfx("WYRM_MARCA", { posicao = chegada,
							raio = CFG.MARCA_RAIO,
							duracao = CFG.MARCA_VIDA, id = id })
						task.spawn(function()
							local ate = os.clock() + CFG.MARCA_VIDA
							while os.clock() < ate do
								if geracao.G ~= minha or not personagem then
									break
								end
								for _, alvo in ipairs(alvosEm(chegada,
										CFG.MARCA_RAIO, 8)) do
									aplicarDano(alvo, CFG.MARCA_DANO)
								end
								task.wait(CFG.MARCA_PASSO)
							end
							apagarEfeito(id)
						end)
					end)
				end)
				i = i + 1
			end
		end },
	}), fecharHabilidade)
end
''')


T("Xester Crown of Cinders", 2,
  objeto="XesterCrownofCinders_Server_V1", sufixo="XesterCoroa",
  arquetipo="EXPLOSIVO",
  rotulo_m1="um sol de Coringa; o clique seguinte estilhaca em brasas",
  guarda_m1=GUARDA_DUPLO,
  origem=["H na Forma 2. Som `1845012046` (CARREGA) e `1982011510` (FOGO)."],
  cfg="""	RECARGA        = 26,
	DURACAO        = 8,
	ALTURA         = 22,
	FRAGMENTOS     = 9,
	INTERVALO      = 0.1,
	ESPALHA        = 12,
	VOO            = 0.5,
	ALCANCE        = 55,
	RAIO           = 9,
	NUCLEO         = 4,
	DANO           = 38,
	BORDA          = 19,
	EMPURRAO       = 54,""",
  estado="local coroaId, coroaOnde = nil, nil",
  corpo='''
function limparTudo()
	novaGeracao("H")
	apagarEfeito(coroaId)
	coroaId, coroaOnde = nil, nil
end

function segundaEtapa()
	return coroaOnde ~= nil
end

local function erguerSol()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("COROA_BRASAS", despachar({
		CARGA = { sfx = { "COROA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local minha = novaGeracao("H")
			apagarEfeito(coroaId)
			coroaId = novoId("COROA")
			local meu = coroaId
			coroaOnde = raiz.Position
			vfx("COROA_SOL", { posicao = raiz.Position, altura = CFG.ALTURA,
				duracao = CFG.DURACAO, id = meu })
			tocarEm("COROA", raiz.Position, 0.95)

			task.delay(CFG.DURACAO, function()
				if geracao.H ~= minha then return end
				apagarEfeito(meu)
				if coroaId == meu then coroaId, coroaOnde = nil, nil end
			end)
		end },
	}), fecharHabilidade)
end

--- Os fragmentos caem em ESPIRAL pelo ângulo áureo, do centro para fora. Um
--- sorteio faria cada cliente ver uma chuva diferente, o que lê como lag.
local function estilhacar(mira)
	ocupado = true
	local destino = mira
	local sol = coroaOnde
	local meu = coroaId
	rig:PlaySequence("BRASAS_CAEM", despachar({
		CARGA  = { sfx = { "COROA", 0.85 } },
		SEGURA = { sfx = { "BRASA", 1 } },
		GOLPE  = { faz = function()
			local origem = (sol or (raiz and raiz.Position) or Vector3.new())
				+ Vector3.new(0, CFG.ALTURA, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			local i = 1
			while i <= CFG.FRAGMENTOS do
				local indice = i
				task.delay(indice * CFG.INTERVALO, function()
					if not personagem then return end
					local ang = anguloDe(indice)
					local raioQueda = CFG.ESPALHA * (indice / CFG.FRAGMENTOS)
					local chegada = ponto + Vector3.new(
						math.cos(ang) * raioQueda, 0,
						math.sin(ang) * raioQueda)
					vfx("COROA_FRAGMENTO", { origem = origem,
						destino = chegada, voo = CFG.VOO })
					task.delay(CFG.VOO, function()
						if not personagem then return end
						tocarEm("BRASA", chegada, 0.9)
						golpearArea(chegada, comBonus(CFG.RAIO), CFG.NUCLEO,
							CFG.DANO, CFG.BORDA, CFG.EMPURRAO, nil, 10)
					end)
				end)
				i = i + 1
			end
			apagarEfeito(meu)
			if coroaId == meu then coroaId, coroaOnde = nil, nil end
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		estilhacar(mira)
	else
		erguerSol()
	end
end
''')


T("Xester Dragons Requiem", 2,
  objeto="XesterDragonsRequiem_Server_V1", sufixo="XesterRequiem",
  arquetipo="CEIFA",
  rotulo_m1="segure para carregar; solte para o sopro curvado",
  extra="SOLTAR", rotulo_extra="Soltar o sopro",
  origem=["J na Forma 2. Som `2014087015` (SOPRO). O `AcaoRemote` aqui não é",
          "uma Extra de verdade: é o LADO DE SOLTAR do mesmo botão, e por isso",
          "ele não paga recarga própria."],
  cfg="""	RECARGA        = 22,
	CARGA_MAX      = 2.4,
	NOS            = 9,
	ALCANCE_MIN    = 24,
	ALCANCE_MAX    = 64,
	LARGURA_MIN    = 5,
	LARGURA_MAX    = 12,
	CURVA          = 0.42,
	DANO_MIN       = 30,
	DANO_MAX       = 72,
	EMPURRAO       = 62,

	RECARGA_EXTRA  = 0,""",
  estado="local requiemId = nil\nlocal cargaRequiem = nil",
  corpo='''
--''' + R + '''
-- SEGURAR CARREGA, SOLTAR DISPARA
--
-- A carga é um prazo com TETO. A versão anterior desta mecânica prendia num
-- `repeat ... until charging == false` amarrado ao `Button1Up` do cliente:
-- soltar o botão fora da tela deixava a sucção rodando para sempre. Aqui, se o
-- `End` nunca chegar, o sopro sai sozinho no máximo.
--
-- A CURVA É CALCULADA NO SERVIDOR. É ela que define quem é atingido, e deixar
-- a hitbox no cliente seria deixá-la com quem pode mentir.
--''' + R + '''

function limparTudo()
	novaGeracao("J")
	apagarEfeito(requiemId)
	requiemId = nil
	cargaRequiem = nil
end

--- `extra` é o lado de SOLTAR. Ele tem de passar mesmo com `ocupado`: a carga
--- É o estado ocupado, e exigir que ela acabe tornaria a habilidade impossível.
function extra(mira)
	if not cargaRequiem then return end
	local carregado = math.min(os.clock() - cargaRequiem, CFG.CARGA_MAX)
	local t = carregado / CFG.CARGA_MAX
	cargaRequiem = nil
	-- corta a geração ANTES de qualquer coisa: o callback da sequência de carga
	-- ainda vai disparar, e sem este corte ele apagaria o `ocupado` do sopro
	-- que está começando agora.
	novaGeracao("J")
	apagarEfeito(requiemId)
	requiemId = nil

	ocupado = true
	local destino = mira
	rig:PlaySequence("REQUIEM_SOPRO", despachar({
		CARGA = { sfx = { "REQUIEM", 0.85 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local alcance = CFG.ALCANCE_MIN
				+ (CFG.ALCANCE_MAX - CFG.ALCANCE_MIN) * t
			local largura = CFG.LARGURA_MIN
				+ (CFG.LARGURA_MAX - CFG.LARGURA_MIN) * t
			local dano = CFG.DANO_MIN + (CFG.DANO_MAX - CFG.DANO_MIN) * t

			local origem = raiz.Position + Vector3.new(0, 2.4, 0)
			local ponto = destino or frente(alcance)
			local reto = ponto - origem
			if reto.Magnitude < 1 then
				reto = raiz.CFrame.LookVector * alcance
			end
			local dir = reto.Unit
			-- o lado para onde a curva desvia. É o que faz o sopro ser
			-- "curvado" e não só longo.
			local lado = Vector3.new(-dir.Z, 0, dir.X)

			local arco = {}
			local i = 1
			while i <= CFG.NOS do
				local passo = i / CFG.NOS
				local desvio = math.sin(passo * math.pi) * CFG.CURVA
					* alcance * 0.35
				table.insert(arco, origem + dir * (alcance * passo)
					+ lado * desvio)
				i = i + 1
			end

			vfx("REQUIEM_SOPRO", { arco = arco, largura = largura })
			tocarEm("REQUIEM", ponto, 0.75)

			local jaBatidos = {}
			for _, onde in ipairs(arco) do
				for _, alvo in ipairs(alvosEm(onde, comBonus(largura), 12)) do
					if not jaBatidos[alvo] then
						jaBatidos[alvo] = true
						aplicarDano(alvo, dano)
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							empurrar(alvo, dir + Vector3.new(0, 0.3, 0),
								CFG.EMPURRAO, 0.3)
						end
					end
				end
			end
		end },
	}), fecharHabilidade)
end

function primaria(_mira)
	abrirHabilidade()
	ocupado = true
	cargaRequiem = os.clock()
	apagarEfeito(requiemId)
	requiemId = novoId("REQUIEM")
	local minha = novaGeracao("J")

	if raiz then
		vfx("REQUIEM_CARGA", { posicao = raiz.Position,
			duracao = CFG.CARGA_MAX + 0.4, id = requiemId })
		tocarEm("REQUIEM", raiz.Position, 0.8)
	end

	rig:PlaySequence("REQUIEM_CARGA", despachar({
		CARGA  = { sfx = { "REQUIEM", 0.9 } },
		SEGURA = { faz = function()
			if raiz and requiemId then
				vfx("MOVER", { id = requiemId, posicao = raiz.Position,
					tempo = 0.3 })
			end
		end },
	}), function()
		-- Três desfechos, e nenhum pode deixar `ocupado` errado:
		--   geração mudou   -> `extra` já assumiu; não tocar em nada
		--   ainda segurando -> segue `ocupado`, e o teto abaixo dispara
		--   já soltou       -> libera
		if geracao.J ~= minha then return end
		if not cargaRequiem then ocupado = false end
	end)

	-- TETO: se o `End` nunca chegar, o sopro sai sozinho no máximo
	task.delay(CFG.CARGA_MAX + 0.15, function()
		if geracao.J ~= minha or not cargaRequiem then return end
		extra(nil)
	end)
end
''')


T("Xester Prism", 2,
  objeto="XesterPrism_Server_V1", sufixo="XesterPrisma",
  arquetipo="ARCANO",
  rotulo_m1="tres mascaras com feixes que se cruzam e seguem o mouse",
  extra="MIRA", rotulo_extra="Mover o ponto",
  origem=["K na Forma 2. Som `1910988873` (RAIO). O `AcaoRemote` aqui carrega",
          "a MIRA MÓVEL, não uma habilidade: ele não passa por recarga nem",
          "por `podeAgir`, e o servidor só o aceita com o prisma de pé."],
  cfg="""	RECARGA        = 20,
	DURACAO        = 5,
	PASSO          = 0.28,
	RAIO_MASCARA   = 7,
	ALTURA         = 7,
	ALCANCE        = 55,
	RAIO           = 6,
	DANO           = 13,
	LENTIDAO       = 0.7,

	RECARGA_EXTRA  = 0,""",
  estado="local prismaId, prismaAlvo = nil, nil",
  corpo='''
function limparTudo()
	novaGeracao("K")
	apagarEfeito(prismaId)
	prismaId, prismaAlvo = nil, nil
end

--- A mira móvel. Não é habilidade: é o mouse do dono chegando enquanto o
--- prisma está de pé. Quem decide se ainda vale é este servidor.
function extra(mira)
	if prismaId and typeof(mira) == "Vector3" then
		prismaAlvo = mira
	end
end

function primaria(mira)
	abrirHabilidade()
	ocupado = true
	local destino = mira
	rig:PlaySequence("PRISMA", despachar({
		CARGA  = { sfx = { "PRISMA", 1 } },
		SEGURA = { sfx = { "PRISMA", 1.15 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			apagarEfeito(prismaId)
			prismaId = novoId("PRISMA")
			prismaAlvo = destino or frente(CFG.ALCANCE * 0.5)
			local meu = prismaId
			local minha = novaGeracao("K")

			vfx("PRISMA_MASCARAS", { posicao = raiz.Position,
				raio = CFG.RAIO_MASCARA, altura = CFG.ALTURA,
				duracao = CFG.DURACAO, id = meu })
			tocarEm("PRISMA", raiz.Position, 1)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				while geracao.K == minha and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local ponto = prismaAlvo or frente(CFG.ALCANCE * 0.5)
					vfx("PRISMA_MIRA", { posicao = ponto, id = meu })
					for _, alvo in ipairs(alvosEm(ponto,
							comBonus(CFG.RAIO), 10)) do
						aplicarDano(alvo, CFG.DANO)
						afrouxar(alvo, CFG.LENTIDAO, CFG.PASSO * 2)
					end
					task.wait(CFG.PASSO)
				end
				if geracao.K == minha then
					local ponto = prismaAlvo or frente(CFG.ALCANCE * 0.5)
					vfx("PRISMA_ESTOURA", { posicao = ponto })
					apagarEfeito(meu)
					if prismaId == meu then prismaId = nil end
					prismaAlvo = nil
				end
			end)
		end },
	}), fecharHabilidade)
end
''')


T("Xester Final Page", 2,
  objeto="XesterFinalPage_Server_V1", sufixo="XesterPagina",
  arquetipo="CEIFA", cutscene=True,
  rotulo_m1="para o tempo; tres cliques marcam; o dragao celeste atravessa",
  guarda_m1=GUARDA_DUPLO,
  origem=["L na Forma 2. Som `54111471` (FIM) e `1040136448` (ECO)."],
  cfg="""	RECARGA        = 70,
	RAIO_PARADA    = 34,
	PARADA         = 3.2,
	PONTOS         = 3,
	JANELA         = 6,
	ALCANCE        = 65,
	RAIO_PONTO     = 16,
	DANO_PONTO     = 58,
	BORDA_PONTO    = 29,
	NUCLEO_PONTO   = 6,
	TOMBO          = 2.4,
	PRAZO_CENA     = 8,""",
  estado=("local pontos, pontosId = {}, {}\n"
          "local presos = {}\nlocal escolhendo = false"),
  corpo='''
--''' + R + '''
-- "DANO ACUMULADO" É LITERAL
--
-- Cada ponto guarda quem estava nele, e o dano final de cada alvo cresce com o
-- NÚMERO de pontos que o pegaram. Quem for pego pelos três leva três vezes — e
-- é essa a recompensa por mirar bem.
--
-- A janela de escolha tem TETO. Sem ele, quem abre a ultimate e não clica
-- deixa os inimigos presos indefinidamente.
--''' + R + '''

function limparTudo()
	novaGeracao("L")
	for _, id in ipairs(pontosId) do apagarEfeito(id) end
	pontos, pontosId, presos = {}, {}, {}
	escolhendo = false
end

function segundaEtapa()
	return escolhendo
end

local function disparar()
	local rota = {}
	for _, onde in ipairs(pontos) do table.insert(rota, onde) end
	local guardados = presos
	limparTudo()

	ocupado = true
	comecarCena("PAGINA")
	rig:PlaySequence("CENA_PAGINA", despachar({
		PARA    = { cam = true, sfx = { "PAGINA", 0.9 } },
		RELOGIO = { cam = true, sfx = { "ECO", 0.85 }, faz = function()
			if raiz then
				vfx("PAGINA_RELOGIO", { posicao = raiz.Position,
					altura = 30, duracao = 1.2 })
			end
		end },
		QUEBRA  = { cam = true, sfx = { "PAGINA", 0.75 } },
		VOLTA   = { cam = true, faz = function()
			vfx("PAGINA_DRAGAO", { rota = rota })
			for _, onde in ipairs(rota) do
				tocarEm("ECO", onde, 0.8)
			end
			local contados = {}
			for _, onde in ipairs(rota) do
				for _, alvo in ipairs(alvosEm(onde,
						comBonus(CFG.RAIO_PONTO), 16)) do
					contados[alvo] = (contados[alvo] or 0) + 1
				end
			end
			for alvo, quantos in pairs(contados) do
				local vez = 1
				while vez <= quantos do
					aplicarDano(alvo, CFG.DANO_PONTO)
					vez = vez + 1
				end
				tombar(alvo, CFG.TOMBO)
			end
			-- quem estava preso e escapou da rota ainda leva a borda
			for _, alvo in ipairs(guardados) do
				if alvo and alvo.Parent and alvo.Health > 0
						and not contados[alvo] then
					aplicarDano(alvo, CFG.BORDA_PONTO)
				end
			end
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
end

local function marcarPonto(mira)
	if not (raiz and raiz.Parent) then return end
	local ponto = mira or frente(CFG.ALCANCE * 0.5)
	table.insert(pontos, ponto)
	local id = novoId("PONTO")
	table.insert(pontosId, id)
	vfx("PAGINA_PONTO", { posicao = ponto, duracao = CFG.JANELA + 1, id = id })
	tocarEm("PAGINA", ponto, 1.1 + #pontos * 0.08)
	if #pontos >= CFG.PONTOS then
		disparar()
	end
end

local function pararOTempo()
	abrirHabilidade()
	ocupado = true
	rig:PlaySequence("PAGINA_FINAL", despachar({
		CARGA  = { sfx = { "PAGINA", 0.85 } },
		SEGURA = { sfx = { "ECO", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			limparTudo()
			local centro = raiz.Position
			local minha = novaGeracao("L")
			escolhendo = true

			vfx("PAGINA_PARA", { posicao = centro,
				raio = comBonus(CFG.RAIO_PARADA) })
			tocarEm("PAGINA", centro, 0.8)

			presos = alvosEm(centro, comBonus(CFG.RAIO_PARADA), 16)
			for _, alvo in ipairs(presos) do
				prender(alvo, CFG.PARADA)
				afrouxar(alvo, 0.1, CFG.PARADA)
			end

			task.delay(CFG.JANELA, function()
				if geracao.L ~= minha then return end
				if #pontos > 0 then
					disparar()
				else
					limparTudo()
				end
			end)
		end },
	}), fecharHabilidade)
end

function primaria(mira)
	if segundaEtapa() then
		marcarPonto(mira)
	else
		pararOTempo()
	end
end
''')


T("Xester Curtain Reversal", 2,
  objeto="XesterCurtainReversal_Server_V1", sufixo="XesterVolta",
  arquetipo="SUPORTE", cutscene=True,
  rotulo_m1="a cutscene de volta para o baralho",
  origem=["F na Forma 2. Som `314678645` (ABRE), `413682983` (ESTILHACA) e",
          "`1499747506` (ATIRA). Ela DIVIDE a `ChaveRecarga` com o",
          "`Eclipse Deck`: a virada de forma é uma só, e trocar de Tool na",
          "mochila não pode burlar a espera dela."],
  cfg="""	RECARGA        = 30,
	PRAZO_CENA     = 8,""",
  corpo='''
--''' + R + '''
-- A VOLTA
--
-- Ela não procura a Tool da Forma 1. Escreve `XesterForma = 1` no Character,
-- tira o cajado e apaga a aura — e quem tiver uma Tool do baralho na mochila
-- já a saca de volta ao normal.
--
-- 1.80 s, três beats, como pedido: o dragão é absorvido pela carta, as chamas
-- somem, e Xester fecha o baralho.
--''' + R + '''

function limparTudo()
	novaGeracao("F")
end

function primaria(_mira)
	abrirHabilidade()
	ocupado = true
	comecarCena("REVERTER")
	local onde = raiz and raiz.Position or Vector3.new()

	rig:PlaySequence("REVERTER", despachar({
		ABSORVE = { cam = true, sfx = { "FECHA", 0.9 }, faz = function()
			vfx("CENA_ABSORVE", { posicao = raiz and raiz.Position or onde })
		end },
		APAGA   = { cam = true, sfx = { "RASGA", 0.85 }, faz = function()
			vfx("CENA_APAGA", { posicao = raiz and raiz.Position or onde })
			tirarCajado()
			apagarAura()
		end },
		FECHA   = { cam = true, sfx = { "NAIPES", 1.05 }, faz = function()
			local aqui = raiz and raiz.Position or onde
			vfx("CENA_FECHA", { posicao = aqui })
			tocarEm("FECHA", aqui, 1)
			escreverAtributo(ATR_FORMA, 1)
			escreverAtributo(ATR_USOS, 0)
		end },
	}), function()
		fecharHabilidade()
		acabarCena()
	end)
end
''')
