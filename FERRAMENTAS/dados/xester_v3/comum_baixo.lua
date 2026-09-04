-- Com todos os clientes desenhando, um sorteio faria cada um ver uma cena
-- diferente, o que lê como lag. O ângulo áureo (137.507764°) nunca repete
-- alinhamento, então o que se espalha por ele nunca fica empilhado.
--═══════════════════════════════════════════════════════════════

local function proximo()
	semente = semente + 1
	if semente > 100000 then semente = 1 end
	return semente
end

local function anguloDe(indice)
	return (indice or proximo()) * 2.399963
end

local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function naFaixa(minimo, maximo)
	local onda = (jitter(0.7) + 1) * 0.5
	return minimo + (maximo - minimo) * onda
end

local function vfx(tipo, dados)
	VFXRemote:FireAllClients(tipo, dados)
end

local function apagarEfeito(id)
	if id then vfx("APAGAR", { id = id }) end
end

local function novoId(prefixo)
	idEfeito = idEfeito + 1
	return prefixo .. "_" .. tostring(idEfeito)
end

local function guardar(conexao)
	table.insert(ativos, conexao)
	return conexao
end

--- Avança a geração de uma habilidade e devolve a nova. Quem roda um laço
--- guarda o valor e compara antes de cada passo.
local function novaGeracao(chave)
	geracao[chave] = (geracao[chave] or 0) + 1
	return geracao[chave]
end

--═══════════════════════════════════════════════════════════════
-- SOM — sempre numa âncora própria, nunca na peça que o pediu
--
-- Um `Sound` só toca enquanto tem pai no DataModel. Pendurar o som na peça que
-- some no quadro seguinte mata o som no quadro em que ele nasce.
--═══════════════════════════════════════════════════════════════

local function somDe(nome)
	local pasta = Tool:FindFirstChild("SFX")
	local achado = pasta and pasta:FindFirstChild(nome)
	if achado and achado:IsA("Sound") then return achado end
	return nil
end

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
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = ancora
	som:Play()
	Debris:AddItem(ancora,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

local function tocar(nome, pitch, corte)
	local base = somDe(nome)
	if not base then return nil end
	local som = base:Clone()
	som.PlaybackSpeed = pitch or base.PlaybackSpeed
	som.Parent = Handle
	som:Play()
	Debris:AddItem(som,
		corte or ((som.TimeLength > 0 and som.TimeLength or 4) + 1))
	return som
end

--═══════════════════════════════════════════════════════════════
-- O BEAT VEM COMO KEYFRAME, NÃO COMO STRING
--
-- `Animator:PlaySequence(seq, onBeat)` chama `onBeat(kf, indice)` — `kf` é a
-- TABELA do passo, e a marca está em `kf.marca`. Comparar o keyframe com uma
-- string nunca dá verdadeiro, e falha em SILÊNCIO: a animação roda inteira e o
-- dano não acontece. Custou 14 Tools de dois conjuntos.
--═══════════════════════════════════════════════════════════════

local function marcaDe(passo)
	return type(passo) == "table" and passo.marca or nil
end

--- Tabela de keyframe no lugar da escada de `elseif marca == "X"`.
---
---     GOLPE = { cam = true, sfx = { "DESABA", 0.9 }, faz = derrubar }
---
--- `cam` manda o beat para a câmera com o nome do PRÓPRIO keyframe — não dá
--- para escrever `beatCena("CARGA")` dentro de `GOLPE` por engano. `sfx` toca
--- um som. `faz` é o trabalho que não cabe em dado.
local function despachar(quadros)
	return function(passo)
		local marca = marcaDe(passo)
		if not marca then return end
		local kf = quadros and quadros[marca]
		if not kf then return end
		if kf.cam and beatCena then beatCena(marca) end
		if kf.sfx then tocar(kf.sfx[1], kf.sfx[2]) end
		if kf.faz then kf.faz(passo) end
	end
end

