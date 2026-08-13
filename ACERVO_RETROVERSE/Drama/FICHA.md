# Modelo: Drama — 3 Tools de briga

- Autor original:            **Rufus14** no `dodge` (declarado no cabeçalho); os outros dois **a confirmar** ⚠️
- Origem:                    `drama.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Drama/` · notas em `R6_CFRAME/NOTAS.md`

---

## O que é

**Três `Tool`**, e é o modelo com mais linha por instância que já entrou aqui: 47 instâncias
para **2513 linhas**. Quase tudo é código.

| Tool | Instâncias | Linhas | O que faz |
|---|---|---|---|
| `Fists` | 21 | **2078** | sistema de luta corpo a corpo — combo, bloqueio, agarrão |
| `UpperSword` | 24 | 323 | espada com uppercut e arremesso, com câmera |
| `dodge` | **2** | 153 | esquiva com i-frames — **um Script e mais nada** |

**Três cai exato no PISO** da regra de distribuição. Não sobra nem falta.

---

## `dodge` é do mesmo autor que `A arma`

O cabeçalho diz `--By Rufus14`, que é quem assina o revólver já convertido no conjunto GUEST.
E ele traz a mesma marca de qualidade:

```lua
local rightarmw, leftarmw, rightlegw, leftlegw, rootpartw, headw
```

**Weld próprio por junta, na convenção do `R6CFrameAnimator`** — as seis, incluindo as pernas.
É a terceira fonte a chegar já nessa convenção, depois do `Cano De Rua` e do `Taco`.

Ele guarda `oldnetowner` e devolve, tem `exhaustiontime`, `hpusegate` (*"you can set it below
100 to make it only usable while injured"*) e `raylength` — parâmetros nomeados no topo, que é
o que este repositório chama de bloco `CFG`. Autor cuidadoso.

**O que não presta nele:** dois `workspace.DescendantAdded` / `DescendantRemoving` globais que
mantêm uma tabela `ppl` de todos os `Humanoid` do jogo. Isso é varrer o mundo por assinatura —
mesma família do `workspace:GetDescendants()`, e pior, porque fica ligado para sempre. O
Núcleo já resolve isso com `detectarHumanoides`.

## `Fists` — 2078 linhas, e nenhum `TakeDamage`

Nove escritas em `Health` e **zero** `TakeDamage`. Mais quatro `BreakJoints` e três
`workspace:GetDescendants()`. É o oposto do `Calebe_Tools`, que já chegou usando a API certa.

`Health = Health - x` ignora `ForceField`, e `BreakJoints` desmonta personagem sem volta. Os
dois são proibições diretas do `CLAUDE.md`.

## `UpperSword` — a espada clássica, com câmera

`Uppercut`, `SpinCamera`, `throwCharacter`, `tagHumanoid`/`untagHumanoid`, `DoSlash`,
`EnterSlash`/`ExitSlash`, `FadeOut`. É o remix mais comum da espada padrão do Roblox, e traz o
que interessa: **uma quarta implementação de câmera de golpe** para a
`GRAMATICA_CUTSCENE.md`, que hoje tem três fontes.

Traz também 4 `Animation` de pose (`1`, `2`, `3`, `4`) num `Model` chamado `poses` — sinal de
que o autor pensou em keyframe, não em CFrame. Não entra: `Animation` é proibida.

E dois `Sound` apontam para `rbxasset://sounds/swordslash.wav` e `unsheath.wav` — arquivos
**locais do cliente Roblox**, não `rbxassetid`. Funcionam, e é o único par de sons do
repositório que não depende do catálogo.

---

## O passe §12.12.2

| Achado | Quantos |
|---|---|
| `math.random` | 39 |
| `tick()` | **31** |
| `:Destroy()` | 18 |
| `Health =` | 10 |
| `wait()` | 9 |
| `BreakJoints` | 4 |
| `delay(` | 3 |
| `workspace:GetDescendants()` | 3 |
| `LoadAnimation` + 5 `Animation` | 2 |
| `ScreenGui` (2 instâncias) | 2 |
| `TakeDamage` | **1** ⚠️ |

Os 31 `tick()` são o número que salta: `tick()` alimentando geometria foi o que picotou a
animação das bombas, e aqui ele é a base de tempo de tudo.

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`, zero `ReplicatedStorage`/`ServerStorage`. Limpo.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO
