-- Poses.lua
-- ModuleScript "Poses" — Xester Curtain Reversal  (Xester, Forma 2)
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
-- ESTA TOOL TOCA 1 SEQUÊNCIA(S), e só elas estão aqui. O vocabulário
-- completo do Xester é maior; mandar tudo em todas as treze seria asset
-- depositado e mudo em doze delas.
--

-- AS SEQUÊNCIAS
--
--   REVERTER         cutscene    1.80s · ABSORVE APAGA FECHA
--
-- Gerado por FERRAMENTAS/gerar_poses_xester_v3.py.

local P = {}


P.CENA_FECHA = {
	RightArm = CFrame.new(1.3, 0.1, -0.44) * CFrame.Angles(math.rad(62), math.rad(-40), math.rad(-48)),
	LeftArm = CFrame.new(-1.3, 0.1, -0.44) * CFrame.Angles(math.rad(62), math.rad(40), math.rad(48)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, -0.18, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
}

P.CENA_RASGA = {
	RightArm = CFrame.new(1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(-38), math.rad(-44)),
	LeftArm = CFrame.new(-1.56, 0.44, -0.42) * CFrame.Angles(math.rad(96), math.rad(38), math.rad(44)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0.08, 0) * CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.5, -1.88, -0.24) * CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.5, -1.88, 0.24) * CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
}

P.IDLE = {
	RightArm = CFrame.new(1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(4), math.rad(4)),
	LeftArm = CFrame.new(-1.48, 0.05, -0.22) * CFrame.Angles(math.rad(18), math.rad(-4), math.rad(-4)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-3), math.rad(0), math.rad(0)),
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(-6), math.rad(0)),
}

P.SEQUENCIAS = {

	-- cutscene · 1.80s · 3 passo(s)
	REVERTER = {
		{ pose = "CENA_RASGA", time = 0.6, style = "Sine", dir = "InOut", marca = "ABSORVE" },
		{ pose = "CENA_FECHA", time = 0.6, style = "Sine", dir = "InOut", marca = "APAGA" },
		{ pose = "IDLE", time = 0.6, style = "Quad", dir = "Out", marca = "FECHA" },
	},

}

return P
