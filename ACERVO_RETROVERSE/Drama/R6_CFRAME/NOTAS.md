# NOTAS R6 — Drama

**Status: CRU.** Nenhuma pose extraída.

---

## O `dodge` é a terceira fonte já na convenção do animator

O cabeçalho diz `--By Rufus14` — o mesmo autor de `A arma`, já convertida no conjunto GUEST.
E ele declara as seis juntas com `Weld` próprio:

```lua
local rightarmw
local leftarmw
local rightlegw
local leftlegw
local rootpartw
local headw
```

Seis, **incluindo as duas pernas**. O `Cano De Rua` cobria quatro e o `Taco` seis, mas o
`Taco` era o que esquecia de soltar as pernas no `Unequipped`. Vale ver como este trata:
o autor guarda `oldnetowner` e devolve, o que sugere cuidado com estado emprestado.

| Fonte | Juntas | Onde escreve | Convenção |
|---|---|---|---|
| `Trident` | 6 | `Motor6D.C0` | precisa conversão |
| `Cano De Rua` | 4 + `RightGrip` | `Weld.C0` | direta |
| `Taco de Baseball` | 6 | `Weld.C0` | direta |
| **`dodge`** | **6** | **`Weld.C0`** | **direta** |

## O que o `dodge` acrescenta que ninguém tinha

**Esquiva com i-frames.** O repertório do repositório é golpe, conjuração, consumo e
transformação — não tem uma única sequência **defensiva de movimento**. E ela tem timing
próprio:

```lua
local exhaustiontime = 20
local dhspeed = 55
local dhdecrement = 9
local dhtime = 0.65
local dhposepeed = 25
local dhanimspeed = 20
local raylength = 5
```

`dhtime = 0.65` é a duração do rolamento. Cai **exatamente** na faixa que o conjunto GUEST
escolheu para golpe de troca (0.50–0.62 s) — o que é uma terceira medição independente
apontando para a mesma região, e contra a regra 1 da gramática (0.8–1.2 s).

Vale medir com `FERRAMENTAS/medir_gramatica_r6.py` adaptado antes de autorar: se três fontes
de jogo responsivo dão 0.3–0.65 s e o Saitama dá 0.8–1.2 s, a regra 1 precisa ganhar a
ressalva por escrito.

## O que jogar fora do `dodge`

```lua
workspace.DescendantAdded:Connect(function(WHAT)
	if WHAT:IsA("Humanoid") then table.insert(ppl, WHAT.Parent) end
end)
```

Dois listeners globais que mantêm uma tabela de **todo `Humanoid` do jogo**, ligados para
sempre. É varredura do mundo por assinatura — pior que `workspace:GetDescendants()`, porque
aquele ao menos termina. O Núcleo resolve com `detectarHumanoides`, que é consulta espacial
sob demanda.

---

## `UpperSword` — a quarta câmera de golpe

`SpinCamera`, `FadeOut`, `EnterSlash`/`ExitSlash`. A `GRAMATICA_CUTSCENE.md` foi medida em
**três** fontes; esta é a quarta, e a única de espada.

Traz 4 `Animation` de pose num `Model` chamado `poses` — sinal de que o autor pensou em
keyframe. Não entram: `Animation` é proibida, e o que se aproveita é o **tempo** delas, não
o conteúdo.

## `Fists` — 2078 linhas, e o que medir nelas

31 `tick()` no modelo inteiro, quase todos aqui: é a base de tempo do combo. Antes de
autorar, vale extrair a **proporção** de cada golpe do combo — é a maior sequência de
corpo a corpo que já entrou, e a gramática só tem `CONSECUTIVE_PUNCHES` como fonte de combo.

## O que NÃO fazer

Copiar as poses. Vale o de sempre: daqui saem **proporção, duração e junta que lidera**. A
silhueta é de quem autora.
