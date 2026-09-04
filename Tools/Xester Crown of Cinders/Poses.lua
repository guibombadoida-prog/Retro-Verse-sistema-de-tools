-- Poses.lua
-- ModuleScript "Poses" — Xester Crown of Cinders  (Xester, Forma 2)
--
-- FORMA 2, o DRAGÃO — o corpo entra inteiro, o HRP lidera o que é peso,
-- e as pausas são mais longas.
--
-- FORMATO V2 — só as juntas que o R6CFrameAnimator solda:
--   RightArm (1.5,0,0) · LeftArm (-1.5,0,0) · Head (0,1.5,0) · HRP () ·
--   RightLeg (0.5,-2,0) · LeftLeg (-0.5,-2,0)
--
-- Sequência usa `time` / `style` / `dir` (V2), nunca `duracao` / `easing`.
--
-- PERNA: quem solda é o animator, sob demanda, e é ele quem chama
-- `ReleaseLegs` ao fim de toda sequência. Perna soldada trava a caminhada.
--
-- ESTA TOOL TOCA 2 SEQUÊNCIA(S), e só elas estão aqui. O vocabulário
-- completo do Xester é maior; mandar tudo em todas as treze seria asset
-- depositado e mudo em doze delas.
--

-- AS SEQUÊNCIAS
--
--   COROA_BRASAS     conjuração  1.11s · CARGA GOLPE FIM
--   BRASAS_CAEM      golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.COROA = {
	RightArm = CFrame.new(1.34, 0.86, -0.16) * CFrame.Angles(math.rad(164), math.rad(-22), math.rad(-34)),
	LeftArm = CFrame.new(-1.34, 0.86, -0.16) * CFrame.Angles(math.rad(164), math.rad(22), math.rad(34)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-38), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
}

P.EMPURRA = {
	RightArm = CFrame.new(1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(-8), math.rad(-4)),
	LeftArm = CFrame.new(-1.52, 0.22, -1.22) * CFrame.Angles(math.rad(88), math.rad(8), math.rad(4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.04, 0) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.84, -0.3) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	COROA_BRASAS = {
		{ pose = "COROA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "COROA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.03, freq = 22 },
		{ pose = "COROA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	BRASAS_CAEM = {
		{ pose = "COROA", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "COROA", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.05, freq = 26, marca = "SEGURA" },
		{ pose = "EMPURRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
