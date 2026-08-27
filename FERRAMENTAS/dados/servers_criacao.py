"""
servers_criacao.py — as 21 habilidades do conjunto CRIAÇÃO.

Sete Tools, TRÊS habilidades cada: M1 no clique, `R` e `T` nas teclas. Lido
por `FERRAMENTAS/gerar_servers_criacao.py`.

O EIXO DAS SETE: A COISA CRIADA É A HABILIDADE

    Em todo conjunto anterior, o que aparecia no mundo era VFX — desenho do
    cliente, que some sozinho e com que ninguém colide. Aqui a muralha
    BLOQUEIA, a torre LEVANTA quem está em cima, o cipó PRENDE. A peça é a
    habilidade, e por isso ela existe no servidor.

    Isso cobra um preço, e o preço é o bloco `criar()` / `recolherTudo()`:
    nada é posto no mundo fora dele, tudo tem prazo, e o registro tem três
    saídas. Peça de servidor sem dono fica no mapa até o servidor cair.

O SEGUNDO EIXO: CRIAR NÃO É SÓ UM JEITO DE BATER

    Quatro das sete têm uma habilidade que NÃO dá dano nenhum — a `Muralha`, o
    `Molde`, o `Esboco` e o `Continente`. Elas mudam o terreno, e o dano vem
    de outra coisa depois. É o que separa este conjunto de mais um conjunto de
    explosões com outro nome.
"""

COM_CUTSCENE = ("Demiurgo",)

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Forja",
  objeto="Forja_Server_V1", sufixo="CriacaoForja",
  arquetipo="MELEE", alcance_mira=45,
  rotulo_m1="Martelar", rotulo_r="Bigorna", rotulo_t="Tempera",
  origem=["Handle autoral: martelo de cabo de madeira com brasa na cabeca",
          "MARTELO 1255794 (Gravity Hammer) · BIGORNA 933780081 (MetalHit)",
          "TEMPERA 546410481 (MetalHit2) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 12,
	RECARGA       = 0.8,
	RAIO          = 8,
	DANO          = 26,
	AQUECE_TETO   = 4,
	AQUECE_BONUS  = 0.22,
	TEMPO_QUENTE  = 5,

	RECARGA_R     = 14,
	QUEDA         = 0.55,
	RAIO_BIGORNA  = 14,
	NUCLEO        = 6,
	DANO_BIGORNA  = 70,
	BORDA         = 28,
	TOMBO         = 1.4,
	VIDA_BIGORNA  = 6,

	RECARGA_T     = 20,
	TEMPO_TEMPERA = 6,
	DEVOLVE       = 0.4,
	TETO_DEVOLVE  = 30,
	TETO_CRIADAS  = 6,""",
  estado="""local temperaAte, temperaConexao = 0, nil
--- Quantas marteladas cada alvo levou. Chave FRACA: alvo que sai do jogo leva
--- a conta junto, e tabela forte aqui seria vazamento que cresce a partida.
local quentes = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	pararTempera()
""",
  corpo='''
--''' + R + '''
-- O AQUECIMENTO
--
-- Cada martelada deixa o alvo mais quente, ATÉ UM TETO, e alvo quente leva
-- mais da próxima. É o que faz o M1 desta Tool valer a pena repetir em vez de
-- ser um golpe qualquer — e o teto é o que impede oito marteladas seguidas de
-- virarem dano infinito.
--''' + R + '''

local function aquecer(alvoHum)
	if not alvoHum or alvoHum.Health <= 0 then return end
	local reg = quentes[alvoHum]
	if not reg then
		reg = { camadas = 0 }
		quentes[alvoHum] = reg
	end
	reg.camadas = math.min(reg.camadas + 1, CFG.AQUECE_TETO)
	reg.ate = os.clock() + CFG.TEMPO_QUENTE
end

local function bonusDe(alvoHum)
	local reg = quentes[alvoHum]
	if not reg then return 1 end
	if os.clock() > (reg.ate or 0) then
		quentes[alvoHum] = nil
		return 1
	end
	return 1 + reg.camadas * CFG.AQUECE_BONUS
end

--''' + R + '''
-- M1 — martelar
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("MARTELAR", despachar({

		CARGA = { sfx = { "MARTELO", 1.2 } },

		GOLPE = {
			sfx = { "MARTELO", 0.95 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("MARTELO", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(quem, math.floor(CFG.DANO * bonusDe(quem) + 0.5))
					aquecer(quem)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a bigorna
--
-- Ela NASCE no ar e cai. A peça é de servidor e colide: quem estiver debaixo
-- quando ela assentar fica preso entre ela e o chão, que é o ponto.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("BIGORNA", despachar({

		CARGA = { sfx = { "BIGORNA", 1.15 } },
		SEGURA = { sfx = { "MARTELO", 1.35 } },

		ERGUE = {
			sfx = { "BIGORNA", 0.85 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("BIGORNA", { posicao = centro, raio = CFG.RAIO_BIGORNA,
					duracao = CFG.QUEDA })

				task.delay(CFG.QUEDA, function()
					if not (personagem and personagem.Parent) then return end
					tocarEm("BIGORNA", centro, 0.8)

					-- a peça de verdade, com prazo e registro
					criar(CFrame.new(centro + Vector3.new(0, 1.7, 0)),
						Vector3.new(5, 3.4, 3), {
							Color = Color3.fromRGB(96, 100, 110),
							Material = Enum.Material.Metal,
						}, CFG.VIDA_BIGORNA)

					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_BIGORNA, 14)) do
						local qr = raizDe(quem)
						local d = qr and (qr.Position - centro).Magnitude
							or CFG.RAIO_BIGORNA
						local dano = (d <= CFG.NUCLEO) and CFG.DANO_BIGORNA
							or CFG.BORDA
						aplicarDano(quem, math.floor(dano * bonusDe(quem) + 0.5))
						tombar(quem, CFG.TOMBO)
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a têmpera
--
-- Parte do dano que chegar é DEVOLVIDA em vida, com teto. Não é redução de
-- dano: reduzir dano exigiria interceptar o golpe, e nenhum script de Tool
-- pode fazer isso sem sequestrar o `Humanoid` de quem usa. Devolver depois é
-- honesto, e o teto impede que a placa vire imortalidade.
--''' + R + '''

function pararTempera()
	if temperaConexao then
		temperaConexao:Disconnect()
		temperaConexao = nil
	end
	temperaAte = 0
end

function extraT()
	if not rig or not humanoide then return end

	ocupado = true
	rig:PlaySequence("TEMPERA", despachar({

		CARGA = { sfx = { "TEMPERA", 1.2 } },
		SEGURA = { sfx = { "MARTELO", 1.4 } },

		ERGUE = {
			sfx = { "TEMPERA", 0.9 },
			faz = function()
				if not (humanoide and raiz) then return end
				pararTempera()
				temperaAte = os.clock() + CFG.TEMPO_TEMPERA

				vfx("TEMPERA", { id = novoId("tempera"), peca = raiz,
					duracao = CFG.TEMPO_TEMPERA })
				tocarEm("TEMPERA", raiz.Position, 1.0)

				local antes = humanoide.Health
				temperaConexao = guardar(humanoide.HealthChanged:Connect(
					function(agora)
						local perdeu = antes - agora
						antes = agora
						if perdeu <= 0 then return end
						if os.clock() > temperaAte then return end
						if not (humanoide and humanoide.Parent) then return end

						local volta = math.min(perdeu * CFG.DEVOLVE,
							CFG.TETO_DEVOLVE)
						local nova = math.min(humanoide.Health + volta,
							humanoide.MaxHealth)
						humanoide.Health = nova
						antes = nova
					end))

				task.delay(CFG.TEMPO_TEMPERA, pararTempera)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Alvenaria",
  objeto="Alvenaria_Server_V1", sufixo="CriacaoAlvenaria",
  arquetipo="MELEE", alcance_mira=55,
  rotulo_m1="Tijolo", rotulo_r="Muralha", rotulo_t="Torre",
  origem=["Handle autoral: colher de pedreiro com tijolo e argamassa",
          "TIJOLO 131219241 (SFX: Gavel) · MURALHA 281633012",
          "(earthparticle) · TORRE 4870579875 (earthquake1) — do catalogo"],
  cfg="""	ALCANCE       = 11,
	RECARGA       = 0.9,
	RAIO          = 7,
	DANO          = 30,

	RECARGA_R     = 16,
	SECOES        = 3,
	LARGURA_MURO  = 18,
	ALTURA_MURO   = 9,
	ESPESSURA     = 1.6,
	DISTANCIA     = 9,
	VIDA_MURO     = 12,

	RECARGA_T     = 22,
	RAIO_TORRE    = 4,
	ALTURA_TORRE  = 16,
	VIDA_TORRE    = 10,
	DANO_TORRE    = 45,
	LEVANTA       = 78,
	TOMBO         = 1.2,
	TETO_CRIADAS  = 8,""",
  corpo='''
--''' + R + '''
-- M1 — o tijolo
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("TIJOLO", despachar({

		CARGA = { sfx = { "TIJOLO", 1.2 } },

		GOLPE = {
			sfx = { "TIJOLO", 1.0 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("TIJOLO", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(quem, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a muralha
--
-- ELA NÃO DÁ DANO NENHUM, e isso é o desenho. É uma habilidade de TERRENO:
-- três seções de pedra colidível à frente, com prazo. O que ela faz é decidir
-- por onde o outro pode vir.
--
-- A muralha nasce À FRENTE, não em volta: nascer em volta prenderia quem a
-- ergueu dentro dela.
--''' + R + '''

function extraR()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("MURALHA", despachar({

		CARGA = { sfx = { "MURALHA", 1.1 } },
		SEGURA = { sfx = { "TIJOLO", 1.3 } },

		ERGUE = {
			sfx = { "MURALHA", 0.85 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local base = noChao(raiz.Position + direcao * CFG.DISTANCIA)
				local quadro = CFrame.lookAt(
					base + Vector3.new(0, CFG.ALTURA_MURO * 0.5, 0),
					base + Vector3.new(0, CFG.ALTURA_MURO * 0.5, 0) + direcao)

				vfx("MURALHA", { quadro = quadro, secoes = CFG.SECOES,
					tamanho = Vector3.new(CFG.LARGURA_MURO, CFG.ALTURA_MURO,
						CFG.ESPESSURA) })
				tocarEm("MURALHA", base, 0.9)

				local largura = CFG.LARGURA_MURO / CFG.SECOES
				local i = 0
				while i < CFG.SECOES do
					local desvio = -CFG.LARGURA_MURO * 0.5
						+ largura * (i + 0.5)
					criar(quadro * CFrame.new(desvio, 0, 0),
						Vector3.new(largura * 0.96, CFG.ALTURA_MURO,
							CFG.ESPESSURA), {
							Color = Color3.fromRGB(150, 146, 138),
							Material = Enum.Material.Concrete,
						}, CFG.VIDA_MURO)
					i = i + 1
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a torre
--
-- Ela abre DEBAIXO do alvo, e o levanta. O empurrão para cima não é enfeite:
-- sem ele o alvo nasce DENTRO da peça e o Roblox o joga para um lado
-- qualquer, ou o prende. Levantar de propósito é a única forma de a
-- habilidade ser legível.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("TORRE", despachar({

		CARGA = { sfx = { "TORRE", 1.0 } },
		SEGURA = { sfx = { "MURALHA", 1.2 } },

		ERGUE = {
			sfx = { "TORRE", 0.8 },
			faz = function()
				local base = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("TORRE", { posicao = base, altura = CFG.ALTURA_TORRE,
					raio = CFG.RAIO_TORRE })
				tocarEm("TORRE", base, 0.8)

				-- levanta ANTES de a peça existir: assim ninguém nasce dentro
				levantar(base, CFG.RAIO_TORRE * 2.4, CFG.LEVANTA, 10)
				for _, quem in ipairs(alvosEm(base, CFG.RAIO_TORRE * 2.4, 10)) do
					aplicarDano(quem, CFG.DANO_TORRE)
					tombar(quem, CFG.TOMBO)
				end

				criar(CFrame.new(base + Vector3.new(0,
						CFG.ALTURA_TORRE * 0.5, 0)),
					Vector3.new(CFG.RAIO_TORRE * 2, CFG.ALTURA_TORRE,
						CFG.RAIO_TORRE * 2), {
						Color = Color3.fromRGB(150, 146, 138),
						Material = Enum.Material.Slate,
					}, CFG.VIDA_TORRE)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Semente",
  objeto="Semente_Server_V1", sufixo="CriacaoSemente",
  arquetipo="ARCANO", alcance_mira=50,
  rotulo_m1="Broto", rotulo_r="Cipo", rotulo_t="Arvore",
  origem=["Handle autoral: galho vivo com folha e broto Neon",
          "BROTO 1489705211 (Swoosh) · CIPO 124444290902740 (chains_break)",
          "ARVORE 3264923 (Defile) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 40,
	RECARGA       = 0.9,
	RAIO          = 7,
	DANO          = 24,
	LENTIDAO      = 0.65,
	TEMPO_LENTO   = 2.5,

	RECARGA_R     = 15,
	RAIO_CIPO     = 20,
	TEMPO_CIPO    = 3,
	DANO_CIPO     = 18,

	RECARGA_T     = 24,
	RAIO_ARVORE   = 12,
	ALTURA_ARVORE = 22,
	VIDA_ARVORE   = 14,
	DANO_ARVORE   = 62,
	LEVANTA       = 88,
	TOMBO         = 1.6,
	TETO_CRIADAS  = 5,""",
  estado="""--- Quem está preso pelo cipó, com a velocidade de ANTES. Chave FRACA.
local presos = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	soltarCipos()
""",
  corpo='''
--''' + R + '''
-- O CIPÓ
--
-- Prender é `WalkSpeed = 0` com a velocidade de ANTES guardada, e nunca
-- `Anchored`: ancorar a raiz do alvo o trava por inteiro e o deixa preso no
-- ar se a Tool sumir no meio.
--
-- E a devolução tem TRÊS saídas, como todo estado deste repositório: o prazo,
-- o `Unequipped` e o `Destroying`.
--''' + R + '''

function soltarCipos()
	for alvoHum, reg in pairs(presos) do
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = reg.andar
			alvoHum.JumpPower = reg.pular
		end
	end
	table.clear(presos)
end

local function prender(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return false end
	if presos[alvoHum] then return false end   -- guarda contra empilhar
	presos[alvoHum] = {
		andar = alvoHum.WalkSpeed,
		pular = alvoHum.JumpPower,
	}
	alvoHum.WalkSpeed = 0
	alvoHum.JumpPower = 0

	task.delay(tempo, function()
		local reg = presos[alvoHum]
		if not reg then return end
		presos[alvoHum] = nil
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = reg.andar
			alvoHum.JumpPower = reg.pular
		end
	end)
	return true
end

--''' + R + '''
-- M1 — o broto
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("BROTO", despachar({

		CARGA = { sfx = { "BROTO", 1.2 } },

		PLANTA = {
			sfx = { "BROTO", 1.0 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("BROTO", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
					aplicarDano(quem, CFG.DANO)
					local antes = quem.WalkSpeed
					quem.WalkSpeed = antes * CFG.LENTIDAO
					task.delay(CFG.TEMPO_LENTO, function()
						if quem and quem.Parent and quem.Health > 0
								and not presos[quem] then
							quem.WalkSpeed = antes
						end
					end)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o cipó
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("CIPO", despachar({

		CARGA = { sfx = { "CIPO", 1.1 } },

		PLANTA = {
			sfx = { "CIPO", 0.9 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())
				tocarEm("CIPO", centro, 0.95)

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_CIPO, 14)) do
					aplicarDano(quem, CFG.DANO_CIPO)
					if prender(quem, CFG.TEMPO_CIPO) then
						local qr = raizDe(quem)
						vfx("CIPO", { id = novoId("cipo"), peca = qr,
							posicao = qr and qr.Position or centro,
							duracao = CFG.TEMPO_CIPO })
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a árvore
--
-- O tronco é peça de servidor, e ele SOBE onde estava o chão. Quem estiver em
-- volta é levantado antes, pelo mesmo motivo da torre.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ARVORE", despachar({

		CARGA = { sfx = { "ARVORE", 1.0 } },
		SEGURA = { sfx = { "CIPO", 1.2 } },

		ERGUE = {
			sfx = { "ARVORE", 0.8 },
			faz = function()
				local base = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("ARVORE", { posicao = base, altura = CFG.ALTURA_ARVORE,
					raio = CFG.RAIO_ARVORE })
				tocarEm("ARVORE", base, 0.8)

				levantar(base, CFG.RAIO_ARVORE, CFG.LEVANTA, 14)
				for _, quem in ipairs(alvosEm(base, CFG.RAIO_ARVORE, 14)) do
					aplicarDano(quem, CFG.DANO_ARVORE)
					tombar(quem, CFG.TOMBO)
				end

				criar(CFrame.new(base + Vector3.new(0,
						CFG.ALTURA_ARVORE * 0.5, 0)),
					Vector3.new(3.4, CFG.ALTURA_ARVORE, 3.4), {
						Color = Color3.fromRGB(122, 96, 68),
						Material = Enum.Material.Wood,
					}, CFG.VIDA_ARVORE)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Projeto",
  objeto="Projeto_Server_V1", sufixo="CriacaoProjeto",
  arquetipo="ARCANO", alcance_mira=60,
  rotulo_m1="Traco", rotulo_r="Esboco", rotulo_t="Materializar",
  origem=["Handle autoral: prancheta com regua e linha de tinta",
          "TRACO 5651577252 (glint) · ESBOCO 1388726556 (ClickAccept)",
          "MATERIALIZA 550210020 (loot_appears) — do catalogo do Acervo"],
  cfg="""	ALCANCE       = 26,
	RECARGA       = 0.8,
	LARGURA       = 4,
	DANO          = 28,

	RECARGA_R     = 13,
	RAIO_ESBOCO   = 22,
	TEMPO_ESBOCO  = 8,
	DANO_ESBOCO   = 8,
	PULSO         = 1.0,

	RECARGA_T     = 21,
	FATOR         = 1.0,
	TETO_CONTA    = 200,
	DANO_BLOCO    = 40,
	EMPURRAO      = 80,
	TOMBO         = 1.3,
	VIDA_BLOCO    = 8,
	TETO_CRIADAS  = 8,""",
  estado="""local esbocoId, esbocoOnde, esbocoAte = nil, nil, 0
--- O que cada alvo acumulou dentro do esboço. Chave FRACA.
local conta = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	pararEsboco()
""",
  corpo='''
--''' + R + '''
-- O DESENHO ACUMULA, E O `T` CONSTRÓI
--
-- Dentro do esboço, o dano não é só dano: ele é ANOTADO. O `T` materializa o
-- que foi desenhado, e a conta cai de uma vez. É o par que dá razão às três
-- habilidades desta Tool existirem juntas.
--
-- O TETO existe porque sem ele um alvo parado oito segundos dentro do esboço
-- acumula a conta de oito segundos de todo mundo e morre sem aviso.
--''' + R + '''

local function anotar(alvoHum, quanto)
	if not alvoHum then return end
	conta[alvoHum] = math.min((conta[alvoHum] or 0) + quanto, CFG.TETO_CONTA)
end

local function cobrar(alvoHum)
	local devido = conta[alvoHum]
	if not devido or devido <= 0 then return 0 end
	conta[alvoHum] = nil
	aplicarDano(alvoHum, math.floor(devido * CFG.FATOR + 0.5))
	return devido
end

--''' + R + '''
-- M1 — o traço
--
-- Uma reta. Quem está NO CAMINHO leva, não quem está perto do fim.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("TRACO", despachar({

		CARGA = { sfx = { "TRACO", 1.2 } },

		TRACA = {
			sfx = { "TRACO", 1.0 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector
				if typeof(alvo) == "Vector3" then
					local delta = alvo - origem
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local destino = origem + direcao * CFG.ALCANCE

				vfx("TRACO", { posicao = raiz.Position, destino = destino,
					direcao = direcao, raio = CFG.ALCANCE })

				for _, quem in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.LARGURA, 10)) do
					aplicarDano(quem, CFG.DANO)
					if esbocoOnde then anotar(quem, CFG.DANO) end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o esboço
--
-- ELE NÃO DÁ QUASE DANO NENHUM: 8 por segundo. O que ele faz é marcar o chão
-- e ligar a contagem — é a habilidade de PREPARAR, e o `T` é a de cobrar.
--''' + R + '''

function pararEsboco()
	if esbocoId then
		vfx("PARAR", { id = esbocoId })
		esbocoId = nil
	end
	esbocoOnde, esbocoAte = nil, 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ESBOCO", despachar({

		CARGA = { sfx = { "ESBOCO", 1.15 } },

		TRACA = {
			sfx = { "ESBOCO", 0.95 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())
				pararEsboco()

				esbocoId = novoId("esboco")
				esbocoOnde = centro
				esbocoAte = os.clock() + CFG.TEMPO_ESBOCO

				vfx("ESBOCO", { id = esbocoId, posicao = centro,
					raio = CFG.RAIO_ESBOCO, duracao = CFG.TEMPO_ESBOCO })
				tocarEm("ESBOCO", centro, 1.0)

				local function pulsar()
					if os.clock() > esbocoAte then
						pararEsboco()
						return
					end
					if not (personagem and personagem.Parent) then
						pararEsboco()
						return
					end
					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_ESBOCO, 16)) do
						aplicarDano(quem, CFG.DANO_ESBOCO)
						anotar(quem, CFG.DANO_ESBOCO)
					end
					task.delay(CFG.PULSO, pulsar)
				end
				task.delay(CFG.PULSO, pulsar)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — materializar
--
-- Seis blocos nascem no esboço, e a conta de todo mundo lá dentro cai de uma
-- vez. Sem esboço aberto, ele nasce onde você mira — e sem conta nenhuma para
-- cobrar, que é o que faz valer a pena preparar antes.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("MATERIALIZAR", despachar({

		CARGA = { sfx = { "MATERIALIZA", 1.1 } },
		SEGURA = { sfx = { "TRACO", 1.35 } },

		ERGUE = {
			sfx = { "MATERIALIZA", 0.85 },
			faz = function()
				local centro = esbocoOnde
					or noChao((typeof(onde) == "Vector3") and onde or frente())

				vfx("MATERIALIZAR", { posicao = centro,
					raio = CFG.RAIO_ESBOCO })
				tocarEm("MATERIALIZA", centro, 0.9)

				local i = 1
				while i <= 6 do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_ESBOCO * 0.6
					local ponto = centro + Vector3.new(math.cos(a) * alcance, 0,
						math.sin(a) * alcance)
					criar(CFrame.new(noChao(ponto) + Vector3.new(0, 2.5, 0)),
						Vector3.new(3, 5, 3), {
							Color = Color3.fromRGB(232, 236, 242),
							Material = Enum.Material.SmoothPlastic,
						}, CFG.VIDA_BLOCO)
					i = i + 1
				end

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_ESBOCO, 18)) do
					aplicarDano(quem, CFG.DANO_BLOCO)
					cobrar(quem)
					local qr = raizDe(quem)
					if qr then
						empurrar(quem, (qr.Position - centro)
							+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.3)
					end
					tombar(quem, CFG.TOMBO)
				end
				pararEsboco()
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Prototipo",
  objeto="Prototipo_Server_V1", sufixo="CriacaoPrototipo",
  arquetipo="EXPLOSIVO", alcance_mira=50,
  rotulo_m1="Peca", rotulo_r="Molde", rotulo_t="Serie",
  origem=["Handle autoral: bancada com uma peca meio pronta",
          "PECA 7449454513 (Drop) · MOLDE 7449454869 (Pickup)",
          "SERIE 6741488567 (expl) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 11,
	RECARGA       = 0.8,
	RAIO          = 7,
	DANO          = 26,

	RECARGA_R     = 14,
	VIDA_MOLDE    = 6,
	RAIO_MOLDE    = 16,
	DANO_MOLDE    = 48,
	EMPURRAO      = 80,
	TETO_MOLDES   = 3,

	RECARGA_T     = 23,
	SERIE         = 3,
	INTERVALO     = 0.14,
	BONUS_SERIE   = 1.25,
	TOMBO         = 1.2,
	TETO_CRIADAS  = 6,""",
  estado="""--- Os moldes de pé: posição, id e prazo. Lista, não instância — a peça de
--- verdade está no registro de `criadas`.
local moldes = {}""",
  ao_guardar="""	limparMoldes()
""",
  corpo='''
--''' + R + '''
-- OS MOLDES
--
-- Cada molde é um boneco em fio que fica de pé e ESTOURA — pelo prazo, ou
-- quando o `T` manda. O teto existe porque sem ele um jogador planta vinte
-- moldes com calma antes da briga e o `T` soma vinte explosões.
--''' + R + '''

function limparMoldes()
	for _, m in ipairs(moldes) do
		vfx("PARAR", { id = m.id })
	end
	table.clear(moldes)
end

local function tirarMolde(id)
	local i = 1
	while i <= #moldes do
		if moldes[i].id == id then return table.remove(moldes, i) end
		i = i + 1
	end
	return nil
end

local function estourarMolde(m, junto)
	if not m then return end
	vfx("PARAR", { id = m.id })
	vfx("SERIE", { posicao = m.onde, raio = CFG.RAIO_MOLDE })
	tocarEm("SERIE", m.onde, 0.95)

	local fator = junto and CFG.BONUS_SERIE or 1
	for _, quem in ipairs(alvosEm(m.onde, CFG.RAIO_MOLDE, 14)) do
		aplicarDano(quem, math.floor(CFG.DANO_MOLDE * fator + 0.5))
		local qr = raizDe(quem)
		if qr then
			empurrar(quem, (qr.Position - m.onde) + Vector3.new(0, 0.6, 0),
				CFG.EMPURRAO, 0.3)
		end
		tombar(quem, CFG.TOMBO)
	end
end

--''' + R + '''
-- M1 — a peça
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("PECA", despachar({

		CARGA = { sfx = { "PECA", 1.2 } },

		GOLPE = {
			sfx = { "PECA", 1.0 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("PECA", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(quem, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o molde
--
-- ELE NÃO DÁ DANO AO NASCER. É uma habilidade de PREPARAR: o boneco fica de
-- pé, pisca cada vez mais rápido, e estoura pelo prazo ou pelo `T`.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("MOLDE", despachar({

		CARGA = { sfx = { "MOLDE", 1.2 } },

		TRACA = {
			sfx = { "MOLDE", 1.0 },
			faz = function()
				local base = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				if #moldes >= CFG.TETO_MOLDES then
					estourarMolde(table.remove(moldes, 1), false)
				end

				local m = { id = novoId("molde"), onde = base }
				table.insert(moldes, m)

				vfx("MOLDE", { id = m.id, quadro = CFrame.new(base),
					duracao = CFG.VIDA_MOLDE })

				task.delay(CFG.VIDA_MOLDE, function()
					local ainda = tirarMolde(m.id)
					if ainda then estourarMolde(ainda, false) end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a série
--
-- Todos os moldes de pé estouram, um a cada `INTERVALO`, e valendo mais.
-- Todos no mesmo quadro seriam uma explosão só, mais brilhante.
--''' + R + '''

function extraT()
	if not rig then return end
	if #moldes == 0 then return end

	local levas = moldes
	moldes = {}

	ocupado = true
	rig:PlaySequence("SERIE", despachar({

		CARGA = { sfx = { "SERIE", 1.1 } },
		SEGURA = { sfx = { "MOLDE", 1.3 } },

		ERGUE = {
			sfx = { "SERIE", 0.85 },
			faz = function()
				local i = 1
				local function proxima()
					if i > #levas then return end
					if not (personagem and personagem.Parent) then return end
					estourarMolde(levas[i], true)
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
T("Genese",
  objeto="Genese_Server_V1", sufixo="CriacaoGenese",
  arquetipo="ASTRAL", alcance_mira=70,
  rotulo_m1="Faisca", rotulo_r="Materia", rotulo_t="Primeiro Instante",
  origem=["Handle autoral: esfera de materia crua entre dois aneis de latao",
          "FAISCA 2273224484 (eyeglow) · MATERIA 8578316223 (charge)",
          "PRIMEIRO 782353443 (energystrike) — do catalogo do Acervo"],
  cfg="""	ALCANCE       = 34,
	RECARGA       = 0.9,
	LARGURA       = 4,
	DANO          = 30,

	RECARGA_R     = 17,
	ATRASO        = 0.28,
	RAIO_MATERIA  = 26,
	NUCLEO        = 10,
	DANO_MATERIA  = 78,
	BORDA         = 30,
	EMPURRAO      = 105,
	TOMBO         = 1.5,

	RECARGA_T     = 26,
	RAIO_PRIMEIRO = 42,
	NUCLEO_PRI    = 16,
	DANO_PRIMEIRO = 130,
	BORDA_PRI     = 48,
	EMPURRAO_PRI  = 140,
	TOMBO_PRI     = 2.0,
	BLOCOS        = 12,
	VIDA_BLOCO    = 7,
	TETO_CRIADAS  = 14,""",
  corpo='''
--''' + R + '''
-- M1 — a faísca
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local alvo = mira

	ocupado = true
	rig:PlaySequence("FAISCA", despachar({

		CARGA = { sfx = { "FAISCA", 1.25 } },

		TRACA = {
			sfx = { "FAISCA", 1.05 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector
				if typeof(alvo) == "Vector3" then
					local delta = alvo - origem
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end

				vfx("FAISCA", { posicao = raiz.Position,
					destino = origem + direcao * CFG.ALCANCE,
					direcao = direcao, raio = CFG.ALCANCE })

				for _, quem in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.LARGURA, 10)) do
					aplicarDano(quem, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a matéria
--
-- Ela CONDENSA antes de abrir. Os `ATRASO` segundos entre o encolher e o
-- estouro são a habilidade inteira: matéria que estoura junto com a condensação
-- é só uma explosão com outro nome.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("MATERIA", despachar({

		CARGA = { sfx = { "MATERIA", 1.15 } },
		SEGURA = { sfx = { "FAISCA", 1.4 } },

		ERGUE = {
			sfx = { "MATERIA", 0.9 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()

				vfx("MATERIA", { posicao = centro, raio = CFG.RAIO_MATERIA })

				task.delay(CFG.ATRASO, function()
					if not (personagem and personagem.Parent) then return end
					tocarEm("MATERIA", centro, 0.85)

					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_MATERIA, 18)) do
						local qr = raizDe(quem)
						local d = qr and (qr.Position - centro).Magnitude
							or CFG.RAIO_MATERIA
						local dano = (d <= CFG.NUCLEO) and CFG.DANO_MATERIA
							or CFG.BORDA
						aplicarDano(quem, dano)
						if qr then
							empurrar(quem, (qr.Position - centro)
								+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.32)
						end
						tombar(quem, CFG.TOMBO)
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o primeiro instante
--
-- O maior estouro do conjunto, e ele DEIXA MATÉRIA: doze blocos nascem em
-- volta e ficam de pé pelo prazo. É a única habilidade daqui que muda o
-- terreno e dá dano cheio ao mesmo tempo — por isso a recarga é a segunda
-- mais longa.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("PRIMEIRO", despachar({

		CARGA = { sfx = { "PRIMEIRO", 1.0 } },
		SEGURA = { sfx = { "MATERIA", 1.3 } },

		ERGUE = {
			sfx = { "PRIMEIRO", 0.8 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("PRIMEIRO", { posicao = centro,
					raio = CFG.RAIO_PRIMEIRO })
				tocarEm("PRIMEIRO", centro, 0.75)

				for _, quem in ipairs(alvosEm(centro,
						CFG.RAIO_PRIMEIRO, 24)) do
					local qr = raizDe(quem)
					local d = qr and (qr.Position - centro).Magnitude
						or CFG.RAIO_PRIMEIRO
					local dano = (d <= CFG.NUCLEO_PRI) and CFG.DANO_PRIMEIRO
						or CFG.BORDA_PRI
					aplicarDano(quem, dano)
					if qr then
						empurrar(quem, (qr.Position - centro)
							+ Vector3.new(0, 0.7, 0), CFG.EMPURRAO_PRI, 0.34)
					end
					tombar(quem, CFG.TOMBO_PRI)
				end

				-- a matéria nova que fica de pé
				local i = 1
				while i <= CFG.BLOCOS do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_PRIMEIRO
						* (0.3 + (i / CFG.BLOCOS) * 0.6)
					local ponto = centro
						+ Vector3.new(math.cos(a) * alcance, 0,
							math.sin(a) * alcance)
					criar(CFrame.new(noChao(ponto) + Vector3.new(0, 3, 0)),
						Vector3.new(2.6, 6, 2.6), {
							Color = Color3.fromRGB(255, 208, 96),
							Material = Enum.Material.Neon,
						}, CFG.VIDA_BLOCO)
					i = i + 1
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Demiurgo",
  objeto="Demiurgo_Server_V1", sufixo="CriacaoDemiurgo",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="Molde do Mundo", rotulo_r="Continente", rotulo_t="Criacao",
  origem=["Handle autoral: mundo pequeno com oceano de vidro e compasso",
          "MOLDE_MUNDO 2836888600 (summoning) · CONTINENTE 165969964",
          "(Explosion) · CRIACAO 18872474050 (Supernova) — do catalogo"],
  cfg="""	ALCANCE       = 20,
	RECARGA       = 1.2,
	ABERTURA      = 70,
	COSSENO       = 0.34,
	DANO          = 34,
	EMPURRAO      = 60,

	RECARGA_R     = 20,
	PLACAS        = 5,
	RAIO_CONT     = 30,
	VIDA_PLACA    = 12,
	LEVANTA       = 82,
	DANO_CONT     = 30,
	TOMBO         = 1.2,

	RECARGA_T     = 44,
	RAIO_FIM      = 52,
	NUCLEO_FIM    = 20,
	DANO_FIM      = 175,
	BORDA_FIM     = 60,
	EMPURRAO_FIM  = 150,
	TOMBO_FIM     = 2.4,
	PLACAS_FIM    = 10,
	VIDA_FIM      = 14,
	RAIO_CENA     = 58,
	TETO_CRIADAS  = 18,""",
  ao_guardar="""	fecharCena()
""",
  corpo='''
--''' + R + '''
-- M1 — o molde do mundo
--
-- Um arco à frente, não uma reta: quem molda um mundo o faz em volta. O
-- `COSSENO` é o que separa cone de esfera — sem o produto escalar, o arco
-- acerta quem está atrás.
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("MOLDE_MUNDO", despachar({

		CARGA = { sfx = { "MOLDE_MUNDO", 1.15 } },

		TRACA = {
			sfx = { "MOLDE_MUNDO", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				vfx("MOLDE_MUNDO", { posicao = raiz.Position,
					direcao = direcao, raio = CFG.ALCANCE })

				for _, quem in ipairs(alvosNoCone(origem, direcao,
						CFG.ALCANCE, CFG.COSSENO, 12)) do
					aplicarDano(quem, CFG.DANO)
					local qr = raizDe(quem)
					if qr then
						empurrar(quem, (qr.Position - origem)
							+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO, 0.24)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o continente
--
-- Cinco placas de pedra sobem em volta. O dano é baixo: o que a habilidade
-- entrega é TERRENO — cobertura, altura, e um caminho que o outro não tinha.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("CONTINENTE", despachar({

		CARGA = { sfx = { "CONTINENTE", 1.1 } },
		SEGURA = { sfx = { "MOLDE_MUNDO", 1.3 } },

		ERGUE = {
			sfx = { "CONTINENTE", 0.85 },
			faz = function()
				local centro = noChao((typeof(onde) == "Vector3") and onde
					or frente())

				vfx("CONTINENTE", { posicao = centro, raio = CFG.RAIO_CONT })
				tocarEm("CONTINENTE", centro, 0.85)

				local i = 1
				while i <= CFG.PLACAS do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_CONT
						* (0.3 + (i / CFG.PLACAS) * 0.55)
					local ponto = noChao(centro
						+ Vector3.new(math.cos(a) * alcance, 0,
							math.sin(a) * alcance))
					local alto = 5 + math.abs(jitter(a)) * 6

					levantar(ponto, 7, CFG.LEVANTA, 6)
					for _, quem in ipairs(alvosEm(ponto, 7, 6)) do
						aplicarDano(quem, CFG.DANO_CONT)
						tombar(quem, CFG.TOMBO)
					end

					criar(CFrame.new(ponto + Vector3.new(0, alto * 0.5, 0)),
						Vector3.new(9, alto, 9), {
							Color = Color3.fromRGB(122, 96, 68),
							Material = Enum.Material.Slate,
						}, CFG.VIDA_PLACA)
					i = i + 1
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a Criação, COM CENA
--
-- A ultimate. Dez placas sobem, o mundo se forma acima, e tudo no raio leva.
--
-- O beat `CENA` abre a cutscene; `CARGA` e `ESTOURA` levam `cam = true`.
-- `fecharCena` roda no fim da sequência E no `desmontar`: câmera presa é o
-- pior do repertório.
--''' + R + '''

function extraT()
	if not rig or not raiz then return end
	local ponto = noChao(raiz.Position)

	ocupado = true
	rig:PlaySequence("CRIACAO", despachar({

		CENA = {
			sfx = { "CRIACAO", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "CONTINENTE", 1.35 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "CRIACAO", 0.75 },
			faz = function()
				vfx("CRIACAO", { posicao = ponto, raio = CFG.RAIO_FIM })
				tocarEm("CRIACAO", ponto, 0.7)

				-- levanta ANTES de as placas existirem: assim ninguém nasce
				-- dentro de uma delas
				levantar(ponto, CFG.RAIO_FIM, CFG.EMPURRAO_FIM * 0.5, 24)

				for _, quem in ipairs(alvosEm(ponto, CFG.RAIO_FIM, 26)) do
					local qr = raizDe(quem)
					local d = qr and (qr.Position - ponto).Magnitude
						or CFG.RAIO_FIM
					local dano = (d <= CFG.NUCLEO_FIM) and CFG.DANO_FIM
						or CFG.BORDA_FIM
					aplicarDano(quem, dano)
					tombar(quem, CFG.TOMBO_FIM)
				end

				local i = 1
				while i <= CFG.PLACAS_FIM do
					local a = anguloDe(i)
					local alcance = CFG.RAIO_FIM
						* (0.25 + (i / CFG.PLACAS_FIM) * 0.65)
					local lugar = noChao(ponto
						+ Vector3.new(math.cos(a) * alcance, 0,
							math.sin(a) * alcance))
					local alto = 6 + math.abs(jitter(a)) * 9
					criar(CFrame.new(lugar + Vector3.new(0, alto * 0.5, 0)),
						Vector3.new(8, alto, 8), {
							Color = Color3.fromRGB(122, 96, 68),
							Material = Enum.Material.Slate,
						}, CFG.VIDA_FIM)
					i = i + 1
				end
			end,
		},

		FIM = { cam = true, ponto = ponto },

	}), function()
		ocupado = false
		task.delay(0.6, fecharCena)
	end)
end
''')
