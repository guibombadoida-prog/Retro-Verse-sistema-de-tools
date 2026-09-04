# -*- coding: utf-8 -*-
"""
servers_fogo.py — Retro-Verse / Studios

O CORPO das 14 habilidades do conjunto PODER DE FOGO. O preâmbulo, o bloco de
física, o de queimadura, o registro de peças, o despachante e o rodapé estão em
FERRAMENTAS/gerar_servers_fogo.py.

DUAS HABILIDADES POR TOOL — M1 + `R`.

  | Tool | M1 | R | o que ela faz com a queimadura |
  |---|---|---|---|
  | `Brasa` | soco em brasa | estouro curto | ACUMULA — é a que acende |
  | `Lanca Chamas` | jato em cone | combustão | COBRA — só estoura quem queima |
  | `Bola de Fogo` | bola balística | estilhaços | acumula à distância |
  | `Muralha de Fogo` | risco no chão | a muralha | acumula por PERMANÊNCIA |
  | `Meteoro` | pedra em brasa | o meteoro | o maior dano bruto |
  | `Fenix` | corte de asa | renascer | **CURA** o que a queimadura tirou |
  | `Inferno` | chicote azul | o campo | COBRA e ESPALHA para os vizinhos |

AS DUAS QUE COBRAM SÃO O PONTO DO CONJUNTO. `Lanca Chamas/R` e `Inferno/R` só
valem a recarga se alguém acumulou antes — e é isso que faz as sete se
falarem em vez de serem sete Tools de fogo soltas.
"""

CONJUNTO = {}


def _t(nome, objeto, sufixo, arquetipo, m1, r, botao, alcance, cfg, estado,
       guardar_extra, corpo):
    CONJUNTO[nome] = dict(
        objeto=objeto, tool=nome, sufixo=sufixo, arquetipo=arquetipo,
        rotulo_m1=m1, rotulo_r=r, rotulo_botao_r=botao,
        alcance_mira=alcance, cutscene=False, extra_require="",
        cfg=cfg, estado=estado, ao_equipar="", ao_guardar=guardar_extra,
        corpo=corpo)


# ═══════════════════════════════════════════════════════════════
# 1 · BRASA — a que ACENDE
# ═══════════════════════════════════════════════════════════════

_t("Brasa", "Brasa_Server_V1", "Brasa", "Brasa",
   "soco em brasa que acumula queimadura", "solta a brasa acumulada",
   "Estouro", 40,
   """	RECARGA = 0.7,
	RECARGA_R = 9,

	DANO = 13,
	ALCANCE = 11,
	--- cos(46°) — o cone do soco é curto e fechado: é corpo a corpo.
	COSSENO = 0.69,
	LIMITE = 3,
	EMPURRAO = 46,

	ESTOURO_RAIO = 13,
	ESTOURO_DANO = 30,
	ESTOURO_FORCA = 84,
	--- quantas camadas o estouro CONSOME do alvo. Ele troca acúmulo por dano
	--- imediato, e é o que dá ao M1 um motivo para existir antes do R.
	ESTOURO_CONSOME = 2,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- M1 — o soco em brasa
--
-- É o M1 do jogo inteiro, e por isso é o mais barato do conjunto: 0.7 s de
-- recarga, cone curto, uma camada de queimadura por acerto.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		GOLPE = {
			sfx = { "GOLPE", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.55)
				vfx("GOLPE", { ponto = centro })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					-- o dano JÁ conta a queimadura que estava lá: bater em
					-- quem queima dói mais, e é o que liga o M1 ao resto
					aplicarDano(alvo, math.floor(CFG.DANO * fatorDe(alvo) + 0.5))
					empurrar(alvo, (direcao + Vector3.new(0, 0.3, 0)).Unit,
						CFG.EMPURRAO, 0.2)
					queimar(alvo, 1)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o estouro
--
-- Ele CONSOME camadas. É a única habilidade do conjunto que tira queimadura
-- em vez de pôr, e é o que dá ao M1 um motivo para vir antes: acumule com o
-- soco, gaste no estouro.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "GOLPE", 0.8 } },

		ESTOURO = {
			sfx = { "ESTOURO", 0.95 },
			faz = function()
				if not raiz then return end
				local centro = typeof(mira) == "Vector3" and mira
					or frente(CFG.ESTOURO_RAIO * 0.5)
				vfx("IMPACTO", { ponto = centro, raio = CFG.ESTOURO_RAIO })
				tocarEm("ESTOURO", centro, 0.9)

				for _, alvo in ipairs(alvosEm(centro, CFG.ESTOURO_RAIO, 8)) do
					local alvoRaiz = raizDe(alvo)
					local queda = 1
					if alvoRaiz then
						queda = math.clamp(1 - ((alvoRaiz.Position - centro)
							.Magnitude / CFG.ESTOURO_RAIO), 0.25, 1)
					end
					local n = camadasDe(alvo)
					-- o bônus é pelo que ESTAVA lá; depois a camada é gasta
					local f = 1 + n * CFG.QUEIMA_BONUS * 2
					aplicarDano(alvo,
						math.floor(CFG.ESTOURO_DANO * queda * f + 0.5))
					if alvoRaiz then
						empurrar(alvo, ((alvoRaiz.Position - centro).Unit
							+ Vector3.new(0, 0.6, 0)).Unit,
							CFG.ESTOURO_FORCA * queda, 0.26)
					end
					if n > CFG.ESTOURO_CONSOME then
						alvo:SetAttribute("RV_FogoCamadas", n - CFG.ESTOURO_CONSOME)
					else
						alvo:SetAttribute("RV_FogoCamadas", nil)
						alvo:SetAttribute("RV_FogoExpira", nil)
					end
					tombar(alvo, 0.9)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 2 · LANCA CHAMAS — a que COBRA
# ═══════════════════════════════════════════════════════════════

_t("Lanca Chamas", "LancaChamas_Server_V1", "LancaChamas", "LancaChamas",
   "o jato contínuo que queima o cone à frente",
   "a combustão: tudo que está queimando estoura junto",
   "Combustão", 60,
   """	RECARGA = 1.0,
	RECARGA_R = 14,

	DANO_TIQUE = 5,
	ALCANCE = 24,
	--- cos(28°) — o jato é o cone mais FECHADO do conjunto. Lança-chamas que
	--- pega meia tela não é lança-chamas, é aura.
	COSSENO = 0.88,
	LIMITE = 6,
	JATO_VIDA = 0.6,
	JATO_PERIODO = 0.12,

	COMBUSTAO_RAIO = 16,
	--- o dano da combustão é POR CAMADA, e é o ponto da Tool: em quem não
	--- está queimando ela não faz nada.
	COMBUSTAO_POR_CAMADA = 16,
	COMBUSTAO_FORCA = 96,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- M1 — o jato
--
-- Ele não é um golpe: é uma JANELA de 0.6 s em que quem estiver no cone
-- acumula. Por isso o tique é curto (0.12 s) e o dano por tique é baixo — o
-- que importa aqui é a camada, não o número.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		JATO = {
			sfx = { "JATO", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end

				vfx("JATO", {
					ponto = raiz.Position + Vector3.new(0, 1.4, 0),
					direcao = direcao, alcance = CFG.ALCANCE,
				})

				local ate = os.clock() + CFG.JATO_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					if not (raiz and raiz.Parent) then return end
					acumulado = acumulado + dt
					if acumulado < CFG.JATO_PERIODO then return end
					acumulado = 0

					for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
							CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
						aplicarDano(alvo, CFG.DANO_TIQUE)
						queimar(alvo, 1)
					end
				end))
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a combustão
--
-- ⭐ A PRIMEIRA DAS DUAS QUE COBRAM A QUEIMADURA. Em quem não está queimando
--    ela NÃO FAZ NADA — e é de propósito. O dano é por CAMADA, então ela vale
--    exatamente o que foi acumulado antes, pela `Brasa`, pelo próprio jato ou
--    por qualquer das outras cinco.
--
--    Se ela acertasse todo mundo, a queimadura seria enfeite.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "JATO", 0.75 } },

		COMBUSTAO = {
			sfx = { "COMBUSTAO", 0.9 },
			faz = function()
				local centro = typeof(mira) == "Vector3" and mira
					or frente(CFG.COMBUSTAO_RAIO * 0.5)
				local acesos = acesosEm(centro, CFG.COMBUSTAO_RAIO, 10)

				vfx("COMBUSTAO", { ponto = centro, raio = CFG.COMBUSTAO_RAIO })
				tocarEm("COMBUSTAO", centro, 0.85)

				for _, reg in ipairs(acesos) do
					local alvoRaiz = raizDe(reg.hum)
					aplicarDano(reg.hum,
						CFG.COMBUSTAO_POR_CAMADA * reg.camadas)
					if alvoRaiz then
						empurrar(reg.hum, ((alvoRaiz.Position - centro).Unit
							+ Vector3.new(0, 0.7, 0)).Unit,
							CFG.COMBUSTAO_FORCA, 0.28)
					end
					-- a combustão GASTA tudo: ela é o pagamento
					reg.hum:SetAttribute("RV_FogoCamadas", nil)
					reg.hum:SetAttribute("RV_FogoExpira", nil)
					desabar(reg.hum, 1.7)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 3 · BOLA DE FOGO
# ═══════════════════════════════════════════════════════════════

_t("Bola de Fogo", "BoladeFogo_Server_V1", "BoladeFogo", "BoladeFogo",
   "arremessa a bola, que voa em arco e quica",
   "divide a bola em estilhaços",
   "Estilhaço", 140,
   """	RECARGA = 0.9,
	RECARGA_R = 12,

	DANO = 30,
	VELOCIDADE = 98,
	QUIQUES = 1,
	PERDA = 0.72,
	VIDA_VOO = 3.4,
	RAIO_IMPACTO = 10,
	ONDA = 88,

	ESTILHACOS = 5,
	ESTILHACO_DANO = 22,
	ESTILHACO_RAIO = 13,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- O PROJÉTIL — raycast, não `Part` com `Velocity`
--
-- A 98 studs/s, uma peça física salta 1,6 stud por quadro a 60 Hz e atravessa
-- parede fina sem o `Touched` disparar. `dispararProjetil` integra à mão e
-- passa um raycast entre dois passos: não há como atravessar.
--══════════════════════════════════════════════════════════════

local function estourar(ponto, dano, raio, camadas)
	vfx("IMPACTO", { ponto = ponto, raio = raio })
	tocarEm("ESTILHACO", ponto, 0.95)

	for _, alvo in ipairs(alvosEm(ponto, raio, 10)) do
		local alvoRaiz = raizDe(alvo)
		local queda = 1
		if alvoRaiz then
			queda = math.clamp(1 - ((alvoRaiz.Position - ponto).Magnitude
				/ raio), 0.22, 1)
		end
		aplicarDano(alvo, math.floor(dano * queda * fatorDe(alvo) + 0.5))
		if alvoRaiz then
			empurrar(alvo, ((alvoRaiz.Position - ponto).Unit
				+ Vector3.new(0, 0.55, 0)).Unit, CFG.ONDA * queda, 0.26)
		end
		queimar(alvo, camadas or 1)
	end
end

local function lancar(saida, direcao, dano, raio, camadas)
	local acabou = false
	dispararProjetil(saida, direcao, CFG.VELOCIDADE, {
		quiques = CFG.QUIQUES,
		perda = CFG.PERDA,
		vida = CFG.VIDA_VOO,
		raio = 0.8,
		aoAndar = function(pos)
			vfx("LANCA", { ponto = pos })
		end,
		aoBater = function(batida, _vel, restantes)
			local modelo = batida.Instance
				and batida.Instance:FindFirstAncestorOfClass("Model")
			local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
			if hum and hum ~= humanoide and hum.Health > 0 then return true end
			return restantes <= 0
		end,
		aoFim = function(ponto)
			if acabou then return end
			acabou = true
			estourar(ponto, dano, raio, camadas)
		end,
	})
end

local function mirarDe(saida, mira, subida)
	if not raiz then return Vector3.new(0, 0, -1) end
	local direcao = raiz.CFrame.LookVector
	if typeof(mira) == "Vector3" then
		local delta = mira - saida
		if delta.Magnitude > 2 then
			-- um pouco para cima: arremesso reto cai antes do alvo, porque a
			-- gravidade age o voo inteiro
			direcao = (delta.Unit + Vector3.new(0, subida or 0.18, 0)).Unit
		end
	end
	return direcao
end

--══════════════════════════════════════════════════════════════
-- M1 — a bola
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		LANCA = {
			sfx = { "LANCA", 1 },
			faz = function()
				if not raiz then return end
				local saida = raiz.Position + raiz.CFrame.LookVector * 2.6
					+ Vector3.new(0, 1.6, 0)
				lancar(saida, mirarDe(saida, mira), CFG.DANO,
					CFG.RAIO_IMPACTO, 1)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — os estilhaços
--
-- Cinco bolas menores, abertas em leque pelo ângulo áureo. Cada uma queima
-- uma camada, então quem estiver no meio do leque sai com várias.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "LANCA", 0.8 } },

		ESTILHACO = {
			sfx = { "ESTILHACO", 1 },
			faz = function()
				if not raiz then return end
				local saida = raiz.Position + raiz.CFrame.LookVector * 2.6
					+ Vector3.new(0, 1.6, 0)
				local base = mirarDe(saida, mira, 0.22)

				vfx("ESTILHACO", { ponto = saida, raio = CFG.ESTILHACO_RAIO })

				for i = 1, CFG.ESTILHACOS do
					local a = anguloDe(i)
					-- o leque: desvio pequeno, senão eles não chegam junto
					local desvio = Vector3.new(math.cos(a), math.sin(a) * 0.5,
						math.sin(a)) * 0.16
					lancar(saida, (base + desvio).Unit, CFG.ESTILHACO_DANO,
						CFG.ESTILHACO_RAIO * 0.6, 1)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 4 · MURALHA DE FOGO
# ═══════════════════════════════════════════════════════════════

_t("Muralha de Fogo", "MuralhadeFogo_Server_V1", "MuralhadeFogo",
   "MuralhadeFogo",
   "risca o chão e acende a linha", "levanta a muralha que bloqueia",
   "Muralha", 90,
   """	RECARGA = 0.9,
	RECARGA_R = 16,

	DANO_TIQUE = 6,
	COMPRIMENTO = 26,
	LARGURA = 3.0,
	RISCO_VIDA = 1.6,

	MURALHA_VIDA = 5.0,
	MURALHA_ALTURA = 7,
	MURALHA_DANO = 11,
	PERIODO = 0.5,
	TETO_PECAS = 8,
""",
   """local linhas = {}""", "\ttable.clear(linhas)\n",
   '''
--══════════════════════════════════════════════════════════════
-- A LINHA — e o que ela É
--
-- Ela não é uma peça que dá dano ao encostar: é uma FAIXA registrada, e o
-- laço confere quem está dentro dela. A peça de servidor existe só para o
-- jogador VER onde a faixa está, e para bloquear tiro.
--
-- A projeção escalar é o que separa "está na faixa" de "está perto da linha":
-- sem ela, alguém dois metros ALÉM do fim da muralha queimaria numa muralha
-- que já acabou.
--══════════════════════════════════════════════════════════════

local function naFaixa(reg, posicao)
	local delta = reg.ate - reg.de
	local comp = delta.Magnitude
	if comp < 0.5 then return false end
	local eixo = delta.Unit
	local t = (posicao - reg.de):Dot(eixo)
	if t < 0 or t > comp then return false end
	local naLinha = reg.de + eixo * t
	return (posicao - naLinha).Magnitude <= CFG.LARGURA
end

local function acenderLinha(de, ate, vida, dano, camadas, alta)
	local reg = { de = de, ate = ate, ate_prazo = os.clock() + vida }
	table.insert(linhas, reg)

	if alta then
		local delta = ate - de
		local peca = criar(CFrame.new(de + delta * 0.5, ate),
			Vector3.new(CFG.LARGURA * 0.5, CFG.MURALHA_ALTURA,
				delta.Magnitude), {
				Color = Color3.fromRGB(238, 96, 28),
				Material = Enum.Material.Neon,
				Transparency = 0.42,
				-- ⚠️ NÃO colide com jogador: uma parede de fogo sólida
				--    empurraria quem está dentro dela para fora, e o efeito
				--    vira uma cerca em vez de uma ameaça. Ela bloqueia a VISTA
				--    e queima; passar por ela é escolha de quem passa.
				CanCollide = false,
			}, vida)
		if peca then peca.CanQuery = false end
	end

	local acumulado = 0
	guardar(RunService.Heartbeat:Connect(function(dt)
		if os.clock() > reg.ate_prazo then return end
		acumulado = acumulado + dt
		if acumulado < CFG.PERIODO then return end
		acumulado = 0

		local meio = (reg.de + reg.ate) * 0.5
		local alcance = (reg.ate - reg.de).Magnitude * 0.6 + CFG.LARGURA
		for _, alvo in ipairs(alvosEm(meio, alcance, 10)) do
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz and naFaixa(reg, alvoRaiz.Position) then
				aplicarDano(alvo, math.floor(dano * fatorDe(alvo) + 0.5))
				queimar(alvo, camadas or 1)
			end
		end
	end))
	return reg
end

local function direcaoNoChao(mira)
	if not raiz then return Vector3.new(0, 0, -1) end
	local direcao = raiz.CFrame.LookVector
	if typeof(mira) == "Vector3" then
		local delta = mira - raiz.Position
		local plano = Vector3.new(delta.X, 0, delta.Z)
		if plano.Magnitude > 0.5 then direcao = plano.Unit end
	end
	return direcao
end

--══════════════════════════════════════════════════════════════
-- M1 — o risco
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		RISCO = {
			sfx = { "RISCO", 1 },
			faz = function()
				if not raiz then return end
				local dir = direcaoNoChao(mira)
				local de = noChao(raiz.Position + dir * 3)
					+ Vector3.new(0, 0.3, 0)
				local ate = noChao(de + dir * (CFG.COMPRIMENTO * 0.55))
					+ Vector3.new(0, 0.3, 0)
				vfx("RISCO", { de = de, ate = ate, vida = CFG.RISCO_VIDA })
				acenderLinha(de, ate, CFG.RISCO_VIDA, CFG.DANO_TIQUE, 1, false)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a muralha
--
-- Mais longa, mais alta, e dura 5 s. Ela é a única habilidade do conjunto
-- que acumula queimadura por PERMANÊNCIA: ninguém leva muito de uma vez, mas
-- quem fica dentro sai no teto.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "RISCO", 0.8 } },

		MURALHA = {
			sfx = { "MURALHA", 0.85 },
			faz = function()
				if not raiz then return end
				local dir = direcaoNoChao(mira)
				-- a muralha nasce ATRAVESSADA na direção da mira: ela é uma
				-- barreira, e barreira paralela ao caminho não barra nada
				local lado = dir:Cross(Vector3.new(0, 1, 0))
				if lado.Magnitude < 0.01 then return end
				lado = lado.Unit

				local centro = noChao(
					(typeof(mira) == "Vector3") and mira or frente(14))
				local de = noChao(centro - lado * (CFG.COMPRIMENTO * 0.5))
					+ Vector3.new(0, 0.3, 0)
				local ate = noChao(centro + lado * (CFG.COMPRIMENTO * 0.5))
					+ Vector3.new(0, 0.3, 0)

				vfx("MURALHA", { de = de, ate = ate, vida = CFG.MURALHA_VIDA })
				tocarEm("MURALHA", centro, 0.85)
				acenderLinha(de, ate, CFG.MURALHA_VIDA, CFG.MURALHA_DANO,
					1, true)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 5 · METEORO
# ═══════════════════════════════════════════════════════════════

_t("Meteoro", "Meteoro_Server_V1", "Meteoro", "Meteoro",
   "atira a pedra em brasa", "chama o meteoro do céu, com marca no chão",
   "Meteoro", 170,
   """	RECARGA = 1.0,
	RECARGA_R = 20,

	DANO = 26,
	VELOCIDADE = 86,
	VIDA_VOO = 3.0,
	RAIO_PEDRA = 9,

	METEORO_RAIO = 18,
	METEORO_DANO = 74,
	METEORO_FORCA = 132,
	--- a espera entre a marca e a queda. É o que dá tempo de sair, e é o que
	--- faz esta ser uma ultimate jogável em vez de um clique que mata.
	ESPERA = 1.0,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- M1 — a pedra
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		PEDRA = {
			sfx = { "PEDRA", 1 },
			faz = function()
				if not raiz then return end
				local saida = raiz.Position + raiz.CFrame.LookVector * 2.6
					+ Vector3.new(0, 1.6, 0)
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - saida
					if delta.Magnitude > 2 then
						direcao = (delta.Unit + Vector3.new(0, 0.2, 0)).Unit
					end
				end

				local acabou = false
				dispararProjetil(saida, direcao, CFG.VELOCIDADE, {
					quiques = 0,
					vida = CFG.VIDA_VOO,
					raio = 0.9,
					aoAndar = function(pos) vfx("LANCA", { ponto = pos }) end,
					aoFim = function(ponto)
						if acabou then return end
						acabou = true
						vfx("IMPACTO", { ponto = ponto,
							raio = CFG.RAIO_PEDRA })
						tocarEm("PEDRA", ponto, 0.85)
						for _, alvo in ipairs(alvosEm(ponto,
								CFG.RAIO_PEDRA, 8)) do
							aplicarDano(alvo, math.floor(
								CFG.DANO * fatorDe(alvo) + 0.5))
							queimar(alvo, 1)
						end
					end,
				})
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o meteoro
--
-- A MARCA vem primeiro, e a queda só depois de `ESPERA`. Ultimate que cai sem
-- aviso é ultimate que o alvo não teve como jogar contra.
--
-- E o ponto de queda é resolvido por RAYCAST de cima: quem está debaixo de
-- uma laje não leva. É a diferença entre uma ultimate e uma planilha de dano.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local alvo = noChao(typeof(mira) == "Vector3" and mira or frente(28))

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = {
			sfx = { "PEDRA", 0.7 },
			faz = function()
				vfx("MARCA", { ponto = alvo, raio = CFG.METEORO_RAIO,
					vida = CFG.ESPERA })
			end,
		},

		QUEDA = {
			sfx = { "QUEDA", 0.8 },
			faz = function()
				task.delay(CFG.ESPERA, function()
					if not (personagem and personagem.Parent) then return end

					local filtro = RaycastParams.new()
					filtro.FilterType = Enum.RaycastFilterType.Exclude
					filtro.FilterDescendantsInstances = { personagem }
					local batida = workspace:Raycast(
						alvo + Vector3.new(0, 260, 0),
						Vector3.new(0, -300, 0), filtro)
					local pouso = batida and batida.Position or alvo

					vfx("QUEDA", { ponto = pouso, raio = CFG.METEORO_RAIO })
					tocarEm("QUEDA", pouso, 0.78)

					for _, quem in ipairs(alvosEm(pouso,
							CFG.METEORO_RAIO, 12)) do
						local quemRaiz = raizDe(quem)
						local queda = 1
						if quemRaiz then
							queda = math.clamp(1 - ((quemRaiz.Position - pouso)
								.Magnitude / CFG.METEORO_RAIO), 0.22, 1)
						end
						aplicarDano(quem, math.floor(
							CFG.METEORO_DANO * queda * fatorDe(quem) + 0.5))
						if quemRaiz then
							empurrar(quem, ((quemRaiz.Position - pouso).Unit
								+ Vector3.new(0, 0.7, 0)).Unit,
								CFG.METEORO_FORCA * queda, 0.3)
						end
						queimar(quem, 2)
						desabar(quem, 2.0)
					end

					for _, peca in ipairs(pecasEm(pouso,
							CFG.METEORO_RAIO, 20)) do
						local delta = peca.Position - pouso
						if delta.Magnitude > 0.5 then
							impulso(peca, (delta.Unit
								+ Vector3.new(0, 0.5, 0)).Unit, 90, 0.3)
						end
					end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 6 · FENIX — a única que CURA
# ═══════════════════════════════════════════════════════════════

_t("Fenix", "Fenix_Server_V1", "Fenix", "Fenix",
   "corte de asa que queima",
   "o renascer: você sobe em chamas e recupera o que a queimadura tirou",
   "Renascer", 60,
   """	RECARGA = 0.8,
	RECARGA_R = 22,

	DANO = 22,
	ALCANCE = 15,
	--- cos(70°) — o corte de asa é o cone mais ABERTO do conjunto: são duas
	--- asas, e elas pegam dos dois lados.
	COSSENO = 0.34,
	LIMITE = 6,
	EMPURRAO = 60,

	SUBIDA = 62,
	RENASCE_RAIO = 14,
	RENASCE_DANO = 34,
	--- a cura por camada que EU tinha. É o que faz a Fenix ser a resposta a
	--- quem estava queimando você, e não só mais um golpe.
	CURA_POR_CAMADA = 9,
	CURA_MINIMA = 12,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- M1 — o corte de asa
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		ASA = {
			sfx = { "ASA", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.5)
				vfx("ASA", { ponto = centro,
					quadro = CFrame.new(centro, centro + direcao) })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					aplicarDano(alvo, math.floor(CFG.DANO * fatorDe(alvo) + 0.5))
					empurrar(alvo, (direcao + Vector3.new(0, 0.4, 0)).Unit,
						CFG.EMPURRAO, 0.22)
					queimar(alvo, 1)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o renascer
--
-- ⭐ A ÚNICA HABILIDADE DO CONJUNTO QUE CURA, e ela cura pela queimadura que
--    EU estava levando: `CURA_POR_CAMADA` vezes as minhas camadas, mais um
--    piso. Quem estava pegando fogo se apaga e volta.
--
--    É a resposta do conjunto a si mesmo. Sem ela, seis Tools acumulam
--    queimadura e nada a tira — e a mecânica vira uma escada de mão única.
--
-- ⚠️ A subida usa `impulso` DIRETO na raiz, não `empurrar()`: aquele consulta
--    `ehMinha()` e recusaria, que é exatamente o que ele existe para fazer.
--══════════════════════════════════════════════════════════════

function extraR()
	if not (rig and raiz and humanoide) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "ASA", 0.8 } },

		RENASCER = {
			sfx = { "RENASCER", 0.9 },
			faz = function()
				if not (raiz and humanoide) then return end
				local centro = raiz.Position

				-- as MINHAS camadas: leio antes de apagar
				local minhas = 0
				local n = humanoide:GetAttribute("RV_FogoCamadas")
				local ate = humanoide:GetAttribute("RV_FogoExpira")
				if type(n) == "number" and type(ate) == "number"
						and os.clock() <= ate then
					minhas = math.min(n, CFG.QUEIMA_TETO)
				end
				humanoide:SetAttribute("RV_FogoCamadas", nil)
				humanoide:SetAttribute("RV_FogoExpira", nil)

				local cura = CFG.CURA_MINIMA + minhas * CFG.CURA_POR_CAMADA
				humanoide.Health = math.min(humanoide.MaxHealth,
					humanoide.Health + cura)

				impulso(raiz, Vector3.new(0, 1, 0), CFG.SUBIDA, 0.3)
				vfx("RENASCER", { ponto = centro, vida = 1.6 })

				for _, alvo in ipairs(alvosEm(centro,
						CFG.RENASCE_RAIO, 10)) do
					local alvoRaiz = raizDe(alvo)
					aplicarDano(alvo, math.floor(
						CFG.RENASCE_DANO * fatorDe(alvo) + 0.5))
					if alvoRaiz then
						empurrar(alvo, ((alvoRaiz.Position - centro).Unit
							+ Vector3.new(0, 0.8, 0)).Unit, 78, 0.28)
					end
					queimar(alvo, 2)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 7 · INFERNO — a que COBRA e ESPALHA
# ═══════════════════════════════════════════════════════════════

_t("Inferno", "Inferno_Server_V1", "Inferno", "Inferno",
   "chicote de fogo azul", "abre o inferno: o campo que queima e ESPALHA",
   "Inferno", 110,
   """	RECARGA = 0.9,
	RECARGA_R = 26,

	DANO = 27,
	ALCANCE = 20,
	--- cos(34°) — o chicote é uma linha, não um leque.
	COSSENO = 0.83,
	LIMITE = 5,
	EMPURRAO = 66,

	INFERNO_RAIO = 20,
	INFERNO_VIDA = 3.0,
	INFERNO_PERIODO = 0.4,
	INFERNO_DANO = 13,
	--- o contágio: quem queima acende quem estiver a este raio dele. É o que
	--- transforma o campo numa reação em cadeia em vez de um raio maior.
	CONTAGIO_RAIO = 9,
	TETO_PECAS = 4,
""",
   "", "",
   '''
--══════════════════════════════════════════════════════════════
-- M1 — o chicote azul
--
-- Fogo azul é mais quente, e a cor é a INFORMAÇÃO: esta é a única Tool do
-- conjunto que não desenha laranja, e o jogador lê isso antes de ler o dano.
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CHICOTE = {
			sfx = { "CHICOTE", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.5)
				vfx("CHICOTE", { ponto = centro })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					aplicarDano(alvo, math.floor(CFG.DANO * fatorDe(alvo) + 0.5))
					empurrar(alvo, (direcao + Vector3.new(0, 0.35, 0)).Unit,
						CFG.EMPURRAO, 0.22)
					queimar(alvo, 2)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o inferno
--
-- ⭐ A SEGUNDA QUE COBRA A QUEIMADURA, e ela cobra de um jeito diferente da
--    `Lanca Chamas`: em vez de gastar as camadas num estouro, ela as ESPALHA.
--
--    Quem está queimando acende quem estiver a `CONTAGIO_RAIO` dele. Um alvo
--    aceso no meio de um grupo pega o grupo inteiro — e é isso que faz o
--    campo valer 26 s de recarga.
--
--    O contágio roda por PERÍODO, e o teto de camadas impede a bola de neve
--    de virar dano infinito: espalhar não soma além do teto.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(18))
		+ Vector3.new(0, 2, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		CARREGA = { sfx = { "CHICOTE", 0.75 } },

		INFERNO = {
			sfx = { "INFERNO", 0.8 },
			faz = function()
				vfx("INFERNO", { ponto = centro, raio = CFG.INFERNO_RAIO,
					vida = CFG.INFERNO_VIDA })
				tocarEm("INFERNO", centro, 0.78)

				local ate = os.clock() + CFG.INFERNO_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					if acumulado < CFG.INFERNO_PERIODO then return end
					acumulado = 0

					-- 1. o campo queima quem está nele
					for _, alvo in ipairs(alvosEm(centro,
							CFG.INFERNO_RAIO, 12)) do
						aplicarDano(alvo, math.floor(
							CFG.INFERNO_DANO * fatorDe(alvo) + 0.5))
						queimar(alvo, 1)
					end

					-- 2. E O CONTÁGIO: quem já queima acende os vizinhos.
					--    A lista é tirada ANTES do laço de propagação: sem
					--    isso, um alvo aceso agora acenderia o vizinho, que
					--    acenderia o dele, tudo no mesmo quadro — e a cadeia
					--    percorreria o mapa inteiro num tique.
					local fonte = acesosEm(centro, CFG.INFERNO_RAIO, 10)
					for _, reg in ipairs(fonte) do
						local regRaiz = raizDe(reg.hum)
						if regRaiz then
							for _, vizinho in ipairs(alvosEm(regRaiz.Position,
									CFG.CONTAGIO_RAIO, 6)) do
								if vizinho ~= reg.hum then
									queimar(vizinho, 1, regRaiz.Position)
								end
							end
						end
					end
				end))
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')
