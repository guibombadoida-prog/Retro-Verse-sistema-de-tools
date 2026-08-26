"""
servers_titan.py — as 21 habilidades do conjunto TITAN (TV Man Titan).

Sete Tools, TRÊS habilidades cada: M1 no clique, `R` e `T` nas teclas. Lido por
`FERRAMENTAS/gerar_servers_titan.py`.

CONJUNTO AUTORAL

    Não há modelo de origem. Os 21 `SoundId` saem do catálogo do Acervo (reuso
    previsto pelo §12.16.2 — id de som não se inventa); a geometria é
    primitiva soldada; as 21 habilidades são escritas aqui.

O EIXO DAS SETE: SINAL

    O Titan é uma televisão que anda. Isso dá ao conjunto um eixo que o
    repositório ainda não tinha: a maioria das Tools daqui não bate mais forte,
    ela ATRAPALHA — chuvisco que cega, interferência que devolve o alvo mais
    devagar, marca que faz o próximo golpe doer mais.

    Três das sete têm efeito de estado, e as três DEVOLVEM o valor de antes:
    `afrouxar` guarda o `WalkSpeed` que o alvo tinha e devolve esse, nunca 16.
    Alvo que sai de uma Tool com a velocidade errada fica quebrado para o resto
    da partida.

QUATRO HABILIDADES TÊM PRAZO, E AS QUATRO DESLIGAM SOZINHAS

    Espelho, Torre, Voo e Reinício ficam de pé por alguns segundos. As quatro
    têm `id`, um prazo por `task.delay`, e um `parar*` chamado tanto pelo fim
    do prazo quanto pelo `desmontar` — guardar a Tool no meio não pode deixar
    efeito órfão na tela de ninguém.

NENHUMA MOVE GEOMETRIA POR QUADRO

    Onde há trajetória (o feixe, a investida, o voo), o CLIENTE desenha a
    60 Hz e o servidor percorre a mesma reta por aritmética, só para achar o
    impacto. Geometria movida pelo servidor replica a ~20 Hz sem interpolação.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Titan Estatica",
  objeto="TitanEstatica_Server_V1", sufixo="TitanEstatica",
  arquetipo="ARCANO", alcance_mira=40,
  rotulo_m1="Golpe de Tela", rotulo_r="Chuvisco", rotulo_t="Espelho",
  origem=["Handle: gabinete de TV com tela Neon e duas antenas",
          "CHUVISCO 9114524356 (hum) · ESTATICA 2674547670 (Electric",
          "Explosion) · ESPELHO 9125673453 (Beep) — os tres do catalogo"],
  cfg="""	ALCANCE       = 12,
	RECARGA       = 0.9,
	RAIO          = 8,
	DANO          = 22,
	EMPURRAO      = 40,

	RECARGA_R     = 13,
	RAIO_CHUVISCO = 15,
	DANO_CHUVISCO = 9,
	TIQUES        = 5,
	INTERVALO     = 0.45,
	LENTIDAO      = 0.55,
	TEMPO_CEGO    = 2.6,

	RECARGA_T     = 24,
	TEMPO_ESPELHO = 6,
	RAIO_ESPELHO  = 6,
	FATIA         = 0.5,
	TETO_DEVOLVE  = 45,""",
  estado="""local espelhoId, espelhoAte = nil, 0
local espelhoConexao = nil""",
  ao_guardar="""	pararEspelho()
""",
  corpo='''
--''' + R + '''
-- M1 — a batida de gabinete
--
-- A tela pisca no contato. Curto e sem estado: é o golpe que sustenta a Tool
-- entre uma Extra e outra.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local alvoMira = mira

	ocupado = true
	rig:PlaySequence("GOLPE_TELA", despachar({

		CARGA = { sfx = { "ESTATICA", 1.15 } },

		GOLPE = {
			sfx = { "ESTATICA", 0.95 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.55)

				vfx("TELA_IMPACTO", { posicao = centro, direcao = direcao })

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(alvo, CFG.DANO)
					empurrar(alvo, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO, 0.22)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
	return alvoMira
end

--''' + R + '''
-- R — o chuvisco
--
-- Volume de estática no ponto mirado. Ele NÃO desenha na tela de ninguém:
-- `ScreenGui` é proibido dentro de Tool, e o motivo é que uma Tool que suma no
-- meio deixaria a tela do jogador coberta e sem saída. O chuvisco é volume no
-- mundo 3D, e quem entrar nele leva dano por tique e sai mais devagar.
--
-- `afrouxar` guarda o `WalkSpeed` de ANTES e devolve esse. Devolver 16 fixo
-- quebraria qualquer alvo que tivesse velocidade própria.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("CHUVISCO", despachar({

		CARGA = { sfx = { "CHUVISCO", 1.1 } },

		SEGURA = { sfx = { "CHUVISCO", 0.85 } },

		GOLPE = {
			sfx = { "ESTATICA", 1.0 },
			faz = function()
				vfx("CHUVISCO", { posicao = onde, raio = CFG.RAIO_CHUVISCO })
				tocarEm("CHUVISCO", onde, 0.8)

				-- cinco tiques por `task.delay` recursivo: quem entrar no meio
				-- do prazo também leva, e quem sair para de levar
				local tique = 0
				local function bater()
					tique = tique + 1
					if tique > CFG.TIQUES then return end
					if not (personagem and personagem.Parent) then return end

					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_CHUVISCO, 14)) do
						aplicarDano(alvo, CFG.DANO_CHUVISCO)
						afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_CEGO)
					end
					task.delay(CFG.INTERVALO, bater)
				end
				bater()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o espelho de sinal
--
-- Por `TEMPO_ESPELHO` segundos, parte do dano que chegar volta para quem deu.
--
-- COMO ELE SABE QUE LEVOU: `HealthChanged` do PRÓPRIO Humanoid, comparando
-- com o valor anterior. Não há como perguntar ao Roblox quem bateu — então o
-- alvo da devolução é quem estiver mais perto dentro de `RAIO_ESPELHO`. É uma
-- aproximação, e ela é honesta: espelho de raio curto só devolve para quem
-- estava perto o bastante para ter batido.
--
-- O TETO EXISTE POR UM MOTIVO. Sem `TETO_DEVOLVE`, dois jogadores com o
-- espelho ligado um contra o outro entrariam em laço de devolução e se
-- matariam com um único golpe de qualquer um dos dois.
--''' + R + '''

function pararEspelho()
	if espelhoConexao then
		espelhoConexao:Disconnect()
		espelhoConexao = nil
	end
	if espelhoId then
		vfx("PARAR", { id = espelhoId })
		espelhoId = nil
	end
	espelhoAte = 0
end

function extraT()
	if not rig or not raiz then return end

	ocupado = true
	rig:PlaySequence("ESPELHO", despachar({

		CARGA = { sfx = { "ESPELHO", 1.2 } },

		SEGURA = { sfx = { "CHUVISCO", 1.3 } },

		GOLPE = {
			sfx = { "ESPELHO", 0.9 },
			faz = function()
				if not (raiz and humanoide) then return end
				pararEspelho()

				espelhoId = novoId("espelho")
				espelhoAte = os.clock() + CFG.TEMPO_ESPELHO
				vfx("ESPELHO", {
					id = espelhoId, posicao = raiz.Position,
					raio = CFG.RAIO_ESPELHO, duracao = CFG.TEMPO_ESPELHO,
				})

				local antes = humanoide.Health
				espelhoConexao = guardar(humanoide.HealthChanged:Connect(
					function(agora)
						local perdeu = antes - agora
						antes = agora
						if perdeu <= 0 then return end
						if os.clock() > espelhoAte then return end
						if not raiz then return end

						local devolve = math.min(perdeu * CFG.FATIA,
							CFG.TETO_DEVOLVE)

						local perto, dist = nil, math.huge
						for _, alvo in ipairs(alvosEm(raiz.Position,
								CFG.RAIO_ESPELHO, 8)) do
							local alvoRaiz = raizDe(alvo)
							if alvoRaiz then
								local d = (alvoRaiz.Position - raiz.Position).Magnitude
								if d < dist then perto, dist = alvo, d end
							end
						end
						if not perto then return end

						local pertoRaiz = raizDe(perto)
						aplicarDano(perto, devolve)
						vfx("ESPELHO_DEVOLVE", {
							posicao = pertoRaiz and pertoRaiz.Position
								or raiz.Position,
						})
						tocar("ESPELHO", 1.1)
					end))

				task.delay(CFG.TEMPO_ESPELHO, pararEspelho)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Titan Raio Catodico",
  objeto="TitanRaioCatodico_Server_V1", sufixo="TitanCatodico",
  arquetipo="ASTRAL", alcance_mira=90,
  rotulo_m1="Faisca", rotulo_r="Feixe", rotulo_t="Leque",
  origem=["Handle: tubo de imagem cromado com lente Neon",
          "FAISCA 2273224484 (eyeglow) · FEIXE 782353443 (energystrike)",
          "LEQUE 80214468 (Lightning1) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 10,
	RECARGA       = 0.8,
	RAIO_FAISCA   = 9,
	LARGURA_FAISCA = 3,
	DANO          = 18,

	RECARGA_R     = 11,
	ALCANCE_FEIXE = 80,
	LARGURA_FEIXE = 4.5,
	DANO_FEIXE    = 48,
	EMPURRAO_FEIXE = 30,

	RECARGA_T     = 22,
	ALCANCE_LEQUE = 48,
	RAIOS         = 5,
	ABERTURA      = 42,
	LARGURA_LEQUE = 4,
	DANO_LEQUE    = 26,""",
  corpo='''
--''' + R + '''
-- M1 — a faísca do tubo
--
-- Feixe curto na direção do olhar. Quem está NO CAMINHO leva, não quem está
-- perto do fim: é `alvosNaReta`, e é a diferença entre um raio e uma bola.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("FAISCA", despachar({

		CARGA = { sfx = { "FAISCA", 1.2 } },

		GOLPE = {
			sfx = { "FAISCA", 1.0 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				vfx("FAISCA", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.RAIO_FAISCA })

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.RAIO_FAISCA, CFG.LARGURA_FAISCA, 6)) do
					aplicarDano(alvo, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o feixe catódico
--
-- Longo e reto, parado pela primeira parede. O raycast não é enfeite: sem ele
-- o feixe atravessa o mapa e acerta quem está do outro lado de uma base
-- fechada, sem nenhum aviso visual de que isso podia acontecer.
--''' + R + '''

function extraR(mira)
	if not rig then return end
	local alvoMira = mira

	ocupado = true
	rig:PlaySequence("FEIXE", despachar({

		CARGA = { sfx = { "FEIXE", 1.15 } },

		SEGURA = { sfx = { "FAISCA", 1.4 } },

		GOLPE = {
			sfx = { "FEIXE", 0.9 },
			faz = function()
				if not (raiz and personagem) then return end
				local origem = raiz.Position + Vector3.new(0, 2.4, 0)
				local delta = alvoMira - origem
				if delta.Magnitude < 1 then
					delta = raiz.CFrame.LookVector * CFG.ALCANCE_FEIXE
				end
				local direcao = delta.Unit
				local alcance = math.min(delta.Magnitude, CFG.ALCANCE_FEIXE)

				local filtro = RaycastParams.new()
				filtro.FilterType = Enum.RaycastFilterType.Exclude
				filtro.FilterDescendantsInstances = { personagem }
				local batida = workspace:Raycast(origem, direcao * alcance, filtro)
				if batida then
					alcance = (batida.Position - origem).Magnitude
				end
				local destino = origem + direcao * alcance

				vfx("FEIXE", { posicao = raiz.Position, destino = destino,
					direcao = direcao })
				tocarEm("FEIXE", destino, 0.95)

				for _, alvo in ipairs(alvosNaReta(origem, direcao, alcance,
						CFG.LARGURA_FEIXE, 12)) do
					aplicarDano(alvo, CFG.DANO_FEIXE)
					empurrar(alvo, direcao + Vector3.new(0, 0.25, 0),
						CFG.EMPURRAO_FEIXE, 0.24)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o leque
--
-- Cinco feixes abrindo em `ABERTURA` graus para cada lado. As direções saem de
-- uma divisão exata do arco, nunca de sorteio: com todos os clientes
-- desenhando, um sorteio faria cada um ver um leque diferente do que o
-- servidor calculou para o dano.
--''' + R + '''

function extraT(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("LEQUE", despachar({

		CARGA = { sfx = { "LEQUE", 1.1 } },

		SEGURA = { sfx = { "FAISCA", 1.5 } },

		GOLPE = {
			sfx = { "LEQUE", 0.85 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2.4, 0)
				local base = CFrame.lookAt(origem,
					origem + raiz.CFrame.LookVector)

				vfx("LEQUE", { posicao = raiz.Position,
					direcao = raiz.CFrame.LookVector,
					raio = CFG.ALCANCE_LEQUE, quantidade = CFG.RAIOS })

				local vistos = {}
				local i = 0
				while i < CFG.RAIOS do
					local passo = CFG.RAIOS > 1 and (i / (CFG.RAIOS - 1)) or 0.5
					local abertura = math.rad(-CFG.ABERTURA
						+ (CFG.ABERTURA * 2) * passo)
					local direcao = (base * CFrame.Angles(0, abertura, 0)).LookVector

					for _, alvo in ipairs(alvosNaReta(origem, direcao,
							CFG.ALCANCE_LEQUE, CFG.LARGURA_LEQUE, 8)) do
						-- um alvo no cruzamento de dois raios leva UMA vez
						if not vistos[alvo] then
							vistos[alvo] = true
							aplicarDano(alvo, CFG.DANO_LEQUE)
						end
					end
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
T("Titan Antena",
  objeto="TitanAntena_Server_V1", sufixo="TitanAntena",
  arquetipo="ARCANO", alcance_mira=50,
  rotulo_m1="Chicote", rotulo_r="Torre", rotulo_t="Interferencia",
  origem=["Handle: haste cromada de 5.4 studs com prato e ponta Neon",
          "CHICOTE 145486992 (sfx_swooshing) · SINAL 1310929645 (Locked On)",
          "INTERFERE 8578316223 (charge) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 16,
	RECARGA       = 1.0,
	RAIO          = 11,
	DANO          = 17,

	RECARGA_R     = 15,
	RAIO_TORRE    = 34,
	TEMPO_TORRE   = 8,
	PULSO_TORRE   = 1.1,
	DANO_PULSO    = 7,
	TEMPO_MARCA   = 6,
	BONUS_MARCA   = 1.4,

	RECARGA_T     = 20,
	RAIO_INTERF   = 26,
	DANO_INTERF   = 20,
	LENTIDAO      = 0.45,
	TEMPO_INTERF  = 4,""",
  estado="""local torreId, torreAte = nil, 0
local marcados = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	pararTorre()
""",
  corpo='''
--''' + R + '''
-- A MARCA
--
-- Quem está marcado leva `BONUS_MARCA` vezes o dano de QUALQUER habilidade
-- desta Tool. A tabela é de chave FRACA (`__mode = "k"`): se o Humanoid morrer
-- e sair do jogo, a entrada some sozinha. Tabela forte aqui seria vazamento
-- que cresce a partida inteira.
--''' + R + '''

local function marcar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	marcados[alvoHum] = os.clock() + (tempo or CFG.TEMPO_MARCA)
	local alvoRaiz = raizDe(alvoHum)
	if alvoRaiz then
		vfx("MARCA", { peca = alvoRaiz, duracao = tempo or CFG.TEMPO_MARCA })
	end
end

local function estaMarcado(alvoHum)
	local ate = marcados[alvoHum]
	if not ate then return false end
	if os.clock() > ate then
		marcados[alvoHum] = nil
		return false
	end
	return true
end

--- O dano desta Tool passa TODO por aqui: é o único lugar que sabe do bônus.
local function danoNoAlvo(alvoHum, bruto)
	local final = bruto
	if estaMarcado(alvoHum) then
		final = bruto * CFG.BONUS_MARCA
	end
	return aplicarDano(alvoHum, math.floor(final + 0.5))
end

--''' + R + '''
-- M1 — o chicote de antena
--
-- Alcance longo para um golpe corpo a corpo: a haste tem 5.4 studs, e o golpe
-- respeita isso.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("CHICOTE", despachar({

		CARGA = { sfx = { "CHICOTE", 1.2 } },

		GOLPE = {
			sfx = { "CHICOTE", 0.95 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("CHICOTE", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.RAIO })

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					danoNoAlvo(alvo, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a torre de sinal
--
-- Um mastro cravado no chão que, a cada `PULSO_TORRE`, marca e sangra quem
-- estiver no raio. Ela NÃO segue o jogador: quem plantou pode sair de perto, e
-- a torre continua trabalhando onde foi plantada. É o que a torna decisão de
-- posição em vez de aura.
--''' + R + '''

function pararTorre()
	if torreId then
		vfx("PARAR", { id = torreId })
		torreId = nil
	end
	torreAte = 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("TORRE", despachar({

		CARGA = { sfx = { "SINAL", 1.15 } },

		SEGURA = { sfx = { "INTERFERE", 1.2 } },

		GOLPE = {
			sfx = { "SINAL", 0.9 },
			faz = function()
				pararTorre()
				torreId = novoId("torre")
				torreAte = os.clock() + CFG.TEMPO_TORRE

				vfx("TORRE", { id = torreId, posicao = onde,
					raio = CFG.RAIO_TORRE, duracao = CFG.TEMPO_TORRE })
				tocarEm("SINAL", onde, 0.85)

				local function pulsar()
					if not torreId or os.clock() > torreAte then
						pararTorre()
						return
					end
					if not (personagem and personagem.Parent) then
						pararTorre()
						return
					end
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_TORRE, 16)) do
						danoNoAlvo(alvo, CFG.DANO_PULSO)
						marcar(alvo, CFG.TEMPO_MARCA)
					end
					task.delay(CFG.PULSO_TORRE, pulsar)
				end
				pulsar()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — a interferência
--
-- Área grande, dano médio, e todo mundo sai mais devagar e marcado. É a
-- habilidade de ABRIR briga: ela não fecha nada sozinha.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("INTERFERENCIA", despachar({

		CARGA = { sfx = { "INTERFERE", 1.1 } },

		SEGURA = { sfx = { "INTERFERE", 0.8 } },

		GOLPE = {
			sfx = { "SINAL", 1.25 },
			faz = function()
				vfx("INTERFERENCIA", { posicao = onde, raio = CFG.RAIO_INTERF })
				tocarEm("INTERFERE", onde, 0.9)

				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_INTERF, 18)) do
					danoNoAlvo(alvo, CFG.DANO_INTERF)
					afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_INTERF)
					marcar(alvo, CFG.TEMPO_MARCA)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Titan Alto Falante",
  objeto="TitanAltoFalante_Server_V1", sufixo="TitanFalante",
  arquetipo="EXPLOSIVO", alcance_mira=40,
  rotulo_m1="Batida", rotulo_r="Cone", rotulo_t="Grito",
  origem=["Handle: caixa acustica com cone de tecido e cupula cromada",
          "BATIDA 145486953 (sfx_hit) · CONE 9125402735 (DuperBoom)",
          "GRITO 7127123554 (Roar2) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 11,
	RECARGA       = 0.9,
	RAIO          = 8,
	DANO          = 20,
	EMPURRAO      = 44,

	RECARGA_R     = 12,
	ALCANCE_CONE  = 34,
	COSSENO_CONE  = 0.62,
	DANO_CONE     = 40,
	EMPURRAO_CONE = 110,
	TOMBO_CONE    = 0.9,

	RECARGA_T     = 23,
	RAIO_GRITO    = 30,
	NUCLEO_GRITO  = 12,
	DANO_GRITO    = 55,
	BORDA_GRITO   = 22,
	EMPURRAO_GRITO = 95,
	TOMBO_GRITO   = 1.6,""",
  corpo='''
--''' + R + '''
-- M1 — a batida sônica
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("BATIDA", despachar({

		CARGA = { sfx = { "BATIDA", 1.15 } },

		GOLPE = {
			sfx = { "BATIDA", 0.95 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.55)

				vfx("BATIDA", { posicao = centro, direcao = direcao })

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(alvo, CFG.DANO)
					empurrar(alvo, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO, 0.22)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o cone de choque
--
-- O `COSSENO_CONE` é o que separa cone de esfera. Sem o produto escalar, um
-- "cone de choque" acerta quem está ATRÁS de quem gritou — e nada na tela
-- explica por quê.
--''' + R + '''

function extraR(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("CONE", despachar({

		CARGA = { sfx = { "CONE", 1.1 } },

		SEGURA = { sfx = { "BATIDA", 1.4 } },

		GOLPE = {
			sfx = { "CONE", 0.85 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				vfx("CONE", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE_CONE })

				for _, alvo in ipairs(alvosNoCone(origem, direcao,
						CFG.ALCANCE_CONE, CFG.COSSENO_CONE, 14)) do
					aplicarDano(alvo, CFG.DANO_CONE)
					empurrar(alvo, direcao + Vector3.new(0, 0.4, 0),
						CFG.EMPURRAO_CONE, 0.34)
					tombar(alvo, CFG.TOMBO_CONE)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o grito
--
-- Radial, com NÚCLEO e BORDA. Raio de 30 com dano chapado mataria quem está na
-- borda sem nenhum aviso visual de que estava no alcance.
--''' + R + '''

function extraT(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("GRITO", despachar({

		CARGA = { sfx = { "GRITO", 1.0 } },

		SEGURA = { sfx = { "CONE", 1.3 } },

		GOLPE = {
			sfx = { "GRITO", 0.75 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("GRITO", { posicao = centro, raio = CFG.RAIO_GRITO })
				tocarEm("GRITO", centro, 0.8)

				golpearArea(centro, CFG.RAIO_GRITO, CFG.NUCLEO_GRITO,
					CFG.DANO_GRITO, CFG.BORDA_GRITO,
					CFG.EMPURRAO_GRITO, CFG.TOMBO_GRITO, 20)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Titan Lamina",
  objeto="TitanLamina_Server_V1", sufixo="TitanLamina",
  arquetipo="MELEE", alcance_mira=45,
  rotulo_m1="Corte", rotulo_r="Estocada", rotulo_t="Descendente",
  origem=["Handle: lamina cromada de 6 studs com fio Neon e guarda",
          "CORTE 4958430453 (Slash) · ESTOCADA 8145344127 (SwordLunge)",
          "DESCE 5287092000 (SwordHit) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 13,
	RECARGA       = 0.7,
	RAIO          = 8,
	DANO          = 24,
	DANO_TERCEIRO = 38,
	EMPURRAO      = 48,
	COMBO_JANELA  = 1.5,

	RECARGA_R     = 10,
	AVANCO        = 62,
	TEMPO_AVANCO  = 0.24,
	ALCANCE_EST   = 22,
	LARGURA_EST   = 5,
	DANO_EST      = 46,

	RECARGA_T     = 21,
	COMPRIMENTO   = 40,
	LARGURA_FENDA = 7,
	DANO_FENDA    = 62,
	EMPURRAO_FENDA = 70,
	TOMBO_FENDA   = 1.3,""",
  estado="""local passoCombo, ultimoGolpe = 0, 0""",
  corpo='''
--''' + R + '''
-- M1 — o corte em três tempos
--
-- Combo de três na MESMA entrada. Pela REGRA_DISTRIBUICAO isso é UMA
-- habilidade, não três: "combo de três golpes na mesma entrada é uma".
--
-- A JANELA EXISTE POR UM MOTIVO. Sem ela o jogador guarda o terceiro golpe na
-- mochila e volta sempre com o mais forte, o que transforma o combo num M1 de
-- dano alto com passos extras de enfeite.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	if os.clock() - ultimoGolpe > CFG.COMBO_JANELA then
		passoCombo = 0
	end
	ultimoGolpe = os.clock()
	passoCombo = passoCombo % 3 + 1

	local terceiro = passoCombo == 3
	local dano = terceiro and CFG.DANO_TERCEIRO or CFG.DANO

	ocupado = true
	rig:PlaySequence("CORTE", despachar({

		CARGA = { sfx = { "CORTE", terceiro and 0.85 or 1.1 } },

		GOLPE = {
			sfx = { terceiro and "DESCE" or "CORTE", 0.9 + passoCombo * 0.06 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("CORTE", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.RAIO, giro = passoCombo * 1.05 })

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 8)) do
					aplicarDano(alvo, dano)
					if terceiro then
						empurrar(alvo, direcao + Vector3.new(0, 0.35, 0),
							CFG.EMPURRAO, 0.24)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a estocada propulsada
--
-- Avança o PRÓPRIO personagem por `BodyVelocity` com prazo, nunca por escrita
-- de `CFrame` por quadro: escrever CFrame no servidor briga com a autoridade
-- de física do dono e produz o tranco que o jogador lê como travada.
--''' + R + '''

function extraR(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ESTOCADA", despachar({

		CARGA = { sfx = { "ESTOCADA", 1.2 } },

		GOLPE = {
			sfx = { "ESTOCADA", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				avancar(direcao, CFG.AVANCO, CFG.TEMPO_AVANCO)

				vfx("ESTOCADA", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE_EST })

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE_EST, CFG.LARGURA_EST, 8)) do
					aplicarDano(alvo, CFG.DANO_EST)
					empurrar(alvo, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO, 0.26)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o corte descendente
--
-- Abre uma fenda no chão, à frente. O dano cai ao longo do comprimento — quem
-- está na ponta da fenda leva menos que quem está no pé de quem cortou.
--''' + R + '''

function extraT(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("DESCENDENTE", despachar({

		CARGA = { sfx = { "DESCE", 1.0 } },

		SEGURA = { sfx = { "CORTE", 1.35 } },

		GOLPE = {
			sfx = { "DESCE", 0.8 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position
				local direcao = raiz.CFrame.LookVector

				vfx("FENDA", { posicao = origem, direcao = direcao,
					raio = CFG.COMPRIMENTO })
				tocarEm("DESCE", origem + direcao * 6, 0.85)

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.COMPRIMENTO, CFG.LARGURA_FENDA, 16)) do
					local alvoRaiz = raizDe(alvo)
					local fracao = 0
					if alvoRaiz then
						fracao = math.clamp(
							(alvoRaiz.Position - origem).Magnitude
								/ CFG.COMPRIMENTO, 0, 1)
					end
					-- cheio no pé, metade na ponta
					aplicarDano(alvo, math.floor(
						CFG.DANO_FENDA * (1 - fracao * 0.5) + 0.5))
					empurrar(alvo, Vector3.new(0, 1, 0),
						CFG.EMPURRAO_FENDA * (1 - fracao * 0.4), 0.3)
					tombar(alvo, CFG.TOMBO_FENDA)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Titan Propulsor",
  objeto="TitanPropulsor_Server_V1", sufixo="TitanPropulsor",
  arquetipo="MELEE", alcance_mira=45,
  rotulo_m1="Investida", rotulo_r="Voo", rotulo_t="Desvio",
  origem=["Handle: turbina cromada com bocal e chama Neon",
          "INVESTIDA 9126231485 (whoosh) · VOO 8186570431 (Fly)",
          "DESVIO 7449437048 (Launch1) — os tres do catalogo do Acervo"],
  cfg="""	ALCANCE       = 26,
	RECARGA       = 0.8,
	AVANCO        = 78,
	TEMPO_AVANCO  = 0.3,
	RAIO_INVEST   = 7,
	DANO          = 26,
	EMPURRAO      = 55,

	RECARGA_R     = 12,
	SUBIDA        = 68,
	TEMPO_SUBIDA  = 0.4,
	TEMPO_VOO     = 1.3,
	RAIO_POUSO    = 20,
	NUCLEO_POUSO  = 8,
	DANO_POUSO    = 52,
	BORDA_POUSO   = 20,
	EMPURRAO_POUSO = 85,
	TOMBO_POUSO   = 1.2,

	RECARGA_T     = 9,
	LATERAL       = 66,
	TEMPO_LATERAL = 0.22,""",
  estado="""local vooId = nil""",
  ao_guardar="""	pararVoo()
""",
  corpo='''
--''' + R + '''
-- M1 — a investida
--
-- Avança e atropela quem estiver no caminho. O alcance do dano acompanha o
-- avanço: o servidor percorre a MESMA reta por aritmética, e por isso o que
-- ele acerta é o que o cliente desenhou.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("INVESTIDA", despachar({

		CARGA = { sfx = { "INVESTIDA", 1.2 } },

		GOLPE = {
			sfx = { "INVESTIDA", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 1.6, 0)
				local direcao = raiz.CFrame.LookVector

				avancar(direcao, CFG.AVANCO, CFG.TEMPO_AVANCO)
				vfx("INVESTIDA", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE })

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.RAIO_INVEST, 10)) do
					aplicarDano(alvo, CFG.DANO)
					empurrar(alvo, direcao + Vector3.new(0, 0.45, 0),
						CFG.EMPURRAO, 0.26)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o voo curto, com pouso
--
-- Sobe, fica no ar `TEMPO_VOO`, e desce batendo. A subida é `BodyVelocity` com
-- prazo — nunca `Anchored`, que travaria o personagem inteiro e deixaria o
-- jogador preso no ar se a Tool sumisse no meio.
--
-- O POUSO ACONTECE MESMO SE A TOOL FOR GUARDADA. Ele é `task.delay`, e o dano
-- só é aplicado se o personagem ainda existir: guardar a Tool no meio do voo
-- não pode deixar o jogador flutuando nem cobrar a recarga sem entregar nada.
--''' + R + '''

function pararVoo()
	if vooId then
		vfx("PARAR", { id = vooId })
		vooId = nil
	end
end

function extraR(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("VOO", despachar({

		CARGA = { sfx = { "VOO", 1.15 } },

		SEGURA = { sfx = { "INVESTIDA", 1.3 } },

		GOLPE = {
			sfx = { "VOO", 0.9 },
			faz = function()
				if not raiz then return end
				pararVoo()

				avancar(Vector3.new(0, 1, 0), CFG.SUBIDA, CFG.TEMPO_SUBIDA)

				vooId = novoId("voo")
				vfx("VOO", { id = vooId, posicao = raiz.Position,
					peca = raiz, duracao = CFG.TEMPO_VOO })

				task.delay(CFG.TEMPO_VOO, function()
					pararVoo()
					if not (personagem and personagem.Parent and raiz) then
						return
					end
					if humanoide and humanoide.Health <= 0 then return end

					local centro = raiz.Position
					vfx("POUSO", { posicao = centro,
						direcao = raiz.CFrame.LookVector,
						raio = CFG.RAIO_POUSO })
					tocarEm("VOO", centro, 0.75)

					golpearArea(centro, CFG.RAIO_POUSO, CFG.NUCLEO_POUSO,
						CFG.DANO_POUSO, CFG.BORDA_POUSO,
						CFG.EMPURRAO_POUSO, CFG.TOMBO_POUSO, 16)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o desvio lateral
--
-- Recarga curta de propósito: é mobilidade, não dano. Ela não acerta ninguém, e
-- por isso pode voltar rápido sem virar a habilidade principal da Tool.
--
-- O LADO SAI DA MIRA. Se o jogador está mirando à esquerda, ele desvia para a
-- esquerda; sem mira, desvia para a direita. Um desvio de lado fixo é inútil
-- metade das vezes.
--''' + R + '''

function extraT(mira)
	if not rig or not raiz then return end
	local alvoMira = mira

	ocupado = true
	rig:PlaySequence("DESVIO", despachar({

		CARGA = { sfx = { "DESVIO", 1.25 } },

		GOLPE = {
			sfx = { "DESVIO", 1.0 },
			faz = function()
				if not raiz then return end
				local lado = raiz.CFrame.RightVector
				if typeof(alvoMira) == "Vector3" then
					local delta = alvoMira - raiz.Position
					if delta.Magnitude > 1 and delta.Unit:Dot(lado) < 0 then
						lado = -lado
					end
				end
				avancar(lado + Vector3.new(0, 0.22, 0),
					CFG.LATERAL, CFG.TEMPO_LATERAL)
				vfx("DESVIO", { posicao = raiz.Position, direcao = lado })
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Titan Sobrecarga",
  objeto="TitanSobrecarga_Server_V1", sufixo="TitanSobrecarga",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="Descarga", rotulo_r="Sobrecarga", rotulo_t="Reinicio",
  origem=["Handle: nucleo Neon vermelho com aro cromado de contencao",
          "DESCARGA 6523812578 (Power Up) · SOBRECARGA 814635481 (Big",
          "Explosion) · REINICIO 18872474050 (Supernova) — do catalogo"],
  cfg="""	ALCANCE       = 14,
	RECARGA       = 1.2,
	LARGURA_DESC  = 4,
	DANO          = 28,

	RECARGA_R     = 18,
	RAIO_SOBRE    = 32,
	NUCLEO_SOBRE  = 13,
	DANO_SOBRE    = 78,
	BORDA_SOBRE   = 30,
	EMPURRAO_SOBRE = 100,
	TOMBO_SOBRE   = 1.4,

	RECARGA_T     = 38,
	RAIO_REINICIO = 46,
	NUCLEO_REINI  = 18,
	DANO_REINICIO = 150,
	BORDA_REINICIO = 55,
	EMPURRAO_REINICIO = 140,
	TOMBO_REINICIO = 2.2,
	LENTIDAO      = 0.4,
	TEMPO_LENTO   = 4,
	ATRASO_ONDA   = 0.35,
	ONDAS         = 3,""",
  corpo='''
--''' + R + '''
-- M1 — a descarga
--
-- Curta e reta. É o M1 mais caro do conjunto em recarga, e o mais forte: a
-- Tool inteira é sobre acumular e soltar.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("DESCARGA", despachar({

		CARGA = { sfx = { "DESCARGA", 1.15 } },

		GOLPE = {
			sfx = { "DESCARGA", 0.95 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2, 0)
				local direcao = raiz.CFrame.LookVector

				vfx("DESCARGA", { posicao = raiz.Position, direcao = direcao,
					raio = CFG.ALCANCE })

				for _, alvo in ipairs(alvosNaReta(origem, direcao,
						CFG.ALCANCE, CFG.LARGURA_DESC, 8)) do
					aplicarDano(alvo, CFG.DANO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a sobrecarga do campo
--
-- Radial, com núcleo e borda, centrada em quem usou.
--''' + R + '''

function extraR(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("SOBRECARGA", despachar({

		CARGA = { sfx = { "SOBRECARGA", 1.1 } },

		SEGURA = { sfx = { "DESCARGA", 1.4 } },

		GOLPE = {
			sfx = { "SOBRECARGA", 0.85 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("SOBRECARGA", { posicao = centro, raio = CFG.RAIO_SOBRE })
				tocarEm("SOBRECARGA", centro, 0.9)

				golpearArea(centro, CFG.RAIO_SOBRE, CFG.NUCLEO_SOBRE,
					CFG.DANO_SOBRE, CFG.BORDA_SOBRE,
					CFG.EMPURRAO_SOBRE, CFG.TOMBO_SOBRE, 20)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o reinício
--
-- A grande do conjunto. TRÊS ondas, com `ATRASO_ONDA` entre elas: a primeira
-- derruba, e as duas seguintes pegam quem ficou.
--
-- SÓ A PRIMEIRA ONDA DÁ DANO CHEIO. As outras duas dão a borda. Três ondas de
-- dano cheio num raio de 46 seria matar todo mundo do servidor que estivesse
-- por perto, e nada na tela avisaria que dava para sair.
--
-- Ela é lenta de propósito: 1.45 s de animação com varredura é o aviso que o
-- adversário tem de que ela está vindo.
--''' + R + '''

function extraT(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("REINICIO", despachar({

		CARGA = { sfx = { "REINICIO", 1.0 } },

		SEGURA = { sfx = { "SOBRECARGA", 1.3 } },

		GOLPE = {
			sfx = { "REINICIO", 0.75 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("REINICIO", { posicao = centro, raio = CFG.RAIO_REINICIO })
				tocarEm("REINICIO", centro, 0.8)

				local onda = 0
				local function bater()
					onda = onda + 1
					if onda > CFG.ONDAS then return end
					if not (personagem and personagem.Parent) then return end

					local primeira = onda == 1
					local dano = primeira and CFG.DANO_REINICIO
						or CFG.BORDA_REINICIO

					golpearArea(centro, CFG.RAIO_REINICIO, CFG.NUCLEO_REINI,
						dano, CFG.BORDA_REINICIO,
						CFG.EMPURRAO_REINICIO * (primeira and 1 or 0.5),
						CFG.TOMBO_REINICIO, 24)

					if primeira then
						for _, alvo in ipairs(alvosEm(centro,
								CFG.RAIO_REINICIO, 24)) do
							afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
						end
					else
						vfx("SOBRECARGA", { posicao = centro,
							raio = CFG.RAIO_REINICIO * 0.7 })
					end

					task.delay(CFG.ATRASO_ONDA, bater)
				end
				bater()
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')
