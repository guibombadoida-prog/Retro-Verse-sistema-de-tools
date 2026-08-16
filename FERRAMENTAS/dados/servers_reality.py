"""
servers_reality.py — as 7 habilidades do conjunto REALITY GUI.

Lido por `FERRAMENTAS/gerar_servers_reality.py`, que monta o Server e o Client
em volta destes corpos.

════════════════════════════════════════════════════════════════════════
UMA HABILIDADE POR TOOL, NO CLIQUE. SÓ ISSO.
════════════════════════════════════════════════════════════════════════

    Sem Extra, sem tecla, sem `AcaoRemote`, sem botão de celular. Cada Tool faz
    o que a Tool de origem dela faz, e nada além.

    A versão anterior inventou sete Extras — `Tripla`, `Marcar`, `Frear`,
    `Derrubar`, `Chuva`, `Concussao`, `Parar`. Nenhuma delas foi pedida, e o
    que a origem tinha já estava pronto.

════════════════════════════════════════════════════════════════════════
A LÓGICA É A DA ORIGEM, COM AS PARTES PERIGOSAS FORA
════════════════════════════════════════════════════════════════════════

    As seis Tools que este conjunto usa foram auditadas. **Veneno: zero.**
    O backdoor do `reality_tools.rbxmx` mora na `Pistol` e o `require(206209239)`
    mora no `TrenchGun` — nenhuma das duas entra aqui.

    O que existe de verdade nas seis são 13 referências FORA da Tool e a
    sintaxe proibida de sempre. É tudo substituição mecânica, e a lógica
    atravessa inteira:

    | Da origem | Vira | Quantos |
    |---|---|---|
    | `wait(` · `spawn(` | `task.wait` · `task.spawn` | 57 · 10 |
    | `math.random` em gameplay | `jitter` / `naFaixa` determinísticos | 36 |
    | `:Destroy()` · `:remove()` | `Parent = nil` / `Debris` | 11 · 3 |
    | `Health = 0` | `TakeDamage` pelo Núcleo | 8 |
    | `BreakJoints` | `PlatformStand` com prazo | 2 |
    | `Instance.new("Explosion")` | `detectarHumanoides` | 2 |
    | `ReplicatedStorage` · `ServerStorage` · `ReplicatedFirst` | asset dentro da Tool | 9 |
    | `ScreenGui` · `PlayerGui` | caem — proibido dentro de Tool | 4 |

    E a ANIMAÇÃO é a da origem, inteira: 40 e 361 keyframes sem amostragem, e
    os laços de `Weld.C0` do `samsung` e do LOIC lidos verbatim. Ver
    `gerar_poses_reality.py`.

════════════════════════════════════════════════════════════════════════
O QUE CADA UMA FAZ, E DE QUAL LINHA SAIU
════════════════════════════════════════════════════════════════════════

    `Lapada Seca`   `SLAP/Hand/Script` — `Touched` → `BodyVelocity` 900 em
                    `-blender.CFrame.lookVector`, `Sit = true`, ragdoll.
    `Canhao Satelite` `LowOrbitIonCannon/Script` — `Call`, espera, feixe, bola
                    de 150 studs, e a radiação que fica.
    `Trem`          `a-train/SwordScript` — `WalkSpeed = 125` e mata por contato
                    até o `Unequipped`.
    `Arvore Maligna` `tre/Script/tree/Death/Script` — caça o mais perto, e só
                    anda enquanto ninguém olha.
    `Gato Ajudante Boss` `gravitycatMAIN.` — `attack1` em laço: bola preta no
                    alvo, 0.8 s, explosão raio 7.
    `Samsungus`     `samsung/LeadpipeServer` — `attacknumber` alterna duas
                    batidas, 20–25 de dano, `PlatformStand`, concussão.
    `Danca Provocadora` `kick dance/SwordScript` — animação e música. Nada mais.
"""

CONJUNTO = {}


def T(alvo, **kw):
    kw.setdefault("cutscene", False)
    kw.setdefault("ao_equipar", "")
    kw.setdefault("ao_guardar", "")
    kw.setdefault("estado", "")
    CONJUNTO[alvo] = kw


REGUA = "═" * 62


T("Lapada Seca",
  objeto="LapadaSeca_Server_V1", sufixo="RealityLapada",
  arquetipo="MELEE", alcance_mira=30,
  rotulo_primaria="o tapa que arremessa (SLAP/Hand/Script)",
  origem=["`SLAP`: Handle 1.76 x 0.1 x 0.1 e a malha `Hand`",
          "sons Smack 511340819 · Boom 1489705211 · slaps 165969964",
          "`FlingAmount = 900` · `bv.P = 12500` · `wait(.05)` e o bv morre",
          "`Humanoid.Sit = true` · seis clones de RagdollSCript"],
  cfg="""	RAIO_MAO        = 5.5,
	DANO            = 34,
	EMPURRAO        = 130,
	ALTURA          = 0.55,
	TEMPO_VOO       = 0.05,
	TOMBO           = 2.2,
	JANELA          = 0.45,
	PASSO           = 0.07,
	INTERVALO_ALVO  = 0.5,
	RECARGA         = 0.7,""",
  estado="local geracao = 0",
  corpo='''
--%s
-- O ARREMESSO — linha por linha do `SLAP/Hand/Script`
--
--     bv.Velocity = blender.CFrame.lookVector * -FlingAmount
--
-- A direção é a do ALVO, invertida: quem leva o tapa sai voando **de costas
-- para onde estava olhando**, não para longe de quem bateu. Essa é a diferença
-- entre a lapada e um empurrão qualquer.
--
-- `bv.P = 12500` e `wait(.05)` antes de destruir: é um safanão curtíssimo e
-- muito forte, não um empurrão contínuo. `TEMPO_VOO = 0.05` guarda isso.
--
-- O `Humanoid.Sit = true` mais os seis `RagdollSCript` viram `PlatformStand`
-- com prazo — o `RagdollSCript` fazia `humanoid.Health = 0` e destruía todo
-- `Motor6D`, que é desmontar personagem sem volta.
--%s

local function arremessar(alvo)
	local alvoRaiz = raizDe(alvo)
	if not alvoRaiz then return false end
	aplicarDano(alvo, CFG.DANO)
	empurrar(alvo, -alvoRaiz.CFrame.LookVector + Vector3.new(0, CFG.ALTURA, 0),
		CFG.EMPURRAO, CFG.TEMPO_VOO)
	tombar(alvo, CFG.TOMBO)
	vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1.4 })
	tocarEm("TAPA", alvoRaiz.Position, 1 + jitter(0.3) * 0.1)
	return true
end

--- A MÃO FICA VIVA POR UMA JANELA.
---
--- Na origem não existe golpe: existe `script.Parent.Touched:connect(hit)`, com
--- a mão quente enquanto a Tool estiver equipada. Aqui ela acende na marca
--- `GOLPE` e apaga sozinha, o que dá o mesmo jogo sem deixar o portador matando
--- por encostar enquanto anda.
---
--- `Touched` sozinho não basta: o Handle tem 0.1 x 0.1 de seção e escapa toque
--- em quem passa rápido. A varredura por TIQUE cobre o buraco — 0.07 s, nunca
--- por quadro.
---
--- O `e = false` da origem é um debounce ÚNICO para o mundo inteiro: dois alvos
--- ao mesmo tempo e um dos dois não levava nada. Aqui o intervalo é POR ALVO.
local function janelaViva()
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
		arremessar(alvo)
	end

	local toque = guardar(Handle.Touched:Connect(function(parte)
		if minha ~= geracao then return end
		local corpo = parte and parte:FindFirstAncestorOfClass("Model")
		if not corpo or corpo == personagem then return end
		servir(corpo:FindFirstChildOfClass("Humanoid"))
	end))

	task.spawn(function()
		local ate = os.clock() + CFG.JANELA
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
-- A HABILIDADE — no clique
--%s

function primaria(_mira)
	ocupado = true
	rig:PlaySequence("TAPA", function(passo)
		local marca = marcaDe(passo)
		if marca == "CARGA" then
			tocar("SEQUENCIA", 1.2)
		elseif marca == "GOLPE" then
			tocar("ESTOURO", 1 + jitter(0.8) * 0.15)
			janelaViva()
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tapagarMao()\n")


T("Canhao Satelite",
  objeto="CanhaoSatelite_Server_V1", sufixo="RealityCanhao",
  arquetipo="EXPLOSIVO", alcance_mira=140, cutscene=True,
  rotulo_primaria="a chamada de orbita (LowOrbitIonCannon/Script)",
  origem=["`LowOrbitIonCannon`: Handle 0.8 x 2.3 x 0.4, **21 Sound**",
          "Call 88858815 · Big Explosion 814635481 · Electric Explosion 2674547670",
          "`Call:Play()` -> `wait(3)` -> anuncio -> `wait(1)` -> feixe",
          "`energyhit` bola de **150 studs** · tremor em quem esta a **600**",
          "29 esferas Neon + 100 Glass expandindo por **~12 s** depois do tiro",
          "a animacao de braco e cabeca saiu dos 6 lacos de Weld.C0 do Script"],
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
	DANO_RAD       = 9,""",
  estado="local radiacaoId = nil\nlocal geracao = 0",
  corpo='''
--%s
-- A CHAMADA DE ÓRBITA — com cutscene
--
-- A ANIMAÇÃO É A DA ORIGEM. Os seis laços de `Weld.C0` do Script do LOIC saem
-- em `Poses.lua` verbatim: braço e cabeça sobem, seguram 2.5 s, ajustam,
-- seguram 1.5 s, e descem. 6.05 s, que é o que o autor escreveu.
--
-- Isso fica ABAIXO da faixa de 7–9 s que a regra 5 pede para ultimate. É de
-- propósito: a animação da origem vale mais que o número da gramática, e o
-- pedido foi manter a essência.
--
-- A RADIAÇÃO É DA ORIGEM, E FALTAVA. Depois que a bola de 150 studs nasce, o
-- LOIC solta 29 esferas `Neon` e 100 `Glass` expandindo por ~12 s — não é
-- decoração, é o que faz o ponto ficar intransitável depois do tiro.
--
-- O que não veio: o `v:destroy()` que apagava toda peça num raio de 250 studs
-- em seis ondas, o `game.Chat:Chat` do anúncio, e o `shakerbreaker` que
-- escrevia `workspace.CurrentCamera.CFrame` num LocalScript clonado para
-- dentro do personagem alheio. O tremor da cutscene faz esse trabalho, e mora
-- dentro da Tool.
--%s

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
	local centro = mira or frente(CFG.ALCANCE)
	rig:LockCharacter(true)
	abrirCena(alvosEm(centro, CFG.RAIO_CENA, 14), "CAMERA")

	rig:PlaySequence("ORBITA", function(passo)
		local marca = marcaDe(passo)
		if not marca then return end

		if marca == "CAMERA" then
			-- `handle.Call:Play()` — a chamada, que é o que abre tudo
			tocar("CHAMADA", 0.8)
			beatCena("CAMERA")
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
''' % (REGUA, REGUA),
  ao_guardar="\tapagarRadiacao()\n\tfecharCena()\n")


T("Trem",
  objeto="Trem_Server_V1", sufixo="RealityTrem",
  arquetipo="MELEE", alcance_mira=40,
  rotulo_primaria="entra em corrida e atropela (a-train/SwordScript)",
  origem=["`a-train`: RequiresHandle = false, sem Handle — ganha um invisivel",
          "`KeyframeSequence` de **40 keyframes** em 0.59 s — INTEIRA, sem corte",
          "som blood 5507830073",
          "`humanoid.WalkSpeed = 125` no Activated · volta a 16 no Unequipped",
          "`Touched` -> Health = 0, ragdoll, clona o corpo e joga a 50,50,50"],
  cfg="""	RECARGA        = 22,
	VELOCIDADE     = 110,
	DURACAO        = 6,
	RAIO_ATROPELO  = 7,
	DANO           = 46,
	EMPURRAO       = 96,
	TOMBO          = 2,
	PASSO          = 0.1,
	RASTRO_A_CADA  = 4,""",
  estado=("local velocidadeAntes = nil\nlocal atropelados = {}\n"
          "local geracao = 0"),
  corpo='''
--%s
-- A CORRIDA — o que a origem realmente faz
--
--     humanoid.WalkSpeed = 125
--     humanoid.Parent.Animate.Enabled = false
--
-- Não há impulso, não há dash: o personagem passa a correr, e mata quem
-- encostar enquanto isso dura. `Unequipped` devolve `WalkSpeed = 16`.
--
-- A velocidade guardada aqui é a que o portador TINHA, nunca 16 fixo — ele
-- pode estar com velocidade própria de outra Tool, e devolver 16 seria roubar.
--
-- O `Animate.Enabled = false` da origem não veio: o `R6CFrameAnimator` já solda
-- `Weld` por cima das juntas enquanto a track roda, então o Animate não briga
-- por elas. E desligar o Animate deixaria o personagem duro se a Tool sumisse
-- no meio.
--
-- Cada alvo paga UMA vez por corrida. Na origem isso é automático porque o alvo
-- é destruído; aqui é a lista `atropelados`, que zera a cada uso.
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
-- A HABILIDADE — no clique
--
-- A animação é a `KeyframeSequence` `a-train` INTEIRA: 40 de 40 quadros, por
-- `PlayTrack`. A versão anterior entregou 10.
--%s

function primaria(_mira)
	ocupado = true
	tocar("APITO", 0.85)
	rig:PlayTrack("INVESTIDA", function(passo)
		local evento = passo and passo.event
		if evento == "GOLPE" then
			correr()
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tfrear()\n")


T("Arvore Maligna",
  objeto="ArvoreMaligna_Server_V1", sufixo="RealityArvore",
  arquetipo="ESPECTRAL", alcance_mira=50,
  rotulo_primaria="planta a arvore, e ela caca (tre/.../Death/Script)",
  origem=["`tre`: Handle 4 x 1 x 2 e o Model `tree` com 5 UnionOperation",
          "som Kill 4817657002",
          "`seen_dist = 200` · `canSee` = FOV (`vec:Dot(lookVector) > 0`) + raycast",
          "`if minply and not beingwatched` -> avanca `unit*-15`",
          "`if minmag < 10` -> Health = 0, BreakJoints, Kill:Play()"],
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
	ARRASTO_A_CADA = 4,""",
  estado=("local arvoreId = nil\nlocal arvoreOnde = nil\n"
          "local geracao = 0"),
  corpo='''
--%s
-- O ANJO CHORÃO
--
-- O `tre` não é uma aura. Ele é uma peça que persegue: acha o `Humanoid` mais
-- perto num raio de 200 studs, aponta para ele, e avança — **mas só enquanto
-- aquele alvo NÃO está olhando para ela**:
--
--     local isInFOV = (vec:Dot(vh.CFrame.lookVector) > 0)
--     if minply and not beingwatched then ... end
--
-- A menos de 10 studs, mata.
--
-- O que mudou para caber nas regras: o passo é de 0.35 s (a origem roda com
-- `wait(.000001)`, que é por quadro e replica picotado), o avanço é de 4.5
-- studs por passo em vez de 15, o alcance é 90 em vez de 200, e o abate é
-- `TakeDamage` pelo Núcleo em vez de `Health = 0` mais `BreakJoints`.
--
-- O raycast de linha de visão ficou de fora: o teste de FOV é o que dá a
-- leitura de "ela parou porque eu olhei", e um raycast por alvo por tique
-- pagaria caro por pouco. Quem se esconder atrás de uma parede e olhar na
-- direção dela ainda a congela.
--
-- E a `ScreenGui` `Popup` que a origem clonava para a `PlayerGui` da vítima não
-- veio: é proibida dentro de Tool, e mexer na GUI de outro jogador é a
-- referência fora da Tool que a regra nº 1 fecha.
--%s

local function derrubar()
	geracao = geracao + 1
	if arvoreId then
		vfx("APAGAR", { id = arvoreId })
		arvoreId = nil
	end
	arvoreOnde = nil
end

--- `vec:Dot(vh.CFrame.lookVector) > 0` — o teste da origem, igual. Meio giro
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
-- A HABILIDADE — no clique
--
-- O molde é o `Model` `tree` da origem, com as 5 `UnionOperation`. Na origem
-- ele morava em `ReplicatedStorage`; aqui mora em `Tool/Moldes/`, ancorado e
-- invisível. O clone é que aparece, e é ele que anda.
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
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tderrubar()\n")


T("Gato Ajudante Boss",
  objeto="GatoAjudanteBoss_Server_V1", sufixo="RealityGato",
  arquetipo="ESPECTRAL", alcance_mira=55,
  rotulo_primaria="invoca o gato, que bombardeia (gravitycatMAIN.)",
  origem=["`gravity cat not amused`: Handle 4 x 1 x 2 e o Model do gato",
          "som theme 1842053299",
          "sobe 12 studs (`t.CFrame.Y + 1` doze vezes) e toca o tema",
          "`attack1`: bola preta no alvo -> `wait(0.8)` -> Explosion raio 7",
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
	TOMBO          = 1.6,""",
  estado=("local gatoId = nil\nlocal gatoOnde = nil\n"
          "local geracao = 0"),
  corpo='''
--%s
-- A BOMBA — `attack1`, que é o que o gato faz o tempo todo
--
--     bobm.CFrame = torso.CFrame ; bobm.Shape = Ball
--     bobm.Color = Color3.new(0.192157, 0.192157, 0.192157)
--     wait(0.8)
--     e.BlastRadius = 7 ; e.BlastPressure = 2
--
-- A espera de 0.8 s é a mecânica: dá para sair de baixo. É o que separa o gato
-- de uma aura que cobra por estar perto.
--
-- `Instance.new("Explosion")` é proibido aqui — quem detecta é o Núcleo, por
-- `golpearArea`. O visual do estouro é do cliente, e o raio 7 é o mesmo.
--
-- `attack2` (50 bolas em volta) e `attack3` (teleporta e mata) ficaram de fora:
-- são o boss da origem em laço infinito, não uma habilidade de Tool. O
-- `attack1` é o que cabe num clique.
--%s

local function soltarBomba(onde)
	vfx("BOMBA", { posicao = onde, escala = 1,
		espera = CFG.ESPERA_BOMBA, raio = CFG.RAIO_BOMBA })
	tocarEm("MIADO", onde, 1.45)
	task.delay(CFG.ESPERA_BOMBA, function()
		vfx("LUA_FIM", { posicao = onde, escala = 1 })
		tocarEm("MIADO", onde, 0.5)
		golpearArea(onde, CFG.RAIO_BOMBA, CFG.RAIO_BOMBA * 0.5,
			CFG.DANO_BOMBA, CFG.DANO_BOMBA * 0.55, CFG.EMPURRAO, CFG.TOMBO)
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

--- O gato invocado. Ele não anda: fica no lugar e bombardeia o mais perto, que
--- é o `attack1` em laço da origem — `findTorso` acha a cabeça mais próxima.
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
				soltarBomba(presaRaiz.Position)
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
-- A HABILIDADE — no clique
--
-- O gato é INVOCAÇÃO, não NPC. O `Humanoid` e os seis `Motor6D` da origem não
-- atravessaram: o que está em `Tool/Moldes/` é o corpo dele como geometria, e
-- quem o invoca, faz bombardear e dispensa é esta Tool — com prazo, e solto no
-- `desmontar()`. Na origem ele morava em `ServerStorage`.
--
-- Mesmo desenho do `Xester Invocacao` e do `Faker Entity`. Invocar é habilidade
-- de Tool; manter sistema de NPC é que o CLAUDE.md põe fora.
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
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tdispensarGato()\n")


T("Samsungus",
  objeto="Samsungus_Server_V1", sufixo="RealitySamsungus",
  arquetipo="MELEE", alcance_mira=35,
  rotulo_primaria="combo de duas batidas (samsung/LeadpipeServer)",
  origem=["`samsung`: Handle **MeshPart** id 430345282 — o celular",
          "sons MetalHit 6879335951 · Swoosh 9113749736 · Hit 743886825",
          "`attacknumber` alterna DUAS batidas · `range = 3`",
          "`humanoiddd.Health - math.random(20,25)` · `PlatformStand = true`",
          "`velocity.Velocity = owner.HumanoidRootPart.CFrame.lookVector * 10`",
          "`owieConcussed`: o alvo anda para pontos tortos por 15 s",
          "as duas animacoes sairam dos 4 lacos de Weld.C0 do proprio script"],
  cfg="""	ALCANCE        = 5,
	RAIO_GOLPE     = 6,
	DANO_MIN       = 20,
	DANO_MAX       = 25,
	EMPURRAO       = 40,
	TOMBO          = 0.7,
	RECARGA        = 0.65,

	DURACAO_CONC   = 15,
	LENTIDAO       = 0.45,
	CAMBALEIO      = 15,
	PASSO_CAMBALEIO = 0.6,""",
  estado="local golpeNumero = 0",
  corpo='''
--%s
-- A CONCUSSÃO — `owieConcussed`, o efeito de assinatura do leadpipe
--
--     local therandom1 = math.random(-15,15)
--     humanoiddd.WalkToPoint = Vector3.new(headdd.Position.x + therandom1, 0, ...)
--
-- Quem leva passa 15 s andando para pontos tortos em volta da própria cabeça.
-- Não é lentidão: é perder o rumo. Os `math.random(-15,15)` viram `jitter`
-- determinístico com a mesma amplitude.
--
-- O que não veio: a `ScreenGui` branca que a origem punha na tela de quem é
-- jogador. `ScreenGui` dentro de Tool é proibida, e mexer na `PlayerGui` de
-- outro jogador é a referência fora da Tool que a regra nº 1 fecha. Em troca o
-- cambaleio vale para todo mundo — a origem só cambaleava NPC.
--
-- Também não veio o `owner.Humanoid.Name = "Immunity"`, que dava invencibilidade
-- ao portador enquanto ele batia: renomear o `Humanoid` para escapar de dano é
-- exatamente o tipo de coisa que o Núcleo existe para não precisar.
--%s

local function atordoar(alvo)
	local corpo = alvo and alvo.Parent
	local cabeca = corpo and (corpo:FindFirstChild("Head")
		or corpo:FindFirstChild("HumanoidRootPart"))
	if not cabeca then return end

	afrouxar(alvo, CFG.LENTIDAO, CFG.DURACAO_CONC)

	task.spawn(function()
		local ate = os.clock() + CFG.DURACAO_CONC
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

--%s
-- A BATIDA
--
-- `range = 3` na origem mede cabeça-até-handle. Aqui a consulta é espacial a
-- partir de um ponto à frente, e 6 é o que dá o mesmo alcance de fato.
--
-- O empurrão é pelo `lookVector` de QUEM BATE, não radial — é o que a origem
-- escreve, e é o que joga o alvo para longe de você em vez de para os lados.
--%s

local function bater()
	local ponto = frente(CFG.ALCANCE)
	local achou = false
	for _, alvo in ipairs(alvosEm(ponto, CFG.RAIO_GOLPE, 4)) do
		aplicarDano(alvo, naFaixa(CFG.DANO_MIN, CFG.DANO_MAX))
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			empurrar(alvo, raiz.CFrame.LookVector + Vector3.new(0, 0.3, 0),
				CFG.EMPURRAO, 0.22)
			vfx("IMPACTO", { posicao = alvoRaiz.Position, escala = 1 })
		end
		tombar(alvo, CFG.TOMBO)
		atordoar(alvo)
		achou = true
	end
	if achou then
		tocarEm("BATE", ponto, 1 + jitter(0.4) * 0.1)
		tocarEm("IMPACTO", ponto, 1 + jitter(0.9) * 0.1)
	end
	return achou
end

--%s
-- A HABILIDADE — no clique, alternando as duas batidas
--
-- `attacknumber` da origem: a A vem de lado com o corpo torcido, a B vem de
-- cima com o braço aberto. São duas animações diferentes, e as duas saíram do
-- próprio `LeadpipeServer`.
--%s

function primaria(_mira)
	ocupado = true
	golpeNumero = 1 - golpeNumero
	local qual = "BATIDA_A"
	if golpeNumero == 1 then qual = "BATIDA_B" end

	rig:PlaySequence(qual, function(passo)
		local marca = marcaDe(passo)
		if marca == "SOPRO" then
			-- `swooshsound2:Play()` e `swooshsound:Play()`, entre os dois laços
			tocar("GIRO", 1 + jitter(0.2) * 0.2)
		elseif marca == "GOLPE" then
			bater()
		end
	end, function() ocupado = false end)
end
''' % (REGUA, REGUA, REGUA, REGUA, REGUA, REGUA),
  ao_guardar='\ttocar("GUARDA", 1)\n')


T("Danca Provocadora",
  objeto="DancaProvocadora_Server_V1", sufixo="RealityDanca",
  arquetipo="SUPORTE", alcance_mira=40,
  rotulo_primaria="danca com a musica (kick dance/SwordScript)",
  origem=["`kick dance`: RequiresHandle = false — ganha um Handle invisivel",
          "`KeyframeSequence` `california gurls`: **361 keyframes** em 12.00 s —",
          "   INTEIRA, sem corte. A versao anterior entregou 14.",
          "sem som proprio (o `music` veio vazio): empresta 2 do Canhao",
          "o SwordScript inteiro cabe em nove linhas: play, music, stop"],
  cfg="""	RECARGA        = 3,""",
  estado="local dancando = false\nlocal musica = nil\nlocal geracao = 0",
  corpo='''
--%s
-- A DANÇA, E SÓ A DANÇA
--
-- O `SwordScript` do `kick dance` inteiro:
--
--     animation = animator.new(char, script.Parent["california gurls"])
--     animation:play() ; script.Parent.music:Play()
--     -- Unequipped: animation:stop() ; music:Stop()
--
-- Não existe dano, não existe raio, não existe puxão. A versão anterior tinha
-- aura de 26 studs, 6 de dano por tique e arrasto para o centro, e nada disso
-- está na origem.
--
-- **361 quadros de 361**, por `PlayTrack`. A versão anterior entregou 14.
-- `PlayTrack` roda no `Heartbeat` com tempo absoluto: os 12.00 s saem em
-- 12.00 s, sem a deriva que 361 tweens encadeados teriam.
--
-- Ela REPETE: na origem a animação roda até o `Unequipped`, e é por isso que a
-- rodada se re-agenda no `onDone`.
--
-- `ocupado` fica FALSO enquanto ela roda, de propósito: dançar não ocupa o
-- personagem, e um segundo clique reinicia — que é o que a origem faz.
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
	rig:PlayTrack("DANCA", function(passo)
		local evento = passo and passo.event
		if evento == "BATIDA" and raiz then
			tocarEm("BATIDA", raiz.Position, 1 + jitter(0.6) * 0.12)
		end
	end, function()
		if minha == geracao and dancando then
			rodada(minha)
		end
	end)
end

--%s
-- A HABILIDADE — no clique
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
''' % (REGUA, REGUA, REGUA, REGUA),
  ao_guardar="\tpararDanca()\n")
