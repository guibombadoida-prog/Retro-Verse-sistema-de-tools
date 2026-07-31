# R6 CFrame — o animator do projeto

## `R6CFrameAnimator_V1.lua` é O animator. Não escreva outro.

Extraído das Tools da família **His Cube** (Server V5 / variantes V1). É código de
produção, já testado em jogo. Vive aqui como fonte única e é **copiado para dentro**
de cada Tool com o nome de objeto `R6CFrameAnimator` (Regra nº 1).

```lua
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))

local rig = Animator.new(personagem, "NomeDaTool", Poses.POSES)
rig:PlayPose("GOLPE_1", 0.12)
rig:StartIdleBob("IDLE", "RightArm")   -- opcional
rig:Destroy()                          -- Unequipped, Died, Destroying
```

## Como ele funciona — e por que assim

O animator **cria `Weld`s próprios** e faz tween do `C0` deles:

| Weld | Part0 → Part1 | C0 base |
|---|---|---|
| `RightArm` | Torso → Right Arm | `CFrame.new(1.5, 0, 0)` |
| `LeftArm` | Torso → Left Arm | `CFrame.new(-1.5, 0, 0)` |
| `Head` | Torso → Head | `CFrame.new(0, 1.5, 0)` |
| `HRP` | HumanoidRootPart → Torso | `CFrame.new()` |

Também corrige o `RightGrip.C0`, para a Tool assentar na mão.

## ⚠️ O bug que isto evita — e que eu causei

**Escrever em `Motor6D.C0` não funciona.** O script `Animate` que o Roblox coloca em
todo personagem escreve nos mesmos `Motor6D` (`Right Shoulder`, `Neck`, `RootJoint`…)
a cada frame, para andar, parar e pular. Um segundo escritor na mesma junta significa
dois donos brigando todo frame: a pose treme, salta e volta sozinha.

Foi exatamente isso que aconteceu nas Tools do Guardião do Tempo na primeira versão:
eu escrevi um animator que mexia nos `Motor6D` direto, em vez de usar este. A animação
bugou. **O `Weld` próprio existe para não ter esse segundo dono.**

O antigo `R6CFrameAnimator_V2.lua` (meu, baseado em `Motor6D`) foi **removido do
Acervo**. Não é uma alternativa: é a versão errada.

## Converter pose de `Motor6D` para `Weld`

Se aparecer material de terceiro com poses em `Motor6D.C0` absoluta — como o modelo
Guardião do Tempo tinha — a conversão é exata:

```
WeldC0 = MotorC0 * MotorC1⁻¹
```

com o `C1` padrão do R6:

| Junta Motor6D | `C1` padrão | Vira |
|---|---|---|
| `Right Shoulder` | `CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, π/2, 0)` | `RightArm` |
| `Left Shoulder` | `CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -π/2, 0)` | `LeftArm` |
| `Neck` | `CFrame.new(0, -0.5, 0) * CFrame.Angles(-π/2, 0, π)` | `Head` |
| `RootJoint` | `CFrame.new(0, 0, 0) * CFrame.Angles(-π/2, 0, π)` | `HRP` |

**Conferência:** com a pose neutra, a fórmula devolve exatamente `CFrame.new(1.5, 0, 0)`,
`CFrame.new(-1.5, 0, 0)`, `CFrame.new(0, 1.5, 0)` e `CFrame.new()` — as quatro bases do
animator. Se der outra coisa, o `C1` usado está errado.

## Limite conhecido: pernas

O animator solda **quatro** juntas. `Right Hip` e `Left Hip` não têm equivalente —
pose de perna vinda de terceiro é descartada na conversão, e isso fica declarado no
cabeçalho de cada arquivo de poses.

Estender para pernas é decisão de projeto, não improviso local. O padrão seria
`Torso → Right Leg` com base `CFrame.new(0.5, -2, 0)` e `Torso → Left Leg` com
`CFrame.new(-0.5, -2, 0)` — mesma fórmula de conversão.

## Onde já é usado

As 7 Tools do conjunto Guardião do Tempo, e o `_TEMPLATE_Tool`.
