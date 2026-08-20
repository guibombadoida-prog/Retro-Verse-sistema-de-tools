-- Poses.lua
-- ModuleScript "Poses" — Impacto Forte  (conjunto DRAMA)
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
-- JUNTA QUE LIDERA: **RightArm** (regra 6 da gramática).
--
--   SOCO           golpe pesado     1.60s · 5 passo(s), 2 segurado(s)
--   RACHA          golpe pesado     1.40s · 5 passo(s), 2 segurado(s)
--
-- O vocabulário é compartilhado entre as sete: GUARDA, SOCO_DIR, SOCO_ESQ,
-- GANCHO, LAMINA_ERGUE… As sete são a MESMA briga, com armas diferentes.
--
-- Gerado por FERRAMENTAS/gerar_poses_drama.py.

local P = {}


P.CHUTE_CARGA = {
	RightArm = CFrame.new(1.5, 0.3, -0.4) * CFrame.Angles(math.rad(62), math.rad(-14), math.rad(-12)),
	LeftArm = CFrame.new(-1.5, 0.3, -0.4) * CFrame.Angles(math.rad(62), math.rad(14), math.rad(12)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-6), math.rad(24), 0),
	HRP = CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(-4), math.rad(-40), 0),
	RightLeg = CFrame.new(0.5, -1.7, -0.5) * CFrame.Angles(math.rad(-34), math.rad(0), 0),
}

P.EMPURRA_SOLTA = {
	RightArm = CFrame.new(1.5, 0.36, -1.2) * CFrame.Angles(math.rad(90), math.rad(-4), math.rad(-2)),
	LeftArm = CFrame.new(-1.5, 0.36, -1.2) * CFrame.Angles(math.rad(90), math.rad(4), math.rad(2)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(4), math.rad(0), 0),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(10), math.rad(0), 0),
	RightLeg = CFrame.new(0.5, -1.88, -0.3) * CFrame.Angles(math.rad(-14), math.rad(0), 0),
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

P.SOCO_DIR = {
	RightArm = CFrame.new(1.5, 0.4, -1.16) * CFrame.Angles(math.rad(92), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.28, 0.5, -0.6) * CFrame.Angles(math.rad(104), math.rad(18), math.rad(30)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-2), math.rad(-14), 0),
	HRP = CFrame.new(0, -0.02, 0) * CFrame.Angles(math.rad(3), math.rad(26), 0),
	RightLeg = CFrame.new(0.5, -1.9, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), 0),
}

P.SEQUENCIAS = {

	-- golpe pesado · 1.60s · 5 passo(s), 2 segurado(s)
	SOCO = {
		{ pose = "GUARDA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "GUARDA", time = 0.62, style = "Sine", dir = "InOut", tremor = 0.04, freq = 24, marca = "SEGURA" },
		{ pose = "SOCO_DIR", time = 0.08, style = "Quint", dir = "Out", marca = "BATE" },
		{ pose = "SOCO_DIR", time = 0.26, style = "Sine", dir = "InOut", marca = "VENTO" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.40s · 5 passo(s), 2 segurado(s)
	RACHA = {
		{ pose = "CHUTE_CARGA", time = 0.26, style = "Back", dir = "In", marca = "ERGUE" },
		{ pose = "CHUTE_CARGA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.045, freq = 24, marca = "SEGURA" },
		{ pose = "EMPURRA_SOLTA", time = 0.14, style = "Quint", dir = "Out", marca = "RACHA" },
		{ pose = "EMPURRA_SOLTA", time = 0.2, style = "Sine", dir = "InOut" },
		{ pose = "IDLE", time = 0.26, style = "Quad", dir = "Out" },
	},

}

return P
