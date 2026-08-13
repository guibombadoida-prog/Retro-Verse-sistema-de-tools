# NOTAS R6 — Trident

**Status: CRU.** Nenhuma pose daqui foi extraída ainda.

## Por que vale medir

O `SaitamaAnimacoes_Originais_V1` deu a gramática que está em
`_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`, mas ele é **bake de 60 fps de punho
fechado**: soco, empurrão, uppercut. Não tem uma única animação de arma.

O `Determination` tem 214 escritas em `Motor6D.C0` distribuídas por cinco golpes, e três
deles são de **arma de haste**:

| Função | Natureza | O que a gramática ainda não cobre |
|---|---|---|
| `swing` | golpe rápido de haste | arco de arma — o Saitama não tem |
| `coloredswing` | variante com cor/carga | golpe com estado |
| `ultrastab` | estocada | **avanço linear** — o Saitama só tem rotação |
| `handfire` | conjuração à distância | braço estendido sustentado |
| `earthquake` | impacto no solo | golpe descendente com os dois braços |

`ultrastab` e `earthquake` são os dois que mais interessam: a regra 6 da gramática diz
*"empurrão, avanço e combo saem do tronco"*, e ela foi medida em **um único** avanço
(`NORMAL_SHOVE`). Uma segunda fonte confirma ou derruba a regra.

## Como extrair

O `Determination` não usa `KeyframeSequence` — a pose é escrita direto no loop. Então o
caminho não é o `medir_gramatica_r6.py` (que lê `Keyframe`), e sim o do Xester:
`FERRAMENTAS/extrair_poses_xester.py`, que lê as atribuições de `C0`/`C1` no código e
converte para a convenção `Weld` do `R6CFrameAnimator` V2:

```
C0_anim = (C0_orig * C1_orig:Inverse()):Inverse()    -- Head, braços, pernas
C0_anim = C0_orig                                     -- HRP, sem correção
```

## O que NÃO fazer

Copiar as poses. A regra já está escrita e vale aqui:

> **Nenhuma pose daqui deve ser copiada.** Este documento entrega PROPORÇÕES.
> Quem escreve a pose nova é o autor, obedecendo às proporções.

O que se extrai é **duração, proporção antecipação : recuo, junta que lidera e fração de
quadros parados** — os quatro números da tabela da gramática. A silhueta é autoral.
