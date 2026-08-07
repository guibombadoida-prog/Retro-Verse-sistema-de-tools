-- Poses_Xester_Forma2_V1.lua
-- ModuleScript "Poses" — TRACKS extraídas do script original do modelo
--
-- NÃO É POSE AUTORAL. Cada keyframe é a pose que o script original REALMENTE
-- alcança: o extrator simula o `:lerp(alvo, alpha)` repetido N quadros
-- (`1-(1-alpha)^N`) em vez de copiar o alvo, porque com alpha baixo o original
-- nunca chega ao alvo escrito no código.
--
-- Convenção: C0 do animator = C0 do original invertido (o original solda
-- membro→Torso, o animator solda Torso→membro). HRP entra sem inverter.
--
-- Gerado por FERRAMENTAS/extrair_poses_xester.py — não editar à mão.


local P = {}

P.GUARDA_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.CARTA_CEIFEIRA_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.CARTA_CEIFEIRA_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.604), math.rad(-35.235), math.rad(6.974)),
	Head = CFrame.new(0.005, 2.005, 0.037) * CFrame.Angles(math.rad(-2.019), math.rad(24.562), math.rad(-1.68)),
	LeftArm = CFrame.new(-2.319, 1, -1.072) * CFrame.Angles(math.rad(109.327), math.rad(-21.372), math.rad(-32.018)),
	LeftLeg = CFrame.new(-1.577, -1.913, -0.743) * CFrame.Angles(math.rad(23.261), math.rad(24.987), math.rad(-28.601)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.136, -2.079, -0.44) * CFrame.Angles(math.rad(-26.919), math.rad(-16.362), math.rad(3.895)),
}

P.CARTA_CEIFEIRA_3 = {
	HRP = CFrame.new(-0.199, 0, 1.988) * CFrame.Angles(math.rad(7.338), math.rad(-28.758), math.rad(22.622)),
	Head = CFrame.new(0.01, 1.933, -0.184) * CFrame.Angles(math.rad(-18.281), math.rad(24.16), math.rad(5.042)),
	LeftArm = CFrame.new(-2.32, 1.003, -1.073) * CFrame.Angles(math.rad(109.396), math.rad(-21.463), math.rad(-32.024)),
	LeftLeg = CFrame.new(-1.64, -2.283, -0.188) * CFrame.Angles(math.rad(-6.149), math.rad(35.091), math.rad(-23.621)),
	RightArm = CFrame.new(0.828, 0.366, 1.292) * CFrame.Angles(math.rad(-101.796), math.rad(-27.609), math.rad(-74.92)),
	RightLeg = CFrame.new(0.976, -2.232, -0.068) * CFrame.Angles(math.rad(-26.9), math.rad(-16.361), math.rad(3.9)),
}

P.CARTA_CEIFEIRA_4 = {
	HRP = CFrame.new(-0.028, 0, 0.283) * CFrame.Angles(math.rad(-21.916), math.rad(-56.016), math.rad(-0.619)),
	Head = CFrame.new(0.043, 2.007, 0.076) * CFrame.Angles(math.rad(3.592), math.rad(50.94), math.rad(3.809)),
	LeftArm = CFrame.new(-0.328, 0.74, -1.507) * CFrame.Angles(math.rad(116.05), math.rad(-0.806), math.rad(71.826)),
	LeftLeg = CFrame.new(-1.757, -2.084, -0.694) * CFrame.Angles(math.rad(50.187), math.rad(38.966), math.rad(-44.189)),
	RightArm = CFrame.new(1.311, 0.68, -1.064) * CFrame.Angles(math.rad(113.816), math.rad(-0.362), math.rad(-49.996)),
	RightLeg = CFrame.new(0.981, -1.908, -0.982) * CFrame.Angles(math.rad(-18.951), math.rad(-20.984), math.rad(-17.809)),
}

P.CARTA_CEIFEIRA_5 = {
	HRP = CFrame.new(-0.001, 0, 0.011) * CFrame.Angles(math.rad(-30.701), math.rad(-60.051), math.rad(-8.44)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.753), math.rad(51.09), math.rad(3.754)),
	LeftArm = CFrame.new(-0.339, 0.681, -1.429) * CFrame.Angles(math.rad(109.648), math.rad(-9.934), math.rad(55.303)),
	LeftLeg = CFrame.new(-1.758, -2.083, -0.698) * CFrame.Angles(math.rad(50.512), math.rad(38.94), math.rad(-44.311)),
	RightArm = CFrame.new(1.707, 0.969, -1.129) * CFrame.Angles(math.rad(125.548), math.rad(-5.65), math.rad(-9.14)),
	RightLeg = CFrame.new(0.982, -1.906, -0.986) * CFrame.Angles(math.rad(-18.911), math.rad(-21.019), math.rad(-17.933)),
}

P.ESFERA_DO_FIM_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.ESFERA_DO_FIM_2 = {
	HRP = CFrame.new(0, 0, 2.96) * CFrame.Angles(math.rad(32.865), math.rad(-45.831), math.rad(2.169)),
	Head = CFrame.new(0.077, 1.962, -0.13) * CFrame.Angles(math.rad(-19.82), math.rad(33.614), math.rad(10.237)),
	LeftArm = CFrame.new(-2.317, 0.73, -0.782) * CFrame.Angles(math.rad(96.692), math.rad(-10.377), math.rad(-22.064)),
	LeftLeg = CFrame.new(-1.405, -2.171, -0.331) * CFrame.Angles(math.rad(-13.521), math.rad(35.152), math.rad(-7.537)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.071, -2.294, 0.17) * CFrame.Angles(math.rad(-32.037), math.rad(-14.211), math.rad(4.863)),
}

P.ESFERA_DO_FIM_3 = {
	HRP = CFrame.new(0, 0, 0.083) * CFrame.Angles(math.rad(-31.75), math.rad(37.192), math.rad(0.406)),
	Head = CFrame.new(0.038, 1.902, -0.023) * CFrame.Angles(math.rad(-2.032), math.rad(-35.859), math.rad(1.284)),
	LeftArm = CFrame.new(-0.587, 0.12, -1.133) * CFrame.Angles(math.rad(69.321), math.rad(-26.268), math.rad(69.143)),
	LeftLeg = CFrame.new(-1.093, -1.897, -0.9) * CFrame.Angles(math.rad(-26.747), math.rad(32.905), math.rad(17.306)),
	RightArm = CFrame.new(0.487, 0.343, -1.032) * CFrame.Angles(math.rad(64.915), math.rad(-24.57), math.rad(-81.952)),
	RightLeg = CFrame.new(1.58, -1.757, -0.819) * CFrame.Angles(math.rad(-13.305), math.rad(-48.877), math.rad(11.711)),
}

P.ESFERA_DO_FIM_4 = {
	HRP = CFrame.new(0, 0, 0.001) * CFrame.Angles(math.rad(-9.124), math.rad(-29.775), math.rad(13.933)),
	Head = CFrame.new(0.136, 1.895, -0.091) * CFrame.Angles(math.rad(-3.547), math.rad(34.541), math.rad(-2.904)),
	LeftArm = CFrame.new(-2.484, 0.234, -0.156) * CFrame.Angles(math.rad(122.766), math.rad(31.298), math.rad(-87.939)),
	LeftLeg = CFrame.new(-1.901, -2.021, -0.657) * CFrame.Angles(math.rad(32.249), math.rad(33.563), math.rad(-40.161)),
	RightArm = CFrame.new(2.336, 0.155, -0.332) * CFrame.Angles(math.rad(69.477), math.rad(-24.205), math.rad(68.485)),
	RightLeg = CFrame.new(0.86, -1.695, -0.683) * CFrame.Angles(math.rad(-39.096), math.rad(-21.231), math.rad(8.056)),
}

P.BARALHO_ESPECTRAL_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.BARALHO_ESPECTRAL_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.6), math.rad(-39.9), math.rad(-0.6)),
	Head = CFrame.new(0, 2.002, 0.026) * CFrame.Angles(math.rad(-2.898), math.rad(38.347), math.rad(2.27)),
	LeftArm = CFrame.new(-2.466, 0.745, -0.474) * CFrame.Angles(math.rad(83.358), math.rad(-20.083), math.rad(-35.007)),
	LeftLeg = CFrame.new(-1.362, -2.081, -0.395) * CFrame.Angles(math.rad(-11.085), math.rad(42.432), math.rad(-5.015)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.123, -2.375, -0.131) * CFrame.Angles(math.rad(-44.219), math.rad(-16.774), math.rad(-1.073)),
}

P.INVOCACAO_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.INVOCACAO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.038, 0.768, -0.509) * CFrame.Angles(math.rad(122.391), math.rad(-2.395), math.rad(-22.707)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.INVOCACAO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-28.109), math.rad(-53.06), math.rad(-6.08)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.708), math.rad(50.883), math.rad(3.792)),
	LeftArm = CFrame.new(-0.331, 0.741, -1.507) * CFrame.Angles(math.rad(116.006), math.rad(-0.667), math.rad(71.863)),
	LeftLeg = CFrame.new(-1.754, -2.083, -0.701) * CFrame.Angles(math.rad(50.33), math.rad(38.899), math.rad(-44.09)),
	RightArm = CFrame.new(1.309, 0.681, -1.06) * CFrame.Angles(math.rad(113.807), math.rad(-0.221), math.rad(-50.037)),
	RightLeg = CFrame.new(0.982, -1.907, -0.982) * CFrame.Angles(math.rad(-18.986), math.rad(-20.981), math.rad(-17.82)),
}

P.INVOCACAO_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.96), math.rad(-59.925), math.rad(-8.67)),
	Head = CFrame.new(0.043, 2.008, 0.078) * CFrame.Angles(math.rad(3.754), math.rad(51.089), math.rad(3.754)),
	LeftArm = CFrame.new(-0.339, 0.681, -1.429) * CFrame.Angles(math.rad(109.648), math.rad(-9.933), math.rad(55.303)),
	LeftLeg = CFrame.new(-1.758, -2.083, -0.698) * CFrame.Angles(math.rad(50.512), math.rad(38.94), math.rad(-44.311)),
	RightArm = CFrame.new(1.707, 0.969, -1.129) * CFrame.Angles(math.rad(125.547), math.rad(-5.65), math.rad(-9.14)),
	RightLeg = CFrame.new(0.982, -1.906, -0.986) * CFrame.Angles(math.rad(-18.911), math.rad(-21.019), math.rad(-17.933)),
}

P.FURIA_DO_MACHADO_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-14.9), math.rad(-43.1), math.rad(4.4)),
	Head = CFrame.new(-0.003, 2.002, -0.004) * CFrame.Angles(math.rad(-3.925), math.rad(40.134), math.rad(2.532)),
	LeftArm = CFrame.new(-2.383, 0.304, 0.266) * CFrame.Angles(math.rad(-5.78), math.rad(11.849), math.rad(-48.21)),
	LeftLeg = CFrame.new(-1.743, -2.049, -0.483) * CFrame.Angles(math.rad(45.814), math.rad(41.32), math.rad(-42.864)),
	RightArm = CFrame.new(2.413, 0.189, -0.103) * CFrame.Angles(math.rad(26.004), math.rad(-2.959), math.rad(47.972)),
	RightLeg = CFrame.new(0.875, -1.869, -0.559) * CFrame.Angles(math.rad(-24.193), math.rad(-20.324), math.rad(-8.869)),
}

P.FURIA_DO_MACHADO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-27.488), math.rad(-40.75), math.rad(-28.28)),
	Head = CFrame.new(0.068, 2.006, 0.101) * CFrame.Angles(math.rad(4.565), math.rad(41.56), math.rad(3.095)),
	LeftArm = CFrame.new(-2.192, 0.097, -0.593) * CFrame.Angles(math.rad(47.976), math.rad(-17.098), math.rad(-35.404)),
	LeftLeg = CFrame.new(-1.432, -2.014, -0.959) * CFrame.Angles(math.rad(45.645), math.rad(31.864), math.rad(-26.936)),
	RightArm = CFrame.new(2.155, 1.397, -0.617) * CFrame.Angles(math.rad(138.257), math.rad(44.804), math.rad(-1.525)),
	RightLeg = CFrame.new(1.196, -1.809, -0.93) * CFrame.Angles(math.rad(-18.901), math.rad(-20.973), math.rad(11.332)),
}

P.FURIA_DO_MACHADO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-27.599), math.rad(-40.7), math.rad(16.148)),
	Head = CFrame.new(0.095, 2.003, 0.14) * CFrame.Angles(math.rad(5.462), math.rad(28.49), math.rad(2.63)),
	LeftArm = CFrame.new(-2.258, 0.137, 0.575) * CFrame.Angles(math.rad(-13.597), math.rad(26.857), math.rad(-28.932)),
	LeftLeg = CFrame.new(-1.452, -2.001, -0.99) * CFrame.Angles(math.rad(-11.455), math.rad(39.857), math.rad(8.627)),
	RightArm = CFrame.new(0.932, 1.322, -1.309) * CFrame.Angles(math.rad(142.845), math.rad(10.33), math.rad(-53.078)),
	RightLeg = CFrame.new(1.199, -1.808, -0.934) * CFrame.Angles(math.rad(-18.847), math.rad(-20.97), math.rad(11.536)),
}

P.PROCISSAO_DE_CARTAS_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-21.3), math.rad(-14.9), math.rad(-0.5)),
	Head = CFrame.new(0.08, 2.023, 0.048) * CFrame.Angles(math.rad(-0.972), math.rad(14.59), math.rad(6.922)),
	LeftArm = CFrame.new(-2.058, 0.43, -0.754) * CFrame.Angles(math.rad(87.174), math.rad(6.608), math.rad(-24.807)),
	LeftLeg = CFrame.new(-0.907, -2.028, -1.08) * CFrame.Angles(math.rad(24.73), math.rad(24.757), math.rad(-11.398)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.064, -2, -0.194) * CFrame.Angles(math.rad(-32.837), math.rad(-16.665), math.rad(2.212)),
}

P.PROCISSAO_DE_CARTAS_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-17.746), math.rad(28.056), math.rad(-12.978)),
	Head = CFrame.new(0.023, 2.005, 0.055) * CFrame.Angles(math.rad(-1.968), math.rad(-27.061), math.rad(1.058)),
	LeftArm = CFrame.new(-2.353, 0.443, 0.326) * CFrame.Angles(math.rad(98.67), math.rad(0.653), math.rad(-114.328)),
	LeftLeg = CFrame.new(-0.853, -1.941, -0.974) * CFrame.Angles(math.rad(-12.839), math.rad(26.606), math.rad(5.374)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(1.323, -2.009, -0.309) * CFrame.Angles(math.rad(-25.964), math.rad(-32.422), math.rad(2.795)),
}

P.PROCISSAO_DE_CARTAS_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-36.4), math.rad(-42.48), math.rad(4.026)),
	Head = CFrame.new(0.038, 2.009, 0.088) * CFrame.Angles(math.rad(10.445), math.rad(39.336), math.rad(-8.544)),
	LeftArm = CFrame.new(-1.253, 0.752, -1.519) * CFrame.Angles(math.rad(98.886), math.rad(-0.337), math.rad(24.781)),
	LeftLeg = CFrame.new(-1.78, -1.868, -1.089) * CFrame.Angles(math.rad(48.066), math.rad(33.722), math.rad(-39.71)),
	RightArm = CFrame.new(0.709, 0.205, 0.822) * CFrame.Angles(math.rad(-101.75), math.rad(-27.74), math.rad(-93.961)),
	RightLeg = CFrame.new(0.926, -1.819, -0.307) * CFrame.Angles(math.rad(-63.229), math.rad(-29.312), math.rad(-17.349)),
}

P.PROCISSAO_DE_CARTAS_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-30.621), math.rad(-56.256), math.rad(2.9)),
	Head = CFrame.new(0.041, 1.965, 0.095) * CFrame.Angles(math.rad(24.454), math.rad(43.474), math.rad(-19.174)),
	LeftArm = CFrame.new(-2.376, 1.372, -0.992) * CFrame.Angles(math.rad(102.586), math.rad(-36.182), math.rad(-43.442)),
	LeftLeg = CFrame.new(-1.759, -2.083, -0.7) * CFrame.Angles(math.rad(50.504), math.rad(38.924), math.rad(-44.296)),
	RightArm = CFrame.new(2.353, -0.045, 0.249) * CFrame.Angles(math.rad(26.991), math.rad(-39.131), math.rad(42.94)),
	RightLeg = CFrame.new(0.982, -1.905, -0.983) * CFrame.Angles(math.rad(-19.047), math.rad(-21.043), math.rad(-17.92)),
}

P.GARGALHADA_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-14.9), math.rad(-43.1), math.rad(4.4)),
	Head = CFrame.new(-0.003, 2.002, -0.004) * CFrame.Angles(math.rad(-3.925), math.rad(40.134), math.rad(2.532)),
	LeftArm = CFrame.new(-2.383, 0.304, 0.266) * CFrame.Angles(math.rad(-5.78), math.rad(11.849), math.rad(-48.21)),
	LeftLeg = CFrame.new(-1.743, -2.049, -0.483) * CFrame.Angles(math.rad(45.814), math.rad(41.32), math.rad(-42.864)),
	RightArm = CFrame.new(2.413, 0.189, -0.103) * CFrame.Angles(math.rad(26.004), math.rad(-2.959), math.rad(47.972)),
	RightLeg = CFrame.new(0.875, -1.869, -0.559) * CFrame.Angles(math.rad(-24.193), math.rad(-20.324), math.rad(-8.869)),
}

P.SEQUENCIAS = {

	CARTA_CEIFEIRA = {
		{ pose = "CARTA_CEIFEIRA_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "CARTA_CEIFEIRA_3", time = 0.167, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_CEIFEIRA_4", time = 0.2, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_CEIFEIRA_5", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	ESFERA_DO_FIM = {
		{ pose = "ESFERA_DO_FIM_2", time = 0.25, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "ESFERA_DO_FIM_3", time = 0.467, style = "Exponential", dir = "Out" },
		{ pose = "ESFERA_DO_FIM_4", time = 0.583, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	BARALHO_ESPECTRAL = {
		{ pose = "BARALHO_ESPECTRAL_2", time = 2.5, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	INVOCACAO = {
		{ pose = "INVOCACAO_2", time = 0.067, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "INVOCACAO_3", time = 0.2, style = "Exponential", dir = "Out" },
		{ pose = "INVOCACAO_4", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	FURIA_DO_MACHADO = {
		{ pose = "FURIA_DO_MACHADO_2", time = 0.15, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "FURIA_DO_MACHADO_3", time = 0.15, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	PROCISSAO_DE_CARTAS = {
		{ pose = "PROCISSAO_DE_CARTAS_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "PROCISSAO_DE_CARTAS_3", time = 0.433, style = "Exponential", dir = "Out" },
		{ pose = "PROCISSAO_DE_CARTAS_4", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	GARGALHADA = {
		{ pose = "GARGALHADA_1", time = 0.12, style = "Quad", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.2, style = "Quad", dir = "Out" },
	},

}

return P
