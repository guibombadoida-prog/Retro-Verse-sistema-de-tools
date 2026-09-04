-- Poses.lua
-- ModuleScript "Poses" — Xester Dragons Requiem  (Xester, Forma 2)
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
--   REQUIEM_CARGA    sustentada  1.52s · CARGA SEGURA GOLPE FIM
--   REQUIEM_SOPRO    golpe pesado 1.34s · CARGA SEGURA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.ENCHE_PEITO = {
	RightArm = CFrame.new(1.36, 0.3, -0.28) * CFrame.Angles(math.rad(78), math.rad(-36), math.rad(-40)),
	LeftArm = CFrame.new(-1.36, 0.3, -0.28) * CFrame.Angles(math.rad(78), math.rad(36), math.rad(40)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.06, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.9, 0.2) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.86, -0.24) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SOPRA = {
	RightArm = CFrame.new(1.5, 0.16, -1.18) * CFrame.Angles(math.rad(84), math.rad(-10), math.rad(-6)),
	LeftArm = CFrame.new(-1.5, 0.16, -1.18) * CFrame.Angles(math.rad(84), math.rad(10), math.rad(6)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.14, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.78, -0.38) * CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- sustentada · 1.52s · 4 passo(s)
	REQUIEM_CARGA = {
		{ pose = "ENCHE_PEITO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ENCHE_PEITO", time = 0.7, style = "Sine", dir = "InOut", tremor = 0.05, freq = 23, marca = "SEGURA" },
		{ pose = "ENCHE_PEITO", time = 0.18, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.34, style = "Quad", dir = "Out", marca = "FIM" },
	},

	-- golpe pesado · 1.34s · 4 passo(s)
	REQUIEM_SOPRO = {
		{ pose = "ENCHE_PEITO", time = 0.3, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "ENCHE_PEITO", time = 0.54, style = "Sine", dir = "InOut", tremor = 0.06, freq = 28, marca = "SEGURA" },
		{ pose = "SOPRA", time = 0.17, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.33, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
