"""
servers_bombas7.py — as 14 habilidades do conjunto PODERES DE BOMBA.

Sete Tools, DUAS habilidades cada: M1 no clique, `R` na tecla. Lido por
`FERRAMENTAS/gerar_servers_bombas7.py`.

AS DUAS DE CADA TOOL SÃO UM PAR

    Não são duas habilidades soltas dividindo um Handle. Na `Fila de Bombas` o
    M1 planta e o R detona; na `Bomba Orbital` o M1 marca e o R faz cair; na
    `Bomba em Corrente` o M1 acende o estopim e o R dispara a reação. Quem usa
    só o M1 tem meia Tool, de propósito — e é isso que faz DUAS habilidades
    caberem numa Tool sem ela parecer pobre ao lado das de três.

QUATRO TÊM CENA, E A CENA COMEÇA NO PRIMEIRO KEYFRAME

    O beat `CENA` das quatro épicas NÃO leva `cam = true`. Ele leva
    `faz = abrirCena(...)`: o despachante roda `cam` ANTES de `faz`, então um
    `cam` ali dispararia `beatCena` com a cena ainda fechada, e o primeiro
    enquadramento seria descartado. A cena abre já no quadro dela.

O PONTO DA BOMBA É CALCULADO UMA VEZ

    `noChao(mira)` desce um raycast até o chão. Bomba que fica boiando na
    altura do mouse é o que faz o jogador errar sem entender por quê. E o
    ponto é guardado em `pontoCena`: a queda orbital cai onde o FAROL foi
    plantado, não onde o portador está quando a animação termina.

NENHUMA USA `Instance.new("Explosion")`

    Ela empurra e desmonta junta por conta própria, sem passar por
    `TakeDamage` nem respeitar `ForceField`, e o servidor perde o controle do
    que ela fez. Todo dano deste conjunto passa por `estourar`, que é núcleo e
    borda.
"""

COM_CUTSCENE = ("Bomba Orbital", "Bomba de Implosao", "Bomba em Corrente",
                "Bomba do Juizo")

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Fila de Bombas",
  objeto="FiladeBombas_Server_V1", sufixo="BombaFila",
  arquetipo="EXPLOSIVO", alcance_mira=55,
  rotulo_m1="Plantar", rotulo_r="Detonar Tudo",
  par="O M1 PLANTA e o R DETONA. Quem só clica planta uma fila que estoura "
      "sozinha, uma por uma; quem aperta o R escolhe o instante.",
  origem=["Handle: bandolim preto com tres bombas e um pavio Neon",
          "PLANTA 12221967 (Press) · ESTOURA 2691586 (DBExplode)",
          "TUDO 814635481 (Big Explosion) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 30,
	RECARGA       = 1.4,
	PRAZO         = 4.5,
	TETO_FILA     = 6,
	RAIO          = 15,
	NUCLEO        = 6,
	DANO          = 42,
	BORDA         = 16,
	EMPURRAO      = 70,
	TOMBO         = 0.9,

	RECARGA_R     = 12,
	INTERVALO     = 0.12,
	BONUS_JUNTO   = 1.35,""",
  estado="""local fila = {}""",
  ao_guardar="""	limparFila()
""",
  corpo='''
--''' + R + '''
-- A FILA
--
-- Cada bomba plantada é uma ENTRADA numa tabela, não uma peça no mundo: o que
-- existe no mundo é o VFX, que é do cliente. O servidor guarda posição, id e
-- prazo, e é só isso que ele precisa para saber o que estourar e onde.
--
-- O TETO EXISTE POR UM MOTIVO. Sem `TETO_FILA`, um jogador planta trinta
-- bombas no mesmo lugar e o `R` aplica trinta vezes o dano de área no mesmo
-- alvo, no mesmo quadro.
--''' + R + '''

function limparFila()
	for _, b in ipairs(fila) do
		vfx("PARAR", { id = b.id })
	end
	table.clear(fila)
end

--- Tira uma bomba da fila pelo id. Devolve a entrada, ou nil se ela já foi.
local function tirarDaFila(id)
	local i = 1
	while i <= #fila do
		if fila[i].id == id then
			local b = table.remove(fila, i)
			return b
		end
		i = i + 1
	end
	return nil
end

local function estourarUma(b, junto)
	if not b then return end
	vfx("PARAR", { id = b.id })
	vfx("ESTOURO_FILA", { posicao = b.onde, raio = CFG.RAIO })
	tocarEm("ESTOURA", b.onde, 0.95 + jitter(b.ordem) * 0.08)

	-- detonar a fila JUNTA vale mais que esperar cada pavio: é o que dá razão
	-- para o R existir
	local fator = junto and CFG.BONUS_JUNTO or 1
	estourar(b.onde, CFG.RAIO, CFG.NUCLEO,
		CFG.DANO * fator, CFG.BORDA * fator,
		CFG.EMPURRAO, CFG.TOMBO, 14)
end

--''' + R + '''
-- M1 — plantar
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local onde = noChao(mira)

	ocupado = true
	rig:PlaySequence("PLANTAR", despachar({

		CARGA = { sfx = { "PLANTA", 1.2 } },

		PLANTA = {
			sfx = { "PLANTA", 1.0 },
			faz = function()
				-- a mais velha sai para a nova entrar
				if #fila >= CFG.TETO_FILA then
					estourarUma(table.remove(fila, 1), false)
				end

				local b = {
					id = novoId("bomba"),
					onde = onde,
					ordem = #fila + 1,
				}
				table.insert(fila, b)

				vfx("BOMBA_PLANTADA", {
					id = b.id, posicao = onde, duracao = CFG.PRAZO,
				})

				-- o pavio: se ninguém apertar o R, ela vai sozinha
				task.delay(CFG.PRAZO, function()
					local ainda = tirarDaFila(b.id)
					if ainda then estourarUma(ainda, false) end
				end)
			end,
		},

		RECUA = { sfx = { "PLANTA", 0.85 } },

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — detonar tudo
--
-- Em ordem de plantio, com `INTERVALO` entre uma e outra: é o pavio correndo.
-- Todas no mesmo quadro seriam uma explosão só, mais brilhante.
--''' + R + '''

function extraR()
	if not rig then return end
	if #fila == 0 then return end

	ocupado = true
	rig:PlaySequence("DETONAR", despachar({

		CARGA = { sfx = { "TUDO", 1.15 } },

		ESTOURA = {
			sfx = { "TUDO", 0.85 },
			faz = function()
				local levas = fila
				fila = {}

				local i = 1
				local function proxima()
					if i > #levas then return end
					if not (personagem and personagem.Parent) then return end
					estourarUma(levas[i], true)
					i = i + 1
					task.delay(CFG.INTERVALO, proxima)
				end
				proxima()
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Explosao Nuclear",
  objeto="ExplosaoNuclear_Server_V1", sufixo="BombaNuclear7",
  arquetipo="EXPLOSIVO", alcance_mira=90,
  rotulo_m1="Ogiva", rotulo_r="Cogumelo",
  par="O M1 é a ogiva que VAI ATÉ LÁ; o R é o cogumelo, que estoura onde você "
      "está e deixa a poeira queimando. Um alcança, o outro nega o terreno.",
  origem=["Handle: ogiva branca com ponta vermelha e faixa de radiacao",
          "OGIVA 387278135 (Shoot) · NUCLEAR 180199793 (Explosion 4)",
          "VENTO 9125402735 (DuperBoom) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 85,
	RECARGA       = 1.6,
	VELOCIDADE    = 120,
	RAIO          = 26,
	NUCLEO        = 10,
	DANO          = 58,
	BORDA         = 22,
	EMPURRAO      = 80,
	TOMBO         = 1.0,
	PASSO_VOO     = 1 / 30,

	RECARGA_R     = 20,
	RAIO_NUKE     = 46,
	NUCLEO_NUKE   = 18,
	DANO_NUKE     = 120,
	BORDA_NUKE    = 45,
	EMPURRAO_NUKE = 130,
	TOMBO_NUKE    = 1.8,
	TEMPO_POEIRA  = 6,
	TIQUE_POEIRA  = 0.8,
	DANO_POEIRA   = 8,
	RAIO_POEIRA   = 26,""",
  estado="""local poeiraId = nil""",
  ao_guardar="""	pararPoeira()
""",
  corpo='''
--''' + R + '''
-- M1 — a ogiva
--
-- O voo é do CLIENTE, a 60 Hz. O servidor percorre a MESMA reta por
-- aritmética, a 1/30 s, só para saber onde ela bate — ele não move peça
-- nenhuma por quadro.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("OGIVA", despachar({

		CARGA = { sfx = { "OGIVA", 1.15 } },

		LANCA = {
			sfx = { "OGIVA", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + raiz.CFrame.LookVector * 3
					+ Vector3.new(0, 2.4, 0)
				local delta = alvo - origem
				if delta.Magnitude < 1 then
					delta = raiz.CFrame.LookVector * CFG.ALCANCE
				end
				local direcao = delta.Unit
				local alcance = math.min(delta.Magnitude, CFG.ALCANCE)
				local duracao = alcance / CFG.VELOCIDADE
				local destino = origem + direcao * alcance

				local id = novoId("ogiva")
				vfx("OGIVA", {
					id = id, posicao = origem, destino = destino,
					duracao = duracao,
				})

				-- o mesmo trajeto, por aritmética, só para achar o impacto
				task.spawn(function()
					local percorrido, onde = 0, origem
					while percorrido < alcance do
						task.wait(CFG.PASSO_VOO)
						if not (personagem and personagem.Parent) then return end
						percorrido = percorrido + CFG.VELOCIDADE * CFG.PASSO_VOO
						onde = origem + direcao * math.min(percorrido, alcance)
						if #alvosEm(onde, CFG.NUCLEO * 0.5, 1) > 0 then break end
					end

					vfx("PARAR", { id = id })
					vfx("ESTOURO_FILA", { posicao = onde, raio = CFG.RAIO })
					tocarEm("NUCLEAR", onde, 1.05)

					estourar(onde, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
						CFG.EMPURRAO, CFG.TOMBO, 16)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o cogumelo
--
-- Usa a sequência `epica` do `Poses.lua` — a mesma das quatro com cutscene —
-- mas SEM `cam`. É a Tool mais lenta das três nomeadas de propósito: 1.36 s de
-- animação é o aviso que o adversário tem de que ela está vindo, e é o que
-- justifica ela bater 120.
--
-- E a POEIRA fica depois. Ela não é enfeite: é negação de terreno com prazo,
-- e o `pararPoeira` a desliga tanto pelo fim quanto pelo `desmontar`.
--''' + R + '''

function pararPoeira()
	if poeiraId then
		vfx("PARAR", { id = poeiraId })
		poeiraId = nil
	end
end

function extraR()
	if not rig or not raiz then return end

	ocupado = true
	rig:PlaySequence("COGUMELO", despachar({

		CENA  = { sfx = { "NUCLEAR", 1.3 } },
		CARGA = { sfx = { "VENTO", 1.1 } },

		ESTOURA = {
			sfx = { "NUCLEAR", 0.8 },
			faz = function()
				if not raiz then return end
				local centro = noChao(raiz.Position)

				vfx("NUCLEAR", { posicao = centro, raio = CFG.RAIO_NUKE })
				tocarEm("NUCLEAR", centro, 0.75)
				tocarEm("VENTO", centro, 0.7)

				estourar(centro, CFG.RAIO_NUKE, CFG.NUCLEO_NUKE,
					CFG.DANO_NUKE, CFG.BORDA_NUKE,
					CFG.EMPURRAO_NUKE, CFG.TOMBO_NUKE, 24)

				-- a poeira que fica queimando
				pararPoeira()
				poeiraId = novoId("poeira")
				vfx("POEIRA", {
					id = poeiraId, posicao = centro,
					raio = CFG.RAIO_POEIRA, duracao = CFG.TEMPO_POEIRA,
				})

				local ate = os.clock() + CFG.TEMPO_POEIRA
				local function queimar()
					if os.clock() > ate then
						pararPoeira()
						return
					end
					if not (personagem and personagem.Parent) then
						pararPoeira()
						return
					end
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_POEIRA, 16)) do
						aplicarDano(alvo, CFG.DANO_POEIRA)
					end
					task.delay(CFG.TIQUE_POEIRA, queimar)
				end
				task.delay(CFG.TIQUE_POEIRA, queimar)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Coca Explosiva",
  objeto="CocaExplosiva_Server_V1", sufixo="BombaCoca",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="Garrafa", rotulo_r="Jato",
  par="O M1 é a garrafa que sai GUINANDO e não dá para mirar direito; o R é o "
      "jato, que é curto mas vai exatamente onde você aponta.",
  origem=["Handle: garrafa de vidro escuro com gargalo e tampa vermelha",
          "CHACOALHA 1489917733 (DrinkSound) · ESTOURO 6741488567 (expl)",
          "JATO 145486992 (sfx_swooshing) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 55,
	RECARGA       = 1.2,
	VOO           = 1.1,
	GUINADAS      = 5,
	DESVIO        = 9,
	RAIO          = 18,
	NUCLEO        = 7,
	DANO          = 44,
	BORDA         = 18,
	EMPURRAO      = 95,
	TOMBO         = 1.1,
	LENTIDAO      = 0.55,
	TEMPO_MELADO  = 3,

	RECARGA_R     = 11,
	ALCANCE_JATO  = 28,
	COSSENO_JATO  = 0.7,
	DANO_JATO     = 22,
	EMPURRAO_JATO = 75,
	LENTIDAO_JATO = 0.45,
	TEMPO_JATO    = 4,""",
  corpo='''
--''' + R + '''
-- M1 — a garrafa chacoalhada
--
-- A trajetória GUINA. Ela é uma poligonal de `GUINADAS` pontos, com desvio
-- lateral por ângulo áureo — determinístico, então o servidor e todos os
-- clientes concordam sobre onde a garrafa passou sem ninguém mandar posição
-- por quadro.
--
-- A GUINADA É A HABILIDADE. Uma garrafa que voa reto é só um projétil pior; o
-- que esta Tool oferece é dano alto em troca de não dar para mirar direito.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("GARRAFA", despachar({

		CARGA = { sfx = { "CHACOALHA", 1.15 } },

		LANCA = {
			sfx = { "CHACOALHA", 0.9 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + raiz.CFrame.LookVector * 2.5
					+ Vector3.new(0, 2.2, 0)
				local delta = alvo - origem
				if delta.Magnitude < 1 then
					delta = raiz.CFrame.LookVector * CFG.ALCANCE
				end
				local direcao = delta.Unit
				local alcance = math.min(delta.Magnitude, CFG.ALCANCE)

				-- a poligonal da guinada
				local lado = direcao:Cross(Vector3.new(0, 1, 0))
				if lado.Magnitude < 0.01 then lado = Vector3.new(1, 0, 0) end
				lado = lado.Unit

				local pontos = { origem }
				local i = 1
				while i <= CFG.GUINADAS do
					local fracao = i / CFG.GUINADAS
					local a = anguloDe(i)
					local reto = origem + direcao * (alcance * fracao)
					local torto = reto
						+ lado * (math.sin(a) * CFG.DESVIO * (1 - fracao * 0.4))
						+ Vector3.new(0, math.cos(a) * CFG.DESVIO * 0.4, 0)
					table.insert(pontos, torto)
					i = i + 1
				end

				local id = novoId("garrafa")
				vfx("GARRAFA", { id = id, pontos = pontos, duracao = CFG.VOO })

				-- o servidor anda pela MESMA poligonal, por aritmética
				task.spawn(function()
					local passo = CFG.VOO / CFG.GUINADAS
					local onde = pontos[#pontos]
					local j = 1
					while j < #pontos do
						task.wait(passo)
						if not (personagem and personagem.Parent) then return end
						onde = pontos[j + 1]
						if #alvosEm(onde, CFG.NUCLEO * 0.6, 1) > 0 then break end
						j = j + 1
					end

					vfx("PARAR", { id = id })
					vfx("ESPUMA", { posicao = onde, raio = CFG.RAIO })
					tocarEm("ESTOURO", onde, 1.0)

					estourar(onde, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
						CFG.EMPURRAO, CFG.TOMBO, 14)

					-- a espuma no chão deixa todo mundo melado
					for _, quem in ipairs(alvosEm(onde, CFG.RAIO, 14)) do
						afrouxar(quem, CFG.LENTIDAO, CFG.TEMPO_MELADO)
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o jato de espuma
--
-- Curto, mas vai exatamente onde aponta. O `COSSENO_JATO` é o que separa cone
-- de esfera: sem o produto escalar, um jato para a frente acerta quem está
-- atrás de quem esguichou.
--''' + R + '''

function extraR(mira)
	if not rig or not raiz then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("JATO", despachar({

		CARGA = { sfx = { "JATO", 1.25 } },

		MANDA = {
			sfx = { "JATO", 1.0 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector
				if typeof(alvo) == "Vector3" then
					local delta = alvo - origem
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end

				vfx("JATO", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE_JATO })

				for _, quem in ipairs(alvosNoCone(origem, direcao,
						CFG.ALCANCE_JATO, CFG.COSSENO_JATO, 12)) do
					aplicarDano(quem, CFG.DANO_JATO)
					empurrar(quem, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO_JATO, 0.3)
					afrouxar(quem, CFG.LENTIDAO_JATO, CFG.TEMPO_JATO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Bomba Orbital",
  objeto="BombaOrbital_Server_V1", sufixo="BombaOrbital",
  arquetipo="EXPLOSIVO", alcance_mira=110,
  rotulo_m1="Marcar", rotulo_r="Queda Orbital",
  par="O M1 planta o FAROL e o R chama a queda EM CIMA DELE. Sem farol, o R "
      "cai onde você está — que é onde você não quer.",
  origem=["Handle: farol com prato cromado, haste e ponta Neon azul",
          "MARCA 1310929645 (Locked On) · QUEDA 260281717 (MeteorSmash)",
          "IMPACTO 165969964 (Explosion) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 100,
	RECARGA       = 1.1,
	RAIO_FAROL    = 24,
	TEMPO_FAROL   = 10,
	DANO_MARCA    = 12,

	RECARGA_R     = 24,
	TEMPO_QUEDA   = 0.8,
	RAIO          = 40,
	NUCLEO        = 15,
	DANO          = 130,
	BORDA         = 48,
	EMPURRAO      = 140,
	TOMBO         = 2.0,
	RAIO_CENA     = 46,""",
  estado="""local farolId, farolOnde, farolAte = nil, nil, 0""",
  ao_guardar="""	pararFarol()
	fecharCena()
""",
  corpo='''
--''' + R + '''
-- O FAROL
--''' + R + '''

function pararFarol()
	if farolId then
		vfx("PARAR", { id = farolId })
		farolId = nil
	end
	farolOnde, farolAte = nil, 0
end

local function farolValido()
	return farolOnde ~= nil and os.clock() <= farolAte
end

--''' + R + '''
-- M1 — marcar
--
-- Um farol por vez. Plantar outro apaga o anterior: dois faróis fariam o
-- jogador ter de adivinhar em qual deles a queda vai cair.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local onde = noChao(mira)

	ocupado = true
	rig:PlaySequence("MARCAR", despachar({

		CARGA = { sfx = { "MARCA", 1.25 } },

		MANDA = {
			sfx = { "MARCA", 1.0 },
			faz = function()
				pararFarol()
				farolId = novoId("farol")
				farolOnde = onde
				farolAte = os.clock() + CFG.TEMPO_FAROL

				vfx("FAROL", {
					id = farolId, posicao = onde,
					raio = CFG.RAIO_FAROL, duracao = CFG.TEMPO_FAROL,
				})
				tocarEm("MARCA", onde, 1.1)

				-- o farol arde de leve em quem está debaixo dele: é o aviso
				for _, quem in ipairs(alvosEm(onde, CFG.RAIO_FAROL, 12)) do
					aplicarDano(quem, CFG.DANO_MARCA)
				end

				task.delay(CFG.TEMPO_FAROL, function()
					if farolId and os.clock() > farolAte then pararFarol() end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a queda orbital, COM CENA
--
-- Ela cai NO FAROL, não onde o portador está quando a animação termina. Sem
-- isso, marcar de longe e correr para trás faria a bomba seguir o jogador — e
-- o farol não serviria para nada.
--
-- O beat `CENA` abre a cutscene; `CARGA` e `ESTOURA` levam `cam = true` e
-- viram enquadramento. `fecharCena` roda no fim da sequência E no
-- `desmontar`: câmera presa é o pior do repertório.
--''' + R + '''

function extraR(mira)
	if not rig or not raiz then return end

	-- sem farol vivo, ela cai no ponto mirado mesmo — mas o farol é o que dá
	-- o alcance de 100 studs; sem ele o alcance é o da mira
	local ponto = farolValido() and farolOnde or noChao(mira)

	ocupado = true
	rig:PlaySequence("ORBITA", despachar({

		CENA = {
			sfx = { "QUEDA", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "QUEDA", 0.95 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "IMPACTO", 0.8 },
			faz = function()
				vfx("QUEDA", { posicao = ponto, duracao = CFG.TEMPO_QUEDA })
				tocarEm("QUEDA", ponto, 0.85)

				-- o impacto vem DEPOIS de a ogiva descer. Estourar junto com o
				-- feixe faria a queda inteira ser enfeite.
				task.delay(CFG.TEMPO_QUEDA, function()
					if not (personagem and personagem.Parent) then
						fecharCena()
						return
					end
					vfx("IMPACTO_ORBITAL", { posicao = ponto, raio = CFG.RAIO })
					tocarEm("IMPACTO", ponto, 0.75)

					estourar(ponto, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
						CFG.EMPURRAO, CFG.TOMBO, 24)
					pararFarol()
				end)
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		-- a cena fecha um pouco depois do último beat, para o FIM assentar
		task.delay(0.5, fecharCena)
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Bomba de Implosao",
  objeto="BombadeImplosao_Server_V1", sufixo="BombaImplosao",
  arquetipo="GRAVIDADE", alcance_mira=60,
  rotulo_m1="Semear", rotulo_r="Colapso",
  par="O M1 semeia o núcleo que PUXA todo mundo para o meio; o R faz colapsar. "
      "Sem semear antes, o colapso estoura num lugar vazio.",
  origem=["Handle: nucleo de vidro escuro dentro de um aro cromado",
          "SEMEIA 8578316223 (charge) · PUXA 2162238374 (SpirtLoop)",
          "COLAPSO 3313098116 (Explosion) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 45,
	RECARGA       = 1.2,
	TEMPO_NUCLEO  = 5,
	RAIO_SUCCAO   = 28,
	PULSO         = 0.2,
	PUXAO_MIN     = 20,
	PUXAO_MAX     = 78,
	ZONA_MORTA    = 5,
	DANO_TIQUE    = 5,

	RECARGA_R     = 22,
	ATRASO_COLAPSO = 0.3,
	RAIO          = 36,
	NUCLEO        = 14,
	DANO          = 110,
	BORDA         = 40,
	EMPURRAO      = 120,
	TOMBO         = 1.8,
	RAIO_CENA     = 40,""",
  estado="""local nucleoId, nucleoOnde, nucleoAte = nil, nil, 0
local nucleoLaco = nil""",
  ao_guardar="""	pararNucleo()
	fecharCena()
""",
  corpo='''
--''' + R + '''
-- O NÚCLEO
--
-- Ele PUXA por pulso, nunca contínuo: um `BodyVelocity` permanente tira o
-- controle do alvo por inteiro, e a habilidade vira prisão em vez de atração.
--''' + R + '''

function pararNucleo()
	if nucleoLaco then
		nucleoLaco:Disconnect()
		nucleoLaco = nil
	end
	if nucleoId then
		vfx("PARAR", { id = nucleoId })
		nucleoId = nil
	end
	nucleoOnde, nucleoAte = nil, 0
end

local function puxarPara(centro, alvoHum)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end

	local delta = centro - alvoRaiz.Position
	local dist = delta.Magnitude
	if dist < CFG.ZONA_MORTA or dist < 0.01 then return end

	local fracao = math.clamp(dist / CFG.RAIO_SUCCAO, 0, 1)
	local forca = CFG.PUXAO_MIN + (CFG.PUXAO_MAX - CFG.PUXAO_MIN) * fracao

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, CFG.PULSO * 0.9)
end

--''' + R + '''
-- M1 — semear
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local onde = noChao(mira) + Vector3.new(0, 2, 0)

	ocupado = true
	rig:PlaySequence("SEMEAR", despachar({

		CARGA = { sfx = { "SEMEIA", 1.2 } },

		PLANTA = {
			sfx = { "PUXA", 0.9 },
			faz = function()
				pararNucleo()
				nucleoId = novoId("nucleo")
				nucleoOnde = onde
				nucleoAte = os.clock() + CFG.TEMPO_NUCLEO

				vfx("NUCLEO", {
					id = nucleoId, posicao = onde,
					raio = CFG.RAIO_SUCCAO, duracao = CFG.TEMPO_NUCLEO,
				})
				tocarEm("PUXA", onde, 0.85)

				local proximoPulso = 0
				nucleoLaco = guardar(RunService.Heartbeat:Connect(function()
					local agora = os.clock()
					if agora > nucleoAte then
						pararNucleo()
						return
					end
					if agora < proximoPulso then return end
					proximoPulso = agora + CFG.PULSO

					for _, quem in ipairs(alvosEm(onde, CFG.RAIO_SUCCAO, 16)) do
						puxarPara(onde, quem)
						aplicarDano(quem, CFG.DANO_TIQUE)
					end
				end))
			end,
		},

		RECUA = { sfx = { "SEMEIA", 0.8 } },

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o colapso, COM CENA
--
-- A casca FECHA, e só então estoura. Os `ATRASO_COLAPSO` segundos são a
-- habilidade inteira: implosão que estoura junto com a sucção é só uma
-- explosão com outro nome.
--''' + R + '''

function extraR(mira)
	if not rig or not raiz then return end
	local ponto = nucleoOnde or (noChao(mira) + Vector3.new(0, 2, 0))

	ocupado = true
	rig:PlaySequence("COLAPSO", despachar({

		CENA = {
			sfx = { "PUXA", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "SEMEIA", 0.9 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "COLAPSO", 0.8 },
			faz = function()
				vfx("COLAPSO", { posicao = ponto, raio = CFG.RAIO })

				-- durante o fechamento a sucção é máxima: é a última chance de
				-- sair, e ela é curta
				for _, quem in ipairs(alvosEm(ponto, CFG.RAIO, 20)) do
					puxarPara(ponto, quem)
				end

				task.delay(CFG.ATRASO_COLAPSO, function()
					if not (personagem and personagem.Parent) then
						fecharCena()
						return
					end
					tocarEm("COLAPSO", ponto, 0.75)
					estourar(ponto, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
						CFG.EMPURRAO, CFG.TOMBO, 24)
					pararNucleo()
				end)
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.5, fecharCena)
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Bomba em Corrente",
  objeto="BombaemCorrente_Server_V1", sufixo="BombaCorrente",
  arquetipo="EXPLOSIVO", alcance_mira=70,
  rotulo_m1="Estopim", rotulo_r="Reacao",
  par="O M1 acende o ESTOPIM em quem acertar; o R faz a reação SALTAR dele "
      "para o mais perto, e do mais perto para o seguinte. Sem estopim aceso, "
      "o R não tem de onde partir.",
  origem=["Handle: tres elos de ferro ligados por um fio Neon",
          "ESTOPIM 2674547670 (Electric Explosion) · SALTO 96478259",
          "(Lightning2) · FIM 142070127 (explosive) — do catalogo do Acervo"],
  cfg="""	ALCANCE       = 20,
	RECARGA       = 1.0,
	RAIO_M1       = 12,
	DANO_M1       = 30,
	TEMPO_ESTOPIM = 8,

	RECARGA_R     = 21,
	SALTOS        = 5,
	RAIO_SALTO    = 34,
	INTERVALO     = 0.16,
	RAIO          = 16,
	NUCLEO        = 6,
	DANO          = 55,
	BORDA         = 22,
	CRESCE        = 1.18,
	EMPURRAO      = 85,
	TOMBO         = 1.0,
	RAIO_CENA     = 30,""",
  estado="""local estopimId, estopimAte = nil, 0
local estopimAlvo = nil""",
  ao_guardar="""	pararEstopim()
	fecharCena()
""",
  corpo='''
--''' + R + '''
-- O ESTOPIM
--
-- Guardado por referência FRACA não dá: aqui é uma variável só, e ela é
-- limpa quando o alvo morre ou o prazo vence. O que não pode acontecer é o
-- `R` partir de um Humanoid que já saiu do jogo.
--''' + R + '''

function pararEstopim()
	if estopimId then
		vfx("PARAR", { id = estopimId })
		estopimId = nil
	end
	estopimAlvo, estopimAte = nil, 0
end

local function estopimVivo()
	if not estopimAlvo then return false end
	if os.clock() > estopimAte then return false end
	if not estopimAlvo.Parent or estopimAlvo.Health <= 0 then return false end
	return true
end

--''' + R + '''
-- M1 — acender o estopim
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ESTOPIM", despachar({

		CARGA = { sfx = { "ESTOPIM", 1.2 } },

		LANCA = {
			sfx = { "ESTOPIM", 1.0 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				local pegos = alvosEm(centro, CFG.RAIO_M1, 6)
				for _, quem in ipairs(pegos) do
					aplicarDano(quem, CFG.DANO_M1)
				end

				vfx("ESTOURO_ELO", { posicao = centro, raio = CFG.RAIO_M1 })

				-- o estopim acende no PRIMEIRO que levou
				if #pegos > 0 then
					pararEstopim()
					estopimAlvo = pegos[1]
					estopimAte = os.clock() + CFG.TEMPO_ESTOPIM
					estopimId = novoId("estopim")
					local alvoRaiz = raizDe(estopimAlvo)
					vfx("ESTOPIM", {
						id = estopimId, peca = alvoRaiz,
						posicao = alvoRaiz and alvoRaiz.Position or centro,
						duracao = CFG.TEMPO_ESTOPIM,
					})
					task.delay(CFG.TEMPO_ESTOPIM, function()
						if not estopimVivo() then pararEstopim() end
					end)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a reação em cadeia, COM CENA
--
-- Salta do estopim para o mais perto, e do mais perto para o seguinte, até
-- `SALTOS`. Cada elo bate `CRESCE` vezes mais que o anterior — é o que faz a
-- corrente valer a pena montar em vez de só bater.
--
-- NINGUÉM É ACERTADO DUAS VEZES. `visitados` é o que impede a corrente de
-- pingar entre dois alvos vizinhos e aplicar cinco vezes o dano no mesmo par.
--''' + R + '''

function extraR(mira)
	if not rig or not raiz then return end
	if not estopimVivo() then return end

	local primeiro = estopimAlvo
	local primeiroRaiz = raizDe(primeiro)
	local ponto = primeiroRaiz and primeiroRaiz.Position or raiz.Position

	ocupado = true
	rig:PlaySequence("REACAO", despachar({

		CENA = {
			sfx = { "SALTO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "ESTOPIM", 1.1 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "FIM", 0.85 },
			faz = function()
				local visitados = {}
				local atual = primeiro
				visitados[atual] = true

				local elo = 0
				local function saltar()
					elo = elo + 1
					if elo > CFG.SALTOS or not atual then
						return
					end
					if not (personagem and personagem.Parent) then return end

					local atualRaiz = raizDe(atual)
					if not atualRaiz then return end
					local onde = atualRaiz.Position
					local forca = CFG.CRESCE ^ (elo - 1)

					vfx("ESTOURO_ELO", { posicao = onde, raio = CFG.RAIO })
					tocarEm("FIM", onde, 0.9 + elo * 0.04)

					estourar(onde, CFG.RAIO, CFG.NUCLEO,
						CFG.DANO * forca, CFG.BORDA * forca,
						CFG.EMPURRAO, CFG.TOMBO, 10)

					-- o próximo elo: o mais perto que ainda não levou
					local melhor, dist = nil, math.huge
					for _, quem in ipairs(alvosEm(onde, CFG.RAIO_SALTO, 16)) do
						if not visitados[quem] then
							local qr = raizDe(quem)
							if qr then
								local dd = (qr.Position - onde).Magnitude
								if dd < dist then melhor, dist = quem, dd end
							end
						end
					end

					if melhor then
						local mr = raizDe(melhor)
						vfx("SALTO", { posicao = onde,
							destino = mr and mr.Position or onde })
						tocarEm("SALTO", onde, 1.1 + elo * 0.05)
						visitados[melhor] = true
						atual = melhor
						task.delay(CFG.INTERVALO, saltar)
					end
				end
				saltar()
				pararEstopim()
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.5, fecharCena)
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Bomba do Juizo",
  objeto="BombadoJuizo_Server_V1", sufixo="BombaJuizo",
  arquetipo="EXPLOSIVO", alcance_mira=50,
  rotulo_m1="Contagem", rotulo_r="Juizo Final",
  par="O M1 começa a CONTAGEM, que já bate e ARMA o R por um tempo. Fora da "
      "janela, o Juízo sai pela metade — a grande do conjunto se paga.",
  origem=["Handle: esfera de ferro com mostrador, cinta Neon e pavio",
          "CONTAGEM 9125673453 (Beep) · JUIZO 95335614812989 (Supernova)",
          "ONDA 4870579875 (earthquake1) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 14,
	RECARGA       = 1.5,
	TEMPO_CONTA   = 3,
	RAIO_CONTA    = 12,
	DANO_CONTA    = 26,
	JANELA_ARMADO = 8,

	RECARGA_R     = 40,
	RAIO          = 60,
	NUCLEO        = 22,
	DANO          = 190,
	BORDA         = 65,
	EMPURRAO      = 165,
	TOMBO         = 2.4,
	ATRASO_ONDA   = 0.45,
	DANO_ONDA     = 60,
	FATOR_FRIO    = 0.5,
	RAIO_CENA     = 66,""",
  estado="""local contaId, armadoAte = nil, 0""",
  ao_guardar="""	pararConta()
	fecharCena()
""",
  corpo='''
--''' + R + '''
-- A CONTAGEM
--''' + R + '''

function pararConta()
	if contaId then
		vfx("PARAR", { id = contaId })
		contaId = nil
	end
end

local function armado()
	return os.clock() <= armadoAte
end

--''' + R + '''
-- M1 — começar a contagem
--
-- Ela já bate sozinha, e ARMA o R por `JANELA_ARMADO` segundos. É o que impede
-- a Tool de ser um botão de 40 s de recarga com nada para fazer no meio.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local onde = noChao(mira)

	ocupado = true
	rig:PlaySequence("CONTAGEM", despachar({

		CARGA = { sfx = { "CONTAGEM", 1.15 } },

		ESTOURA = {
			sfx = { "CONTAGEM", 1.0 },
			faz = function()
				pararConta()
				contaId = novoId("conta")
				armadoAte = os.clock() + CFG.JANELA_ARMADO

				vfx("CONTAGEM", {
					id = contaId, posicao = onde,
					raio = CFG.RAIO_CONTA, duracao = CFG.TEMPO_CONTA,
				})
				tocarEm("CONTAGEM", onde, 1.05)

				task.delay(CFG.TEMPO_CONTA, function()
					pararConta()
					if not (personagem and personagem.Parent) then return end
					vfx("ESTOURO_ELO", { posicao = onde, raio = CFG.RAIO_CONTA })
					estourar(onde, CFG.RAIO_CONTA, CFG.RAIO_CONTA * 0.4,
						CFG.DANO_CONTA, CFG.DANO_CONTA * 0.5, 60, 0.7, 10)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o Juízo Final, COM CENA
--
-- A maior do conjunto. Fora da janela de `JANELA_ARMADO` ela sai por
-- `FATOR_FRIO` do dano — não é bloqueada, porque bloquear a ultimate de uma
-- Tool de 40 s de recarga é fazer o jogador esperar 40 s por nada.
--
-- E ela tem DUAS batidas: o estouro, e a onda que vem `ATRASO_ONDA` depois.
-- A segunda pega quem se levantou.
--''' + R + '''

function extraR(mira)
	if not rig or not raiz then return end
	local ponto = noChao(raiz.Position)
	local frio = not armado()
	local fator = frio and CFG.FATOR_FRIO or 1

	ocupado = true
	rig:PlaySequence("JUIZO", despachar({

		CENA = {
			sfx = { "JUIZO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "CONTAGEM", 1.4 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "JUIZO", 0.75 },
			faz = function()
				armadoAte = 0
				pararConta()

				vfx("JUIZO", { posicao = ponto, raio = CFG.RAIO })
				tocarEm("JUIZO", ponto, 0.7)

				estourar(ponto, CFG.RAIO, CFG.NUCLEO,
					CFG.DANO * fator, CFG.BORDA * fator,
					CFG.EMPURRAO, CFG.TOMBO, 28)

				-- a segunda batida, para quem se levantou
				task.delay(CFG.ATRASO_ONDA, function()
					if not (personagem and personagem.Parent) then return end
					vfx("ONDA_JUIZO", { posicao = ponto, raio = CFG.RAIO })
					tocarEm("ONDA", ponto, 0.7)
					estourar(ponto, CFG.RAIO, CFG.NUCLEO,
						CFG.DANO_ONDA * fator, CFG.DANO_ONDA * 0.5 * fator,
						CFG.EMPURRAO * 0.6, CFG.TOMBO * 0.6, 28)
				end)
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.6, fecharCena)
	end)
end
''')
