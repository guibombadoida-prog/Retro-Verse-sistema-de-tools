-- Poses_Tempo_V1.lua
-- ModuleScript "Poses" — Paradoxo  (conjunto TEMPO)
--
-- FORMATO V2 — juntas que o R6CFrameAnimator solda, e só elas:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing` (V1).
--
-- PERNA: quem solda perna é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada — nenhuma pose daqui deve ser aplicada fora de sequência.
--
-- ESTA TOOL LIDERA POR `RightArm`.
--
-- DE ONDE VIERAM AS SILHUETAS (§12.12)
--
--   O `Celestial Staff` da origem trazia SEIS `Animation` — `Summon`,
--   `RightSlash` e `Wave`, em R6 e R15 — e oito `LoadAnimation`. `Animation`
--   é proibida: é asset de fora, some se o id sair do ar, e briga com o
--   `Animate` padrão. E não há CFrame a extrair de um id.
--
--   O que veio foi a CADÊNCIA que os nomes declaram: `Summon` lento e
--   vertical, `RightSlash` curto e diagonal, `Wave` sustentado.
--
-- A GRAMÁTICA: O TEMPO É O QUE PARA E O QUE CORRE
--
--   Os moldes são separados pela DURAÇÃO antes de qualquer outra coisa. O
--   `estalo` tem 0.60 s e é o mais curto do repositório inteiro — parar o
--   tempo tem de ser mais rápido do que qualquer coisa que se possa fazer
--   para impedir.
--
-- Gerado por FERRAMENTAS/gerar_poses_tempo.py. Editar aqui à mão faz as sete
-- derivarem; edite o gerador.

local P = {}

P.ESTALA_ARMA = {
	RightArm = CFrame.new(1.34, 0.42, -0.28) * CFrame.Angles(math.rad(78), math.rad(-22), math.rad(-34)),
	LeftArm = CFrame.new(-1.48, 0.06, -0.1) * CFrame.Angles(math.rad(12), math.rad(4), math.rad(-6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(-12), math.rad(0)),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-2), math.rad(-10), math.rad(0)),
}

P.ESTALA_SOLTA = {
	RightArm = CFrame.new(1.54, 0.2, -1.06) * CFrame.Angles(math.rad(86), math.rad(6), math.rad(-12)),
	LeftArm = CFrame.new(-1.47, 0.0, 0.06) * CFrame.Angles(math.rad(4), math.rad(-4), math.rad(8)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(10), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(14), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.06, -0.16) * CFrame.Angles(math.rad(16), math.rad(4), math.rad(5)),
	LeftArm = CFrame.new(-1.49, 0.02, -0.06) * CFrame.Angles(math.rad(8), math.rad(-2), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-4), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.ERGUE_MAO = {
	RightArm = CFrame.new(1.5, 0.62, -0.24) * CFrame.Angles(math.rad(128), math.rad(-10), math.rad(-14)),
	LeftArm = CFrame.new(-1.5, 0.62, -0.24) * CFrame.Angles(math.rad(128), math.rad(10), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.06, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

P.SEGURA_ALTO = {
	RightArm = CFrame.new(1.44, 0.92, -0.04) * CFrame.Angles(math.rad(174), math.rad(-10), math.rad(-18)),
	LeftArm = CFrame.new(-1.44, 0.92, -0.04) * CFrame.Angles(math.rad(174), math.rad(10), math.rad(18)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-34), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.92, 0.08) * CFrame.Angles(math.rad(5), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.92, 0.08) * CFrame.Angles(math.rad(5), math.rad(0), math.rad(0)),
}

P.ABRE_CAMPO = {
	RightArm = CFrame.new(1.6, 0.26, -0.42) * CFrame.Angles(math.rad(58), math.rad(0), math.rad(-58)),
	LeftArm = CFrame.new(-1.6, 0.26, -0.42) * CFrame.Angles(math.rad(58), math.rad(0), math.rad(58)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
}

P.VARRE_ARMA = {
	RightArm = CFrame.new(1.4, 0.28, -0.5) * CFrame.Angles(math.rad(82), math.rad(-52), math.rad(-18)),
	LeftArm = CFrame.new(-1.44, 0.1, -0.2) * CFrame.Angles(math.rad(20), math.rad(14), math.rad(-12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(-44), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-48), math.rad(0)),
}

P.VARRE_PASSA = {
	RightArm = CFrame.new(1.52, 0.24, -0.86) * CFrame.Angles(math.rad(84), math.rad(48), math.rad(-14)),
	LeftArm = CFrame.new(-1.4, 0.02, 0.2) * CFrame.Angles(math.rad(-8), math.rad(-14), math.rad(14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(2), math.rad(44), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(0), math.rad(52), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- estalo — 0.60 s
	ECO_P = {
		{ pose = "ESTALA_ARMA", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESTALA_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.42, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- sustentada — 1.50 s
	DUPLO = {
		{ pose = "ERGUE_MAO", time = 0.24, style = "Back", dir = "Out", marca = "CARGA" },
		{ pose = "SEGURA_ALTO", time = 0.42, style = "Sine", dir = "InOut", tremor = 0.028, freq = 24, marca = "SEGURA" },
		{ pose = "ABRE_CAMPO", time = 0.36, style = "Sine", dir = "InOut", tremor = 0.028, freq = 28 },
		{ pose = "ABRE_CAMPO", time = 0.14, style = "Quint", dir = "Out", marca = "SOLTA" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- varredura — 0.90 s
	COLAPSO = {
		{ pose = "VARRE_ARMA", time = 0.18, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "VARRE_PASSA", time = 0.12, style = "Quint", dir = "Out", marca = "VARRE" },
		{ pose = "VARRE_PASSA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.4, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
