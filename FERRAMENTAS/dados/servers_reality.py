"""
servers_reality.py — as 7 habilidades do conjunto REALITY GUI.

Lido por `FERRAMENTAS/gerar_servers_reality.py`, que monta o Server e o Client
em volta destes corpos.

⛔ Nenhuma linha veio do `reality_tools.rbxmx`. Aquele arquivo está em
   quarentena por causa do backdoor em `Pistol/…/qPerfectionWeld`; o que este
   conjunto usa dele é geometria, som e `KeyframeSequence` — dado, nunca
   código.

════════════════════════════════════════════════════════════════════════
A LÓGICA É A DA ORIGEM. LIDA, NÃO COPIADA.
════════════════════════════════════════════════════════════════════════

    A primeira versão destas sete foi escrita POR TEMA: o nome da Tool sugeria
    uma habilidade e a habilidade era inventada em cima do nome. `Lapada Seca`
    girava o alvo 140°; `Trem` era uma investida de 0.7 s; `Arvore Maligna` era
    uma aura parada; a dança puxava e machucava.

    Nada disso está nos scripts de origem. O que está:

    | Tool | O que a origem REALMENTE faz |
    |---|---|
    | `Lapada Seca` | `Hand.Touched` → `BodyVelocity` de **900** na direção do alvo INVERTIDA, `Sit = true`, ragdoll. Arremesso, não giro. |
    | `Canhao Satelite` | disco de mira no chão → feixe de órbita → bola de 150 studs, tremor a 600, e **radiação que fica** ~12 s |
    | `Trem` | `Activated` põe **`WalkSpeed = 125`** e mata por contato até o `Unequipped`. Estado de corrida, não investida. |
    | `Arvore Maligna` | a árvore **CAÇA**: anda 15 studs por passo em direção ao mais perto, e **só enquanto ninguém olha para ela** |
    | `Gato Ajudante Boss` | o gato **BOMBARDEIA**: bola preta no alvo, 0.8 s, `Explosion` raio 7 — e a variante que chove 50 delas |
    | `Samsungus` | leadpipe de R2DA: combo de **duas** batidas alternadas, 20–25 de dano, `PlatformStand`, e **concussão** que faz o alvo cambalear |
    | `Danca Provocadora` | toca a animação e a música. **Só isso.** Para no `Unequipped`. |

    Cada habilidade abaixo reproduz esse comportamento sob as regras do
    repositório — `TakeDamage` pelo Núcleo no lugar de `Health = 0`, `task.*`
    no lugar de `wait`, jitter determinístico no lugar dos `math.random`,
    `PlatformStand` com prazo no lugar de `BreakJoints`, e nada de `ScreenGui`.

    O que NÃO atravessou, e por quê:

      · `Health = 0` / `BreakJoints` / `Foe:Destroy()` — matar por decreto tira
        o abate do Núcleo; a origem fazia isso em seis lugares
      · `ScreenGui` branca do leadpipe e do gato — proibida dentro de Tool
      · `require(ReplicatedFirst.Ragdoll)` — dependência FORA da Tool, que é a
        regra nº 1; o tombo virou `PlatformStand` com prazo
      · o `v:destroy()` do LOIC, que apagava toda peça num raio de 250 studs
      · `game.Chat:Chat` do LOIC, e o `Humanoid.Name = "Immunity"` do leadpipe

════════════════════════════════════════════════════════════════════════
EXTRA DE CICLO NÃO É EXTRA INVENTADA
════════════════════════════════════════════════════════════════════════

    Quatro destas origens têm UMA habilidade só, e ela liga no `Activated` e
    desliga no `Unequipped`. A Extra dessas quatro é o próprio desligar —
    `Frear`, `Derrubar`, `Parar` — porque é o que a origem faz, e não uma
    segunda habilidade inventada para preencher a tecla.
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
  rotulo_primaria="o tapa que arremessa", rotulo_extra="Mao Quente",
  origem=["`SLAP`: Handle 1.76 x 0.1 x 0.1 e a malha `Hand`",
          "sons Smack 511340819 · Boom 1489705211 · slaps 165969964",
          "LOGICA: `Hand.Touched` -> BodyVelocity 900 em -Head.lookVector,",
          "   Sit = true, e seis clones de RagdollSCript. Arremesso por CONTATO,",
          "   nunca por Activated — o Activated da origem so tocava a animacao."],
  cfg="""	RAIO_MAO        = 5.5,
	DANO            = 34,
	EMPURRAO        = 130,
	ALTURA          = 0.55,
	TEMPO_VOO       = 0.28,
	TOMBO           = 2.2,
	JANELA          = 0.35,
	PASSO           = 0.07,
	INTERVALO_ALVO  = 0.5,
	RECARGA         = 0.7,

	RECARGA_EXTRA   = 14,
	DURACAO_QUENTE  = 5,
	DANO_QUENTE     = 21,
	EMPURRAO_QUENTE = 165,""",
  estado="local geracao = 0",
  corpo='''
--%s
-- O ARREMESSO — a assinatura da origem
--
-- `BodyVelocity` de 900 em `-blender.CFrame.lookVector`: a direção é a do
-- ALVO, invertida. Quem leva o tapa sai voando **de costas para onde estava
-- olhando**, não para longe de quem bateu. Essa é a diferença entre a lapada e
-- um empurrão qualquer, e é por isso que aqui não se usa o `empurrar` com
-- vetor radial.
--
-- A origem matava (`humanoid.Health = 0` dentro do `RagdollSCript`, clonado
-- seis vezes). Aqui o tombo é `PlatformStand` com prazo, e o dano passa pelo
-- Núcleo.
--%s

local function arremessar(alvo, dano, forca)
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return false end
	aplicarDano(alvo, dano)
	empurrar(alvo, -alvoRaiz.CFrame.LookVector + Vector3.new(0, CFG.ALTURA, 0),
		forca, CFG.TEMPO_VOO)
	tombar(alvo, CFG.TOMBO)
	vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.4 })
	tocarEm("TAPA", alvoRaiz.Position, 1 + jitter(0.3) * 0.1)
	return true
end

--- A MÃO FICA VIVA POR UMA JANELA.
---
--- Na origem não existe golpe: existe a mão ligada no `Touched` o tempo todo.
--- Aqui ela acende na marca `GOLPE` e apaga sozinha, o que dá o mesmo jogo sem
--- deixar o portador matando por encostar enquanto anda.
---
--- `Touched` sozinho não bastaria: o Handle tem 0.1 x 0.1 de seção e escapa
--- toque em quem passa rápido. A varredura por TIQUE cobre o buraco — 0.07 s,
--- nunca por quadro.
local function janelaViva(duracao, dano, forca)
	geracao = geracao + 1
	local minha = geracao
	local ultimo = {}

	local function servir(alvo)
		if not alvo or alvo.Health <= 0 then return end
		local agora = os.clock()
		if ultimo[alvo] and agora - ultimo[alvo] < CFG.INTERVALO_ALVO then
			return
		end
		ultimo[alvo] = agora
		arremessar(alvo, dano, forca)
	end

	local toque = guardar(Handle.Touched:Connect(function(parte)
		if minha ~= geracao then return end
		local corpo = parte and parte:FindFirstAncestorOfClass("Model")
		if not corpo or corpo == personagem then return end
		servir(corpo:FindFirstChildOfClass("Humanoid"))
	end))

	task.spawn(function()
		local ate = os.clock() + duracao
		while minha == geracao and os.clock() < ate do
			if not (raiz and raiz.Parent) then break end
			for _, alvo in ipairs(alvosEm(Handle.Position, CFG.RAIO_MAO, 6)) do
				servir(alvo)
			end
			task.wait(CFG.PASSO)
		end
		toque:Disconnect()
	end)
end

local function apagarMao()
	geracao = geracao + 1
end

--%s
-- PRIMÁRIA — o tapa
--%s

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("TAPA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("SEQUENCIA", 1.2)
		elseif marca == "GOLPE" then
			janelaViva(CFG.JANELA, CFG.DANO, CFG.EMPURRAO)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — a mão quente
--
-- A origem não tem segunda habilidade: tem a mão ligada no `Touched` enquanto
-- a Tool estiver equipada. Esta Extra é exatamente isso, com prazo — 5 s de
-- mão acesa, arremessando quem encostar.
--%s

function extra(_mira)
	ocupado = true
	rig:PlaySequence("MAO_QUENTE", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("ESTOURO", 0.9)
		elseif marca == "SEGURA" then
			janelaViva(CFG.DURACAO_QUENTE, CFG.DANO_QUENTE, CFG.EMPURRAO_QUENTE)
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tapagarMao()\n")


T("Canhao Satelite",
  objeto="CanhaoSatelite_Server_V1", sufixo="RealityCanhao",
  arquetipo="EXPLOSIVO", alcance_mira=140, cutscene=True,
  rotulo_primaria="o feixe de orbita, e a radiacao que fica",
  rotulo_extra="Marcar",
  origem=["`LowOrbitIonCannon`: Handle 0.8 x 2.3 x 0.4, **21 Sound**",
          "Call 88858815 · Big Explosion 814635481 · Electric Explosion 2674547670",
          "ja estava no repositorio como CRU desde o lote de 2026-08-13",
          "LOGICA: disco de mira que so aceita superficie Top -> Call -> 3 s ->",
          "   satelite desliza para cima do ponto -> feixe -> bola de 150 studs,",
          "   tremor em todo mundo a 600 studs, e **radiacao expandindo por 12 s**"],
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

	DURACAO_RAD    = 10,
	INTERVALO_RAD  = 1,
	DANO_RAD       = 9,

	RECARGA_EXTRA  = 6,
	DURACAO_MARCA  = 8,""",
  estado=("local marcaId = nil\nlocal marcaOnde = nil\n"
          "local radiacaoId = nil\nlocal geracao = 0"),
  corpo='''
--%s
-- PRIMÁRIA — o feixe, COM CUTSCENE
--
-- ULTIMATE: 7.30 s com 71 por cento de preparação, dentro da regra 5.
--
-- O feixe cai no ponto MARCADO se houver um, e à frente se não houver. É o par
-- da Extra, e reproduz o disco de mira da origem: lá o clique só valia sobre
-- uma superfície `Top`, e o disco ficava azul ou vermelho para dizer isso.
--
-- A RADIAÇÃO É DA ORIGEM, E FALTAVA. Depois que a bola de 150 studs nasce, o
-- LOIC solta 29 esferas `Neon` e 100 esferas `Glass` expandindo por cerca de
-- 12 s — não é decoração, é o que faz o ponto ficar intransitável depois do
-- tiro. Aqui ela cobra por tique, com prazo, e some sozinha.
--%s

local function apagarMarca()
	if marcaId then
		vfx("APAGAR", { id = marcaId })
		marcaId = nil
	end
	marcaOnde = nil
end

local function apagarRadiacao()
	geracao = geracao + 1
	if radiacaoId then
		vfx("APAGAR", { id = radiacaoId })
		radiacaoId = nil
	end
end

--- A cratera que continua cobrando. Tique de 1 s, nunca por quadro.
local function irradiar(centro)
	apagarRadiacao()
	geracao = geracao + 1
	local minha = geracao
	radiacaoId = novoId("RADIACAO")
	local id = radiacaoId

	vfx("RADIACAO", { posicao = centro, raio = CFG.RAIO_FEIXE,
		duracao = CFG.DURACAO_RAD, id = id })

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO_RAD
		while minha == geracao and os.clock() < ate do
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_FEIXE, 16)) do
				aplicarDano(alvo, CFG.DANO_RAD)
			end
			task.wait(CFG.INTERVALO_RAD)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			radiacaoId = nil
		end
	end)
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
			irradiar(centro)
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
-- É o disco de mira da origem, na sua própria tecla. Alcance 140 studs, dura
-- 8 s, e **não faz dano**: o disco do LOIC não fere ninguém, ele só diz onde o
-- tiro vai cair. A versão anterior cobrava 12 aqui, o que era invenção.
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
			local meu = marcaId
			task.delay(CFG.DURACAO_MARCA, function()
				if marcaId == meu then apagarMarca() end
			end)
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tapagarMarca()\n\tapagarRadiacao()\n\tfecharCena()\n")


T("Trem",
  objeto="Trem_Server_V1", sufixo="RealityTrem",
  arquetipo="MELEE", alcance_mira=40,
  rotulo_primaria="entra em corrida e atropela por contato",
  rotulo_extra="Frear",
  origem=["`a-train`: RequiresHandle = false, sem Handle — ganha um invisivel",
          "`KeyframeSequence` de **40 keyframes** em 0.59 s, amostrada em 10",
          "som blood 5507830073",
          "LOGICA: `Activated` poe **WalkSpeed = 125**, toca a musica, desliga o",
          "   Animate — e o `Touched` mata quem encostar. `Unequipped` devolve",
          "   WalkSpeed = 16. E ESTADO DE CORRIDA, nao uma investida de 0.7 s."],
  cfg="""	RECARGA        = 22,
	VELOCIDADE     = 110,
	DURACAO        = 6,
	RAIO_ATROPELO  = 7,
	DANO           = 46,
	EMPURRAO       = 96,
	TOMBO          = 2,
	PASSO          = 0.1,
	RASTRO_A_CADA  = 4,

	RECARGA_EXTRA  = 1,""",
  estado=("local velocidadeAntes = nil\nlocal atropelados = {}\n"
          "local geracao = 0"),
  corpo='''
--%s
-- A CORRIDA — o que a origem realmente faz
--
-- `humanoid.WalkSpeed = 125` no `Activated`, e volta a 16 no `Unequipped`. Não
-- há impulso, não há dash: o personagem simplesmente passa a correr, e mata
-- quem encostar enquanto isso dura. A versão anterior era um `BodyVelocity` de
-- 0.7 s, que é outra coisa.
--
-- A velocidade guardada é a que o portador TINHA, nunca 16 fixo — ele pode
-- estar com velocidade própria de outra Tool, e devolver 16 seria roubar.
--
-- Cada alvo paga UMA vez por corrida. Na origem isso é automático porque o
-- alvo é destruído; aqui é a lista `atropelados`, que zera a cada uso.
--%s

local function frear()
	geracao = geracao + 1
	table.clear(atropelados)
	if velocidadeAntes and humanoide and humanoide.Parent
			and humanoide.Health > 0 then
		humanoide.WalkSpeed = velocidadeAntes
	end
	velocidadeAntes = nil
end

local function correr()
	if not (humanoide and raiz) then return end
	geracao = geracao + 1
	local minha = geracao
	table.clear(atropelados)

	if velocidadeAntes == nil then
		velocidadeAntes = humanoide.WalkSpeed
	end
	humanoide.WalkSpeed = CFG.VELOCIDADE
	tocar("APITO", 0.85)

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		local tique = 0
		while minha == geracao and os.clock() < ate do
			if not (raiz and raiz.Parent and humanoide
					and humanoide.Health > 0) then
				break
			end

			tique = tique + 1
			if tique %% CFG.RASTRO_A_CADA == 0 then
				vfx("CONJURA", { posicao = raiz.Position - Vector3.new(0, 2.2, 0),
					escala = 0.8, duracao = 0.35 })
			end

			for _, alvo in ipairs(alvosEm(raiz.Position, CFG.RAIO_ATROPELO, 8)) do
				if not atropelados[alvo] then
					atropelados[alvo] = true
					aplicarDano(alvo, CFG.DANO)
					tombar(alvo, CFG.TOMBO)
					local alvoRaiz = raizDe(alvo)
					if alvoRaiz then
						empurrar(alvo, raiz.CFrame.LookVector
							+ Vector3.new(0, 0.5, 0), CFG.EMPURRAO, 0.3)
						vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.6 })
						tocarEm("ATROPELA", alvoRaiz.Position, 1)
					end
				end
			end
			task.wait(CFG.PASSO)
		end
		if minha == geracao then frear() end
	end)
end

--%s
-- PRIMÁRIA — entrar em corrida
--%s

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("INVESTIDA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("APITO", 1.1)
		elseif marca == "GOLPE" then
			correr()
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — frear
--
-- A origem para a corrida no `Unequipped`, e só. Esta Extra é esse mesmo
-- desligar, na tecla — não uma segunda habilidade inventada.
--%s

function extra(_mira)
	if velocidadeAntes == nil then return end
	tocar("ATROPELA", 0.7)
	frear()
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tfrear()\n")


T("Arvore Maligna",
  objeto="ArvoreMaligna_Server_V1", sufixo="RealityArvore",
  arquetipo="ESPECTRAL", alcance_mira=50,
  rotulo_primaria="planta a arvore, e ela caca",
  rotulo_extra="Derrubar",
  origem=["`tre`: Handle 4 x 1 x 2 e o Model `tree` com 5 UnionOperation",
          "som Kill 4817657002",
          "LOGICA: a arvore CACA. Ela procura o Humanoid mais perto num raio de",
          "   200, e **so anda enquanto ninguem esta olhando para ela** — o",
          "   `canSee` da origem testa FOV mais raycast. A menos de 10 studs,",
          "   mata. E anjo chorao, nao aura parada.",
          "o BodyGyro e a ScreenGui da origem NAO atravessaram"],
  cfg="""	ALCANCE        = 12,
	RECARGA        = 30,
	DURACAO        = 16,
	ALCANCE_CACA   = 90,
	PASSO          = 0.35,
	PASSO_STUDS    = 4.5,
	RAIO_MORTE     = 7,
	DANO_MORTE     = 85,
	TOMBO          = 2.5,
	INTERVALO_ALVO = 1.6,
	ARRASTO_A_CADA = 4,

	RECARGA_EXTRA  = 2,""",
  estado=("local arvoreId = nil\nlocal arvoreOnde = nil\n"
          "local geracao = 0"),
  corpo='''
--%s
-- O ANJO CHORÃO — a mecânica que a versão anterior tinha perdido
--
-- O `tre` não é uma aura. Ele é uma peça que persegue: acha o `Humanoid` mais
-- perto num raio de 200 studs, aponta para ele, e **avança 15 studs por volta
-- do laço — mas só enquanto aquele alvo NÃO está olhando para ela**. O teste
-- da origem (`canSee`) é o produto escalar do vetor até a árvore com o
-- `lookVector` da cabeça: positivo = está no campo de visão = ela congela.
--
-- A menos de 10 studs, mata.
--
-- O que mudou para caber nas regras: o passo é de 0.35 s (a origem roda com
-- `wait(.000001)`, o que é por quadro e replica picotado), o avanço é de 4.5
-- studs por passo em vez de 15, o alcance é 90 em vez de 200, e o abate é
-- `TakeDamage` pelo Núcleo em vez de `Health = 0` mais `BreakJoints`.
--
-- O raycast de linha de visão da origem ficou de fora: o teste de FOV é o que
-- dá a leitura de "ela parou porque eu olhei", e um raycast por alvo por tique
-- pagaria caro por pouco. Quem se esconder atrás de uma parede e olhar na
-- direção dela ainda a congela.
--%s

local function derrubar()
	geracao = geracao + 1
	if arvoreId then
		vfx("APAGAR", { id = arvoreId })
		arvoreId = nil
	end
	arvoreOnde = nil
end

--- O alvo está olhando para o ponto? `> 0` é o teste da origem: meio giro
--- inteiro conta como "de frente", e é isso que faz a árvore parecer travada
--- sempre que se vira para ela.
local function estaOlhando(alvo, ponto)
	local corpo = alvo and alvo.Parent
	local cabeca = corpo and (corpo:FindFirstChild("Head")
		or corpo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return false end
	local para = ponto - cabeca.Position
	if para.Magnitude < 0.5 then return true end
	return para.Unit:Dot(cabeca.CFrame.LookVector) > 0
end

local function cacar(id)
	geracao = geracao + 1
	local minha = geracao
	local ultimo = {}

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO
		local tique = 0
		while minha == geracao and os.clock() < ate and arvoreOnde do
			tique = tique + 1

			local presa, dist = nil, math.huge
			for _, alvo in ipairs(alvosEm(arvoreOnde, CFG.ALCANCE_CACA, 16)) do
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					local d = (alvoRaiz.Position - arvoreOnde).Magnitude
					if d < dist then presa, dist = alvo, d end
				end
			end

			local presaRaiz = presa and raizDe(presa)
			if presaRaiz then
				if estaOlhando(presa, arvoreOnde) then
					-- congelada. É a regra da origem, e é o jogo inteiro dela.
					if tique %% CFG.ARRASTO_A_CADA == 0 then
						vfx("PARAR", { posicao = arvoreOnde, escala = 0.7,
							duracao = CFG.PASSO * CFG.ARRASTO_A_CADA })
					end
				else
					local delta = presaRaiz.Position - arvoreOnde
					local plano = Vector3.new(delta.X, 0, delta.Z)
					if plano.Magnitude > 0.5 then
						local anda = math.min(CFG.PASSO_STUDS, plano.Magnitude)
						arvoreOnde = arvoreOnde + plano.Unit * anda
						vfx("MOVER", { id = id, posicao = arvoreOnde,
							tempo = CFG.PASSO, olhar = presaRaiz.Position })
						if tique %% CFG.ARRASTO_A_CADA == 0 then
							tocarEm("GALHO", arvoreOnde, 1.4,
								CFG.PASSO * CFG.ARRASTO_A_CADA + 0.3)
						end
					end
				end

				local agora = os.clock()
				if dist <= CFG.RAIO_MORTE
						and (not ultimo[presa]
							or agora - ultimo[presa] >= CFG.INTERVALO_ALVO) then
					ultimo[presa] = agora
					aplicarDano(presa, CFG.DANO_MORTE)
					tombar(presa, CFG.TOMBO)
					vfx("BURACO_FIM", { posicao = presaRaiz.Position, escala = 1.4 })
					tocarEm("GALHO", presaRaiz.Position, 0.55)
				end
			end

			task.wait(CFG.PASSO)
		end
		if minha == geracao then derrubar() end
	end)
end

--%s
-- PRIMÁRIA — plantar
--
-- O molde é o `Model` `tree` da origem, com as 5 `UnionOperation`. Entrou como
-- GEOMETRIA, ancorada e invisível; o clone é que aparece, e é ele que anda.
--%s

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
			cacar(arvoreId)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — derrubar
--
-- A origem não tem segunda habilidade: a árvore fica de pé até o fim do round.
-- Esta Extra é o desligar dela, na tecla.
--%s

function extra(_mira)
	if not arvoreId then return end
	ocupado = true
	local onde = arvoreOnde
	rig:PlaySequence("GALHADA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GALHO", 1.15)
		elseif marca == "GOLPE" then
			local centro = onde or frente(CFG.ALCANCE)
			derrubar()
			vfx("BURACO_FIM", { posicao = centro, escala = 1.8 })
			tocarEm("GALHO", centro, 0.55)
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tderrubar()\n")


T("Gato Ajudante Boss",
  objeto="GatoAjudanteBoss_Server_V1", sufixo="RealityGato",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_primaria="invoca o gato, que bombardeia",
  rotulo_extra="Chuva",
  origem=["`gravity cat not amused`: Handle 4 x 1 x 2 e o Model do gato",
          "som theme 1842053299",
          "LOGICA: o gato sobe 12 studs, toca o tema, e faz tres ataques —",
          "   attack1: bola preta em cima do alvo, 0.8 s, Explosion raio 7",
          "   attack2: **50 bolas** chovendo em volta, uma a cada 0.1 s",
          "   attack3: teleporta ate o alvo, espera 1 s, volta, e mata",
          "o Humanoid e os 6 Motor6D NAO atravessaram: o gato entra como",
          "   geometria, e quem invoca e dispensa e a Tool (NPC fora de escopo)"],
  cfg="""	ALCANCE        = 12,
	RECARGA        = 34,
	ALTURA         = 6,
	DURACAO_GATO   = 14,
	RAIO_CACA      = 60,
	INTERVALO_BOMBA = 1.6,
	ESPERA_BOMBA   = 0.8,
	RAIO_BOMBA     = 7,
	DANO_BOMBA     = 38,
	EMPURRAO       = 68,
	TOMBO          = 1.6,

	RECARGA_EXTRA  = 16,
	BOMBAS         = 12,
	RAIO_CHUVA     = 30,
	PASSO_CHUVA    = 0.12,""",
  estado=("local gatoId = nil\nlocal gatoOnde = nil\n"
          "local geracao = 0"),
  corpo='''
--%s
-- A BOMBA — `attack1` da origem, que é o que o gato faz o tempo todo
--
-- Bola preta em cima do alvo, som, 0.8 s de espera, e uma `Explosion` de raio
-- 7. A espera é o ponto: dá para sair de baixo, e é o que separa o gato de uma
-- aura que cobra por estar perto (que foi o que a versão anterior fez dele).
--
-- `Instance.new("Explosion")` é proibido aqui — quem detecta é o Núcleo, por
-- `golpearArea`. O visual do estouro é do cliente.
--%s

local function soltarBomba(onde, raio, dano)
	vfx("BOMBA", { posicao = onde, escala = raio / 7,
		espera = CFG.ESPERA_BOMBA, raio = raio })
	tocarEm("MIADO", onde, 1.45)
	task.delay(CFG.ESPERA_BOMBA, function()
		vfx("LUA_FIM", { posicao = onde, escala = raio / 7 })
		tocarEm("MIADO", onde, 0.5)
		golpearArea(onde, raio, raio * 0.5, dano, dano * 0.55,
			CFG.EMPURRAO, CFG.TOMBO)
	end)
end

local function dispensarGato()
	geracao = geracao + 1
	if gatoId then
		vfx("APAGAR", { id = gatoId })
		gatoId = nil
	end
	gatoOnde = nil
end

--- O gato invocado. Ele não anda: ele fica no lugar e bombardeia o mais perto,
--- que é o `attack1` em laço da origem.
local function manterGato(onde, id)
	geracao = geracao + 1
	local minha = geracao
	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO_GATO
		while minha == geracao and os.clock() < ate do
			local centro = gatoOnde or onde
			local presa = maisPerto(centro, CFG.RAIO_CACA)
			local presaRaiz = presa and raizDe(presa)
			if presaRaiz then
				soltarBomba(presaRaiz.Position, CFG.RAIO_BOMBA, CFG.DANO_BOMBA)
			end
			task.wait(CFG.INTERVALO_BOMBA)
		end
		if minha == geracao then
			vfx("APAGAR", { id = id })
			gatoId = nil
			gatoOnde = nil
		end
	end)
end

--%s
-- PRIMÁRIA — chamar o gato
--
-- O gato é INVOCAÇÃO, não NPC. O `Humanoid` e os seis `Motor6D` da origem não
-- atravessaram: o que está em `Tool/Moldes/` é o corpo dele como geometria, e
-- quem o invoca, faz bombardear e dispensa é esta Tool — com prazo, e solto no
-- `desmontar()`.
--
-- Mesmo desenho do `Xester Invocacao` e do `Faker Entity`. Invocar é
-- habilidade de Tool; manter sistema de NPC é que o CLAUDE.md põe fora.
--%s

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("CHAMAR", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("MIADO", 1.3)
		elseif marca == "GOLPE" then
			dispensarGato()
			local onde = frente(CFG.ALCANCE) + Vector3.new(0, CFG.ALTURA, 0)
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
-- EXTRA — a chuva
--
-- `attack2`: a origem solta **50 bolas** em volta do gato, uma a cada 0.1 s,
-- em `math.random(-35,15)` por `math.random(-35,35)`. Aqui são 12, espalhadas
-- por ÂNGULO ÁUREO em vez de sorteio — com todos os clientes desenhando, um
-- sorteio faria cada um ver uma chuva diferente.
--
-- Sem gato de pé, ela cai em volta de quem carrega: o `attack2` da origem é do
-- gato, mas a Tool nunca fica inerte.
--%s

function extra(mira)
	local centro = gatoOnde or mira or frente(CFG.ALCANCE)
	tocar("MIADO", 0.75)

	task.spawn(function()
		for i = 1, CFG.BOMBAS do
			local a = i * 2.399963
			local r = CFG.RAIO_CHUVA * math.sqrt(i / CFG.BOMBAS)
			local onde = centro + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			soltarBomba(onde, CFG.RAIO_BOMBA, CFG.DANO_BOMBA)
			task.wait(CFG.PASSO_CHUVA)
		end
	end)
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tdispensarGato()\n")


T("Samsungus",
  objeto="Samsungus_Server_V1", sufixo="RealitySamsungus",
  arquetipo="MELEE", alcance_mira=35,
  rotulo_primaria="combo de duas batidas", rotulo_extra="Concussao",
  origem=["`samsung`: Handle **MeshPart** id 430345282 — o celular",
          "sons MetalHit 6879335951 · Swoosh 9113749736 · Hit 743886825",
          "LOGICA: o `LeadpipeServer` e um melee de R2DA — `attacknumber`",
          "   alterna DUAS batidas, alcance 3, dano math.random(20,25),",
          "   PlatformStand mais BodyVelocity, e **concussao**: o alvo passa a",
          "   andar para pontos tortos em volta de si mesmo por 15 s"],
  cfg="""	ALCANCE        = 5,
	RAIO_GOLPE     = 6,
	DANO_MIN       = 20,
	DANO_MAX       = 25,
	EMPURRAO       = 40,
	RECARGA        = 0.65,

	RECARGA_EXTRA  = 12,
	RAIO_CHAMADA   = 14,
	DANO_CHAMADA   = 30,
	DURACAO_CONC   = 9,
	LENTIDAO       = 0.45,
	CAMBALEIO      = 15,
	PASSO_CAMBALEIO = 0.6,""",
  estado="local golpeNumero = 0",
  corpo='''
--%s
-- O COMBO DE DUAS — `attacknumber` da origem
--
-- O leadpipe alterna: a primeira batida vem de cima com o braço aberto, a
-- segunda vem de lado com o corpo torcido. Não é a mesma animação repetida, e
-- não é uma batida só — a versão anterior tinha uma.
--
-- O dano da origem é `math.random(20,25)`. Aqui é `naFaixa(20, 25)`, que é
-- determinístico: o mesmo intervalo, sem sorteio.
--%s

local function bater(dano, forca)
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, dano)
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			-- a origem empurra pelo `lookVector` de QUEM BATE, não radial
			empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.3, 0),
				forca, 0.22)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1 })
		end
		tombar(alvo, 0.7)
		achou = true
	end
	if achou then tocarEm("BATE", ponto, 1 + jitter(0.4) * 0.1) end
	return achou
end

--%s
-- PRIMÁRIA — a batida, alternando
--%s

function primaria(_mira)
	ocupado = true
	golpeNumero = 1 - golpeNumero
	local qual = "BATIDA"
	if golpeNumero == 1 then qual = "BATIDA_B" end

	rig:PlaySequence(qual, function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GIRO", 1 + jitter(0.2) * 0.2)
		elseif marca == "GOLPE" then
			bater(naFaixa(CFG.DANO_MIN, CFG.DANO_MAX), CFG.EMPURRAO)
		end
	end, function() ocupado = false end)
end

--%s
-- EXTRA — a concussão
--
-- O efeito de assinatura do leadpipe. Na origem, quem leva vira `owieConcussed`
-- e passa 15 s andando para pontos tortos em volta da própria cabeça — não é
-- lentidão, é perder o rumo.
--
-- O que não veio: a `ScreenGui` branca que a origem punha na tela de quem é
-- jogador. `ScreenGui` dentro de Tool é proibida, e mexer na `PlayerGui` de
-- outro jogador é justamente o tipo de referência fora da Tool que a regra nº 1
-- fecha. O cambaleio vale para todo mundo, jogador ou NPC — o que é MAIS do que
-- a origem fazia, que só cambaleava NPC.
--%s

local function atordoar(alvo, tempo)
	local corpo = alvo and alvo.Parent
	local cabeca = corpo and (corpo:FindFirstChild("Head")
		or corpo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return end

	afrouxar(alvo, CFG.LENTIDAO, tempo)

	task.spawn(function()
		local ate = os.clock() + tempo
		local passo = 0
		while os.clock() < ate do
			if not (alvo.Parent and alvo.Health > 0 and cabeca.Parent) then
				break
			end
			passo = passo + 1
			alvo:MoveTo(cabeca.Position
				+ Vector3.new(jitter(passo * 0.31) * CFG.CAMBALEIO, 0,
					jitter(passo * 0.77 + 1.1) * CFG.CAMBALEIO))
			task.wait(CFG.PASSO_CAMBALEIO)
		end
	end)
end

function extra(_mira)
	ocupado = true
	rig:PlaySequence("CHAMADA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("GIRO", 0.8)
		elseif marca == "SEGURA" then
			tocar("IMPACTO", 1.4)
		elseif marca == "GOLPE" then
			local centro = frente(CFG.ALCANCE)
			vfx("RELOGIO", { posicao = centro, escala = 1.4 })
			tocarEm("IMPACTO", centro, 0.9)
			for _, alvo in ipairs(alvosEm(centro, CFG.RAIO_CHAMADA, 10)) do
				aplicarDano(alvo, CFG.DANO_CHAMADA)
				tombar(alvo, 1.1)
				atordoar(alvo, CFG.DURACAO_CONC)
				local alvoRaiz = raizDe(alvo)
				if alvoRaiz then
					vfx("PARAR", { posicao = alvoRaiz.Position, escala = 1,
						duracao = CFG.DURACAO_CONC })
				end
			end
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar='\ttocar("GUARDA", 1)\n')


T("Danca Provocadora",
  objeto="DancaProvocadora_Server_V1", sufixo="RealityDanca",
  arquetipo="SUPORTE", alcance_mira=40,
  rotulo_primaria="danca com a musica, ate mandar parar",
  rotulo_extra="Parar",
  origem=["`kick dance`: RequiresHandle = false — ganha um Handle invisivel",
          "`KeyframeSequence` `california gurls`: **361 keyframes** em 12.00 s,",
          "   amostrada em 14 — a maior densidade que ja entrou no repositorio",
          "sem som proprio (o `music` veio vazio): empresta 2 do Canhao",
          "LOGICA: `Activated` toca a animacao e a musica. `Unequipped` para as",
          "   duas. **NAO HA MAIS NADA** — sem dano, sem raio, sem puxao."],
  cfg="""	RECARGA        = 3,
	RECARGA_EXTRA  = 1,""",
  estado="local dancando = false\nlocal musica = nil\nlocal geracao = 0",
  corpo='''
--%s
-- A DANÇA, E SÓ A DANÇA
--
-- O `SwordScript` do `kick dance` inteiro cabe em nove linhas: `Activated` dá
-- `animation:play()` e `music:Play()`, `Unequipped` dá `animation:stop()` e
-- `music:Stop()`. Não existe dano, não existe raio, não existe puxão — a versão
-- anterior tinha aura de 26 studs, 6 de dano por tique e arrasto para o centro,
-- e nada disso está na origem.
--
-- 14 quadros amostrados de uma `KeyframeSequence` de **361 keyframes** em
-- 12.00 s. É a maior densidade de animação que já entrou aqui.
--
-- Ela REPETE: na origem a animação roda até o `Unequipped`, e é por isso que a
-- rodada se re-agenda no `onDone` em vez de parar no fim do ciclo.
--
-- `ocupado` fica FALSO enquanto ela roda, de propósito: se ficasse verdadeiro,
-- o `podeAgir()` barraria a própria tecla de parar.
--%s

local function pararDanca()
	geracao = geracao + 1
	dancando = false
	if musica then
		musica:Stop()
		musica.Parent = nil
		musica = nil
	end
	if rig then rig:CancelSequence() end
end

local rodada
rodada = function(minha)
	if minha ~= geracao or not dancando or not rig then return end
	rig:PlaySequence("DANCA", function(passo)
		local marca = marcaDe(passo)
		if marca == "GOLPE" and raiz then
			tocarEm("BATIDA", raiz.Position, 1 + jitter(0.6) * 0.12)
		end
	end, function()
		if minha == geracao and dancando then
			rodada(minha)
		end
	end)
end

--%s
-- PRIMÁRIA — dançar
--%s

function primaria(_mira)
	pararDanca()
	geracao = geracao + 1
	local minha = geracao
	dancando = true

	musica = tocar("PROVOCA", 1, 600)
	if musica then musica.Looped = true end

	rodada(minha)
	ocupado = false
end

--%s
-- EXTRA — parar
--
-- É o `Unequipped` da origem, na tecla.
--%s

function extra(_mira)
	if not dancando then return end
	pararDanca()
	ocupado = false
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tpararDanca()\n")
