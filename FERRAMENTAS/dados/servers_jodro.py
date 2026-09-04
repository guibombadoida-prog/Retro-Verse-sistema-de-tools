"""
servers_jodro.py — as 21 habilidades do conjunto JODRO.

Sete Tools, TRÊS habilidades cada: M1 no clique, `R` e `T` nas teclas. Lido por
`FERRAMENTAS/gerar_servers_jodro.py`.

CONJUNTO AUTORAL INTEIRO

    Não há modelo de origem. Handle, som, pose e habilidade são escritos aqui.
    O que NÃO é inventado é o `SoundId`: cada um já toca em outra Tool entregue
    deste repositório. Id chutado é som mudo que nenhum verificador pega.

MEME PRECISA DE MECÂNICA, NÃO SÓ DE NOME

    A piada está no enquadramento — o martelo alto demais, o dedo apontado, a
    mãe de mãos na cintura. A MECÂNICA por baixo é séria: cada uma das 21 tem
    número, raio e recarga escolhidos para caber ao lado das outras Tools do
    repositório, e nenhuma delas destrói parte de mundo ou de personagem.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Bonk",
  objeto="Bonk_Server_V1", sufixo="JodroBonk",
  arquetipo="MELEE", alcance_mira=30,
  rotulo_m1="bonk", rotulo_r="Mega Bonk", rotulo_t="Cadeia",
  origem=["Handle autoral: cabo de madeira 0.5 x 4.2 e cabeca de aco 1.6",
          "BONK 933780081 (MetalHit) · MEGA 472579737 · CADEIA 413682983",
          "os tres id ja tocam em Tool entregue deste repositorio"],
  cfg="""	ALCANCE       = 5,
	RAIO          = 6,
	DANO          = 24,
	EMPURRAO      = 34,
	TOMBO         = 0.8,
	RECARGA       = 0.8,

	RECARGA_R     = 12,
	RAIO_MEGA     = 14,
	NUCLEO_MEGA   = 5,
	DANO_MEGA     = 52,
	BORDA_MEGA    = 26,
	EMPURRAO_MEGA = 92,
	TOMBO_MEGA    = 2.2,

	RECARGA_T     = 20,
	ALCANCE_CADEIA = 40,
	DURACAO_CADEIA = 4,
	DANO_CADEIA   = 18,
	LENTIDAO      = 0.35,""",
  estado="local cadeiaId = nil",
  corpo='''
--''' + R + '''
-- M1 — bonk
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BONK", despachar({
		CARGA = { sfx = { "BONK", 0.75 } },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			local achou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO, 5)) do
				aplicarDano(alvo, CFG.DANO)
				tombar(alvo, CFG.TOMBO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO, 0.2)
					vfx("BONK", { posicao = alvoRaiz.Position, escala = 1 })
				end
				achou = true
			end
			if achou then tocarEm("BONK", ponto, 1 + jitter(0.4) * 0.12) end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Mega Bonk
--
-- Golpe pesado a DUAS mãos. A pausa de 0.52 s no `SEGURA` é o que faz ele ler
-- como pesado — regra 7: o que dá peso é a parada, não a quantidade de quadro.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("MEGA", despachar({
		CARGA = { sfx = { "MEGA", 0.6 } },
		GOLPE = { faz = function()
			local centro = raiz.Position - Vector3.new(0, 1.6, 0)
			vfx("MEGA_BONK", { posicao = centro, raio = CFG.RAIO_MEGA,
				escala = 1 })
			tocarEm("MEGA", centro, 0.7)
			golpearArea(centro, CFG.RAIO_MEGA, CFG.NUCLEO_MEGA,
				CFG.DANO_MEGA, CFG.BORDA_MEGA, CFG.EMPURRAO_MEGA,
				CFG.TOMBO_MEGA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Cadeia
--
-- Prende o alvo mais perto no lugar. `BodyPosition` com prazo, no ponto onde
-- ele já está — nunca `Anchored`, que travaria o personagem inteiro e deixaria
-- o jogador preso se a Tool sumisse no meio.
--''' + R + '''

local function soltarCadeia()
	if cadeiaId then
		vfx("APAGAR", { id = cadeiaId })
		cadeiaId = nil
	end
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CADEIA", despachar({
		CARGA = { sfx = { "CADEIA", 1.15 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_CADEIA),
				CFG.ALCANCE_CADEIA)
			local alvoRaiz = alvo and raizDe(alvo)
			if not alvoRaiz then
				tocar("CADEIA", 0.8)
				return
			end
			soltarCadeia()
			cadeiaId = novoId("CADEIA")
			aplicarDano(alvo, CFG.DANO_CADEIA)
			prender(alvo, CFG.DURACAO_CADEIA)
			afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_CADEIA + 1)
			vfx("CADEIA", { posicao = alvoRaiz.Position, escala = 1,
				duracao = CFG.DURACAO_CADEIA, id = cadeiaId })
			tocarEm("CADEIA", alvoRaiz.Position, 1)
			local meu = cadeiaId
			task.delay(CFG.DURACAO_CADEIA, function()
				if cadeiaId == meu then soltarCadeia() end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tsoltarCadeia()\n")


# ═══════════════════════════════════════════════════════════════
T("Chinelo Voador",
  objeto="ChineloVoador_Server_V1", sufixo="JodroChinelo",
  arquetipo="MELEE", alcance_mira=45,
  rotulo_m1="chinelada", rotulo_r="Teleguiado", rotulo_t="Mae Brava",
  origem=["Handle autoral: sola 1.5 x 0.35 x 3.6 com tira em V",
          "TAPA 1086616651 (sfx_corte) · VOA 342337569 · BRAVA 1072606965"],
  cfg="""	ALCANCE       = 5,
	RAIO          = 5.5,
	DANO          = 18,
	EMPURRAO      = 30,
	RECARGA       = 0.7,

	RECARGA_R     = 10,
	ALCANCE_VOO   = 45,
	DANO_VOO      = 34,
	EMPURRAO_VOO  = 60,
	TOMBO_VOO     = 1.1,

	RECARGA_T     = 22,
	RAIO_BRAVA    = 20,
	DANO_BRAVA    = 12,
	EMPURRAO_BRAVA = 54,
	LENTIDAO      = 0.45,
	TEMPO_BRAVA   = 5,""",
  estado="local auraId = nil",
  corpo='''
--''' + R + '''
-- M1 — a chinelada
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CHINELADA", despachar({
		CARGA = { sfx = { "TAPA", 1.45 } },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO, 4)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.25, 0),
						CFG.EMPURRAO, 0.18)
					vfx("TAPA", { cframe = CFrame.lookAt(alvoRaiz.Position,
						raiz.Position), escala = 1 })
				end
			end
			tocarEm("TAPA", ponto, 1 + jitter(0.6) * 0.14)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — o chinelo teleguiado
--
-- Ele VAI e VOLTA: o risco de ida sai da mão para o alvo, o de volta refaz o
-- caminho. Sem o segundo, o chinelo lê como perdido, e o portador continua com
-- ele na mão — que é a piada, e precisa aparecer.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TELEGUIADO", despachar({
		CARGA = { sfx = { "VOA", 1.2 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE_VOO)
			local alvo = maisPerto(ponto, 14)
			local alvoRaiz = alvo and raizDe(alvo)
			local onde = (alvoRaiz and alvoRaiz.Position) or ponto
			local mao = raiz.Position + raiz.CFrame.LookVector * 2
				+ Vector3.new(0, 1, 0)

			vfx("CHINELO_VOA", { origem = mao, destino = onde })
			tocarEm("VOA", onde, 1.1)

			if alvo then
				aplicarDano(alvo, CFG.DANO_VOO)
				tombar(alvo, CFG.TOMBO_VOO)
				empurrar(alvo, (onde - raiz.Position) + Vector3.new(0, 0.4, 0),
					CFG.EMPURRAO_VOO, 0.24)
				vfx("TAPA", { cframe = CFrame.lookAt(onde, raiz.Position),
					escala = 1.3 })
			end

			-- a volta, meio segundo depois: é o que fecha a piada
			task.delay(0.35, function()
				if raiz and raiz.Parent then
					vfx("CHINELO_VOA", { origem = onde,
						destino = raiz.Position + Vector3.new(0, 1, 0) })
					tocarEm("VOA", raiz.Position, 1.35)
				end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — a Mãe Brava
--
-- Ninguém morre disso. Quem está no raio recua e fica lento por 5 s: é medo,
-- não dano. Os 12 por alvo existem só para o abate contar se alguém já estava
-- por um fio.
--''' + R + '''

local function pararAura()
	if auraId then
		vfx("APAGAR", { id = auraId })
		auraId = nil
	end
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("BRAVA", despachar({
		CARGA = { sfx = { "BRAVA", 0.9 } },
		SEGURA = { faz = function()
			pararAura()
			auraId = novoId("BRAVA")
			vfx("AURA_BRAVA", { posicao = raiz.Position, escala = 1,
				duracao = CFG.TEMPO_BRAVA, id = auraId })
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			tocarEm("BRAVA", centro, 0.85)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_BRAVA, 14)) do
				aplicarDano(alvo, CFG.DANO_BRAVA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_BRAVA)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.35, 0), CFG.EMPURRAO_BRAVA, 0.28)
				end
			end
			local meu = auraId
			task.delay(CFG.TEMPO_BRAVA, function()
				if auraId == meu then pararAura() end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tpararAura()\n")


# ═══════════════════════════════════════════════════════════════
T("Sussy",
  objeto="Sussy_Server_V1", sufixo="JodroSussy",
  arquetipo="MELEE", alcance_mira=45,
  rotulo_m1="facada", rotulo_r="Vent", rotulo_t="Reuniao",
  origem=["Handle autoral: cabo 0.35 x 1.2 e lamina 0.12 x 2.4",
          "FACA 1086616651 · VENT 1894958339 (DESFAZ) · REUNIAO 743521450"],
  cfg="""	ALCANCE       = 4.5,
	RAIO          = 5,
	DANO          = 26,
	BONUS_COSTAS  = 1.6,
	RECARGA       = 0.9,

	RECARGA_R     = 14,
	ALCANCE_VENT  = 45,

	RECARGA_T     = 26,
	RAIO_REUNIAO  = 30,
	PUXAO         = 62,
	DANO_REUNIAO  = 16,
	TOMBO_REUNIAO = 1.2,""",
  corpo='''
--''' + R + '''
-- M1 — a facada, com bônus PELAS COSTAS
--
-- O produto escalar entre para onde o alvo olha e para onde eu olho diz se
-- estou atrás dele. Positivo = os dois olham para o mesmo lado = eu estou nas
-- costas dele, e o dano sobe 60 por cento.
--
-- É o único lugar do repositório onde a posição relativa muda o número, e é o
-- que faz esta Tool ser sobre POSICIONAMENTO em vez de sobre apertar rápido.
--''' + R + '''

local function pelasCostas(alvo)
	local corpo = alvo and alvo.Parent
	local alvoRaiz = corpo and corpo:FindFirstChild("HumanoidRootPart")
	if not (alvoRaiz and raiz) then return false end
	return alvoRaiz.CFrame.LookVector:Dot(raiz.CFrame.LookVector) > 0.35
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("FACADA", despachar({
		CARGA = { sfx = { "FACA", 1.7 } },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO, 3)) do
				local dano = CFG.DANO
				if pelasCostas(alvo) then dano = dano * CFG.BONUS_COSTAS end
				aplicarDano(alvo, dano)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("FACADA", { posicao = alvoRaiz.Position,
						cframe = CFrame.lookAt(alvoRaiz.Position, raiz.Position),
						escala = pelasCostas(alvo) and 1.4 or 1 })
				end
			end
			tocarEm("FACA", ponto, 1 + jitter(0.3) * 0.1)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — o Vent
--
-- Teleporte curto até a mira. Mexer no `CFrame` do PRÓPRIO personagem é
-- permitido — o que a regra proíbe é o servidor mover geometria por quadro, e
-- isto é um salto único.
--
-- A fumaça sai nos DOIS pontos. Sem a de origem, quem estava olhando não
-- entende para onde a pessoa foi, e o teleporte lê como desconexão.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("VENT", despachar({
		CARGA = { sfx = { "VENT", 1.05 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local saida = raiz.Position
			local alvo = destino or frente(CFG.ALCANCE_VENT)
			local delta = alvo - saida
			if delta.Magnitude > CFG.ALCANCE_VENT then
				alvo = saida + delta.Unit * CFG.ALCANCE_VENT
			end
			alvo = Vector3.new(alvo.X, alvo.Y + 3, alvo.Z)

			vfx("VENT", { origem = saida, destino = alvo, escala = 1 })
			tocarEm("VENT", saida, 1)
			raiz.CFrame = CFrame.new(alvo, alvo + raiz.CFrame.LookVector)
			tocarEm("VENT", alvo, 0.9)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Reunião de Emergência
--
-- Puxa todo mundo do raio para o centro e derruba. Não mata: junta. O que
-- acontece depois é problema de quem foi chamado.
--''' + R + '''

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("REUNIAO", despachar({
		CARGA = { sfx = { "REUNIAO", 0.7 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("REUNIAO", { posicao = centro, raio = CFG.RAIO_REUNIAO,
				escala = 1 })
			tocarEm("REUNIAO", centro, 0.8)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_REUNIAO, 16)) do
				aplicarDano(alvo, CFG.DANO_REUNIAO)
				puxar(alvo, centro, CFG.PUXAO, 0.4)
				tombar(alvo, CFG.TOMBO_REUNIAO)
			end
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Caixa de Som",
  objeto="CaixadeSom_Server_V1", sufixo="JodroCaixa",
  arquetipo="SUPORTE", alcance_mira=60,
  rotulo_m1="onda sonora", rotulo_r="Nunca Te Abandono", rotulo_t="Troca de Faixa",
  origem=["Handle autoral: caixa 2.4 x 1.6 x 1.2 com dois cones e uma luz",
          "ONDA 2960518660 (GRAVE) · NUNCA 824687369 · TROCA 260281717"],
  cfg="""	ALCANCE       = 8,
	RAIO_ONDA     = 18,
	DANO_ONDA     = 16,
	EMPURRAO_ONDA = 70,
	RECARGA       = 1.1,

	RECARGA_R     = 16,
	RAIO_NUNCA    = 22,
	DANO_NUNCA    = 14,
	PRENDE_NUNCA  = 2.5,
	LENTIDAO      = 0.4,
	TEMPO_LENTO   = 4,

	RECARGA_T     = 24,
	ALCANCE_TROCA = 60,""",
  corpo='''
--''' + R + '''
-- M1 — a onda sonora
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("ONDA", despachar({
		CARGA = { sfx = { "ONDA", 1.1 } },
		GOLPE = { faz = function()
			local centro = frente(CFG.ALCANCE)
			vfx("ONDA_SOM", { posicao = centro, raio = CFG.RAIO_ONDA,
				escala = 1 })
			vfx("NOTA", { posicao = centro, escala = 1 })
			tocarEm("ONDA", centro, 0.95)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ONDA, 12)) do
				aplicarDano(alvo, CFG.DANO_ONDA)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO_ONDA, 0.26)
				end
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Nunca Te Abandono
--
-- Quem ouve não sai do lugar por 2.5 s e fica lento por mais 4. `BodyPosition`
-- com prazo, no ponto onde o alvo já está.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("NUNCA", despachar({
		CARGA = { sfx = { "NUNCA", 0.8 } },
		SEGURA = { faz = function()
			vfx("NOTA", { posicao = raiz.Position + Vector3.new(0, 2, 0),
				escala = 1.2 })
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("ONDA_SOM", { posicao = centro, raio = CFG.RAIO_NUNCA,
				escala = 1.2 })
			tocarEm("NUNCA", centro, 0.75)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_NUNCA, 14)) do
				aplicarDano(alvo, CFG.DANO_NUNCA)
				prender(alvo, CFG.PRENDE_NUNCA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("NOTA", { posicao = alvoRaiz.Position, escala = 0.9 })
				end
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Troca de Faixa
--
-- Troca de lugar com o alvo mais perto da mira. Os dois `CFrame` são lidos
-- ANTES de qualquer escrita: ler um, escrever, e só então ler o outro colocaria
-- os dois no mesmo ponto.
--''' + R + '''

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TROCA", despachar({
		CARGA = { sfx = { "TROCA", 1.25 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE_TROCA)
			local alvo = maisPerto(ponto, CFG.ALCANCE_TROCA)
			local alvoRaiz = alvo and raizDe(alvo)
			if not (alvoRaiz and raiz and raiz.Parent) then
				tocar("TROCA", 0.85)
				return
			end

			-- os DOIS lidos antes de qualquer escrita
			local meu = raiz.CFrame
			local dele = alvoRaiz.CFrame

			vfx("TROCA", { origem = meu.Position, destino = dele.Position })
			tocarEm("TROCA", meu.Position, 1.2)
			tocarEm("TROCA", dele.Position, 1.2)

			raiz.CFrame = CFrame.new(dele.Position, dele.Position
				+ meu.LookVector)
			alvoRaiz.CFrame = CFrame.new(meu.Position, meu.Position
				+ dele.LookVector)
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Privada Sonora",
  objeto="PrivadaSonora_Server_V1", sufixo="JodroPrivada",
  arquetipo="EXPLOSIVO", alcance_mira=55,
  rotulo_m1="jato", rotulo_r="Descarga", rotulo_t="Coro",
  origem=["Handle autoral: base 1.8 x 1.6 x 2.2, tampa e cano",
          "JATO 342337569 · DESCARGA 472579737 · CORO 1072606965"],
  cfg="""	ALCANCE       = 34,
	RAIO_JATO     = 6,
	DANO_JATO     = 22,
	EMPURRAO_JATO = 48,
	RECARGA       = 1,

	RECARGA_R     = 15,
	RAIO_DESCARGA = 16,
	NUCLEO_DESC   = 6,
	DANO_DESC     = 46,
	BORDA_DESC    = 24,
	PUXAO_DESC    = 46,
	TOMBO_DESC    = 1.6,

	RECARGA_T     = 30,
	DURACAO_CORO  = 8,
	RAIO_CORO     = 13,
	TIQUE_CORO    = 0.9,
	DANO_CORO     = 9,
	PASSO_CORO    = 0.3,""",
  estado="local coroId = nil\nlocal coroOnde = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — o jato
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("JATO", despachar({
		CARGA = { sfx = { "JATO", 0.85 } },
		GOLPE = { faz = function()
			local boca = raiz.Position + raiz.CFrame.LookVector * 2
				+ Vector3.new(0, 1, 0)
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("JATO", { origem = boca, destino = ponto, escala = 1 })
			tocarEm("JATO", ponto, 0.75)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_JATO, 8)) do
				aplicarDano(alvo, CFG.DANO_JATO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (ponto - boca).Unit + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO_JATO, 0.22)
				end
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — a Descarga
--
-- Puxa para o centro e estoura. A ordem importa: puxar primeiro junta quem
-- estava na borda, e aí o núcleo pega mais gente.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("DESCARGA", despachar({
		CARGA = { sfx = { "DESCARGA", 1.3 } },
		SEGURA = { faz = function()
			local centro = raiz.Position
			vfx("DESCARGA", { posicao = centro, escala = 1 })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_DESCARGA, 14)) do
				puxar(alvo, centro, CFG.PUXAO_DESC, 0.3)
			end
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("DESCARGA", { posicao = centro, escala = 1.5 })
			tocarEm("DESCARGA", centro, 0.9)
			golpearArea(centro, CFG.RAIO_DESCARGA, CFG.NUCLEO_DESC,
				CFG.DANO_DESC, CFG.BORDA_DESC, 40, CFG.TOMBO_DESC)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — o Coro
--
-- Três cabeças invocadas por 8 s. Elas seguem o alvo mais perto e cobram por
-- tique — e são GEOMETRIA do cliente, não NPC: quem invoca, faz seguir e
-- dispensa é a Tool, com prazo e solto no `desmontar()`.
--
-- O passo é por TIQUE de 0.3 s, nunca por quadro: o servidor manda a posição
-- nova e o cliente faz o meio do caminho com tween.
--''' + R + '''

local function dispensarCoro()
	geracao = geracao + 1
	if coroId then
		vfx("APAGAR", { id = coroId })
		coroId = nil
	end
	coroOnde = nil
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("CORO", despachar({
		CARGA = { sfx = { "CORO", 1.5 } },
		GOLPE = { faz = function()
			dispensarCoro()
			geracao = geracao + 1
			local minha = geracao
			local onde = frente(8)
			coroOnde = onde
			coroId = novoId("CORO")
			local id = coroId

			vfx("CORO", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO_CORO, id = id })
			tocarEm("CORO", onde, 1.4)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_CORO
				while minha == geracao and os.clock() < ate do
					local centro = coroOnde or onde
					local presa = maisPerto(centro, 40)
					local presaRaiz = presa and raizDe(presa)
					if presaRaiz then
						coroOnde = presaRaiz.Position + Vector3.new(0, 2, 0)
						vfx("MOVER", { id = id, posicao = coroOnde,
							tempo = CFG.PASSO_CORO })
					end
					for _, alvo in ipairs(alvosEm(coroOnde or centro,
							CFG.RAIO_CORO, 10)) do
						aplicarDano(alvo, CFG.DANO_CORO)
					end
					task.wait(CFG.TIQUE_CORO)
				end
				if minha == geracao then
					vfx("APAGAR", { id = id })
					coroId = nil
					coroOnde = nil
				end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tdispensarCoro()\n")


# ═══════════════════════════════════════════════════════════════
T("Pombo Correio",
  objeto="PomboCorreio_Server_V1", sufixo="JodroPombo",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_m1="bicada", rotulo_r="Revoada", rotulo_t="Encomenda",
  origem=["Handle autoral: corpo 1.1 x 1.0 x 1.9, cabeca, bico e uma carta",
          "BICADA 546410481 · REVOADA 743521450 · ENCOMENDA 472214107"],
  cfg="""	ALCANCE       = 4.5,
	RAIO          = 5,
	DANO          = 16,
	RECARGA       = 0.8,

	RECARGA_R     = 13,
	DURACAO_REVOADA = 6,
	RAIO_REVOADA  = 11,
	TIQUE_REVOADA = 0.7,
	DANO_REVOADA  = 8,
	PASSO_REVOADA = 0.3,

	RECARGA_T     = 28,
	ALCANCE_ENC   = 55,
	QUEDA_ENC     = 1.2,
	RAIO_ENC      = 12,
	NUCLEO_ENC    = 5,
	DANO_ENC      = 60,
	BORDA_ENC     = 30,
	TOMBO_ENC     = 1.8,""",
  estado="local revoadaId = nil\nlocal revoadaOnde = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — a bicada
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BICADA", despachar({
		CARGA = { sfx = { "BICADA", 1.6 } },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO, 3)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("BICADA", { posicao = alvoRaiz.Position, escala = 1 })
				end
			end
			tocarEm("BICADA", ponto, 1 + jitter(0.7) * 0.16)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — a Revoada
--
-- Sete aves que perseguem o alvo mais perto por 6 s e cobram por tique.
-- Mesmo desenho do Coro: geometria do cliente, movida por TIQUE, dispensada no
-- `desmontar()`.
--''' + R + '''

local function dispensarRevoada()
	geracao = geracao + 1
	if revoadaId then
		vfx("APAGAR", { id = revoadaId })
		revoadaId = nil
	end
	revoadaOnde = nil
end

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("REVOADA", despachar({
		CARGA = { sfx = { "REVOADA", 1.3 } },
		GOLPE = { faz = function()
			dispensarRevoada()
			geracao = geracao + 1
			local minha = geracao
			local onde = frente(6) + Vector3.new(0, 2, 0)
			revoadaOnde = onde
			revoadaId = novoId("REVOADA")
			local id = revoadaId

			vfx("REVOADA", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO_REVOADA, id = id })
			tocarEm("REVOADA", onde, 1.2)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_REVOADA
				while minha == geracao and os.clock() < ate do
					local centro = revoadaOnde or onde
					local presa = maisPerto(centro, 45)
					local presaRaiz = presa and raizDe(presa)
					if presaRaiz then
						revoadaOnde = presaRaiz.Position + Vector3.new(0, 2, 0)
						vfx("MOVER", { id = id, posicao = revoadaOnde,
							tempo = CFG.PASSO_REVOADA })
					end
					for _, alvo in ipairs(alvosEm(revoadaOnde or centro,
							CFG.RAIO_REVOADA, 10)) do
						aplicarDano(alvo, CFG.DANO_REVOADA)
					end
					task.wait(CFG.TIQUE_REVOADA)
				end
				if minha == geracao then
					vfx("APAGAR", { id = id })
					revoadaId = nil
					revoadaOnde = nil
				end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — a Encomenda
--
-- Cai do céu no ponto mirado, 1.2 s depois. A espera é a mecânica: dá para
-- sair de baixo, e é o que separa isto de um dano instantâneo em área.
--''' + R + '''

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ENCOMENDA", despachar({
		CARGA = { sfx = { "ENCOMENDA", 1.1 } },
		GOLPE = { faz = function()
			local onde = destino or frente(CFG.ALCANCE_ENC)
			vfx("ENCOMENDA", { posicao = onde, escala = 1,
				queda = CFG.QUEDA_ENC })
			tocarEm("ENCOMENDA", onde, 1.25)
			task.delay(CFG.QUEDA_ENC, function()
				vfx("ENCOMENDA_FIM", { posicao = onde, raio = CFG.RAIO_ENC,
					escala = 1 })
				tocarEm("ENCOMENDA", onde, 0.7)
				golpearArea(onde, CFG.RAIO_ENC, CFG.NUCLEO_ENC,
					CFG.DANO_ENC, CFG.BORDA_ENC, 66, CFG.TOMBO_ENC)
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tdispensarRevoada()\n")


# ═══════════════════════════════════════════════════════════════
T("Deu Ruim",
  objeto="DeuRuim_Server_V1", sufixo="JodroDeuRuim",
  arquetipo="SUPORTE", alcance_mira=40,
  rotulo_m1="o dedo", rotulo_r="Stonks", rotulo_t="Not Stonks",
  origem=["Handle autoral: mao 1.0 cubica com dedo 0.32 x 0.32 x 1.6",
          "APONTA 220834019 · STONKS 236989198 · NOT 1894958339"],
  cfg="""	ALCANCE       = 7,
	RAIO          = 5,
	DANO          = 20,
	RECARGA       = 0.9,

	RECARGA_R     = 18,
	TEMPO_STONKS  = 10,
	VELOCIDADE    = 1.5,
	MULTIPLICADOR = 1.4,

	RECARGA_T     = 25,
	RAIO_NOT      = 16,
	DANO_NOT      = 14,
	TIQUE_NOT     = 1,
	DURACAO_NOT   = 8,
	LENTIDAO_NOT  = 0.5,""",
  estado=("local multiplicador = 1\nlocal velocidadeAntes = nil\n"
          "local stonksId = nil\nlocal geracao = 0"),
  corpo='''
--''' + R + '''
-- O MULTIPLICADOR — o Stonks precisa mexer no dano das outras duas
--
-- `aplicarDano` é do preâmbulo e vale para todo o conjunto. Aqui o dano passa
-- por um envelope local antes, para o buff de 40 por cento valer no dedo e no
-- Not Stonks sem tocar no helper compartilhado.
--''' + R + '''

local function danoBuff(alvo, bruto)
	return aplicarDano(alvo, bruto * multiplicador)
end

--''' + R + '''
-- M1 — o dedo
--''' + R + '''

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("DEDO", despachar({
		CARGA = { sfx = { "APONTA", 1.2 } },
		GOLPE = { faz = function()
			local ponto = frente(CFG.ALCANCE)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO, 4)) do
				danoBuff(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("DEDO", { posicao = alvoRaiz.Position, escala = 1 })
				end
			end
			tocarEm("APONTA", ponto, 1.1)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Stonks
--
-- Buff PRÓPRIO por 10 s: velocidade e dano. A velocidade guardada é a que o
-- portador TINHA, nunca 16 fixo — ele pode estar com velocidade de outra
-- fonte, e devolver 16 seria roubar. Foi o defeito do `Trem`, e não se repete.
--''' + R + '''

local function baixarStonks()
	geracao = geracao + 1
	multiplicador = 1
	if velocidadeAntes and humanoide and humanoide.Parent
			and humanoide.Health > 0 then
		humanoide.WalkSpeed = velocidadeAntes
	end
	velocidadeAntes = nil
	if stonksId then
		vfx("APAGAR", { id = stonksId })
		stonksId = nil
	end
end

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("STONKS", despachar({
		CARGA = { sfx = { "STONKS", 1.35 } },
		GOLPE = { faz = function()
			if not (humanoide and raiz) then return end
			baixarStonks()
			geracao = geracao + 1
			local minha = geracao

			if velocidadeAntes == nil then
				velocidadeAntes = humanoide.WalkSpeed
			end
			humanoide.WalkSpeed = velocidadeAntes * CFG.VELOCIDADE
			multiplicador = CFG.MULTIPLICADOR

			vfx("STONKS", { posicao = raiz.Position, escala = 1 })
			tocarEm("STONKS", raiz.Position, 1.3)

			task.delay(CFG.TEMPO_STONKS, function()
				if minha == geracao then baixarStonks() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Not Stonks
--
-- O contrário, e nos outros: quem está no raio fica lento e sangra por 8 s.
-- Tique de 1 s, nunca por quadro.
--''' + R + '''

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("NOT", despachar({
		CARGA = { sfx = { "NOT", 0.7 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("NOT_STONKS", { posicao = centro, raio = CFG.RAIO_NOT,
				escala = 1 })
			tocarEm("NOT", centro, 0.65)

			local pegos = alvosEm(centro, CFG.RAIO_NOT, 14)
			for _, alvo in ipairs(pegos) do
				afrouxar(alvo, CFG.LENTIDAO_NOT, CFG.DURACAO_NOT)
			end

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_NOT
				while os.clock() < ate do
					for _, alvo in ipairs(pegos) do
						if alvo and alvo.Parent and alvo.Health > 0 then
							danoBuff(alvo, CFG.DANO_NOT)
						end
					end
					task.wait(CFG.TIQUE_NOT)
				end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tbaixarStonks()\n")
