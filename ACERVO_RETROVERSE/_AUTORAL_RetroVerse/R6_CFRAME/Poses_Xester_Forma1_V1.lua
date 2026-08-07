-- Poses_Xester_Forma1_V1.lua
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
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ATO_DE_DESAPARECER_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ATO_DE_DESAPARECER_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.898, 0.463, -1.4) * CFrame.Angles(math.rad(89.988), math.rad(-4), math.rad(2.999)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ATO_DE_DESAPARECER_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.952, 0.019, -0.958) * CFrame.Angles(math.rad(60.771), math.rad(-4.954), math.rad(0.668)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.FULL_HOUSE_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.FULL_HOUSE_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.2, 1.5, 0) * CFrame.Angles(math.rad(-180), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.FULL_HOUSE_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(49.881), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.436, 0.167, -0.48) * CFrame.Angles(math.rad(50.118), math.rad(-14.531), math.rad(3.435)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.FULL_HOUSE_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(-24.94), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.284, 0.491, -1.045) * CFrame.Angles(math.rad(89.967), math.rad(-4.003), math.rad(-14.983)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARDNADO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARDNADO_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.455, 1.244, 0.161) * CFrame.Angles(math.rad(178.102), math.rad(9.834), math.rad(10.163)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARDNADO_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.528, 1.223, 0.16) * CFrame.Angles(math.rad(177.416), math.rad(9.664), math.rad(15.017)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARDNADO_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.454, 1.239, 0.16) * CFrame.Angles(math.rad(178.212), math.rad(9.841), math.rad(10.348)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.TELEPORTE_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.455, 1.243, 0.16) * CFrame.Angles(math.rad(178.242), math.rad(9.846), math.rad(10.151)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.411, 1.183, 0.344) * CFrame.Angles(math.rad(-161.762), math.rad(12.693), math.rad(6.204)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.CARTA_COLOSSAL_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.472, 0.213, -0.667) * CFrame.Angles(math.rad(75.387), math.rad(-7.713), math.rad(13.5)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BURACO_NEGRO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BURACO_NEGRO_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.455, 1.245, 0.162) * CFrame.Angles(math.rad(177.39), math.rad(9.77), math.rad(10.223)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_1 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_2 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.439, 0.157, -0.471) * CFrame.Angles(math.rad(49.482), math.rad(-14.586), math.rad(3.362)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_3 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(-20), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.37, 0.497, -0.927) * CFrame.Angles(math.rad(90), math.rad(-4), math.rad(-20)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_4 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(24.786), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.439, 0.159, -0.476) * CFrame.Angles(math.rad(49.667), math.rad(-14.5), math.rad(3.271)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.ESCUDO_DE_CARTAS_5 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(-18.735), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-1.376, 0.495, -0.926) * CFrame.Angles(math.rad(88.825), math.rad(-4.059), math.rad(-19.271)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.738, 0.094, 0.57) * CFrame.Angles(math.rad(-28.224), math.rad(16.499), math.rad(-37.259)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.935, 0.296, 0.621) * CFrame.Angles(math.rad(19.871), math.rad(-14.022), math.rad(89.56)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(9.999), math.rad(14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.665, 0.5, -1.413) * CFrame.Angles(math.rad(89.998), math.rad(0.002), math.rad(-24.997)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(49.98), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.551, 1.298, -0.133) * CFrame.Angles(math.rad(-179.797), math.rad(-50), math.rad(0.094)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-14.998), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.933, 0.318, 0.634) * CFrame.Angles(math.rad(19.521), math.rad(-14.41), math.rad(90.241)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.BOLA_DE_FOGO_IMENSA_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(9.999), math.rad(14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.665, 0.5, -1.413) * CFrame.Angles(math.rad(89.998), math.rad(0.002), math.rad(-24.997)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_2 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-14.999), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.935, 0.296, 0.621) * CFrame.Angles(math.rad(19.871), math.rad(-14.022), math.rad(89.56)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_3 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-10), math.rad(-15), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.939, 0.302, 0.624) * CFrame.Angles(math.rad(19.956), math.rad(-14.008), math.rad(89.849)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SOPRO_DO_DRAGAO_4 = {
	HRP = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(10), math.rad(15), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(0.665, 0.5, -1.413) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(-25)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.RAIO_1 = {
	HRP = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(0), math.rad(25), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.RAIO_2 = {
	HRP = CFrame.new(0, -0.001, 0) * CFrame.Angles(math.rad(0), math.rad(89.691), math.rad(0)),
	Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
	LeftArm = CFrame.new(-0.722, 0.074, 0.561) * CFrame.Angles(math.rad(-26.574), math.rad(-15.282), math.rad(37.711)),
	LeftLeg = CFrame.new(-0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10)),
	RightArm = CFrame.new(1.994, 0.49, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(89.573)),
	RightLeg = CFrame.new(0.643, -1.918, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10)),
}

P.SEQUENCIAS = {

	ATO_DE_DESAPARECER = {
		{ pose = "ATO_DE_DESAPARECER_2", time = 0.417, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "ATO_DE_DESAPARECER_3", time = 0.167, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	FULL_HOUSE = {
		{ pose = "FULL_HOUSE_2", time = 0.667, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "FULL_HOUSE_3", time = 0.25, style = "Exponential", dir = "Out" },
		{ pose = "FULL_HOUSE_4", time = 0.333, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	CARDNADO = {
		{ pose = "CARDNADO_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "CARDNADO_3", time = 0.15, style = "Exponential", dir = "Out" },
		{ pose = "CARDNADO_4", time = 0.15, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	TELEPORTE = {
		{ pose = "TELEPORTE_1", time = 0.12, style = "Quad", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.2, style = "Quad", dir = "Out" },
	},

	CARTA_COLOSSAL = {
		{ pose = "CARTA_COLOSSAL_2", time = 0.5, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "CARTA_COLOSSAL_3", time = 0.217, style = "Exponential", dir = "Out" },
		{ pose = "CARTA_COLOSSAL_4", time = 0.4, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	BURACO_NEGRO = {
		{ pose = "BURACO_NEGRO_2", time = 0.25, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	ESCUDO_DE_CARTAS = {
		{ pose = "ESCUDO_DE_CARTAS_2", time = 0.583, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "ESCUDO_DE_CARTAS_3", time = 0.583, style = "Exponential", dir = "Out" },
		{ pose = "ESCUDO_DE_CARTAS_4", time = 0.25, style = "Exponential", dir = "Out" },
		{ pose = "ESCUDO_DE_CARTAS_5", time = 0.167, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	BOLA_DE_FOGO = {
		{ pose = "BOLA_DE_FOGO_2", time = 0.25, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "BOLA_DE_FOGO_3", time = 0.25, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	BOLA_DE_FOGO_IMENSA = {
		{ pose = "BOLA_DE_FOGO_IMENSA_2", time = 0.333, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "BOLA_DE_FOGO_IMENSA_3", time = 0.25, style = "Exponential", dir = "Out" },
		{ pose = "BOLA_DE_FOGO_IMENSA_4", time = 0.25, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	SOPRO_DO_DRAGAO = {
		{ pose = "SOPRO_DO_DRAGAO_2", time = 0.25, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "SOPRO_DO_DRAGAO_3", time = 0.05, style = "Exponential", dir = "Out" },
		{ pose = "SOPRO_DO_DRAGAO_4", time = 0.833, style = "Exponential", dir = "Out", marca = "GOLPE" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

	RAIO = {
		{ pose = "RAIO_2", time = 0.25, style = "Exponential", dir = "Out", marca = "CARGA" },
		{ pose = "GUARDA_1", time = 0.24, style = "Quad", dir = "Out" },
	},

}

return P
