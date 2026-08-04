# R6 CFrame — o animator do projeto

## `R6CFrameAnimator_V2.lua` é O animator. Não escreva outro.

V2 é **superset do V1**: mesma API (`PlayPose` · `SetJoint` · `StartIdleBob` ·
`StopIdleBob` · `Destroy`), mesmas bases de Weld, mesmos nomes de junta. Toda tabela
de poses escrita para o V1 roda no V2 sem tocar em uma linha.

O V1 continua no Acervo como **referência histórica e mínimo comum**. Não é alternativa:
se a Tool é nova, nasce no V2.

```lua
local Animator = require(tool:WaitForChild("R6CFrameAnimator"))

local rig = Animator.new(personagem, "NomeDaTool", Poses.POSES, Poses.SEQUENCIAS, Poses.TRACKS)
rig:PlayPose("GOLPE_1", 0.12)                      -- pose única (V1 e V2)
rig:PlaySequence("TRANSFORMACAO", aoBeat, aoFim)   -- timeline por Tween.Completed
rig:PlayTrack("SERIOUS_PUNCH", aoEvento, aoFim)    -- track amostrada por dt
rig:LockCharacter(true)                            -- trava andar/pular na cutscene
rig:StartTremor("HRP", 0.05, 22)                   -- vibração determinística
rig:Destroy()                                      -- Unequipped, Died, Destroying
```

## As seis juntas

| Weld | Part0 → Part1 | C0 base | Quando existe |
|---|---|---|---|
| `RightArm` | Torso → Right Arm | `CFrame.new(1.5, 0, 0)` | sempre |
| `LeftArm` | Torso → Left Arm | `CFrame.new(-1.5, 0, 0)` | sempre |
| `Head` | Torso → Head | `CFrame.new(0, 1.5, 0)` | sempre |
| `HRP` | HumanoidRootPart → Torso | `CFrame.new()` | sempre |
| `RightLeg` | Torso → Right Leg | `CFrame.new(0.5, -2, 0)` | **sob demanda** |
| `LeftLeg` | Torso → Left Leg | `CFrame.new(-0.5, -2, 0)` | **sob demanda** |

Também corrige o `RightGrip.C0`, para a Tool assentar na mão.

### Perna é sob demanda, e é solta no fim

As pernas só ganham `Weld` quando **uma pose as cita**, e são liberadas por
`ReleaseLegs()` no fim da sequência ou da track. Isso não é detalhe de implementação:
uma perna soldada permanentemente **trava a caminhada**, porque o `Humanoid` deixa de
mandar nela. Fora de cutscene, o personagem tem de andar normal.

Se você chamar `PlayPose` com uma pose de perna e nunca rodar uma sequência, ninguém
solta a perna — `ReleaseLegs()` é seu, manualmente, ou use `PlaySequence`/`PlayTrack`.

## `PlaySequence` × `PlayTrack` — quando usar qual

| | `PlaySequence` | `PlayTrack` |
|---|---|---|
| Dado | poucos keyframes autorais, com easing por beat | dezenas/centenas de keyframes de bake |
| Motor | encadeia `Tween.Completed` | amostra por acumulador `dt` em `Heartbeat` |
| Timing | some ~1 frame por beat (custo do encadeamento) | exato: nenhum acúmulo |
| Serve para | golpe, transformação, dramaturgia autoral | animação remasterizada de pack |

Regra prática: **até ~10 beats, `PlaySequence`. Acima disso, `PlayTrack`** — com 100
keyframes encadeados o erro de um frame por beat vira quase dois segundos de atraso.

## ⚠️ O bug que isto evita — e que eu causei

**Escrever em `Motor6D.C0` não funciona.** O script `Animate` que o Roblox coloca em
todo personagem escreve nos mesmos `Motor6D` (`Right Shoulder`, `Neck`, `RootJoint`…)
a cada frame, para andar, parar e pular. Um segundo escritor na mesma junta significa
dois donos brigando todo frame: a pose treme, salta e volta sozinha.

Foi exatamente isso que aconteceu nas Tools do Guardião do Tempo na primeira versão:
eu escrevi um animator que mexia nos `Motor6D` direto, em vez de usar este. A animação
bugou. **O `Weld` próprio existe para não ter esse segundo dono.**

> Nota histórica: houve um `R6CFrameAnimator_V2.lua` **meu**, baseado em `Motor6D`, que
> foi removido do Acervo por ser a versão errada. O V2 que está aqui **não é aquele** —
> é o do projeto, soldando `Weld`, e não tem parentesco com o arquivo removido.

## Converter pose de `Motor6D` para `Weld`

Se aparecer material de terceiro com poses em `Motor6D.C0` absoluta — como o modelo
Guardião do Tempo tinha — a conversão é exata:

```
WeldC0 = MotorC0 * MotorC1⁻¹
```

Para `KeyframeSequence`/`Pose`, que é o formato de pack de animação, entra o valor da
pose no meio:

```
WeldC0 = MotorC0 * Pose.CFrame * MotorC1⁻¹
```

com o `C1` padrão do R6:

| Junta Motor6D | `C1` padrão | Vira |
|---|---|---|
| `Right Shoulder` | `CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, π/2, 0)` | `RightArm` |
| `Left Shoulder` | `CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -π/2, 0)` | `LeftArm` |
| `Right Hip` | `CFrame.new(0.5, 1, 0) * CFrame.Angles(0, π/2, 0)` | `RightLeg` |
| `Left Hip` | `CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -π/2, 0)` | `LeftLeg` |
| `Neck` | `CFrame.new(0, -0.5, 0) * CFrame.Angles(-π/2, 0, π)` | `Head` |
| `RootJoint` | `CFrame.new(0, 0, 0) * CFrame.Angles(-π/2, 0, π)` | `HRP` |

**Conferência:** com a pose neutra, a fórmula devolve exatamente `CFrame.new(1.5, 0, 0)`,
`CFrame.new(-1.5, 0, 0)`, `CFrame.new(0.5, -2, 0)`, `CFrame.new(-0.5, -2, 0)`,
`CFrame.new(0, 1.5, 0)` e `CFrame.new()` — as seis bases do animator. Se der outra
coisa, o `C1` usado está errado.

## Onde já é usado

As 7 Tools do conjunto Guardião do Tempo, e o `_TEMPLATE_Tool`.

## Biblioteca de referência

`ACERVO_RETROVERSE/Saitama_Animacoes_Referencia/` tem 2417 keyframes de animação de
pack **já convertidos para este formato**. É material de consulta para autorar — silhueta,
timing, ritmo de golpe — não é runtime. Ver a `FICHA.md` de lá: o dado é derivado de
terceiro e está **CRU**.
