# -*- coding: utf-8 -*-
"""
servers_magnetismo.py — Retro-Verse / Studios

O CORPO das 21 habilidades do conjunto MAGNETISMO. O preâmbulo, o bloco de
física, o de polaridade, o registro de peças, o despachante e o rodapé estão em
FERRAMENTAS/gerar_servers_magnetismo.py; aqui fica só o que é próprio de cada
Tool.

TRÊS HABILIDADES POR TOOL — M1 + `R` + `T`.

A POLARIDADE É O EIXO, e cada Tool tem a SUA:

  | Tool | emite | M1 | R | T |
  |---|---|---|---|---|
  | `Polo Norte` | NORTE | puxa em cone | cúpula que suga | implosão |
  | `Polo Sul` | SUL | empurra em cone | escudo repulsor | onda radial |
  | `Ferrovia Magnetica` | NORTE | assenta trilho | lança você no trilho | malha |
  | `Sucata` | NORTE | junta a bola | arremessa a bola | chuva de sucata |
  | `Bobina de Tesla` | SUL | arco em cadeia | bobina que pulsa | descarga |
  | `Levitacao` | NORTE | suspende o alvo | você flutua | inverte a gravidade |
  | `Colapso Magnetico` | alterna | carrega o alvo | atrai as cargas | singularidade |

O `Colapso Magnetico` ALTERNA de propósito: ele é a Tool que MONTA a
combinação, e para isso precisa poder pôr as duas cargas em campo. As outras
seis emitem uma só, e é o que as torna previsíveis.
"""

CONJUNTO = {}


# ═══════════════════════════════════════════════════════════════
# 1 · POLO NORTE — atração
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Polo Norte"] = dict(
    objeto="PoloNorte_Server_V1",
    tool="Polo Norte",
    sufixo="PoloNorte",
    arquetipo="Norte",
    rotulo_m1="puxa o que está no cone, e carrega de NORTE",
    rotulo_r="a cúpula que suga tudo que entrar",
    rotulo_t="implode o ponto mirado",
    rotulo_botao_r="Cúpula",
    rotulo_botao_t="Implosão",
    alcance_mira=90,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 0.9,
	RECARGA_R = 15,
	RECARGA_T = 26,

	DANO = 14,
	ALCANCE = 26,
	--- cos(42°) — o cone de atração é mais fechado que o de empurrão: puxar
	--- para si o que está ao lado colocaria o alvo às suas costas.
	COSSENO = 0.74,
	LIMITE = 6,
	PUXAO = 62,

	CUPULA_RAIO = 22,
	CUPULA_VIDA = 2.0,
	CUPULA_FORCA = 190,
	CUPULA_PERIODO = 0.18,
	CUPULA_DANO = 5,

	IMPLOSAO_RAIO = 18,
	IMPLOSAO_DANO = 48,
	IMPLOSAO_PUXAO = 120,
	TETO_ATRAIDAS = 26,
	DESABA = 1.8,
""",
    estado="""local atraidas = {}""",
    ao_equipar="",
    ao_guardar="\tliberarAtraidas()\n",
    corpo='''
--══════════════════════════════════════════════════════════════
-- O PÓLO DESTA TOOL
--══════════════════════════════════════════════════════════════

local MEU_POLO = "NORTE"

--- Devolve toda peça que este campo pendurou. Chamado no fim de cada campo E
--- no `desmontar()`: `VectorForce` órfã é uma peça sendo puxada para um ponto
--- onde não há mais nada, para sempre.
local function liberarAtraidas()
	for _, peca in ipairs(atraidas) do
		if peca and peca.Parent then soltarPeca(peca) end
	end
	table.clear(atraidas)
end

local function anotarPeca(peca)
	for _, p in ipairs(atraidas) do
		if p == peca then return end
	end
	table.insert(atraidas, peca)
end

--- Puxa um humanoide PARA UM PONTO, com o bônus da polaridade.
---
--- `fatorDe(alvo, MEU_POLO, true)` — o `true` é "estou ATRAINDO", e é o que
--- faz o bônus certo valer: carga oposta atrai mais forte, carga igual não.
--- Sem esse parâmetro a habitação de atração ganharia bônus por repulsão.
local function puxarPara(alvoHum, centro, forca)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return 0 end
	local delta = centro - alvoRaiz.Position
	if delta.Magnitude < 0.6 then return 0 end
	local f = fatorDe(alvoHum, MEU_POLO, true)
	empurrar(alvoHum, delta.Unit, forca * f, 0.24)
	return f
end

--══════════════════════════════════════════════════════════════
-- M1 — puxar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		PUXAR = {
			sfx = { "PUXAR", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local para = raiz.Position + direcao * 3

				vfx("PUXAR", { ponto = para, eixo = direcao,
					raio = CFG.ALCANCE * 0.5 })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					local f = puxarPara(alvo, para, CFG.PUXAO)
					aplicarDano(alvo, math.floor(CFG.DANO * f + 0.5))
					marcar(alvo, MEU_POLO)
				end

				-- e as peças SOLTAS do mapa vêm junto. Nada é destruído: o que
				-- acontece com elas é uma `VectorForce`, e `soltarPeca` a tira.
				for _, peca in ipairs(pecasEm(para, CFG.ALCANCE * 0.6,
						CFG.TETO_ATRAIDAS)) do
					if atrairPeca(peca, para, CFG.PUXAO * 2.4,
							CFG.ALCANCE * 0.6) then
						anotarPeca(peca)
					end
				end
				task.delay(0.5, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a cúpula
--
-- Ela não é um puxão maior: é um LUGAR. Fica aberta por 2 s e suga o que
-- ENTRAR nela, não só o que já estava — é o que faz dela uma armadilha em vez
-- de um golpe com raio grande.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(14))
		+ Vector3.new(0, 3, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		ABRE = { sfx = { "CUPULA", 1.1 } },

		CUPULA = {
			sfx = { "CUPULA", 0.9 },
			faz = function()
				vfx("CUPULA", { ponto = centro, raio = CFG.CUPULA_RAIO,
					vida = CFG.CUPULA_VIDA })
				tocarEm("CUPULA", centro, 0.85)

				local ate = os.clock() + CFG.CUPULA_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					if acumulado < CFG.CUPULA_PERIODO then return end
					acumulado = 0

					for _, alvo in ipairs(alvosEm(centro, CFG.CUPULA_RAIO, 10)) do
						puxarPara(alvo, centro, CFG.CUPULA_FORCA
							* CFG.CUPULA_PERIODO)
						marcar(alvo, MEU_POLO)
					end
					for _, peca in ipairs(pecasEm(centro, CFG.CUPULA_RAIO,
							CFG.TETO_ATRAIDAS)) do
						if atrairPeca(peca, centro, CFG.CUPULA_FORCA,
								CFG.CUPULA_RAIO) then
							anotarPeca(peca)
						end
					end
				end))

				-- o dano é LENTO: a cúpula não é um golpe, é um lugar de onde
				-- é difícil sair
				local tique = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					tique = tique + dt
					if tique < 1 then return end
					tique = 0
					for _, alvo in ipairs(alvosEm(centro, CFG.CUPULA_RAIO, 10)) do
						aplicarDano(alvo, CFG.CUPULA_DANO)
					end
				end))

				task.delay(CFG.CUPULA_VIDA, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a implosão
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(20))
		+ Vector3.new(0, 3, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "CUPULA", 1.25 } },

		IMPLOSAO = {
			sfx = { "IMPLOSAO", 0.9 },
			faz = function()
				vfx("IMPLOSAO", { ponto = centro, raio = CFG.IMPLOSAO_RAIO })
				tocarEm("IMPLOSAO", centro, 0.8)

				for _, alvo in ipairs(alvosEm(centro, CFG.IMPLOSAO_RAIO, 12)) do
					local f = puxarPara(alvo, centro, CFG.IMPLOSAO_PUXAO)
					aplicarDano(alvo, math.floor(CFG.IMPLOSAO_DANO * f + 0.5))
					marcar(alvo, MEU_POLO)
					desabar(alvo, CFG.DESABA)
				end

				for _, peca in ipairs(pecasEm(centro, CFG.IMPLOSAO_RAIO,
						CFG.TETO_ATRAIDAS)) do
					if atrairPeca(peca, centro, CFG.IMPLOSAO_PUXAO * 3,
							CFG.IMPLOSAO_RAIO) then
						anotarPeca(peca)
					end
				end
				task.delay(0.9, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 2 · POLO SUL — repulsão
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Polo Sul"] = dict(
    objeto="PoloSul_Server_V1",
    tool="Polo Sul",
    sufixo="PoloSul",
    arquetipo="Sul",
    rotulo_m1="empurra o cone à frente, e carrega de SUL",
    rotulo_r="o escudo que repele quem chega",
    rotulo_t="a onda que limpa o círculo",
    rotulo_botao_r="Escudo",
    rotulo_botao_t="Onda",
    alcance_mira=80,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 0.9,
	RECARGA_R = 14,
	RECARGA_T = 24,

	DANO = 18,
	ALCANCE = 22,
	--- cos(58°) — mais aberto que o do Norte. Empurrar para longe o que está
	--- ao lado é útil; puxar para si o que está ao lado não é.
	COSSENO = 0.53,
	LIMITE = 8,
	EMPURRAO = 88,
	SUBIDA = 0.4,

	ESCUDO_RAIO = 9,
	ESCUDO_VIDA = 2.4,
	ESCUDO_FORCA = 74,
	ESCUDO_PERIODO = 0.16,

	ONDA_RAIO = 20,
	ONDA_DANO = 40,
	ONDA_FORCA = 126,
	TETO_PECAS_ONDA = 24,
	DESABA = 1.6,
""",
    estado="",
    ao_equipar="",
    ao_guardar="",
    corpo='''
local MEU_POLO = "SUL"

--- Empurra PARA LONGE de um ponto, com o bônus da polaridade.
---
--- `fatorDe(alvo, MEU_POLO, false)` — o `false` é "estou REPELINDO". Carga
--- igual repele mais forte; oposta não. É a física, e é o que faz valer a pena
--- carregar alguém de SUL antes de empurrá-lo.
local function empurrarDe(alvoHum, centro, forca, subida)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return 0 end
	local delta = alvoRaiz.Position - centro
	if delta.Magnitude < 0.6 then
		delta = raiz and raiz.CFrame.LookVector or Vector3.new(0, 0, -1)
	end
	local f = fatorDe(alvoHum, MEU_POLO, false)
	local para = (delta.Unit + Vector3.new(0, subida or CFG.SUBIDA, 0)).Unit
	empurrar(alvoHum, para, forca * f, 0.26)
	return f
end

--══════════════════════════════════════════════════════════════
-- M1 — empurrar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		EMPURRAR = {
			sfx = { "EMPURRAR", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local centro = raiz.Position

				vfx("EMPURRAR", { ponto = centro + direcao * 3, eixo = direcao,
					raio = CFG.ALCANCE * 0.5 })

				for _, alvo in ipairs(alvosNoCone(centro, direcao, CFG.ALCANCE,
						CFG.COSSENO, CFG.LIMITE)) do
					local f = empurrarDe(alvo, centro, CFG.EMPURRAO)
					aplicarDano(alvo, math.floor(CFG.DANO * f + 0.5))
					marcar(alvo, MEU_POLO)
				end

				for _, peca in ipairs(pecasEm(centro + direcao * 6,
						CFG.ALCANCE * 0.5, CFG.TETO_PECAS_ONDA)) do
					impulso(peca, (peca.Position - centro).Unit
						+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO * 0.7, 0.28)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — o escudo
--
-- Ele SEGUE você, e é a única habilidade do conjunto que faz isso. Um escudo
-- parado num ponto do mapa não é escudo, é uma cerca.
--══════════════════════════════════════════════════════════════

function extraR()
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		ESCUDO = {
			sfx = { "ESCUDO", 1 },
			faz = function()
				local ate = os.clock() + CFG.ESCUDO_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					if not (raiz and raiz.Parent) then return end
					acumulado = acumulado + dt
					if acumulado < CFG.ESCUDO_PERIODO then return end
					acumulado = 0

					local centro = raiz.Position
					vfx("ESCUDO", { ponto = centro, raio = CFG.ESCUDO_RAIO,
						vida = CFG.ESCUDO_PERIODO * 2 })

					for _, alvo in ipairs(alvosEm(centro, CFG.ESCUDO_RAIO, 8)) do
						empurrarDe(alvo, centro, CFG.ESCUDO_FORCA, 0.25)
						marcar(alvo, MEU_POLO)
					end
					for _, peca in ipairs(pecasEm(centro, CFG.ESCUDO_RAIO, 12)) do
						local d = peca.Position - centro
						if d.Magnitude > 0.4 then
							impulso(peca, d.Unit, CFG.ESCUDO_FORCA * 0.6, 0.2)
						end
					end
				end))
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a onda
--══════════════════════════════════════════════════════════════

function extraT()
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "ESCUDO", 1.3 } },

		ONDA = {
			sfx = { "ONDA", 0.85 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position
				vfx("ONDA", { ponto = centro, raio = CFG.ONDA_RAIO })
				tocarEm("ONDA", centro, 0.82)

				for _, alvo in ipairs(alvosEm(centro, CFG.ONDA_RAIO, 12)) do
					local alvoRaiz = raizDe(alvo)
					local queda = 1
					if alvoRaiz then
						local dist = (alvoRaiz.Position - centro).Magnitude
						queda = math.clamp(1 - (dist / CFG.ONDA_RAIO), 0.2, 1)
					end
					local f = empurrarDe(alvo, centro, CFG.ONDA_FORCA * queda, 0.6)
					aplicarDano(alvo, math.floor(CFG.ONDA_DANO * queda * f + 0.5))
					marcar(alvo, MEU_POLO)
					desabar(alvo, CFG.DESABA)
				end

				for _, peca in ipairs(pecasEm(centro, CFG.ONDA_RAIO,
						CFG.TETO_PECAS_ONDA)) do
					local d = peca.Position - centro
					if d.Magnitude > 0.4 then
						local queda = math.clamp(
							1 - (d.Magnitude / CFG.ONDA_RAIO), 0.15, 1)
						impulso(peca, (d.Unit + Vector3.new(0, 0.5, 0)).Unit,
							CFG.ONDA_FORCA * 0.8 * queda, 0.3)
						giro(peca, Vector3.new(jitter(1), jitter(2), jitter(3)),
							7, 0.5)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 3 · FERROVIA MAGNETICA
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Ferrovia Magnetica"] = dict(
    objeto="FerroviaMagnetica_Server_V1",
    tool="Ferrovia Magnetica",
    sufixo="FerroviaMagnetica",
    arquetipo="Ferrovia",
    rotulo_m1="assenta o trilho, que arrasta quem pisa",
    rotulo_r="lança você pelo próprio trilho",
    rotulo_t="cruza a malha inteira",
    rotulo_botao_r="Montar",
    rotulo_botao_t="Malha",
    alcance_mira=110,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 1.0,
	RECARGA_R = 12,
	RECARGA_T = 25,

	DANO_TIQUE = 7,
	COMPRIMENTO = 34,
	LARGURA = 3.2,
	VIDA = 5.0,
	ARRASTO = 68,
	PERIODO = 0.15,

	LANCAMENTO = 130,
	MALHA_RAIO = 16,
	MALHA_VIDA = 4.0,
	TETO_PECAS = 10,
""",
    estado="""local trilhos = {}""",
    ao_equipar="",
    ao_guardar="\ttable.clear(trilhos)\n",
    corpo='''
local MEU_POLO = "NORTE"

--══════════════════════════════════════════════════════════════
-- O TRILHO
--
-- Ele é uma peça de servidor ANCORADA e FINA, deitada no chão. Não é ela que
-- move ninguém: quem move é o laço, aplicando `impulso` a quem estiver na
-- faixa. A peça existe para o jogador VER onde a faixa está — e para colidir
-- de leve, dando a ela presença física.
--
-- O trilho não é apagado pela habilidade: ele entra em `criar()`, que tem
-- prazo, teto e três saídas.
--══════════════════════════════════════════════════════════════

local function assentarTrilho(de, ate)
	local delta = ate - de
	local dist = delta.Magnitude
	if dist < 2 then return nil end

	local meio = de + delta * 0.5
	local peca = criar(CFrame.new(meio, ate), Vector3.new(CFG.LARGURA, 0.24, dist), {
		Color = Color3.fromRGB(168, 176, 188),
		Material = Enum.Material.DiamondPlate,
		Transparency = 0.15,
		CanCollide = false,
	}, CFG.VIDA)

	local reg = { de = de, ate = ate, ate_prazo = os.clock() + CFG.VIDA }
	table.insert(trilhos, reg)
	vfx("TRILHO", { de = de, ate = ate, vida = CFG.VIDA })
	return peca, reg
end

--- Quem está NA FAIXA do trilho, e a que altura do percurso.
---
--- A projeção escalar é o que separa "está na faixa" de "está perto da linha":
--- sem ela, alguém dois metros ALÉM do fim do trilho seria arrastado por um
--- trilho que já acabou.
local function naFaixa(reg, posicao)
	local delta = reg.ate - reg.de
	local comp = delta.Magnitude
	if comp < 0.5 then return nil end
	local eixo = delta.Unit
	local t = (posicao - reg.de):Dot(eixo)
	if t < 0 or t > comp then return nil end
	local naLinha = reg.de + eixo * t
	if (posicao - naLinha).Magnitude > CFG.LARGURA then return nil end
	return eixo, t / comp
end

--══════════════════════════════════════════════════════════════
-- M1 — assentar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		TRILHO = {
			sfx = { "TRILHO", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 2 then
						direcao = Vector3.new(delta.X, 0, delta.Z)
						if direcao.Magnitude < 0.2 then
							direcao = raiz.CFrame.LookVector
						else
							direcao = direcao.Unit
						end
					end
				end

				local de = noChao(raiz.Position + direcao * 3)
					+ Vector3.new(0, 0.2, 0)
				local ate = noChao(de + direcao * CFG.COMPRIMENTO)
					+ Vector3.new(0, 0.2, 0)
				local _peca, reg = assentarTrilho(de, ate)
				if not reg then return end

				--- O ARRASTO. Repare: `impulso` ao longo do eixo, não escrita
				--- de `CFrame`. Quem está no trilho continua no controle — ele
				--- só ganha uma velocidade constante para a frente, e pode
				--- lutar contra ela. Teleportar seria tirar o jogo do jogador.
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > reg.ate_prazo then return end
					acumulado = acumulado + dt
					if acumulado < CFG.PERIODO then return end
					acumulado = 0

					for _, alvo in ipairs(alvosEm(
							(reg.de + reg.ate) * 0.5,
							CFG.COMPRIMENTO * 0.6 + CFG.LARGURA, 10)) do
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz and not ehMinha(alvoRaiz) then
							local eixo = naFaixa(reg, alvoRaiz.Position)
							if eixo then
								local f = fatorDe(alvo, MEU_POLO, false)
								impulso(alvoRaiz, eixo, CFG.ARRASTO * f,
									CFG.PERIODO + 0.05)
								aplicarDano(alvo, CFG.DANO_TIQUE)
								marcar(alvo, MEU_POLO)
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

--══════════════════════════════════════════════════════════════
-- R — montar o trilho
--
-- ⚠️ ESTA É A ÚNICA HABILIDADE DO CONJUNTO QUE MOVE O PRÓPRIO JOGADOR, e por
--    isso ela NÃO passa por `empurrar()`: aquele consulta `ehMinha()` e
--    recusaria, que é exatamente o que ele existe para fazer. Aqui a chamada é
--    `impulso()` direto na raiz, que é a intenção declarada.
--══════════════════════════════════════════════════════════════

function extraR()
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		MONTAR = {
			sfx = { "MONTAR", 1 },
			faz = function()
				if not raiz then return end

				-- o trilho MAIS RECENTE que ainda está de pé e que me contém
				local escolhido = nil
				for i = #trilhos, 1, -1 do
					local reg = trilhos[i]
					if os.clock() <= reg.ate_prazo then
						local eixo = naFaixa(reg, raiz.Position)
						if eixo then escolhido = { reg = reg, eixo = eixo } break end
					end
				end

				-- sem trilho embaixo, ele lança para a frente mesmo assim, com
				-- metade da força. Habilidade que não faz NADA quando a
				-- condição falha é habilidade que o jogador acha que bugou.
				local eixo = escolhido and escolhido.eixo or raiz.CFrame.LookVector
				local forca = escolhido and CFG.LANCAMENTO or (CFG.LANCAMENTO * 0.5)

				impulso(raiz, (eixo + Vector3.new(0, 0.28, 0)).Unit, forca, 0.3)
				vfx("MONTAR", { ponto = raiz.Position, eixo = eixo })
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a malha
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(16))
		+ Vector3.new(0, 0.2, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "TRILHO", 1.2 } },

		MALHA = {
			sfx = { "MALHA", 0.85 },
			faz = function()
				vfx("MALHA", { ponto = centro, raio = CFG.MALHA_RAIO,
					vida = CFG.MALHA_VIDA })
				tocarEm("MALHA", centro, 0.85)

				-- quatro trilhos cruzados. O ângulo áureo espalha melhor do
				-- que quatro múltiplos de 90°, que se alinham com o grid do
				-- mapa e somem visualmente contra ele.
				for i = 1, 4 do
					local a = anguloDe(i)
					local dir = Vector3.new(math.cos(a), 0, math.sin(a))
					local de = noChao(centro - dir * CFG.MALHA_RAIO)
						+ Vector3.new(0, 0.2, 0)
					local ate = noChao(centro + dir * CFG.MALHA_RAIO)
						+ Vector3.new(0, 0.2, 0)
					assentarTrilho(de, ate)
				end

				for _, alvo in ipairs(alvosEm(centro, CFG.MALHA_RAIO, 12)) do
					aplicarDano(alvo, CFG.DANO_TIQUE * 2)
					marcar(alvo, MEU_POLO)
					tombar(alvo, 1.0)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 4 · SUCATA
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Sucata"] = dict(
    objeto="Sucata_Server_V1",
    tool="Sucata",
    sufixo="Sucata",
    arquetipo="Sucata",
    rotulo_m1="junta o metal solto numa bola",
    rotulo_r="arremessa a bola",
    rotulo_t="a chuva de sucata",
    rotulo_botao_r="Arremessar",
    rotulo_botao_t="Chuva",
    alcance_mira=140,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 0.8,
	RECARGA_R = 13,
	RECARGA_T = 23,

	RAIO_COLETA = 16,
	VIDA_BOLA = 12,
	TAMANHO_BASE = 1.4,
	TAMANHO_POR_CAMADA = 0.34,
	CAMADAS_MAX = 4,
	TETO_PECAS = 6,

	DANO_BASE = 22,
	DANO_POR_CAMADA = 12,
	VELOCIDADE = 96,
	QUIQUES = 1,
	PERDA = 0.7,
	VIDA_VOO = 3.2,
	RAIO_IMPACTO = 11,
	ONDA = 92,

	CHUVA_RAIO = 12,
	CHUVA_DANO = 34,
	CHUVA_QUEDA = 0.35,
	DESABA = 1.5,
""",
    estado="""local bola = nil
local camadas = 0""",
    ao_equipar="",
    ao_guardar="\tlargarBola()\n",
    corpo='''
local MEU_POLO = "NORTE"

--══════════════════════════════════════════════════════════════
-- A BOLA — uma peça de servidor SOLTA, presa por constraint
--
-- ⚠️ Ela é o caso em que a proibição "servidor não move geometria por frame"
--    morde de verdade. Uma bola ancorada cujo `CFrame` o servidor escrevesse
--    por quadro replicaria a ~20 Hz e sem interpolação: na tela dos outros ela
--    piscaria de um lugar para outro.
--
--    Por isso ela é SOLTA (`ancorada = false`) e mantida na mão por
--    `segurar()`, que é `AlignPosition` + `AlignOrientation`. Quem a move é o
--    solver, junto com o resto do mundo — e a replicação sai de graça.
--
-- E ela CRESCE. Cada M1 junta uma camada, até `CAMADAS_MAX`, e o dano e o
-- tamanho sobem com ela. É o que faz o M1 desta Tool valer a pena repetir em
-- vez de ser um golpe qualquer.
--══════════════════════════════════════════════════════════════

local function largarBola()
	if bola and bola.Parent then
		soltarPeca(bola)
		bola.Parent = nil
	end
	bola = nil
	camadas = 0
end

local function tamanhoDaBola()
	local lado = CFG.TAMANHO_BASE + camadas * CFG.TAMANHO_POR_CAMADA
	return Vector3.new(lado, lado, lado)
end

local function pontoDeMao()
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * 3.4 + Vector3.new(0, 1.6, 0)
end

local function nascerBola()
	local p = criar(CFrame.new(pontoDeMao()), tamanhoDaBola(), {
		Shape = Enum.PartType.Ball,
		Color = Color3.fromRGB(126, 86, 62),
		Material = Enum.Material.CorrodedMetal,
		CanCollide = true,
	}, CFG.VIDA_BOLA, false)
	bola = p
	-- ela SEGUE a mão, e o seguimento é por constraint
	guardar(RunService.Heartbeat:Connect(function()
		if not (bola and bola.Parent) then return end
		if bola ~= p then return end
		segurar(p, pontoDeMao())
	end))
	return p
end

--══════════════════════════════════════════════════════════════
-- M1 — coletar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		COLETAR = {
			sfx = { "COLETAR", 1 },
			faz = function()
				if not raiz then return end
				local centro = typeof(mira) == "Vector3" and mira
					or frente(CFG.RAIO_COLETA * 0.5)

				vfx("COLETAR", { ponto = pontoDeMao(),
					raio = CFG.RAIO_COLETA * 0.5 })

				-- as peças do mapa são PUXADAS, e nenhuma é destruída. O que
				-- vira camada é a CONTAGEM: a bola engorda porque houve metal
				-- por perto, não porque o metal sumiu.
				local achadas = pecasEm(centro, CFG.RAIO_COLETA, 14)
				for _, peca in ipairs(achadas) do
					atrairPeca(peca, pontoDeMao(), 240, CFG.RAIO_COLETA)
				end
				task.delay(0.5, function()
					for _, peca in ipairs(achadas) do
						if peca and peca.Parent then soltarPeca(peca) end
					end
				end)

				if not (bola and bola.Parent) then
					camadas = 0
					nascerBola()
				elseif camadas < CFG.CAMADAS_MAX then
					camadas = camadas + 1
					bola.Size = tamanhoDaBola()
				end

				for _, alvo in ipairs(alvosEm(pontoDeMao(), 6, 4)) do
					marcar(alvo, MEU_POLO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — arremessar
--
-- A bola sai como PROJÉTIL BALÍSTICO por raycast, não como peça com
-- `Velocity`. A 96 studs/s uma peça salta 1,6 stud por quadro a 60 Hz, e
-- parede fina é atravessada sem o `Touched` disparar.
--══════════════════════════════════════════════════════════════

local function estourar(ponto, dano)
	vfx("ARREMESSAR", { ponto = ponto, direcao = Vector3.new(0, 1, 0) })
	tocarEm("ARREMESSAR", ponto, 0.9)

	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_IMPACTO, 10)) do
		local alvoRaiz = raizDe(alvo)
		local queda = 1
		if alvoRaiz then
			queda = math.clamp(1 - ((alvoRaiz.Position - ponto).Magnitude
				/ CFG.RAIO_IMPACTO), 0.2, 1)
		end
		local f = fatorDe(alvo, MEU_POLO, false)
		aplicarDano(alvo, math.floor(dano * queda * f + 0.5))
		if alvoRaiz then
			empurrar(alvo, ((alvoRaiz.Position - ponto).Unit
				+ Vector3.new(0, 0.6, 0)).Unit, CFG.ONDA * queda * f, 0.26)
		end
		marcar(alvo, MEU_POLO)
		desabar(alvo, CFG.DESABA)
	end
end

function extraR(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		ARREMESSAR = {
			sfx = { "ARREMESSAR", 1 },
			faz = function()
				if not raiz then return end
				if not (bola and bola.Parent) then return end

				local dano = CFG.DANO_BASE + camadas * CFG.DANO_POR_CAMADA
				local saida = bola.Position
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - saida
					if delta.Magnitude > 2 then
						direcao = (delta.Unit + Vector3.new(0, 0.18, 0)).Unit
					end
				end

				largarBola()

				local acabou = false
				dispararProjetil(saida, direcao, CFG.VELOCIDADE, {
					quiques = CFG.QUIQUES,
					perda = CFG.PERDA,
					vida = CFG.VIDA_VOO,
					raio = 0.8,
					aoAndar = function(pos)
						vfx("ARREMESSAR", { ponto = pos,
							direcao = Vector3.new(0, 1, 0) })
					end,
					aoBater = function(batida, _vel, restantes)
						local modelo = batida.Instance
							and batida.Instance:FindFirstAncestorOfClass("Model")
						local hum = modelo
							and modelo:FindFirstChildOfClass("Humanoid")
						if hum and hum ~= humanoide and hum.Health > 0 then
							return true
						end
						return restantes <= 0
					end,
					aoFim = function(ponto)
						if acabou then return end
						acabou = true
						estourar(ponto, dano)
					end,
				})
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a chuva de sucata
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(18))

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "COLETAR", 1.25 } },

		CHUVA = {
			sfx = { "CHUVA", 0.85 },
			faz = function()
				vfx("CHUVA", { ponto = centro, raio = CFG.CHUVA_RAIO })

				-- a queda tem ATRASO, e ele é o que dá tempo de sair. Ultimate
				-- que cai sem aviso é ultimate que o alvo não teve como jogar
				-- contra.
				task.delay(CFG.CHUVA_QUEDA, function()
					if not (personagem and personagem.Parent) then return end
					tocarEm("CHUVA", centro, 0.82)
					for _, alvo in ipairs(alvosEm(centro, CFG.CHUVA_RAIO, 12)) do
						local f = fatorDe(alvo, MEU_POLO, false)
						aplicarDano(alvo, math.floor(CFG.CHUVA_DANO * f + 0.5))
						marcar(alvo, MEU_POLO)
						tombar(alvo, 1.2)
					end
					for _, peca in ipairs(pecasEm(centro, CFG.CHUVA_RAIO, 16)) do
						impulso(peca, Vector3.new(jitter(1) * 0.4, -1,
							jitter(2) * 0.4), 60, 0.3)
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
# 5 · BOBINA DE TESLA
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Bobina de Tesla"] = dict(
    objeto="BobinadeTesla_Server_V1",
    tool="Bobina de Tesla",
    sufixo="BobinadeTesla",
    arquetipo="Bobina",
    rotulo_m1="o arco salta de alvo em alvo",
    rotulo_r="planta a bobina que pulsa",
    rotulo_t="descarrega em todos os carregados",
    rotulo_botao_r="Bobina",
    rotulo_botao_t="Descarga",
    alcance_mira=100,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 0.8,
	RECARGA_R = 16,
	RECARGA_T = 27,

	DANO = 20,
	--- Cada salto perde força. Sem isso um arco de seis pulos daria seis vezes
	--- o dano, e a habilidade viraria a única do conjunto que importa.
	QUEDA_POR_SALTO = 0.76,
	ALCANCE = 30,
	SALTO = 18,
	SALTOS_MAX = 5,

	BOBINA_RAIO = 10,
	BOBINA_VIDA = 4.0,
	BOBINA_PERIODO = 0.7,
	BOBINA_DANO = 9,
	TETO_PECAS = 4,

	DESCARGA_RAIO = 24,
	DESCARGA_DANO = 46,
	DESCARGA_EMPURRAO = 70,
	DESABA = 1.7,
""",
    estado="",
    ao_equipar="",
    ao_guardar="",
    corpo='''
local MEU_POLO = "SUL"

--══════════════════════════════════════════════════════════════
-- M1 — o arco em cadeia
--
-- Ele salta para o alvo mais PRÓXIMO ainda não atingido, e cada salto perde
-- força. `vistos` é o que impede o arco de ficar pingando entre dois alvos
-- para sempre — sem ele, dois inimigos lado a lado consomem os cinco saltos
-- entre si e o resto da sala não é tocado.
--══════════════════════════════════════════════════════════════

local function maisPerto(de, vistos)
	local melhor, menor = nil, math.huge
	for _, alvo in ipairs(alvosEm(de, CFG.SALTO, 12)) do
		if not vistos[alvo] then
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				local d = (alvoRaiz.Position - de).Magnitude
				if d < menor then melhor, menor = alvo, d end
			end
		end
	end
	return melhor
end

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		ARCO = {
			sfx = { "ARCO", 1 },
			faz = function()
				if not raiz then return end
				local origem = raiz.Position + Vector3.new(0, 2.2, 0)

				-- o primeiro alvo: o mais perto da MIRA, não de mim
				local foco = typeof(mira) == "Vector3" and mira
					or frente(CFG.ALCANCE * 0.5)
				local vistos = {}
				local atual = nil
				local menor = math.huge
				for _, alvo in ipairs(alvosEm(origem, CFG.ALCANCE, 14)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - foco).Magnitude
						if d < menor then atual, menor = alvo, d end
					end
				end

				local de = origem
				local forca = 1
				for _salto = 1, CFG.SALTOS_MAX do
					if not atual then break end
					local alvoRaiz = raizDe(atual)
					if not alvoRaiz then break end

					vistos[atual] = true
					vfx("ARCO", { de = de, ate = alvoRaiz.Position })
					local f = fatorDe(atual, MEU_POLO, false)
					aplicarDano(atual, math.floor(CFG.DANO * forca * f + 0.5))
					marcar(atual, MEU_POLO)

					de = alvoRaiz.Position
					forca = forca * CFG.QUEDA_POR_SALTO
					atual = maisPerto(de, vistos)
				end

				-- sem ninguém no caminho, o arco vai para a mira mesmo assim.
				-- Habilidade que não desenha nada quando erra é habilidade que
				-- o jogador acha que não disparou.
				if next(vistos) == nil then
					vfx("ARCO", { de = origem, ate = foco })
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a bobina
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(10))

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		BOBINA = {
			sfx = { "BOBINA", 1 },
			faz = function()
				local peca = criar(CFrame.new(centro + Vector3.new(0, 1.6, 0)),
					Vector3.new(1.6, 3.2, 1.6), {
						Color = Color3.fromRGB(196, 122, 62),
						Material = Enum.Material.Metal,
						CanCollide = true,
					}, CFG.BOBINA_VIDA)
				if not peca then return end

				vfx("BOBINA", { ponto = centro + Vector3.new(0, 2, 0),
					raio = CFG.BOBINA_RAIO, vida = CFG.BOBINA_VIDA })

				local ate = os.clock() + CFG.BOBINA_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					if not (peca and peca.Parent) then return end
					acumulado = acumulado + dt
					if acumulado < CFG.BOBINA_PERIODO then return end
					acumulado = 0

					local topo = peca.Position + Vector3.new(0, 1.8, 0)
					for _, alvo in ipairs(alvosEm(peca.Position,
							CFG.BOBINA_RAIO, 8)) do
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							vfx("ARCO", { de = topo, ate = alvoRaiz.Position })
						end
						local f = fatorDe(alvo, MEU_POLO, false)
						aplicarDano(alvo, math.floor(CFG.BOBINA_DANO * f + 0.5))
						marcar(alvo, MEU_POLO)
					end
					tocarEm("ARCO", topo, 1.1)
				end))
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a descarga
--
-- ⭐ É A HABILIDADE QUE PAGA A POLARIDADE. Ela só atinge quem está CARREGADO,
--    e é por isso que ela vale a recarga de 27 s: quem passou o jogo inteiro
--    marcando alvos com as outras seis Tools colhe aqui.
--
--    Se ela atingisse todo mundo, a carga seria enfeite.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = typeof(mira) == "Vector3" and mira or frente(16)

    ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "BOBINA", 1.3 } },

		DESCARGA = {
			sfx = { "DESCARGA", 0.85 },
			faz = function()
				local marcados = carregadosEm(centro, CFG.DESCARGA_RAIO, 12)

				local pontos = {}
				for _, reg in ipairs(marcados) do
					local alvoRaiz = raizDe(reg.hum)
					if alvoRaiz then table.insert(pontos, alvoRaiz.Position) end
				end
				vfx("DESCARGA", { ponto = centro, raio = CFG.DESCARGA_RAIO,
					alvos = pontos })
				tocarEm("DESCARGA", centro, 0.82)

				for _, reg in ipairs(marcados) do
					local alvoRaiz = raizDe(reg.hum)
					-- carga IGUAL à minha leva mais: é o mesmo pólo se
					-- repelindo, e é o que a Tool passou o jogo montando
					local f = (reg.polo == MEU_POLO) and CFG.BONUS_IGUAL or 1
					aplicarDano(reg.hum,
						math.floor(CFG.DESCARGA_DANO * f + 0.5))
					if alvoRaiz then
						empurrar(reg.hum, ((alvoRaiz.Position - centro).Unit
							+ Vector3.new(0, 0.7, 0)).Unit,
							CFG.DESCARGA_EMPURRAO * f, 0.28)
					end
					desabar(reg.hum, CFG.DESABA)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
# 6 · LEVITACAO
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Levitacao"] = dict(
    objeto="Levitacao_Server_V1",
    tool="Levitacao",
    sufixo="Levitacao",
    arquetipo="Levitacao",
    rotulo_m1="suspende o alvo no ar",
    rotulo_r="você flutua",
    rotulo_t="inverte a gravidade da área",
    rotulo_botao_r="Flutuar",
    rotulo_botao_t="Inverter",
    alcance_mira=90,
    cutscene=False,
    extra_require="",
    cfg="""	RECARGA = 1.0,
	RECARGA_R = 14,
	RECARGA_T = 28,

	DANO = 12,
	ALCANCE = 30,
	ALTURA = 9,
	SUSPENSO = 2.6,
	TETO_PECAS = 4,

	FLUTUA_VIDA = 3.0,
	FLUTUA_ALTURA = 11,

	INVERTE_RAIO = 20,
	INVERTE_VIDA = 3.4,
	INVERTE_FORCA = 210,
	INVERTE_PERIODO = 0.16,
	INVERTE_DANO = 6,
	DESABA = 1.4,
""",
    estado="""local suspensos = setmetatable({}, { __mode = "k" })
local flutuando = false""",
    ao_equipar="",
    ao_guardar="\tdescerTudo()\n\tpousar()\n",
    corpo='''
local MEU_POLO = "NORTE"

--══════════════════════════════════════════════════════════════
-- SUSPENDER — `AlignPosition` na raiz, e ele SEMPRE solta
--
-- ⚠️ Suspender é um efeito de status, e efeito de status tem de voltar. Um
--    `AlignPosition` órfão num jogador é um jogador preso no ar até o servidor
--    cair, e não há tecla que o resolva do lado dele.
--
--    Por isso são TRÊS saídas: o prazo, o `descerTudo()` do `desmontar()`, e a
--    checagem de que o alvo ainda existe. `soltarPeca` tira só o que ESTA Tool
--    pendurou — o `PREFIXO` carrega o arquétipo, então duas Tools do conjunto
--    na mesma pessoa não desfazem uma à outra.
--══════════════════════════════════════════════════════════════

local function descer(alvoHum)
	local reg = suspensos[alvoHum]
	if not reg then return end
	suspensos[alvoHum] = nil
	if reg.peca and reg.peca.Parent then
		soltarPeca(reg.peca)
	end
	if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
		alvoHum.PlatformStand = false
	end
end

local function descerTudo()
	for alvoHum in pairs(suspensos) do
		descer(alvoHum)
	end
end

local function suspender(alvoHum, altura, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return end
	if suspensos[alvoHum] then return end

	local destino = alvoRaiz.Position + Vector3.new(0, altura, 0)
	segurar(alvoRaiz, destino)
	-- mole enquanto sobe: um corpo rígido suspenso fica de pé no ar, o que lê
	-- como bug em vez de como levitação
	alvoHum.PlatformStand = true
	suspensos[alvoHum] = { peca = alvoRaiz, ate = os.clock() + tempo }

	vfx("SUSPENDER", { ponto = destino, vida = tempo })
	task.delay(tempo, function() descer(alvoHum) end)
end

--══════════════════════════════════════════════════════════════
-- M1 — suspender o alvo
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		SUSPENDER = {
			sfx = { "SUSPENDER", 1 },
			faz = function()
				if not raiz then return end
				local foco = typeof(mira) == "Vector3" and mira
					or frente(CFG.ALCANCE * 0.5)

				local escolhido, menor = nil, math.huge
				for _, alvo in ipairs(alvosEm(raiz.Position, CFG.ALCANCE, 12)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - foco).Magnitude
						if d < menor then escolhido, menor = alvo, d end
					end
				end
				if not escolhido then
					vfx("SUSPENDER", { ponto = foco, vida = 0.6 })
					return
				end

				local f = fatorDe(escolhido, MEU_POLO, true)
				suspender(escolhido, CFG.ALTURA, CFG.SUSPENSO * f)
				aplicarDano(escolhido, math.floor(CFG.DANO * f + 0.5))
				marcar(escolhido, MEU_POLO)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — flutuar
--
-- Como o `MONTAR` da Ferrovia, esta é sobre o PRÓPRIO jogador e por isso NÃO
-- passa por `empurrar()`: aquele consulta `ehMinha()` e recusaria.
--══════════════════════════════════════════════════════════════

local function pousar()
	if not flutuando then return end
	flutuando = false
	if raiz and raiz.Parent then soltarPeca(raiz) end
	if humanoide and humanoide.Parent then
		humanoide.PlatformStand = false
	end
end

function extraR()
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		FLUTUAR = {
			sfx = { "FLUTUAR", 1 },
			faz = function()
				if not raiz then return end
				flutuando = true
				local destino = raiz.Position + Vector3.new(0, CFG.FLUTUA_ALTURA, 0)
				vfx("FLUTUAR", { ponto = destino, vida = CFG.FLUTUA_VIDA })

				local ate = os.clock() + CFG.FLUTUA_VIDA
				guardar(RunService.Heartbeat:Connect(function()
					if not flutuando then return end
					if os.clock() > ate then
						pousar()
						return
					end
					if raiz and raiz.Parent then
						segurar(raiz, destino)
					end
				end))
				task.delay(CFG.FLUTUA_VIDA, pousar)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — inverter a gravidade
--
-- ⛔ NADA AQUI TOCA EM `workspace.Gravity`. Ela é global do place: mexer nela
--    inverteria a gravidade de TODO MUNDO no servidor, inclusive de quem está
--    do outro lado do mapa e não pediu. A verificação de autocontenção proíbe
--    escrever nela, e a proibição está certa.
--
--    A inversão aqui é LOCAL e por força: `VectorForce` para cima em cada peça
--    solta, e impulso para cima em cada humanoide da área.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(16))
		+ Vector3.new(0, 4, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "SUSPENDER", 1.2 } },

		INVERTER = {
			sfx = { "INVERTER", 0.85 },
			faz = function()
				vfx("INVERTER", { ponto = centro, raio = CFG.INVERTE_RAIO,
					vida = CFG.INVERTE_VIDA })
				tocarEm("INVERTER", centro, 0.85)

				local tocadas = {}
				local ate = os.clock() + CFG.INVERTE_VIDA
				local acumulado, tique = 0, 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					tique = tique + dt
					if acumulado < CFG.INVERTE_PERIODO then return end
					acumulado = 0

					-- o TETO da atração está no centro ACIMA do chão: as peças
					-- sobem porque estão sendo puxadas para lá
					for _, peca in ipairs(pecasEm(centro, CFG.INVERTE_RAIO, 24)) do
						if atrairPeca(peca, centro + Vector3.new(0, 8, 0),
								CFG.INVERTE_FORCA, CFG.INVERTE_RAIO) then
							local ja = false
							for _, p in ipairs(tocadas) do
								if p == peca then ja = true break end
							end
							if not ja then table.insert(tocadas, peca) end
						end
					end

					for _, alvo in ipairs(alvosEm(centro, CFG.INVERTE_RAIO, 10)) do
						local f = fatorDe(alvo, MEU_POLO, true)
						empurrar(alvo, Vector3.new(jitter(1) * 0.12, 1,
							jitter(2) * 0.12), 46 * f, CFG.INVERTE_PERIODO + 0.05)
						marcar(alvo, MEU_POLO)
					end

					if tique >= 1 then
						tique = 0
						for _, alvo in ipairs(alvosEm(centro,
								CFG.INVERTE_RAIO, 10)) do
							aplicarDano(alvo, CFG.INVERTE_DANO)
						end
					end
				end))

				task.delay(CFG.INVERTE_VIDA, function()
					for _, peca in ipairs(tocadas) do
						if peca and peca.Parent then soltarPeca(peca) end
					end
					table.clear(tocadas)
					-- e quem estava no ar cai, e cai mole
					for _, alvo in ipairs(alvosEm(centro, CFG.INVERTE_RAIO, 10)) do
						desabar(alvo, CFG.DESABA)
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
# 7 · COLAPSO MAGNETICO — a ultimate, com cena
# ═══════════════════════════════════════════════════════════════

CONJUNTO["Colapso Magnetico"] = dict(
    objeto="ColapsoMagnetico_Server_V1",
    tool="Colapso Magnetico",
    sufixo="ColapsoMagnetico",
    arquetipo="Colapso",
    rotulo_m1="marca o alvo com carga, ALTERNANDO o pólo",
    rotulo_r="as cargas se atraem",
    rotulo_t="a singularidade, com cena",
    rotulo_botao_r="Atrair",
    rotulo_botao_t="Colapso",
    alcance_mira=120,
    cutscene=True,
    extra_require='local CutsceneRemote = Tool:WaitForChild("CutsceneRemote")\n',
    cfg="""	RECARGA = 1.1,
	RECARGA_R = 18,
	RECARGA_T = 46,

	DANO = 10,
	ALCANCE = 34,
	TETO_PECAS = 4,

	ATRAI_RAIO = 26,
	ATRAI_FORCA = 108,
	ATRAI_DANO = 26,

	SING_RAIO = 28,
	SING_DANO = 78,
	SING_FORCA = 150,
	SING_ESPERA = 1.1,
	SING_CENA = 22,
	DESABA = 2.4,
""",
    estado="""local proximoPolo = "NORTE\"""",
    ao_equipar="",
    ao_guardar="\tfecharCena()\n",
    corpo='''
--══════════════════════════════════════════════════════════════
-- ESTA TOOL ALTERNA O PÓLO, e é a única que faz isso
--
-- As outras seis emitem um pólo fixo, e é o que as torna previsíveis: quem vê
-- um `Polo Sul` na mão sabe o que vai sair. Esta é a que MONTA a combinação, e
-- para isso precisa poder pôr as duas cargas em campo — sem alternar, ela não
-- teria como criar um par oposto, que é o que o `ATRAIR_CARGAS` explora.
--══════════════════════════════════════════════════════════════

local function alternar()
	local polo = proximoPolo
	proximoPolo = (polo == "NORTE") and "SUL" or "NORTE"
	return polo
end

--══════════════════════════════════════════════════════════════
-- M1 — carregar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CARGA = {
			sfx = { "CARGA", 1 },
			faz = function()
				if not raiz then return end
				local foco = typeof(mira) == "Vector3" and mira
					or frente(CFG.ALCANCE * 0.5)

				local escolhido, menor = nil, math.huge
				for _, alvo in ipairs(alvosEm(raiz.Position, CFG.ALCANCE, 12)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - foco).Magnitude
						if d < menor then escolhido, menor = alvo, d end
					end
				end
				if not escolhido then
					vfx("CARGA", { ponto = foco, polaridade = proximoPolo })
					return
				end

				local polo = alternar()
				aplicarDano(escolhido, CFG.DANO)
				marcar(escolhido, polo)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — as cargas se atraem
--
-- ⭐ A SEGUNDA HABILIDADE QUE PAGA A POLARIDADE. Ela puxa os CARREGADOS para o
--    centroide deles — e quem tem pólo OPOSTO ao do vizinho mais próximo vai
--    mais forte, porque é isso que ímãs opostos fazem.
--
--    Sem ninguém carregado ela não faz nada, e é de propósito: é a habilidade
--    que cobra o preço de ter usado as outras seis antes.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local foco = typeof(mira) == "Vector3" and mira or frente(16)

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		ATRAIR_CARGAS = {
			sfx = { "ATRAIR_CARGAS", 1 },
			faz = function()
				local marcados = carregadosEm(foco, CFG.ATRAI_RAIO, 12)
				if #marcados == 0 then
					vfx("ATRAIR_CARGAS", { ponto = foco, raio = CFG.ATRAI_RAIO,
						alvos = {} })
					return
				end

				-- o CENTROIDE dos carregados, não o ponto mirado: são eles que
				-- se atraem entre si, e o jogador só apontou onde olhar
				local soma, n = Vector3.new(), 0
				local pontos = {}
				for _, reg in ipairs(marcados) do
					local alvoRaiz = raizDe(reg.hum)
					if alvoRaiz then
						soma = soma + alvoRaiz.Position
						n = n + 1
						table.insert(pontos, alvoRaiz.Position)
					end
				end
				if n == 0 then return end
				local centro = soma / n

				vfx("ATRAIR_CARGAS", { ponto = centro, raio = CFG.ATRAI_RAIO,
					alvos = pontos, polaridade = proximoPolo })
				tocarEm("ATRAIR_CARGAS", centro, 0.88)

				for _, reg in ipairs(marcados) do
					local alvoRaiz = raizDe(reg.hum)
					if alvoRaiz and not ehMinha(alvoRaiz) then
						-- quem tem pólo diferente do meu PRÓXIMO é o par
						-- oposto, e vai mais forte
						local f = (reg.polo ~= proximoPolo)
							and CFG.BONUS_OPOSTO or 1
						local delta = centro - alvoRaiz.Position
						if delta.Magnitude > 0.6 then
							empurrar(reg.hum, delta.Unit,
								CFG.ATRAI_FORCA * f, 0.3)
						end
						aplicarDano(reg.hum,
							math.floor(CFG.ATRAI_DANO * f + 0.5))
						tombar(reg.hum, 1.1)
					end
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a singularidade, com CENA
--
-- Quatro beats, e TRÊS deles caem no meio do passo (`quando`). Sem isso a
-- sequência precisaria de nove passos para o mesmo desenho — cada marca
-- exigiria um passo próprio só para ter onde ser pendurada.
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(20))
		+ Vector3.new(0, 5, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CENA_ABRE = {
			cam = true, ponto = centro,
			sfx = { "CARGA", 0.85 },
			faz = function()
				abrirCena(centro, CFG.SING_CENA, "CENA_ABRE")
			end,
		},

		CENA_CARGA = {
			cam = true, ponto = centro,
			sfx = { "ATRAIR_CARGAS", 0.8 },
			faz = function()
				-- a carga puxa devagar ANTES do colapso: é o aviso, e é o que
				-- dá tempo de sair
				local ate = os.clock() + CFG.SING_ESPERA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					if acumulado < 0.16 then return end
					acumulado = 0
					for _, alvo in ipairs(alvosEm(centro, CFG.SING_RAIO, 12)) do
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							local delta = centro - alvoRaiz.Position
							if delta.Magnitude > 1 then
								empurrar(alvo, delta.Unit, 34, 0.2)
							end
						end
					end
					for _, peca in ipairs(pecasEm(centro, CFG.SING_RAIO, 26)) do
						atrairPeca(peca, centro, 150, CFG.SING_RAIO)
					end
				end))
			end,
		},

		SINGULARIDADE = {
			cam = true, ponto = centro,
			sfx = { "SINGULARIDADE", 0.75 },
			faz = function()
				vfx("SINGULARIDADE", { ponto = centro, raio = CFG.SING_RAIO })
				tocarEm("SINGULARIDADE", centro, 0.72)

				for _, alvo in ipairs(alvosEm(centro, CFG.SING_RAIO, 14)) do
					local alvoRaiz = raizDe(alvo)
					local queda = 1
					if alvoRaiz then
						queda = math.clamp(1 - ((alvoRaiz.Position - centro)
							.Magnitude / CFG.SING_RAIO), 0.25, 1)
					end
					-- carregado leva mais, seja qual for o pólo: no colapso o
					-- que importa é ter carga, não qual
					local f = polaridadeDe(alvo) and CFG.BONUS_OPOSTO or 1
					aplicarDano(alvo,
						math.floor(CFG.SING_DANO * queda * f + 0.5))
					if alvoRaiz then
						local delta = centro - alvoRaiz.Position
						if delta.Magnitude > 0.6 then
							empurrar(alvo, delta.Unit,
								CFG.SING_FORCA * queda * f, 0.34)
						end
					end
					desabar(alvo, CFG.DESABA)
				end

				local puxadas = pecasEm(centro, CFG.SING_RAIO, 30)
				for _, peca in ipairs(puxadas) do
					atrairPeca(peca, centro, 320, CFG.SING_RAIO)
				end
				task.delay(1.4, function()
					for _, peca in ipairs(puxadas) do
						if peca and peca.Parent then soltarPeca(peca) end
					end
				end)
			end,
		},

		CENA_FIM = {
			cam = true, ponto = centro,
			faz = function()
				fecharCena()
			end,
		},

	}), function()
		ocupado = false
		--- A cena fecha por DUAS portas: o beat `CENA_FIM` e este `onDone`. O
		--- beat pode não chegar se a sequência for cancelada no meio, e câmera
		--- presa é o pior do repertório.
		fecharCena()
	end)
end
''')
