#!/usr/bin/env bash
# verificar_autocontencao.sh — Retro-Verse / Studios
#
# Regra nº 1: NADA de referência de script FORA da Tool.
# Todo script, animação, VFX, SFX, mesh, MeshPart e textura é filho da Tool.
#
#   bash TESTES/verificar_autocontencao.sh [caminho]
#
# Sai com 1 se achar qualquer referência externa. Rodar antes de fechar entrega.
#
# A varredura é sobre CÓDIGO: comentários de linha (--) e de bloco (--[[ ]]) são
# removidos antes de comparar. Documentar a proibição é obrigatório, não é violação.

set -u

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALVO="${1:-$RAIZ/Tools}"
FALHAS=0

vermelho() { printf '\033[31m%s\033[0m\n' "$1"; }
verde()    { printf '\033[32m%s\033[0m\n' "$1"; }
cinza()    { printf '\033[90m%s\033[0m\n' "$1"; }

# Emite "arquivo:linha:código" com todo comentário removido e a numeração preservada.
codigo_puro() {
	find "$ALVO" -name '*.lua' -print0 2>/dev/null | while IFS= read -r -d '' arquivo; do
		awk -v nome="${arquivo#"$RAIZ"/}" '
			# Comentário longo do Lua tem NÍVEL: --[[ ]], --[=[ ]=], --[==[ ]==].
			# Ignorar o nível fazia o verificador ler documentação como se fosse código.
			{
				linha = $0
				if (bloco) {
					fecha = "]" nivel "]"
					pos = index(linha, fecha)
					if (pos > 0) {
						bloco = 0
						linha = substr(linha, pos + length(fecha))
					} else {
						linha = ""
					}
				}
				if (!bloco) {
					if (match(linha, /--\[=*\[/)) {
						abertura = substr(linha, RSTART, RLENGTH)
						nivel = substr(abertura, 4, RLENGTH - 4)
						prefixo = substr(linha, 1, RSTART - 1)
						resto = substr(linha, RSTART + RLENGTH)
						fecha = "]" nivel "]"
						pos = index(resto, fecha)
						if (pos > 0) {
							linha = prefixo substr(resto, pos + length(fecha))
						} else {
							bloco = 1
							linha = prefixo
						}
					}
					sub(/--.*$/, "", linha)
				}
				print nome ":" FNR ":" linha
			}
		' "$arquivo"
	done
}

PURO="$(codigo_puro)"

checar() {
	local rotulo="$1"
	local padrao="$2"
	local achado

	achado=$(printf '%s\n' "$PURO" | grep -E "$padrao" || true)

	if [ -n "$achado" ]; then
		vermelho "✗ $rotulo"
		printf '%s\n' "$achado" | sed 's|^|    |'
		FALHAS=$((FALHAS + 1))
	else
		verde "✓ $rotulo"
	fi
}

echo ""
echo "AUTOCONTENÇÃO ABSOLUTA — varredura em: ${ALVO#"$RAIZ"/}"
cinza "Regra nº 1: nada de referência de script fora da Tool"
echo ""

# --- Depósitos de asset fora da Tool -----------------------------------------
# ReplicatedStorage é a ÚNICA exceção à Regra nº 1, e ela é estreita de
# propósito: só o VFXModule, só para achar o pack de VFX compartilhado, e só
# por uma via que não yielda. As três checagens abaixo são o que a mantém
# estreita — ver DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md, "A exceção declarada".
RS_FORA=$(printf '%s\n' "$PURO" | grep -E 'ReplicatedStorage' \
	| grep -vE '/VFXModule\.lua:[0-9]+:.*game:FindService\("ReplicatedStorage"\)' || true)
if [ -n "$RS_FORA" ]; then
	vermelho "✗ ReplicatedStorage só no VFXModule, e só via FindService"
	printf '%s\n' "$RS_FORA" | sed 's|^|    |'
	cinza "    A exceção é para o pack de VFX. Som, mesh, pose e módulo continuam dentro."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ ReplicatedStorage só no VFXModule, e só via FindService"
fi

# WaitForChild num depósito que pode não existir pendura a thread para sempre.
# É justamente o que faria a Tool QUEBRAR em vez de empobrecer sem o pack.
RS_ESPERA=$(printf '%s\n' "$PURO" | grep -E '/VFXModule\.lua:.*:WaitForChild\(' || true)
if [ -n "$RS_ESPERA" ]; then
	vermelho "✗ o VFXModule não espera por nada"
	printf '%s\n' "$RS_ESPERA" | sed 's|^|    |'
	cinza "    Sem o pack, WaitForChild pendura. FindFirstChild devolve nil e segue."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ o VFXModule não espera por nada"
fi

# Do depósito só pode sair o pack declarado. Se dali saísse mais alguma coisa —
# um Sound, um Mesh, uma pose — a exceção teria virado porta. A checagem segue a
# variável que recebeu o serviço e exige que TUDO lido nela seja PACK.DEPOSITO.
RS_LITERAL=$(printf '%s\n' "$PURO" | awk -F: '
	{
		arquivo = $1
		numero  = $2
		corpo   = substr($0, index($0, $3))

		if (arquivo !~ /VFXModule\.lua$/) next
		if (arquivo != anterior) { alca = ""; anterior = arquivo }

		# `local rs = game:FindService("ReplicatedStorage")` -> alca = "rs"
		if (corpo ~ /=[ \t]*game:FindService\("ReplicatedStorage"\)/) {
			nome = corpo
			sub(/[ \t]*=.*$/, "", nome)
			sub(/^[ \t]*local[ \t]+/, "", nome)
			gsub(/[ \t]/, "", nome)
			alca = nome
			next
		}

		if (alca != "" && corpo ~ (alca "[:.]")) {
			if (corpo ~ /FindFirstChild\([ \t]*PACK\.DEPOSITO[ \t]*\)/) next
			print arquivo ":" numero ":" corpo
		}
	}
')
if [ -n "$RS_LITERAL" ]; then
	vermelho "✗ do depósito só sai o nome declarado em PACK.DEPOSITO"
	printf '%s\n' "$RS_LITERAL" | sed 's|^|    |'
	FALHAS=$((FALHAS + 1))
else
	verde "✓ do depósito só sai o nome declarado em PACK.DEPOSITO"
fi

checar "sem ServerStorage"              'ServerStorage'
checar "sem ServerScriptService"        'ServerScriptService'
checar "sem StarterGui / StarterPack"   'StarterGui|StarterPack|StarterPlayer'
checar "sem Lighting"                   'GetService\("Lighting"\)|game\.Lighting'
checar "sem SoundService como depósito" 'GetService\("SoundService"\)|game\.SoundService'
checar "sem InsertService"              'InsertService'
checar "sem referência ao Acervo"       'ACERVO'

# --- Ler de workspace é dependência; escrever nele é saída, e é permitido ----
# O que a regra proíbe é BUSCAR ASSET lá fora. Resolver uma entidade viva —
# o personagem que carrega a Tool, o alvo que levou o golpe — é outra coisa:
# entra pelo payload como dado (um nome), não como Instance, e não há Tool
# que acerte alguém sem localizar esse alguém. Mesma categoria de
# workspace.CurrentCamera e Players.LocalPlayer, já declarada na Regra nº 1.
#
# A linha entre as duas é o literal: buscar "MeuEfeito" é depósito de asset;
# buscar `nome`, que veio do servidor, é resolver quem está em campo.
checar "sem buscar asset em workspace"  'workspace[:.](FindFirstChild|WaitForChild|FindFirstDescendant)\(\s*"|game\.Workspace[:.](FindFirstChild|WaitForChild)\(\s*"'

# WaitForChild em workspace yielda por algo que pode nunca chegar.
checar "sem esperar por algo em workspace" 'workspace[:.]WaitForChild|game\.Workspace[:.]WaitForChild'

# --- Animação R6: o animator canônico solda Welds próprios -------------------
# Escrever em Motor6D.C0 briga com o script Animate padrão do Roblox, que escreve
# nas mesmas juntas todo frame. Dois donos por junta: a pose treme e volta só.
checar "sem escrita em Motor6D.C0"      'Motor6D|\["(Right|Left) (Shoulder|Hip)"\]|\["RootJoint"\]|\["Neck"\]'
checar "sem Animation / LoadAnimation"  'Instance\.new\("Animation"\)|LoadAnimation|AnimationTrack'

# Encadear beat com task.wait(duração) some ~1 frame por beat — com 100 beats
# vira quase 2 s de atraso. Quem encadeia é o animator (Tween.Completed / dt).
checar "sem encadear beat por task.wait" 'task\.wait\(\s*(passo|kf|beat|quadro)\.'

# --- Câmera: 100% cliente (REGRA_CAMERA_DE_CUTSCENE) -------------------------
# workspace.CurrentCamera é singleton por cliente, não depósito de asset — não
# viola a Regra nº 1. Mas em Server Script é violação das duas regras.
CAMERA_NO_SERVIDOR=$(printf '%s\n' "$PURO" \
	| grep -E '_Server_V[0-9]+\.lua:' \
	| grep -E 'CurrentCamera|CameraType|FieldOfView' || true)
if [ -n "$CAMERA_NO_SERVIDOR" ]; then
	vermelho "✗ câmera só no cliente"
	printf '%s\n' "$CAMERA_NO_SERVIDOR" | sed 's|^|    |'
	cinza "    Não existe a câmera do jogo: existe uma por cliente. Mande beat."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ câmera só no cliente"
fi

# Câmera presa sem devolução é bug sem saída para o jogador: quem escreve em
# CameraType tem de desligar em Unequipped E em Destroying.
SEM_DEVOLVER=$(printf '%s\n' "$PURO" | awk -F: '
	{
		arquivo = $1
		corpo   = substr($0, index($0, $3))

		if (arquivo != anterior) {
			if (anterior != "" && prende && !(desliga_uneq && desliga_dest)) {
				print anterior
			}
			anterior = arquivo
			prende = 0; desliga_uneq = 0; desliga_dest = 0
		}
		if (corpo ~ /CameraType[ \t]*=/)   { prende = 1 }
		if (corpo ~ /Unequipped/)          { desliga_uneq = 1 }
		if (corpo ~ /Destroying/)          { desliga_dest = 1 }
	}
	END {
		if (anterior != "" && prende && !(desliga_uneq && desliga_dest)) {
			print anterior
		}
	}
')
if [ -n "$SEM_DEVOLVER" ]; then
	vermelho "✗ câmera presa é sempre devolvida"
	printf '%s\n' "$SEM_DEVOLVER" | sed 's|^|    |'
	cinza "    Escreve em CameraType sem ligar Tool.Unequipped E Tool.Destroying."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ câmera presa é sempre devolvida"
fi

# --- Assinatura das funções do Núcleo ----------------------------------------
#
# Errar a aridade de uma função de _G.Combate NÃO dá erro: o Lua aceita, e a
# função devolve lixo ou um no-op. Foi assim que as 7 Tools de escudo saíram
# com dano ZERO — chamavam registrarAtaque (que só grava atribuição de abate)
# no lugar de calcular, e aoAplicarDano com um Humanoid no lugar da função.
checar "registrarAtaque não é aplicador de dano" '_G\.Combate\.registrarAtaque\([^)]*,[^)]*,[^)]*,'
checar "aoAplicarDano recebe só a função"        '_G\.Combate\.aoAplicarDano\(\s*[a-z]\w*\s*,'
# detectarHumanoides(posicao, raio, ignorar, jogador, humanoideDono, limite):
# seis argumentos, cinco vírgulas. Com menos, `jogador` fica nil e o filtro de
# time do podeCausarDano é PULADO — aliado vira alvo válido.
CURTA=$(printf '%s\n' "$PURO" | grep -E '_G\.Combate\.detectarHumanoides\(' | awk -F: '
	{
		corpo = substr($0, index($0, $3))
		n = gsub(/,/, ",", corpo)
		if (n < 5) { print $1 ":" $2 ":" corpo }
	}
')
if [ -n "$CURTA" ]; then
	vermelho "✗ detectarHumanoides com 6 argumentos"
	printf '%s\n' "$CURTA" | sed 's|^|    |'
	cinza "    Faltando jogador/humanoideDono: o filtro de time não roda."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ detectarHumanoides com 6 argumentos"
fi

# Detecção de alvo por Players:GetPlayers() não enxerga NPC: NPC é Model com
# Humanoid no workspace, não é Player. Quem varre área usa consulta espacial.
VARRE_PLAYERS=$(printf '%s\n' "$PURO" \
	| grep -E '_Server_V[0-9]+\.lua:' \
	| grep -E 'Players:GetPlayers\(\)' || true)
if [ -n "$VARRE_PLAYERS" ]; then
	ACHOU_ESPACIAL=$(printf '%s\n' "$PURO" | grep -cE 'GetPartBoundsInRadius' || true)
	if [ "$ACHOU_ESPACIAL" -eq 0 ]; then
		vermelho "✗ detecção de alvo enxerga NPC"
		printf '%s\n' "$VARRE_PLAYERS" | sed 's|^|    |'
		cinza "    Players:GetPlayers() não vê NPC. Use GetPartBoundsInRadius."
		FALHAS=$((FALHAS + 1))
	else
		verde "✓ detecção de alvo enxerga NPC"
	fi
else
	verde "✓ detecção de alvo enxerga NPC"
fi

# --- Fluidez: nada de mover geometria pelo servidor ---------------------------
#
# Part ancorada cujo CFrame é escrito por script de SERVIDOR replica a ~20 Hz e
# o cliente NÃO interpola: o movimento chega em passos discretos. Foi isso que
# deixou a órbita, o voo do disco e a marca do vínculo "não fluidos".
#
# Movimento contínuo é do cliente, a 60 Hz, a partir de um beat com parâmetros.
# O servidor segue dono do dano, calculando a MESMA fórmula sem geometria.
MOVE_NO_SERVIDOR=$(printf '%s\n' "$PURO" | awk -F: '
	{
		arquivo = $1
		corpo   = substr($0, index($0, $3))

		if (arquivo !~ /_Server_V[0-9]+\.lua/) { next }
		if (corpo ~ /Heartbeat:Connect|RenderStepped:Connect|Stepped:Connect/) {
			dentro[arquivo] = 1
		}
		if (dentro[arquivo] && corpo ~ /\.CFrame[ \t]*=/) {
			print arquivo ":" $2 ":" corpo
		}
	}
')
if [ -n "$MOVE_NO_SERVIDOR" ]; then
	vermelho "✗ servidor não move geometria por frame"
	printf '%s\n' "$MOVE_NO_SERVIDOR" | sed 's|^|    |'
	cinza "    Replica a ~20 Hz sem interpolação. Mande beat; quem desenha é o cliente."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ servidor não move geometria por frame"
fi

# --- Código de fora ----------------------------------------------------------
checar "sem require de id numérico"     'require\(\s*[0-9]'
checar "sem require do Núcleo"          'require\(.*NucleoCombate'

# --- Todo require aponta para módulo da própria Tool -------------------------
# O handle da Tool aparece como `Tool` ou `tool` conforme o autor — a regra é
# sobre PARA ONDE o require aponta, não sobre a caixa da variável. Enquanto
# esta lista era só minúscula, `require(Tool:WaitForChild("VFXModule"))`, que é
# módulo da própria Tool, aparecia como violação.
FORA=$(printf '%s\n' "$PURO" | grep -E 'require\(' \
	| grep -vE 'require\(\s*[Tt]ool[:.]|require\(\s*script[:.]' || true)
if [ -n "$FORA" ]; then
	vermelho "✗ todo require aponta para módulo da própria Tool"
	printf '%s\n' "$FORA" | sed 's|^|    |'
	FALHAS=$((FALHAS + 1))
else
	verde "✓ todo require aponta para módulo da própria Tool"
fi

# --- Chamadas ao Núcleo sempre sob guarda ------------------------------------
# Guarda válida: na mesma linha (_G.Combate and), num "if _G.Combate" aberto até
# 15 linhas acima, ou numa expressão que COMEÇOU guardada e continua na linha
# seguinte. Heurística de lint — o checklist manual continua valendo.
#
# A continuação não é detalhe: a forma canônica da chamada opcional é
#     local final = (_G.Combate and _G.Combate.calcular
#         and _G.Combate.calcular(owner, alvoHum, bruto)) or bruto
# e a segunda linha, lida sozinha, parece uma chamada nua. Sem esta regra o
# verificador acusava justamente o código que segue a diretriz.
SEM_GUARDA=$(printf '%s\n' "$PURO" | awk -F: '
	{
		arquivo = $1
		numero  = $2
		corpo   = substr($0, index($0, $3))

		if (arquivo != anterior) { guarda = -999; aberta = 0; anterior = arquivo }
		if (corpo ~ /if +_G\.Combate/) { guarda = numero }

		# Uma linha que COMEÇA com and/or/)/,/.. é continuação da anterior —
		# é assim que a quebra canônica se apresenta, com o `and` na frente.
		inicio = corpo
		sub(/^[ \t]*/, "", inicio)
		emContinuacao = (inicio ~ /^(and|or|\)|,|\.\.)/)

		herdada = (aberta && emContinuacao)

		if (corpo ~ /_G\.Combate and/ || herdada) {
			aberta = 1
		} else if (!emContinuacao) {
			aberta = 0
		}

		if (corpo ~ /_G\.Combate\./) {
			if (corpo ~ /_G\.Combate and/) next
			if (corpo ~ /if +_G\.Combate/) next
			if (herdada) next
			if (numero - guarda <= 15) next
			print arquivo ":" numero ":" corpo
		}
	}
')
if [ -n "$SEM_GUARDA" ]; then
	vermelho "✗ toda chamada a _G.Combate está sob guarda"
	printf '%s\n' "$SEM_GUARDA" | sed 's|^|    |'
	cinza "    A Tool tem de funcionar com o NucleoCombate deletado do place."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ toda chamada a _G.Combate está sob guarda"
fi

echo ""
if [ "$FALHAS" -eq 0 ]; then
	verde "AUTOCONTENÇÃO OK — nenhuma referência fora da Tool"
	echo ""
	exit 0
else
	vermelho "$FALHAS VERIFICAÇÃO(ÕES) FALHARAM"
	cinza "Ver DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md"
	echo ""
	exit 1
fi
