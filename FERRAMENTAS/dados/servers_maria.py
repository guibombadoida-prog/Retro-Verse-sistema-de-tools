"""
servers_maria.py — as 28 habilidades do conjunto MARIA.

Sete cajados, QUATRO habilidades cada: a que a origem já tinha no clique, mais
três Extras em `R`, `T` e `Y`. Lido por `FERRAMENTAS/gerar_servers_maria.py`.

════════════════════════════════════════════════════════════════════════
A M1 É A DA ORIGEM. AS TRÊS EXTRAS ESTENDEM O MESMO CAJADO.
════════════════════════════════════════════════════════════════════════

    | Tool | o que o `MainAttack` da origem faz |
    |---|---|
    | `Cajado Curador` | feixe no alvo, `Health + 2` dez vezes = cura 20 |
    | `Cajado da Escuridao` | orbe negro com `BodyVelocity` 30 e script `Follow` |
    | `Cajado da Ilusao` | clona o personagem como isca, que vaga |
    | `Cajado das Estrelas` | estrela 16 x 5.2 x 16, velocidade 30–80, dano 10 |
    | `Cajado de Gelo` | feixe, e `HumanoidRootPart.Anchored = true` |
    | `Cajado do Meteoro` | meteoro 53³, velocidade 30, dano 50 |
    | `Cajado Relampago` | 4 raios do céu e `Explosion` raio 10 |

    Os números acima são os da origem e foram mantidos onde faziam sentido: a
    cura de 20, o dano 10 da estrela, o 50 do meteoro, o raio 10 do relâmpago.

════════════════════════════════════════════════════════════════════════
CINCO PROIBIÇÕES DA ORIGEM, RESOLVIDAS
════════════════════════════════════════════════════════════════════════

    `Health = Health + x`        cura vira `alvoHum.Health = math.min(...)`, que
                                 respeita `MaxHealth` — a origem estourava
    `HumanoidRootPart.Anchored`  vira `prender()`: `BodyPosition` com prazo. Com
                                 `Anchored`, a Tool sumindo no meio deixava o
                                 jogador preso PARA SEMPRE
    `Instance.new("Explosion")`  vira `golpearArea`, pelo Núcleo
    `math.random` em gameplay    vira `naFaixa` / ângulo áureo
    `wait` / `LoadAnimation`     `task.wait` / `R6CFrameAnimator`
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


R = "═" * 62


# ═══════════════════════════════════════════════════════════════
T("Cajado Curador",
  objeto="CajadoCurador_Server_V1", sufixo="MariaCurador",
  arquetipo="SUPORTE", alcance_mira=60,
  rotulo_m1="cura 20 no alvo", rotulo_r="Roubar",
  rotulo_t="Bencao", rotulo_y="Ressurgir",
  origem=["`Cajado Curador`: Handle e ExtraTHICK da origem, mais a `Beam`",
          "a origem cura `Health + 2` DEZ vezes = 20, com feixe preso no alvo",
          "`R` e o `Cajado Roubador de Hp`, que a distribuicao fundiu aqui:",
          "   ele drena `faltante/10` dez vezes e poe a mesma quantia em voce"],
  cfg="""	ALCANCE       = 60,
	CURA          = 20,
	TIQUES        = 10,
	PASSO_TIQUE   = 0.1,
	RECARGA       = 1.2,

	RECARGA_R     = 14,
	ALCANCE_ROUBO = 45,

	RECARGA_T     = 20,
	RAIO_BENCAO   = 18,
	CURA_BENCAO   = 12,

	RECARGA_Y     = 34,
	RAIO_RESSURGE = 16,
	CURA_RESSURGE = 45,
	ESCUDO        = 6,""",
  corpo='''
--''' + R + '''
-- CURAR — respeitando `MaxHealth`, que a origem não respeitava
--
-- `humanoid.Health = humanoid.Health + extra` estoura o teto: com 95 de 100 e
-- uma cura de 20, a origem escrevia 115. O Roblox corta na leitura seguinte,
-- mas o valor intermediário vaza para qualquer script que leia no meio.
--''' + R + '''

local function curar(alvoHum, quanto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	local antes = alvoHum.Health
	alvoHum.Health = math.min(alvoHum.MaxHealth, antes + quanto)
	return alvoHum.Health - antes
end

--- O feixe de dez tiques, que é a cadência da origem nas duas habilidades.
local function feixeLento(alvoHum, porTique, aoTique)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz then return end
	task.spawn(function()
		for _ = 1, CFG.TIQUES do
			if not (alvoHum.Parent and alvoHum.Health > 0
					and raiz and raiz.Parent) then
				break
			end
			aoTique(alvoHum, porTique)
			vfx("CURA", { origem = raiz.Position + Vector3.new(0, 2, 0),
				destino = alvoRaiz.Position, duracao = CFG.PASSO_TIQUE * 2 })
			task.wait(CFG.PASSO_TIQUE)
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CURAR", despachar({
		CARGA = { sfx = { "ATAQUE", 1 } },
		GOLPE = { faz = function()
			local alvo = maisPertoAliado(destino or frente(CFG.ALCANCE))
			if not alvo then
				tocar("ATAQUE", 0.8)
				return
			end
			feixeLento(alvo, CFG.CURA / CFG.TIQUES, curar)
			tocarEm("ATAQUE", (raizDe(alvo) or raiz).Position, 1.05)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Roubar  (era o `Cajado Roubador de Hp`)
--
-- Ele drena exatamente a SUA vida faltante, dividida em dez tiques. Cheio de
-- vida, não rouba nada — e isso é da origem, não invenção. É a única mecânica
-- do repositório onde o dano depende do estado de QUEM ATACA.
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ROUBAR", despachar({
		CARGA = { sfx = { "ROUBO", 0.95 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_ROUBO),
				CFG.ALCANCE_ROUBO)
			local alvoRaiz = alvo and raizDe(alvo)
			if not (alvoRaiz and humanoide) then
				tocar("ROUBO", 0.8)
				return
			end
			local faltante = humanoide.MaxHealth - humanoide.Health
			if faltante <= 0 then
				tocar("ROUBO", 1.3)
				return
			end
			local porTique = faltante / CFG.TIQUES
			feixeLento(alvo, porTique, function(quem, quanto)
				aplicarDano(quem, quanto)
				curar(humanoide, quanto)
			end)
			vfx("ROUBO", { origem = raiz.Position + Vector3.new(0, 2, 0),
				destino = alvoRaiz.Position, duracao = 1 })
			tocarEm("ROUBO", alvoRaiz.Position, 0.9)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Bênção  ·  Y — Ressurgir
--''' + R + '''

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("BENCAO", despachar({
		CARGA = { sfx = { "BENCAO", 1.1 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("BENCAO", { posicao = centro, raio = CFG.RAIO_BENCAO,
				escala = 1 })
			tocarEm("BENCAO", centro, 1.15)
			curar(humanoide, CFG.CURA_BENCAO)
			for _, amigo in ipairs(aliadosEm(centro, CFG.RAIO_BENCAO)) do
				curar(amigo, CFG.CURA_BENCAO)
			end
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("RESSURGIR", despachar({
		CARGA = { sfx = { "RESSURGIR", 0.85 } },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("RESSURGIR", { posicao = centro, escala = 1 })
			tocarEm("RESSURGIR", centro, 0.9)
			curar(humanoide, CFG.CURA_RESSURGE)
			for _, amigo in ipairs(aliadosEm(centro, CFG.RAIO_RESSURGE)) do
				curar(amigo, CFG.CURA_RESSURGE)
			end
			-- o escudo: `ForceField` com prazo, no personagem. `TakeDamage`
			-- respeita ForceField, então o Núcleo já entende sozinho.
			local campo = Instance.new("ForceField")
			campo.Visible = true
			campo.Parent = personagem
			Debris:AddItem(campo, CFG.ESCUDO)
		end },
	}), function() ocupado = false end)
end
''')


# ═══════════════════════════════════════════════════════════════
T("Cajado da Escuridao",
  objeto="CajadodaEscuridao_Server_V1", sufixo="MariaEscuridao",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_m1="orbe teleguiado", rotulo_r="Enxame",
  rotulo_t="Cegueira", rotulo_y="Manto",
  origem=["`Cajado Da Escuridão`: Handle, `Orb` (SpecialMesh), `Shadows`",
          "   (ParticleEmitter) e `Trail` vieram da origem",
          "a origem lanca um orbe 4x4x4 com BodyVelocity 30 e um script Follow"],
  cfg="""	ALCANCE       = 45,
	VOO           = 0.5,
	RAIO_ORBE     = 8,
	DANO_ORBE     = 26,
	EMPURRAO      = 40,
	RECARGA       = 1,

	RECARGA_R     = 12,
	ORBES         = 3,
	PASSO_ENXAME  = 0.14,
	DANO_ENXAME   = 16,

	RECARGA_T     = 18,
	RAIO_CEGUEIRA = 14,
	DANO_CEGUEIRA = 12,
	TEMPO_CEGO    = 4,
	LENTIDAO_CEGO = 0.5,

	RECARGA_Y     = 30,
	TEMPO_MANTO   = 6,
	RAIO_MANTO    = 9,
	LENTIDAO_MANTO = 0.6,
	TIQUE_MANTO   = 0.8,""",
  estado="local mantoId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- O ORBE — teleguiado, como o `Follow` da origem
--
-- Na origem o orbe é uma `Part` com `BodyVelocity` e um script `Follow` que
-- reaponta a velocidade a cada quadro. Aqui quem desenha o voo é o cliente, e
-- o servidor só resolve o impacto no fim — o servidor mover geometria por
-- quadro replica a ~20 Hz picotado, e foi o bug de "não está fluido".
--''' + R + '''

local function lancarOrbe(ponto, raioDano, dano)
	local mao = raiz.Position + raiz.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)
	vfx("ORBE", { origem = mao, destino = ponto, tempo = CFG.VOO, escala = 1 })
	task.delay(CFG.VOO, function()
		vfx("ORBE_FIM", { posicao = ponto, escala = 1 })
		tocarEm("ATAQUE", ponto, 0.9)
		for _, alvo in ipairs(alvosEm(ponto, raioDano, 8)) do
			aplicarDano(alvo, dano)
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - ponto)
					+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.24)
			end
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ORBE", despachar({
		CARGA = { sfx = { "ATAQUE", 1 } },
		GOLPE = { faz = function()
			lancarOrbe(destino or frente(CFG.ALCANCE), CFG.RAIO_ORBE,
				CFG.DANO_ORBE)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — o Enxame  ·  T — a Cegueira  ·  Y — o Manto
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ENXAME", despachar({
		CARGA = { sfx = { "ENXAME", 1.15 } },
		GOLPE = { faz = function()
			local base = destino or frente(CFG.ALCANCE)
			task.spawn(function()
				for i = 1, CFG.ORBES do
					if not (raiz and raiz.Parent) then break end
					-- ângulo áureo espalha sem sorteio: três orbes nunca
					-- saem alinhados, e todos os clientes veem o mesmo
					local a = i * 2.399963
					lancarOrbe(base + Vector3.new(math.cos(a), 0, math.sin(a)) * 4,
						CFG.RAIO_ORBE * 0.8, CFG.DANO_ENXAME)
					task.wait(CFG.PASSO_ENXAME)
				end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CEGUEIRA", despachar({
		CARGA = { sfx = { "CEGUEIRA", 0.75 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			vfx("CEGUEIRA", { posicao = centro, escala = 1,
				duracao = CFG.TEMPO_CEGO })
			tocarEm("CEGUEIRA", centro, 0.7)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CEGUEIRA, 12)) do
				aplicarDano(alvo, CFG.DANO_CEGUEIRA)
				afrouxar(alvo, CFG.LENTIDAO_CEGO, CFG.TEMPO_CEGO)
			end
		end },
	}), function() ocupado = false end)
end

local function tirarManto()
	geracao = geracao + 1
	if mantoId then
		vfx("APAGAR", { id = mantoId })
		mantoId = nil
	end
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("MANTO", despachar({
		CARGA = { sfx = { "MANTO", 0.9 } },
		GOLPE = { faz = function()
			tirarManto()
			geracao = geracao + 1
			local minha = geracao
			mantoId = novoId("MANTO")
			local id = mantoId
			vfx("MANTO", { posicao = raiz.Position, escala = 1,
				duracao = CFG.TEMPO_MANTO, id = id })
			tocarEm("MANTO", raiz.Position, 0.9)

			task.spawn(function()
				local ate = os.clock() + CFG.TEMPO_MANTO
				while minha == geracao and os.clock() < ate do
					if not (raiz and raiz.Parent) then break end
					vfx("MOVER", { id = id, posicao = raiz.Position,
						tempo = CFG.TIQUE_MANTO })
					for _, alvo in ipairs(alvosEm(raiz.Position,
							CFG.RAIO_MANTO, 10)) do
						afrouxar(alvo, CFG.LENTIDAO_MANTO,
							CFG.TIQUE_MANTO * 1.4)
					end
					task.wait(CFG.TIQUE_MANTO)
				end
				if minha == geracao then tirarManto() end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\ttirarManto()\n")


# ═══════════════════════════════════════════════════════════════
T("Cajado da Ilusao",
  objeto="CajadodaIlusao_Server_V1", sufixo="MariaIlusao",
  arquetipo="ESPECTRAL", alcance_mira=60,
  rotulo_m1="isca", rotulo_r="Trocar",
  rotulo_t="Multiplicar", rotulo_y="Dispersar",
  origem=["`Cajado Da Ilusão`: Handle e ExtraTHICK da origem",
          "a origem CLONA o personagem como isca, com `Animate` de 505 linhas,",
          "   `Wander` e `ControlFollow`. Aqui a isca e geometria do cliente:",
          "   o clone punha um `Humanoid` a mais no servidor por uso"],
  cfg="""	ALCANCE       = 45,
	DURACAO_ISCA  = 10,
	RAIO_ISCA     = 3,
	RECARGA       = 1.4,

	RECARGA_R     = 16,

	RECARGA_T     = 22,
	ISCAS         = 3,
	RAIO_ANEL     = 7,

	RECARGA_Y     = 28,
	RAIO_DISPERSA = 13,
	DANO_DISPERSA = 30,
	EMPURRAO      = 60,""",
  estado="local iscas = {}\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- AS ISCAS — geometria do cliente, com prazo
--
-- A origem clonava o PERSONAGEM: `Humanoid` novo no servidor, `Animate` de 505
-- linhas copiado junto, `Wander` reapontando a cada volta. Por uso. Aqui a
-- isca é desenho do cliente e uma posição no servidor — quem a invoca, move e
-- dispensa é a Tool, e ela some no `desmontar()`.
--
-- NPC segue fora de escopo pelo `CLAUDE.md`; invocar com prazo, não.
--''' + R + '''

local function soltarIscas()
	geracao = geracao + 1
	for _, dados in ipairs(iscas) do
		vfx("APAGAR", { id = dados.id })
	end
	table.clear(iscas)
end

local function plantarIsca(onde)
	local id = novoId("ISCA")
	vfx("ISCA", { posicao = onde, escala = 1,
		duracao = CFG.DURACAO_ISCA, id = id })
	table.insert(iscas, { id = id, onde = onde })
	return id
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ISCA", despachar({
		CARGA = { sfx = { "ATAQUE", 1 } },
		GOLPE = { faz = function()
			soltarIscas()
			geracao = geracao + 1
			local minha = geracao
			local onde = destino or frente(CFG.ALCANCE)
			plantarIsca(onde)
			tocarEm("ATAQUE", onde, 1.1)
			task.delay(CFG.DURACAO_ISCA, function()
				if minha == geracao then soltarIscas() end
			end)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Trocar com a isca
--
-- Os dois pontos são lidos ANTES de qualquer escrita. Ler um, escrever, e só
-- então ler o outro colocaria os dois no mesmo lugar.
--''' + R + '''

function extraR(_mira)
	ocupado = true
	rig:PlaySequence("TROCAR", despachar({
		CARGA = { sfx = { "TROCAR", 1.2 } },
		GOLPE = { faz = function()
			local primeira = iscas[1]
			if not (primeira and raiz and raiz.Parent) then
				tocar("TROCAR", 0.85)
				return
			end
			local meu = raiz.CFrame
			local dela = primeira.onde

			vfx("ISCA_FIM", { posicao = dela, escala = 1 })
			vfx("ISCA_FIM", { posicao = meu.Position, escala = 1 })
			tocarEm("TROCAR", dela, 1.2)

			raiz.CFrame = CFrame.new(dela, dela + meu.LookVector)
			primeira.onde = meu.Position
			vfx("MOVER", { id = primeira.id, posicao = meu.Position,
				tempo = 0.2 })
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- T — Multiplicar  ·  Y — Dispersar
--''' + R + '''

function extraT(_mira)
	ocupado = true
	rig:PlaySequence("MULTIPLICAR", despachar({
		CARGA = { sfx = { "MULTIPLICAR", 1.25 } },
		GOLPE = { faz = function()
			soltarIscas()
			geracao = geracao + 1
			local minha = geracao
			local centro = raiz.Position
			for i = 1, CFG.ISCAS do
				local a = i * 2.399963
				plantarIsca(centro + Vector3.new(math.cos(a), 0, math.sin(a))
					* CFG.RAIO_ANEL)
			end
			tocarEm("MULTIPLICAR", centro, 1.3)
			task.delay(CFG.DURACAO_ISCA, function()
				if minha == geracao then soltarIscas() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("DISPERSAR", despachar({
		CARGA = { sfx = { "DISPERSAR", 1.3 } },
		GOLPE = { faz = function()
			if #iscas == 0 then
				tocar("DISPERSAR", 0.8)
				return
			end
			for _, dados in ipairs(iscas) do
				local onde = dados.onde
				vfx("ISCA_FIM", { posicao = onde, escala = 1.6 })
				tocarEm("DISPERSAR", onde, 1.2)
				for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_DISPERSA, 10)) do
					aplicarDano(alvo, CFG.DANO_DISPERSA)
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						empurrar(alvo, (alvoRaiz.Position - onde)
							+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.26)
					end
				end
			end
			soltarIscas()
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tsoltarIscas()\n")


# ═══════════════════════════════════════════════════════════════
T("Cajado das Estrelas",
  objeto="CajadodasEstrelas_Server_V1", sufixo="MariaEstrelas",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="estrela", rotulo_r="Chuva",
  rotulo_t="Constelacao", rotulo_y="Estrela-guia",
  origem=["`Cajado Das Estrelas`: Handle, `Mesh` e `Particle` da origem",
          "estrela 16 x 5.2 x 16 · `Damage.Value = 10` · velocidade 30–80",
          "a faixa de velocidade virou `naFaixa`, que e a mesma sem sorteio"],
  cfg="""	ALCANCE       = 50,
	VOO_MIN       = 0.35,
	VOO_MAX       = 0.7,
	RAIO_ESTRELA  = 10,
	DANO          = 10,
	EMPURRAO      = 44,
	RECARGA       = 1.1,

	RECARGA_R     = 13,
	ESTRELAS      = 6,
	PASSO_CHUVA   = 0.16,
	RAIO_CHUVA    = 22,

	RECARGA_T     = 21,
	ALCANCE_MARCA = 55,
	DURACAO_MARCA = 6,
	BONUS_MARCA   = 1.5,

	RECARGA_Y     = 32,
	DURACAO_GUIA  = 7,
	RAIO_GUIA     = 9,
	TIQUE_GUIA    = 0.8,
	DANO_GUIA     = 11,
	PASSO_GUIA    = 0.3,""",
  estado=("local marcados = {}\nlocal guiaId = nil\nlocal guiaOnde = nil\n"
          "local geracao = 0"),
  corpo='''
--''' + R + '''
-- A ESTRELA — e a marca que multiplica
--
-- `naFaixa(0.35, 0.7)` no lugar de `math.random(30, 80)`: a origem sorteava a
-- velocidade do projétil, e com todos os clientes desenhando um sorteio faria
-- cada um ver a estrela chegar num tempo diferente.
--''' + R + '''

local function danoNaEstrela(alvo)
	local dano = CFG.DANO
	if marcados[alvo] and os.clock() < marcados[alvo] then
		dano = dano * CFG.BONUS_MARCA
	end
	return dano
end

local function lancarEstrela(ponto, raioDano)
	local mao = raiz.Position + raiz.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)
	local voo = naFaixa(CFG.VOO_MIN, CFG.VOO_MAX)
	vfx("ESTRELA", { origem = mao, destino = ponto, tempo = voo, escala = 1 })
	task.delay(voo, function()
		vfx("ESTRELA_FIM", { posicao = ponto, escala = 1 })
		tocarEm("ATAQUE", ponto, 1.2)
		for _, alvo in ipairs(alvosEm(ponto, raioDano, 10)) do
			aplicarDano(alvo, danoNaEstrela(alvo))
			local alvoRaiz = raizDe(alvo)
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - ponto)
					+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.24)
			end
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("ESTRELA", despachar({
		CARGA = { sfx = { "ATAQUE", 1.1 } },
		GOLPE = { faz = function()
			lancarEstrela(destino or frente(CFG.ALCANCE), CFG.RAIO_ESTRELA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — a Chuva  ·  T — a Constelação  ·  Y — a Estrela-guia
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CHUVA", despachar({
		CARGA = { sfx = { "CHUVA", 1.4 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			task.spawn(function()
				for i = 1, CFG.ESTRELAS do
					if not (raiz and raiz.Parent) then break end
					local a = i * 2.399963
					local r = CFG.RAIO_CHUVA * math.sqrt(i / CFG.ESTRELAS)
					lancarEstrela(centro + Vector3.new(math.cos(a) * r, 0,
						math.sin(a) * r), CFG.RAIO_ESTRELA * 0.8)
					task.wait(CFG.PASSO_CHUVA)
				end
			end)
		end },
	}), function() ocupado = false end)
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CONSTELACAO", despachar({
		CARGA = { sfx = { "CONSTELACAO", 1.45 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE_MARCA)
			local ate = os.clock() + CFG.DURACAO_MARCA
			local n = 0
			for _, alvo in ipairs(alvosEm(centro, 16, 10)) do
				marcados[alvo] = ate
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("CONSTELACAO", { posicao = alvoRaiz.Position,
						escala = 1, duracao = CFG.DURACAO_MARCA })
				end
				n = n + 1
			end
			if n > 0 then tocarEm("CONSTELACAO", centro, 1.4) end
		end },
	}), function() ocupado = false end)
end

local function dispensarGuia()
	geracao = geracao + 1
	if guiaId then
		vfx("APAGAR", { id = guiaId })
		guiaId = nil
	end
	guiaOnde = nil
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("GUIA", despachar({
		CARGA = { sfx = { "GUIA", 1.2 } },
		GOLPE = { faz = function()
			dispensarGuia()
			geracao = geracao + 1
			local minha = geracao
			local onde = frente(8) + Vector3.new(0, 3, 0)
			guiaOnde = onde
			guiaId = novoId("GUIA")
			local id = guiaId
			vfx("CONSTELACAO", { posicao = onde, escala = 1.4,
				duracao = CFG.DURACAO_GUIA, id = id })
			tocarEm("GUIA", onde, 1.25)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_GUIA
				while minha == geracao and os.clock() < ate do
					local centro = guiaOnde or onde
					local presa = maisPerto(centro, 40)
					local presaRaiz = presa and raizDe(presa)
					if presaRaiz then
						guiaOnde = presaRaiz.Position + Vector3.new(0, 3, 0)
						vfx("MOVER", { id = id, posicao = guiaOnde,
							tempo = CFG.PASSO_GUIA })
					end
					for _, alvo in ipairs(alvosEm(guiaOnde or centro,
							CFG.RAIO_GUIA, 8)) do
						aplicarDano(alvo, CFG.DANO_GUIA)
					end
					task.wait(CFG.TIQUE_GUIA)
				end
				if minha == geracao then dispensarGuia() end
			end)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tdispensarGuia()\n\ttable.clear(marcados)\n")


# ═══════════════════════════════════════════════════════════════
T("Cajado de Gelo",
  objeto="CajadodeGelo_Server_V1", sufixo="MariaGelo",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_m1="congela", rotulo_r="Prisao",
  rotulo_t="Trilha", rotulo_y="Estilhacar",
  origem=["`Cajado De Gelo`: Handle e ExtraTHICK da origem",
          "a origem faz `HumanoidRootPart.Anchored = true` e solda um bloco",
          "   6 x 6 x 3 — o bloco ficou, o Anchored virou `prender()`"],
  cfg="""	ALCANCE       = 45,
	DURACAO_GELO  = 3.5,
	DANO_GELO     = 18,
	LENTIDAO      = 0.35,
	RECARGA       = 1.3,

	RECARGA_R     = 15,
	RAIO_PRISAO   = 15,
	DANO_PRISAO   = 22,
	DURACAO_PRISAO = 2.6,

	RECARGA_T     = 19,
	RAIO_TRILHA   = 14,
	DURACAO_TRILHA = 6,
	TIQUE_TRILHA  = 0.7,
	LENTIDAO_TRILHA = 0.45,
	DANO_TRILHA   = 6,

	RECARGA_Y     = 29,
	RAIO_ESTILHACO = 16,
	DANO_ESTILHACO = 26,
	BONUS_CONGELADO = 2.2,""",
  estado=("local congelados = {}\nlocal trilhaId = nil\nlocal geracao = 0"),
  corpo='''
--''' + R + '''
-- CONGELAR — `prender()`, e não `Anchored`
--
-- A origem faz `humanoid.Parent.HumanoidRootPart.Anchored = true`. Se a Tool
-- sumir no meio — troca de personagem, morte do portador, `Destroy` — nada
-- desfaz, e o jogador fica preso no lugar PARA SEMPRE.
--
-- `prender()` é `BodyPosition` com prazo no `Debris`: ele acaba sozinho mesmo
-- que todo o resto desapareça.
--
-- A lista `congelados` guarda até quando cada um está preso — é ela que o
-- `Estilhaçar` lê para saber em quem o dano dobra.
--''' + R + '''

local function congelar(alvo, tempo, dano)
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return false end
	aplicarDano(alvo, dano)
	prender(alvo, tempo)
	afrouxar(alvo, CFG.LENTIDAO, tempo + 1)
	congelados[alvo] = os.clock() + tempo
	vfx("GELO", { posicao = alvoRaiz.Position, escala = 1, duracao = tempo })
	return true
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CONGELA", despachar({
		CARGA = { sfx = { "ATAQUE", 1.05 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE), CFG.ALCANCE)
			if not alvo then
				tocar("ATAQUE", 0.85)
				return
			end
			if congelar(alvo, CFG.DURACAO_GELO, CFG.DANO_GELO) then
				tocarEm("ATAQUE", (raizDe(alvo) or raiz).Position, 1)
			end
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Prisão  ·  T — Trilha  ·  Y — Estilhaçar
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PRISAO", despachar({
		CARGA = { sfx = { "PRISAO", 1 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			tocarEm("PRISAO", centro, 1.05)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PRISAO, 12)) do
				congelar(alvo, CFG.DURACAO_PRISAO, CFG.DANO_PRISAO)
			end
		end },
	}), function() ocupado = false end)
end

local function derreterTrilha()
	geracao = geracao + 1
	if trilhaId then
		vfx("APAGAR", { id = trilhaId })
		trilhaId = nil
	end
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TRILHA", despachar({
		CARGA = { sfx = { "TRILHA", 1.5 } },
		GOLPE = { faz = function()
			derreterTrilha()
			geracao = geracao + 1
			local minha = geracao
			local centro = destino or frente(CFG.ALCANCE)
			trilhaId = novoId("TRILHA")
			local id = trilhaId
			vfx("TRILHA", { posicao = centro, raio = CFG.RAIO_TRILHA,
				duracao = CFG.DURACAO_TRILHA, id = id })
			tocarEm("TRILHA", centro, 1.4)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_TRILHA
				while minha == geracao and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_TRILHA, 12)) do
						aplicarDano(alvo, CFG.DANO_TRILHA)
						afrouxar(alvo, CFG.LENTIDAO_TRILHA,
							CFG.TIQUE_TRILHA * 1.5)
					end
					task.wait(CFG.TIQUE_TRILHA)
				end
				if minha == geracao then derreterTrilha() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("ESTILHACAR", despachar({
		CARGA = { sfx = { "ESTILHACAR", 1.4 } },
		GOLPE = { faz = function()
			local centro = frente(CFG.ALCANCE * 0.3)
			local agora = os.clock()
			tocarEm("ESTILHACAR", centro, 1.35)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ESTILHACO, 14)) do
				local dano = CFG.DANO_ESTILHACO
				-- o par certo: congelar antes, estilhaçar depois
				if congelados[alvo] and agora < congelados[alvo] then
					dano = dano * CFG.BONUS_CONGELADO
					congelados[alvo] = nil
				end
				aplicarDano(alvo, dano)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("GELO_FIM", { posicao = alvoRaiz.Position, escala = 1 })
				end
			end
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tderreterTrilha()\n\ttable.clear(congelados)\n")


# ═══════════════════════════════════════════════════════════════
T("Cajado do Meteoro",
  objeto="CajadodoMeteoro_Server_V1", sufixo="MariaMeteoro",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="meteoro", rotulo_r="Chuva",
  rotulo_t="Cratera", rotulo_y="Impacto",
  origem=["`Cajado Do Meteoro`: Handle e `Particle` da origem",
          "meteoro 53 x 53 x 53 · `Damage.Value = 50` · velocidade 30",
          "o 50 foi mantido; o 53 de lado virou raio de dano 16"],
  cfg="""	ALCANCE       = 55,
	QUEDA         = 0.8,
	RAIO_METEORO  = 16,
	NUCLEO        = 6,
	DANO          = 50,
	BORDA         = 26,
	EMPURRAO      = 80,
	TOMBO         = 1.8,
	RECARGA       = 1.6,

	RECARGA_R     = 18,
	METEOROS      = 5,
	PASSO_CHUVA   = 0.28,
	RAIO_CHUVA    = 26,
	DANO_CHUVA    = 30,

	RECARGA_T     = 24,
	RAIO_CRATERA  = 14,
	DURACAO_CRATERA = 6,
	TIQUE_CRATERA = 0.8,
	DANO_CRATERA  = 10,

	RECARGA_Y     = 40,
	RAIO_IMPACTO  = 20,
	PUXAO         = 54,
	DANO_IMPACTO  = 58,
	BORDA_IMPACTO = 30,
	TOMBO_IMPACTO = 2.4,""",
  estado="local crateraId = nil\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- O METEORO — a espera é a mecânica
--
-- 0.8 s entre a conjuração e o impacto. Dá para sair de baixo, e é o que
-- separa isto de um dano instantâneo em área.
--''' + R + '''

local function cairMeteoro(onde, raioDano, danoNucleo, danoBorda)
	vfx("METEORO", { posicao = onde, escala = 1, queda = CFG.QUEDA })
	tocarEm("ATAQUE", onde, 0.8)
	task.delay(CFG.QUEDA, function()
		vfx("METEORO_FIM", { posicao = onde, raio = raioDano, escala = 1 })
		tocarEm("ATAQUE", onde, 0.55)
		golpearArea(onde, raioDano, CFG.NUCLEO, danoNucleo, danoBorda,
			CFG.EMPURRAO, CFG.TOMBO)
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("METEORO", despachar({
		CARGA = { sfx = { "ATAQUE", 0.85 } },
		GOLPE = { faz = function()
			cairMeteoro(destino or frente(CFG.ALCANCE), CFG.RAIO_METEORO,
				CFG.DANO, CFG.BORDA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — a Chuva  ·  T — a Cratera  ·  Y — o Impacto
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CHUVA", despachar({
		CARGA = { sfx = { "CHUVA", 0.7 } },
		GOLPE = { faz = function()
			local centro = destino or frente(CFG.ALCANCE)
			task.spawn(function()
				for i = 1, CFG.METEOROS do
					if not (raiz and raiz.Parent) then break end
					local a = i * 2.399963
					local r = CFG.RAIO_CHUVA * math.sqrt(i / CFG.METEOROS)
					cairMeteoro(centro + Vector3.new(math.cos(a) * r, 0,
						math.sin(a) * r), CFG.RAIO_METEORO * 0.75,
						CFG.DANO_CHUVA, CFG.DANO_CHUVA * 0.5)
					task.wait(CFG.PASSO_CHUVA)
				end
			end)
		end },
	}), function() ocupado = false end)
end

local function apagarCratera()
	geracao = geracao + 1
	if crateraId then
		vfx("APAGAR", { id = crateraId })
		crateraId = nil
	end
end

function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CRATERA", despachar({
		CARGA = { sfx = { "CRATERA", 0.85 } },
		GOLPE = { faz = function()
			apagarCratera()
			geracao = geracao + 1
			local minha = geracao
			local centro = destino or frente(CFG.ALCANCE)
			crateraId = novoId("CRATERA")
			local id = crateraId
			vfx("CRATERA", { posicao = centro, raio = CFG.RAIO_CRATERA,
				duracao = CFG.DURACAO_CRATERA, id = id })
			tocarEm("CRATERA", centro, 0.8)

			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_CRATERA
				while minha == geracao and os.clock() < ate do
					for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CRATERA, 12)) do
						aplicarDano(alvo, CFG.DANO_CRATERA)
					end
					task.wait(CFG.TIQUE_CRATERA)
				end
				if minha == geracao then apagarCratera() end
			end)
		end },
	}), function() ocupado = false end)
end

function extraY(_mira)
	ocupado = true
	rig:PlaySequence("IMPACTO", despachar({
		CARGA = { sfx = { "IMPACTO", 0.9 } },
		SEGURA = { faz = function()
			-- puxa PRIMEIRO: quem estava na borda entra no núcleo
			local centro = raiz.Position
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_IMPACTO, 14)) do
				puxar(alvo, centro, CFG.PUXAO, 0.34)
			end
		end },
		GOLPE = { faz = function()
			local centro = raiz.Position
			vfx("METEORO_FIM", { posicao = centro, raio = CFG.RAIO_IMPACTO,
				escala = 1.3 })
			tocarEm("IMPACTO", centro, 0.6)
			golpearArea(centro, CFG.RAIO_IMPACTO, CFG.NUCLEO * 1.5,
				CFG.DANO_IMPACTO, CFG.BORDA_IMPACTO, CFG.EMPURRAO,
				CFG.TOMBO_IMPACTO)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tapagarCratera()\n")


# ═══════════════════════════════════════════════════════════════
T("Cajado Relampago",
  objeto="CajadoRelampago_Server_V1", sufixo="MariaRelampago",
  arquetipo="EXPLOSIVO", alcance_mira=60,
  rotulo_m1="quatro raios", rotulo_r="Tempestade",
  rotulo_t="Corrente", rotulo_y="Para-raios",
  origem=["`Cajado Relâmpago`: Handle e `Mesh` da origem",
          "a origem solta **4** raios e uma `Explosion` de `BlastRadius = 10`,",
          "   com `DestroyJointRadiusPercent = 0` — ela ja nao desmembrava.",
          "os dois numeros foram mantidos; a Explosion virou `golpearArea`"],
  cfg="""	ALCANCE       = 55,
	RAIOS         = 4,
	PASSO_RAIO    = 0.09,
	ESPALHA       = 5,
	RAIO_ESTOURO  = 10,
	NUCLEO        = 4,
	DANO          = 34,
	BORDA         = 18,
	EMPURRAO      = 56,
	RECARGA       = 1.2,

	RECARGA_R     = 14,
	DURACAO_TEMPESTADE = 6,
	RAIO_TEMPESTADE = 20,
	TIQUE_TEMPESTADE = 0.75,
	DANO_TEMPESTADE = 16,

	RECARGA_T     = 20,
	SALTOS        = 5,
	ALCANCE_SALTO = 18,
	DANO_SALTO    = 24,
	QUEDA_SALTO   = 0.85,

	RECARGA_Y     = 33,
	ALCANCE_PARA  = 55,
	DURACAO_PARA  = 5,
	BONUS_PARA    = 1.6,""",
  estado="local marcado = nil\nlocal marcadoAte = 0\nlocal geracao = 0",
  corpo='''
--''' + R + '''
-- OS QUATRO RAIOS — o número é da origem
--
-- `for x = 1, 4 do` com um `strike` por volta, e no fim uma `Explosion` de
-- `BlastRadius = 10`. Os dois números ficaram; a `Explosion` virou
-- `golpearArea`, porque quem detecta alvo aqui é o Núcleo.
--
-- Vale notar que a origem já punha `DestroyJointRadiusPercent = 0` — ela não
-- desmembrava ninguém. O autor tinha pensado nisso.
--''' + R + '''

local function bonusPara(alvo)
	if marcado and alvo == marcado and os.clock() < marcadoAte then
		return CFG.BONUS_PARA
	end
	return 1
end

local function descarga(centro, dano, borda)
	task.spawn(function()
		for i = 1, CFG.RAIOS do
			if not (raiz and raiz.Parent) then break end
			local a = i * 2.399963
			local onde = centro + Vector3.new(math.cos(a), 0, math.sin(a))
				* CFG.ESPALHA
			vfx("RAIO", { posicao = onde, escala = 1 })
			tocarEm("ATAQUE", onde, 1 + jitter(i) * 0.12)
			task.wait(CFG.PASSO_RAIO)
		end
		vfx("RAIO_FIM", { posicao = centro, raio = CFG.RAIO_ESTOURO,
			escala = 1 })
		for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_ESTOURO, 12)) do
			local alvoRaiz = raizDe(alvo)
			local d = alvoRaiz and (alvoRaiz.Position - centro).Magnitude
				or CFG.RAIO_ESTOURO
			local base = (d <= CFG.NUCLEO) and dano or borda
			aplicarDano(alvo, base * bonusPara(alvo))
			if alvoRaiz then
				empurrar(alvo, (alvoRaiz.Position - centro)
					+ Vector3.new(0, 0.6, 0), CFG.EMPURRAO, 0.28)
			end
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("RAIOS", despachar({
		CARGA = { sfx = { "ATAQUE", 0.9 } },
		GOLPE = { faz = function()
			local alvoPara = (marcado and os.clock() < marcadoAte)
				and raizDe(marcado) or nil
			descarga((alvoPara and alvoPara.Position)
				or destino or frente(CFG.ALCANCE), CFG.DANO, CFG.BORDA)
		end },
	}), function() ocupado = false end)
end

--''' + R + '''
-- R — Tempestade  ·  T — Corrente  ·  Y — Para-raios
--''' + R + '''

function extraR(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("TEMPESTADE", despachar({
		CARGA = { sfx = { "TEMPESTADE", 0.8 } },
		GOLPE = { faz = function()
			geracao = geracao + 1
			local minha = geracao
			local centro = destino or frente(CFG.ALCANCE)
			tocarEm("TEMPESTADE", centro, 0.75)
			task.spawn(function()
				local ate = os.clock() + CFG.DURACAO_TEMPESTADE
				local passo = 0
				while minha == geracao and os.clock() < ate do
					passo = passo + 1
					local a = passo * 2.399963
					local r = CFG.RAIO_TEMPESTADE * 0.75
					local onde = centro + Vector3.new(math.cos(a) * r, 0,
						math.sin(a) * r)
					vfx("RAIO", { posicao = onde, escala = 0.9 })
					for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ESTOURO * 0.8,
							8)) do
						aplicarDano(alvo, CFG.DANO_TEMPESTADE * bonusPara(alvo))
					end
					task.wait(CFG.TIQUE_TEMPESTADE)
				end
			end)
		end },
	}), function() ocupado = false end)
end

--- A corrente que salta. Cada alvo é pago UMA vez: sem a lista, dois inimigos
--- lado a lado devolveriam o salto um para o outro até o limite.
function extraT(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("CORRENTE", despachar({
		CARGA = { sfx = { "CORRENTE", 1.4 } },
		GOLPE = { faz = function()
			local ponto = destino or frente(CFG.ALCANCE)
			local atual = maisPerto(ponto, CFG.ALCANCE)
			if not atual then
				tocar("CORRENTE", 0.9)
				return
			end
			local jaPagos = {}
			local anterior = raiz.Position + Vector3.new(0, 2, 0)
			local dano = CFG.DANO_SALTO

			task.spawn(function()
				for _ = 1, CFG.SALTOS do
					if not atual then break end
					local atualRaiz = raizDe(atual)
					if not atualRaiz then break end
					jaPagos[atual] = true

					vfx("CORRENTE", { origem = anterior,
						destino = atualRaiz.Position })
					tocarEm("CORRENTE", atualRaiz.Position, 1.35)
					aplicarDano(atual, dano * bonusPara(atual))

					anterior = atualRaiz.Position
					dano = dano * CFG.QUEDA_SALTO

					local proximo, dist = nil, math.huge
					for _, cand in ipairs(alvosEm(anterior,
							CFG.ALCANCE_SALTO, 12)) do
						local candRaiz = raizDe(cand)
						if candRaiz and not jaPagos[cand] then
							local d = (candRaiz.Position - anterior).Magnitude
							if d < dist then proximo, dist = cand, d end
						end
					end
					atual = proximo
					task.wait(0.1)
				end
			end)
		end },
	}), function() ocupado = false end)
end

function extraY(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PARARAIOS", despachar({
		CARGA = { sfx = { "PARARAIOS", 1.05 } },
		GOLPE = { faz = function()
			local alvo = maisPerto(destino or frente(CFG.ALCANCE_PARA),
				CFG.ALCANCE_PARA)
			local alvoRaiz = alvo and raizDe(alvo)
			if not alvoRaiz then
				tocar("PARARAIOS", 0.85)
				return
			end
			marcado = alvo
			marcadoAte = os.clock() + CFG.DURACAO_PARA
			vfx("PARARAIOS", { posicao = alvoRaiz.Position, escala = 1,
				duracao = CFG.DURACAO_PARA })
			tocarEm("PARARAIOS", alvoRaiz.Position, 1.1)
		end },
	}), function() ocupado = false end)
end
''',
  ao_guardar="\tgeracao = geracao + 1\n\tmarcado = nil\n")
