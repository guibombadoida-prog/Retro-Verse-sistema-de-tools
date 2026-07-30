# Guardião do Tempo — poses R6 CFrame

19 quadros extraídos do `Convert`, mais 5 autorais para o que o modelo não animava.

## Como foram extraídas

O modelo anima por `Clerp(<junta>.C0, <alvo>, alpha)` dentro de laços
`for i = 0, LIMITE, PASSO / Animation_Speed do`. Cada laço vira **um quadro**.

As expressões de `<alvo>` foram avaliadas numericamente com as constantes do próprio modelo:

```
ROOTC0          = CF(0, 0, 0)    * ANGLES(RAD(-90), RAD(0),  RAD(180))
NECKC0          = CF(0, 1, 0)    * ANGLES(RAD(-90), RAD(0),  RAD(180))
RIGHTSHOULDERC0 = CF(-0.5, 0, 0) * ANGLES(RAD(0),   RAD(90),  RAD(0))
LEFTSHOULDERC0  = CF(0.5, 0, 0)  * ANGLES(RAD(0),   RAD(-90), RAD(0))
```

`SINE = 0`, o que **congela** a oscilação do `Idle` numa fase fixa (`COS(0) = 1`, `SIN(0) = 0`)
e transforma o laço num quadro estático.

O resultado é a **C0 absoluta**, emitida como matriz completa
`CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)`.

> ⚠️ Por serem absolutas, todo quadro extraído traz `absoluto = true` e **exige o
> `R6CFrameAnimator` V2**. No V1, que só entende offset sobre a base, a pose sai torta.

### Conferência

`ROOTC0 * CF(0, 0.2, -0.05)`: a rotação de `ROOTC0` é `[[-1,0,0],[0,0,1],[0,1,0]]`, que leva
`(0, 0.2, -0.05)` em `(0, -0.05, 0.2)` — exatamente a translação emitida no primeiro quadro de
`TemperoTemporal`. A extração confere.

## Juntas usadas

| Junta | Pai | Usada em |
|---|---|---|
| `RootJoint` | `HumanoidRootPart` | todos os quadros |
| `Neck` | `Torso` | todos os quadros extraídos |
| `Right Shoulder` | `Torso` | todos |
| `Left Shoulder` | `Torso` | todos |
| `Right Hip` | `Torso` | só nos quadros extraídos |
| `Left Hip` | `Torso` | só nos quadros extraídos |

Os quadros autorais mexem em 3 juntas; os extraídos, nas 6.

## Sequências

| Arquivo | Origem | Quadros | Duração |
|---|---|---|---|
| `Poses_GuardiaoDoTempo_TemperoTemporal_V1.lua` | `TemporalTemper` | 5 | 0,64 s |
| `Poses_GuardiaoDoTempo_Cronostase_V1.lua` | **autoral** | 3 | 0,58 s |
| `Poses_GuardiaoDoTempo_AvancoRapido_V1.lua` | `FastForward` + autoral | 4 + 2 | 0,49 s + 0,32 s |
| `Poses_GuardiaoDoTempo_CanhaoCronos_V1.lua` | `ChronosCannon` | 2 | 1,00 s |
| `Poses_GuardiaoDoTempo_Temporalise_V1.lua` | `Temporalysis` | 1 | 0,35 s |
| `Poses_GuardiaoDoTempo_ArmadilhaTemporal_V1.lua` | `TemporalTrap` | 2 | 1,00 s |
| `Poses_GuardiaoDoTempo_AvoDoTempo_V1.lua` | `GrandfatherTime` + `Taunt` | 3 + 2 | 0,75 s + 0,58 s |

`Chronostasis` não tem nenhum laço de pose no modelo — é só efeito e teleporte. Os 3 quadros da
Cronostase são **autorais**, e estão declarados como tal no cabeçalho do arquivo.

## Duração

`iterações = LIMITE / (PASSO / Animation_Speed)`, com `Animation_Speed = 3`, e cada iteração
valendo um quadro a 60 fps. Piso de 0,08 s: abaixo disso o quadro não é percebido (`_PADROES.md`).

## Armadilhas

- **Não misturar V1 e V2 na mesma Tool.** Pose absoluta rodando em animador de offset fica torta.
- Os quadros extraídos carregam a fase congelada da respiração do `Idle`. Se em jogo a pose
  parecer levemente "inclinada" em repouso, é isto — e o ajuste é autoral, no arquivo de poses.
- `Temporalise` tem **um** quadro só: a sequência é curta de propósito no modelo. Se precisar de
  mais dramaturgia, acrescentar quadros autorais, declarando-os no cabeçalho.
