--[[
	harness_NucleoCombate  —  BANCADA, não artefato de place
	Retro-Verse / Studios

	Stubs mínimos da API Roblox para exercitar o pipeline de dano do NucleoCombate fora do
	Studio. Valida §12.5 (aumento aditivo com teto, redução multiplicativa com teto, escudo
	antes da vida), §12.6 (guardas de entrada, cancelamentos) e §12.9 (recarga global).

	⚠️ ESTE ARQUIVO NUNCA VAI PARA O PLACE. Roda no terminal:

		lua5.4 TESTES/harness_NucleoCombate.lua

	O que ele NÃO cobre: o modo observado (§12.8) depende de HealthChanged real, e a detecção
	em área depende de GetPartBoundsInRadius real — os dois só se testam no Studio, pelos
	testes de aceitação do CHECKLIST_ENTREGA.md.

	Rodar isto depois de QUALQUER edição no NucleoCombate.lua.
--]]

--==================== stubs ====================

function math.clamp(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end

local function novoSinal()
	return { Connect = function() return { Disconnect = function() end } end }
end

function typeof(v)
	if type(v) == "table" and v.__tipo then return v.__tipo end
	return type(v)
end

Vector3 = { new = function(x, y, z) return { __tipo = "Vector3", X = x, Y = y, Z = z } end }
Color3 = { fromRGB = function(r, g, b) return { __tipo = "Color3", r = r, g = g, b = b } end }

task = {
	spawn = function() end,
	wait = function() end,
	delay = function() end,
}

Instance = {
	new = function(classe)
		return { __tipo = "Instance", ClassName = classe, Name = "", Value = nil, Parent = nil }
	end,
}

OverlapParams = { new = function() return {} end }
Enum = { RaycastFilterType = { Exclude = "Exclude" } }

local Players
Players = {
	personagens = {},
	GetPlayers = function() return {} end,
	PlayerAdded = novoSinal(),
	PlayerRemoving = novoSinal(),
	GetPlayerFromCharacter = function(_, personagem)
		return Players.personagens[personagem]
	end,
}

local Debris = { AddItem = function() end }

workspace = {
	GetDescendants = function() return {} end,
	DescendantAdded = novoSinal(),
	GetPartBoundsInRadius = function() return {} end,
}

game = {
	GetService = function(_, nome)
		if nome == "Players" then return Players end
		if nome == "Debris" then return Debris end
		return {}
	end,
}

--==================== fábricas de teste ====================

local function novoHumanoide(personagem, vida)
	local h
	h = {
		__tipo = "Instance",
		ClassName = "Humanoid",
		Health = vida,
		MaxHealth = vida,
		Parent = personagem,
		IsA = function(_, c) return c == "Humanoid" end,
		FindFirstChild = function() return nil end,
		HealthChanged = novoSinal(),
		Died = novoSinal(),
		Destroying = novoSinal(),
	}
	personagem.humanoide = h
	return h
end

local function novoPersonagem(nome)
	local p
	p = {
		__tipo = "Instance",
		ClassName = "Model",
		Name = nome,
		FindFirstChildOfClass = function(_, c)
			if c == "Humanoid" then return p.humanoide end
			return nil
		end,
		FindFirstChild = function() return nil end,
	}
	return p
end

local function novoJogador(nome, personagem)
	local j = {
		__tipo = "Instance",
		ClassName = "Player",
		Name = nome,
		Character = personagem,
		Team = nil,
		Neutral = false,
		FindFirstChild = function() return nil end,
		FindFirstChildOfClass = function() return nil end,
	}
	Players.personagens[personagem] = j
	return j
end

--==================== carga ====================

local raiz = arg and arg[0] and arg[0]:match("^(.*)TESTES[/\\]") or "./"
dofile(raiz .. "ServerScriptService/NucleoCombate.lua")

local C = _G.Combate
assert(C, "_G.Combate não foi publicado")

--==================== testes ====================

local falhas = 0
local function conferir(rotulo, obtido, esperado)
	local ok = math.abs(obtido - esperado) < 0.001
	if not ok then falhas = falhas + 1 end
	print(string.format("%-58s %-10.4f %s %.4f", rotulo, obtido, ok and "==" or "!=", esperado))
end

local atacante = novoPersonagem("Atacante")
novoHumanoide(atacante, 100)
local jogador = novoJogador("Atacante", atacante)

local alvo = novoPersonagem("Alvo")
local humAlvo = novoHumanoide(alvo, 500)
novoJogador("Alvo", alvo)

print("\n-- §12.5 pipeline --")
conferir("dano puro, sem modificador", C.calcular(jogador, humAlvo, 100), 100)

local cancelaAumento = C.registrarAumento(atacante, 0.20)
conferir("aumento +20%", C.calcular(jogador, humAlvo, 100), 120)

local cancelaAumento2 = C.registrarAumento(atacante, 0.30)
conferir("aumento +20% e +30% = aditivo, +50%", C.calcular(jogador, humAlvo, 100), 150)
cancelaAumento()
cancelaAumento2()

local cancelaTeto = C.registrarAumento(atacante, 5.00)
conferir("aumento +500% limitado ao teto de +300%", C.calcular(jogador, humAlvo, 100), 400)
cancelaTeto()

local r1 = C.registrarReducao(alvo, 0.40)
conferir("reducao 40%", C.calcular(jogador, humAlvo, 100), 60)

local r2 = C.registrarReducao(alvo, 0.40)
conferir("reducao 40% + 40% multiplicativo = 64%", C.calcular(jogador, humAlvo, 100), 36)

local r3 = C.registrarReducao(alvo, 0.40)
conferir("tres reducoes de 40% = 78,4%, nunca 120%", C.calcular(jogador, humAlvo, 100), 21.6)
r1() r2() r3()

local t1 = C.registrarReducao(alvo, 0.60)
local t2 = C.registrarReducao(alvo, 0.60)
local t3 = C.registrarReducao(alvo, 0.60)
conferir("reducao limitada ao teto de 90%", C.calcular(jogador, humAlvo, 100), 10)
t1() t2() t3()

print("\n-- escudo: HP paralelo, consumido antes da vida --")
local cancelaEscudo = C.registrarEscudo(alvo, 50)
conferir("escudo 50 absorve golpe de 30", C.calcular(jogador, humAlvo, 30), 0)
conferir("restam 20 de escudo: golpe de 30 passa 10", C.calcular(jogador, humAlvo, 30), 10)
conferir("escudo esgotado: golpe de 30 passa inteiro", C.calcular(jogador, humAlvo, 30), 30)
cancelaEscudo()

print("\n-- ordem: aumento -> reducao -> escudo --")
local a = C.registrarAumento(atacante, 1.00)     -- x2
local r = C.registrarReducao(alvo, 0.50)         -- x0,5
local e = C.registrarEscudo(alvo, 40)            -- -40
conferir("100 -> x2 -> x0,5 -> -40 escudo", C.calcular(jogador, humAlvo, 100), 60)
a() r() e()

print("\n-- §12.5 modificadores: contribuicao aditiva, no mesmo grupo --")
local cancelaMod = C.registrarModificador("Passiva_Frenesi", function(contexto)
	if contexto.classe == "Melee" then return 0.25 end
	return 0
end)
conferir("modificador +25% entra no grupo aditivo", C.calcular(jogador, humAlvo, 100), 125)

local a2 = C.registrarAumento(atacante, 0.25)
conferir("modificador +25% e aumento +25% somam", C.calcular(jogador, humAlvo, 100), 150)
a2()
cancelaMod()
conferir("modificador cancelado nao deixa residuo", C.calcular(jogador, humAlvo, 100), 100)

print("\n-- cancelamento --")
local cancelaDuplo = C.registrarAumento(atacante, 0.50)
cancelaDuplo()
cancelaDuplo() -- idempotente: chamar duas vezes nao pode derrubar
conferir("cancelamento idempotente", C.calcular(jogador, humAlvo, 100), 100)

print("\n-- §12.9 recarga global --")
local liberado1 = C.recargaGlobal(jogador, "Teste_X", 5)
local liberado2, restante = C.recargaGlobal(jogador, "Teste_X", 5)
print(string.format("%-58s %s / %s (restante %.2fs)", "1a chamada libera, 2a bloqueia",
	tostring(liberado1), tostring(liberado2), restante))
if not (liberado1 == true and liberado2 == false) then falhas = falhas + 1 end

local outraChave = C.recargaGlobal(jogador, "Teste_Y", 5)
print(string.format("%-58s %s", "chave diferente nao e afetada", tostring(outraChave)))
if outraChave ~= true then falhas = falhas + 1 end

print("\n-- §12.6 guardas de entrada --")
conferir("dano zero devolve zero", C.calcular(jogador, humAlvo, 0), 0)
conferir("dano negativo devolve zero", C.calcular(jogador, humAlvo, -50), 0)
conferir("alvo nil devolve o bruto", C.calcular(jogador, nil, 42), 42)

print("")
if falhas == 0 then
	print("TODOS OS TESTES PASSARAM")
else
	print(string.format("%d TESTE(S) FALHARAM", falhas))
	os.exit(1)
end
