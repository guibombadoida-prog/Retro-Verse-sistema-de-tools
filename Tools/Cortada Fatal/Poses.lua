-- Poses.lua
-- ModuleScript "Poses" — Cortada Fatal  (conjunto DRAMA)
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- ReleaseLegs ao fim de toda sequência. Perna soldada permanentemente trava
-- a caminhada.
--
-- JUNTA QUE LIDERA: **HRP** (regra 6 da gramática).
--
--   CORTADA        golpe pesado     1.30s · 5 passo(s), 2 segurado(s)
--   FATAL          ultimate         6.15s · 9 passo(s), 4 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.CORTADA_ALTA = {
	RightArm = CFrame.new(1.3, 0.86, 0.12) * CFrame.Angles(math.rad(168), math.rad(10), math.rad(14)),
	LeftArm = CFrame.new(-1.3, 0.86, 0.12) * CFrame.Angles(math.rad(168), math.rad(-10), math.rad(-14)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), 0),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-18), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.86, 0.24) * CFrame.Angles(math.rad(12), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.86, 0.24) * CFrame.Angles(math.rad(12), math.rad(0), 0),
}

P.CORTADA_BAIXA = {
	RightArm = CFrame.new(1.44, -0.34, -0.86) * CFrame.Angles(math.rad(34), math.rad(-8), math.rad(-10)),
	LeftArm = CFrame.new(-1.44, -0.34, -0.86) * CFrame.Angles(math.rad(34), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(24), math.rad(0), 0),
	HRP = CFrame.new(0, -0.42, 0) * CFrame.Angles(math.rad(26), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.6, -0.62) * CFrame.Angles(math.rad(-40), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.3) * CFrame.Angles(math.rad(18), math.rad(0), 0),
}

P.ESTOCADA = {
	RightArm = CFrame.new(1.5, 0.42, -1.3) * CFrame.Angles(math.rad(96), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.5, 0.1, -0.3) * CFrame.Angles(math.rad(30), math.rad(8), math.rad(10)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-6), 0),
	HRP = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.rad(16), math.rad(12), 0),
	RightLeg = CFrame.new(0.5, -1.82, -0.44) * CFrame.Angles(math.rad(-22), math.rad(0), 0),
	LeftLeg = CFrame.new(-0.5, -1.9, 0.28) * CFrame.Angles(math.rad(16), math.rad(0), 0),
}

P.GUARDA = {
	RightArm = CFrame.new(1.34, 0.46, -0.66) * CFrame.Angles(math.rad(96), math.rad(-12), math.rad(-24)),
	LeftArm = CFrame.new(-1.3, 0.52, -0.7) * CFrame.Angles(math.rad(102), math.rad(14), math.rad(26)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(10), 0),
	HRP = CFrame.new(0, 0.02, 0) * CFrame.Angles(math.rad(-3), math.rad(-18), 0),
}

P.IDLE = {
	RightArm = CFrame.new(1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(5), math.rad(5)),
	LeftArm = CFrame.new(-1.46, 0.06, -0.3) * CFrame.Angles(math.rad(26), math.rad(-5), math.rad(-5)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(4), 0),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-8), 0),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.30s · 5 passo(s), 2 segurado(s)
	CORTADA = {
		{ pose = "CORTADA_ALTA", time = 0.28, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "CORTADA_ALTA", time = 0.52, style = "Sine", dir = "InOut", tremor = 0.035, freq = 22, marca = "SEGURA" },
		{ pose = "CORTADA_BAIXA", time = 0.1, style = "Quint", dir = "Out", marca = "DESCE" },
		{ pose = "CORTADA_BAIXA", time = 0.16, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.24, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- ultimate · 6.15s · 9 passo(s), 4 segurado(s)
	FATAL = {
		{ pose = "GUARDA", time = 0.4, style = "Back", dir = "In", tremor = 0.02, freq = 15, marca = "CAMERA" },
		{ pose = "CORTADA_ALTA", time = 0.7, style = "Quad", dir = "InOut", tremor = 0.03, freq = 19, marca = "ERGUE" },
		{ pose = "CORTADA_ALTA", time = 0.95, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "CARGA" },
		{ pose = "CORTADA_ALTA", time = 1.0, style = "Sine", dir = "InOut", tremor = 0.06, freq = 29 },
		{ pose = "ESTOCADA", time = 0.35, style = "Quint", dir = "In", marca = "AVANCA" },
		{ pose = "ESTOCADA", time = 0.85, style = "Sine", dir = "InOut", tremor = 0.075, freq = 34, marca = "SEGURA" },
		{ pose = "CORTADA_BAIXA", time = 0.14, style = "Quint", dir = "Out", marca = "EXECUTA" },
		{ pose = "CORTADA_BAIXA", time = 0.66, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 1.1, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
