"""
servers_jupiter.py — as 21 habilidades do conjunto JUPITER.

Sete Tools, TRÊS habilidades cada: M1 no clique, `R` e `T` nas teclas. Lido por
`FERRAMENTAS/gerar_servers_jupiter.py`.

OS ASSETS SÃO DA ORIGEM; A LÓGICA NÃO É

    Do `Jupiter_Great_Pressure_Sword` vieram 19 `SoundId`, a malha do planeta
    com a textura dela, e seis texturas de emissor — todos catalogados na ficha
    do Acervo. Nenhum id foi inventado: id chutado é som mudo e partícula
    invisível que nenhum verificador estático pega.

    A lógica dos 31 scripts da origem ficou de fora, e o
    `LOGICA/HABILIDADES.md` diz por quê: `Health = 0`, raio de 1500 studs,
    `TagHumanoid` reimplementado 12 vezes, 69 `:Destroy()`, 37 `wait()`, 16
    `math.random`, e 11 `require` de id numérico.

O EIXO DAS SETE É PRESSÃO, E PRESSÃO NÃO É `workspace.Gravity`

    Nenhuma das 21 toca na gravidade global. Ela é estado do place inteiro:
    mexer nela por Tool quebra todo mundo que estiver no servidor, e deixa o
    place torto se a Tool sumir no meio. Quem sobe, cai ou é puxado, é por
    `BodyPosition`/`BodyVelocity` com prazo, no alvo, um por um.

QUATRO HABILIDADES TÊM PRAZO, E AS QUATRO DESLIGAM SOZINHAS

    Mancha, Vácuo, Luas, Cinturão e Blindagem ficam de pé por alguns segundos.
    As cinco têm `id`, um tique recursivo por `task.delay`, e um `parar*` que é
    chamado tanto pelo fim do prazo quanto pelo `desmontar` — guardar a Tool no
    meio não pode deixar efeito órfão na tela de ninguém.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Jupiter Grande Mancha",
  objeto="JupiterGrandeMancha_Server_V1", sufixo="JupiterMancha",
  arquetipo="GRAVIDADE", alcance_mira=60,
  rotulo_m1="Grande Mancha", rotulo_r="Olho", rotulo_t="Dispersar",
  origem=["Handle: bastao ocre com disco vermelho girando na ponta",
          "GIRA 2162238374 (SpirtLoop) · OLHO 9125402735 (DuperBoom)",
          "DISPERSA 5405455343 (Unwing) — os tres do SFX/ids.md da ficha"],
  cfg="""	ALCANCE       = 26,
	RECARGA       = 1.0,
	RAIO          = 18,
	DANO          = 14,
	VIDA_MANCHA   = 5,
	INTERVALO     = 0.5,
	PUXAO         = 26,

	RECARGA_R     = 14,
	RAIO_OLHO     = 10,
	DANO_OLHO     = 22,
	ALTURA_OLHO   = 14,
	TEMPO_OLHO    = 2.2,

	RECARGA_T     = 22,
	RAIO_SOPRO    = 26,
	NUCLEO_SOPRO  = 9,
	DANO_SOPRO    = 34,
	BORDA_SOPRO   = 17,
	EMPURRAO      = 96,
	TOMBO         = 1.6,""",
  estado="local manchaId, manchaOnde = nil, nil",
  ao_guardar="\tpararMancha()\n",
  corpo='''
--''' + R + '''
-- M1 — a tempestade que gira
--
-- Ela fica de pé por `VIDA_MANCHA` segundos, com um tique a cada `INTERVALO`.
-- O tique é recursivo por `task.delay`, nunca por quadro: o servidor não move
-- geometria a 60 Hz, e o disco do cliente gira sozinho pelo `RotSpeed` do
-- emissor — que é a solução do próprio modelo de origem.
--''' + R + '''

local function pararMancha()
	if manchaId then
		vfx("APAGAR", { id = manchaId })
		manchaId = nil
	end
	manchaOnde = nil
end

local function girarMancha(centro, restantes)
	if not manchaId then return end
	if restantes <= 0 then
		pararMancha()
		return
	end
	vfx("MANCHA_TIQUE", { posicao = centro, raio = CFG.RAIO, escala = 1 })
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
		aplicarDano(alvo, CFG.DANO)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, centro - alvoRaiz.Position, CFG.PUXAO, 0.24)
		end
	end
	task.delay(CFG.INTERVALO, function()
		girarMancha(centro, restantes - 1)
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MANCHA", despachar({
		CARGA  = { sfx = { "GIRA", 0.9 } },
		SEGURA = { faz = function()
			vfx("MANCHA_TIQUE", { posicao = destino, raio = CFG.RAIO * 0.4,
				escala = 0.7 })
		end },
		GOLPE = { faz = function()
			pararMancha()
			manchaId = novoId("MANCHA")
			manchaOnde = destino
			vfx("MANCHA", { id = manchaId, posicao = destino, raio = CFG.RAIO,
				escala = 1, vida = CFG.VIDA_MANCHA })
			tocarEm("GIRA", destino, 1)
			girarMancha(destino, math.floor(CFG.VIDA_MANCHA / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Olho
--
-- O centro parado da tempestade. Sobe quem está dentro e segura no ar por
-- `TEMPO_OLHO` — `BodyPosition` com prazo, nunca `Anchored`.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("OLHO", despachar({
		CARGA  = { sfx = { "OLHO", 0.8 } },
		SEGURA = { faz = function()
			vfx("MANCHA_TIQUE", { posicao = destino, raio = CFG.RAIO_OLHO,
				escala = 0.8 })
		end },
		GOLPE = { faz = function()
			vfx("OLHO", { posicao = destino, raio = CFG.RAIO_OLHO, escala = 1 })
			tocarEm("OLHO", destino, 0.85)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_OLHO, 8)) do
				aplicarDano(alvo, CFG.DANO_OLHO)
				suspender(alvo, CFG.ALTURA_OLHO, CFG.TEMPO_OLHO, 9000)
				afrouxar(alvo, 0.55, CFG.TEMPO_OLHO)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Dispersar
--
-- Desmonta a tempestade de uma vez. Se houver uma de pé, ela é o CENTRO do
-- sopro — é o que amarra a Extra à M1 sem uma Tool alcançar a outra.
--''' + R + '''

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("DISPERSAR", despachar({
		CARGA  = { sfx = { "DISPERSA", 1.15 } },
		SEGURA = { faz = function()
			vfx("MANCHA_TIQUE", { posicao = manchaOnde or destino,
				raio = CFG.RAIO_SOPRO * 0.3, escala = 0.8 })
		end },
		GOLPE = { faz = function()
			local centro = manchaOnde or destino
			vfx("DISPERSAR", { posicao = centro, raio = CFG.RAIO_SOPRO,
				escala = 1 })
			tocarEm("DISPERSA", centro, 1.05)
			golpearArea(centro, CFG.RAIO_SOPRO, CFG.NUCLEO_SOPRO,
				CFG.DANO_SOPRO, CFG.BORDA_SOPRO, CFG.EMPURRAO, CFG.TOMBO)
			pararMancha()
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Pressao Esmagadora",
  objeto="JupiterPressaoEsmagadora_Server_V1", sufixo="JupiterPressao",
  arquetipo="GRAVIDADE", alcance_mira=55,
  rotulo_m1="Coluna", rotulo_r="Prensa", rotulo_t="Vacuo",
  origem=["Handle: eixo de ferro com dois blocos pesados nas pontas",
          "PRENSA 9125403260 (Impact_Sound) · ESMAGA 260281717 (MeteorSmash)",
          "VACUO 763717897 (VJ_Explosion) — os tres da ficha"],
  cfg="""	ALCANCE       = 24,
	RECARGA       = 1.1,
	RAIO_COLUNA   = 7,
	DANO_COLUNA   = 16,
	PRESSAO       = 58,
	LENTIDAO      = 0.55,
	TEMPO_LENTO   = 2.4,

	RECARGA_R     = 13,
	RAIO_PRENSA   = 9,
	DANO_PRENSA   = 38,
	BORDA_PRENSA  = 19,
	TOMBO_PRENSA  = 1.8,

	RECARGA_T     = 24,
	RAIO_VACUO    = 22,
	DANO_VACUO    = 11,
	VIDA_VACUO    = 2.4,
	INTERVALO     = 0.4,
	RIGIDEZ_VACUO = 7000,""",
  estado="local vacuoId = nil",
  ao_guardar="\tpararVacuo()\n",
  corpo='''
--''' + R + '''
-- M1 — a coluna de pressão
--
-- Ela vem de CIMA. O alvo não é jogado para longe: é prensado contra o chão e
-- afrouxado — é o que separa esta Tool de uma explosão comum.
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COLUNA", despachar({
		CARGA  = { sfx = { "PRENSA", 0.9 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_COLUNA * 0.3,
				escala = 0.5 })
		end },
		GOLPE = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_COLUNA,
				escala = 1 })
			tocarEm("PRENSA", destino, 1)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_COLUNA, 10)) do
				aplicarDano(alvo, CFG.DANO_COLUNA)
				empurrar(alvo, Vector3.new(0, -1, 0), CFG.PRESSAO, 0.3)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Prensa
--
-- Duas placas fecham no ponto. O dano é de núcleo e borda, e não de raio só:
-- é o que impede a prensa de matar quem estava só passando perto.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PRENSAR", despachar({
		CARGA  = { sfx = { "ESMAGA", 0.8 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = CFG.RAIO_PRENSA * 0.4,
				escala = 0.6 })
		end },
		GOLPE = { faz = function()
			vfx("PRENSA", { posicao = destino, raio = CFG.RAIO_PRENSA,
				escala = 1 })
			tocarEm("ESMAGA", destino, 0.9)
			golpearArea(destino, CFG.RAIO_PRENSA, CFG.RAIO_PRENSA * 0.45,
				CFG.DANO_PRENSA, CFG.BORDA_PRENSA, nil, CFG.TOMBO_PRENSA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Vácuo
--
-- Puxa para o ponto por `VIDA_VACUO` segundos. `atrair` é `BodyPosition` com
-- prazo: quem está preso continua podendo girar a câmera e atacar, e sai
-- sozinho quando o prazo vence — mesmo se a Tool sumir no meio.
--''' + R + '''

local function pararVacuo()
	if vacuoId then
		vfx("APAGAR", { id = vacuoId })
		vacuoId = nil
	end
end

local function sugar(centro, restantes)
	if not vacuoId then return end
	if restantes <= 0 then
		pararVacuo()
		return
	end
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_VACUO, 12)) do
		aplicarDano(alvo, CFG.DANO_VACUO)
		atrair(alvo, centro, CFG.INTERVALO, CFG.RIGIDEZ_VACUO)
	end
	task.delay(CFG.INTERVALO, function()
		sugar(centro, restantes - 1)
	end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("VACUO", despachar({
		CARGA  = { sfx = { "VACUO", 1.1 } },
		SEGURA = { faz = function()
			vfx("COLUNA", { posicao = destino, raio = 3, escala = 0.4 })
		end },
		GOLPE = { faz = function()
			pararVacuo()
			vacuoId = novoId("VACUO")
			vfx("VACUO", { id = vacuoId, posicao = destino,
				raio = CFG.RAIO_VACUO, escala = 1, vida = CFG.VIDA_VACUO })
			tocarEm("VACUO", destino, 0.95)
			sugar(destino, math.floor(CFG.VIDA_VACUO / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Raio Joviano",
  objeto="JupiterRaioJoviano_Server_V1", sufixo="JupiterRaio",
  arquetipo="ASTRAL", alcance_mira=70,
  rotulo_m1="Raio", rotulo_r="Cadeia", rotulo_t="Tormenta",
  origem=["Handle: lanca preta com ponta em neon azul",
          "RAIO 80214468 (Lightning1) · CADEIA 96478567 (Lightning3)",
          "TORMENTA 96478346 (Lightning5) — os tres da ficha"],
  cfg="""	ALCANCE       = 30,
	RECARGA       = 0.9,
	RAIO_QUEDA    = 8,
	DANO          = 26,
	TOMBO         = 0.7,

	RECARGA_R     = 12,
	ELOS          = 5,
	ALCANCE_ELO   = 26,
	DANO_ELO      = 18,
	CHOQUE        = 1.4,

	RECARGA_T     = 26,
	RAIO_TORMENTA = 30,
	QUEDAS        = 8,
	INTERVALO     = 0.35,
	DANO_QUEDA    = 15,
	RAIO_FAISCA   = 7,""",
  estado="local tormentaId = nil",
  ao_guardar="\tpararTormenta()\n",
  corpo='''
--''' + R + '''
-- M1 — o raio que cai
--
-- O desenho vem de 90 studs acima do ponto, e é isso que faz ele ler como
-- vindo do céu. A origem trazia um `LightningBolt` de terceiro com 260 linhas
-- e `math.random` no meio; o raio daqui é traçado por ângulo áureo, e os dois
-- clientes veem o mesmo.
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("RAIO", despachar({
		CARGA = { sfx = { "RAIO", 1 } },
		GOLPE = { faz = function()
			vfx("RAIO", { posicao = destino, escala = 1 })
			tocarEm("RAIO", destino, 1 + jitter(0.4) * 0.1)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_QUEDA, 6)) do
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Cadeia
--
-- Pula de alvo em alvo, sempre para o MAIS PERTO ainda não visitado. Sem
-- sorteio: a mesma configuração de alvos dá a mesma cadeia, o que faz a
-- habilidade ser jogável em vez de loteria.
--
-- O choque fica preso ao alvo (`LockedToPart`), não ao ponto onde ele estava —
-- é o único emissor do conjunto que ANDA junto de quem levou.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("CADEIA", despachar({
		CARGA = { sfx = { "CADEIA", 1.2 } },
		GOLPE = { faz = function()
			local anterior = raiz.Position + Vector3.new(0, 2, 0)
			local vistos = {}
			local elos = 0
			while elos < CFG.ELOS do
				local melhor, dist = nil, math.huge
				for _, alvo in ipairs(alvosEm(anterior, CFG.ALCANCE_ELO, 12)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz and not vistos[alvo] then
						local d = (alvoRaiz.Position - anterior).Magnitude
						if d < dist then melhor, dist = alvo, d end
					end
				end
				if not melhor then break end
				vistos[melhor] = true
				local alvoRaiz = raizDe(melhor)
				vfx("ARCO", { de = anterior, para = alvoRaiz.Position,
					escala = 1 })
				vfx("CHOQUE", { peca = alvoRaiz, escala = 1,
					vida = CFG.CHOQUE })
				aplicarDano(melhor, CFG.DANO_ELO)
				afrouxar(melhor, 0.6, CFG.CHOQUE)
				anterior = alvoRaiz.Position
				elos = elos + 1
			end
			if elos == 0 then
				tocar("CADEIA", 0.8)
			else
				tocarEm("CADEIA", anterior, 1.15)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Tormenta
--
-- A nuvem fica de pé e os raios caem por baixo dela, espalhados pelo ângulo
-- áureo — 137.507764° nunca repete alinhamento, então oito quedas cobrem a
-- área sem duas caírem no mesmo lugar.
--''' + R + '''

local function pararTormenta()
	if tormentaId then
		vfx("APAGAR", { id = tormentaId })
		tormentaId = nil
	end
end

local function cair(centro, indice, restantes)
	if not tormentaId then return end
	if restantes <= 0 then
		pararTormenta()
		return
	end
	local a = anguloDe(indice)
	local afastamento = CFG.RAIO_TORMENTA * (0.25 + 0.7 * (indice % 4) / 4)
	local ponto = centro + Vector3.new(math.cos(a), 0, math.sin(a)) * afastamento
	vfx("RAIO", { posicao = ponto, escala = 0.8 })
	tocarEm("TORMENTA", ponto, 0.85 + jitter(indice) * 0.12)
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_FAISCA, 5)) do
		aplicarDano(alvo, CFG.DANO_QUEDA)
	end
	task.delay(CFG.INTERVALO, function()
		cair(centro, indice + 1, restantes - 1)
	end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TORMENTA", despachar({
		CARGA  = { sfx = { "TORMENTA", 0.85 } },
		SEGURA = { faz = function()
			vfx("ARCO", { de = raiz.Position + Vector3.new(0, 3, 0),
				para = destino + Vector3.new(0, 30, 0), escala = 0.7 })
		end },
		GOLPE = { faz = function()
			pararTormenta()
			tormentaId = novoId("TORMENTA")
			vfx("TORMENTA", { id = tormentaId, posicao = destino,
				raio = CFG.RAIO_TORMENTA, escala = 1,
				vida = CFG.QUEDAS * CFG.INTERVALO + 0.5 })
			cair(destino, 1, CFG.QUEDAS)
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Luas Galileanas",
  objeto="JupiterLuasGalileanas_Server_V1", sufixo="JupiterLuas",
  arquetipo="ASTRAL", alcance_mira=65,
  rotulo_m1="Luas", rotulo_r="Lanca Io", rotulo_t="Eclipse",
  origem=["Handle: o planeta na mao com as quatro luas em volta",
          "ORBITA 160773067 (SpawnJupiter) · IO 96478259 (Lightning2)",
          "ECLIPSE 401056199 (VJ_Explosion2) — os tres da ficha",
          "malha do planeta: 907848103 com textura 8077647902"],
  cfg="""	ALCANCE       = 22,
	RECARGA       = 1.0,
	RAIO_ORBITA   = 8,
	DANO_LUA      = 9,
	VIDA_ORBITA   = 6,
	INTERVALO     = 0.4,
	PASSO_FASE    = 0.55,

	RECARGA_R     = 11,
	VOO_MINIMO    = 0.28,
	VOO_MAXIMO    = 0.46,
	RAIO_IO       = 12,
	DANO_IO       = 25,
	QUEIMA        = 7,
	QUEIMADAS     = 3,

	RECARGA_T     = 25,
	RAIO_ECLIPSE  = 24,
	NUCLEO_ECLIPSE = 8,
	DANO_ECLIPSE  = 40,
	BORDA_ECLIPSE = 20,
	TOMBO_ECLIPSE = 2,
	LENTIDAO      = 0.45,
	TEMPO_SOMBRA  = 3,""",
  estado="local luasId, luasFase = nil, 0",
  ao_guardar="\tpararLuas()\n",
  corpo='''
--''' + R + '''
-- M1 — as quatro luas
--
-- Io, Europa, Ganimedes e Calisto giram em volta de quem conjurou e ferem quem
-- encostar. Quem as leva é o `MOVER`, por TIQUE — uma mensagem a cada 0.4 s, e
-- o cliente faz o meio do caminho com um tween linear. Mandar posição por
-- quadro seria 60 mensagens por segundo por lua.
--''' + R + '''

local function pararLuas()
	if luasId then
		vfx("APAGAR", { id = luasId })
		luasId = nil
	end
end

local function orbitar(restantes)
	if not luasId then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		pararLuas()
		return
	end
	luasFase = luasFase + CFG.PASSO_FASE
	vfx("MOVER", { id = luasId, posicao = raiz.Position,
		raio = CFG.RAIO_ORBITA, fase = luasFase, tempo = CFG.INTERVALO })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_ORBITA + 2, 8)) do
		aplicarDano(alvo, CFG.DANO_LUA)
	end
	task.delay(CFG.INTERVALO, function()
		orbitar(restantes - 1)
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("LUAS", despachar({
		CARGA  = { sfx = { "ORBITA", 1 } },
		SEGURA = { faz = function()
			vfx("LUAS", { posicao = raiz.Position, raio = CFG.RAIO_ORBITA * 0.4,
				escala = 0.5, vida = 0.4 })
		end },
		GOLPE = { faz = function()
			pararLuas()
			luasId = novoId("LUAS")
			luasFase = 0
			vfx("LUAS", { id = luasId, posicao = raiz.Position,
				raio = CFG.RAIO_ORBITA, escala = 1, vida = CFG.VIDA_ORBITA })
			orbitar(math.floor(CFG.VIDA_ORBITA / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Lança Io
--
-- A lua vulcânica sai da mão e vai até o ponto. O impacto queima: três tiques
-- de dano pequeno depois do estouro, que é o que separa Io das outras três.
--''' + R + '''

local function queimar(centro, restantes)
	if restantes <= 0 then return end
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_IO * 0.7, 6)) do
		aplicarDano(alvo, CFG.QUEIMA)
	end
	task.delay(0.5, function()
		queimar(centro, restantes - 1)
	end)
end

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LANCA_IO", despachar({
		CARGA = { sfx = { "IO", 1.3 } },
		GOLPE = { faz = function()
			local saida = raiz.Position + raiz.CFrame.LookVector * 2
				+ Vector3.new(0, 2, 0)
			local voo = naFaixa(CFG.VOO_MINIMO, CFG.VOO_MAXIMO)
			vfx("IO", { de = saida, para = destino, tempo = voo, escala = 1 })
			tocar("IO", 1.25)
			task.delay(voo, function()
				vfx("IO_IMPACTO", { posicao = destino, raio = CFG.RAIO_IO,
					escala = 1 })
				tocarEm("IO", destino, 0.95)
				for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_IO, 8)) do
					aplicarDano(alvo, CFG.DANO_IO)
				end
				queimar(destino, CFG.QUEIMADAS)
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Eclipse
--
-- As quatro se alinham e a sombra cai. É a única habilidade do conjunto que
-- SUBTRAI luz em vez de somar, e o efeito é 3D — nada de `ColorCorrection`,
-- que a origem usava quatro vezes e é proibido dentro da Tool.
--''' + R + '''

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ECLIPSE", despachar({
		CARGA  = { sfx = { "ECLIPSE", 0.75 } },
		SEGURA = { faz = function()
			vfx("LUAS", { posicao = destino, raio = CFG.RAIO_ECLIPSE * 0.3,
				escala = 0.7, vida = 0.6 })
		end },
		GOLPE = { faz = function()
			vfx("ECLIPSE", { posicao = destino, raio = CFG.RAIO_ECLIPSE,
				escala = 1 })
			tocarEm("ECLIPSE", destino, 0.8)
			golpearArea(destino, CFG.RAIO_ECLIPSE, CFG.NUCLEO_ECLIPSE,
				CFG.DANO_ECLIPSE, CFG.BORDA_ECLIPSE, nil, CFG.TOMBO_ECLIPSE)
			for _, alvo in ipairs(alvosEm(destino, CFG.RAIO_ECLIPSE, 12)) do
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_SOMBRA)
			end
			pararLuas()
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Cinturao de Radiacao",
  objeto="JupiterCinturaodeRadiacao_Server_V1", sufixo="JupiterRadiacao",
  arquetipo="ARCANO", alcance_mira=45,
  rotulo_m1="Cinturao", rotulo_r="Pulso", rotulo_t="Blindagem",
  origem=["Handle: planeta pequeno com o anel verde do cinturao",
          "CAMPO 1146689657 (DistantJupiter) · PULSO 96478505 (Lightning4)",
          "BLINDA 96478426 (Lightning6) — os tres da ficha"],
  cfg="""	ALCANCE       = 18,
	RECARGA       = 1.0,
	RAIO_CINTO    = 14,
	DANO_CINTO    = 8,
	VIDA_CINTO    = 6,
	INTERVALO     = 0.5,
	CORROSAO      = 0.75,

	RECARGA_R     = 10,
	RAIO_PULSO    = 20,
	NUCLEO_PULSO  = 7,
	DANO_PULSO    = 30,
	BORDA_PULSO   = 15,
	EMPURRAO      = 74,

	RECARGA_T     = 20,
	RAIO_ESCUDO   = 7,
	VIDA_ESCUDO   = 5,
	INTERVALO_BLINDA = 0.4,
	REDUCAO       = 0.4,
	REPULSAO      = 52,""",
  estado="local cintoId, escudoId, cancelarReducao = nil, nil, nil",
  ao_guardar="\tpararCinto()\n\tpararBlindagem()\n",
  corpo='''
--''' + R + '''
-- M1 — o cinturão
--
-- Um campo em volta de quem conjurou, que corrói por tique e afrouxa. Ele
-- ACOMPANHA o dono pelo `MOVER`, então andar não o deixa para trás.
--''' + R + '''

local function pararCinto()
	if cintoId then
		vfx("APAGAR", { id = cintoId })
		cintoId = nil
	end
end

local function corroer(restantes)
	if not cintoId then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		pararCinto()
		return
	end
	vfx("MOVER", { id = cintoId, posicao = raiz.Position,
		tempo = CFG.INTERVALO })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_CINTO, 12)) do
		aplicarDano(alvo, CFG.DANO_CINTO)
		afrouxar(alvo, CFG.CORROSAO, CFG.INTERVALO * 1.6)
	end
	task.delay(CFG.INTERVALO, function()
		corroer(restantes - 1)
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CINTURAO", despachar({
		CARGA  = { sfx = { "CAMPO", 0.9 } },
		SEGURA = { faz = function()
			vfx("PULSO_RAD", { posicao = raiz.Position,
				raio = CFG.RAIO_CINTO * 0.3, escala = 0.5 })
		end },
		GOLPE = { faz = function()
			pararCinto()
			cintoId = novoId("CINTO")
			vfx("CINTURAO", { id = cintoId, posicao = raiz.Position,
				raio = CFG.RAIO_CINTO, escala = 1, vida = CFG.VIDA_CINTO })
			corroer(math.floor(CFG.VIDA_CINTO / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Pulso
--
-- O cinturão inteiro joga para fora de uma vez. Núcleo e borda, para o pulso
-- não matar quem estava na periferia.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("PULSO", despachar({
		CARGA  = { sfx = { "PULSO", 1.15 } },
		SEGURA = { faz = function()
			vfx("PULSO_RAD", { posicao = raiz.Position,
				raio = CFG.RAIO_PULSO * 0.25, escala = 0.6 })
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("PULSO_RAD", { posicao = centro, raio = CFG.RAIO_PULSO,
				escala = 1 })
			tocarEm("PULSO", centro, 1.1)
			golpearArea(centro, CFG.RAIO_PULSO, CFG.NUCLEO_PULSO,
				CFG.DANO_PULSO, CFG.BORDA_PULSO, CFG.EMPURRAO, 0.8)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Blindagem
--
-- A magnetosfera. Com o Núcleo de pé, ela é uma REDUÇÃO registrada lá —
-- `registrarReducao` devolve a função de cancelar, e é ela que o `desmontar`
-- chama se a Tool sumir antes do prazo.
--
-- Sem o Núcleo não há gancho de dano para descontar nada. O que a Tool
-- consegue sozinha é REPELIR: quem entra na cúpula é empurrado para fora e
-- afrouxado. É a mesma leitura, por outro caminho — e é o que faz a Tool
-- sozinha num place vazio ainda funcionar por inteiro (Regra nº 1).
--''' + R + '''

local function pararBlindagem()
	if escudoId then
		vfx("APAGAR", { id = escudoId })
		escudoId = nil
	end
	if cancelarReducao then
		cancelarReducao()
		cancelarReducao = nil
	end
end

local function repelir(restantes)
	if not escudoId then return end
	if restantes <= 0 or not (personagem and raiz and raiz.Parent) then
		pararBlindagem()
		return
	end
	vfx("MOVER", { id = escudoId, posicao = raiz.Position,
		tempo = CFG.INTERVALO_BLINDA })
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_ESCUDO, 8)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, alvoRaiz.Position - raiz.Position, CFG.REPULSAO, 0.2)
			afrouxar(alvo, 0.7, 0.6)
		end
	end
	task.delay(CFG.INTERVALO_BLINDA, function()
		repelir(restantes - 1)
	end)
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("BLINDAGEM", despachar({
		CARGA  = { sfx = { "BLINDA", 0.7 } },
		SEGURA = { faz = function()
			vfx("PULSO_RAD", { posicao = raiz.Position,
				raio = CFG.RAIO_ESCUDO * 0.5, escala = 0.5 })
		end },
		GOLPE = { faz = function()
			pararBlindagem()
			escudoId = novoId("BLINDA")
			vfx("BLINDAGEM", { id = escudoId, posicao = raiz.Position,
				raio = CFG.RAIO_ESCUDO, escala = 1, vida = CFG.VIDA_ESCUDO })
			tocar("BLINDA", 0.75)
			if _G.Combate and _G.Combate.registrarReducao then
				cancelarReducao = _G.Combate.registrarReducao(
					personagem, CFG.REDUCAO, CFG.VIDA_ESCUDO)
			end
			repelir(math.floor(CFG.VIDA_ESCUDO / CFG.INTERVALO_BLINDA))
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Espada de Pressao",
  objeto="JupiterEspadadePressao_Server_V1", sufixo="JupiterEspada",
  arquetipo="MELEE", alcance_mira=40,
  rotulo_m1="Golpe", rotulo_r="Estocada", rotulo_t="Corte Gigante",
  origem=["Handle: a unica lamina de verdade do conjunto",
          "LAMINA 8145344127 (SwordLunge) · CORTE 5287092000 (SwordHit)",
          "GIGANTE 3360000345 (SwordHit2) — os tres da ficha"],
  cfg="""	ALCANCE       = 6,
	RECARGA       = 0.7,
	RAIO_GOLPE    = 7,
	DANO          = 21,
	EMPURRAO      = 38,
	TOMBO         = 0.6,
	ALCANCE_ONDA  = 22,
	DANO_ONDA     = 12,
	RAIO_ONDA     = 5,

	RECARGA_R     = 9,
	ALCANCE_ESTOQUE = 30,
	PASSOS_ESTOQUE = 8,
	RAIO_ESTOQUE  = 4,
	DANO_ESTOQUE  = 32,

	RECARGA_T     = 21,
	ALCANCE_CORTE = 34,
	LARGURA_CORTE = 12,
	NUCLEO_CORTE  = 7,
	DANO_CORTE    = 46,
	BORDA_CORTE   = 23,
	EMPURRAO_CORTE = 84,
	TOMBO_CORTE   = 1.6,""",
  corpo='''
--''' + R + '''
-- M1 — o golpe
--
-- Bate perto E manda uma onda de pressão à frente. É o que faz a espada deste
-- conjunto não ser só uma espada: o alcance de corpo a corpo é 7 studs, mas a
-- onda chega a 22.
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("GOLPE", despachar({
		CARGA = { sfx = { "LAMINA", 1.2 } },
		GOLPE = { faz = function()
			local q = raiz.CFrame * CFrame.new(0, 1, -3)
			local ponto = frente(CFG.ALCANCE)
			vfx("CORTE", { cframe = q, escala = 1 })
			vfx("ONDA_PRESSAO", { cframe = q, alcance = CFG.ALCANCE_ONDA,
				escala = 1 })
			tocarEm("CORTE", ponto, 1 + jitter(0.4) * 0.1)

			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 6)) do
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.3, 0),
					CFG.EMPURRAO, 0.2)
			end

			-- a onda: o dano dela é menor, e mora mais longe
			local longe = raiz.Position
				+ raiz.CFrame.LookVector * CFG.ALCANCE_ONDA
			for _, alvo in ipairs(alvosEm(longe, CFG.RAIO_ONDA, 6)) do
				aplicarDano(alvo, CFG.DANO_ONDA)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Estocada
--
-- Uma linha reta. O dano é colhido em `PASSOS_ESTOQUE` pontos ao longo dela,
-- com um raio pequeno em cada — é o que faz a estocada acertar quem está NO
-- caminho, e não quem está numa esfera gigante em volta do fim dela.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ESTOCADA", despachar({
		CARGA = { sfx = { "LAMINA", 0.95 } },
		GOLPE = { faz = function()
			local saida = raiz.Position + Vector3.new(0, 1.2, 0)
			local delta = destino - saida
			local distancia = math.min(delta.Magnitude, CFG.ALCANCE_ESTOQUE)
			if distancia < 1 then return end
			local direcao = delta.Unit
			local fim = saida + direcao * distancia

			vfx("ESTOCADA", { de = saida, para = fim, escala = 1 })
			tocarEm("LAMINA", fim, 1.05)

			local vistos = {}
			for i = 1, CFG.PASSOS_ESTOQUE do
				local ponto = saida + direcao * (distancia * i / CFG.PASSOS_ESTOQUE)
				for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_ESTOQUE, 6)) do
					if not vistos[alvo] then
						vistos[alvo] = true
						aplicarDano(alvo, CFG.DANO_ESTOQUE)
					end
				end
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Corte Gigante
--
-- A lâmina desce inteira. Núcleo e borda, e o empurrão é para FRENTE do
-- personagem, não para longe do ponto — é um corte, não uma explosão.
--''' + R + '''

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("CORTE_GIGANTE", despachar({
		CARGA  = { sfx = { "GIGANTE", 0.85 } },
		SEGURA = { faz = function()
			vfx("CORTE", { cframe = raiz.CFrame * CFrame.new(0, 2.4, -2),
				escala = 0.6 })
		end },
		GOLPE = { faz = function()
			local q = raiz.CFrame * CFrame.new(0, 2, -4)
			local centro = raiz.Position
				+ raiz.CFrame.LookVector * (CFG.ALCANCE_CORTE * 0.5)
			vfx("CORTE_GIGANTE", { cframe = q, alcance = CFG.ALCANCE_CORTE,
				escala = 1 })
			tocarEm("GIGANTE", centro, 0.9)

			for _, alvo in ipairs(alvosEm(centro, CFG.LARGURA_CORTE, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz
					and (alvoRaiz.Position - centro).Magnitude
					or CFG.LARGURA_CORTE
				if d <= CFG.NUCLEO_CORTE then
					aplicarDano(alvo, CFG.DANO_CORTE)
					tombar(alvo, CFG.TOMBO_CORTE)
				else
					aplicarDano(alvo, CFG.BORDA_CORTE)
					tombar(alvo, CFG.TOMBO_CORTE * 0.5)
				end
				empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.4, 0),
					CFG.EMPURRAO_CORTE, 0.3)
			end
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Jupiter Queda do Gigante",
  objeto="JupiterQuedadoGigante_Server_V1", sufixo="JupiterQueda",
  arquetipo="EXPLOSIVO", alcance_mira=80,
  rotulo_m1="Invocar", rotulo_r="Presenca", rotulo_t="Impacto",
  origem=["Handle: o planeta grande cravado num pedestal curto",
          "INVOCA 5405455343 (JupiterSummon) · PRESENCA 9125402735 (DuperBoom)",
          "IMPACTO 83367202273950 (VJ_Explosion3) — os tres da ficha",
          "malha do planeta: 907848103 com textura 8077647902"],
  cfg="""	ALCANCE       = 34,
	RECARGA       = 1.4,
	TAMANHO       = 16,
	ALTURA        = 60,
	VIDA_PLANETA  = 8,

	RECARGA_R     = 20,
	RAIO_PESO     = 26,
	DANO_PESO     = 12,
	VIDA_PESO     = 5,
	INTERVALO     = 0.6,
	LENTIDAO      = 0.4,

	RECARGA_T     = 40,
	TEMPO_QUEDA   = 0.7,
	RAIO_CRATERA  = 34,
	NUCLEO_CRATERA = 12,
	DANO_CRATERA  = 68,
	BORDA_CRATERA = 30,
	EMPURRAO      = 128,
	TOMBO         = 2.6,""",
  estado="local planetaId, presencaId, planetaOnde = nil, nil, nil",
  ao_guardar="\tpararPlaneta()\n\tpararPresenca()\n",
  corpo='''
--''' + R + '''
-- M1 — invocar
--
-- O planeta sobe e FICA. Ele não cai aqui: cai no `T`. Entre uma coisa e
-- outra ele é um efeito com id, e é o `planetaOnde` que amarra as três
-- habilidades desta Tool umas nas outras.
--''' + R + '''

local function pararPlaneta()
	if planetaId then
		vfx("APAGAR", { id = planetaId })
		planetaId = nil
	end
	planetaOnde = nil
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("INVOCAR", despachar({
		CARGA  = { sfx = { "INVOCA", 0.875 } },
		SEGURA = { faz = function()
			vfx("PRESENCA", { posicao = destino, raio = CFG.RAIO_PESO * 0.3,
				escala = 0.6, vida = 0.5 })
		end },
		GOLPE = { faz = function()
			pararPlaneta()
			planetaId = novoId("PLANETA")
			planetaOnde = destino
			vfx("PLANETA", { id = planetaId,
				posicao = destino + Vector3.new(0, CFG.ALTURA, 0),
				tamanho = CFG.TAMANHO, escala = 1, vida = CFG.VIDA_PLANETA })
			tocarEm("INVOCA", destino, 0.9)
			task.delay(CFG.VIDA_PLANETA, function()
				pararPlaneta()
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Presença
--
-- O peso que o planeta joga no chão embaixo dele. Corrói e afrouxa por tique;
-- se não houver planeta de pé, a presença nasce onde o jogador mira.
--''' + R + '''

local function pararPresenca()
	if presencaId then
		vfx("APAGAR", { id = presencaId })
		presencaId = nil
	end
end

local function pesar(centro, restantes)
	if not presencaId then return end
	if restantes <= 0 then
		pararPresenca()
		return
	end
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PESO, 14)) do
		aplicarDano(alvo, CFG.DANO_PESO)
		afrouxar(alvo, CFG.LENTIDAO, CFG.INTERVALO * 1.8)
		empurrar(alvo, Vector3.new(0, -1, 0), 34, 0.25)
	end
	task.delay(CFG.INTERVALO, function()
		pesar(centro, restantes - 1)
	end)
end

function extraR(mira)
	ocupado = true
	local destino = planetaOnde or mira
	rig:PlaySequence("PRESENCA", despachar({
		CARGA  = { sfx = { "PRESENCA", 0.7 } },
		SEGURA = { faz = function()
			vfx("PRESENCA", { posicao = destino, raio = CFG.RAIO_PESO * 0.4,
				escala = 0.7, vida = 0.5 })
		end },
		GOLPE = { faz = function()
			pararPresenca()
			presencaId = novoId("PESO")
			vfx("PRESENCA", { id = presencaId, posicao = destino,
				raio = CFG.RAIO_PESO, escala = 1, vida = CFG.VIDA_PESO })
			tocarEm("PRESENCA", destino, 0.72)
			pesar(destino, math.floor(CFG.VIDA_PESO / CFG.INTERVALO))
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Impacto
--
-- O planeta cai. É a habilidade mais cara das 21 — 40 s de recarga — e é a
-- única que precisa de duas etapas no tempo: a queda desenha por
-- `TEMPO_QUEDA`, e só então o dano acontece. Dano antes da imagem chegar é o
-- que faz uma habilidade grande parecer quebrada.
--
-- A origem resolvia isto com `Health = 0` e um `Impact_Frame` feito de
-- `ScreenGui` mais `ColorCorrectionEffect` mais `Sky`. Os três são proibidos
-- dentro da Tool; o que ficou é 3D e mora no mundo.
--''' + R + '''

function extraT(mira)
	ocupado = true
	local destino = planetaOnde or mira
	rig:PlaySequence("IMPACTO", despachar({
		CARGA  = { sfx = { "IMPACTO", 0.955 } },
		SEGURA = { faz = function()
			vfx("PRESENCA", { posicao = destino, raio = CFG.RAIO_CRATERA * 0.3,
				escala = 0.8, vida = 0.6 })
		end },
		GOLPE = { faz = function()
			pararPlaneta()
			vfx("QUEDA", { posicao = destino, tamanho = CFG.TAMANHO,
				altura = CFG.ALTURA, tempo = CFG.TEMPO_QUEDA, escala = 1 })
			task.delay(CFG.TEMPO_QUEDA, function()
				vfx("IMPACTO_JOVE", { posicao = destino,
					raio = CFG.RAIO_CRATERA, escala = 1 })
				tocarEm("IMPACTO", destino, 0.955)
				golpearArea(destino, CFG.RAIO_CRATERA, CFG.NUCLEO_CRATERA,
					CFG.DANO_CRATERA, CFG.BORDA_CRATERA, CFG.EMPURRAO,
					CFG.TOMBO)
			end)
		end },
	}), function() ocupado = false end)
end
''')
