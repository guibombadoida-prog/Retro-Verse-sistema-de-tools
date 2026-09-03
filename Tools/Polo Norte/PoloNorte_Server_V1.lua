-- PoloNorte_Server_V1.lua
-- Script de servidor — Polo Norte  (conjunto MAGNETISMO)
--
--   M1   puxa o que está no cone, e carrega de NORTE
--   R    a cúpula que suga tudo que entrar   (Extra 1)
--   T    implode o ponto mirado   (Extra 2)
--
-- CONJUNTO AUTORAL — o quinto. Não sai de modelo nenhum: a geometria é
-- primitiva soldada, e os SoundId saem do catálogo do Acervo (id de som não se
-- inventa: id chutado é som mudo que nenhum verificador estático pega).
--
--═══════════════════════════════════════════════════════════════
-- O QUE ESTE CONJUNTO TEM QUE NENHUM OUTRO TINHA
--═══════════════════════════════════════════════════════════════
--
--   1. POLARIDADE, e ela ATRAVESSA as sete Tools. Quem é atingido fica
--      carregado NORTE ou SUL por um prazo, e a carga mede o que as outras
--      seis fazem com ele: mesma polaridade repele mais forte, oposta atrai
--      mais forte. É o primeiro conjunto do repositório em que uma Tool
--      depende do que outra fez.
--
--   2. GRUPO DE VARIAÇÃO DE SFX. `Tool/SFX/<PAPEL>` é uma `Folder` quando há
--      mais de uma gravação, e `tocar()` sorteia com peso. A `Bobina de Tesla`
--      tem SEIS gravações de raio no `ARCO`.
--
--   3. `quando` no keyframe: o beat cai no MEIO do passo, não na borda.
--
--   Os três saem de FERRAMENTAS/TRIAGEM_VFX_SFX_ANIMACAO_CUTSCENE.md.
--
-- ONDE O EFEITO APARECE: EM TODO MUNDO. `VFXRemote:FireAllClients`, e o
-- `Client` é `Script` com `RunContext = Client`.
--
-- Gerado por FERRAMENTAS/gerar_servers_magnetismo.py. Editar aqui à mão faz as
-- sete derivarem; edite o gerador.

local Players    = game:GetService("Players")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Tool       = script.Parent
local Handle     = Tool:WaitForChild("Handle")
local VFXRemote  = Tool:WaitForChild("VFXRemote")
local AcaoRemote = Tool:WaitForChild("AcaoRemote")
local Poses      = require(Tool:WaitForChild("Poses"))
local Animator   = require(Tool:WaitForChild("R6CFrameAnimator"))
local Deposito   = require(Tool:WaitForChild("DepositoVFX"))

--═══════════════════════════════════════════════════════════════
-- CFG — número mágico espalhado pelo corpo é violação
--═══════════════════════════════════════════════════════════════

local ARQUETIPO = "Norte"

local CFG = {
	--- Força por unidade de massa, e ela é FINITA. `BodyPosition` com
	--- `maxForce` infinito arrasta um prédio como arrasta um cubo, e por isso
	--- nada feito com ele tem peso.
	FORCA_POR_MASSA = 260,
	TORQUE_POR_MASSA = 90,
	G_PADRAO = 196.2,
	PASSOS_MAX = 600,

	--- POLARIDADE — quanto a carga muda a força.
	---
	--- Mesma polaridade repele; oposta atrai. Os dois bônus são maiores que 1
	--- porque a carga tem de RECOMPENSAR quem montou a combinação: sem isso
	--- ela é enfeite, e ninguém troca de Tool para usá-la.
	CARGA_DURA = 8.0,
	BONUS_IGUAL = 1.55,
	BONUS_OPOSTO = 1.75,

	--- Teto de peças de servidor SIMULTÂNEAS desta Tool. Sem ele um jogador
	--- assenta trinta trilhos e todos ficam.
	TETO_PECAS = 10,

	RECARGA = 0.9,
	RECARGA_R = 15,
	RECARGA_T = 26,

	DANO = 14,
	ALCANCE = 26,
	--- cos(42°) — o cone de atração é mais fechado que o de empurrão: puxar
	--- para si o que está ao lado colocaria o alvo às suas costas.
	COSSENO = 0.74,
	LIMITE = 6,
	PUXAO = 62,

	CUPULA_RAIO = 22,
	CUPULA_VIDA = 2.0,
	CUPULA_FORCA = 190,
	CUPULA_PERIODO = 0.18,
	CUPULA_DANO = 5,

	IMPLOSAO_RAIO = 18,
	IMPLOSAO_DANO = 48,
	IMPLOSAO_PUXAO = 120,
	TETO_ATRAIDAS = 26,
	DESABA = 1.8,

}

--═══════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════

local jogador, personagem, humanoide, raiz, rig
local ultimoPrimaria, ultimoR, ultimoT = 0, 0, 0
local ocupado = false
local ativos = {}
local semente = 0
local idEfeito = 0
local passeAtual = 0

--- Declaradas aqui e atribuídas mais abaixo: `local x` seguido de
--- `function x()` atribui ao local, e sem isso as três virariam globais.
local primaria, extraR, extraT
local atraidas = {}

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
-- SOM — GRUPO DE VARIAÇÃO
--
-- `Tool/SFX/TAPA` pode ser um `Sound` (como sempre) OU uma `Folder` com
-- vários. Se for `Folder`, sorteia com peso (`NumberValue` "Weight").
--
-- O SORTEIO É NO SERVIDOR, e é o único lugar onde pode ser: `tocar()` clona e
-- parenteia no `Handle` PELO SERVIDOR, então a INSTÂNCIA replica e todo mundo
-- ouve a mesma. Cliente sorteando = duas pessoas ouvindo sons diferentes para
-- o mesmo golpe.
--═══════════════════════════════════════════════════════════════

local function sortearNoGrupo(pasta)
	local candidatos, total = {}, 0
	for _, filho in ipairs(pasta:GetChildren()) do
		if filho:IsA("Sound") then
			local w = filho:FindFirstChild("Weight")
			local peso = 1
			if w and w:IsA("NumberValue") and w.Value > 0 then peso = w.Value end
			table.insert(candidatos, { som = filho, peso = peso })
			total = total + peso
		end
	end
	if #candidatos == 0 then return nil end
	if #candidatos == 1 then return candidatos[1].som end

	local sorteio = math.random() * total
	for _, c in ipairs(candidatos) do
		if sorteio < c.peso then return c.som end
		sorteio = sorteio - c.peso
	end
	--- ⚠️ Não é paranoia: `math.random() * total` pode sobrar por
	---    arredondamento e cair fora do laço. A implementação de onde a ideia
	---    veio devolve `nil` aí — um som mudo, calado, de vez em quando.
	return candidatos[#candidatos].som
end

local function acharSom(onde, nome)
	local achado = onde and onde:FindFirstChild(nome)
	if not achado then return nil end
	if achado:IsA("Sound") then return achado end
	if achado:IsA("Folder") then return sortearNoGrupo(achado) end
	return nil
end

local function somDe(nome)
	return acharSom(Tool:FindFirstChild("SFX"), nome)
		or acharSom(Handle, nome)
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
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
	som.PlaybackSpeed = pitch or som.PlaybackSpeed or 1
	som.Parent = ancora
	som:Play()

	Debris:AddItem(ancora, corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- A GUARDA — O QUE É MEU NÃO É ALVO
--
-- Toda função abaixo consulta ESTA, e nenhuma repete a checagem. Filtro
-- copiado é um lugar a mais para esquecer, e num conjunto que ATRAI esquecer
-- significa o jogador se puxar para dentro do próprio campo.
--═══════════════════════════════════════════════════════════════

local function ehMinha(inst)
	if not inst then return true end
	if personagem and inst:IsDescendantOf(personagem) then return true end
	if inst:IsDescendantOf(Tool) then return true end
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
--- sem ele, um campo para a frente pega quem está atrás de quem o abriu.
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
-- 🧲 A POLARIDADE — o eixo que atravessa as sete Tools
--
-- Nenhum conjunto anterior tem uma mecânica em que uma Tool depende do que
-- OUTRA fez. Esta tem, e é a razão de o conjunto existir como conjunto em vez
-- de sete Tools soltas com o mesmo tema.
--
-- ONDE A CARGA MORA, E POR QUE ALI
--
--   Num `Attribute` do `Humanoid` do alvo. Não é depósito de asset e não é
--   global: é marca de ENTIDADE EM CAMPO, a mesma natureza e o mesmo lugar da
--   tag `creator` que o repositório já usa para creditar abate. Escrever no
--   mundo é saída, e a regra nº 1 sempre permitiu.
--
--   As sete Tools leem e escrevem os MESMOS dois atributos, e isso é de
--   propósito: é o que faz a combinação existir. Nenhuma delas precisa
--   alcançar a outra — elas se falam através do alvo.
--
-- E ELA VENCE
--
--   `RV_MagPolExpira` guarda o `os.clock()` do fim, e quem lê confere antes de
--   acreditar. Marca que não vence é modificador permanente, e isso é a mesma
--   família do ragdoll que não volta.
--═══════════════════════════════════════════════════════════════

local ATRIB_POLO = "RV_MagPolaridade"
local ATRIB_ATE = "RV_MagPolExpira"

--- A polaridade VÁLIDA de um alvo, ou `nil`. Vencida conta como `nil`, e o
--- atributo é limpo na hora — atributo velho pendurado num jogador é dado
--- errado esperando alguém acreditar nele.
local function polaridadeDe(alvoHum)
	if not (alvoHum and alvoHum.Parent) then return nil end
	local polo = alvoHum:GetAttribute(ATRIB_POLO)
	if polo ~= "NORTE" and polo ~= "SUL" then return nil end
	local ate = alvoHum:GetAttribute(ATRIB_ATE)
	if type(ate) ~= "number" or os.clock() > ate then
		alvoHum:SetAttribute(ATRIB_POLO, nil)
		alvoHum:SetAttribute(ATRIB_ATE, nil)
		return nil
	end
	return polo
end

--- Carrega o alvo. Recarregar RENOVA o prazo — carga não empilha em força,
--- só em duração, senão bater dez vezes viraria dano multiplicado por dez.
local function carregar(alvoHum, polo, ponto)
	if not (alvoHum and alvoHum.Parent) or alvoHum == humanoide then return end
	if polo ~= "NORTE" and polo ~= "SUL" then return end
	alvoHum:SetAttribute(ATRIB_POLO, polo)
	alvoHum:SetAttribute(ATRIB_ATE, os.clock() + CFG.CARGA_DURA)
	local alvoRaiz = raizDe(alvoHum)
	vfx("CARGA", {
		ponto = ponto or (alvoRaiz and alvoRaiz.Position) or Vector3.new(),
		polaridade = polo,
	})
end

--- O MULTIPLICADOR. `meu` é a polaridade que ESTA habilidade emite.
---
---   igual   → repele → o EMPURRÃO ganha bônus
---   oposto  → atrai  → o PUXÃO ganha bônus
---   nenhuma → 1
---
--- `atraindo` diz o que a habilidade está fazendo, e é o que decide qual dos
--- dois bônus vale. Sem esse parâmetro, uma habilidade de atração ganharia
--- bônus por repulsão, que é o oposto do que a física diz.
local function fatorDe(alvoHum, meu, atraindo)
	local dele = polaridadeDe(alvoHum)
	if not dele then return 1 end
	local igual = (dele == meu)
	if atraindo then
		return igual and 1 or CFG.BONUS_OPOSTO
	end
	return igual and CFG.BONUS_IGUAL or 1
end

--- Todos os carregados num raio, com a polaridade de cada um. É o que a
--- `Bobina de Tesla` e o `Colapso Magnetico` consomem.
local function carregadosEm(ponto, raio, limite)
	local achados = {}
	for _, alvo in ipairs(alvosEm(ponto, raio, (limite or 10) * 2)) do
		local polo = polaridadeDe(alvo)
		if polo then
			table.insert(achados, { hum = alvo, polo = polo })
			if #achados >= (limite or 10) then break end
		end
	end
	return achados
end

--- Descarrega TODOS os que esta Tool carregou. Chamado no `desmontar()`.
---
--- Sem isto, um jogador guarda a Tool e o alvo fica com carga fantasma por
--- oito segundos — e a carga muda o que as outras seis Tools fazem com ele.
--- Efeito de status que sobrevive a quem o aplicou é a mesma família do
--- ragdoll que não volta.
local carregados = setmetatable({}, { __mode = "k" })

local function descarregarTudo()
	for alvoHum in pairs(carregados) do
		if alvoHum and alvoHum.Parent then
			alvoHum:SetAttribute(ATRIB_POLO, nil)
			alvoHum:SetAttribute(ATRIB_ATE, nil)
		end
	end
	table.clear(carregados)
end

--- O `carregar` que ANOTA, e é o que as habilidades usam.
local function marcar(alvoHum, polo, ponto)
	carregar(alvoHum, polo, ponto)
	if alvoHum and polaridadeDe(alvoHum) then
		carregados[alvoHum] = true
	end
end


--═══════════════════════════════════════════════════════════════
-- O REGISTRO — TUDO QUE É POSTO NO MUNDO É RECOLHIDO
--
-- Quatro das sete Tools põem `Part` DE SERVIDOR no mundo: o trilho, a bobina,
-- a bola de sucata e a malha. Peça de servidor que fica é lixo permanente no
-- mapa, e `Instance.new` + `Debris:AddItem` NÃO basta — o `Debris` não roda se
-- a thread morrer antes de chamá-lo, e a Tool destruída no meio deixa o
-- trilho no chão até o servidor cair.
--
-- Nada é posto fora de `criar()`. O registro tem TETO e TRÊS saídas: o prazo,
-- o `Unequipped` e o `Destroying`. É o mesmo desenho do conjunto CRIAÇÃO, que
-- foi o primeiro a precisar dele.
--═══════════════════════════════════════════════════════════════

local criadas = {}

local function recolher(reg)
	if not reg then return end
	if reg.peca and reg.peca.Parent then
		reg.peca.CanCollide = false
		reg.peca.Parent = nil
	end
	reg.peca = nil
end

local function recolherTudo()
	for _, reg in ipairs(criadas) do
		recolher(reg)
	end
	table.clear(criadas)
end

--- Põe uma peça no mundo e a REGISTRA. Única porta.
---
--- `ancorada = false` é para o que tem de ser movido por constraint (a bola de
--- sucata). Peça ancorada cujo `CFrame` o servidor escreve por quadro replica
--- a ~20 Hz e SEM interpolação — é a proibição "servidor não move geometria
--- por frame", e é por isso que a bola é solta e puxada, nunca teleportada.
local function criar(quadro, tamanho, props, vida, ancorada)
	while #criadas >= CFG.TETO_PECAS do
		recolher(table.remove(criadas, 1))
	end

	local p = Instance.new("Part")
	p.Anchored = (ancorada ~= false)
	p.CanCollide = true
	p.CanQuery = true
	p.CastShadow = false
	p.Size = tamanho
	p.CFrame = quadro
	p.Material = Enum.Material.Metal
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace

	local reg = { peca = p, ate = os.clock() + vida }
	table.insert(criadas, reg)
	task.delay(vida, function()
		local i = table.find(criadas, reg)
		if i then
			table.remove(criadas, i)
			recolher(reg)
		end
	end)
	return p
end

--- O VIGIA. Cada peça tem prazo próprio e o `task.delay` do `criar` o cobra no
--- caso normal; este laço é a rede embaixo, para quando a thread morrer.
local function vigiar()
	guardar(RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		local i = #criadas
		while i >= 1 do
			local reg = criadas[i]
			if agora > reg.ate then
				table.remove(criadas, i)
				recolher(reg)
			end
			i = i - 1
		end
	end))
end

--- Esta Tool NÃO tem cutscene. `beatCena` é `nil` DECLARADO — não global
--- implícito — e a guarda `kf.cam and beatCena` do despachante resolve sem
--- nenhum acesso a global.
local beatCena = nil

--═══════════════════════════════════════════════════════════════
-- O DESPACHANTE DE BEAT — com `quando`
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` NO INÍCIO do
-- passo, antes de o tween começar (conferido no `R6CFrameAnimator`: o
-- `if onBeat then` vem antes do `TweenService:Create`).
--
-- Então `kf.quando` — a fração do passo — é um ATRASO de `time * quando`.
--
-- ⚙️ Este é o primeiro despachante do repositório a implementar isso, e é o
--    achado nº 4 da triagem. Até aqui a marca só podia cair na BORDA de um
--    passo: um som que devia tocar no meio de um quadro de 0.9 s virava um
--    passo extra só para ter onde ser pendurado.
--
--    E o beat ANDA JUNTO com a duração. Mudou o passo de 0.9 para 0.6 e a
--    marca acompanha, porque ela é fração e não segundo.
--
-- ⚠️ O ATRASO PRECISA DE TOKEN. `task.delay` sobrevive ao cancelamento da
--    sequência: sem o `passe`, trocar de habilidade no meio faria o beat da
--    anterior disparar em cima da nova. `passeAtual` sobe a cada sequência, e
--    o disparo confere.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

local function despachar(quadros)
	passeAtual = passeAtual + 1
	local meuPasse = passeAtual

	local function disparar(kf, passo)
		if meuPasse ~= passeAtual then return end
		if not (personagem and personagem.Parent) then return end
		if kf.cam and beatCena then beatCena(passo.marca, kf.ponto) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end

	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end

		local atraso = 0
		if type(passo) == "table" and passo.quando and passo.time then
			atraso = passo.time * math.clamp(passo.quando, 0, 1)
		end
		if atraso <= 0 then
			disparar(kf, passo)
		else
			task.delay(atraso, function() disparar(kf, passo) end)
		end
	end
end


--══════════════════════════════════════════════════════════════
-- O PÓLO DESTA TOOL
--══════════════════════════════════════════════════════════════

local MEU_POLO = "NORTE"

--- Devolve toda peça que este campo pendurou. Chamado no fim de cada campo E
--- no `desmontar()`: `VectorForce` órfã é uma peça sendo puxada para um ponto
--- onde não há mais nada, para sempre.
local function liberarAtraidas()
	for _, peca in ipairs(atraidas) do
		if peca and peca.Parent then soltarPeca(peca) end
	end
	table.clear(atraidas)
end

local function anotarPeca(peca)
	for _, p in ipairs(atraidas) do
		if p == peca then return end
	end
	table.insert(atraidas, peca)
end

--- Puxa um humanoide PARA UM PONTO, com o bônus da polaridade.
---
--- `fatorDe(alvo, MEU_POLO, true)` — o `true` é "estou ATRAINDO", e é o que
--- faz o bônus certo valer: carga oposta atrai mais forte, carga igual não.
--- Sem esse parâmetro a habitação de atração ganharia bônus por repulsão.
local function puxarPara(alvoHum, centro, forca)
	local alvoRaiz = raizDe(alvoHum)
	if not alvoRaiz or ehMinha(alvoRaiz) then return 0 end
	local delta = centro - alvoRaiz.Position
	if delta.Magnitude < 0.6 then return 0 end
	local f = fatorDe(alvoHum, MEU_POLO, true)
	empurrar(alvoHum, delta.Unit, forca * f, 0.24)
	return f
end

--══════════════════════════════════════════════════════════════
-- M1 — puxar
--══════════════════════════════════════════════════════════════

function primaria(mira)
	if not (rig and raiz) then return end

	ocupado = true
	rig:PlaySequence("PRIMARIA", despachar({

		PUXAR = {
			sfx = { "PUXAR", 1 },
			faz = function()
				if not raiz then return end
				local direcao = raiz.CFrame.LookVector
				if typeof(mira) == "Vector3" then
					local delta = mira - raiz.Position
					if delta.Magnitude > 1 then direcao = delta.Unit end
				end
				local para = raiz.Position + direcao * 3

				vfx("PUXAR", { ponto = para, eixo = direcao,
					raio = CFG.ALCANCE * 0.5 })

				for _, alvo in ipairs(alvosNoCone(raiz.Position, direcao,
						CFG.ALCANCE, CFG.COSSENO, CFG.LIMITE)) do
					local f = puxarPara(alvo, para, CFG.PUXAO)
					aplicarDano(alvo, math.floor(CFG.DANO * f + 0.5))
					marcar(alvo, MEU_POLO)
				end

				-- e as peças SOLTAS do mapa vêm junto. Nada é destruído: o que
				-- acontece com elas é uma `VectorForce`, e `soltarPeca` a tira.
				for _, peca in ipairs(pecasEm(para, CFG.ALCANCE * 0.6,
						CFG.TETO_ATRAIDAS)) do
					if atrairPeca(peca, para, CFG.PUXAO * 2.4,
							CFG.ALCANCE * 0.6) then
						anotarPeca(peca)
					end
				end
				task.delay(0.5, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- R — a cúpula
--
-- Ela não é um puxão maior: é um LUGAR. Fica aberta por 2 s e suga o que
-- ENTRAR nela, não só o que já estava — é o que faz dela uma armadilha em vez
-- de um golpe com raio grande.
--══════════════════════════════════════════════════════════════

function extraR(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(14))
		+ Vector3.new(0, 3, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_R", despachar({

		ABRE = { sfx = { "CUPULA", 1.1 } },

		CUPULA = {
			sfx = { "CUPULA", 0.9 },
			faz = function()
				vfx("CUPULA", { ponto = centro, raio = CFG.CUPULA_RAIO,
					vida = CFG.CUPULA_VIDA })
				tocarEm("CUPULA", centro, 0.85)

				local ate = os.clock() + CFG.CUPULA_VIDA
				local acumulado = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					acumulado = acumulado + dt
					if acumulado < CFG.CUPULA_PERIODO then return end
					acumulado = 0

					for _, alvo in ipairs(alvosEm(centro, CFG.CUPULA_RAIO, 10)) do
						puxarPara(alvo, centro, CFG.CUPULA_FORCA
							* CFG.CUPULA_PERIODO)
						marcar(alvo, MEU_POLO)
					end
					for _, peca in ipairs(pecasEm(centro, CFG.CUPULA_RAIO,
							CFG.TETO_ATRAIDAS)) do
						if atrairPeca(peca, centro, CFG.CUPULA_FORCA,
								CFG.CUPULA_RAIO) then
							anotarPeca(peca)
						end
					end
				end))

				-- o dano é LENTO: a cúpula não é um golpe, é um lugar de onde
				-- é difícil sair
				local tique = 0
				guardar(RunService.Heartbeat:Connect(function(dt)
					if os.clock() > ate then return end
					tique = tique + dt
					if tique < 1 then return end
					tique = 0
					for _, alvo in ipairs(alvosEm(centro, CFG.CUPULA_RAIO, 10)) do
						aplicarDano(alvo, CFG.CUPULA_DANO)
					end
				end))

				task.delay(CFG.CUPULA_VIDA, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--══════════════════════════════════════════════════════════════
-- T — a implosão
--══════════════════════════════════════════════════════════════

function extraT(mira)
	if not (rig and raiz) then return end
	local centro = noChao(typeof(mira) == "Vector3" and mira or frente(20))
		+ Vector3.new(0, 3, 0)

	ocupado = true
	rig:PlaySequence("EXTRA_T", despachar({

		CARREGA = { sfx = { "CUPULA", 1.25 } },

		IMPLOSAO = {
			sfx = { "IMPLOSAO", 0.9 },
			faz = function()
				vfx("IMPLOSAO", { ponto = centro, raio = CFG.IMPLOSAO_RAIO })
				tocarEm("IMPLOSAO", centro, 0.8)

				for _, alvo in ipairs(alvosEm(centro, CFG.IMPLOSAO_RAIO, 12)) do
					local f = puxarPara(alvo, centro, CFG.IMPLOSAO_PUXAO)
					aplicarDano(alvo, math.floor(CFG.IMPLOSAO_DANO * f + 0.5))
					marcar(alvo, MEU_POLO)
					desabar(alvo, CFG.DESABA)
				end

				for _, peca in ipairs(pecasEm(centro, CFG.IMPLOSAO_RAIO,
						CFG.TETO_ATRAIDAS)) do
					if atrairPeca(peca, centro, CFG.IMPLOSAO_PUXAO * 3,
							CFG.IMPLOSAO_RAIO) then
						anotarPeca(peca)
					end
				end
				task.delay(0.9, liberarAtraidas)
			end,
		},

	}), function()
		ocupado = false
	end)
end

--═══════════════════════════════════════════════════════════════
-- CICLO DE VIDA — uma primária e DUAS Extras
--═══════════════════════════════════════════════════════════════

local function pronto(quando, recarga)
	return os.clock() - quando >= recarga
end

local function podeAgir()
	if not (personagem and humanoide and raiz and rig) then return false end
	if humanoide.Health <= 0 then return false end
	return not ocupado
end

VFXRemote.OnServerEvent:Connect(function(quem, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end
	if not pronto(ultimoPrimaria, CFG.RECARGA) then return end
	ultimoPrimaria = os.clock()
	primaria(mira)
end)

--- As DUAS Extras chegam pelo MESMO remote. Qualquer coisa fora de "R" e "T"
--- é descartada sem resposta.
AcaoRemote.OnServerEvent:Connect(function(quem, tecla, mira)
	if quem ~= jogador or not podeAgir() then return end
	if typeof(mira) ~= "Vector3" then mira = frente() end

	if tecla == "R" then
		if not pronto(ultimoR, CFG.RECARGA_R) then return end
		ultimoR = os.clock()
		extraR(mira)
	elseif tecla == "T" then
		if not pronto(ultimoT, CFG.RECARGA_T) then return end
		ultimoT = os.clock()
		extraT(mira)
	end
end)

Tool.Equipped:Connect(function()
	personagem = Tool.Parent
	humanoide  = personagem and personagem:FindFirstChildOfClass("Humanoid")
	raiz       = personagem and personagem:FindFirstChild("HumanoidRootPart")
	jogador    = personagem and Players:GetPlayerFromCharacter(personagem)
	if not (personagem and humanoide and raiz) then return end

	rig = Animator.new(personagem, "PoloNorte", Poses,
		Poses.SEQUENCIAS, Poses.TRACKS)
	vigiar()
end)

--- AS DUAS PORTAS, e a terceira coisa que elas fazem: DESCARREGAR.
---
--- Carga que sobrevive a quem a aplicou é modificador permanente num jogador
--- que não tem como tirá-lo — a mesma família do ragdoll que não volta. Some
--- a isso o `passeAtual`, que invalida qualquer beat atrasado ainda na fila.
local function desmontar()
	for _, c in ipairs(ativos) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(ativos)
	ocupado = false
	passeAtual = passeAtual + 1
	descarregarTudo()
	recolherTudo()
	levantarTodos()
	liberarAtraidas()
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
