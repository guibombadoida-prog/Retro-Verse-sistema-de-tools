-- Poses_Tempo_V1.lua
-- ModuleScript "Poses" — Reversao  (conjunto TEMPO)
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
-- ESTA TOOL LIDERA POR `HRP`.
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

P.VOLTA_INCLINA = {
	RightArm = CFrame.new(1.46, 0.16, 0.62) * CFrame.Angles(math.rad(-46), math.rad(-12), math.rad(16)),
	LeftArm = CFrame.new(-1.46, 0.16, 0.62) * CFrame.Angles(math.rad(-46), math.rad(12), math.rad(-16)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-24), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.86, 0.38) * CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.52, -1.8, -0.34) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
}

P.VOLTA_PUXA = {
	RightArm = CFrame.new(1.3, 0.3, -0.24) * CFrame.Angles(math.rad(92), math.rad(-34), math.rad(-40)),
	LeftArm = CFrame.new(-1.3, 0.3, -0.24) * CFrame.Angles(math.rad(92), math.rad(34), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

--═══════════════════════════════════════════════════════════════
-- SEQUÊNCIAS
--═══════════════════════════════════════════════════════════════

P.SEQUENCIAS = {

	-- estalo — 0.60 s
	MARCAR = {
		{ pose = "ESTALA_ARMA", time = 0.1, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ESTALA_SOLTA", time = 0.08, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.42, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- reversão — 1.10 s
	REVERTER = {
		{ pose = "VOLTA_INCLINA", time = 0.3, style = "Quint", dir = "Out", marca = "CARGA" },
		{ pose = "VOLTA_INCLINA", time = 0.24, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "VOLTA_PUXA", time = 0.14, style = "Back", dir = "In", marca = "VOLTA" },
		{ pose = "IDLE", time = 0.42, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- reversão — 1.10 s
	REVERTER_EU = {
		{ pose = "VOLTA_INCLINA", time = 0.3, style = "Quint", dir = "Out", marca = "CARGA" },
		{ pose = "VOLTA_INCLINA", time = 0.24, style = "Sine", dir = "InOut", tremor = 0.045, freq = 26 },
		{ pose = "VOLTA_PUXA", time = 0.14, style = "Back", dir = "In", marca = "VOLTA" },
		{ pose = "IDLE", time = 0.42, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
