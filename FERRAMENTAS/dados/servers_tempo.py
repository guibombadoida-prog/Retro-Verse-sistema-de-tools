"""
servers_tempo.py — as 21 habilidades do conjunto TEMPO.

Sete Tools, TRÊS habilidades cada: M1 no clique, `R` e `T` nas teclas. Lido
por `FERRAMENTAS/gerar_servers_tempo.py`.

CADA UMA DAS 21 DESCENDE DE ALGO QUE A ORIGEM FAZIA

    O `timetools.rbxmx` trouxe três Tools e seis ideias. As 21 habilidades
    daqui saem delas — nenhuma foi inventada do nada:

      congelar em quatro eixos      -> `Instante Parado` inteira
      gravar CFrame e devolver      -> `Reversao` inteira
      o fantasma vermelho adiantado -> `Paradoxo` inteira
      o portão Sol/Lua              -> `Cajado Celeste` M1
      a chuva de fótons             -> `Cajado Celeste` M1 de dia
      a lâmina que atravessa        -> `Cajado Celeste` T
      o holofote                    -> `Cajado Celeste` R
      `PlaybackSpeed` indo a zero   -> `Lentidao` (o mundo escorregando)
      `TimeScale = 0`               -> `Aceleracao` (o mesmo eixo, invertido)

    `Fim do Relogio` é a única sem ancestral direto: ela é a ultimate, e junta
    o congelamento, a atração e o estouro num arco só.

O QUE MUDA EM RELAÇÃO À ORIGEM, EM UMA FRASE

    Tudo que é mexido é devolvido. A origem não devolvia, e uma Tool destruída
    no meio deixava o mapa ancorado para sempre.
"""

COM_CUTSCENE = ("Fim do Relogio",)

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Instante Parado",
  objeto="InstanteParado_Server_V1", sufixo="TempoParada",
  arquetipo="ARCANO", alcance_mira=60,
  rotulo_m1="Travar", rotulo_r="Zona Parada", rotulo_t="Retomar",
  origem=["Handle autoral: relogio de bolso (a origem nao tinha Handle —",
          "`Para o tempo` vinha com RequiresHandle = false)",
          "TRAVA 12221967 (Press) · PARA 5326246476 (Timestop)",
          "RETOMA 3101648169 (Resume) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 40,
	RECARGA       = 1.0,
	TEMPO_TRAVA   = 2.5,
	DANO_TRAVA    = 18,

	RECARGA_R     = 20,
	RAIO_ZONA     = 34,
	TEMPO_ZONA    = 5,
	DANO_ZONA     = 10,

	RECARGA_T     = 16,
	FATOR_GUARDADO = 1.0,
	TETO_GUARDADO = 220,
	EMPURRAO      = 90,
	TOMBO         = 1.4,""",
  estado="""local zonaId, zonaOnde, zonaAte = nil, nil, 0
--- O dano que caiu em quem estava congelado, para cair de uma vez no `T`.
--- Chave FRACA: alvo que sai do jogo leva a conta dele junto.
local guardado = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	pararZona()
""",
  corpo='''
--''' + R + '''
-- O DANO GUARDADO
--
-- Esta é a melhoria de desenho sobre a origem. Lá, congelar era só congelar:
-- o alvo ficava parado e você batia nele normalmente. Aqui o dano que cai em
-- quem está congelado NÃO É APLICADO na hora — ele é ANOTADO, e cai todo de
-- uma vez quando o tempo volta.
--
-- É o que transforma a parada do tempo de "alvo parado" em "conta a pagar", e
-- é o que dá razão para o `T` existir.
--
-- O TETO existe porque sem ele um alvo congelado por 5 s acumula o dano de
-- cinco segundos de todo mundo do servidor, e morre de uma vez sem que nada
-- na tela tenha avisado.
--''' + R + '''

local function anotarDano(alvoHum, quanto)
	if not alvoHum then return end
	local conta = (guardado[alvoHum] or 0) + quanto
	guardado[alvoHum] = math.min(conta, CFG.TETO_GUARDADO)
end

local function cobrarGuardado(alvoHum)
	local conta = guardado[alvoHum]
	if not conta or conta <= 0 then return 0 end
	guardado[alvoHum] = nil
	aplicarDano(alvoHum, math.floor(conta * CFG.FATOR_GUARDADO + 0.5))
	return conta
end

--''' + R + '''
-- M1 — travar um alvo
--
-- O estalo: 0.60 s de animação, o molde mais curto do repositório. Parar o
-- tempo tem de ser mais rápido do que qualquer coisa que se possa fazer para
-- impedir.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local ponto = mira

	ocupado = true
	rig:PlaySequence("TRAVAR", despachar({

		CARGA = { sfx = { "TRAVA", 1.2 } },

		GOLPE = {
			sfx = { "TRAVA", 1.0 },
			faz = function()
				if not raiz then return end
				local onde = (typeof(ponto) == "Vector3") and ponto or frente()

				-- o mais perto do ponto mirado, não uma área: o M1 é
				-- cirúrgico, e a área é o R
				local perto, dist = nil, math.huge
				for _, alvo in ipairs(alvosEm(onde, 14, 10)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - onde).Magnitude
						if d < dist then perto, dist = alvo, d end
					end
				end
				if not perto then return end

				aplicarDano(perto, CFG.DANO_TRAVA)
				if congelarHumanoide(perto, CFG.TEMPO_TRAVA) then
					local pr = raizDe(perto)
					vfx("TRAVA", { peca = pr, duracao = CFG.TEMPO_TRAVA,
						posicao = pr and pr.Position or onde })
					tocarEm("TRAVA", pr and pr.Position or onde, 1.05)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — a zona parada
--
-- A esfera `ForceField` da origem, com a malha e a textura dela. Quem entra
-- congela; o dano que cair em quem está congelado fica ANOTADO.
--
-- A ORIGEM VARRIA `workspace:GetDescendants()` e ancorava o mundo inteiro.
-- Aqui é `GetPartBoundsInRadius` num raio declarado, e cada peça ancorada
-- entra no registro com o estado de antes.
--''' + R + '''

function pararZona()
	if zonaId then
		vfx("PARAR", { id = zonaId })
		zonaId = nil
	end
	zonaOnde, zonaAte = nil, 0
	restaurarTudo()
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ZONA", despachar({

		CARGA = { sfx = { "PARA", 1.1 } },
		SEGURA = { sfx = { "PARA", 0.85 } },

		SOLTA = {
			sfx = { "PARA", 0.7 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				pararZona()

				zonaId = novoId("zona")
				zonaOnde = centro
				zonaAte = os.clock() + CFG.TEMPO_ZONA

				vfx("ZONA_PARADA", {
					id = zonaId, posicao = centro,
					raio = CFG.RAIO_ZONA, duracao = CFG.TEMPO_ZONA,
				})
				tocarEm("PARA", centro, 0.9)

				congelarArea(centro, CFG.RAIO_ZONA, CFG.TEMPO_ZONA, 18)

				-- quem está congelado sangra devagar, e a conta vai para o
				-- guardado em vez de cair na hora
				local function tique()
					if os.clock() > zonaAte then return end
					if not (personagem and personagem.Parent) then
						pararZona()
						return
					end
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ZONA, 18)) do
						anotarDano(alvo, CFG.DANO_ZONA)
					end
					task.delay(1, tique)
				end
				task.delay(1, tique)

				task.delay(CFG.TEMPO_ZONA, function()
					if zonaId and os.clock() > zonaAte then pararZona() end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — retomar
--
-- Solta todo mundo de uma vez, e a conta guardada cai junto. É o pagamento
-- do que o `R` preparou.
--''' + R + '''

function extraT()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("RETOMAR", despachar({

		CARGA = { sfx = { "RETOMA", 1.15 } },

		GOLPE = {
			sfx = { "RETOMA", 0.9 },
			faz = function()
				local centro = zonaOnde or (raiz and raiz.Position)
				if not centro then return end

				vfx("RETOMAR", { posicao = centro, raio = CFG.RAIO_ZONA })
				tocarEm("RETOMA", centro, 0.85)

				for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ZONA, 20)) do
					local conta = cobrarGuardado(alvo)
					descongelarHumanoide(alvo)
					if conta > 0 then
						local alvoRaiz = raizDe(alvo)
						if alvoRaiz then
							empurrar(alvo, (alvoRaiz.Position - centro)
								+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.3)
						end
						tombar(alvo, CFG.TOMBO)
					end
				end
				pararZona()
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Reversao",
  objeto="Reversao_Server_V1", sufixo="TempoReversao",
  arquetipo="ARCANO", alcance_mira=55,
  rotulo_m1="Marcar", rotulo_r="Reverter Alvo", rotulo_t="Reverter a Si",
  origem=["Handle DA ORIGEM: o do `reverter!!`, com os Sound Epitaph e Erase",
          "MARCA 3373995015 (Epitaph) · VOLTA 3373991228 (Erase)",
          "EU 3101648169 (Resume) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 45,
	RECARGA       = 1.0,
	QUADROS       = 240,
	DANO_MARCA    = 10,
	TEMPO_MARCA   = 12,

	RECARGA_R     = 18,
	DURACAO_VOLTA = 1.2,
	DANO_VOLTA    = 45,

	RECARGA_T     = 26,
	CURA_SI       = 55,
	DURACAO_SI    = 1.0,

	--- Os DOIS Sound que vieram no Handle do `reverter!!`. A origem tocava
	--- `Epitaph` ao começar a gravar e `Erase` ao devolver — os mesmos dois
	--- momentos daqui.
	SFX_EPITAPH   = "Epitaph",
	SFX_ERASE     = "Erase",""",
  estado="""local gravacao, alvoMarcado, marcaAte = nil, nil, 0
local vidaNaMarca = nil
local gravacaoPropria = nil""",
  ao_equipar="""	-- a gravação PRÓPRIA começa no Equipped e não para: o `T` precisa de um
	-- passado disponível a qualquer momento, sem o jogador ter pedido antes
	gravacaoPropria = iniciarGravacao(raiz, CFG.QUADROS)
""",
  ao_guardar="""	pararGravacao(gravacao)
	pararGravacao(gravacaoPropria)
	gravacao, gravacaoPropria, alvoMarcado = nil, nil, nil
""",
  corpo='''
--''' + R + '''
-- M1 — marcar o instante
--
-- Marca um alvo e COMEÇA A GRAVAR o trajeto dele. A origem gravava TODA
-- `BasePart` do workspace, uma corrotina por peça — num mapa de verdade isso
-- é milhares de corrotinas escrevendo num vetor a cada quadro. Aqui é UMA
-- peça: a raiz do alvo marcado.
--''' + R + '''

function primaria(mira)
	if not rig then return end
	local ponto = mira

	ocupado = true
	rig:PlaySequence("MARCAR", despachar({

		-- `Epitaph`: o som que a origem tocava ao começar a gravar
		CARGA = { sfx = { CFG.SFX_EPITAPH, 1.2 } },

		GOLPE = {
			sfx = { "MARCA", 1.0 },
			faz = function()
				if not raiz then return end
				local onde = (typeof(ponto) == "Vector3") and ponto or frente()

				local perto, dist = nil, math.huge
				for _, alvo in ipairs(alvosEm(onde, 16, 10)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - onde).Magnitude
						if d < dist then perto, dist = alvo, d end
					end
				end
				if not perto then return end

				pararGravacao(gravacao)
				alvoMarcado = perto
				marcaAte = os.clock() + CFG.TEMPO_MARCA
				vidaNaMarca = perto.Health

				local pr = raizDe(perto)
				gravacao = iniciarGravacao(pr, CFG.QUADROS)

				aplicarDano(perto, CFG.DANO_MARCA)
				vfx("MARCA_INSTANTE", { peca = pr,
					posicao = pr and pr.Position or onde })
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — reverter o alvo
--
-- Ele volta ao começo do trajeto gravado e o refaz, com o fantasma vermelho
-- 40 quadros à frente — o `beforeimage` da origem, com a cor e o atraso dela.
--
-- E A VIDA VOLTA JUNTO, MAS SÓ PARA BAIXO. Se o alvo se curou desde a marca,
-- a reversão desfaz a cura; se ele se machucou, ela NÃO cura. Reverter a vida
-- nos dois sentidos faria a Tool ser um curativo para o inimigo.
--''' + R + '''

function extraR()
	if not rig then return end
	if not (alvoMarcado and alvoMarcado.Parent) then return end
	if alvoMarcado.Health <= 0 or os.clock() > marcaAte then return end
	if not (gravacao and #gravacao.caminho > 1) then return end

	local alvo = alvoMarcado
	local caminho = gravacao.caminho
	local pr = raizDe(alvo)

	ocupado = true
	rig:PlaySequence("REVERTER", despachar({

		-- `Erase`: o som que a origem tocava ao devolver o trajeto
		CARGA = { sfx = { CFG.SFX_ERASE, 1.1 } },

		VOLTA = {
			sfx = { "VOLTA", 0.9 },
			faz = function()
				if not (alvo and alvo.Parent and pr and pr.Parent) then return end

				vfx("REVERTER", {
					id = novoId("reverter"),
					posicao = pr.Position, caminho = caminho,
					duracao = CFG.DURACAO_VOLTA,
				})
				tocarEm("VOLTA", pr.Position, 0.95)

				reverterPara(pr, caminho, CFG.DURACAO_VOLTA)
				aplicarDano(alvo, CFG.DANO_VOLTA)

				-- a vida volta SÓ PARA BAIXO
				if vidaNaMarca and alvo.Health > vidaNaMarca then
					alvo.Health = vidaNaMarca
				end

				pararGravacao(gravacao)
				gravacao, alvoMarcado, vidaNaMarca = nil, nil, nil
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — reverter a si
--
-- A gravação própria roda desde o `Equipped`, então o passado está sempre
-- disponível. Você volta ao começo do buffer e recupera vida — mas com TETO,
-- porque uma volta que cura tudo é imortalidade com recarga.
--''' + R + '''

function extraT()
	if not rig or not raiz then return end
	if not (gravacaoPropria and #gravacaoPropria.caminho > 1) then return end

	local caminho = gravacaoPropria.caminho

	ocupado = true
	rig:PlaySequence("REVERTER_EU", despachar({

		CARGA = { sfx = { "EU", 1.2 } },

		VOLTA = {
			sfx = { "EU", 0.95 },
			faz = function()
				if not (raiz and raiz.Parent and humanoide) then return end

				vfx("REVERTER_EU", {
					id = novoId("reverterEu"),
					posicao = raiz.Position, caminho = caminho,
					duracao = CFG.DURACAO_SI,
				})
				tocarEm("EU", raiz.Position, 1.0)

				reverterPara(raiz, caminho, CFG.DURACAO_SI)

				local nova = math.min(humanoide.Health + CFG.CURA_SI,
					humanoide.MaxHealth)
				humanoide.Health = nova

				-- o buffer recomeça: voltar duas vezes ao mesmo instante
				-- daria duas curas pelo mesmo passado
				pararGravacao(gravacaoPropria)
				gravacaoPropria = iniciarGravacao(raiz, CFG.QUADROS)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Cajado Celeste",
  objeto="CajadoCeleste_Server_V1", sufixo="TempoCajado",
  arquetipo="ASTRAL", alcance_mira=120, usa_astro=True,
  rotulo_m1="Sol / Lua", rotulo_r="Holofote", rotulo_t="Eco do Instante",
  origem=["Handle DA ORIGEM: o CelestialStaffModel inteiro, 33 pecas soldadas",
          "e as duas MeshPart (ARC 1204910704, Meshes/C 3084463904)",
          "LANCA 4750661969 (Cast) · HOLOFOTE 4953086953 (Effect)",
          "LAMINA 4953084421 (Aura) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 110,
	RECARGA       = 0.8,

	FOTONS        = 5,
	INTERVALO_SOL = 0.12,
	QUEDA_FOTON   = 0.7,
	ESPALHA       = 14,
	RAIO_FOTON    = 12,
	DANO_FOTON    = 26,

	VOO_LAMINA    = 1.4,
	ALCANCE_LAMINA = 120,
	LARGURA_LAMINA = 8,
	DANO_LAMINA   = 62,
	EMPURRAO_LAMINA = 60,
	PASSO_VOO     = 1 / 30,

	RECARGA_R     = 13,
	RAIO_HOLOFOTE = 20,
	TEMPO_HOLOFOTE = 4,
	PULSO_HOLOFOTE = 0.7,
	DANO_HOLOFOTE = 12,
	LENTIDAO      = 0.6,

	RECARGA_T     = 22,
	RAIO_ECO      = 16,
	DANO_ECO      = 48,
	TEMPO_ECO     = 2.0,

	--- Os QUATRO Sound que vieram pendurados no Handle da origem. Eles não
	--- estão na pasta `SFX`: estão onde o autor os pôs, e `somDe` procura nos
	--- dois lugares. `Cast` no início do M1 e `UnCast` no fim são exatamente
	--- os momentos em que o `Celestial Staff` os tocava.
	SFX_CAST      = "Cast",
	SFX_UNCAST    = "UnCast",
	SFX_PRONTO    = "ChargeReady",
	SFX_TEMPO     = "TimeSound",""",
  estado="""local holofoteId, holofoteAte = nil, 0""",
  ao_guardar="""	pararHolofote()
""",
  corpo='''
--''' + R + '''
-- M1 — O PORTÃO SOL / LUA
--
-- É a mecânica que veio inteira da origem, e a única de HORA do repositório:
-- `Lighting:GetSunDirection()` e um raycast para cima decidem QUAL habilidade
-- o M1 é.
--
--   dia    chuva de fótons no ponto mirado
--   noite  a lâmina que atravessa 120 studs
--
-- E há a terceira hora, que a origem não tratava: sol e lua os DOIS abaixo do
-- horizonte, ou um teto por cima. Lá o M1 simplesmente não fazia nada, em
-- silêncio. Aqui ele cai na lâmina — a habilidade tem de responder ao clique.
--''' + R + '''

local function chuvaDeFotons(alvo)
	local i = 0
	local function solta()
		i = i + 1
		if i > CFG.FOTONS then return end
		if not (personagem and personagem.Parent) then return end

		-- o espalhamento por ângulo áureo, nunca `math.random(-25,25)` como na
		-- origem: com todos os clientes desenhando, um sorteio faria cada um
		-- ver uma chuva diferente da que o servidor calculou para o dano
		local a = anguloDe(i)
		local raioEspalha = CFG.ESPALHA * (i / CFG.FOTONS)
		local onde = alvo + Vector3.new(math.cos(a) * raioEspalha, 0,
			math.sin(a) * raioEspalha)

		vfx("FOTON", { posicao = onde, duracao = CFG.QUEDA_FOTON })

		task.delay(CFG.QUEDA_FOTON, function()
			if not (personagem and personagem.Parent) then return end
			tocarEm("LANCA", onde, 1.1 + i * 0.04)
			for _, quem in ipairs(alvosEm(onde, CFG.RAIO_FOTON, 8)) do
				aplicarDano(quem, CFG.DANO_FOTON)
			end
		end)

		task.delay(CFG.INTERVALO_SOL, solta)
	end
	solta()
end

local function laminaDaLua()
	if not raiz then return end
	local origem = raiz.Position + Vector3.new(0, 2, 0)
	local direcao = raiz.CFrame.LookVector

	vfx("LAMINA_LUA", {
		id = novoId("lamina"), posicao = raiz.Position, direcao = direcao,
		raio = CFG.ALCANCE_LAMINA, duracao = CFG.VOO_LAMINA,
	})
	tocarEm("LAMINA", origem, 1.0)

	-- o servidor percorre a MESMA reta por aritmética. A origem movia a peça
	-- por Tween NO SERVIDOR e lia `Touched` — que é geometria movida pelo
	-- servidor, a ~20 Hz.
	task.spawn(function()
		local vistos = {}
		local percorrido = 0
		local velocidade = CFG.ALCANCE_LAMINA / CFG.VOO_LAMINA
		while percorrido < CFG.ALCANCE_LAMINA do
			task.wait(CFG.PASSO_VOO)
			if not (personagem and personagem.Parent) then return end
			percorrido = percorrido + velocidade * CFG.PASSO_VOO
			local onde = origem + direcao * math.min(percorrido,
				CFG.ALCANCE_LAMINA)
			for _, quem in ipairs(alvosEm(onde, CFG.LARGURA_LAMINA, 10)) do
				if not vistos[quem] then
					vistos[quem] = true
					aplicarDano(quem, CFG.DANO_LAMINA)
					empurrar(quem, direcao + Vector3.new(0, 0.3, 0),
						CFG.EMPURRAO_LAMINA, 0.26)
				end
			end
		end
	end)
end

function primaria(mira)
	if not rig then return end
	local ponto = mira
	local dia = ehDia()

	ocupado = true
	rig:PlaySequence("CAJADO", despachar({

		-- `Cast` no início: é o que o `Tool.Activated` da origem tocava, na
		-- primeira linha, antes mesmo de olhar o Sol
		CARGA = { sfx = { CFG.SFX_CAST, dia and 1.2 or 0.9 } },

		VARRE = {
			sfx = { dia and "LANCA" or "LAMINA", dia and 1.0 or 0.85 },
			faz = function()
				if not raiz then return end
				if dia then
					local alvo = (typeof(ponto) == "Vector3") and ponto
						or frente(CFG.ALCANCE)
					chuvaDeFotons(alvo)
				else
					laminaDaLua()
				end
			end,
		},

	}), function()
		ocupado = false
		-- e `UnCast` no fim, que é onde o `Tool.Deactivated` da origem o tocava
		tocar(CFG.SFX_UNCAST, 0.95)
	end)
end

--''' + R + '''
-- R — o holofote
--
-- A coluna da origem, com a malha dela. Quem fica debaixo sangra e sai mais
-- devagar — e `afrouxar` guarda a velocidade de ANTES.
--''' + R + '''

function pararHolofote()
	if holofoteId then
		vfx("PARAR", { id = holofoteId })
		holofoteId = nil
	end
	holofoteAte = 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("HOLOFOTE", despachar({

		CARGA = { sfx = { CFG.SFX_PRONTO, 1.1 } },
		SEGURA = { sfx = { "HOLOFOTE", 0.85 } },

		SOLTA = {
			sfx = { "LANCA", 1.15 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				pararHolofote()

				holofoteId = novoId("holofote")
				holofoteAte = os.clock() + CFG.TEMPO_HOLOFOTE

				vfx("HOLOFOTE", {
					id = holofoteId, posicao = centro,
					raio = CFG.RAIO_HOLOFOTE, duracao = CFG.TEMPO_HOLOFOTE,
				})
				tocarEm("HOLOFOTE", centro, 0.9)

				local function pulsar()
					if os.clock() > holofoteAte then
						pararHolofote()
						return
					end
					if not (personagem and personagem.Parent) then
						pararHolofote()
						return
					end
					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_HOLOFOTE, 14)) do
						aplicarDano(quem, CFG.DANO_HOLOFOTE)
						local antes = quem.WalkSpeed
						quem.WalkSpeed = antes * CFG.LENTIDAO
						task.delay(CFG.PULSO_HOLOFOTE * 1.4, function()
							if quem and quem.Parent and quem.Health > 0 then
								quem.WalkSpeed = antes
							end
						end)
					end
					task.delay(CFG.PULSO_HOLOFOTE, pulsar)
				end
				pulsar()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o eco do instante
--
-- O anel da origem, parado no ar. Quem estiver dentro dele quando ele fecha
-- leva, e fica preso pelo tempo do eco.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ECO", despachar({

		CARGA = { sfx = { CFG.SFX_TEMPO, 1.25 } },

		GOLPE = {
			sfx = { "LAMINA", 0.9 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				vfx("ECO_INSTANTE", { posicao = centro, raio = CFG.RAIO_ECO })
				tocarEm("LAMINA", centro, 0.85)

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_ECO, 12)) do
					aplicarDano(quem, CFG.DANO_ECO)
					congelarHumanoide(quem, CFG.TEMPO_ECO)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Aceleracao",
  objeto="Aceleracao_Server_V1", sufixo="TempoAceleracao",
  arquetipo="MELEE", alcance_mira=40,
  rotulo_m1="Golpe Acelerado", rotulo_r="Passo Rapido", rotulo_t="Envelhecer",
  origem=["Handle autoral: ampulheta deitada, a areia correndo depressa",
          "GOLPE 127416781 (ChargeReady) · PASSO 4750661969 (Cast)",
          "ENVELHECE 116049255 (TimeSound) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 12,
	RECARGA       = 0.6,
	GOLPES        = 3,
	INTERVALO     = 0.05,
	RAIO          = 8,
	DANO          = 16,

	RECARGA_R     = 14,
	TEMPO_PASSO   = 5,
	FATOR_ANDAR   = 1.9,
	FATOR_SALTO   = 1.35,

	RECARGA_T     = 19,
	RAIO_VELHICE  = 22,
	TEMPO_VELHICE = 4,
	TIQUES        = 5,
	DANO_BASE     = 8,
	CRESCE        = 1.55,
	LENTIDAO      = 0.6,""",
  estado="""local passoAte = 0
local meuAndar, meuSalto, minhaAltura = nil, nil, nil""",
  ao_guardar="""	devolverPasso()
""",
  corpo='''
--''' + R + '''
-- M1 — o golpe acelerado
--
-- Três golpes com 0.05 s entre eles. Não é combo: é UMA entrada, e os três
-- saem juntos demais para o olho separar. É o `TimeScale` da origem visto do
-- outro lado — lá o tempo ia a zero, aqui ele corre.
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ACELERADO", despachar({

		CARGA = { sfx = { "GOLPE", 1.35 } },

		GOLPE = {
			sfx = { "GOLPE", 1.15 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("GOLPE_RAPIDO", { posicao = raiz.Position,
					direcao = direcao, raio = CFG.RAIO })

				local n = 0
				local function bater()
					n = n + 1
					if n > CFG.GOLPES then return end
					if not (personagem and personagem.Parent and raiz) then
						return
					end
					local aqui = raiz.Position
						+ raiz.CFrame.LookVector * (CFG.ALCANCE * 0.6)
					for _, quem in ipairs(alvosEm(aqui, CFG.RAIO, 8)) do
						aplicarDano(quem, CFG.DANO)
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
-- R — o passo rápido
--
-- Guarda `WalkSpeed`, `JumpPower` e `JumpHeight` de ANTES e devolve ESSES.
-- Devolver 16 e 50 fixos quebraria qualquer personagem que tenha os dele — e
-- é o defeito clássico que a REGRA_AUTOCONTENCAO chama de "efeito de status
-- que não volta".
--''' + R + '''

function devolverPasso()
	if not humanoide then return end
	if meuAndar then humanoide.WalkSpeed = meuAndar end
	if meuSalto then humanoide.JumpPower = meuSalto end
	if minhaAltura then humanoide.JumpHeight = minhaAltura end
	meuAndar, meuSalto, minhaAltura = nil, nil, nil
	passoAte = 0
end

function extraR()
	if not rig or not humanoide then return end

	ocupado = true
	rig:PlaySequence("PASSO", despachar({

		CARGA = { sfx = { "PASSO", 1.35 } },

		GOLPE = {
			sfx = { "PASSO", 1.2 },
			faz = function()
				if not (humanoide and raiz) then return end

				-- guarda contra empilhar: acionar duas vezes guardaria o valor
				-- JÁ ACELERADO como "o de antes", e o passo nunca voltaria
				if not meuAndar then
					meuAndar = humanoide.WalkSpeed
					meuSalto = humanoide.JumpPower
					minhaAltura = humanoide.JumpHeight
				end

				humanoide.WalkSpeed = meuAndar * CFG.FATOR_ANDAR
				humanoide.JumpPower = meuSalto * CFG.FATOR_SALTO
				humanoide.JumpHeight = minhaAltura * CFG.FATOR_SALTO
				passoAte = os.clock() + CFG.TEMPO_PASSO

				vfx("PASSO_RAPIDO", { id = novoId("passo"), peca = raiz,
					duracao = CFG.TEMPO_PASSO })

				task.delay(CFG.TEMPO_PASSO, function()
					if os.clock() >= passoAte then devolverPasso() end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — envelhecer
--
-- O tempo do alvo corre depressa demais. O dano por tique CRESCE a cada
-- tique — é o que separa isto de um veneno comum, e é o que dá razão para
-- deixar o alvo vivo por quatro segundos.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("ENVELHECER", despachar({

		CARGA = { sfx = { "ENVELHECE", 1.0 } },

		VARRE = {
			sfx = { "ENVELHECE", 0.8 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				tocarEm("ENVELHECE", centro, 0.85)

				local pegos = alvosEm(centro, CFG.RAIO_VELHICE, 14)
				for _, quem in ipairs(pegos) do
					local qr = raizDe(quem)
					vfx("ENVELHECER", { id = novoId("velhice"), peca = qr,
						posicao = qr and qr.Position or centro,
						duracao = CFG.TEMPO_VELHICE })

					local antes = quem.WalkSpeed
					quem.WalkSpeed = antes * CFG.LENTIDAO
					task.delay(CFG.TEMPO_VELHICE, function()
						if quem and quem.Parent and quem.Health > 0 then
							quem.WalkSpeed = antes
						end
					end)
				end

				local tique = 0
				local passo = CFG.TEMPO_VELHICE / CFG.TIQUES
				local function envelhecer()
					tique = tique + 1
					if tique > CFG.TIQUES then return end
					if not (personagem and personagem.Parent) then return end
					local dano = CFG.DANO_BASE * (CFG.CRESCE ^ (tique - 1))
					for _, quem in ipairs(pegos) do
						aplicarDano(quem, math.floor(dano + 0.5))
					end
					task.delay(passo, envelhecer)
				end
				task.delay(passo, envelhecer)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Lentidao",
  objeto="Lentidao_Server_V1", sufixo="TempoLentidao",
  arquetipo="ARCANO", alcance_mira=50,
  rotulo_m1="Peso do Tempo", rotulo_r="Campo Lento", rotulo_t="Segundo Longo",
  origem=["Handle autoral: pendulo de bronze com haste longa",
          "PESO 65068518 (Break) · CAMPO 5326246476 (Timestop)",
          "SEGUNDO 116049255 (TimeSound) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 14,
	RECARGA       = 0.9,
	RAIO          = 9,
	DANO          = 22,
	EMPILHA_TETO  = 4,
	FATOR_PILHA   = 0.86,
	TEMPO_PILHA   = 5,

	RECARGA_R     = 15,
	RAIO_CAMPO    = 28,
	TEMPO_CAMPO   = 6,
	PULSO_CAMPO   = 0.8,
	DANO_CAMPO    = 9,
	FATOR_CAMPO   = 0.5,

	RECARGA_T     = 21,
	TEMPO_SEGUNDO = 3,
	DANO_SEGUNDO  = 40,""",
  estado="""local campoId, campoAte = nil, 0
--- Quantas vezes cada alvo levou o peso, e a velocidade de ANTES da primeira.
--- Chave FRACA: alvo que sai do jogo leva a conta junto.
local pilha = setmetatable({}, { __mode = "k" })""",
  ao_guardar="""	pararCampo()
	devolverPilhas()
""",
  corpo='''
--''' + R + '''
-- A PILHA DO PESO
--
-- Cada golpe do M1 deixa o alvo mais lento, ATÉ UM TETO. Sem teto, quatro
-- golpes deixariam o alvo com `WalkSpeed` zero — que é uma parada do tempo de
-- graça, na Tool errada.
--
-- E a velocidade guardada é a de ANTES DA PRIMEIRA. Guardar a de antes de
-- cada golpe faria a devolução restaurar um valor já reduzido, e o alvo nunca
-- voltaria ao normal.
--''' + R + '''

function devolverPilhas()
	for alvoHum, reg in pairs(pilha) do
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = reg.andar
		end
	end
	table.clear(pilha)
end

local function empilharPeso(alvoHum)
	if not alvoHum or alvoHum.Health <= 0 then return end
	local reg = pilha[alvoHum]
	if not reg then
		reg = { andar = alvoHum.WalkSpeed, camadas = 0 }
		pilha[alvoHum] = reg
	end
	reg.camadas = math.min(reg.camadas + 1, CFG.EMPILHA_TETO)
	reg.ate = os.clock() + CFG.TEMPO_PILHA
	alvoHum.WalkSpeed = reg.andar * (CFG.FATOR_PILHA ^ reg.camadas)

	task.delay(CFG.TEMPO_PILHA + 0.1, function()
		local ainda = pilha[alvoHum]
		if not ainda or os.clock() < ainda.ate then return end
		pilha[alvoHum] = nil
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.WalkSpeed = ainda.andar
		end
	end)
end

--''' + R + '''
-- M1 — o peso do tempo
--''' + R + '''

function primaria(mira)
	if not rig then return end

	ocupado = true
	rig:PlaySequence("PESO", despachar({

		CARGA = { sfx = { "PESO", 0.9 } },

		VARRE = {
			sfx = { "PESO", 0.75 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				local centro = raiz.Position + direcao * (CFG.ALCANCE * 0.6)

				vfx("PESO", { posicao = centro, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 10)) do
					aplicarDano(quem, CFG.DANO)
					empilharPeso(quem)
				end
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o campo lento
--
-- É o `PlaybackSpeed` indo a zero da origem, virado em mecânica: dentro do
-- campo tudo escorrega para o grave. Quem sai, volta ao normal — o campo lê
-- o valor de ANTES e o devolve por prazo.
--''' + R + '''

function pararCampo()
	if campoId then
		vfx("PARAR", { id = campoId })
		campoId = nil
	end
	campoAte = 0
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("CAMPO", despachar({

		CARGA = { sfx = { "CAMPO", 0.9 } },
		SEGURA = { sfx = { "CAMPO", 0.7 } },

		SOLTA = {
			sfx = { "PESO", 0.8 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				pararCampo()

				campoId = novoId("campo")
				campoAte = os.clock() + CFG.TEMPO_CAMPO

				vfx("CAMPO_LENTO", {
					id = campoId, posicao = centro,
					raio = CFG.RAIO_CAMPO, duracao = CFG.TEMPO_CAMPO,
				})
				tocarEm("CAMPO", centro, 0.75)

				local function pulsar()
					if os.clock() > campoAte then
						pararCampo()
						return
					end
					if not (personagem and personagem.Parent) then
						pararCampo()
						return
					end
					for _, quem in ipairs(alvosEm(centro, CFG.RAIO_CAMPO, 16)) do
						aplicarDano(quem, CFG.DANO_CAMPO)
						local antes = quem.WalkSpeed
						quem.WalkSpeed = antes * CFG.FATOR_CAMPO
						task.delay(CFG.PULSO_CAMPO * 1.5, function()
							if quem and quem.Parent and quem.Health > 0 then
								quem.WalkSpeed = antes
							end
						end)
					end
					task.delay(CFG.PULSO_CAMPO, pulsar)
				end
				pulsar()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o segundo longo
--
-- Um alvo só, quase parado. Usa o mesmo `congelarHumanoide` da `Parada do
-- Tempo`, e por isso a mesma garantia: o valor de antes está no registro, e
-- `restaurarTudo` roda no `Destroying`.
--''' + R + '''

function extraT(mira)
	if not rig then return end
	local ponto = mira

	ocupado = true
	rig:PlaySequence("SEGUNDO", despachar({

		CARGA = { sfx = { "SEGUNDO", 0.85 } },
		SEGURA = { sfx = { "SEGUNDO", 0.7 } },

		SOLTA = {
			sfx = { "PESO", 0.7 },
			faz = function()
				local onde = (typeof(ponto) == "Vector3") and ponto or frente()

				local perto, dist = nil, math.huge
				for _, alvo in ipairs(alvosEm(onde, 16, 10)) do
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						local d = (alvoRaiz.Position - onde).Magnitude
						if d < dist then perto, dist = alvo, d end
					end
				end
				if not perto then return end

				local pr = raizDe(perto)
				aplicarDano(perto, CFG.DANO_SEGUNDO)
				congelarHumanoide(perto, CFG.TEMPO_SEGUNDO)
				vfx("SEGUNDO_LONGO", { peca = pr, duracao = CFG.TEMPO_SEGUNDO,
					posicao = pr and pr.Position or onde })
				tocarEm("SEGUNDO", pr and pr.Position or onde, 0.75)
			end,
		},

	}), function()
		ocupado = false
	end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Paradoxo",
  objeto="Paradoxo_Server_V1", sufixo="TempoParadoxo",
  arquetipo="ARCANO", alcance_mira=45,
  rotulo_m1="Eco", rotulo_r="Duplo", rotulo_t="Colapso de Linha",
  origem=["Handle autoral: dois ponteiros cruzados, um deles vermelho",
          "A Tool inteira sai do `beforeimage` do `reverter!!` — o clone",
          "semitransparente vermelho, 40 quadros a frente de quem volta",
          "ECO 3748210376 (Pulse) · DUPLO 3373995015 (Epitaph)",
          "COLAPSO 163064102 (Explosion) — os tres da ficha do Acervo"],
  cfg="""	ALCANCE       = 18,
	RECARGA       = 0.9,
	TETO_ECOS     = 4,
	VIDA_ECO      = 8,

	RECARGA_R     = 17,
	RAIO_DUPLO    = 12,
	DANO_DUPLO    = 30,
	GOLPES_DUPLO  = 3,
	INTERVALO     = 0.35,

	RECARGA_T     = 24,
	RAIO_COLAPSO  = 26,
	NUCLEO        = 10,
	DANO_COLAPSO  = 55,
	BORDA         = 22,
	POR_ECO       = 1.3,
	EMPURRAO      = 95,
	TOMBO         = 1.3,""",
  estado="""--- Os ecos vivos: posição, CFrame e prazo. Lista, não instância: o que existe
--- no mundo é o VFX, que é do cliente.
local ecos = {}""",
  ao_guardar="""	limparEcos()
""",
  corpo='''
--''' + R + '''
-- OS ECOS
--
-- A Tool inteira sai de UM detalhe da origem: o `beforeimage` do `reverter!!`
-- — um clone semitransparente vermelho, adiantado no tempo. Lá ele era
-- enfeite de uma habilidade; aqui ele é a habilidade.
--
-- O TETO existe porque sem ele o `T` soma o dano de vinte ecos plantados com
-- calma antes da briga.
--''' + R + '''

function limparEcos()
	for _, e in ipairs(ecos) do
		vfx("PARAR", { id = e.id })
	end
	table.clear(ecos)
end

local function tirarEco(id)
	local i = 1
	while i <= #ecos do
		if ecos[i].id == id then return table.remove(ecos, i) end
		i = i + 1
	end
	return nil
end

--''' + R + '''
-- M1 — deixar um eco
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("ECO_P", despachar({

		CARGA = { sfx = { "ECO", 1.2 } },

		GOLPE = {
			sfx = { "ECO", 1.0 },
			faz = function()
				if not raiz then return end

				if #ecos >= CFG.TETO_ECOS then
					local velho = table.remove(ecos, 1)
					if velho then vfx("PARAR", { id = velho.id }) end
				end

				local e = {
					id = novoId("eco"),
					onde = raiz.Position,
					quadro = raiz.CFrame,
					ate = os.clock() + CFG.VIDA_ECO,
				}
				table.insert(ecos, e)

				vfx("ECO", { id = e.id, posicao = e.onde, quadro = e.quadro,
					duracao = CFG.VIDA_ECO })

				task.delay(CFG.VIDA_ECO, function()
					local ainda = tirarEco(e.id)
					if ainda then vfx("PARAR", { id = ainda.id }) end
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- R — o duplo
--
-- O eco mais NOVO ataca sozinho, três vezes, de onde ele está. Não é um NPC:
-- é uma sequência de golpes de área na posição gravada, e o VFX conta a
-- história.
--''' + R + '''

function extraR()
	if not rig then return end
	if #ecos == 0 then return end
	local e = ecos[#ecos]

	ocupado = true
	rig:PlaySequence("DUPLO", despachar({

		CARGA = { sfx = { "DUPLO", 1.2 } },
		SEGURA = { sfx = { "ECO", 1.3 } },

		SOLTA = {
			sfx = { "DUPLO", 0.95 },
			faz = function()
				local direcao = e.quadro.LookVector
				local n = 0
				local function golpear()
					n = n + 1
					if n > CFG.GOLPES_DUPLO then return end
					if not (personagem and personagem.Parent) then return end

					local aqui = e.onde + direcao * (CFG.ALCANCE * 0.5)
					vfx("DUPLO", { posicao = e.onde, direcao = direcao })
					tocarEm("DUPLO", e.onde, 1.0 + n * 0.06)

					for _, quem in ipairs(alvosEm(aqui, CFG.RAIO_DUPLO, 10)) do
						aplicarDano(quem, CFG.DANO_DUPLO)
					end
					task.delay(CFG.INTERVALO, golpear)
				end
				golpear()
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o colapso de linha
--
-- TODOS os ecos estouram ao mesmo tempo, e o dano cresce com quantos havia.
-- É o pagamento de ter plantado eco antes — e é por isso que o M1 tem recarga
-- curta e o `T` tem recarga longa.
--''' + R + '''

function extraT()
	if not rig then return end
	if #ecos == 0 then return end

	local levas = ecos
	ecos = {}
	local quantos = #levas

	ocupado = true
	rig:PlaySequence("COLAPSO", despachar({

		CARGA = { sfx = { "COLAPSO", 1.1 } },

		VARRE = {
			sfx = { "COLAPSO", 0.85 },
			faz = function()
				local fator = CFG.POR_ECO ^ (quantos - 1)
				for _, e in ipairs(levas) do
					vfx("PARAR", { id = e.id })
					vfx("COLAPSO", { posicao = e.onde,
						raio = CFG.RAIO_COLAPSO })
					tocarEm("COLAPSO", e.onde, 0.9)

					for _, quem in ipairs(alvosEm(e.onde,
							CFG.RAIO_COLAPSO, 16)) do
						local qr = raizDe(quem)
						local d = qr and (qr.Position - e.onde).Magnitude
							or CFG.RAIO_COLAPSO
						local dano = (d <= CFG.NUCLEO)
							and CFG.DANO_COLAPSO or CFG.BORDA
						aplicarDano(quem, math.floor(dano * fator + 0.5))
						if qr then
							empurrar(quem, (qr.Position - e.onde)
								+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.3)
						end
						tombar(quem, CFG.TOMBO)
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
T("Fim do Relogio",
  objeto="FimdoRelogio_Server_V1", sufixo="TempoFim",
  arquetipo="EXPLOSIVO", alcance_mira=50,
  rotulo_m1="Ponteiro", rotulo_r="Ampulheta", rotulo_t="Fim do Relogio",
  origem=["Handle autoral: mostrador rachado com cinta Neon",
          "A unica sem ancestral direto na origem: ela e a ultimate, e junta",
          "o congelamento, a atracao e o estouro num arco so",
          "PONTEIRO 116049255 (TimeSound) · AMPULHETA 127416781",
          "(ChargeReady) · FIM 5642129054 (ExplosionSound) — da ficha"],
  cfg="""	ALCANCE       = 16,
	RECARGA       = 1.2,
	RAIO          = 16,
	DANO          = 34,
	EMPURRAO      = 60,

	RECARGA_R     = 20,
	RAIO_AMPULHETA = 30,
	TEMPO_AMPULHETA = 4,
	PULSO         = 0.25,
	PUXAO_MIN     = 18,
	PUXAO_MAX     = 72,
	ZONA_MORTA    = 5,
	DANO_AMPULHETA = 6,

	RECARGA_T     = 42,
	RAIO_FIM      = 55,
	NUCLEO_FIM    = 20,
	DANO_FIM      = 175,
	BORDA_FIM     = 60,
	EMPURRAO_FIM  = 150,
	TOMBO_FIM     = 2.2,
	CONGELA_FIM   = 2.5,
	RAIO_CENA     = 60,""",
  estado="""local ampulhetaId, ampulhetaAte = nil, 0
local ampulhetaLaco = nil""",
  ao_guardar="""	pararAmpulheta()
	fecharCena()
""",
  corpo='''
--''' + R + '''
-- M1 — o ponteiro
--
-- Varredura de 360° em volta. Não é um golpe para a frente: é o ponteiro
-- atravessando o mostrador, e ele acerta quem estiver em qualquer direção.
--''' + R + '''

function primaria()
	if not rig then return end

	ocupado = true
	rig:PlaySequence("PONTEIRO", despachar({

		CARGA = { sfx = { "PONTEIRO", 1.15 } },

		VARRE = {
			sfx = { "PONTEIRO", 0.95 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("PONTEIRO", { posicao = centro,
					direcao = raiz.CFrame.LookVector, raio = CFG.RAIO })

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO, 14)) do
					aplicarDano(quem, CFG.DANO)
					local qr = raizDe(quem)
					if qr then
						empurrar(quem, (qr.Position - centro)
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
-- R — a ampulheta
--
-- Puxa por PULSO, nunca contínuo: um `BodyVelocity` permanente tira o
-- controle do alvo por inteiro, e a habilidade vira prisão em vez de atração.
--''' + R + '''

function pararAmpulheta()
	if ampulhetaLaco then
		ampulhetaLaco:Disconnect()
		ampulhetaLaco = nil
	end
	if ampulhetaId then
		vfx("PARAR", { id = ampulhetaId })
		ampulhetaId = nil
	end
	ampulhetaAte = 0
end

local function puxarPara(centro, alvoHum)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end

	local delta = centro - alvoRaiz.Position
	local dist = delta.Magnitude
	if dist < CFG.ZONA_MORTA or dist < 0.01 then return end

	local fracao = math.clamp(dist / CFG.RAIO_AMPULHETA, 0, 1)
	local forca = CFG.PUXAO_MIN + (CFG.PUXAO_MAX - CFG.PUXAO_MIN) * fracao

	local impulso = Instance.new("BodyVelocity")
	impulso.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	impulso.Velocity = delta.Unit * forca
	impulso.Parent = alvoRaiz
	Debris:AddItem(impulso, CFG.PULSO * 0.9)
end

function extraR(mira)
	if not rig then return end
	local onde = mira

	ocupado = true
	rig:PlaySequence("AMPULHETA", despachar({

		CARGA = { sfx = { "AMPULHETA", 1.1 } },
		SEGURA = { sfx = { "AMPULHETA", 0.85 } },

		SOLTA = {
			sfx = { "PONTEIRO", 0.9 },
			faz = function()
				local centro = (typeof(onde) == "Vector3") and onde or frente()
				pararAmpulheta()

				ampulhetaId = novoId("ampulheta")
				ampulhetaAte = os.clock() + CFG.TEMPO_AMPULHETA

				vfx("AMPULHETA", {
					id = ampulhetaId, posicao = centro,
					raio = CFG.RAIO_AMPULHETA, duracao = CFG.TEMPO_AMPULHETA,
				})
				tocarEm("AMPULHETA", centro, 0.9)

				local proximoPulso = 0
				ampulhetaLaco = guardar(RunService.Heartbeat:Connect(function()
					local agora = os.clock()
					if agora > ampulhetaAte then
						pararAmpulheta()
						return
					end
					if agora < proximoPulso then return end
					proximoPulso = agora + CFG.PULSO

					for _, quem in ipairs(alvosEm(centro,
							CFG.RAIO_AMPULHETA, 18)) do
						puxarPara(centro, quem)
						aplicarDano(quem, CFG.DANO_AMPULHETA)
					end
				end))
			end,
		},

	}), function()
		ocupado = false
	end)
end

--''' + R + '''
-- T — o Fim do Relógio, COM CENA
--
-- A ultimate. Congela todo mundo no raio E estoura — e o congelamento vem
-- ANTES do dano de propósito: quem levou não sai correndo do que vem depois.
--
-- O beat `CENA` abre a cutscene; `CARGA` e `ESTOURA` levam `cam = true`.
-- `fecharCena` roda no fim da sequência E no `desmontar`.
--''' + R + '''

function extraT()
	if not rig or not raiz then return end
	local ponto = raiz.Position

	ocupado = true
	rig:PlaySequence("FIM_RELOGIO", despachar({

		CENA = {
			sfx = { "FIM", 1.2 },
			faz = function()
				abrirCena(ponto, CFG.RAIO_CENA, "CENA")
			end,
		},

		CARGA = { cam = true, ponto = ponto, sfx = { "AMPULHETA", 1.3 } },

		ESTOURA = {
			cam = true, ponto = ponto,
			sfx = { "FIM", 0.75 },
			faz = function()
				if not raiz then return end
				local centro = raiz.Position

				vfx("FIM_RELOGIO", { posicao = centro, raio = CFG.RAIO_FIM })
				tocarEm("FIM", centro, 0.7)

				-- congela ANTES de bater: quem levou não sai correndo do que
				-- vem depois
				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_FIM, 26)) do
					congelarHumanoide(quem, CFG.CONGELA_FIM)
				end

				for _, quem in ipairs(alvosEm(centro, CFG.RAIO_FIM, 26)) do
					local qr = raizDe(quem)
					local d = qr and (qr.Position - centro).Magnitude
						or CFG.RAIO_FIM
					local dano = (d <= CFG.NUCLEO_FIM)
						and CFG.DANO_FIM or CFG.BORDA_FIM
					aplicarDano(quem, dano)
					if qr then
						empurrar(quem, (qr.Position - centro)
							+ Vector3.new(0, 0.7, 0), CFG.EMPURRAO_FIM, 0.36)
					end
					tombar(quem, CFG.TOMBO_FIM)
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
