"""
servers_xester.py — as 56 habilidades do Xester, Forma 1 e Forma 2.

Catorze Tools, QUATRO habilidades cada: M1 no clique, `R`, `T` e `Y` nas
teclas. Lido por `FERRAMENTAS/gerar_servers_xester_novo.py`.

RECRIADAS DO ZERO

    As 14 eram as Tools mais antigas do repositório, de um gerador próprio
    anterior ao `despachar`, à pasta `SFX/` e ao preâmbulo compartilhado.
    Tinham M1 mais UMA Extra. A M1 de cada uma foi mantida — é a habilidade
    pela qual a Tool tem nome — e as três Extras estendem o mesmo tema.

DUAS FORMAS, DOIS JEITOS DE BRIGAR

    Forma 1 é o baralho: alcance, projétil, controle. Números menores, recarga
    curta, muita carta no ar.

    Forma 2 é O Despertar: cajado, machado e invocação. Números maiores,
    recarga longa, e três das sete são de área pesada.

NENHUMA DESTRÓI PARTE DE MUNDO NEM DE PERSONAGEM.
"""

CONJUNTO = {}


def T(alvo, forma, **kw):
    kw["forma"] = forma
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
# FORMA 1 — O MESTRE DAS CARTAS
# ═══════════════════════════════════════════════════════════════

T("Xester Ato de Desaparecer", "Forma1",
  objeto="XesterAtodeDesaparecer_Server_V1", sufixo="XesterAto",
  arquetipo="ESPECTRAL", alcance_mira=50,
  rotulo_m1="sumir e reaparecer atras", rotulo_r="Baralhar",
  rotulo_t="Blefe", rotulo_y="Grande Final",
  origem=["Forma 1 — Handle e cartas do baralho `cards` da Forma 2",
          "SELA · AFUNDA · FIM · RISO, os quatro do `xesterv2`"],
  cfg="""	ALCANCE       = 40,
	ATRAS         = 5,
	DANO          = 28,
	RECARGA       = 6,

	RECARGA_R     = 12,
	ALCANCE_TROCA = 50,

	RECARGA_T     = 14,
	DURACAO_BLEFE = 8,
	RAIO_BLEFE    = 4,

	RECARGA_Y     = 26,
	RAIO_FINAL    = 20,
	NUCLEO_FINAL  = 7,
	DANO_FINAL    = 62,
	BORDA_FINAL   = 30,
	EMPURRAO      = 74,
	TOMBO         = 1.8,""",
  estado="local blefeId = nil",
  corpo='''
--''' + R + '''
-- M1 — sumir e reaparecer ATRÁS do alvo
--
-- É a habilidade que dá nome à Tool. O ponto de chegada é atrás das costas do
-- alvo — `-LookVector` DELE, não do portador: reaparecer na frente seria só um
-- teleporte, e o ato é sobre aparecer onde ninguém esperava.
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("SUMIR", despachar({
		CARGA = { sfx = { "SELA", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local saida = raiz.Position
			local alvo = maisPerto(destino or frente(CFG.ALCANCE), CFG.ALCANCE)
			local alvoRaiz = alvo and raizDe(alvo)
			vfx("FANTASMA", { posicao = saida })
			tocarEm("SOME", saida, 1)

			if not alvoRaiz then
				local onde = destino or frente(CFG.ALCANCE * 0.4)
				raiz.CFrame = CFrame.new(onde + Vector3.new(0, 3, 0),
					onde + raiz.CFrame.LookVector)
				return
			end

			local atras = alvoRaiz.Position
				- alvoRaiz.CFrame.LookVector * CFG.ATRAS
			raiz.CFrame = CFrame.new(atras + Vector3.new(0, 1, 0),
				alvoRaiz.Position)
			vfx("FANTASMA", { posicao = atras })
			tocarEm("AFUNDA", atras, 0.95)
			aplicarDano(alvo, CFG.DANO)
			vfx("CARTA_VOA", { origem = atras, destino = alvoRaiz.Position })
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Baralhar  ·  T — Blefe  ·  Y — Grande Final
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("BARALHAR", despachar({
		CARGA = { sfx = { "RISO", 1.15 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_TROCA),
				CFG.ALCANCE_TROCA)
			local alvoRaiz = alvo and raizDe(alvo)
			if not (alvoRaiz and raiz and raiz.Parent) then
				tocar("RISO", 0.85)
				return
			end
			-- os DOIS lidos antes de qualquer escrita
			local meu, dele = raiz.CFrame, alvoRaiz.CFrame
			vfx("FANTASMA", { posicao = meu.Position })
			vfx("FANTASMA", { posicao = dele.Position })
			tocarEm("RISO", dele.Position, 1.1)
			raiz.CFrame = CFrame.new(dele.Position, dele.Position + meu.LookVector)
			alvoRaiz.CFrame = CFrame.new(meu.Position, meu.Position + dele.LookVector)
		end },
	}), function() ocupado = false end)
end

local function tirarBlefe()
	if blefeId then
		vfx("APAGAR", { id = blefeId })
		blefeId = nil
	end
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("BLEFE", despachar({
		CARGA = { sfx = { "FIM", 1.2 } },
		GOLPE = { faz = function()
			tirarBlefe()
			blefeId = novoId("BLEFE")
			local onde = raiz.Position
			vfx("FANTASMA", { posicao = onde, duracao = CFG.DURACAO_BLEFE,
				id = blefeId })
			tocarEm("FIM", onde, 1.15)
			local meu = blefeId
			task.delay(CFG.DURACAO_BLEFE, function()
				if blefeId == meu then tirarBlefe() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("FINAL", despachar({
		CARGA = { sfx = { "RISO", 0.8 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("TEMPESTADE", { posicao = centro, raio = CFG.RAIO_FINAL })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("FIM", centro, 0.75)
			golpearArea(centro, CFG.RAIO_FINAL, CFG.NUCLEO_FINAL,
				CFG.DANO_FINAL, CFG.BORDA_FINAL, CFG.EMPURRAO, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\ttirarBlefe()\n")


T("Xester Full House", "Forma1",
  objeto="XesterFullHouse_Server_V1", sufixo="XesterFullHouse",
  arquetipo="MELEE", alcance_mira=55,
  rotulo_m1="leque de cartas", rotulo_r="Sequencia",
  rotulo_t="Trinca", rotulo_y="Mao Fechada",
  origem=["Forma 1 — as 4 cartas do modelo em `Tool/Moldes/`",
          "ABRE · ATIRA · SEQUENCIA · PUXA"],
  cfg="""	ALCANCE       = 45,
	CARTAS        = 5,
	ESPALHA       = 14,
	DANO          = 14,
	RAIO_CARTA    = 5,
	RECARGA       = 1.1,

	RECARGA_R     = 9,
	CARTAS_SEQ    = 6,
	PASSO_SEQ     = 0.1,
	AVANCO_SEQ    = 7,
	DANO_SEQ      = 18,

	RECARGA_T     = 11,
	CARTAS_TRINCA = 3,
	DANO_TRINCA   = 24,
	ALCANCE_TRINCA = 55,

	RECARGA_Y     = 20,
	RAIO_MAO      = 22,
	PUXAO         = 58,
	DANO_MAO      = 40,""",
  corpo='''
--''' + R + '''
-- O LEQUE — cinco cartas num arco
--
-- O espalhamento é por ângulo áureo escalado, não por sorteio: com todos os
-- clientes desenhando, `math.random` faria cada um ver um leque diferente.
--''' + R + '''

local function atirarCarta(destino, dano, raioDano)
	local mao = raiz.Position + raiz.CFrame.LookVector * 2 + Vector3.new(0, 1.5, 0)
	vfx("LEQUE_ATIRA", { origem = mao, destino = destino })
	vfx("CARTA_VOA", { origem = mao, destino = destino })
	for _, alvo in ipairs(alvosEm(destino, raioDano, 6)) do
		aplicarDano(alvo, dano)
	end
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LEQUE", despachar({
		CARGA = { sfx = { "ABRE", 1 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			local direita = raiz.CFrame.RightVector
			tocarEm("ATIRA", centro, 1.1)
			for i = 1, CFG.CARTAS do
				local desvio = (i - (CFG.CARTAS + 1) / 2)
					* (CFG.ESPALHA / CFG.CARTAS)
				atirarCarta(centro + direita * desvio, CFG.DANO, CFG.RAIO_CARTA)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Sequência (cartas em LINHA, avançando)  ·  T — Trinca  ·  Y — Mão Fechada
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("SEQUENCIA", despachar({
		CARGA = { sfx = { "SEQUENCIA", 1.2 } },
		GOLPE = { faz = function()
			local base = raiz.Position
			local dir = ((destino or frente(CFG.ALCANCE)) - base)
			if dir.Magnitude < 1 then dir = raiz.CFrame.LookVector end
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
			task.spawn(function()
				for i = 1, CFG.CARTAS_SEQ do
					if not (raiz and raiz.Parent) then break end
					atirarCarta(base + dir * (i * CFG.AVANCO_SEQ),
						CFG.DANO_SEQ, CFG.RAIO_CARTA)
					task.wait(CFG.PASSO_SEQ)
				end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TRINCA", despachar({
		CARGA = { sfx = { "ATIRA", 1.35 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE_TRINCA)
			-- teleguiadas: cada uma procura o alvo mais perto do ponto
			for i = 1, CFG.CARTAS_TRINCA do
				local alvo = maisPerto(ponto, CFG.ALCANCE_TRINCA)
				local alvoRaiz = alvo and raizDe(alvo)
				local onde = (alvoRaiz and alvoRaiz.Position) or ponto
				task.delay((i - 1) * 0.08, function()
					if raiz and raiz.Parent then
						atirarCarta(onde, CFG.DANO_TRINCA, CFG.RAIO_CARTA)
					end
				end)
			end
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("MAO_FECHADA", despachar({
		CARGA = { sfx = { "PUXA", 0.9 } },
		SEGURA = { faz = function()
			local centro = raiz.Position
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_MAO, 14)) do
				puxar(alvo, centro, CFG.PUXAO, 0.34)
			end
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("TEMPESTADE", { posicao = centro, raio = CFG.RAIO_MAO })
			tocarEm("PUXA", centro, 0.75)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_MAO, 14)) do
				aplicarDano(alvo, CFG.DANO_MAO)
			end
		end },
	}), function() ocupado = false end)
end
''')


T("Xester Cardnado", "Forma1",
  objeto="XesterCardnado_Server_V1", sufixo="XesterCardnado",
  arquetipo="ESPECTRAL", alcance_mira=50,
  rotulo_m1="tornado de cartas", rotulo_r="Sopro",
  rotulo_t="Olho do Furacao", rotulo_y="Dispersar",
  origem=["Forma 1 — ARRANCA · RUGE · FOGO · OLHO"],
  cfg="""	ALCANCE       = 30,
	RAIO_TORNADO  = 14,
	DURACAO       = 7,
	TIQUE         = 0.7,
	DANO_TIQUE    = 11,
	PUXAO         = 30,
	PASSO_MOVER   = 0.3,
	RECARGA       = 16,

	RECARGA_R     = 10,
	ALCANCE_SOPRO = 26,
	RAIO_SOPRO    = 9,
	DANO_SOPRO    = 22,
	EMPURRAO      = 88,

	RECARGA_T     = 15,
	RAIO_OLHO     = 16,
	DURACAO_OLHO  = 6,
	LENTIDAO      = 0.4,

	RECARGA_Y     = 24,
	RAIO_DISPERSA = 20,
	DANO_DISPERSA = 46,
	TOMBO         = 1.6,""",
  estado=("local tornadoId = nil\nlocal tornadoOnde = nil\n"
          "local olhoId = nil\nlocal geracao = 0"),
  corpo='''
--''' + R + '''
-- O TORNADO — ele ANDA atrás de quem está mais perto
--
-- O passo é por TIQUE de 0.3 s, nunca por quadro: o servidor manda a posição
-- nova e o cliente faz o meio do caminho com tween. Servidor movendo geometria
-- por quadro replica a ~20 Hz picotado.
--''' + R + '''

local function pararTornado()
	geracao = geracao + 1
	if tornadoId then
		vfx("APAGAR", { id = tornadoId })
		tornadoId = nil
	end
	tornadoOnde = nil
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CARDNADO", despachar({
		CARGA = { sfx = { "ARRANCA", 1 } },
		GOLPE = { faz = function()
			pararTornado()
			geracao = geracao + 1
			local minha = geracao
			local onde = destino or frente(CFG.ALCANCE)
			tornadoOnde = onde
			tornadoId = novoId("TORNADO")
			local id = tornadoId

			vfx("TEMPESTADE", { posicao = onde, raio = CFG.RAIO_TORNADO,
				duracao = CFG.DURACAO, id = id })
			tocarEm("RUGE", onde, 0.9)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				while minha == geracao and os.clock() < ate do
					local centro = tornadoOnde or onde
					local presa = maisPerto(centro, 45)
					local presaRaiz = presa and raizDe(presa)
					if presaRaiz then
						local delta = presaRaiz.Position - centro
						local plano = Vector3.new(delta.X, 0, delta.Z)
						if plano.Magnitude > 1 then
							tornadoOnde = centro + plano.Unit
								* math.min(4, plano.Magnitude)
							vfx("MOVER", { id = id, posicao = tornadoOnde,
								tempo = CFG.PASSO_MOVER })
						end
					end
					for _, alvo in ipairs(alvosEm(tornadoOnde or centro,
							CFG.RAIO_TORNADO, 12)) do
						aplicarDano(alvo, CFG.DANO_TIQUE)
						puxar(alvo, tornadoOnde or centro, CFG.PUXAO, CFG.TIQUE)
					end
					task.wait(CFG.TIQUE)
				end
				if minha == geracao then pararTornado() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Sopro  ·  T — Olho do Furacão  ·  Y — Dispersar
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("SOPRO", despachar({
		CARGA = { sfx = { "FOGO", 1.2 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE_SOPRO)
			vfx("SOPRO", { origem = raiz.Position + Vector3.new(0, 2, 0),
				destino = ponto })
			tocarEm("FOGO", ponto, 1.1)
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_SOPRO, 10)) do
				aplicarDano(alvo, CFG.DANO_SOPRO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (ponto - raiz.Position).Unit
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.3)
				end
			end
		end },
	}), function() ocupado = false end)
end

local function fecharOlho()
	if olhoId then
		vfx("APAGAR", { id = olhoId })
		olhoId = nil
	end
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("OLHO", despachar({
		CARGA = { sfx = { "OLHO", 0.85 } },
		GOLPE = { faz = function()
			fecharOlho()
			olhoId = novoId("OLHO")
			local centro = destino or frente(CFG.ALCANCE)
			local meu = olhoId
			vfx("ONDA_CHAO", { posicao = centro, raio = CFG.RAIO_OLHO,
				duracao = CFG.DURACAO_OLHO, id = meu })
			tocarEm("OLHO", centro, 0.8)
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_OLHO
				while olhoId == meu and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_OLHO, 12)) do
						afrouxar(alvo, CFG.LENTIDAO, 1.2)
					end
					task.wait(0.9)
				end
				if olhoId == meu then fecharOlho() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Dispersar CONSOME o tornado: sem um de pé sai com metade. A Tool nunca fica
--- inerte, mas o par certo rende mais.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISPERSAR", despachar({
		CARGA = { sfx = { "RUGE", 0.8 } },
		GOLPE = { faz = function()
			local centro = tornadoOnde or frente(CFG.ALCANCE)
			local cheio = tornadoOnde ~= nil
			pararTornado()
			vfx("TEMPESTADE", { posicao = centro, raio = CFG.RAIO_DISPERSA })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("ARRANCA", centro, 0.7)
			local dano = cheio and CFG.DANO_DISPERSA or CFG.DANO_DISPERSA * 0.5
			golpearArea(centro, CFG.RAIO_DISPERSA, CFG.RAIO_DISPERSA * 0.4,
				dano, dano * 0.5, 70, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tpararTornado()\n\tfecharOlho()\n")


T("Xester Teleporte", "Forma1",
  objeto="XesterTeleporte_Server_V1", sufixo="XesterTeleporte",
  arquetipo="ESPECTRAL", alcance_mira=60,
  rotulo_m1="teleporte", rotulo_r="Marcar",
  rotulo_t="Voltar", rotulo_y="Corrente",
  origem=["Forma 1 — SOME · MARCA · VOLTA · CORRENTE"],
  cfg="""	ALCANCE       = 55,
	RECARGA       = 5,

	RECARGA_R     = 8,
	DURACAO_MARCA = 25,

	RECARGA_T     = 10,

	RECARGA_Y     = 22,
	SALTOS        = 3,
	PASSO_SALTO   = 0.16,
	RAIO_CORTE    = 7,
	DANO_CORTE    = 26,""",
  estado="local marcaOnde = nil\nlocal marcaId = nil",
  corpo='''
--''' + R + '''
-- M1 — o teleporte
--
-- Mexer no `CFrame` do PRÓPRIO personagem é permitido: o que a regra proíbe é
-- o servidor mover geometria por quadro, e isto é um salto único.
--''' + R + '''

local function saltar(onde)
	if not (raiz and raiz.Parent) then return end
	local saida = raiz.Position
	vfx("FANTASMA", { posicao = saida })
	tocarEm("SOME", saida, 1)
	raiz.CFrame = CFrame.new(onde + Vector3.new(0, 3, 0),
		onde + raiz.CFrame.LookVector)
	vfx("FANTASMA", { posicao = onde })
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TELEPORTE", despachar({
		CARGA = { sfx = { "SOME", 1.2 } },
		GOLPE = { faz = function()
			local alvo = destino or frente(CFG.ALCANCE)
			local delta = alvo - raiz.Position
			if delta.Magnitude > CFG.ALCANCE then
				alvo = raiz.Position + delta.Unit * CFG.ALCANCE
			end
			saltar(alvo)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Marcar  ·  T — Voltar  ·  Y — Corrente de saltos
--
-- Marcar e Voltar são um par: a marca dura 25 s, e voltar é a saída de
-- emergência. Sem marca, o Voltar não faz nada — e avisa com som, em vez de
-- gastar a recarga em silêncio.
--''' + R + '''

local function apagarMarca()
	if marcaId then
		vfx("APAGAR", { id = marcaId })
		marcaId = nil
	end
	marcaOnde = nil
end

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("MARCAR", despachar({
		CARGA = { sfx = { "MARCA", 1.15 } },
		GOLPE = { faz = function()
			apagarMarca()
			marcaOnde = raiz.Position
			marcaId = novoId("MARCA")
			vfx("PORTAL_ABRE", { posicao = marcaOnde,
				duracao = CFG.DURACAO_MARCA, id = marcaId })
			tocarEm("MARCA", marcaOnde, 1.1)
			local meu = marcaId
			task.delay(CFG.DURACAO_MARCA, function()
				if marcaId == meu then apagarMarca() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("VOLTAR", despachar({
		CARGA = { sfx = { "VOLTA", 1.3 } },
		GOLPE = { faz = function()
			if not marcaOnde then
				tocar("VOLTA", 0.7)
				return
			end
			local onde = marcaOnde
			apagarMarca()
			saltar(onde)
			vfx("PORTAL_COLAPSA", { posicao = onde })
		end },
	}), function() ocupado = false end)
end

function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CORRENTE", despachar({
		CARGA = { sfx = { "CORRENTE", 1.25 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			local jaPagos = {}
			task.spawn(function()
				for _ = 1, CFG.SALTOS do
					if not (raiz and raiz.Parent) then break end
					local presa, dist = nil, math.huge
					for _, cand in ipairs(alvosEm(ponto, CFG.ALCANCE, 12)) do
						local candRaiz = raizDe(cand)
						if candRaiz and not jaPagos[cand] then
							local d = (candRaiz.Position - raiz.Position).Magnitude
							if d < dist then presa, dist = cand, d end
						end
					end
					local presaRaiz = presa and raizDe(presa)
					if not presaRaiz then break end
					jaPagos[presa] = true
					local atras = presaRaiz.Position
						- presaRaiz.CFrame.LookVector * 4
					saltar(atras)
					vfx("CORTE_PORTAL", { posicao = presaRaiz.Position })
					tocarEm("CORRENTE", presaRaiz.Position, 1.2)
					for _, perto in ipairs(alvosEm(presaRaiz.Position,
							CFG.RAIO_CORTE, 5)) do
						aplicarDano(perto, CFG.DANO_CORTE)
					end
					task.wait(CFG.PASSO_SALTO)
				end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tapagarMarca()\n")


T("Xester Carta Colossal", "Forma1",
  objeto="XesterCartaColossal_Server_V1", sufixo="XesterColossal",
  arquetipo="EXPLOSIVO", alcance_mira=55,
  rotulo_m1="carta colossal", rotulo_r="Muralha",
  rotulo_t="Guilhotina", rotulo_y="Baralho Colossal",
  origem=["Forma 1 — ERGUE · BATE · FOGO · MURALHA"],
  cfg="""	ALCANCE       = 40,
	QUEDA         = 0.75,
	RAIO          = 15,
	NUCLEO        = 6,
	DANO          = 54,
	BORDA         = 27,
	EMPURRAO      = 78,
	TOMBO         = 1.9,
	RECARGA       = 8,

	RECARGA_R     = 13,
	DURACAO_MURO  = 8,
	RAIO_MURO     = 10,
	LENTIDAO      = 0.4,

	RECARGA_T     = 11,
	ALCANCE_CORTE = 34,
	RAIO_CORTE    = 6,
	DANO_CORTE    = 38,

	RECARGA_Y     = 28,
	CARTAS        = 3,
	PASSO         = 0.3,""",
  estado="local muroId = nil",
  corpo='''
--''' + R + '''
-- A CARTA COLOSSAL — a espera é a mecânica
--
-- 0.75 s entre a conjuração e a queda. Dá para sair de baixo, e é o que separa
-- isto de um dano instantâneo em área.
--''' + R + '''

local function cairCarta(onde, dano, borda)
	vfx("CARTA_ERGUE", { posicao = onde, queda = CFG.QUEDA })
	tocarEm("ERGUE", onde, 0.9)
	task.delay(CFG.QUEDA, function()
		vfx("CARTA_DESABA", { posicao = onde, raio = CFG.RAIO })
		vfx("ONDA_CHAO", { posicao = onde, raio = CFG.RAIO })
		tocarEm("BATE", onde, 0.8)
		golpearArea(onde, CFG.RAIO, CFG.NUCLEO, dano, borda,
			CFG.EMPURRAO, CFG.TOMBO)
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COLOSSAL", despachar({
		CARGA = { sfx = { "ERGUE", 0.85 } },
		GOLPE = { faz = function()
			cairCarta(destino or frente(CFG.ALCANCE), CFG.DANO, CFG.BORDA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Muralha  ·  T — Guilhotina  ·  Y — Baralho Colossal
--''' + R + '''

local function derrubarMuro()
	if muroId then
		vfx("APAGAR", { id = muroId })
		muroId = nil
	end
end

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MURALHA", despachar({
		CARGA = { sfx = { "MURALHA", 0.8 } },
		GOLPE = { faz = function()
			derrubarMuro()
			muroId = novoId("MURO")
			local onde = destino or frente(CFG.ALCANCE * 0.4)
			local meu = muroId
			vfx("CARTA_CHAO", { posicao = onde, duracao = CFG.DURACAO_MURO,
				id = meu })
			tocarEm("MURALHA", onde, 0.85)
			-- a muralha não bloqueia de verdade: ela ATRASA quem atravessa.
			-- Parte sólida no caminho de jogador é o tipo de coisa que prende
			-- gente em canto de mapa.
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_MURO
				while muroId == meu and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_MURO, 10)) do
						afrouxar(alvo, CFG.LENTIDAO, 1.2)
					end
					task.wait(0.9)
				end
				if muroId == meu then derrubarMuro() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("GUILHOTINA", despachar({
		CARGA = { sfx = { "FOGO", 1.3 } },
		GOLPE = { faz = function()
			local base = raiz.Position
			local dir = ((destino or frente(CFG.ALCANCE_CORTE)) - base)
			if dir.Magnitude < 1 then dir = raiz.CFrame.LookVector end
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
			for i = 1, 5 do
				local onde = base + dir * (i * CFG.ALCANCE_CORTE / 5)
				task.delay((i - 1) * 0.05, function()
					vfx("CORTE_PORTAL", { posicao = onde })
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_CORTE, 6)) do
						aplicarDano(alvo, CFG.DANO_CORTE)
					end
				end)
			end
			tocarEm("FOGO", base + dir * 8, 1.2)
		end },
	}), function() ocupado = false end)
end

function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("BARALHO", despachar({
		CARGA = { sfx = { "ERGUE", 0.7 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			task.spawn(function()
				for i = 1, CFG.CARTAS do
					if not (raiz and raiz.Parent) then break end
					local a = i * 2.399963
					cairCarta(centro + Vector3.new(math.cos(a), 0, math.sin(a)) * 9,
						CFG.DANO * 0.7, CFG.BORDA * 0.7)
					task.wait(CFG.PASSO)
				end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tderrubarMuro()\n")


T("Xester Buraco Negro", "Forma1",
  objeto="XesterBuracoNegro_Server_V1", sufixo="XesterBuraco",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_m1="buraco que puxa", rotulo_r="Colapso",
  rotulo_t="Horizonte", rotulo_y="Ejecao",
  origem=["Forma 1 — ABRE · COLAPSA · RAIO · EJETA"],
  cfg="""	ALCANCE       = 45,
	RAIO_BURACO   = 18,
	DURACAO       = 6,
	TIQUE         = 0.6,
	PUXAO         = 52,
	DANO_TIQUE    = 9,
	RECARGA       = 18,

	RECARGA_R     = 12,
	RAIO_COLAPSO  = 16,
	NUCLEO        = 6,
	DANO_COLAPSO  = 56,
	BORDA_COLAPSO = 28,
	TOMBO         = 2,

	RECARGA_T     = 14,
	RAIO_HORIZONTE = 20,
	DURACAO_HORIZ = 7,
	LENTIDAO      = 0.35,

	RECARGA_Y     = 20,
	RAIO_EJECAO   = 18,
	DANO_EJECAO   = 34,
	EMPURRAO      = 120,""",
  estado=("local buracoId = nil\nlocal buracoOnde = nil\n"
          "local horizonteId = nil\nlocal geracao = 0"),
  corpo='''
--''' + R + '''
-- O BURACO — puxa por tique, e o par com o Colapso é o jogo
--
-- Ele sozinho quase não fere: 9 por tique. O que ele faz é JUNTAR. Quem abre o
-- buraco e depois usa o Colapso pega todo mundo no núcleo.
--''' + R + '''

local function fecharBuraco()
	geracao = geracao + 1
	if buracoId then
		vfx("APAGAR", { id = buracoId })
		buracoId = nil
	end
	buracoOnde = nil
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("BURACO", despachar({
		CARGA = { sfx = { "ABRE", 0.75 } },
		GOLPE = { faz = function()
			fecharBuraco()
			geracao = geracao + 1
			local minha = geracao
			local onde = destino or frente(CFG.ALCANCE)
			buracoOnde = onde
			buracoId = novoId("BURACO")
			local id = buracoId

			vfx("PORTAL_ABRE", { posicao = onde, raio = CFG.RAIO_BURACO,
				duracao = CFG.DURACAO, id = id })
			tocarEm("ABRE", onde, 0.7)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				while minha == geracao and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_BURACO, 14)) do
						aplicarDano(alvo, CFG.DANO_TIQUE)
						puxar(alvo, onde, CFG.PUXAO, CFG.TIQUE)
					end
					task.wait(CFG.TIQUE)
				end
				if minha == geracao then fecharBuraco() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Colapso  ·  T — Horizonte  ·  Y — Ejeção
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("COLAPSO", despachar({
		CARGA = { sfx = { "COLAPSA", 0.8 } },
		GOLPE = { faz = function()
			local centro = buracoOnde or frente(CFG.ALCANCE)
			local cheio = buracoOnde ~= nil
			fecharBuraco()
			vfx("PORTAL_COLAPSA", { posicao = centro, raio = CFG.RAIO_COLAPSO })
			tocarEm("COLAPSA", centro, 0.75)
			local dano = cheio and CFG.DANO_COLAPSO or CFG.DANO_COLAPSO * 0.55
			golpearArea(centro, CFG.RAIO_COLAPSO, CFG.NUCLEO,
				dano, dano * 0.5, 60, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end

local function fecharHorizonte()
	if horizonteId then
		vfx("APAGAR", { id = horizonteId })
		horizonteId = nil
	end
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("HORIZONTE", despachar({
		CARGA = { sfx = { "RAIO", 0.9 } },
		GOLPE = { faz = function()
			fecharHorizonte()
			horizonteId = novoId("HORIZONTE")
			local onde = destino or frente(CFG.ALCANCE)
			local meu = horizonteId
			vfx("ONDA_CHAO", { posicao = onde, raio = CFG.RAIO_HORIZONTE,
				duracao = CFG.DURACAO_HORIZ, id = meu })
			tocarEm("RAIO", onde, 0.85)
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_HORIZ
				while horizonteId == meu and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_HORIZONTE, 14)) do
						afrouxar(alvo, CFG.LENTIDAO, 1.2)
					end
					task.wait(0.9)
				end
				if horizonteId == meu then fecharHorizonte() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Ejeção: o contrário do buraco. Ele CUSPE — e é a saída de quem foi cercado.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("EJECAO", despachar({
		CARGA = { sfx = { "EJETA", 1.2 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("PORTAL_COLAPSA", { posicao = centro, raio = CFG.RAIO_EJECAO })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("EJETA", centro, 1.15)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_EJECAO, 14)) do
				aplicarDano(alvo, CFG.DANO_EJECAO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.7, 0), CFG.EMPURRAO, 0.32)
				end
			end
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tfecharBuraco()\n\tfecharHorizonte()\n")


T("Xester Escudo de Cartas", "Forma1",
  objeto="XesterEscudodeCartas_Server_V1", sufixo="XesterEscudo",
  arquetipo="SUPORTE", alcance_mira=40,
  rotulo_m1="escudo orbital", rotulo_r="Rebater",
  rotulo_t="Estilhacar", rotulo_y="Baralho Blindado",
  origem=["Forma 1 — SOBE · REBATE · ESTILHACA · SOPRO"],
  cfg="""	DURACAO_ESCUDO = 10,
	RAIO_ESCUDO   = 7,
	TIQUE         = 0.8,
	DANO_TIQUE    = 8,
	RECARGA       = 14,

	RECARGA_R     = 9,
	RAIO_REBATE   = 9,
	DANO_REBATE   = 30,
	EMPURRAO      = 76,

	RECARGA_T     = 12,
	RAIO_ESTILHACO = 16,
	DANO_ESTILHACO = 44,
	TOMBO         = 1.4,

	RECARGA_Y     = 24,
	RAIO_ALIADO   = 22,
	ESCUDO_ALIADO = 5,""",
  estado="local escudoId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- O ESCUDO — cartas em órbita que ferem quem encosta
--
-- Ele segue o portador por `MOVER`, um tique de 0.8 s. Não é parte sólida:
-- escudo sólido em volta de jogador empurra gente para dentro de parede.
--''' + R + '''

local function baixarEscudo()
	geracao = geracao + 1
	if escudoId then
		vfx("APAGAR", { id = escudoId })
		escudoId = nil
	end
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("ESCUDO", despachar({
		CARGA = { sfx = { "SOBE", 1 } },
		GOLPE = { faz = function()
			baixarEscudo()
			geracao = geracao + 1
			local minha = geracao
			escudoId = novoId("ESCUDO")
			local id = escudoId
			vfx("ESCUDO_SOBE", { posicao = raiz.Position,
				duracao = CFG.DURACAO_ESCUDO, id = id })
			tocarEm("SOBE", raiz.Position, 1)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ESCUDO
				while minha == geracao and os.clock() < ate do
					if not (raiz and raiz.Parent) then break end
					vfx("MOVER", { id = id, posicao = raiz.Position,
						tempo = CFG.TIQUE })
					for _, alvo in ipairs(alvosEm(raiz.Position,
							CFG.RAIO_ESCUDO, 10)) do
						aplicarDano(alvo, CFG.DANO_TIQUE)
					end
					task.wait(CFG.TIQUE)
				end
				if minha == geracao then baixarEscudo() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Rebater  ·  T — Estilhaçar  ·  Y — Baralho Blindado
--
-- Estilhaçar CONSOME o escudo, e por isso dobra sem escudo de pé — não: SEM
-- escudo ele sai pela metade. O par certo é subir o escudo e estilhaçar depois.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("REBATER", despachar({
		CARGA = { sfx = { "REBATE", 1.1 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("ESCUDO_REBATE", { posicao = centro })
			tocarEm("REBATE", centro, 1.05)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_REBATE, 10)) do
				aplicarDano(alvo, CFG.DANO_REBATE)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - centro)
						+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.28)
				end
			end
		end },
	}), function() ocupado = false end)
end

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("ESTILHACAR", despachar({
		CARGA = { sfx = { "ESTILHACA", 1.15 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			local cheio = escudoId ~= nil
			baixarEscudo()
			vfx("ESCUDO_ESTILHACA", { posicao = centro,
				raio = CFG.RAIO_ESTILHACO })
			tocarEm("ESTILHACA", centro, 1.1)
			local dano = cheio and CFG.DANO_ESTILHACO
				or CFG.DANO_ESTILHACO * 0.5
			golpearArea(centro, CFG.RAIO_ESTILHACO, CFG.RAIO_ESTILHACO * 0.4,
				dano, dano * 0.5, 58, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end

--- Blindado: o escudo vai para os ALIADOS. `ForceField` com prazo — o
--- `TakeDamage` respeita ForceField, então o Núcleo já entende sozinho.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("BLINDADO", despachar({
		CARGA = { sfx = { "SOPRO", 0.9 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("ESCUDO_SOBE", { posicao = centro, duracao = CFG.ESCUDO_ALIADO })
			tocarEm("SOPRO", centro, 0.85)
			for _, amigo in ipairs(aliadosEm(centro, CFG.RAIO_ALIADO)) do
				local corpo = amigo.Parent
				if corpo and not corpo:FindFirstChildOfClass("ForceField") then
					local campo = Instance.new("ForceField")
					campo.Visible = true
					campo.Parent = corpo
					Debris:AddItem(campo, CFG.ESCUDO_ALIADO)
					local amigoRaiz = corpo:FindFirstChild("HumanoidRootPart")
					if amigoRaiz then
						vfx("ESCUDO_SOBE", { posicao = amigoRaiz.Position,
							duracao = CFG.ESCUDO_ALIADO })
					end
				end
			end
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tbaixarEscudo()\n")


# ═══════════════════════════════════════════════════════════════
# FORMA 2 — O DESPERTAR
#
# Cajado, machado e invocação. Números maiores, recarga longa. As sete M1 são
# as da origem, mecânica por mecânica; o que mudou foi o que a origem fazia de
# proibido — `Health =`, `BreakJoints`, `Foe:Destroy()`, `math.random`, e o
# `ws = 120` que ficava para sempre.
# ═══════════════════════════════════════════════════════════════

T("Xester Carta Ceifeira", "Forma2",
  objeto="XesterCartaCeifeira_Server_V1", sufixo="XesterCeifeira",
  arquetipo="CEIFA", alcance_mira=55,
  rotulo_m1="tres cartas que perseguem", rotulo_r="Ceifar",
  rotulo_t="Marca", rotulo_y="Colheita",
  origem=["Forma 2 — cartas do `cards`, cajado do `staff`",
          "SAI · CRAVA · CEIFA · COLHEITA, os quatro do `xesterv2`"],
  cfg="""	ALCANCE       = 55,
	CARTAS        = 3,
	INTERVALO     = 0.12,
	VOO           = 0.35,
	SAIDA         = 3,
	ESPALHA       = 4,
	RAIO          = 8,
	NUCLEO        = 3,
	DANO          = 26,
	BORDA         = 13,
	EMPURRAO      = 40,
	RECARGA       = 7,

	RECARGA_R     = 11,
	FRENTE_CEIFA  = 9,
	RAIO_CEIFA    = 11,
	NUCLEO_CEIFA  = 5,
	DANO_CEIFA    = 48,
	BORDA_CEIFA   = 24,
	TOMBO         = 1.4,

	RECARGA_T     = 13,
	ALCANCE_MARCA = 55,
	DURACAO_MARCA = 9,
	BONUS_MARCA   = 1.6,
	LENTIDAO      = 0.6,

	RECARGA_Y     = 24,
	RAIO_COLHEITA = 22,
	NUCLEO_COLH   = 8,
	DANO_COLHEITA = 58,
	BORDA_COLHEITA = 29,
	PUXAO         = 66,""",
  estado=("local marcado = nil\nlocal marcaAte = 0\n"
          "local marcaId = nil"),
  corpo='''
--''' + R + '''
-- A MARCA — o multiplicador mora aqui, e vale para as três outras
--
-- `marcado` é um Humanoid, não um nome nem um caminho: se o alvo morre ou sai,
-- a referência ainda existe mas `Health <= 0` derruba o bônus sozinho. O prazo
-- é `os.clock()`, nunca `tick()`.
--''' + R + '''

local function marcaViva()
	if not marcado then return false end
	if marcado.Health <= 0 then return false end
	if os.clock() > marcaAte then return false end
	return true
end

local function limparMarca()
	if marcaId then
		vfx("APAGAR", { id = marcaId })
		marcaId = nil
	end
	marcado = nil
	marcaAte = 0
end

--- O dano com o bônus da marca já aplicado. Uma porta só: se um dia o bônus
--- mudar, muda aqui, e as quatro habilidades acompanham.
local function ceifar(alvo, bruto)
	if marcaViva() and alvo == marcado then
		return aplicarDano(alvo, bruto * CFG.BONUS_MARCA)
	end
	return aplicarDano(alvo, bruto)
end

local function estourarEm(onde, raio, nucleo, danoNucleo, danoBorda, forca)
	for _, alvo in ipairs(alvosEm(onde, raio, 12)) do
		local alvoRaiz = raizDe(alvo)
		local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude or raio
		if d <= nucleo then
			ceifar(alvo, danoNucleo)
		else
			ceifar(alvo, danoBorda)
		end
		if alvoRaiz and forca then
			empurrar(alvo, (alvoRaiz.Position - onde) + Vector3.new(0, 0.5, 0),
				forca, 0.28)
		end
	end
end

--''' + R + '''
-- M1 — três cartas ceifeiras
--
-- A mecânica é a da origem: três cartas saem acima do ombro, espalham em volta
-- do ponto mirado e estouram ao chegar. O espalhamento era `math.random` lá;
-- aqui é o ângulo áureo, para todos os clientes desenharem o mesmo leque.
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CEIFEIRA", despachar({
		CARGA = { sfx = { "SAI", 1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ponto = destino or frente(CFG.ALCANCE)
			local origem = raiz.Position + Vector3.new(0, CFG.SAIDA, 0)
			local i = 1
			while i <= CFG.CARTAS do
				local indice = i
				task.delay(indice * CFG.INTERVALO, function()
					if not (personagem and raiz) then return end
					local ang = indice * 2.399963
					local chegada = ponto + Vector3.new(
						math.cos(ang) * CFG.ESPALHA, 0,
						math.sin(ang) * CFG.ESPALHA)
					vfx("CEIFEIRA_VOA", { origem = origem, destino = chegada,
						voo = CFG.VOO })
					task.delay(CFG.VOO, function()
						if not personagem then return end
						vfx("CEIFEIRA_ESTOURA", { posicao = chegada })
						tocarEm("CRAVA", chegada, 0.95)
						estourarEm(chegada, CFG.RAIO, CFG.NUCLEO, CFG.DANO,
							CFG.BORDA, CFG.EMPURRAO)
					end)
				end)
				i = i + 1
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Ceifar  ·  T — Marca  ·  Y — Colheita
--''' + R + '''

--- Corte largo à frente. É o único golpe corpo a corpo da Tool, e o que fecha
--- a distância que as cartas abrem.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("CEIFAR", despachar({
		CARGA  = { sfx = { "CEIFA", 0.85 } },
		SEGURA = { sfx = { "SAI", 1.2 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local onde = raiz.Position
				+ raiz.CFrame.LookVector * CFG.FRENTE_CEIFA
			vfx("MACHADO_CORTA", { posicao = onde })
			vfx("CEIFEIRA_ESTOURA", { posicao = onde })
			tocarEm("CEIFA", onde, 0.9)
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_CEIFA, 14)) do
				local alvoRaiz = raizDe(alvo)
				local d = alvoRaiz and (alvoRaiz.Position - onde).Magnitude
					or CFG.RAIO_CEIFA
				if d <= CFG.NUCLEO_CEIFA then
					ceifar(alvo, CFG.DANO_CEIFA)
					tombar(alvo, CFG.TOMBO)
				else
					ceifar(alvo, CFG.BORDA_CEIFA)
					tombar(alvo, CFG.TOMBO * 0.5)
				end
			end
		end },
	}), function() ocupado = false end)
end

--- Marca o alvo mirado. Não fere: só faz doer mais, e mais devagar.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MARCA", despachar({
		CARGA = { sfx = { "COLHEITA", 1.25 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_MARCA),
				CFG.ALCANCE_MARCA)
			if not alvo then
				tocar("COLHEITA", 0.9)
				return
			end
			limparMarca()
			marcado = alvo
			marcaAte = os.clock() + CFG.DURACAO_MARCA
			marcaId = novoId("MARCA")
			local alvoRaiz = raizDe(alvo)
			local onde = alvoRaiz and alvoRaiz.Position or frente(10)
			vfx("CARTA_CHAO", { posicao = onde, duracao = CFG.DURACAO_MARCA,
				id = marcaId })
			tocarEm("COLHEITA", onde, 1.2)
			afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_MARCA)
			task.delay(CFG.DURACAO_MARCA, function()
				if marcado == alvo then limparMarca() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Colheita: puxa tudo para o centro e ceifa. Com a marca de pé, o marcado
--- entra no núcleo, e é ali que o bônus paga.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COLHEITA", despachar({
		CARGA  = { sfx = { "CEIFA", 0.75 } },
		SEGURA = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("PORTAL_ABRE", { posicao = centro, raio = CFG.RAIO_COLHEITA,
				duracao = 0.6 })
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_COLHEITA, 16)) do
				puxar(alvo, centro, CFG.PUXAO, 0.5)
			end
		end },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("CEIFEIRA_ESTOURA", { posicao = centro })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("COLHEITA", centro, 0.75)
			estourarEm(centro, CFG.RAIO_COLHEITA, CFG.NUCLEO_COLH,
				CFG.DANO_COLHEITA, CFG.BORDA_COLHEITA, nil)
			limparMarca()
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tlimparMarca()\n")


T("Xester Esfera do Fim", "Forma2",
  objeto="XesterEsferadoFim_Server_V1", sufixo="XesterEsfera",
  arquetipo="ARCANO", alcance_mira=45,
  rotulo_m1="esfera que suga e detona", rotulo_r="Orbita",
  rotulo_t="Compressao", rotulo_y="O Fim",
  origem=["Forma 2 — `energb` e `staff`",
          "CARREGA · DETONA · ECO · ORBITA, os quatro do `xesterv2`"],
  cfg="""	CARGA         = 0.5,
	RAIO_SUGA     = 22,
	SUCCAO        = 46,
	RASPAO        = 5,
	PULSOS_CARGA  = 4,
	AVANCO        = 7,
	RAIO          = 16,
	NUCLEO        = 6,
	DANO          = 52,
	BORDA         = 26,
	EMPURRAO      = 88,
	TOMBO         = 1.6,
	RECARGA       = 14,

	RECARGA_R     = 13,
	ORBITAS       = 3,
	RAIO_ORBITA   = 9,
	DURACAO_ORB   = 6,
	PASSO_ORB     = 0.45,
	RAIO_TOQUE    = 6,
	DANO_ORBITA   = 11,

	RECARGA_T     = 16,
	RAIO_COMPRIME = 18,
	DURACAO_COMP  = 4.5,
	PASSO_COMP    = 0.5,
	LENTIDAO      = 0.35,
	DANO_COMPRIME = 7,

	RECARGA_Y     = 30,
	ALCANCE_FIM   = 45,
	RAIO_FIM      = 26,
	NUCLEO_FIM    = 9,
	DANO_FIM      = 78,
	BORDA_FIM     = 38,
	EMPURRAO_FIM  = 130,
	TOMBO_FIM     = 2.4,""",
  estado="local orbitaId = nil\nlocal compressaoId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — a Esfera do Fim
--
-- A origem prendia a carga num `repeat ... until charging == false` amarrado ao
-- `Button1Up` do cliente: soltar o botão fora da tela deixava a sucção rodando
-- para sempre. Aqui a carga é o próprio compasso da animação — `CARGA` liga a
-- sucção, `SEGURA` a mantém, `GOLPE` detona. Não existe caminho em que ela
-- fique ligada.
--''' + R + '''

local sugando = false

local function sugar()
	if not (personagem and raiz) then return end
	for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_SUGA, 12)) do
		aplicarDano(alvo, CFG.RASPAO)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, raiz.Position - alvoRaiz.Position, CFG.SUCCAO, 0.22)
		end
	end
end

--- `ECO` é RÉPLICA, não segunda explosão: chega depois, mais grave, e não
--- carrega dano nenhum. Quem fere é o `DETONA`, que já saiu no beat.
local function detonar(centro, raio, nucleo, danoNucleo, danoBorda, forca, tombo)
	vfx("ESFERA_DETONA", { posicao = centro, raio = raio })
	tocarEm("DETONA", centro, 0.85)
	golpearArea(centro, raio, nucleo, danoNucleo, danoBorda, forca, tombo)
	task.delay(0.35, function()
		tocarEm("ECO", centro, 0.7)
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("ESFERA", despachar({
		CARGA  = { sfx = { "CARREGA", 1 }, faz = function()
			sugando = true
			vfx("ESFERA_CARREGA", { duracao = CFG.CARGA })
			local i = 1
			while i <= CFG.PULSOS_CARGA do
				task.delay(i * (CFG.CARGA / CFG.PULSOS_CARGA), function()
					if sugando then sugar() end
				end)
				i = i + 1
			end
		end },
		SEGURA = { faz = sugar },
		GOLPE  = { faz = function()
			sugando = false
			if not (raiz and raiz.Parent) then return end
			local centro = raiz.Position + raiz.CFrame.LookVector * CFG.AVANCO
			detonar(centro, CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA,
				CFG.EMPURRAO, CFG.TOMBO)
		end },
		FIM    = { faz = function() sugando = false end },
	}), function()
		ocupado = false
		sugando = false
	end)
end

--''' + R + '''
-- R — Órbita  ·  T — Compressão  ·  Y — O Fim
--''' + R + '''

local function apagarOrbita()
	geracao = geracao + 1
	if orbitaId then
		vfx("APAGAR", { id = orbitaId })
		orbitaId = nil
	end
end

--- Três esferas menores girando em volta do portador. Elas seguem o portador,
--- então o centro é lido A CADA PASSO — guardar a posição de partida deixaria
--- a órbita para trás no primeiro passo dado.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("ORBITA", despachar({
		CARGA = { sfx = { "ORBITA", 1.3 } },
		GOLPE = { faz = function()
			apagarOrbita()
			geracao = geracao + 1
			local minha = geracao
			orbitaId = novoId("ORBITA")
			vfx("ESFERA_CARREGA", { duracao = CFG.DURACAO_ORB,
				raio = CFG.RAIO_ORBITA, id = orbitaId })

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ORB
				local passo = 0
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local centro = raiz.Position
					local i = 1
					while i <= CFG.ORBITAS do
						local ang = passo * 0.9 + i * (math.pi * 2 / CFG.ORBITAS)
						local onde = centro + Vector3.new(
							math.cos(ang) * CFG.RAIO_ORBITA, 1,
							math.sin(ang) * CFG.RAIO_ORBITA)
						vfx("BARALHO_GOLPE", { posicao = onde })
						for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_TOQUE, 6)) do
							aplicarDano(alvo, CFG.DANO_ORBITA)
						end
						i = i + 1
					end
					passo = passo + 1
					task.wait(CFG.PASSO_ORB)
				end
				if minha == geracao then apagarOrbita() end
			end)
		end },
	}), function() ocupado = false end)
end

local function apagarCompressao()
	if compressaoId then
		vfx("APAGAR", { id = compressaoId })
		compressaoId = nil
	end
end

--- Compressão: campo parado que puxa devagar e afrouxa. É controle, não dano —
--- 7 por passo é raspão, e quem entra sai lento.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COMPRESSAO", despachar({
		CARGA  = { sfx = { "CARREGA", 0.8 } },
		SEGURA = { sfx = { "ORBITA", 0.9 } },
		GOLPE  = { faz = function()
			apagarCompressao()
			compressaoId = novoId("COMPRIME")
			local meu = compressaoId
			local onde = destino or frente(CFG.RAIO_COMPRIME)
			vfx("ONDA_CHAO", { posicao = onde, raio = CFG.RAIO_COMPRIME,
				duracao = CFG.DURACAO_COMP, id = meu })
			tocarEm("CARREGA", onde, 0.75)
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_COMP
				while compressaoId == meu and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_COMPRIME, 14)) do
						aplicarDano(alvo, CFG.DANO_COMPRIME)
						afrouxar(alvo, CFG.LENTIDAO, CFG.PASSO_COMP * 2)
						puxar(alvo, onde, 24, CFG.PASSO_COMP)
					end
					task.wait(CFG.PASSO_COMP)
				end
				if compressaoId == meu then apagarCompressao() end
			end)
		end },
	}), function() ocupado = false end)
end

--- O Fim: a detonação inteira, no ponto mirado, e longe do portador.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("FIM", despachar({
		CARGA  = { sfx = { "CARREGA", 0.7 } },
		SEGURA = { sfx = { "ORBITA", 0.7 } },
		GOLPE  = { faz = function()
			local centro = destino or frente(CFG.ALCANCE_FIM)
			vfx("ESFERA_CARREGA", { posicao = centro, duracao = 0.2 })
			detonar(centro, CFG.RAIO_FIM, CFG.NUCLEO_FIM, CFG.DANO_FIM,
				CFG.BORDA_FIM, CFG.EMPURRAO_FIM, CFG.TOMBO_FIM)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tapagarOrbita()\n\tapagarCompressao()\n")


T("Xester Baralho Espectral", "Forma2",
  objeto="XesterBaralhoEspectral_Server_V1", sufixo="XesterBaralho",
  arquetipo="ESPECTRAL", alcance_mira=40,
  rotulo_m1="baralho que gira em volta", rotulo_r="Naipe",
  rotulo_t="Espelho", rotulo_y="Baralho Completo",
  origem=["Forma 2 — cartas do `cards`, cajado do `staff`",
          "CONJURA · GOLPE · NAIPE · ESPELHO, os quatro do `xesterv2`"],
  cfg="""	CONJURA       = 0.4,
	DURACAO       = 5,
	PASSO         = 0.4,
	ORBITA        = 8,
	RAIO          = 6,
	DANO          = 14,
	EMPURRAO      = 26,
	RECARGA       = 10,

	RECARGA_R     = 12,
	NAIPES        = 4,
	ALCANCE_NAIPE = 40,
	PASSOS_NAIPE  = 8,
	ESPACO_NAIPE  = 5,
	RAIO_NAIPE    = 6,
	DANO_NAIPE    = 22,
	INTERVALO     = 0.06,

	RECARGA_T     = 18,
	DURACAO_ESP   = 5,
	PASSO_ESP     = 0.5,
	RAIO_ESPELHO  = 7,
	DANO_ESPELHO  = 16,

	RECARGA_Y     = 26,
	RAIO_COMPLETO = 20,
	NUCLEO_COMP   = 7,
	DANO_COMPLETO = 60,
	BORDA_COMPLETO = 30,
	EMPURRAO_COMP = 96,
	TOMBO         = 1.8,""",
  estado="local baralhoId = nil\nlocal espelhoId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — o baralho espectral
--
-- A mecânica da origem: cartas girando em volta do portador, batendo em quem
-- chega perto. Ela travava `ws = 0` durante a conjuração inteira e devolvia na
-- unha; aqui a trava é `rig:LockCharacter`, que o `desmontar` desfaz sozinho
-- nas DUAS portas — `Unequipped` e `Destroying`.
--''' + R + '''

local function apagarBaralho()
	geracao = geracao + 1
	if baralhoId then
		vfx("APAGAR", { id = baralhoId })
		baralhoId = nil
	end
	if rig then rig:LockCharacter(false) end
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("ESPECTRAL", despachar({
		CARGA = { sfx = { "CONJURA", 1 }, faz = function()
			if rig then rig:LockCharacter(true) end
			vfx("BARALHO_CONJURA", { duracao = CFG.CONJURA })
		end },
		GOLPE = { faz = function()
			apagarBaralho()
			geracao = geracao + 1
			local minha = geracao
			baralhoId = novoId("BARALHO")
			vfx("BARALHO_CONJURA", { duracao = CFG.DURACAO,
				raio = CFG.ORBITA, id = baralhoId })
			tocar("CONJURA", 0.95)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				local passo = 0
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					-- ângulo áureo: cada passo cai num lugar novo, e todos os
					-- clientes veem o mesmo lugar
					local ang = passo * 2.399963
					local onde = raiz.Position + Vector3.new(
						math.cos(ang) * CFG.ORBITA, 1,
						math.sin(ang) * CFG.ORBITA)
					vfx("BARALHO_GOLPE", { posicao = onde })
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 8)) do
						aplicarDano(alvo, CFG.DANO)
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							empurrar(alvo, alvoRaiz.Position - onde,
								CFG.EMPURRAO, 0.2)
						end
					end
					passo = passo + 1
					task.wait(CFG.PASSO)
				end
				if minha == geracao then apagarBaralho() end
			end)
		end },
	}), function()
		ocupado = false
		if rig then rig:LockCharacter(false) end
	end)
end

--''' + R + '''
-- R — Naipe  ·  T — Espelho  ·  Y — Baralho Completo
--''' + R + '''

--- Quatro linhas de carta, uma por naipe, nas quatro direções do portador. Não
--- é um leque à frente: é uma cruz, e serve para quem está cercado.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("NAIPE", despachar({
		CARGA = { sfx = { "NAIPE", 1.2 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local frenteDir = raiz.CFrame.LookVector
			local ladoDir = raiz.CFrame.RightVector
			local direcoes = {
				frenteDir, -frenteDir, ladoDir, -ladoDir,
			}
			tocarEm("NAIPE", origem, 1.15)
			local n = 1
			while n <= CFG.NAIPES do
				local direcao = direcoes[n]
				local i = 1
				while i <= CFG.PASSOS_NAIPE do
					local indice = i
					task.delay(indice * CFG.INTERVALO, function()
						if not personagem then return end
						local onde = origem
							+ direcao * (indice * CFG.ESPACO_NAIPE)
						vfx("CARTA_VOA", { origem = origem, destino = onde })
						for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_NAIPE, 6)) do
							aplicarDano(alvo, CFG.DANO_NAIPE)
						end
					end)
					i = i + 1
				end
				n = n + 1
			end
		end },
	}), function() ocupado = false end)
end

local function apagarEspelho()
	if espelhoId then
		vfx("APAGAR", { id = espelhoId })
		espelhoId = nil
	end
end

--- Espelho: casca espectral colada no portador. Ela DEVOLVE — quem encosta
--- toma. O `ForceField` com prazo é quem segura o outro lado, e o `TakeDamage`
--- do Núcleo já o respeita sozinho.
function extraT(_mira)
	ocupado = true
	rig:PlaySequence("ESPELHO", despachar({
		CARGA  = { sfx = { "ESPELHO", 1.05 } },
		SEGURA = { sfx = { "CONJURA", 1.2 } },
		GOLPE  = { faz = function()
			apagarEspelho()
			espelhoId = novoId("ESPELHO")
			local meu = espelhoId
			vfx("ESCUDO_SOBE", { posicao = raiz.Position,
				duracao = CFG.DURACAO_ESP, id = meu })
			tocar("ESPELHO", 1)

			if personagem and not personagem:FindFirstChildOfClass("ForceField") then
				local campo = Instance.new("ForceField")
				campo.Visible = true
				campo.Parent = personagem
				Debris:AddItem(campo, CFG.DURACAO_ESP)
			end

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ESP
				while espelhoId == meu and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local centro = raiz.Position
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ESPELHO, 10)) do
						aplicarDano(alvo, CFG.DANO_ESPELHO)
						vfx("BARALHO_GOLPE", { posicao = centro })
					end
					task.wait(CFG.PASSO_ESP)
				end
				if espelhoId == meu then apagarEspelho() end
			end)
		end },
	}), function() ocupado = false end)
end

--- O baralho inteiro fecha de uma vez. É a única das quatro com núcleo e
--- borda: um estouro grande sem borda mataria quem só passava perto.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("COMPLETO", despachar({
		CARGA  = { sfx = { "CONJURA", 0.8 } },
		SEGURA = { sfx = { "NAIPE", 0.85 } },
		GOLPE  = { faz = function()
			local centro = raiz.Position
			apagarBaralho()
			vfx("BARALHO_GOLPE", { posicao = centro })
			vfx("ONDA_DUPLA", { posicao = centro })
			vfx("CEIFEIRA_ESTOURA", { posicao = centro })
			tocarEm("GOLPE", centro, 0.85)
			golpearArea(centro, CFG.RAIO_COMPLETO, CFG.NUCLEO_COMP,
				CFG.DANO_COMPLETO, CFG.BORDA_COMPLETO, CFG.EMPURRAO_COMP,
				CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tapagarBaralho()\n\tapagarEspelho()\n")


T("Xester Invocacao", "Forma2",
  objeto="XesterInvocacao_Server_V1", sufixo="XesterInvocacao",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_m1="chama um servo", rotulo_r="Comandar",
  rotulo_t="Legiao", rotulo_y="Dispensar",
  origem=["Forma 2 — `enemy` e `skully`, PODADOS: os scripts `ai` e `core`",
          "da origem não vieram junto",
          "CHAMA · NASCE · COMANDA · LEGIAO, os quatro do `xesterv2`"],
  cfg="""	ALCANCE       = 55,
	LIMITE        = 4,
	VIDA          = 22,
	PASSO         = 0.5,
	VELOCIDADE    = 18,
	VISAO         = 30,
	ALCANCE_GOLPE = 5,
	DANO          = 12,
	RECARGA       = 9,

	RECARGA_R     = 10,
	RAIO_COMANDO  = 10,
	DANO_COMANDO  = 24,
	EMPURRAO      = 44,

	RECARGA_T     = 26,
	LEGIAO        = 3,
	ANEL_LEGIAO   = 7,

	RECARGA_Y     = 16,
	RAIO_DISPENSA = 12,
	NUCLEO_DISP   = 5,
	DANO_DISPENSA = 42,
	BORDA_DISPENSA = 21,
	EMPURRAO_DISP = 70,
	TOMBO         = 1.5,""",
  estado="local servos = {}",
  corpo='''
--''' + R + '''
-- O SERVO — molde da própria Tool, e SEM script nenhum
--
-- A origem clonava `enemy` com os scripts `ai` e `core` ligados. Script de
-- terceiro rodando com vida própria dentro de uma Tool é o oposto da
-- autocontenção: ele lê o mundo, e ninguém sabe o que mais faz. O
-- `preparar_xester.py` poda os scripts do molde, e a perseguição é escrita
-- aqui, neste Server, que é filho da Tool.
--''' + R + '''

local function moldeDe(nome)
	local pasta = Tool:FindFirstChild("Moldes")
	local achado = pasta and pasta:FindFirstChild(nome)
	return achado
end

local function porNoMundo(nome, cframe, vida)
	local base = moldeDe(nome)
	if not base then return nil end
	local copia = base:Clone()
	if copia:IsA("Model") then
		if not copia.PrimaryPart then
			local qualquer = copia:FindFirstChildWhichIsA("BasePart", true)
			if qualquer then copia.PrimaryPart = qualquer end
		end
		if copia.PrimaryPart then copia:PivotTo(cframe) end
	elseif copia:IsA("BasePart") then
		copia.CFrame = cframe
	end
	copia.Parent = workspace
	Debris:AddItem(copia, vida)
	return copia
end

--- Servo NÃO é alvo. `alvosEm` só sabe tirar o portador da conta; sem este
--- filtro os servos bateriam uns nos outros, e a Dispensar mataria os próprios
--- invocados antes de estourar.
local function hostisEm(posicao, raio, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(posicao, raio, (limite or 12) + CFG.LIMITE)) do
		local corpo = alvo.Parent
		if corpo and corpo.Name ~= "ServoDoXester" then
			table.insert(achados, alvo)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

local function esquecer(servo)
	local i = 1
	while i <= #servos do
		if servos[i] == servo then
			table.remove(servos, i)
			return
		end
		i = i + 1
	end
end

local function nascer(ponto)
	if #servos >= CFG.LIMITE then return nil end
	local servo = porNoMundo("enemy", CFrame.new(ponto + Vector3.new(0, 3, 0)),
		CFG.VIDA)
	if not servo then
		-- sem o molde a habilidade ainda acontece: o estouro do nascimento
		vfx("INVOCA", { posicao = ponto })
		return nil
	end
	servo.Name = "ServoDoXester"
	table.insert(servos, servo)
	vfx("INVOCA", { posicao = ponto })
	tocarEm("NASCE", ponto, 1)

	local servoHum = servo:FindFirstChildOfClass("Humanoid")
	local servoRaiz = servo:FindFirstChild("HumanoidRootPart")
		or servo:FindFirstChild("Torso")
	if not (servoHum and servoRaiz) then
		task.delay(CFG.VIDA, function() esquecer(servo) end)
		return servo
	end
	servoHum.WalkSpeed = CFG.VELOCIDADE

	-- a caça é por PRAZO, não por quadro: o servo escolhe alvo a cada passo e
	-- deixa o `Humanoid` andar. Quem interpola é o motor de física.
	task.spawn(function()
		local ate = os.clock() + CFG.VIDA
		while os.clock() < ate do
			if not (servo.Parent and servoHum.Health > 0) then break end
			local presa = hostisEm(servoRaiz.Position, CFG.VISAO, 1)[1]
			if presa then
				local presaRaiz = raizDe(presa)
				if presaRaiz then
					servoHum:MoveTo(presaRaiz.Position)
					if (presaRaiz.Position - servoRaiz.Position).Magnitude
							<= CFG.ALCANCE_GOLPE then
						vfx("SERVO_GOLPE", { posicao = servoRaiz.Position })
						aplicarDano(presa, CFG.DANO)
					end
				end
			end
			task.wait(CFG.PASSO)
		end
		esquecer(servo)
	end)
	return servo
end

local function dispensarServos()
	local guardados = servos
	servos = {}
	for _, servo in ipairs(guardados) do
		if servo.Parent then servo.Parent = nil end
	end
	return guardados
end

--''' + R + '''
-- M1 — chama um servo no ponto mirado
--''' + R + '''

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("INVOCAR", despachar({
		CARGA = { sfx = { "CHAMA", 0.95 } },
		GOLPE = { faz = function()
			nascer(destino or frente(CFG.ALCANCE))
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Comandar  ·  T — Legião  ·  Y — Dispensar
--''' + R + '''

--- Comandar: manda TODOS ao ponto mirado, e o ponto leva um golpe junto. Sem
--- servo em pé ela ainda vale — é o golpe que chega.
function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("COMANDAR", despachar({
		CARGA = { sfx = { "COMANDA", 0.9 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("INVOCA", { posicao = ponto })
			tocarEm("COMANDA", ponto, 0.85)
			for _, servo in ipairs(servos) do
				local servoHum = servo.Parent
					and servo:FindFirstChildOfClass("Humanoid")
				if servoHum and servoHum.Health > 0 then
					servoHum:MoveTo(ponto)
				end
			end
			for _, alvo in ipairs(hostisEm(ponto, CFG.RAIO_COMANDO, 10)) do
				aplicarDano(alvo, CFG.DANO_COMANDO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, alvoRaiz.Position - ponto, CFG.EMPURRAO, 0.24)
				end
			end
		end },
	}), function() ocupado = false end)
end

--- Legião: três de uma vez, em anel em volta do ponto. O teto de `LIMITE`
--- continua valendo — `nascer` recusa sozinho.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("LEGIAO", despachar({
		CARGA  = { sfx = { "LEGIAO", 0.85 } },
		SEGURA = { sfx = { "CHAMA", 0.8 } },
		GOLPE  = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			vfx("PORTAL_ABRE", { posicao = ponto, raio = CFG.ANEL_LEGIAO,
				duracao = 1 })
			tocarEm("LEGIAO", ponto, 0.8)
			local i = 1
			while i <= CFG.LEGIAO do
				local ang = i * (math.pi * 2 / CFG.LEGIAO)
				nascer(ponto + Vector3.new(
					math.cos(ang) * CFG.ANEL_LEGIAO, 0,
					math.sin(ang) * CFG.ANEL_LEGIAO))
				i = i + 1
			end
		end },
	}), function() ocupado = false end)
end

--- Dispensar: cada servo estoura onde estava. É a saída de emergência quando
--- a legião inteira está longe e o portador está cercado.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISPENSAR", despachar({
		CARGA  = { sfx = { "NASCE", 0.75 } },
		SEGURA = { sfx = { "CHAMA", 0.7 } },
		GOLPE  = { faz = function()
			local guardados = dispensarServos()
			local pontos = {}
			for _, servo in ipairs(guardados) do
				local peca = servo:FindFirstChild("HumanoidRootPart")
					or servo:FindFirstChild("Torso")
					or servo:FindFirstChildWhichIsA("BasePart", true)
				if peca then table.insert(pontos, peca.Position) end
			end
			if #pontos == 0 then
				table.insert(pontos, frente(CFG.RAIO_DISPENSA))
			end
			for _, onde in ipairs(pontos) do
				vfx("CEIFEIRA_ESTOURA", { posicao = onde })
				tocarEm("NASCE", onde, 0.7)
				for _, alvo in ipairs(hostisEm(onde, CFG.RAIO_DISPENSA, 12)) do
					local alvoRaiz = raizDe(alvo)
					local d = alvoRaiz
						and (alvoRaiz.Position - onde).Magnitude
						or CFG.RAIO_DISPENSA
					if d <= CFG.NUCLEO_DISP then
						aplicarDano(alvo, CFG.DANO_DISPENSA)
						tombar(alvo, CFG.TOMBO)
					else
						aplicarDano(alvo, CFG.BORDA_DISPENSA)
					end
					if alvoRaiz then
						empurrar(alvo, (alvoRaiz.Position - onde)
							+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO_DISP, 0.3)
					end
				end
			end
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tdispensarServos()\n")


T("Xester Furia do Machado", "Forma2",
  objeto="XesterFuriadoMachado_Server_V1", sufixo="XesterMachado",
  arquetipo="MELEE", alcance_mira=30,
  rotulo_m1="saca o machado e avanca", rotulo_r="Arremesso",
  rotulo_t="Redemoinho", rotulo_y="Decapitar",
  origem=["Forma 2 — só a pasta `Effects`; o machado é efeito, não peça",
          "SACA · RISO · REDEMOINHO · DECAPITA, os quatro do `xesterv2`"],
  cfg="""	VELOCIDADE    = 34,
	DURACAO       = 5,
	PASSO         = 0.3,
	FRENTE        = 6,
	RAIO          = 7,
	NUCLEO        = 3,
	DANO          = 26,
	BORDA         = 13,
	EMPURRAO      = 40,
	RECARGA       = 12,

	RECARGA_R     = 9,
	ALCANCE_TIRO  = 45,
	VOO           = 0.3,
	RAIO_TIRO     = 9,
	NUCLEO_TIRO   = 4,
	DANO_TIRO     = 38,
	BORDA_TIRO    = 19,
	EMPURRAO_TIRO = 58,

	RECARGA_T     = 15,
	GIROS         = 6,
	PASSO_GIRO    = 0.16,
	RAIO_GIRO     = 10,
	DANO_GIRO     = 15,
	EMPURRAO_GIRO = 34,

	RECARGA_Y     = 22,
	ALCANCE_CORTE = 14,
	RAIO_CORTE    = 6,
	DANO_CORTE    = 72,
	TOMBO_CORTE   = 3,""",
  estado="local correndo = false\nlocal velocidadeAntes = nil",
  corpo='''
--''' + R + '''
-- M1 — saca o machado e avança
--
-- A origem punha `ws = 120` e saía correndo. 120 de WalkSpeed atravessa
-- colisão com replicação normal, e a origem NUNCA devolvia a velocidade: ela
-- ficava até a próxima troca de estado. Aqui a corrida tem prazo, teto que o
-- motor sustenta, e `pararCorrida` é chamado do beat, do fim da sequência e
-- do `desmontar` — três caminhos, e nenhum deixa o portador rápido para sempre.
--''' + R + '''

local function pararCorrida()
	if not correndo then return end
	correndo = false
	if humanoide and humanoide.Parent and velocidadeAntes then
		humanoide.WalkSpeed = velocidadeAntes
	end
	velocidadeAntes = nil
	vfx("MACHADO_GUARDA", {})
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("MACHADO", despachar({
		CARGA = { sfx = { "SACA", 1 } },
		GOLPE = { faz = function()
			if correndo then
				pararCorrida()
				return
			end
			if not (humanoide and humanoide.Parent) then return end
			correndo = true
			velocidadeAntes = humanoide.WalkSpeed
			humanoide.WalkSpeed = CFG.VELOCIDADE
			vfx("MACHADO_SACA", { duracao = CFG.DURACAO })
			tocar("SACA", 1)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				while correndo and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local onde = raiz.Position
						+ raiz.CFrame.LookVector * CFG.FRENTE
					if golpearArea(onde, CFG.RAIO, CFG.NUCLEO, CFG.DANO,
							CFG.BORDA, CFG.EMPURRAO, nil, 8) > 0 then
						vfx("MACHADO_CORTA", { posicao = onde })
					end
					task.wait(CFG.PASSO)
				end
				pararCorrida()
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Arremesso  ·  T — Redemoinho  ·  Y — Decapitar
--''' + R + '''

--- O machado sai da mão e volta. Ele é EFEITO, não peça: nada é criado no
--- mundo, e por isso não há o que largar no chão se a Tool sumir no meio.
function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ARREMESSO", despachar({
		CARGA = { sfx = { "SACA", 1.2 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position + Vector3.new(0, 2, 0)
			local ponto = destino or frente(CFG.ALCANCE_TIRO)
			vfx("CEIFEIRA_VOA", { origem = origem, destino = ponto,
				voo = CFG.VOO })
			task.delay(CFG.VOO, function()
				if not personagem then return end
				vfx("MACHADO_CORTA", { posicao = ponto })
				vfx("CEIFEIRA_ESTOURA", { posicao = ponto })
				tocarEm("SACA", ponto, 0.9)
				golpearArea(ponto, CFG.RAIO_TIRO, CFG.NUCLEO_TIRO,
					CFG.DANO_TIRO, CFG.BORDA_TIRO, CFG.EMPURRAO_TIRO, nil, 12)
				-- a volta: efeito só, sem dano. O golpe já saiu.
				task.delay(CFG.VOO, function()
					if not (personagem and raiz) then return end
					vfx("CEIFEIRA_VOA", { origem = ponto,
						destino = raiz.Position, voo = CFG.VOO })
				end)
			end)
		end },
	}), function() ocupado = false end)
end

--- Redemoinho: gira no lugar. Seis voltas rápidas, dano pequeno por volta —
--- é para tirar quem está colado, não para trocar com a M1.
function extraT(_mira)
	ocupado = true
	rig:PlaySequence("REDEMOINHO", despachar({
		CARGA  = { sfx = { "REDEMOINHO", 0.85 } },
		SEGURA = { sfx = { "RISO", 1.25 } },
		GOLPE  = { faz = function()
			local i = 1
			while i <= CFG.GIROS do
				local indice = i
				task.delay(indice * CFG.PASSO_GIRO, function()
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						return
					end
					local centro = raiz.Position
					local ang = indice * 2.399963
					vfx("MACHADO_CORTA", { posicao = centro + Vector3.new(
						math.cos(ang) * CFG.RAIO_GIRO * 0.6, 1,
						math.sin(ang) * CFG.RAIO_GIRO * 0.6) })
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_GIRO, 12)) do
						aplicarDano(alvo, CFG.DANO_GIRO)
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							empurrar(alvo, alvoRaiz.Position - centro,
								CFG.EMPURRAO_GIRO, 0.18)
						end
					end
				end)
				i = i + 1
			end
		end },
	}), function() ocupado = false end)
end

--- Decapitar: UM alvo, dano grande, tombo longo. A origem marcava INSTAKILL em
--- quatro habilidades; morte por número é morte que o Núcleo credita, e que
--- `ForceField` ainda barra. Instakill não é nenhuma das duas coisas.
function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("DECAPITAR", despachar({
		CARGA  = { sfx = { "DECAPITA", 0.8 } },
		SEGURA = { sfx = { "REDEMOINHO", 0.8 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ponto = destino or frente(CFG.ALCANCE_CORTE)
			local alvo = maisPerto(ponto, CFG.ALCANCE_CORTE)
			if not alvo then
				alvo = maisPerto(raiz.Position
					+ raiz.CFrame.LookVector * CFG.ALCANCE_CORTE * 0.5,
					CFG.ALCANCE_CORTE)
			end
			if not alvo then
				vfx("MACHADO_CORTA", { posicao = ponto })
				tocarEm("DECAPITA", ponto, 0.8)
				return
			end
			local alvoRaiz = raizDe(alvo)
			local onde = alvoRaiz and alvoRaiz.Position or ponto
			vfx("MACHADO_CORTA", { posicao = onde })
			vfx("CEIFEIRA_ESTOURA", { posicao = onde })
			tocarEm("DECAPITA", onde, 0.78)
			aplicarDano(alvo, CFG.DANO_CORTE)
			tombar(alvo, CFG.TOMBO_CORTE)
			-- respingo: quem está encostado no decapitado leva metade
			for _, vizinho in ipairs(alvosEm(onde, CFG.RAIO_CORTE, 8)) do
				if vizinho ~= alvo then
					aplicarDano(vizinho, CFG.DANO_CORTE * 0.35)
				end
			end
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tpararCorrida()\n")


T("Xester Procissao de Cartas", "Forma2",
  objeto="XesterProcissaodeCartas_Server_V1", sufixo="XesterProcissao",
  arquetipo="ESPECTRAL", alcance_mira=60,
  rotulo_m1="fileira de cartas ate o alvo", rotulo_r="Formacao",
  rotulo_t="Marcha", rotulo_y="Dissolver",
  origem=["Forma 2 — cartas do `cards`, cajado do `staff`",
          "SOBE · FORMACAO · MARCHA · DISSOLVE, os quatro do `xesterv2`"],
  cfg="""	ALCANCE       = 60,
	PASSOS        = 14,
	ESPACO        = 4,
	INTERVALO     = 0.07,
	RAIO          = 6,
	NUCLEO        = 3,
	DANO          = 22,
	BORDA         = 11,
	EMPURRAO      = 34,
	RECARGA       = 9,

	RECARGA_R     = 12,
	ANEL          = 8,
	CARTAS_ANEL   = 8,
	DURACAO_ANEL  = 5,
	PASSO_ANEL    = 0.5,
	DANO_ANEL     = 13,

	RECARGA_T     = 17,
	PASSOS_MARCHA = 18,
	ESPACO_MARCHA = 4,
	PASSO_MARCHA  = 0.16,
	RAIO_MARCHA   = 7,
	DANO_MARCHA   = 16,
	EMPURRAO_MAR  = 52,

	RECARGA_Y     = 24,
	RAIO_DISSOLVE = 20,
	NUCLEO_DISS   = 7,
	DANO_DISSOLVE = 56,
	BORDA_DISSOLVE = 28,
	EMPURRAO_DISS = 90,
	TOMBO         = 1.7,""",
  estado="local anelId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — a procissão
--
-- A origem andava 200 passos POR QUADRO, num laço apertado que segurava o
-- servidor inteiro. Aqui os passos são `task.delay` com o mesmo espaçamento —
-- mesma fileira, mesmo desenho, e o servidor respira entre um e outro.
--''' + R + '''

local function fileira(origem, direcao, passos, espaco, intervalo, raio,
		nucleo, danoNucleo, danoBorda, forca, som)
	local i = 1
	while i <= passos do
		local indice = i
		task.delay(indice * intervalo, function()
			if not personagem then return end
			local onde = origem + direcao * (indice * espaco)
			vfx("CARTA_ERGUE", { posicao = onde })
			if som and indice % 4 == 1 then
				tocarEm(som, onde, 1)
			end
			golpearArea(onde, raio, nucleo, danoNucleo, danoBorda, forca,
				nil, 8)
		end)
		i = i + 1
	end
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PROCISSAO", despachar({
		CARGA  = { sfx = { "SOBE", 1 } },
		SEGURA = { sfx = { "FORMACAO", 1.1 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local ponto = destino or frente(CFG.ALCANCE)
			local delta = ponto - origem
			local distancia = delta.Magnitude
			if distancia < 1 then return end
			local passos = math.min(CFG.PASSOS,
				math.floor(distancia / CFG.ESPACO))
			if passos < 1 then passos = 1 end
			local direcao = delta.Unit
			vfx("PROCISSAO", { origem = origem, direcao = direcao,
				passos = passos, espaco = CFG.ESPACO,
				intervalo = CFG.INTERVALO })
			fileira(origem, direcao, passos, CFG.ESPACO, CFG.INTERVALO,
				CFG.RAIO, CFG.NUCLEO, CFG.DANO, CFG.BORDA, CFG.EMPURRAO,
				"SOBE")
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Formação  ·  T — Marcha  ·  Y — Dissolver
--''' + R + '''

local function apagarAnel()
	geracao = geracao + 1
	if anelId then
		vfx("APAGAR", { id = anelId })
		anelId = nil
	end
end

--- Formação: as cartas sobem em ANEL em volta do portador e ficam. É a
--- procissão parada — cobre as costas, que é o que a fileira não faz.
function extraR(_mira)
	ocupado = true
	rig:PlaySequence("FORMACAO", despachar({
		CARGA = { sfx = { "FORMACAO", 1 } },
		GOLPE = { faz = function()
			apagarAnel()
			geracao = geracao + 1
			local minha = geracao
			anelId = novoId("ANEL")
			vfx("PROCISSAO", { origem = raiz.Position,
				raio = CFG.ANEL, passos = CFG.CARTAS_ANEL,
				duracao = CFG.DURACAO_ANEL, id = anelId })
			tocar("FORMACAO", 0.95)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_ANEL
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local centro = raiz.Position
					local i = 1
					while i <= CFG.CARTAS_ANEL do
						local ang = i * (math.pi * 2 / CFG.CARTAS_ANEL)
						local onde = centro + Vector3.new(
							math.cos(ang) * CFG.ANEL, 0,
							math.sin(ang) * CFG.ANEL)
						for _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 4)) do
							aplicarDano(alvo, CFG.DANO_ANEL)
							vfx("CARTA_ERGUE", { posicao = onde })
						end
						i = i + 1
					end
					task.wait(CFG.PASSO_ANEL)
				end
				if minha == geracao then apagarAnel() end
			end)
		end },
	}), function() ocupado = false end)
end

--- Marcha: a fileira anda sozinha, mais longe e mais devagar que a M1, e
--- empurra em vez de estourar. É deslocamento de linha, não pico de dano.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MARCHA", despachar({
		CARGA  = { sfx = { "MARCHA", 1.1 } },
		SEGURA = { sfx = { "FORMACAO", 0.9 } },
		GOLPE  = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local origem = raiz.Position
			local ponto = destino or frente(CFG.ALCANCE)
			local delta = ponto - origem
			if delta.Magnitude < 1 then return end
			local direcao = delta.Unit
			vfx("PROCISSAO", { origem = origem, direcao = direcao,
				passos = CFG.PASSOS_MARCHA, espaco = CFG.ESPACO_MARCHA,
				intervalo = CFG.PASSO_MARCHA })
			fileira(origem, direcao, CFG.PASSOS_MARCHA, CFG.ESPACO_MARCHA,
				CFG.PASSO_MARCHA, CFG.RAIO_MARCHA, CFG.RAIO_MARCHA,
				CFG.DANO_MARCHA, CFG.DANO_MARCHA, CFG.EMPURRAO_MAR, "MARCHA")
		end },
	}), function() ocupado = false end)
end

--- Dissolver: a formação cai de uma vez. Com o anel de pé ela sai inteira; sem
--- ele, sai pela metade — a habilidade nunca é nula, mas premia quem preparou.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISSOLVER", despachar({
		CARGA  = { sfx = { "DISSOLVE", 1.2 } },
		SEGURA = { sfx = { "MARCHA", 0.85 } },
		GOLPE  = { faz = function()
			local centro = raiz.Position
			local cheio = anelId ~= nil
			apagarAnel()
			vfx("CARTA_DESABA", { posicao = centro, raio = CFG.RAIO_DISSOLVE })
			vfx("ONDA_DUPLA", { posicao = centro })
			tocarEm("DISSOLVE", centro, 1.15)
			local nucleo = cheio and CFG.DANO_DISSOLVE
				or CFG.DANO_DISSOLVE * 0.5
			golpearArea(centro, CFG.RAIO_DISSOLVE, CFG.NUCLEO_DISS,
				nucleo, nucleo * 0.5, CFG.EMPURRAO_DISS, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tapagarAnel()\n")


T("Xester Portal do Cajado", "Forma2",
  objeto="XesterPortaldoCajado_Server_V1", sufixo="XesterPortal",
  arquetipo="ARCANO", alcance_mira=50,
  rotulo_m1="carta-portal que puxa e corta", rotulo_r="Saida",
  rotulo_t="Atravessar", rotulo_y="Fechar",
  origem=["Forma 2 — `cards`, `energb` e `staff`",
          "ABRE · CORTA · SAIDA · FECHA, os quatro do `xesterv2`"],
  cfg="""	FRENTE        = 8,
	DURACAO       = 4,
	PASSO         = 0.35,
	RAIO          = 7,
	DANO          = 18,
	PUXAO         = 42,
	RECARGA       = 10,

	RECARGA_R     = 14,
	ALCANCE_SAIDA = 50,
	ALTURA_SAIDA  = 3,

	RECARGA_T     = 12,
	ALCANCE_TRAZ  = 50,
	ATRAS         = 5,
	DANO_TRAZ     = 26,

	RECARGA_Y     = 20,
	RAIO_FECHA    = 18,
	NUCLEO_FECHA  = 6,
	DANO_FECHA    = 54,
	BORDA_FECHA   = 27,
	EMPURRAO      = 86,
	TOMBO         = 1.6,""",
  estado="local portalId = nil\nlocal portalOnde = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- M1 — a carta-portal
--
-- Ela nasce à frente do portador e ACOMPANHA: o centro é lido a cada passo do
-- `raiz`, não guardado na abertura. É o ramo do `e` sem `secondform` da
-- origem, que refazia a hitbox 10 studs à frente a cada um dos 500 passos.
--''' + R + '''

local function fecharPortal()
	geracao = geracao + 1
	if portalId then
		vfx("APAGAR", { id = portalId })
		portalId = nil
	end
	portalOnde = nil
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("PORTAL", despachar({
		CARGA  = { sfx = { "ABRE", 0.9 } },
		SEGURA = { sfx = { "SAIDA", 1.1 } },
		GOLPE  = { faz = function()
			fecharPortal()
			geracao = geracao + 1
			local minha = geracao
			portalId = novoId("PORTAL")
			local id = portalId
			vfx("PORTAL_CAJADO", { posicao = raiz.Position
				+ raiz.CFrame.LookVector * CFG.FRENTE,
				duracao = CFG.DURACAO, id = id })
			tocar("ABRE", 0.9)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO
				while minha == geracao and os.clock() < ate do
					if not (personagem and raiz and humanoide
							and humanoide.Health > 0) then
						break
					end
					local onde = raiz.Position
						+ raiz.CFrame.LookVector * CFG.FRENTE
					portalOnde = onde
					vfx("CORTE_PORTAL", { posicao = onde })
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO, 10)) do
						aplicarDano(alvo, CFG.DANO)
						puxar(alvo, onde, CFG.PUXAO, CFG.PASSO)
					end
					task.wait(CFG.PASSO)
				end
				if minha == geracao then fecharPortal() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Saída  ·  T — Atravessar  ·  Y — Fechar
--''' + R + '''

--- Saída: o portal cospe o PORTADOR no ponto mirado. `raiz.CFrame` escrito no
--- servidor replica; escrever no cliente seria o portador andando sozinho para
--- todo mundo menos ele.
function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("SAIDA", despachar({
		CARGA = { sfx = { "SAIDA", 1.1 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local partida = raiz.Position
			local onde = destino or frente(CFG.ALCANCE_SAIDA)
			vfx("PORTAL_ABRE", { posicao = partida, raio = 5, duracao = 0.8 })
			vfx("PORTAL_ABRE", { posicao = onde, raio = 5, duracao = 0.8 })
			tocarEm("SAIDA", partida, 1.05)
			tocarEm("SAIDA", onde, 1.15)
			raiz.CFrame = CFrame.new(
				onde + Vector3.new(0, CFG.ALTURA_SAIDA, 0),
				onde + raiz.CFrame.LookVector)
		end },
	}), function() ocupado = false end)
end

--- Atravessar: o contrário da Saída. Quem está do outro lado vem PARA CÁ, e
--- cai atrás do portador — de costas para ele, e com o corte de entrada.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ATRAVESSAR", despachar({
		CARGA = { sfx = { "ABRE", 1.05 } },
		GOLPE = { faz = function()
			if not (raiz and raiz.Parent) then return end
			local ponto = destino or frente(CFG.ALCANCE_TRAZ)
			local alvo = maisPerto(ponto, CFG.ALCANCE_TRAZ)
			local alvoRaiz = alvo and raizDe(alvo)
			if not alvoRaiz then
				vfx("PORTAL_ABRE", { posicao = ponto, raio = 4, duracao = 0.6 })
				tocarEm("ABRE", ponto, 1)
				return
			end
			local saida = raiz.Position
				- raiz.CFrame.LookVector * CFG.ATRAS
			vfx("PORTAL_ABRE", { posicao = alvoRaiz.Position, raio = 4,
				duracao = 0.6 })
			vfx("PORTAL_ABRE", { posicao = saida, raio = 4, duracao = 0.6 })
			tocarEm("ABRE", saida, 1.05)
			alvoRaiz.CFrame = CFrame.new(saida + Vector3.new(0, 1, 0),
				saida - raiz.CFrame.LookVector)
			vfx("CORTE_PORTAL", { posicao = saida })
			aplicarDano(alvo, CFG.DANO_TRAZ)
		end },
	}), function() ocupado = false end)
end

--- Fechar: o portal colapsa em cima de quem foi puxado. Com o portal de pé o
--- colapso sai no lugar DELE; sem portal, sai à frente e pela metade.
function extraY(_mira)
	ocupado = true
	rig:PlaySequence("FECHAR", despachar({
		CARGA  = { sfx = { "FECHA", 0.85 } },
		SEGURA = { sfx = { "CORTA", 1 } },
		GOLPE  = { faz = function()
			local cheio = portalOnde ~= nil
			local centro = portalOnde or frente(CFG.FRENTE)
			fecharPortal()
			vfx("PORTAL_COLAPSA", { posicao = centro, raio = CFG.RAIO_FECHA })
			vfx("CORTE_PORTAL", { posicao = centro })
			tocarEm("FECHA", centro, 0.8)
			local dano = cheio and CFG.DANO_FECHA or CFG.DANO_FECHA * 0.5
			golpearArea(centro, CFG.RAIO_FECHA, CFG.NUCLEO_FECHA,
				dano, dano * 0.5, CFG.EMPURRAO, CFG.TOMBO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tfecharPortal()\n")
