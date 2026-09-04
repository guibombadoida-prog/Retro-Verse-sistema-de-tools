
--═══════════════════════════════════════════════════════════════
-- A CÂMERA — beat nomeado, e só para o DONO
--
-- Câmera é 100% cliente: o servidor manda NOME e nunca `CFrame`. E o pedido
-- foi explícito — a cutscene não pode ser forçada nos outros jogadores —,
-- então é `FireClient(jogador, …)`, não `FireAllClients`.
--
-- O VFX da cena continua indo para todo mundo: quem está por perto vê o
-- Xester se transformar, só não perde o controle da própria visão.
--═══════════════════════════════════════════════════════════════

function beatCena(nome)
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "BEAT", { nome = nome })
end

function comecarCena(qual)
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "INICIO",
		{ cena = qual, prazo = CFG.PRAZO_CENA })
end

function acabarCena()
	if not jogador then return end
	CutsceneRemote:FireClient(jogador, "FIM", {})
end
