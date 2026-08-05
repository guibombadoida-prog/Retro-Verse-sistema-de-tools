--[[
	Poses_Escudos_EscudoPartido_V1  —  ModuleScript "Poses", filho direto da Tool
	Retro-Verse / Studios  ·  §10.11 — pose, ritmo e dramaturgia são AUTORAIS

	Formato do R6CFrameAnimator V2 canônico do projeto.

	═══════════════════════════════════════════════════════════════════════
	V2 — ANIMAÇÃO PRÓPRIA, COM O PACK COMO REFERÊNCIA

	A V1 tinha 6 poses chutadas a olho, e ficava dura. Esta versão foi autorada
	a partir do que o pack ENSINA, não do que ele contém:

	  O QUE FOI LIDO      `CONSECUTIVE_PUNCHES` (111 quadros, 1,833 s) e
	                      `SERIOUS_PUNCH`, de Saitama_Animacoes_Referencia.
	  O QUE FOI EXTRAÍDO  a CADÊNCIA. Medindo a velocidade angular do braço
	                      direito quadro a quadro, os picos de impacto caem em
	                      t = 0,167 · 0,550 · 0,767 · 0,983 · 1,200 · 1,417.
	                      Ou seja: primeiro golpe em 0,167 s, uma respirada de
	                      0,38 s, e depois um golpe a cada ~0,217 s.
	  O QUE NÃO FOI COPIADO  nenhum CFrame. As silhuetas abaixo são novas e são
	                      de ESCUDO-LÂMINA, não de punho: o braço corta em
	                      diagonal com a borda, o outro contrabalança, e o
	                      tronco gira CONTRA o corte. Punho fecha para dentro;
	                      lâmina abre para fora. São gestos opostos, e copiar
	                      pose de soco num corte é o que deixava isto duro.

	Por que a cadência importa mais que a pose: o que faz uma série de cortes
	ler como série é o INTERVALO entre eles ser constante e curto o bastante
	para o olho ligar um no outro. 0,217 s faz isso. 0,4 s vira seis golpes
	separados.
	═══════════════════════════════════════════════════════════════════════

	Cada pose é o C0 de um Weld que o animator cria:

		RightArm   Torso → Right Arm          base CFrame.new( 1.5,  0,   0)
		LeftArm    Torso → Left Arm           base CFrame.new(-1.5,  0,   0)
		Head       Torso → Head               base CFrame.new( 0,    1.5, 0)
		HRP        HumanoidRootPart → Torso   base CFrame.new()
		RightLeg   Torso → Right Leg          base CFrame.new( 0.5, -2,   0)   sob demanda
		LeftLeg    Torso → Left Leg           base CFrame.new(-0.5, -2,   0)   sob demanda

	⚠️ NÃO escreva em Motor6D. O script `Animate` padrão do Roblox escreve nessas
	mesmas juntas todo frame — os dois brigam e a animação treme.

	PERNA É SOB DEMANDA e é solta no fim (ReleaseLegs). Perna soldada
	permanentemente TRAVA A CAMINHADA.

	Ver DIRETRIZES/REGRA_ANIMACAO_R6.md.
--]]

local Poses = {}

local function graus(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local BASE_BRACO_D = CFrame.new(1.5, 0, 0)
local BASE_BRACO_E = CFrame.new(-1.5, 0, 0)
local BASE_CABECA  = CFrame.new(0, 1.5, 0)
local BASE_TRONCO  = CFrame.new()
local BASE_PERNA_D = CFrame.new(0.5, -2, 0)
local BASE_PERNA_E = CFrame.new(-0.5, -2, 0)

--==============================================================================
-- POSES
--==============================================================================

Poses.POSES = {
	-- Repouso: lâmina baixa e de lado, ponta para trás. Postura de esgrima,
	-- não de escudo — o corpo já está de perfil, pronto para girar.
	REPOUSO = {
		RightArm = BASE_BRACO_D * graus(-22, 0, -26),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, 12),
		Head     = BASE_CABECA * graus(0, -10, 0),
		HRP      = BASE_TRONCO * graus(0, 14, 0),
	},

	-- ── PRIMÁRIA: o corte que lança a lâmina ──────────────────────────────
	-- 1. Recolher: o braço cruza o peito e o tronco carrega CONTRA o corte.
	--    É a torção do tronco que arma o golpe, não a dobra do cotovelo.
	CORTE_1 = {
		RightArm = BASE_BRACO_D * graus(-38, 0, 104),
		LeftArm  = BASE_BRACO_E * graus(-26, 0, -40),
		Head     = BASE_CABECA * graus(-4, -34, 0),
		HRP      = BASE_TRONCO * graus(0, 42, -6),
	},
	-- 2. Cortar: sai em diagonal alta→baixa. QUADRO DE IMPACTO — a lâmina
	--    nasce aqui e o dano entra aqui, não no fim da sequência.
	CORTE_2 = {
		RightArm = BASE_BRACO_D * graus(-112, 0, -66),
		LeftArm  = BASE_BRACO_E * graus(-14, 0, 26),
		Head     = BASE_CABECA * graus(6, 34, 0),
		HRP      = BASE_TRONCO * graus(4, -48, 8),
	},
	-- 3. Sobrar: o braço passa do ponto e o corpo acompanha meio passo.
	--    Sem retorno — o escudo partiu e não volta.
	CORTE_3 = {
		RightArm = BASE_BRACO_D * graus(-70, 0, -34),
		LeftArm  = BASE_BRACO_E * graus(-10, 0, 14),
		Head     = BASE_CABECA * graus(2, 18, 0),
		HRP      = BASE_TRONCO * graus(2, -22, 3),
	},

	-- ── EXTRA: a sentença ─────────────────────────────────────────────────
	-- Aponta: a lâmina sobe à altura do rosto e trava no alvo. O corpo recua
	-- meio passo — quem vai executar não avança, espera.
	SENTENCA_APONTA = {
		RightArm = BASE_BRACO_D * graus(-104, 0, 22),
		LeftArm  = BASE_BRACO_E * graus(-28, 0, -18),
		Head     = BASE_CABECA * graus(-10, 16, 0),
		HRP      = BASE_TRONCO * graus(-4, -14, 0),
		RightLeg = BASE_PERNA_D * graus(-10, 0, 3),
		LeftLeg  = BASE_PERNA_E * graus(8, 0, -3),
	},
	-- Firme: corpo travado no centro. O Server chama LockCharacter aqui — a
	-- cutscene precisa do corpo parado para os cortes girarem em volta.
	SENTENCA_FIRME = {
		RightArm = BASE_BRACO_D * graus(-92, 0, 10),
		LeftArm  = BASE_BRACO_E * graus(-22, 0, -10),
		Head     = BASE_CABECA * graus(-2, 0, 0),
		HRP      = BASE_TRONCO * graus(-6, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-8, 0, 2),
		LeftLeg  = BASE_PERNA_E * graus(6, 0, -2),
	},

	-- Os seis cortes. Alternam LADO e ALTURA — é a alternância que faz seis
	-- golpes lerem como uma série, e não como o mesmo golpe repetido.
	-- alto, da direita
	SENTENCA_A = {
		RightArm = BASE_BRACO_D * graus(-148, 0, 40),
		LeftArm  = BASE_BRACO_E * graus(-30, 0, -22),
		HRP      = BASE_TRONCO * graus(-8, 26, -10),
	},
	-- baixo, da esquerda
	SENTENCA_B = {
		RightArm = BASE_BRACO_D * graus(-46, 0, -78),
		LeftArm  = BASE_BRACO_E * graus(-18, 0, 34),
		HRP      = BASE_TRONCO * graus(10, -30, 12),
	},
	-- horizontal, cruzando
	SENTENCA_C = {
		RightArm = BASE_BRACO_D * graus(-88, 0, 96),
		LeftArm  = BASE_BRACO_E * graus(-24, 0, -48),
		HRP      = BASE_TRONCO * graus(0, 38, 0),
	},
	-- horizontal, de volta
	SENTENCA_D = {
		RightArm = BASE_BRACO_D * graus(-84, 0, -92),
		LeftArm  = BASE_BRACO_E * graus(-20, 0, 44),
		HRP      = BASE_TRONCO * graus(0, -36, 0),
	},
	-- alto, da esquerda
	SENTENCA_E = {
		RightArm = BASE_BRACO_D * graus(-156, 0, -34),
		LeftArm  = BASE_BRACO_E * graus(-34, 0, 26),
		HRP      = BASE_TRONCO * graus(-10, -24, 10),
	},
	-- estocada frontal, o corpo inteiro entra
	SENTENCA_F = {
		RightArm = BASE_BRACO_D * graus(-96, 0, 4),
		LeftArm  = BASE_BRACO_E * graus(-40, 0, -8),
		Head     = BASE_CABECA * graus(-8, 0, 0),
		HRP      = BASE_TRONCO * graus(-14, 0, 0),
	},

	-- O golpe mortal: a lâmina sobe inteira e desce em cima. É o único quadro
	-- da Tool em base larga — o corpo todo entra nos 299.
	SENTENCA_MORTAL_ALTO = {
		RightArm = BASE_BRACO_D * graus(-178, 0, 12),
		LeftArm  = BASE_BRACO_E * graus(-170, 0, -12),
		Head     = BASE_CABECA * graus(-30, 0, 0),
		HRP      = BASE_TRONCO * graus(-20, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-6, 0, 6),
		LeftLeg  = BASE_PERNA_E * graus(4, 0, -6),
	},
	SENTENCA_MORTAL_BAIXO = {
		RightArm = BASE_BRACO_D * graus(-16, 0, 6),
		LeftArm  = BASE_BRACO_E * graus(-12, 0, -6),
		Head     = BASE_CABECA * graus(30, 0, 0),
		HRP      = BASE_TRONCO * graus(34, 0, 0),
		RightLeg = BASE_PERNA_D * graus(-30, 0, 10),
		LeftLeg  = BASE_PERNA_E * graus(16, 0, -10),
	},
}

--==============================================================================
-- SEQUÊNCIAS — timeline do V2: o animator encadeia por Tween.Completed.
--
-- `time` é a duração do beat; `style`/`dir` são o easing. Encadear com
-- task.wait(duracao) some ~1 frame por beat e é proibido pela
-- DIRETRIZES/REGRA_ANIMACAO_R6.md — quem encadeia é o animator.
--
-- Back/In na carga, Quint/Out no golpe: é o easing que dá o peso. Carga em
-- Quad lê como o braço subindo devagar; em Back/In ela RECUA antes de ir, e é
-- esse recuo que o olho lê como força sendo acumulada.
--==============================================================================

Poses.SEQUENCIAS = {
	REPOUSO = {
		{ pose = "REPOUSO", time = 0.22, style = "Quad", dir = "Out" },
	},

	-- Primeiro impacto em 0,17 s, como no pack: 0,10 de carga + 0,07 de corte.
	CORTE = {
		{ pose = "CORTE_1", time = 0.10, style = "Back",  dir = "In"    },
		{ pose = "CORTE_2", time = 0.07, style = "Quint", dir = "Out"   },
		{ pose = "CORTE_3", time = 0.13, style = "Quad",  dir = "Out"   },
		{ pose = "REPOUSO", time = 0.20, style = "Quad",  dir = "InOut" },
	},

	-- Abertura: aponta, respira, trava. A respirada de 0,38 s é a mesma do
	-- pack entre o primeiro golpe e o início da série.
	SENTENCA = {
		{ pose = "SENTENCA_APONTA", time = 0.22, style = "Back", dir = "Out",   tremor = 0.02 },
		{ pose = "SENTENCA_FIRME",  time = 0.38, style = "Sine", dir = "InOut", tremor = 0.03, freq = 18 },
	},

	-- A série. 0,217 s por corte, medido no pack: 0,07 de carga + 0,147 de
	-- snap. É o snap que faz o corte existir.
	SENTENCA_CORTES = {
		{ pose = "SENTENCA_A", time = 0.07,  style = "Back",  dir = "In"  },
		{ pose = "SENTENCA_B", time = 0.147, style = "Quint", dir = "Out" },
		{ pose = "SENTENCA_C", time = 0.07,  style = "Back",  dir = "In"  },
		{ pose = "SENTENCA_D", time = 0.147, style = "Quint", dir = "Out" },
		{ pose = "SENTENCA_E", time = 0.07,  style = "Back",  dir = "In"  },
		{ pose = "SENTENCA_F", time = 0.147, style = "Quint", dir = "Out" },
	},

	-- O mortal: sobe segurando (Back/In prende o alto por um instante) e desce
	-- em Quint/Out. O contraste entre 0,30 e 0,09 é o golpe.
	SENTENCA_MORTAL = {
		{ pose = "SENTENCA_MORTAL_ALTO",  time = 0.30, style = "Back",  dir = "In",  tremor = 0.06, freq = 24 },
		{ pose = "SENTENCA_MORTAL_BAIXO", time = 0.09, style = "Quint", dir = "Out", tremor = 0.09, freq = 30 },
		{ pose = "REPOUSO",               time = 0.36, style = "Quad",  dir = "Out" },
	},
}

--==============================================================================
-- ACESSORES — devolvem o NOME da sequência, que é o que PlaySequence recebe
--==============================================================================

function Poses.repouso()
	return "REPOUSO"
end

function Poses.primaria()
	return "CORTE"
end

function Poses.extra()
	return "SENTENCA"
end

-- A série e o mortal são sequências próprias: o Server as dispara nos beats
-- certos da cutscene, não empilhadas em cima da abertura.
function Poses.cortes()
	return "SENTENCA_CORTES"
end

function Poses.mortal()
	return "SENTENCA_MORTAL"
end

return Poses
