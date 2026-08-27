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

# ─────────────────────────────────────────────────────────────────────────────
# AUTOTESTE — `bash TESTES/verificar_autocontencao.sh --autoteste`
#
# A checagem `servidor não move geometria por frame` já parou de funcionar UMA
# VEZ sem avisar: um conserto no `awk` fez a contagem dar sempre zero, e ela
# passou a imprimir verde para tudo — inclusive para o defeito que existe para
# pegar. Verificador quebrado é pior que verificador ausente, porque dá
# confiança falsa.
#
# As duas fixtures em `TESTES/fixtures/move_no_servidor/` são o antídoto: uma
# TEM o defeito e outra não, e o autoteste falha se qualquer das duas for
# classificada errado.
# ─────────────────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--autoteste" ]; then
	base="$RAIZ/TESTES/fixtures/move_no_servidor"
	saida_ruim=$(bash "$0" "$base/Ruim" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
	saida_boa=$(bash "$0" "$base/Boa" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
	falhou=0

	if ! printf '%s' "$saida_ruim" | grep -q '✗ servidor não move geometria por frame'; then
		printf '\033[31m%s\033[0m\n' "✗ AUTOTESTE: a fixture COM o defeito NÃO foi acusada"
		falhou=1
	else
		printf '\033[32m%s\033[0m\n' "✓ autoteste: a fixture com o defeito foi acusada"
	fi

	if printf '%s' "$saida_boa" | grep -q '✗ servidor não move geometria por frame'; then
		printf '\033[31m%s\033[0m\n' "✗ AUTOTESTE: a fixture SEM o defeito foi acusada (falso positivo)"
		falhou=1
	else
		printf '\033[32m%s\033[0m\n' "✓ autoteste: a fixture sem o defeito passou"
	fi

	exit $falhou
fi
ALVO="${1:-$RAIZ/Tools}"
FALHAS=0

# O pack de VFX conformado viaja DENTRO de cada Tool, mas a fonte dele mora no
# Acervo (uma só, para as 7 cópias não derivarem). Como esse código embarca na
# Tool, ele é varrido junto — senão a Regra nº 1 teria um ponto cego do tamanho
# de dez módulos.
PACK_ACERVO="$RAIZ/ACERVO_RETROVERSE/Stella_VFX_Addon/VFX"

vermelho() { printf '\033[31m%s\033[0m\n' "$1"; }
verde()    { printf '\033[32m%s\033[0m\n' "$1"; }
cinza()    { printf '\033[90m%s\033[0m\n' "$1"; }

# Emite "arquivo:linha:código" com todo comentário removido e a numeração preservada.
codigo_puro() {
	find "$ALVO" "$PACK_ACERVO" -name '*.lua' -print0 2>/dev/null | while IFS= read -r -d '' arquivo; do
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

# Casa o padrão SÓ contra o corpo da linha, nunca contra o caminho do arquivo.
# Sem isto, varrer ACERVO_RETROVERSE/ fazia a checagem "sem referência ao
# Acervo" acusar todas as linhas do pack — inclusive as vazias — porque a
# palavra estava no nome da pasta, não no código.
checar() {
	local rotulo="$1"
	local padrao="$2"
	local achado

	# `substr($0, index($0, $3))` NÃO serve aqui: quando a linha de código é
	# vazia, $3 é "" e index(s, "") devolve 0 — o substr volta a linha inteira,
	# caminho junto, e a linha vazia passa a "conter" o padrão.
	achado=$(printf '%s\n' "$PURO" \
		| awk -v p="$padrao" '
			{
				corpo = $0
				sub(/^[^:]*:[0-9]+:/, "", corpo)
				if (corpo ~ p) print $0
			}' || true)

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
# Sem exceção. Já teve uma aqui — o pack de VFX em ReplicatedStorage — e ela
# saiu: os módulos de efeito não dependiam de nada e cabiam dentro da Tool
# desde o começo. Quem não cabia era o loader do pack, e o loader não entra.
# Ver FERRAMENTAS/conformar_pack_vfx.py.
# `ReplicatedStorage` tem UMA ressalva, e ela tem nome: `DepositoVFX`, o módulo
# da Regra nº 2. Ele existe justamente para montar lá a pasta da PRÓPRIA Tool e
# desmontá-la quando ela morre.
#
# A ressalva é NOMINAL de propósito — vale para esse arquivo e para nenhum
# outro. Qualquer outro script que toque em `ReplicatedStorage` continua sendo
# violação, inclusive um que se chame parecido.
RS=$(printf '%s\n' "$PURO" | grep -E 'ReplicatedStorage' \
	| grep -v '/DepositoVFX\.lua:' || true)
if [ -n "$RS" ]; then
	vermelho "✗ sem ReplicatedStorage fora do DepositoVFX"
	printf '%s\n' "$RS" | sed 's|^|    |' | head -20
	FALHAS=$((FALHAS + 1))
else
	verde "✓ sem ReplicatedStorage fora do DepositoVFX"
fi
checar "sem ServerStorage"              'ServerStorage'
checar "sem ServerScriptService"        'ServerScriptService'
checar "sem StarterGui / StarterPack"   'StarterGui|StarterPack|StarterPlayer'
# `Lighting` continua barrado — mas com UMA exceção nomeada: as duas consultas
# de direção de astro.
#
#   Lighting:GetSunDirection()   Lighting:GetMoonDirection()
#
# As duas são LEITURA de um singleton que existe em todo place e nunca falta —
# a mesma natureza de `workspace.CurrentCamera` num LocalScript, que a Regra
# nº 1 já lista como não-violação. Elas não guardam asset, não são depósito, e
# não alteram nada: num place vazio a Tool que as usa funciona por inteiro.
#
# O que continua proibido é o que a origem do `timetools` fazia: pendurar
# `ColorCorrectionEffect` e `BlurEffect` em `Lighting`. Isso é ESCRITA em
# estado do place inteiro, e a checagem `sem escrever Lighting global` logo
# abaixo é quem cobra.
#
# A exceção é estreita de propósito: `GetService("Lighting")` sozinho, sem uma
# das duas chamadas no mesmo arquivo, continua sendo erro.
# A varredura usa `$PURO` como todas as outras: comentário não é violação, e
# este arquivo documenta a proibição em texto várias vezes.
lighting_bruto=$(printf '%s\n' "$PURO" \
	| awk '{
		corpo = $0
		sub(/^[^:]*:[0-9]+:/, "", corpo)
		if (corpo ~ /GetService\("Lighting"\)|game\.Lighting/) print $0
	  }' || true)

lighting_suspeitos=""
if [ -n "$lighting_bruto" ]; then
	while IFS= read -r linha; do
		arq="${linha%%:*}"
		if ! grep -qE 'Lighting:Get(Sun|Moon)Direction\(' "$arq" 2>/dev/null; then
			lighting_suspeitos="${lighting_suspeitos}${linha}"$'\n'
		fi
	done <<< "$lighting_bruto"
fi

if [ -n "$lighting_suspeitos" ]; then
	vermelho "✗ sem Lighting"
	printf '%s' "$lighting_suspeitos" | sed 's|^|    |'
	cinza "    Só GetSunDirection/GetMoonDirection são leitura permitida."
	FALHAS=$((FALHAS + 1))
else
	verde "✓ sem Lighting, fora as duas consultas de astro"
fi
checar "sem SoundService como depósito" 'GetService\("SoundService"\)|game\.SoundService'

# --- Estado GLOBAL do servidor -----------------------------------------------
# A Regra nº 1 vale nos dois sentidos: a Tool não lê de fora, e não SEQUESTRA o
# que é de fora. Escrever no mundo é saída legítima quando é uma peça nova; não
# é quando é uma propriedade única que todo mundo divide.
#
# O caso real: o `Gravitron 1000` do `calebe_tools.rbxmx` ciclava
# `workspace.Gravity` e o `Unequipped` dele NÃO devolvia — equipar, clicar e
# guardar deixava o servidor inteiro em gravidade 21.2 para sempre. É a mesma
# família de "câmera presa", e pior de escala: câmera presa incomoda um
# jogador, gravidade presa quebra o mapa para todos.
#
# LER `workspace.Gravity` é permitido, e as Tools de gravidade fazem isso para
# calcular impulso. O que a checagem barra é a ATRIBUIÇÃO.
checar "sem escrever workspace.Gravity" '(workspace|[Ww]orkspace|game\.Workspace)\.Gravity[[:space:]]*='
checar "sem escrever Lighting global"   '(game\.Lighting|Lighting)\.(Ambient|Brightness|ClockTime|FogEnd|TimeOfDay)[[:space:]]*='
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
#
# O perigo é escrever numa junta que JÁ TEM DONO: o script Animate padrão do
# Roblox escreve nas juntas do personagem todo frame, e dois donos por junta
# fazem a pose tremer e voltar sozinha. Foi o que bugou a primeira leva.
#
# Montar juntas de um rig que o próprio script acabou de criar — o corpo da
# bomba-NPC, por exemplo — é outra coisa: ninguém mais escreve nelas, e um
# Humanoid R6 não existe sem RootJoint e Neck. Por isso a checagem mira o
# ACESSO A JUNTA DE PERSONAGEM EXISTENTE, não a classe Motor6D em si.
checar "sem escrita em junta de personagem" \
	'\["(Right|Left) (Shoulder|Hip)"\]|\["RootJoint"\]|\["Neck"\]|FindFirstChild\("(RootJoint|Neck|(Right|Left) (Shoulder|Hip))"\)|WaitForChild\("(RootJoint|Neck|(Right|Left) (Shoulder|Hip))"\)'
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

# --- Fluidez: nada de mover geometria pelo servidor ---------------------------
#
# Part ancorada cujo CFrame é escrito por script de SERVIDOR replica a ~20 Hz e
# o cliente NÃO interpola: o movimento chega em passos discretos. Foi isso que
# deixou a órbita, o voo do disco e a marca do vínculo "não fluidos".
#
# Movimento contínuo é do cliente, a 60 Hz, a partir de um beat com parâmetros.
# O servidor segue dono do dano, calculando a MESMA fórmula sem geometria.
# O LATCH TEM ESCOPO DE BLOCO, NÃO DE ARQUIVO.
#
# A primeira versão desta checagem ligava `dentro[arquivo] = 1` no primeiro
# `Heartbeat:Connect` e nunca mais desligava: dali em diante, TODA escrita de
# `.CFrame` no arquivo era acusada — inclusive uma escrita única, num teleporte,
# quinhentas linhas abaixo e fora de laço nenhum.
#
# Isso não é rigor, é falso positivo. E falso positivo em verificador é pior
# que checagem ausente, porque ensina quem escreve a contornar o verificador em
# vez de escrever certo — foi o que quase aconteceu com a reversão do conjunto
# TEMPO, que faz UM salto e estava sendo acusada de mover por quadro.
#
# Agora a profundidade é contada: `function` abre, `end` fecha, e o latch cai
# quando o corpo do `Connect` termina. O que a checagem cobra continua sendo
# exatamente o que ela sempre quis cobrar — `.CFrame =` DENTRO do laço.
MOVE_NO_SERVIDOR=$(printf '%s\n' "$PURO" | awk -F: '
	# O PADRÃO VEM COMO STRING, NÃO COMO /regex/.
	#
	# awk não tem regex como valor de primeira classe: `conta(x, /function/)`
	# avalia `$0 ~ /function/` PRIMEIRO e passa 0 ou 1, e o `gsub` acaba
	# contando ocorrências do dígito. A contagem dava sempre zero, o latch caía
	# na primeira linha, e a checagem parou de pegar o defeito que ela existe
	# para pegar — sem nenhum aviso, porque continuava imprimindo verde.
	function conta(texto, alvo,   copia) {
		copia = texto
		return gsub(alvo, "", copia)
	}
	{
		arquivo = $1
		corpo   = substr($0, index($0, $3))

		if (arquivo !~ /_Server_V[0-9]+\.lua/) { next }

		if (!dentro[arquivo] &&
				corpo ~ /Heartbeat:Connect|RenderStepped:Connect|Stepped:Connect/) {
			dentro[arquivo] = 1
			prof[arquivo] = 0
		}

		if (dentro[arquivo]) {
			if (corpo ~ /\.CFrame[ \t]*=/) {
				print arquivo ":" $2 ":" corpo
			}
			prof[arquivo] += conta(corpo, "function")
			prof[arquivo] -= conta(corpo, "(^|[^a-zA-Z0-9_])end([^a-zA-Z0-9_]|$)")
			if (prof[arquivo] <= 0) {
				dentro[arquivo] = 0
			}
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

# --- A global do Núcleo foi APOSENTADA ---------------------------------------
#
# Ela era permitida sob guarda — global opcional, sempre com `and`. Não é mais:
# o Núcleo saiu do repositório inteiro. Uma Tool que se comporta de dois jeitos
# conforme exista ou não um script em outro lugar do place não é a Tool que o
# modelo de origem era, e o legado da origem vale mais que o bônus.
#
# O que era fallback virou o caminho único, e ele já estava escrito e verificado
# nas 94 — nenhuma Tool perdeu habilidade quando o de cima saiu.
checar "sem _G.Combate — a global foi aposentada" '_G\.Combate'

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
