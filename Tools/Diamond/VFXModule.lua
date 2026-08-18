-- VFXModule_Guest_V1.lua
-- ModuleScript "VFXModule" — executor de VFX do conjunto GUEST
--
-- ONDE RODA: CLIENTE. O servidor transmite o tipo pelo VFXRemote; quem desenha
-- é quem vê (§12.11). Por isso `:Emit()` aqui é legítimo — não há replicação.
--
-- LINGUAGEM VISUAL DESTE CONJUNTO
--
--   Este não é o conjunto das bombas, e não deve parecer com ele. Bomba é
--   volume: bola, anel, fumaça. Porrada de rua é CONTATO — o que vende um
--   golpe de taco não é o tamanho do clarão, é o quadro em que ele acontece.
--
--   Por isso o impacto daqui é curto e seco:
--     FLASH   0.06 s   o contato
--     FAISCA  0.35 s   o estilhaço
--     ANEL    0.30 s   a força, e só nos golpes pesados
--
--   O arco do golpe (`ARCO`) é o único efeito longo, porque ele acompanha a
--   mão: é a leitura de "por onde o taco passou".
--
-- CURA É AZUL-ESVERDEADA, DANO É QUENTE
--   Os dois consumíveis do conjunto curam. Se a cura usasse a mesma paleta do
--   impacto, num tiroteio ninguém distinguiria quem apanhou de quem se curou.
--
-- Zero math.random: ângulo áureo e jitter senoidal por contador.
--
-- Gerado por FERRAMENTAS/gerar_servers_guest.py.

local Debris       = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX = {}

local CFG = {
	ANGULO_AUREO = math.rad(137.507764),
	COR_IMPACTO  = Color3.fromRGB(255, 214, 122),
	COR_METAL    = Color3.fromRGB(214, 226, 240),
	COR_CURA     = Color3.fromRGB(120, 235, 170),
	COR_PEDRA    = Color3.fromRGB(150, 146, 138),
	COR_POLVORA  = Color3.fromRGB(255, 176, 62),
	COR_ZOMBA    = Color3.fromRGB(255, 96, 176),
	TEX_FAISCA   = "rbxasset://textures/particles/sparkles_main.dds",
	TEX_FUMACA   = "rbxasset://textures/particles/smoke_main.dds",
	LIMITE_VIVOS = 220,
}

local Vivos, PorId, contador = {}, {}, 0

local function proximo()
	contador = contador + 1
	if contador > 100000 then contador = 1 end
	return contador
end

--- Jitter determinístico em [-1,1]. No lugar do math.random: mesma variedade,
--- e os dois clientes veem a mesma coisa.
local function jitter(fase)
	return math.sin(proximo() * 2.399963 + (fase or 0))
end

local function registrar(inst, vida)
	table.insert(Vivos, inst)
	if #Vivos > CFG.LIMITE_VIVOS then
		local velho = table.remove(Vivos, 1)
		if velho and velho.Parent then velho.Parent = nil end
	end
	if vida then Debris:AddItem(inst, vida) end
	return inst
end

local function novaParte(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Massless, p.CastShadow = true, false
	p.Material = Enum.Material.Neon
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for chave, valor in pairs(props or {}) do
		p[chave] = valor
	end
	p.Parent = workspace
	return p
end

local function tween(inst, tempo, alvo, estilo, direcao)
	local info = TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad,
		direcao or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, alvo)
	t:Play()
	return t
end

local function branco(cor, quanto)
	return cor:Lerp(Color3.new(1, 1, 1), quanto or 0.5)
end

--═══════════════════════════════════════════════════════════════
-- PACK DE VFX — DENTRO DA TOOL (VFXModule/Pack)
--
-- O pack do Acervo viaja como filho deste módulo, não em ReplicatedStorage:
-- a Regra nº 1 não abre exceção para pack. Se ele não estiver lá, cada efeito
-- daqui continua desenhando sozinho — `pk` só devolve false.
--
-- ATENÇÃO AO TIPO DO ARGUMENTO. Cinco dos dez efeitos do pack tomam tamanho
-- como NÚMERO e dois como Vector3, e o nome não avisa qual é qual
-- (`Size_A` × `Vector_Size_A`). Passar Vector3 onde ele quer número estoura
-- dentro do pcall e o efeito some sem avisar — foi o bug do `Small_Nova`.
-- `TESTES/verificar_pack_vfx.py` confere isso arquivo a arquivo.
--═══════════════════════════════════════════════════════════════

local PACK = { LIGADO = true, PASTA = "Pack" }
local raizPack, packProcurado, moduloDoPack = nil, false, {}

local function acharPack()
	if packProcurado then return raizPack end
	packProcurado = true
	raizPack = script:FindFirstChild(PACK.PASTA)
	return raizPack
end

local function efeitoDoPack(nome)
	if not PACK.LIGADO then return nil end
	local guardado = moduloDoPack[nome]
	if guardado ~= nil then
		if guardado == false then return nil end
		return guardado
	end
	local raiz = acharPack()
	if not raiz then moduloDoPack[nome] = false return nil end
	local modulo = raiz:FindFirstChild(nome)
	if not modulo or not modulo:IsA("ModuleScript") then
		moduloDoPack[nome] = false
		return nil
	end
	local ok, fn = pcall(require, modulo)
	if not ok or type(fn) ~= "function" then
		moduloDoPack[nome] = false
		return nil
	end
	moduloDoPack[nome] = fn
	return fn
end

local function pk(nome, ...)
	local fn = efeitoDoPack(nome)
	if not fn then return false end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[VFXModule_Guest] pack " .. tostring(nome) .. ": " .. tostring(err))
	end
	return ok
end

--═══════════════════════════════════════════════════════════════
-- CAMADAS
--═══════════════════════════════════════════════════════════════

--- O contato. 0.06 s — mais que isso e vira explosão, que não é o que é.
local function camadaFlash(p, c, raio)
	local bola = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(raio, raio, raio) * 0.5,
		Color = branco(c, 0.35),
		Transparency = 0.1,
		CFrame = CFrame.new(p),
	})
	local luz = Instance.new("PointLight")
	luz.Color, luz.Brightness, luz.Range = c, 6, raio * 4
	luz.Parent = bola
	tween(bola, 0.06, { Size = Vector3.new(raio, raio, raio) * 1.4,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(bola, 0.2)
end

local function camadaFaiscas(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.3), c)
	em.LightEmission = 1
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.2, 0.5)
	em.Speed = NumberRange.new(14 * forca, 32 * forca)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Rotation = NumberRange.new(0, 360)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 10)
	registrar(ancora, 1)
end

local function camadaAnel(p, c, raio, tempo)
	local anel = novaParte({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, raio * 0.4, raio * 0.4),
		Color = branco(c, 0.4),
		Transparency = 0.25,
		CFrame = CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)),
	})
	tween(anel, tempo, { Size = Vector3.new(0.05, raio * 2.2, raio * 2.2),
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(anel, tempo + 0.2)
end

local function camadaPoeira(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FUMACA
	em.Color = ColorSequence.new(c, branco(c, 0.2))
	em.LightEmission = 0.15
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2 * forca),
		NumberSequenceKeypoint.new(1, 3.4 * forca),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.6, 1.2)
	em.Speed = NumberRange.new(4 * forca, 11 * forca)
	em.SpreadAngle = Vector2.new(60, 60)
	em.Rotation = NumberRange.new(0, 360)
	em.RotSpeed = NumberRange.new(-30, 30)
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 8)
	registrar(ancora, 2)
end

--- Motes que SOBEM. É a assinatura da cura, e o único efeito do conjunto com
--- velocidade positiva no eixo Y — é o que faz ela não parecer dano.
local function camadaSubida(p, c, forca, quantidade)
	local ancora = novaParte({ Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1, CFrame = CFrame.new(p) })
	local att = Instance.new("Attachment")
	att.Parent = ancora
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FAISCA
	em.Color = ColorSequence.new(branco(c, 0.4), c)
	em.LightEmission = 0.9
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.5 * forca),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.7, 1.3)
	em.Speed = NumberRange.new(5 * forca, 9 * forca)
	em.SpreadAngle = Vector2.new(22, 22)
	em.Acceleration = Vector3.new(0, 6, 0)
	em.EmissionDirection = Enum.NormalId.Top
	em.Enabled = false
	em.Parent = att
	em:Emit(quantidade or 16)
	registrar(ancora, 2.4)
end

--═══════════════════════════════════════════════════════════════
-- EFEITOS
--═══════════════════════════════════════════════════════════════

local Efeitos = {}

local function pos(d)
	return (d and d.posicao) or Vector3.new()
end

local function escala(d)
	return (d and d.escala) or 1
end

local function cor(d, padrao)
	return (d and d.cor) or padrao or CFG.COR_IMPACTO
end

local function quadro(d)
	if d and d.cframe then return d.cframe end
	return CFrame.new(pos(d))
end

--- Contato de golpe. Curto e seco.
function Efeitos.IMPACTO(d)
	local p, e, c = pos(d), escala(d), cor(d)
	camadaFlash(p, c, 2.2 * e)
	camadaFaiscas(p, c, 0.55 * e, 10 + math.floor(e * 4))
	pk("Small_Nova", p, 0.28, 0, 7 * e, branco(c, 0.5), c)
end

--- Contato em metal — mesma forma, paleta fria e mais estilhaço.
function Efeitos.IMPACTO_METAL(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_METAL)
	camadaFlash(p, c, 2.4 * e)
	camadaFaiscas(p, c, 0.75 * e, 16 + math.floor(e * 5))
	pk("Small_Nova", p, 0.24, 0, 6 * e, branco(c, 0.6), c)
end

--- O rastro da arma. Único efeito longo do conjunto: acompanha a mão.
function Efeitos.ARCO(d)
	local e, c = escala(d), cor(d)
	pk("Small_Slash", quadro(d), 9 * e, 0.22, branco(c, 0.55), c)
end

--- Golpe pesado no chão: onda, rachadura e poeira.
function Efeitos.CONCUSSAO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_METAL)
	camadaFlash(p, c, 3.4 * e)
	camadaAnel(p, c, 4.5 * e, 0.3)
	camadaPoeira(p, Color3.fromRGB(120, 114, 104), 0.8 * e, 12)
	camadaFaiscas(p, c, 0.9 * e, 18)
	pk("Shockwave", CFrame.new(p), CFrame.new(p), 0.55,
		Vector3.new(6 * e, 1.4, 6 * e), Vector3.new(22 * e, 0.4, 22 * e),
		branco(c, 0.5), c)
	pk("Floor_Crack", CFrame.new(p), 9 * e, 3, c)
end

--- Cura. Sobe, e é a única coisa do conjunto que sobe.
function Efeitos.CURA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_CURA)
	camadaSubida(p, c, 0.9 * e, 18 + math.floor(e * 6))
	pk("Sonar_Ring", CFrame.new(p), 0.7, 0, 7 * e, 1.4, 0.15,
		branco(c, 0.5), c)
end

--- Lata, caroço, respingo. Um jato curto na direção do arremesso.
function Efeitos.RESPINGO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_CURA)
	camadaFaiscas(p, c, 0.5 * e, 12)
	camadaFlash(p, c, 1.6 * e)
end

--- Provocação. Anel rosa e nada de dano — quem vê tem de entender na hora que
--- ninguém apanhou.
function Efeitos.ZOMBARIA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_ZOMBA)
	pk("Sonar_Ring", CFrame.new(p), 0.5, 0, 9 * e, 1.1, 0.1, branco(c, 0.6), c)
	camadaFaiscas(p, c, 0.4 * e, 10)
end

--- Provocação em roda: três anéis com atraso, e o espiral no meio.
function Efeitos.ZOMBARIA_RODA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_ZOMBA)
	for i = 1, 3 do
		local raio = (5 + i * 3.5) * e
		camadaAnel(p + Vector3.new(0, 0.2 * i, 0), c, raio, 0.32 + i * 0.06)
	end
	pk("Spiral_Effect", p, 1.4 * e, c, 3, 5 * e, 6 * e)
	camadaFaiscas(p, c, 0.5 * e, 16)
end

--- A pedra se fechando em volta do corpo.
function Efeitos.PEDRA(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_PEDRA)
	local casca = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1),
		Color = c,
		Material = Enum.Material.Slate,
		Transparency = 0.15,
		CFrame = CFrame.new(p),
	})
	tween(casca, 0.22, { Size = Vector3.new(6.2, 6.6, 6.2) * e },
		Enum.EasingStyle.Back)
	registrar(casca, (d and d.duracao) or 8)
	camadaPoeira(p, c, 0.7 * e, 10)
	if d and d.id then
		PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
		table.insert(PorId[d.id].partes, casca)
	end
end

--- A pedra se abrindo. Estilhaço para fora, e a casca sai por `Parar`.
function Efeitos.PEDRA_FIM(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_PEDRA)
	camadaFaiscas(p, c, 0.9 * e, 20)
	camadaPoeira(p, c, 1.1 * e, 14)
	camadaAnel(p, branco(c, 0.3), 5 * e, 0.34)
	pk("Smoky_Explosion", p, 1.1, 4 * e, c, Color3.fromRGB(112, 108, 102))
end

--- Fogacho de boca de cano. Fica no CFrame da ponta, não numa posição solta:
--- revólver mal enquadrado lê como faísca no ar.
function Efeitos.FOGACHO(d)
	local cf, e = quadro(d), escala(d)
	local c = cor(d, CFG.COR_POLVORA)
	camadaFlash(cf.Position, c, 1.5 * e)
	local clarao = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.9, 0.9, 2.2) * e,
		Color = branco(c, 0.55),
		Transparency = 0.2,
		CFrame = cf,
	})
	tween(clarao, 0.07, { Size = Vector3.new(0.2, 0.2, 0.4) * e,
		Transparency = 1 }, Enum.EasingStyle.Quint)
	registrar(clarao, 0.2)
	camadaFaiscas(cf.Position + cf.LookVector * 0.6, c, 0.35 * e, 7)
	camadaPoeira(cf.Position + cf.LookVector * 1.2,
		Color3.fromRGB(150, 146, 140), 0.3 * e, 4)
end

--- O traçado. Nasce na boca do cano e morre no ponto atingido.
function Efeitos.TRACADO(d)
	local origem = (d and d.origem) or pos(d)
	local destino = (d and d.destino) or origem
	local c = cor(d, CFG.COR_POLVORA)
	if not pk("Laser_Shot", origem, destino, 0.16, 0.02, 8,
			branco(c, 0.6), c) then
		local delta = destino - origem
		if delta.Magnitude < 0.1 then return end
		local feixe = novaParte({
			Size = Vector3.new(0.14, 0.14, delta.Magnitude),
			Color = branco(c, 0.5),
			Transparency = 0.25,
			CFrame = CFrame.lookAt(origem + delta * 0.5, destino),
		})
		tween(feixe, 0.1, { Transparency = 1 }, Enum.EasingStyle.Quad)
		registrar(feixe, 0.25)
	end
end

--- A cápsula saindo do tambor. Some sozinha; não é peça de gameplay.
function Efeitos.CASQUINHA(d)
	local p = pos(d)
	local casca = novaParte({
		Size = Vector3.new(0.12, 0.28, 0.12),
		Color = Color3.fromRGB(214, 176, 92),
		Material = Enum.Material.Metal,
		CFrame = CFrame.new(p) * CFrame.Angles(jitter(0.4) * 2, jitter(1.1) * 2, 0),
	})
	local alvo = CFrame.new(p + Vector3.new(jitter(0.2) * 2, -3.2, jitter(0.9) * 2))
		* CFrame.Angles(jitter(2.2) * 3, jitter(0.7) * 3, jitter(1.5) * 3)
	tween(casca, 0.7, { CFrame = alvo, Transparency = 1 },
		Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	registrar(casca, 0.9)
end

--- Rastro curto de coisa arremessada.
function Efeitos.ARREMESSO(d)
	local p, e = pos(d), escala(d)
	camadaFaiscas(p, cor(d, CFG.COR_CURA), 0.28 * e, 5)
end

--- A CEGUEIRA — a nuvem que fica NA FRENTE DA CARA do alvo.
---
--- O original do Cano abria uma `ScreenGui` no cliente de quem apanhava.
--- `ScreenGui` dentro de Tool é proibida, e além de proibida é ruim: só a
--- vítima via, e para a sala inteira nada acontecia.
---
--- Aqui a cegueira é **geometria no mundo 3D**: uma nuvem escura soldada à
--- frente da cabeça. Ela tapa a vista de quem levou — porque está fisicamente
--- no caminho — e todo mundo vê que aquele jogador está cego. Some por
--- `VFX.Parar`, e o `Debris` é a rede de segurança.
function Efeitos.CEGUEIRA(d)
	local alvo = d and d.alvo
	local cabeca = alvo and alvo:FindFirstChild("Head")
	if not cabeca then return end

	local nuvem = novaParte({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 2.6, 2.6) * ((d and d.escala) or 1),
		Color = CFG.COR_FUMACA or Color3.fromRGB(28, 26, 24),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 1,
		Anchored = false,
		CFrame = cabeca.CFrame,
	})
	local solda = Instance.new("Weld")
	solda.Part0 = cabeca
	solda.Part1 = nuvem
	solda.C0 = CFrame.new(0, 0, -0.6)
	solda.Parent = nuvem

	tween(nuvem, 0.18, { Transparency = 0.05 })

	local att = Instance.new("Attachment")
	att.Parent = nuvem
	local em = Instance.new("ParticleEmitter")
	em.Texture = CFG.TEX_FUMACA or "rbxasset://textures/particles/smoke_main.dds"
	em.Color = ColorSequence.new(Color3.fromRGB(20, 18, 16))
	em.Size = NumberSequence.new(2.2)
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.5, 0.9)
	em.Speed = NumberRange.new(0.4, 1.2)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Rate = 26
	em.Enabled = true
	em.Parent = att

	registrar(nuvem, (d and d.duracao) or 3)
	if d and d.id then
		PorId[d.id] = PorId[d.id] or { partes = {}, conexoes = {} }
		table.insert(PorId[d.id].partes, nuvem)
	end
end


--═══════════════════════════════════════════════════════════════
-- EFEITOS NOVOS — 2026-08-18
--═══════════════════════════════════════════════════════════════

--- O REBOTE: o rastro de saída da peça rebatida.
---
--- O `IMPACTO_METAL` já dava o clarão do contato, mas nada mostrava PARA ONDE
--- a coisa foi. Sem isso o rebate lia como "a peça sumiu". Aqui sai um risco na
--- direção da saída, com o comprimento proporcional à força — e como o teto do
--- servidor limita a velocidade, o risco também tem tamanho máximo.
function Efeitos.REBOTE(d)
	local p, e = pos(d), escala(d)
	local dir = (d and d.direcao) or Vector3.new(0, 0, -1)
	local forca = math.clamp((d and d.forca) or 0.5, 0.1, 1)
	local c = cor(d, CFG.COR_METAL)
	local comprimento = 6 + 26 * forca

	local risco = novaParte({
		Size = Vector3.new(0.5 * e, 0.5 * e, comprimento),
		Color = branco(c, 0.5),
		Transparency = 0.1,
		CFrame = CFrame.lookAt(p + dir * (comprimento * 0.5), p + dir * comprimento),
	})
	tween(risco, 0.2 + 0.14 * forca, {
		Size = Vector3.new(0.03, 0.03, comprimento * 1.5),
		Transparency = 1,
	}, Enum.EasingStyle.Quint)
	registrar(risco, 0.5)

	camadaFaiscas(p, c, 0.9 * e * (0.5 + forca), 10 + math.floor(forca * 14))
	pk("Small_Nova", p, 0.22, 0, 4.5 * e * forca, branco(c, 0.7), c)
end

--- A ONDA: o anel raso no chão do golpe pesado.
---
--- Serve para ler o ALCANCE do golpe de fora, que antes só dava para descobrir
--- levando. O anel nasce na altura do pé, não no peito.
function Efeitos.ONDA(d)
	local p, e = pos(d), escala(d)
	local raio = (d and d.raio) or 10
	local c = cor(d, CFG.COR_IMPACTO)
	camadaAnel(p - Vector3.new(0, 2.4, 0), c, raio * e, 0.34)
	camadaPoeira(p - Vector3.new(0, 2.6, 0), CFG.COR_PEDRA, 0.7 * e, 14)
	pk("Shockwave_Explosion", p - Vector3.new(0, 2.2, 0), 0.4,
		1.5 * e, raio * e, c, branco(c, 0.6))
end

--- A FAÍSCA DE TACO: o risco de metal ao longo do arco da batida.
---
--- Diferente do `ARCO`, que é o desenho do movimento. Esta é a raspagem: sai
--- do ponto de contato e acompanha o giro, curta e seca.
function Efeitos.FAISCA_TACO(d)
	local p, e = pos(d), escala(d)
	local c = cor(d, CFG.COR_METAL)
	for i = 1, 5 do
		local a = i * 1.2566 + jitter(i) * 0.25
		local onde = p + Vector3.new(math.cos(a), jitter(i + 3) * 0.4,
			math.sin(a)) * (1.4 * e)
		camadaFaiscas(onde, c, 0.5 * e, 5)
	end
	camadaFlash(p, branco(c, 0.4), 1.6 * e)
end

--═══════════════════════════════════════════════════════════════
-- API
--═══════════════════════════════════════════════════════════════

function VFX.Executar(tipo, dados)
	local fn = Efeitos[tipo]
	if not fn then return false end
	local ok, err = pcall(fn, dados)
	if not ok then
		warn("[VFXModule_Guest] falha em " .. tostring(tipo) .. ": " .. tostring(err))
	end
	return ok
end

function VFX.Parar(id)
	local reg = PorId[id]
	if not reg then return end
	for _, conn in ipairs(reg.conexoes) do
		if conn then conn:Disconnect() end
	end
	for _, inst in ipairs(reg.partes) do
		if inst and inst.Parent then
			if inst:IsA("ParticleEmitter") then inst.Enabled = false end
			inst.Parent = nil
		end
	end
	PorId[id] = nil
end

function VFX.LimparTudo()
	for id in pairs(PorId) do VFX.Parar(id) end
	for _, inst in ipairs(Vivos) do
		if inst and inst.Parent then inst.Parent = nil end
	end
	table.clear(Vivos)
end

return VFX
