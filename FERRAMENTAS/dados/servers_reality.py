"""
servers_reality.py — as 7 habilidades do conjunto REALITY GUI.

Lido por `FERRAMENTAS/gerar_servers_reality.py`, que monta o Server e o Client
em volta destes corpos.

⛔ Nenhuma linha veio do `reality_tools.rbxmx`. Aquele arquivo está em
   quarentena por causa do backdoor em `Pistol/…/qPerfectionWeld`; o que este
   conjunto usa dele é geometria, som e `KeyframeSequence` — dado, nunca
   código.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("cutscene", False)
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    kw.setdefault("botao", "ButtonR1")
    kw.setdefault("tecla", "R")
    CONJUNTO[alvo] = kw


REGUA = "═" * 62


T("Lapada Seca",
  objeto="LapadaSeca_Server_V1", sufixo="RealityLapada",
  arquetipo="MELEE", alcance_mira=30,
  rotulo_primaria="tapa seco que gira o alvo", rotulo_extra="Tripla",
  origem=["`SLAP`: Handle 1.76 x 0.1 x 0.1 e a malha `Hand`",
          "sons Smack 511340819 · Boom 1489705211 · slaps 165969964"],
  cfg="""	ALCANCE         = 6,
	RAIO_GOLPE      = 6,
	DANO            = 22,
	EMPURRAO        = 44,
	GIRO            = 140,
	RECARGA         = 0.55,

	RECARGA_EXTRA   = 7,
	DANO_TRIPLO     = 18,
	EMPURRAO_TRIPLO = 62,
	TOMBO           = 1.3,""",
  corpo='''
--%s
-- PRIMÁRIA — o tapa
--
-- O que faz a lapada ser lapada é o GIRO: quem leva roda 140°, e a leitura de
-- "levou um tapa" vem daí, não do número do dano.
--%s

local function girar(alvo, graus)
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return end
	alvoRaiz.CFrame = alvoRaiz.CFrame * CFrame.Angles(0, math.rad(graus), 0)
end

local function bater(dano, forca, escala)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 5)) do
		aplicarDano(alvo, dano)
		girar(alvo, CFG.GIRO)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, (alvoRaiz.Position - raiz.Position)
				+ Vector3.new(0, 0.4, 0), forca, 0.2)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = escala })
		end
		achou = true
	end
	if achou then tocarEm("TAPA", ponto, 1 + jitter(0.3) * 0.1) end
	return achou
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("TAPA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("SEQUENCIA", 1.2)
		elseif marca == "GOLPE" then
			bater(CFG.DANO, CFG.EMPURRAO, 1)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — a tripla
--%s

function extra(_mira)
	ocupado = true
	rig:PlaySequence("TRIPLA", function(passo)
		local marca = marcaDe(passo)
		if marca == "GOLPE" then
			bater(CFG.DANO_TRIPLO, CFG.EMPURRAO_TRIPLO, 1.2)
		elseif marca == "FIM" then
			tocar("ESTOURO", 0.9)
			for _, alvo in ipairs(alvosEm(frente(CFG.ALCANCE),
					CFG.RAIO_GOLPE, 5)) do
				tombar(alvo, CFG.TOMBO)
			end
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA))


T("Canhao Satelite",
  objeto="CanhaoSatelite_Server_V1", sufixo="RealityCanhao",
  arquetipo="EXPLOSIVO", alcance_mira=140, cutscene=True,
  rotulo_primaria="o feixe de orbita — ultimate com cutscene",
  rotulo_extra="Marcar",
  origem=["`LowOrbitIonCannon`: Handle 0.8 x 2.3 x 0.4, **21 Sound**",
          "Call 88858815 · Big Explosion 814635481 · Electric Explosion 2674547670",
          "ja estava no repositorio como CRU desde o lote de 2026-08-13"],
  cfg="""	ALCANCE        = 16,
	RECARGA        = 44,
	RAIO_CENA      = 48,
	RAIO_FEIXE     = 26,
	RAIO_NUCLEO    = 9,
	DANO_NUCLEO    = 118,
	DANO_BORDA     = 52,
	EMPURRAO       = 118,
	TOMBO          = 2.8,
	ALTURA_FEIXE   = 400,

	RECARGA_EXTRA  = 6,
	DURACAO_MARCA  = 6,
	DANO_MARCA     = 12,""",
  estado="local marcaId = nil\nlocal marcaOnde = nil",
  corpo='''
--%s
-- PRIMÁRIA — o feixe, COM CUTSCENE
--
-- ULTIMATE: 7.30 s com 71%% de preparação, dentro da regra 5.
--
-- O feixe cai no ponto MARCADO se houver um, e à frente se não houver. É o par
-- da Extra: marcar primeiro e disparar depois é o jeito certo de jogar, e rende
-- alcance de 140 studs em vez de 16.
--%s

local function apagarMarca()
	if marcaId then
		vfx("APAGAR", { id = marcaId })
		marcaId = nil
	end
	marcaOnde = nil
end

function primaria(mira)
	ocupado = true
	local centro = marcaOnde or mira or frente(CFG.ALCANCE)
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 14), "CAMERA")

	rig:PlaySequence("ORBITA", function(passo)
		local marca = marcaDe(passo)
		if not marca then return end

		if marca == "CAMERA" then
			tocar("CHAMADA", 0.8)
		elseif marca == "MARCA" then
			beatCena("MARCA")
			vfx("CONJURA", { posicao = centro, escala = 1.4, duracao = 1.2 })
		elseif marca == "CARGA" then
			beatCena("CARGA")
			tocar("CARGA", 0.7)
		elseif marca == "SEGURA" then
			beatCena("SEGURA")
		elseif marca == "DESCE" then
			beatCena("DESCE")
		elseif marca == "GOLPE" then
			beatCena("GOLPE")
			apagarMarca()
			vfx("DISPARO", { origem = centro + Vector3.new(0, CFG.ALTURA_FEIXE, 0),
				destino = centro, grossura = 7, escala = 2 })
			vfx("LUA_FIM", { posicao = centro, escala = 2.2 })
			tocarEm("FEIXE", centro, 0.6)
			tocarEm("ECO", centro, 0.5)
			golpearArea(centro, CFG.RAIO_FEIXE, CFG.RAIO_NUCLEO,
				CFG.DANO_NUCLEO, CFG.DANO_BORDA, CFG.EMPURRAO, CFG.TOMBO)
		elseif marca == "FIM" then
			fecharCena()
		end
	end, function()
		fecharCena()
		rig:LockCharacter(false)
		ocupado = false
	end)
end

--%s
-- EXTRA — marcar o ponto
--
-- Alcance 140 studs. A marca dura 6 s e cobra pouco por tique: ela não é o
-- dano, é o ALVO do feixe.
--%s

function extra(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("MIRA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("CHAMADA", 1.2)
		elseif marca == "GOLPE" then
			apagarMarca()
			local onde = destino or frente(CFG.ALCANCE)
			marcaOnde = onde
			marcaId = novoId("MARCA")
			vfx("PARAR", { posicao = onde, escala = 1.2,
				duracao = CFG.DURACAO_MARCA, id = marcaId })
			tocarEm("CARGA", onde, 1.1)
			for _, alvo in ipairs(alvosEm(onde, 8, 6)) do
				aplicarDano(alvo, CFG.DANO_MARCA)
			end
			local meu = marcaId
			task.delay(CFG.DURACAO_MARCA, function()
				if marcaId == meu then apagarMarca() end
			end)
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tapagarMarca()\n\tfecharCena()\n")


T("Trem",
  objeto="Trem_Server_V1", sufixo="RealityTrem",
  arquetipo="MELEE", alcance_mira=40,
  rotulo_primaria="investida que atropela em linha reta",
  rotulo_extra="—  (esta Tool tem uma habilidade so)",
  origem=["`a-train`: RequiresHandle = false, sem Handle — ganha um invisivel",
          "`KeyframeSequence` de **40 keyframes** em 0.59 s, amostrada em 10",
          "som blood 5507830073"],
  cfg="""	ALCANCE        = 8,
	RECARGA        = 18,
	VELOCIDADE     = 96,
	TEMPO_CORRIDA  = 0.7,
	RAIO_ATROPELO  = 7,
	DANO           = 46,
	EMPURRAO       = 96,
	TOMBO          = 2,

	RECARGA_EXTRA  = 1,""",
  estado="local impulso = nil\nlocal atropelados = {}",
  corpo='''
--%s
-- PRIMÁRIA — a investida
--
-- A pose vem de uma `KeyframeSequence` de verdade: 40 keyframes em 0.59 s. É
-- curta porque a origem é curta — investida longa não é investida.
--
-- Cada alvo paga UMA vez por corrida: `atropelados` é a lista, e ela zera a
-- cada uso. E a varredura é por TIQUE de 0.08 s, não por quadro — servidor
-- varrendo por frame replica picotado.
--%s

local function pararCorrida()
	if impulso then
		impulso.Parent = nil
		impulso = nil
	end
	table.clear(atropelados)
end

function primaria(_mira)
	ocupado = true
	table.clear(atropelados)
	rig:PlaySequence("INVESTIDA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("APITO", 0.8)
		elseif marca == "GOLPE" then
			tocar("ATROPELA", 1)
			vfx("CONJURA", { posicao = raiz.Position, escala = 1.4,
				duracao = 0.5 })

			if impulso then impulso.Parent = nil end
			impulso = Instance.new("BodyVelocity")
			impulso.MaxForce = Vector3.new(1e5, 0, 1e5)
			impulso.Velocity = raiz.CFrame.LookVector * CFG.VELOCIDADE
			impulso.Parent = raiz
			Debris:AddItem(impulso, CFG.TEMPO_CORRIDA)

			task.spawn(function()
				local ate = os.clock() + CFG.TEMPO_CORRIDA
				while os.clock() < ate and raiz and raiz.Parent do
					for _, alvo in ipairs(alvosEm(raiz.Position,
							CFG.RAIO_ATROPELO, 8)) do
						if not atropelados[alvo] then
							atropelados[alvo] = true
							aplicarDano(alvo, CFG.DANO)
							tombar(alvo, CFG.TOMBO)
							local alvoRaiz = raizDe(alvo)
							if alvoRaiz then
								empurrar(alvo, raiz.CFrame.LookVector
									+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.3)
								vfx("IMPACTO", { posicao = alvoRaiz.Position,
									escala = 1.4 })
							end
						end
					end
					task.wait(0.08)
				end
			end)
		elseif marca == "FIM" then
			pararCorrida()
		end
	end, function()
		pararCorrida()
		ocupado = false
	end)
end

--%s
-- SEM EXTRA — a origem tem uma habilidade só
--%s

function extra(_mira)
	return
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tpararCorrida()\n")


T("Arvore Maligna",
  objeto="ArvoreMaligna_Server_V1", sufixo="RealityArvore",
  arquetipo="ESPECTRAL", alcance_mira=50,
  rotulo_primaria="ergue a arvore que prende quem chega perto",
  rotulo_extra="Galhada",
  origem=["`tre`: Handle 4 x 1 x 2 e o Model `tree` com 5 UnionOperation",
          "som Kill 4817657002",
          "o BodyGyro e a ScreenGui da origem NAO atravessaram"],
  cfg="""	ALCANCE        = 12,
	RECARGA        = 28,
	RAIO_ARVORE    = 16,
	DURACAO        = 7,
	INTERVALO_TICK = 0.9,
	DANO_TICK      = 14,
	LENTIDAO       = 0.45,

	RECARGA_EXTRA  = 9,
	RAIO_GALHO     = 18,
	DANO_GALHO     = 48,
	EMPURRAO       = 70,
	TOMBO          = 1.8,""",
  estado="local arvoreId = nil\nlocal arvoreOnde = nil\nlocal geracao = 0",
  corpo='''
--%s
-- PRIMÁRIA — plantar
--
-- O molde é o `Model` `tree` da origem, com as 5 `UnionOperation`. Entrou como
-- GEOMETRIA, ancorada e invisível; o clone é que aparece.
--%s

local function derrubar()
	geracao = geracao + 1
	if arvoreId then
		vfx("APAGAR", { id = arvoreId })
		arvoreId = nil
	end
	arvoreOnde = nil
end

local function manterArvore(onde, id)
	geracao = geracao + 1
	local minha = geracao
	local ate = os.clock() + CFG.DURACAO
	task.spawn(function()
		while minha == geracao and os.clock() < ate do
			for _, alvo in ipairs(alvosEm(onde, CFG.RAIO_ARVORE, 12)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				afrouxar(alvo, CFG.LENTIDAO, CFG.INTERVALO_TICK * 1.3)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			arvoreId = nil
			arvoreOnde = nil
		end
	end)
end

function primaria(mira)
	ocupado = true
	local destino = mira
	rig:PlaySequence("PLANTAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GALHO", 0.8)
		elseif marca == "GOLPE" then
			derrubar()
			local onde = (destino or frente(CFG.ALCANCE)) - Vector3.new(0, 1.5, 0)
			arvoreOnde = onde
			arvoreId = novoId("ARVORE")
			vfx("BURACO", { posicao = onde, escala = 1.6,
				duracao = CFG.DURACAO, id = arvoreId })
			tocarEm("GALHO", onde, 0.7)
			manterArvore(onde, arvoreId)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — a galhada
--
-- Consome a árvore. Sem uma de pé sai com metade do dano — a Tool nunca fica
-- inerte, mas o par certo rende mais.
--%s

function extra(_mira)
	ocupado = true
	local onde = arvoreOnde
	rig:PlaySequence("GALHADA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GALHO", 1.15)
		elseif marca == "GOLPE" then
			local centro = onde or frente(CFG.ALCANCE)
			local cheio = onde ~= nil
			derrubar()
			vfx("BURACO_FIM", { posicao = centro, escala = cheio and 1.8 or 1 })
			tocarEm("GALHO", centro, 0.55)
			golpearArea(centro, CFG.RAIO_GALHO, CFG.RAIO_GALHO * 0.4,
				cheio and CFG.DANO_GALHO or CFG.DANO_GALHO * 0.5,
				cheio and CFG.DANO_GALHO * 0.5 or CFG.DANO_GALHO * 0.25,
				CFG.EMPURRAO, cheio and CFG.TOMBO or nil)
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tderrubar()\n")


T("Gato Ajudante Boss",
  objeto="GatoAjudanteBoss_Server_V1", sufixo="RealityGato",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_primaria="invoca o gato, que briga por voce",
  rotulo_extra="Mandar",
  origem=["`gravity cat not amused`: Handle 4 x 1 x 2 e o Model do gato",
          "som theme 1842053299",
          "o Humanoid e os 6 Motor6D NAO atravessaram: o gato entra como",
          "   geometria, e quem invoca e dispensa e a Tool (NPC fora de escopo)"],
  cfg="""	ALCANCE        = 12,
	RECARGA        = 34,
	DURACAO_GATO   = 12,
	RAIO_GATO      = 16,
	INTERVALO_TICK = 0.8,
	DANO_TICK      = 11,

	RECARGA_EXTRA  = 8,
	RAIO_ENVIO     = 50,
	RAIO_SALTO     = 13,
	DANO_SALTO     = 44,
	EMPURRAO       = 68,""",
  estado="local gatoId = nil\nlocal gatoOnde = nil\nlocal geracao = 0",
  corpo='''
--%s
-- PRIMÁRIA — chamar o gato
--
-- O gato é INVOCAÇÃO, não NPC. O `Humanoid` e os seis `Motor6D` da origem não
-- atravessaram: o que está em `Tool/Moldes/` é o corpo dele como geometria, e
-- quem o invoca, faz brigar e dispensa é esta Tool — com prazo, e solto no
-- `desmontar()`.
--
-- Mesmo desenho do `Xester Invocacao` e do `Faker Entity`. Invocar é
-- habilidade de Tool; manter sistema de NPC é que o CLAUDE.md põe fora.
--%s

local function dispensarGato()
	geracao = geracao + 1
	if gatoId then
		vfx("APAGAR", { id = gatoId })
		gatoId = nil
	end
	gatoOnde = nil
end

local function manterGato(onde, id)
	geracao = geracao + 1
	local minha = geracao
	local ate = os.clock() + CFG.DURACAO_GATO
	task.spawn(function()
		while minha == geracao and os.clock() < ate do
			local centro = gatoOnde or onde
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_GATO, 10)) do
				aplicarDano(alvo, CFG.DANO_TICK)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			gatoId = nil
			gatoOnde = nil
		end
	end)
end

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CHAMAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("MIADO", 1.3)
		elseif marca == "GOLPE" then
			dispensarGato()
			local onde = frente(CFG.ALCANCE) + Vector3.new(0, 2, 0)
			gatoOnde = onde
			gatoId = novoId("GATO")
			vfx("ENTIDADE", { posicao = onde, escala = 1,
				duracao = CFG.DURACAO_GATO, id = gatoId })
			tocarEm("MIADO", onde, 1)
			manterGato(onde, gatoId)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — mandar o gato
--
-- Ele SALTA: uma fala do servidor, e o percurso é desenhado pelo cliente.
--%s

function extra(mira)
	if not gatoId then
		tocar("MIADO", 0.7)
		return
	end

	ocupado = true
	rig:PlaySequence("MANDAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("MIADO", 1.5)
		elseif marca == "GOLPE" then
			local alvo = maisPerto(mira, CFG.RAIO_ENVIO)
			local alvoRaiz = alvo and raizDe(alvo)
			local onde = (alvoRaiz and alvoRaiz.Position) or mira
				or frente(CFG.ALCANCE)

			local partiu = gatoOnde
			gatoOnde = onde
			if partiu then
				vfx("FEIXE", { origem = partiu, destino = onde,
					grossura = 1.6, escala = 1 })
			end
			vfx("ENTIDADE", { posicao = onde, escala = 1.2, duracao = 2.4 })
			tocarEm("MIADO", onde, 0.85)

			for _, perto in ipairs(alvosEm(onde, CFG.RAIO_SALTO, 8)) do
				aplicarDano(perto, CFG.DANO_SALTO)
				local pertoRaiz = raizDe(perto)
				if pertoRaiz then
					empurrar(perto, (pertoRaiz.Position - onde)
						+ Vector3.new(0, 0.4, 0), CFG.EMPURRAO, 0.26)
				end
			end
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tdispensarGato()\n")


T("Samsungus",
  objeto="Samsungus_Server_V1", sufixo="RealitySamsungus",
  arquetipo="MELEE", alcance_mira=35,
  rotulo_primaria="bate com o aparelho", rotulo_extra="Chamada",
  origem=["`samsung`: Handle **MeshPart** id 430345282 — o celular",
          "sons MetalHit 6879335951 · Swoosh 9113749736 · Hit 743886825",
          "a origem clonava o LeadpipeServer do Cano De Rua; nada dele entrou"],
  cfg="""	ALCANCE        = 6,
	RAIO_GOLPE     = 6,
	DANO           = 26,
	EMPURRAO       = 40,
	RECARGA        = 0.65,

	RECARGA_EXTRA  = 12,
	RAIO_CHAMADA   = 18,
	DANO_CHAMADA   = 32,
	DURACAO_TRAVA  = 1.8,
	LENTIDAO       = 0.4,
	TEMPO_LENTO    = 3,""",
  corpo='''
--%s
-- PRIMÁRIA — a batida
--%s

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("BATIDA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GIRO", 1.1)
		elseif marca == "GOLPE" then
			local ponto = frente(CFG.ALCANCE)
			local achou = false
			for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
				aplicarDano(alvo, CFG.DANO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					empurrar(alvo, (alvoRaiz.Position - raiz.Position)
						+ Vector3.new(0, 0.3, 0), CFG.EMPURRAO, 0.18)
					vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1 })
				end
				achou = true
			end
			if achou then tocarEm("BATE", ponto, 1 + jitter(0.4) * 0.1) end
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — a chamada
--
-- O aparelho toca alto e trava quem está perto. `BodyPosition` com prazo, no
-- ponto onde o alvo já está — nunca `Anchored`, que prenderia o jogador se a
-- Tool sumisse no meio.
--%s

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CHAMADA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GIRO", 0.8)
		elseif marca == "SEGURA" then
			tocar("IMPACTO", 1.4)
		elseif marca == "GOLPE" then
			local centro = raiz.Position
			vfx("RELOGIO", { posicao = centro, escala = 1.6 })
			tocarEm("IMPACTO", centro, 0.9)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CHAMADA, 12)) do
				aplicarDano(alvo, CFG.DANO_CHAMADA)
				prender(alvo, CFG.DURACAO_TRAVA)
				afrouxar(alvo, CFG.LENTIDAO, CFG.TEMPO_LENTO)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("PARAR", { posicao = alvoRaiz.Position, escala = 1,
						duracao = CFG.DURACAO_TRAVA })
				end
			end
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar='\ttocar("GUARDA", 1)\n')


T("Danca Provocadora",
  objeto="DancaProvocadora_Server_V1", sufixo="RealityDanca",
  arquetipo="SUPORTE", alcance_mira=40,
  rotulo_primaria="a danca de 12 s que puxa a atencao",
  rotulo_extra="—  (esta Tool tem uma habilidade so)",
  origem=["`kick dance`: RequiresHandle = false — ganha um Handle invisivel",
          "`KeyframeSequence` `california gurls`: **361 keyframes** em 12.00 s,",
          "   amostrada em 14 — a maior densidade que ja entrou no repositorio",
          "sem som proprio (o `music` veio vazio): empresta 2 do Canhao"],
  cfg="""	ALCANCE        = 10,
	RECARGA        = 24,
	RAIO_PROVOCA   = 26,
	INTERVALO_TICK = 1.6,
	DANO_TICK      = 6,
	PUXAO          = 22,
	LENTIDAO       = 0.7,
	DURACAO_AURA   = 12,

	RECARGA_EXTRA  = 1,""",
  estado="local dancaId = nil\nlocal geracao = 0",
  corpo='''
--%s
-- PRIMÁRIA — a dança
--
-- 14 quadros amostrados de uma `KeyframeSequence` de **361 keyframes** em
-- 12.00 s. É a maior densidade de animação que já entrou aqui, e a estreia do
-- formato: tudo antes era pose escrita em laço.
--
-- Provocar é PUXAR: quem está no raio é arrastado para perto, desacelera, e
-- paga pouco por tique. A Tool não mata — ela junta gente para outra matar.
--%s

local function pararDanca()
	geracao = geracao + 1
	if dancaId then
		vfx("APAGAR", { id = dancaId })
		dancaId = nil
	end
end

function primaria(_mira)
	ocupado = true
	pararDanca()
	geracao = geracao + 1
	local minha = geracao
	dancaId = novoId("DANCA")
	local id = dancaId

	vfx("COROA", { posicao = raiz.Position, escala = 1.2,
		duracao = CFG.DURACAO_AURA, id = id })
	tocar("PROVOCA", 1)

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO_AURA
		while minha == geracao and os.clock() < ate do
			if not (raiz and raiz.Parent) then break end
			local centro = raiz.Position
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_PROVOCA, 14)) do
				aplicarDano(alvo, CFG.DANO_TICK)
				afrouxar(alvo, CFG.LENTIDAO, CFG.INTERVALO_TICK * 1.2)
				puxar(alvo, centro, CFG.PUXAO, CFG.INTERVALO_TICK * 0.7)
			end
			task.wait(CFG.INTERVALO_TICK)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			dancaId = nil
		end
	end)

	rig:PlaySequence("DANCA", function(passo)
		local marca = marcaDe(passo)
		if marca == "GOLPE" then
			tocarEm("BATIDA", raiz.Position, 1 + jitter(0.6) * 0.15)
			vfx("CONJURA", { posicao = raiz.Position, escala = 0.9,
				duracao = 0.4 })
		elseif marca == "FIM" then
			pararDanca()
		end
	end, function()
		pararDanca()
		ocupado = false
	end)
end

--%s
-- SEM EXTRA — a dança é a Tool inteira
--%s

function extra(_mira)
	return
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tpararDanca()\n")
