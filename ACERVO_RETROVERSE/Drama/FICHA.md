# Modelo: Drama — 3 Tools de briga → **7 Tools**

- Autor original:            **Rufus14** no `dodge` (declarado no cabeçalho); os outros dois **a confirmar** ⚠️
- Origem:                    `drama.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **LIMPO** — passe §12.12.2 executado; falta licença
- Onde vive:                 `MODELOS_ENTRADA/Drama/` · as **7 Tools** em `Tools/`

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

## Passe de conformidade §12.12.2 — EXECUTADO

```bash
python3 FERRAMENTAS/preparar_drama.py          # 3 Handles -> 7 Tools
python3 FERRAMENTAS/gerar_poses_drama.py       # 7 Poses.lua
python3 FERRAMENTAS/gerar_servers_drama.py     # Server · Client · VFX · CutsceneCam
python3 FERRAMENTAS/clonar_tool.py montar ...  # os .rbxmx
python3 FERRAMENTAS/converter_para_rbxm.py ... # a entrega
```

Saíram **7 Tools** — `Drama_7_Tools.rbxm`. `Fists` e `dodge` não têm Handle
nenhum, e as cinco derivadas deles ganharam um **invisível de 0.4 stud**. Duas
têm **cutscene**: `Corte Frio` e `TryHard`.

### A regra 2 da gramática de cutscene finalmente saiu do papel

`GRAMATICA_CUTSCENE.md` regra 2 — **enquadramento por espectador** — foi escrita
a partir do YorrSlayer e nunca tinha sido implementada. O motivo: a
`CutsceneCam` era `LocalScript`, e LocalScript dentro de Tool só roda para quem
a segura. **O alvo nunca executava o arquivo**, então a metade da cena que era
dele não existia.

Aqui ela é `Script` com `RunContext = Client`, e o servidor manda um
`FireClient` por espectador com o papel de cada um. Só o portador e o alvo
entram — quem está longe não perde a câmera por briga alheia.

### O que foi trocado

| Defeito da origem | Conserto |
|---|---|
| 9 `Health = Health - x` contra **1** `TakeDamage` no `Fists` inteiro | `TakeDamage` pelo Núcleo |
| 4 `BreakJoints` | `PlatformStand` com prazo |
| 2 `workspace.DescendantAdded`/`Removing` globais no `dodge`, ligados para sempre | `detectarHumanoides`, consulta espacial sob demanda |
| **31 `tick()`** | `os.clock()` para recarga, acumulador `dt` para animação |
| 2 `ScreenGui` | `ContextActionService`; o combo é estado do Server |
| 5 `Animation` + 2 `LoadAnimation` | pose CFrame sob `R6CFrameAnimator` |
| um `Sound` chamado `Sound`, repetido 4× no mesmo pai | 4 papéis com nome de papel |
| 39 `math.random` · 18 `:Destroy()` · 9 `wait()` · 3 `delay()` · 3 `GetDescendants()` | trocados |

### O que a origem deu, e ficou

O **`dhtime = 0.65`** do `dodge` — a duração da esquiva, medida por Rufus14. É o
único número do conjunto abaixo da faixa da regra 1, e está declarado: esquiva
lenta não é esquiva.

E os quatro sons, todos do próprio modelo. Dois deles são `rbxasset://sounds/`,
conteúdo do **cliente Roblox** — mais "dentro" que qualquer id de catálogo,
porque não há nada para buscar. `TESTES/verificar_rbxmx.py` foi ensinado a
aceitar essa forma por causa deles; recusá-la era o verificador sendo estreito.

⚠️ A paleta sonora é **fina**: quatro timbres para sete Tools.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo. Nada aqui rodou no Studio — a verificação
é toda estática, e a cutscene por espectador é justamente o tipo de coisa que só
o jogo confirma.
