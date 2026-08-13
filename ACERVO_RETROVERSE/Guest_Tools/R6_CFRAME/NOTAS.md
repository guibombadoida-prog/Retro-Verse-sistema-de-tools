# NOTAS R6 — Guest Tools

**Status: CRU** como material — nenhuma pose foi extraída, e nenhuma será: a regra é que
daqui saem PROPORÇÕES, não silhuetas. O que ficou **LIMPO** é o que se autorou a partir
delas: os sete `Poses.lua` do conjunto GUEST, em `Tools/<Nome>/Poses.lua`, gerados por
`FERRAMENTAS/gerar_poses_guest.py` — 39 poses e 17 sequências.

Esta é a fonte de pose mais **barata** que já entrou no Acervo, e o motivo é de convenção,
não de qualidade.

---

## Por que estas poses entram quase direto

O `R6CFrameAnimator` V2 do repositório solda `Weld`s próprios a partir do `Torso`, com o
pivô do ombro em `C1`. As duas Tools de porrada daqui fazem **exatamente isso**:

```lua
local rightarm = Instance.new("Weld", owner.Torso)
rightarm.Part0 = owner.Torso
rightarm.Part1 = owner["Right Arm"]
rightarm.C0 = CFrame.new(1.5, 0.5, 0)
rightarm.C1 = CFrame.new(0, 0.5, 0)
rightarm.Name = "RightArmWelde"
```

| Modelo | Escritas de pose | Onde escreve | Conversão necessária |
|---|---|---|---|
| `Trident` | 214 | **`Motor6D.C0`** | `C0_anim = (C0 * C1:Inverse()):Inverse()` |
| `Xester` | — | `Motor6D.C0`/`C1` | idem, já feito por `extrair_poses_xester.py` |
| **Guest Tools** | **78** | **`Weld.C0`, convenção do animator** | **nenhuma** |

E os `Weld` nascem no **servidor**, que é onde precisam nascer: `Weld` criado em
`LocalScript` não replica — isso já custou um bug de visibilidade neste repositório.

As juntas cobertas:

| Tool | Sufixo do `Weld` | Juntas |
|---|---|---|
| `Cano De Rua` | `…Welde` | `HumanoidRootPart`, `RightArm`, `LeftArm`, `Head` + `RightGrip` |
| `Taco de Baseball` | `…Weldbat` | as quatro acima **+ `RightLeg` e `LeftLeg`** |

---

## O que a medição diz, e onde ela contraria a gramática

As poses são interpoladas por `for i = 0, 1, passo do … step:wait() end` — o passo dá o
número de quadros, e `Stepped` roda a 60 fps.

### `Cano De Rua` — dois golpes, quatro fases

| Fase | Passo | Quadros | Tempo @60 fps |
|---|---|---|---|
| golpe 1 — antecipação | 0.14 | 8 | 0.133 s |
| golpe 1 — recuo | 0.10 | 11 | 0.183 s |
| golpe 2 — antecipação | 0.14 | 8 | 0.133 s |
| golpe 2 — recuo | 0.10 | 11 | 0.183 s |

**Golpe: 0.317 s. Proporção antecipação : recuo = 42 : 58.**

Duas leituras, e as duas importam:

- **A proporção CONFIRMA a regra 3.** O `Cano` alterna `attacknumber` entre dois golpes, ou
  seja é combo — e a `GRAMATICA_R6.md` mede combo em **35 : 65** (`CONSECUTIVE_PUNCHES`).
  42 : 58 cai no mesmo lado da metade. É a primeira confirmação independente dessa regra,
  vinda de um autor que nunca viu a nossa tabela.
- **A duração CONTRARIA a regra 1.** A regra diz que golpe rápido vive entre 0.8 s e 1.2 s,
  medido em três golpes do Saitama. Este vive em **0.317 s** — quatro vezes mais rápido.

A explicação provável é que a regra 1 foi medida em **bake de 60 fps de anime**, onde o golpe
é encenado; aqui é um cano de rua num jogo de porrada, onde o golpe é responsivo. Isso não
derruba a regra — **delimita** ela: 0.8–1.2 s é a faixa do golpe *encenado*, não do golpe
*de troca*. Vale registrar como ressalva na gramática quando alguém for autorar combate
rápido.

### `Taco de Baseball` — seis fases

Passos `0.1 · 0.1 · 0.05 · 0.12 · 0.07 · 0.05` → 11, 11, 21, 9, 15, 21 quadros → **1.467 s
somados**. É o golpe finalizador ("vibe check"), com trava de `WalkSpeed` e as pernas
soldadas. Cai dentro da faixa de golpe pesado, não de ultimate.

---

## O bug das pernas — este repositório tem uma regra exatamente para isto

O invariante do `CLAUDE.md`:

> **Perna volta ao `Humanoid`** — `ReleaseLegs` no fim; perna soldada permanentemente trava a
> caminhada.

O `Taco de Baseball` solda as duas pernas e zera `WalkSpeed` na linha 312. No caminho normal
ele desfaz tudo — linhas 344–346:

```lua
leftlegweld:destroy()
rightlegweld:destroy()
character:findFirstChildOfClass("Humanoid").WalkSpeed = 16
```

Mas o `tool.Unequipped` solta `LeftArmWeldbat`, `RightArmWeldbat`, `HeadWeldbat` e
`HumanoidRootPartWeldbat` — **e não toca nas pernas, nem devolve o `WalkSpeed`.** Não existe
`Tool.Destroying`.

Ou seja: **desequipar durante o 1.5 s do finalizador deixa o personagem soldado e parado, sem
volta.** Não é bug incondicional — é janela — mas é exatamente o caso que a regra descreve, e
é a primeira vez que ele aparece num modelo de verdade em vez de na teoria.

Isso não foi testado no Studio; é leitura do código. Vale confirmar em jogo antes de tratar
como certo.

---

## Como autorar a partir daqui

1. **Não copiar as poses.** Vale o mesmo de sempre: o que se extrai é proporção, duração e
   junta que lidera. A silhueta é autoral.
2. A proporção 42 : 58 do `Cano` e o 1.467 s do `Taco` **entram na tabela da gramática** como
   segunda fonte — a primeira que não é do Saitama.
3. Trocar `for i = 0,1,passo … :lerp(alvo, i)` por `rig:PlaySequence`. O laço original nunca
   chega ao alvo: cada volta interpola a partir do `C0` **novo**, então o resto encolhe
   geometricamente. É a mesma armadilha do `:lerp` repetido já registrada no projeto.
4. Perna sob demanda, e `ReleaseLegs` em `Unequipped` **e** `Destroying` — as duas portas.

---

## O que saiu disso, na prática

`FERRAMENTAS/gerar_poses_guest.py`, sete arquivos. A decisão que foge da tabela está
declarada no cabeçalho do gerador:

| | duração | proporção | segurados |
|---|---|---|---|
| original do `Cano` | 0.317 s | 42 : 58 | **0** |
| a tabela (regra 1) | 0.80–1.20 s | 49–59 : 51–41 | — |
| **o que ficou** | **0.50 s** | 35 : 65 | **2** |

Mais lento que o original porque ele não tinha um único quadro segurado, e a regra 7 é a que
mais muda a leitura. Mais rápido que a tabela porque a 0.8 s uma briga de rua vira
coreografia. Ultimate (`FINALIZADOR`, 1.50 s, 64% de preparação) e transformação (`PEDRA`,
2.00 s, 2 : 98) seguem a tabela sem desconto.
