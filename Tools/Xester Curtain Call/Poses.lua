-- Poses.lua
-- ModuleScript "Poses" — Xester Curtain Call  (Xester, Forma 1)
--
-- FORMA 1, o BARALHO — gesto de mão, carta e leque. O braço direito
-- lidera e o corpo quase não sai do lugar: mágico de salão não se debate.
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
-- ESTA TOOL TOCA 1 SEQUÊNCIA(S), e só elas estão aqui. O vocabulário
-- completo do Xester é maior; mandar tudo em todas as treze seria asset
-- depositado e mudo em doze delas.
--

-- AS SEQUÊNCIAS
--
--   CURTAIN_CALL     conjuração  1.11s · CARGA GOLPE FIM
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.CORTINA = {
	RightArm = CFrame.new(1.24, 0.18, -0.66) * CFrame.Angles(math.rad(74), math.rad(-52), math.rad(-58)),
	LeftArm = CFrame.new(-1.24, 0.18, -0.66) * CFrame.Angles(math.rad(74), math.rad(52), math.rad(58)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(8), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(6), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.REVELA = {
	RightArm = CFrame.new(1.54, 0.26, 0.28) * CFrame.Angles(math.rad(30), math.rad(-28), math.rad(-62)),
	LeftArm = CFrame.new(-1.54, 0.26, 0.28) * CFrame.Angles(math.rad(30), math.rad(28), math.rad(62)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(-14), math.rad(0), math.rad(0)),
}

P.SEQUENCIAS = {

	-- conjuração · 1.11s · 4 passo(s)
	CURTAIN_CALL = {
		{ pose = "CORTINA", time = 0.26, style = "Back", dir = "In", marca = "CARGA" },
		{ pose = "CORTINA", time = 0.4, style = "Sine", dir = "InOut", tremor = 0.02, freq = 24 },
		{ pose = "REVELA", time = 0.15, style = "Quint", dir = "Out", marca = "GOLPE" },
		{ pose = "IDLE", time = 0.3, style = "Quad", dir = "Out", marca = "FIM" },
	},

}

return P
