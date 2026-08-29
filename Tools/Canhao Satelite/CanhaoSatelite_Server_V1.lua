-- CanhaoSatelite_Server_V1.lua
-- Script de servidor — Canhao Satelite  (conjunto REALITY)
--
--   M1   marca o ponto, e a órbita descarrega nele
--
-- ORIGEM: `LowOrbitIonCannon`, de `reality_tools.rbxmx`.
--
--   A origem marcava o ponto e criava um `Explosion` — que é a instância que o repositório proíbe, porque ela quebra junta e derruba mapa sem pedir licença.
--   O que fica é a FORMA: marca, espera, feixe. O que muda é o miolo. O feixe desce por RAYCAST, então ele bate no primeiro teto que
--   encontrar em vez de atravessar o prédio, e a onda empurra por MASSA em vez de aplicar `BlastPressure` fixo em tudo.
--
-- ⛔ NENHUMA LINHA DA ORIGEM ATRAVESSOU. O arquivo de origem carrega três
--    vetores de execução remota (`assetimport.org` via `HttpService`,
--    `require(206209239)`, `chipmunkav.com`). O que veio de lá é geometria,
--    som e malha; a lógica foi reescrita a partir da LEITURA do script, que é
--    o que o pedido dizia: estudar a mecânica, e refazê-la conforme as regras.
--
-- A FAMÍLIA NOVA DE FÍSICA
--
--   Nada aqui usa `BodyVelocity`/`BodyPosition`/`BodyGyro`. Tudo é constraint:
--   `LinearVelocity`, `AlignPosition`, `AlignOrientation`, `VectorForce`,
--   `AngularVelocity`, `RopeConstraint`. Elas são resolvidas pelo solver junto
--   com o mundo, então o que empurram COLIDE, quica e gira — e replica sozinho.
--
-- AS TRÊS PROIBIÇÕES DO CONJUNTO
--
--   1. nada destrói peça do mapa   2. nada fere o próprio jogador
--   3. a árvore é ancorada
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_reality_v2.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool      = script.Parent
local Handle    = Tool:WaitForChild("Handle")
local VFXRemote = Tool:WaitForChild("VFXRemote")
local Poses     = require(Tool:WaitForChild("Poses"))
local Animator  = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito  = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "Canhao"

local CFG = {
	--- Quanto de força cada constraint pode gastar, POR UNIDADE DE MASSA.
	---
	--- Este é o número que separa física de teleporte. `BodyPosition` da
	--- origem usava `math.huge*math.huge` — força infinita, que arrasta um
	--- prédio com a mesma facilidade que um cubo, e por isso nada nela tinha
	--- peso. Aqui o teto é proporcional à massa e FINITO: a peça pesada
	--- responde devagar, e é isso que o jogador lê como "pesada".
	FORCA_POR_MASSA = 260,
	TORQUE_POR_MASSA = 90,

	--- Gravidade assumida para a balística fechada (roPhysics). `workspace`
	--- pode mudar a dela, e é lida em `gravidade()`.
	G_PADRAO = 196.2,

	--- O teto de passos do projétil. Entre dois passos vai um RAYCAST, que é
	--- o método do FastCast — sem ele uma peça a 200 studs/s atravessa parede,
	--- porque a 60 Hz ela salta 3,3 studs por quadro.
	PASSOS_MAX = 600,

	RECARGA = 26.0,
	DANO = 62,
	RAIO = 15,
	ALTURA = 300,

	--- A espera entre a marca e o feixe. É o que dá tempo de sair — e é o que
	--- faz esta ser uma ultimate jogável em vez de um clique que mata.
	ESPERA = 0.9,

	ONDA = 130,
	ONDA_PECA = 90,
	TETO_PECAS = 24,
	DESABA = 2.2,

}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoUso = 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0

--- Declarada aqui e atribuída mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso ela viraria global.
local primaria


local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function anguloDe(i)
	return (i or proximo()) * 2.399963
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--═══════════════════════════════════════════════════════════════
-- SOM — mora no Handle, e veio da origem
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local achado = Handle:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	local pasta = Tool:FindFirstChild("SFX")
	achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--- Toca numa ÂNCORA PRÓPRIA. Um `Sound` só toca enquanto tem pai no
--- DataModel, e a peça que o carrega pode sair do mundo antes do fim.
local function tocarEm(nome, posicao, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end

	local ancora = Instance.new("Part")
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Transparency = 1
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.CFrame = CFrame.new(posicao or Vector3.new())
	ancora.Parent = workspace

	local som = base:Clone()
	som.PlaybackSpeed = pitch or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- ⛔ A GUARDA — O QUE É MEU NÃO É ALVO
--
-- ISTO É UMA DAS TRÊS PROIBIÇÕES PEDIDAS, e está aqui em cima de propósito:
-- toda função abaixo consulta ESTA, e nenhuma repete a checagem por conta
-- própria. Filtro copiado em sete Servers é sete lugares para esquecer, e no
-- `Indutor de Gravidade` esquecer significa o jogador se puxar para dentro do
-- próprio poço e não conseguir mais sair.
--═══════════════════════════════════════════════════════════════

local function ehMinha(inst)
	if not inst then return true end
	if personagem and inst:IsDescendantOf(personagem) then return true end
	if inst:IsDescendantOf(Tool) then return true end
	-- peça que uma Tool qualquer esteja segurando também não é alvo: puxar o
	-- Handle de outro jogador arranca a arma da mão dele
	if inst:FindFirstAncestorOfClass("Tool") then return true end
	return false
end

--═══════════════════════════════════════════════════════════════
-- DANO
--
-- `TakeDamage` respeita `ForceField`; escrever em `Health` fura. A tag
-- `creator` é o que credita o abate, e o `Name` vem ANTES do `Parent`.
--═══════════════════════════════════════════════════════════════

local function creditar(alvoHum)
	local marca = alvoHum:FindFirstChild("creator")
	if marca then marca.Parent = nil end
	marca = Instance.new("ObjectValue")
	marca.Name = "creator"
	marca.Value = jogador
	marca.Parent = alvoHum
	Debris:AddItem(marca, 3)
end

local function aplicarDano(alvoHum, bruto)
	if not alvoHum or alvoHum.Health <= 0 then return 0 end
	if alvoHum == humanoide then return 0 end
	creditar(alvoHum)
	alvoHum:TakeDamage(bruto)
	return bruto
end

local function raizDe(alvoHum)
	local corpo = alvoHum and alvoHum.Parent
	return corpo and corpo:FindFirstChild("HumanoidRootPart") or nil
end

--- Humanoides num raio. `personagem` sai pelo `OverlapParams`, e o
--- `humanoide` sai de novo no laço — cinto e suspensório, porque a Tool pode
--- estar na mão de alguém cujo Character trocou no meio.
local function alvosEm(posicao, raio, limite)
	local achados, vistos = {}, {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	for _, parte in ipairs(workspace:GetPartBoundsInRadius(posicao, raio, filtro)) do
		local modelo = parte:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and hum ~= humanoide and not vistos[hum] then
			vistos[hum] = true
			table.insert(achados, hum)
			if limite and #achados >= limite then break end
		end
	end
	return achados
end

--- Alvos num CONE à frente. O produto escalar é o que separa cone de esfera:
--- sem ele, um golpe para a frente acerta quem está atrás de quem o deu.
local function alvosNoCone(origem, direcao, alcance, cosseno, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(origem, alcance, (limite or 12) * 2)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - origem
			if delta.Magnitude > 0.01
					and delta.Unit:Dot(direcao.Unit) >= cosseno then
				table.insert(achados, alvo)
				if #achados >= (limite or 12) then break end
			end
		end
	end
	return achados
end

local function frente(distancia)
	if not raiz then return Vector3.new() end
	return raiz.Position + raiz.CFrame.LookVector * (distancia or 20)
end

--- O chão sob um ponto mirado.
local function noChao(ponto)
	if typeof(ponto) ~= "Vector3" then return Vector3.new() end
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(ponto + Vector3.new(0, 8, 0),
		Vector3.new(0, -400, 0), filtro)
	return batida and batida.Position or ponto
end


--═══════════════════════════════════════════════════════════════
-- ⚙️  O BLOCO DE FÍSICA — a família NOVA, e por que ela é outra coisa
--
-- Tudo daqui para baixo é constraint. Nenhuma linha usa `BodyVelocity`,
-- `BodyPosition`, `BodyGyro`, `BodyForce` nem `BodyAngularVelocity`.
--
-- A DIFERENÇA QUE IMPORTA, e não é o nome:
--
--   `BodyPosition` teleporta. Ele tem `maxForce` infinito, ignora colisão no
--   caminho, e a peça chega ao destino atravessando o que estiver no meio. É
--   o que a `Physics Gun` e o `Gravity Inducer` da origem faziam — e por isso
--   nada neles tinha PESO: um cubo de 4 studs e um prédio se moviam igual.
--
--   `AlignPosition` PUXA. A força tem teto, a peça acelera, colide, balança,
--   e chega tarde se for pesada. `ForceLimitMode = Magnitude` com
--   `MaxForce ∝ massa` é o que faz o jogador sentir a diferença entre um
--   caixote e uma pedra sem que ninguém escreva um número na tela.
--
-- TODA constraint aqui precisa de `Attachment`, e a antiga não precisava. Por
-- isso `pontoDe()` existe, e por isso ele REUSA o attachment pelo nome: criar
-- um novo por chamada deixa lixo pendurado na peça de outro jogador.
--═══════════════════════════════════════════════════════════════

local PREFIXO = "RV_" .. ARQUETIPO

local function gravidade()
	local g = workspace.Gravity
	if type(g) ~= "number" or g <= 0 then return CFG.G_PADRAO end
	return g
end

--- Um `Attachment` com nome próprio, criado uma vez e reusado.
local function pontoDe(peca, sufixo, deslocamento)
	local nome = PREFIXO .. "_" .. sufixo
	local a = peca:FindFirstChild(nome)
	if a and a:IsA("Attachment") then
		if deslocamento then a.Position = deslocamento end
		return a
	end
	a = Instance.new("Attachment")
	a.Name = nome
	a.Position = deslocamento or Vector3.new()
	a.Parent = peca
	return a
end

--- Tira TUDO que este arquétipo pendurou numa peça.
---
--- É o oposto exato de `pontoDe` + as constraints, e é o que garante que a
--- peça de outro jogador volte a ser dela. O `PREFIXO` carrega o nome da
--- Tool: duas Tools deste conjunto na mesma peça não desfazem uma à outra.
---
--- ⛔ Note o que ele NÃO faz: ele não toca na peça. Nada aqui apaga, esconde
---    nem redimensiona geometria do mapa — só remove o que esta Tool pendurou.
local function soltarPeca(peca)
	if not (peca and peca.Parent) then return end
	for _, filho in ipairs(peca:GetChildren()) do
		if filho.Name:sub(1, #PREFIXO) == PREFIXO then
			filho.Parent = nil
		end
	end
end

--═══════════════════════════════════════════════════════════════
-- IMPULSO — `LinearVelocity`, o substituto de `BodyVelocity`
--
-- `MaxForce` é PROPORCIONAL À MASSA, e finito. Com teto fixo, um alvo pesado
-- nem se move e um leve sai voando — que é o defeito que 160 `BodyVelocity`
-- deste repositório têm hoje e ninguém percebeu porque todo alvo é R6.
--═══════════════════════════════════════════════════════════════

local function impulso(peca, direcao, velocidade, tempo)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored then return nil end
	if direcao.Magnitude < 0.001 then return nil end

	local a = pontoDe(peca, "Imp")
	local lv = peca:FindFirstChild(PREFIXO .. "_LV")
	if not lv then
		lv = Instance.new("LinearVelocity")
		lv.Name = PREFIXO .. "_LV"
		lv.Attachment0 = a
	end
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.max(peca.AssemblyMass, 0.1) * CFG.FORCA_POR_MASSA
	lv.VectorVelocity = direcao.Unit * velocidade
	lv.Parent = peca
	Debris:AddItem(lv, tempo or 0.2)
	return lv
end

--- GIRO — `AngularVelocity`. É o que a `Lapada Seca` tem e a origem não tinha:
--- o alvo sai RODANDO, não deslizando. Um empurrão sem giro lê como escorregão.
local function giro(peca, eixo, velocidade, tempo)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored then return nil end

	local a = pontoDe(peca, "Gir")
	local av = peca:FindFirstChild(PREFIXO .. "_AV")
	if not av then
		av = Instance.new("AngularVelocity")
		av.Name = PREFIXO .. "_AV"
		av.Attachment0 = a
	end
	av.RelativeTo = Enum.ActuatorRelativeTo.World
	av.MaxTorque = math.max(peca.AssemblyMass, 0.1) * CFG.TORQUE_POR_MASSA
	av.AngularVelocity = (eixo or Vector3.new(0, 1, 0)).Unit * velocidade
	av.Parent = peca
	Debris:AddItem(av, tempo or 0.4)
	return av
end

--- Empurra um HUMANOIDE. É `impulso` na raiz dele, e existe separado porque
--- personagem tem dono de rede próprio e o alvo é sempre a `HumanoidRootPart`.
local function empurrar(alvoHum, direcao, forca, tempo)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return end
	if direcao.Magnitude < 0.01 then return end
	impulso(alvoRaiz, direcao, forca, tempo or 0.2)
	vfx("EMPURRAO", {
		ponto = alvoRaiz.Position, direcao = direcao.Unit, forca = forca,
	})
end

--═══════════════════════════════════════════════════════════════
-- OS TRÊS PESOS DE QUEDA — e eles têm nome (TRIAGEM_FISICA, decisão #3)
--
--   `empurrar`  só desloca. O alvo continua de pé e no controle.
--   `tombar`    `PlatformStand`. Fica mole, juntas RÍGIDAS. Boneco de pau.
--   `desabar`   `BallSocketConstraint` por junta. O corpo desmonta de verdade.
--
-- `desabar` guarda `Enabled` de cada `Motor6D` e devolve AQUELE valor, nunca
-- `true` fixo. `BreakJoints` continua proibido — ragdoll sem volta é
-- `BreakJoints` com outro nome, e este SEMPRE volta: por prazo, e de novo no
-- `desmontar()`.
--═══════════════════════════════════════════════════════════════

local function tombar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum == humanoide then return end
	alvoHum.PlatformStand = true
	task.delay(tempo or 1.2, function()
		if alvoHum and alvoHum.Parent and alvoHum.Health > 0 then
			alvoHum.PlatformStand = false
		end
	end)
end

--- O blueprint R6 do `ragdoll-system` (MIT): seis juntas, quatro números cada.
--- Tabela de dados pura, do mesmo feitio que o `Poses.lua`.
local SOCKET = {
	["Neck"] = { atrito = 150, limite = 45, tw0 = -30, tw1 = 30 },
	["RootJoint"] = { atrito = 50, limite = 20, tw0 = 0, tw1 = 30 },
	["Right Shoulder"] = { atrito = 150, limite = 50, tw0 = -70, tw1 = 160 },
	["Left Shoulder"] = { atrito = 150, limite = 50, tw0 = -70, tw1 = 160 },
	["Right Hip"] = { atrito = 150, limite = 40, tw0 = -60, tw1 = 80 },
	["Left Hip"] = { atrito = 150, limite = 40, tw0 = -60, tw1 = 80 },
}

--- Quem está desabado agora, e o que precisa voltar. Chave fraca: se o
--- personagem for coletado, o registro vai junto.
local desabados = setmetatable({}, { __mode = "k" })

local function levantar(alvoHum)
	local reg = desabados[alvoHum]
	if not reg then return end
	desabados[alvoHum] = nil

	for _, s in ipairs(reg.sockets) do
		if s then s.Parent = nil end
	end
	for _, a in ipairs(reg.pontos) do
		if a then a.Parent = nil end
	end
	-- devolve o valor DE ANTES, não `true`
	for motor, ligado in pairs(reg.motores) do
		if motor and motor.Parent then motor.Enabled = ligado end
	end
	for peca, valor in pairs(reg.colide) do
		if peca and peca.Parent then peca.CanCollide = valor end
	end
	if alvoHum and alvoHum.Parent then
		alvoHum.PlatformStand = false
	end
end

local function levantarTodos()
	for alvoHum in pairs(desabados) do
		levantar(alvoHum)
	end
end

local function desabar(alvoHum, tempo)
	if not alvoHum or alvoHum.Health <= 0 then return end
	if alvoHum == humanoide then return end
	if desabados[alvoHum] then return end   -- guarda contra empilhar

	local corpo = alvoHum.Parent
	if not corpo then return end

	local reg = { sockets = {}, pontos = {}, motores = {}, colide = {} }

	for _, d in ipairs(corpo:GetDescendants()) do
		if d:IsA("Motor6D") and SOCKET[d.Name] and d.Part0 and d.Part1 then
			local cfg = SOCKET[d.Name]
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")
			a0.Name = PREFIXO .. "_Rag0"
			a1.Name = PREFIXO .. "_Rag1"
			a0.CFrame = d.C0
			a1.CFrame = d.C1
			a0.Parent = d.Part0
			a1.Parent = d.Part1

			local s = Instance.new("BallSocketConstraint")
			s.Name = PREFIXO .. "_Socket"
			s.Attachment0 = a0
			s.Attachment1 = a1
			s.LimitsEnabled = true
			s.TwistLimitsEnabled = true
			s.MaxFrictionTorque = cfg.atrito
			s.UpperAngle = cfg.limite
			s.TwistLowerAngle = cfg.tw0
			s.TwistUpperAngle = cfg.tw1
			s.Parent = d.Parent

			reg.motores[d] = d.Enabled
			d.Enabled = false
			table.insert(reg.sockets, s)
			table.insert(reg.pontos, a0)
			table.insert(reg.pontos, a1)
		elseif d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			reg.colide[d] = d.CanCollide
			d.CanCollide = true
		end
	end

	if #reg.sockets == 0 then
		-- rig sem os `Motor6D` esperados (R15, ou já desmontado): cai para o
		-- tombo, que sempre funciona. Melhor um tombo leve do que nada, e
		-- melhor do que forçar juntas que não existem.
		for peca, valor in pairs(reg.colide) do
			if peca and peca.Parent then peca.CanCollide = valor end
		end
		tombar(alvoHum, tempo)
		return
	end

	alvoHum.PlatformStand = true
	desabados[alvoHum] = reg
	task.delay(tempo or 2.0, function() levantar(alvoHum) end)
end

--═══════════════════════════════════════════════════════════════
-- AMARRAR — `RopeConstraint` (TRIAGEM_FISICA, decisão #4)
--
-- A corda não tem equivalente na família `BodyMover`, e é por isso que as 55
-- Tools que "puxam" hoje aproximam isso com `BodyPosition` em tique — o alvo
-- desliza em linha reta e para. Com corda ele CORRE, estica, e é puxado de
-- volta em arco.
--
-- Devolve a função que desamarra. Quem amarra é obrigado a guardá-la.
--═══════════════════════════════════════════════════════════════

local function amarrar(peca, ancora, comprimento, elasticidade)
	if not (peca and peca.Parent and ancora and ancora.Parent) then
		return function() end
	end
	if peca.Anchored then return function() end end

	local a0 = pontoDe(ancora, "Corda0")
	local a1 = pontoDe(peca, "Corda1")

	local corda = Instance.new("RopeConstraint")
	corda.Name = PREFIXO .. "_Corda"
	corda.Attachment0 = a0
	corda.Attachment1 = a1
	corda.Length = comprimento or 14
	corda.Restitution = elasticidade or 0.28
	corda.Visible = false
	corda.Parent = ancora

	local solto = false
	return function()
		if solto then return end
		solto = true
		if corda then corda.Parent = nil end
		if a1 and a1.Parent then a1.Parent = nil end
	end
end

--═══════════════════════════════════════════════════════════════
-- ATRAIR POR MASSA — `VectorForce`, o poço de gravidade
--
-- A origem usava `BodyPosition` com `maxForce = massa * 3000`, renovado a cada
-- 0.25 s. Isso PUXA PARA UM PONTO com força de mola: a peça chega, para, e
-- fica parada no centro como se estivesse colada.
--
-- Poço de verdade não faz isso. Ele acelera, e a peça PASSA do centro e volta.
-- `VectorForce` dá a aceleração; o resto é o solver. E a queda com a distância
-- é o que faz o efeito ter borda em vez de recortar num raio seco.
--═══════════════════════════════════════════════════════════════

local function atrairPeca(peca, centro, forca, raio)
	if not (peca and peca.Parent) then return nil end
	if peca.Anchored or ehMinha(peca) then return nil end

	local delta = centro - peca.Position
	local dist = delta.Magnitude
	if dist < 0.4 or dist > raio then return nil end

	-- queda LINEAR até a borda: 1 no centro, 0 na borda. Inverso do quadrado
	-- daria força enorme perto do centro, e a peça sairia disparada — que é o
	-- oposto do que um poço deve parecer.
	local queda = 1 - (dist / raio)
	local a = pontoDe(peca, "Poco")
	local vf = peca:FindFirstChild(PREFIXO .. "_VF")
	if not vf then
		vf = Instance.new("VectorForce")
		vf.Name = PREFIXO .. "_VF"
		vf.Attachment0 = a
	end
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.ApplyAtCenterOfMass = true
	vf.Force = delta.Unit * (math.max(peca.AssemblyMass, 0.1) * forca * queda)
	vf.Parent = peca
	return vf
end

--- As peças SOLTAS num raio. Não personagens (esses vão por `alvosEm`, e pela
--- raiz, para nunca puxar um membro), não ancoradas, e nunca as minhas.
---
--- ⛔ A ORIGEM VARRIA `workspace:GetDescendants()` RECURSIVAMENTE, a cada
---    0.25 s, durante 3.5 s. Num mapa de verdade isso é o place inteiro
---    quatorze vezes. `GetPartBoundsInRadius` faz a mesma pergunta ao
---    broadphase, que é para isso que ele existe.
local function pecasEm(centro, raio, limite)
	local achadas = {}
	local filtro = OverlapParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }
	for _, peca in ipairs(workspace:GetPartBoundsInRadius(centro, raio, filtro)) do
		local modelo = peca:FindFirstAncestorOfClass("Model")
		local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
		if not hum and not peca.Anchored and not ehMinha(peca) then
			table.insert(achadas, peca)
			if limite and #achadas >= limite then break end
		end
	end
	return achadas
end

--═══════════════════════════════════════════════════════════════
-- SEGURAR — `AlignPosition` + `AlignOrientation`, a garra
--
-- É a mecânica da `Physics Gun` da origem, e é a única coisa dela que valia a
-- pena: pegar uma peça solta e mantê-la a uma distância do cano, seguindo o
-- mouse. O que muda é que aqui ela tem PESO.
--
--   `ForceLimitMode = Magnitude` + `MaxForce ∝ massa` — a peça pesada chega
--   atrasada, balança, e bate nas coisas no caminho. A `Responsiveness` baixa
--   é o que dá o balanço; a origem punha `P` alto justamente para tirá-lo.
--═══════════════════════════════════════════════════════════════

local function segurar(peca, alvo)
	if not (peca and peca.Parent) then return nil end
	local massa = math.max(peca.AssemblyMass, 0.1)

	local a = pontoDe(peca, "Garra")
	local ap = peca:FindFirstChild(PREFIXO .. "_AP")
	if not ap then
		ap = Instance.new("AlignPosition")
		ap.Name = PREFIXO .. "_AP"
		ap.Attachment0 = a
		ap.Mode = Enum.PositionAlignmentMode.OneAttachment
		ap.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		ap.ApplyAtCenterOfMass = true
		ap.Parent = peca
	end
	ap.MaxForce = massa * CFG.FORCA_POR_MASSA * 4
	ap.Responsiveness = math.clamp(60 / (1 + massa * 0.35), 6, 45)
	ap.Position = alvo

	local ao = peca:FindFirstChild(PREFIXO .. "_AO")
	if not ao then
		ao = Instance.new("AlignOrientation")
		ao.Name = PREFIXO .. "_AO"
		ao.Attachment0 = a
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Parent = peca
	end
	ao.MaxTorque = massa * CFG.TORQUE_POR_MASSA * 3
	ao.Responsiveness = 12
	return ap
end

--═══════════════════════════════════════════════════════════════
-- PROJÉTIL — o método do FastCast, em doze linhas
--
-- A bala NÃO é uma `Part` física. É um ponto integrado à mão, e entre dois
-- passos vai um RAYCAST. O que se vê é cosmético, desenhado pelo cliente.
--
--   pos' = pos + v*dt + 0.5*a*dt²        v' = v + a*dt
--
-- ⛔ POR QUE ISTO E NÃO `Velocity = dir * 200`, QUE É O QUE A ORIGEM FAZIA:
--    a 60 Hz, 200 studs/s é um salto de 3,3 studs por quadro. Parede fina de
--    2 studs: a bala está de um lado num quadro e do outro no seguinte, e o
--    `Touched` nunca dispara. O raio cobre o trecho inteiro, então não há
--    como atravessar.
--
-- `aoBater` devolve `true` para PARAR e `false` para QUICAR. É o que dá o
-- ricochete da `ClassicSuperball` da origem sem uma peça física no meio.
--═══════════════════════════════════════════════════════════════

--- Balística fechada (roPhysics): o ângulo que faz o tiro cair no alcance.
--- Devolve `nil` se o alcance for maior do que a velocidade permite.
local function anguloParaAlcance(velocidade, alcance)
	local s = (gravidade() * alcance) / (velocidade * velocidade)
	if s > 1 or s < -1 then return nil end
	return math.asin(s) * 0.5
end

local function dispararProjetil(origem, direcao, velocidade, opcoes)
	opcoes = opcoes or {}
	local pos = origem
	local vel = direcao.Unit * velocidade
	local acel = opcoes.aceleracao or Vector3.new(0, -gravidade(), 0)
	local quiques = opcoes.quiques or 0
	local vida = opcoes.vida or 4
	local raioBala = opcoes.raio or 0.4

	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem, Tool }

	local passado = 0
	local passos = 0
	local conexao
	conexao = RunService.Heartbeat:Connect(function(dt)
		passos = passos + 1
		passado = passado + dt
		if passado >= vida or passos > CFG.PASSOS_MAX then
			conexao:Disconnect()
			if opcoes.aoFim then opcoes.aoFim(pos) end
			return
		end

		local adiante = pos + vel * dt + acel * (dt * dt * 0.5)
		local delta = adiante - pos
		local batida = nil
		if delta.Magnitude > 0.001 then
			batida = workspace:Raycast(pos, delta, filtro)
		end

		if batida then
			local parar = true
			if opcoes.aoBater then
				parar = opcoes.aoBater(batida, vel, quiques)
			end
			if parar or quiques <= 0 then
				conexao:Disconnect()
				if opcoes.aoFim then opcoes.aoFim(batida.Position) end
				return
			end
			-- REFLEXÃO: v' = v - 2(v·n)n, com perda por quique
			quiques = quiques - 1
			local n = batida.Normal
			vel = (vel - n * (2 * vel:Dot(n))) * (opcoes.perda or 0.86)
			pos = batida.Position + n * raioBala
		else
			pos = adiante
			vel = vel + acel * dt
		end

		if opcoes.aoAndar then opcoes.aoAndar(pos, vel) end
	end)
	guardar(conexao)
	return conexao
end


--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — tabela de keyframe no lugar da escada
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end


--══════════════════════════════════════════════════════════════
-- M1 — o feixe de órbita
--
-- Três tempos, e o do meio é o que importa: MARCA · espera · FEIXE.
--
-- ⛔ NADA AQUI É `Instance.new("Explosion")`. A instância nativa quebra junta
--    (`DestroyJointRadiusPercent`) e derruba geometria do mapa, que são as
--    duas coisas proibidas neste conjunto. A onda é feita à mão, e ela empurra
--    proporcional à MASSA de cada coisa — caixote voa, prédio ancorado não.
--══════════════════════════════════════════════════════════════

--- A onda: empurra para FORA, com a força caindo com a distância.
---
--- Personagem vai pela raiz (nunca por membro, que é como se arranca braço);
--- peça solta vai por `impulso`, com a massa dela mandando no resultado.
local function onda(centro)
	for _, alvo in ipairs(alvosEm(centro, CFG.RAIO, 12)) do
		local alvoRaiz = raizDe(alvo)
		if alvoRaiz then
			local delta = alvoRaiz.Position - centro
			local dist = math.max(delta.Magnitude, 0.5)
			local queda = math.clamp(1 - (dist / CFG.RAIO), 0.15, 1)
			local para = (delta.Unit + Vector3.new(0, 0.7, 0)).Unit

			aplicarDano(alvo, math.floor(CFG.DANO * queda + 0.5))
			empurrar(alvo, para, CFG.ONDA * queda, 0.3)
			desabar(alvo, CFG.DESABA)
		end
	end

	for _, peca in ipairs(pecasEm(centro, CFG.RAIO, CFG.TETO_PECAS)) do
		local delta = peca.Position - centro
		local dist = math.max(delta.Magnitude, 0.5)
		local queda = math.clamp(1 - (dist / CFG.RAIO), 0.1, 1)
		impulso(peca, (delta.Unit + Vector3.new(0, 0.5, 0)).Unit,
			CFG.ONDA_PECA * queda, 0.35)
		giro(peca, Vector3.new(jitter(1), jitter(2), jitter(3)), 6, 0.6)
	end
end

--- O feixe DESCE por raycast, e para no primeiro teto.
---
--- A origem punha o dano na posição mirada e pronto. Com raycast, quem está
--- debaixo de uma laje não leva — que é a diferença entre uma ultimate e uma
--- planilha de dano.
local function pousoDoFeixe(alvo)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	filtro.FilterDescendantsInstances = { personagem }
	local batida = workspace:Raycast(alvo + Vector3.new(0, CFG.ALTURA, 0),
		Vector3.new(0, -(CFG.ALTURA + 40), 0), filtro)
	return batida and batida.Position or alvo
end

function primaria(mira)
	if not (rig and raiz) then return end
	local alvo = noChao(typeof(mira) == "Vector3" and mira or frente(40))

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		CHAMA = { sfx = { "CHAMADA", 1 } },

		MARCA = {
			sfx = { "CARGA", 1 },
			faz = function()
				vfx("MARCA", { ponto = alvo, raio = CFG.RAIO,
					vida = CFG.ESPERA })
			end,
		},

		FEIXE = {
			sfx = { "FEIXE", 0.92 },
			faz = function()
				task.delay(CFG.ESPERA, function()
					if not (personagem and personagem.Parent) then return end
					local pouso = pousoDoFeixe(alvo)
					vfx("FEIXE", { ponto = pouso, raio = CFG.RAIO })
					tocarEm("ECO", pouso, 0.88)
					onda(pouso)
				end)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma habilidade, e ela é no clique
--
-- Sem `AcaoRemote`, sem tecla, sem Extra. O `acao` do `VFXRemote` só existe
-- porque a `Arma de Fisica` precisa distinguir o botão DESCENDO do botão
-- SUBINDO, e as duas coisas são o mesmo clique.
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira, acao)
	if quem ~= jogador then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not podeAgir() then return end
	if not pronto(ultimoUso, CFG.RECARGA) then return end
	ultimoUso = os.clock()
	primaria(mira)
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "CanhaoSatelite", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
end)

--- AS DUAS PORTAS, e a terceira coisa que elas fazem: DEVOLVER O QUE FOI
--- MEXIDO. `Unequipped` sozinho não cobre a Tool ser destruída com uma peça
--- ainda presa na garra, e peça com `AlignPosition` órfã fica puxando para um
--- ponto no vazio até o servidor cair. Alvo desabado idem: ragdoll cuja Tool
--- sumiu é ragdoll permanente, que é `BreakJoints` com outro nome.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	levantarTodos()
	if rig then
		rig:CancelSequence()
		rig:ReleaseLegs()
		rig:LockCharacter(false)
		rig:Destroy()
		rig = nil
	end
end

Tool.Unequipped:Connect(desmontar)
Tool.Destroying:Connect(desmontar)

--═══════════════════════════════════════════════════════════════
-- O DEPÓSITO (Regra nº 2)
--
-- Ao chegar ao jogador — mochila OU mão —, os moldes vão para
-- `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta CRIA ou REUTILIZA, e
-- NINGUÉM a apaga: ela é do MODELO, e outro jogador pode estar com a irmã.
--═══════════════════════════════════════════════════════════════

Deposito.ligar(Tool)
