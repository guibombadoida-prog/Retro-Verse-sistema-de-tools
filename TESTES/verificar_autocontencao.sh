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
			{
				linha = $0
				if (bloco) {
					pos = index(linha, "]]")
					if (pos > 0) { bloco = 0; linha = substr(linha, pos + 2) } else { linha = "" }
				}
				if (!bloco) {
					pos = index(linha, "--[[")
					if (pos > 0) { bloco = 1; linha = substr(linha, 1, pos - 1) }
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
checar "sem ReplicatedStorage"          'ReplicatedStorage'
checar "sem ServerStorage"              'ServerStorage'
checar "sem ServerScriptService"        'ServerScriptService'
checar "sem StarterGui / StarterPack"   'StarterGui|StarterPack|StarterPlayer'
checar "sem Lighting"                   'GetService\("Lighting"\)|game\.Lighting'
checar "sem SoundService como depósito" 'GetService\("SoundService"\)|game\.SoundService'
checar "sem InsertService"              'InsertService'
checar "sem referência ao Acervo"       'ACERVO'

# --- Ler de workspace é dependência; escrever nele é saída, e é permitido ----
checar "sem busca em workspace"         'workspace[:.](FindFirstChild|WaitForChild|FindFirstDescendant)|game\.Workspace[:.](FindFirstChild|WaitForChild)'

# --- Código de fora ----------------------------------------------------------
checar "sem require de id numérico"     'require\(\s*[0-9]'
checar "sem require do Núcleo"          'require\(.*NucleoCombate'

# --- Todo require aponta para módulo da própria Tool -------------------------
FORA=$(printf '%s\n' "$PURO" | grep -E 'require\(' \
	| grep -vE 'require\(\s*tool[:.]|require\(\s*script\.Parent' || true)
if [ -n "$FORA" ]; then
	vermelho "✗ todo require aponta para módulo da própria Tool"
	printf '%s\n' "$FORA" | sed 's|^|    |'
	FALHAS=$((FALHAS + 1))
else
	verde "✓ todo require aponta para módulo da própria Tool"
fi

# --- Chamadas ao Núcleo sempre sob guarda ------------------------------------
# Guarda válida: na mesma linha (_G.Combate and) ou num "if _G.Combate" aberto
# até 15 linhas acima. Heurística de lint — o checklist manual continua valendo.
SEM_GUARDA=$(printf '%s\n' "$PURO" | awk -F: '
	{
		arquivo = $1
		numero  = $2
		corpo   = substr($0, index($0, $3))

		if (arquivo != anterior) { guarda = -999; anterior = arquivo }
		if (corpo ~ /if +_G\.Combate/) { guarda = numero }

		if (corpo ~ /_G\.Combate\./) {
			if (corpo ~ /_G\.Combate and/) next
			if (corpo ~ /if +_G\.Combate/) next
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
