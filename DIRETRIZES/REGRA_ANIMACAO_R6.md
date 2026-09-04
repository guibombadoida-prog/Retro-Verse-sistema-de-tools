# REGRA DA ANIMAÇÃO R6
**Retro-Verse / Studios** · precedência: abaixo da autocontenção e do ciclo de vida do VFX, acima da base

---

## O enunciado

> Animação de Tool é **`Weld.C0` em CFrame**, tocada pelo `R6CFrameAnimator` canônico.
> Nada de `Animation`, nada de `AnimationTrack`, nada de escrita em `Motor6D`.

---

## Por que — o bug que originou a regra

Todo personagem do Roblox recebe um script `Animate`, e ele escreve nos `Motor6D`
(`Right Shoulder`, `Left Shoulder`, `Neck`, `RootJoint`, `Right Hip`, `Left Hip`) **a cada
frame**, para andar, parar e pular.

Um animator que também escreve em `Motor6D.C0` é um **segundo dono da mesma junta**. Os
dois brigam todo frame: a pose treme, salta e volta sozinha. Não é bug de timing nem de
easing — é dois escritores, e não tem conserto por ajuste.

Foi o que bugou a primeira leva de Tools deste repositório.

**A saída é não disputar a junta:** o animator canônico cria `Weld`s próprios, com nome
próprio, e anima o `C0` deles. O `Animate` segue mexendo nos `Motor6D` dele, sem colisão.

---

## O animator canônico

`R6CFrameAnimator_V2` — copiado para dentro de cada Tool com o nome de objeto
`R6CFrameAnimator` (Regra nº 1). Fonte única em
`ACERVO_RETROVERSE/_AUTORAL_RetroVerse/R6_CFRAME/`.

**Não escreva outro animator.** Se faltar recurso, a saída é V3 declarada no Acervo, com
a versão antiga substituída e a substituição no relatório de entrega — nunca um animator
local dentro de uma Tool.

V2 é **superset do V1**: mesma API, mesmas bases, mesmos nomes de junta. Toda tabela de
poses escrita para o V1 roda no V2 sem alteração. O V1 fica no Acervo como referência
histórica; Tool nova nasce no V2.

### As seis juntas

| Junta | Part0 → Part1 | C0 base | Existe |
|---|---|---|---|
| `RightArm` | Torso → Right Arm | `CFrame.new(1.5, 0, 0)` | sempre |
| `LeftArm` | Torso → Left Arm | `CFrame.new(-1.5, 0, 0)` | sempre |
| `Head` | Torso → Head | `CFrame.new(0, 1.5, 0)` | sempre |
| `HRP` | HumanoidRootPart → Torso | `CFrame.new()` | sempre |
| `RightLeg` | Torso → Right Leg | `CFrame.new(0.5, -2, 0)` | sob demanda |
| `LeftLeg` | Torso → Left Leg | `CFrame.new(-0.5, -2, 0)` | sob demanda |

**Nome de junta fora desta lista é erro silencioso** — o animator ignora e a pose não sai.

---

## Perna é sob demanda, e tem de ser solta

As pernas só ganham `Weld` quando uma pose as cita, e voltam ao `Humanoid` por
`ReleaseLegs()` no fim da sequência ou da track.

Isso não é otimização. **Perna soldada permanentemente trava a caminhada** — o `Humanoid`
deixa de mandar nela e o personagem desliza pelo mapa com as pernas paradas.

| Você chamou | Quem solta a perna |
|---|---|
| `PlaySequence` / `PlayTrack` | o animator, no fim |
| `CancelSequence` / `Destroy` | o animator |
| `PlayPose` com pose de perna | **você**, chamando `ReleaseLegs()` |

A terceira linha é a armadilha. Pose de perna avulsa por `PlayPose` fora de sequência
exige `ReleaseLegs()` explícito.

---

## `PlaySequence` × `PlayTrack`

| | `PlaySequence` | `PlayTrack` |
|---|---|---|
| Dado | poucos keyframes autorais, easing por beat | dezenas/centenas de keyframes de bake |
| Motor | encadeia `Tween.Completed` | amostra por acumulador `dt` em `Heartbeat` |
| Erro de timing | ~1 frame por beat, acumulado | nenhum |
| Serve para | golpe, transformação, dramaturgia | animação remasterizada de pack |

**Até ~10 beats, `PlaySequence`. Acima disso, `PlayTrack`.** Com 100 keyframes
encadeados, o frame perdido por beat vira quase dois segundos de atraso no fim.

`task.wait(duração)` **não** é forma válida de encadear beat. O encadeamento é por
`Tween.Completed` (sequência) ou por acumulador `dt` (track) — `task.wait` erra o alvo
sempre que o frame estica.

---

## Formato da tabela de poses

ModuleScript `Poses`, filho direto da Tool:

```lua
Poses.POSES = {
    NEUTRO = {
        RightArm = CFrame.new(1.5, 0, 0),
        LeftArm  = CFrame.new(-1.5, 0, 0),
        Head     = CFrame.new(0, 1.5, 0),
        HRP      = CFrame.new(),
    },
    GOLPE_1 = { RightArm = ..., HRP = ... },
}

Poses.SEQUENCIAS = {
    GOLPE = {
        { pose = "GOLPE_1", time = 0.10, style = "Back",  dir = "In"  },
        { pose = "GOLPE_2", time = 0.08, style = "Quint", dir = "Out", tremor = 0.04 },
        { pose = "NEUTRO",  time = 0.18 },
    },
}
```

Cada pose cita **só** as juntas que mexem. Junta ausente fica onde estava — é assim que
se sobrepõe pose de braço a uma pose de tronco em andamento.

Variação entre golpes vem de **índice sequencial**, nunca de `math.random` (§10).

---

## Converter pose de terceiro

Material de pack vem em `KeyframeSequence`/`Pose` sobre `Motor6D`. A conversão é exata:

```
WeldC0 = MotorC0 * Pose.CFrame * MotorC1⁻¹
```

Sem `Pose.CFrame` (quando a fonte já dá o `C0` absoluto do Motor6D):

```
WeldC0 = MotorC0 * MotorC1⁻¹
```

`C1` padrão do R6:

| Junta Motor6D | `C1` | Vira |
|---|---|---|
| `Right Shoulder` | `CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, π/2, 0)` | `RightArm` |
| `Left Shoulder` | `CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -π/2, 0)` | `LeftArm` |
| `Right Hip` | `CFrame.new(0.5, 1, 0) * CFrame.Angles(0, π/2, 0)` | `RightLeg` |
| `Left Hip` | `CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -π/2, 0)` | `LeftLeg` |
| `Neck` | `CFrame.new(0, -0.5, 0) * CFrame.Angles(-π/2, 0, π)` | `Head` |
| `RootJoint` | `CFrame.Angles(-π/2, 0, π)` | `HRP` |

**Conferência obrigatória:** rode a pose neutra pela fórmula. Tem de sair exatamente
`CFrame.new(1.5,0,0)`, `CFrame.new(-1.5,0,0)`, `CFrame.new(0.5,-2,0)`,
`CFrame.new(-0.5,-2,0)`, `CFrame.new(0,1.5,0)` e `CFrame.new()`. Qualquer outra coisa
significa `C1` errado — e a conversão inteira sai torta de um jeito difícil de ver.

---

## Autoria: o bake não é a animação

Pack vem baked a 60 fps e **linear** entre frames. Copiar os 548 keyframes crus produz
movimento chapado, porque o easing estava na densidade dos frames, não na curva.

Reautorar bem é: achar as **poses-chave** (carga, impacto, recuperação), escrever poucos
beats e pôr o easing certo em cada um — `Back/In` na carga, `Quint/Out` no golpe.

O **pico de velocidade** de uma sequência é o frame de impacto. É ali que o dano entra,
não no fim da animação. Aplicar dano no fim faz o golpe parecer atrasado mesmo quando o
número está certo.

Referência com 2417 keyframes já convertidos:
`ACERVO_RETROVERSE/Saitama_Animacoes_Referencia/`. Está **CRU** — consulta livre, uso em
Tool só depois de fechar autor e licença.

---

## Ciclo de vida

```lua
local rig = nil

tool.Equipped:Connect(function()
    rig = Animator.new(personagem, CFG.NOME, Poses.POSES, Poses.SEQUENCIAS)
end)

local function desmontar()
    if rig then
        rig:Destroy()
        rig = nil
    end
end

tool.Unequipped:Connect(desmontar)
tool.Destroying:Connect(desmontar)
humanoid.Died:Connect(desmontar)
```

`Destroy()` cancela sequência, para o tremor, destrava o personagem e solta os `Weld` por
reparent. **Os três gatilhos são obrigatórios** — faltar o `Died` deixa `Weld` órfão no
personagem que respawna.

---

## Proibições

| Proibido | Usar |
|---|---|
| `Instance.new("Animation")` · `LoadAnimation` | tabela de poses CFrame |
| **Escrita em `Motor6D.C0`** | `Weld.C0` pelo animator canônico |
| Animator próprio dentro de uma Tool | o canônico, copiado para dentro |
| `task.wait(duração)` para encadear beat | `Tween.Completed` ou acumulador `dt` |
| `tick()` alimentando CFrame | acumulador `dt` a partir de zero |
| `math.random` em pose ou tremor | senoide multi-frequência determinística |
| `:Destroy()` nos `Weld` | `Parent = nil` (o animator já faz) |

---

## Verificação

```bash
bash TESTES/verificar_autocontencao.sh
```

Checa `sem escrita em Motor6D.C0`, `sem Animation/LoadAnimation` e
`animator canônico presente e íntegro`.

Manual, no Studio:

- [ ] Equipar, andar, correr, pular — a caminhada é normal
- [ ] Tocar a sequência com perna, esperar acabar, **andar de novo** — voltou ao normal
- [ ] Desequipar no meio da sequência — nada fica preso
- [ ] Morrer no meio da sequência — respawn limpo, sem `Weld` órfão
- [ ] Duas Tools diferentes equipadas em sequência — nomes de `Weld` não colidem

---

## Ragdoll e o animator disputam as mesmas juntas

Ragdoll passou a ser permitido (§10.12 da base). Ele desliga `Motor6D`; o
`R6CFrameAnimator` V2 solda `Weld`s próprios. **São dois donos das mesmas juntas**, e o
sintoma de dois donos já apareceu neste repositório: a pose treme e volta sozinha.

Ordem obrigatória, sem exceção:

```lua
-- ANTES de ligar o ragdoll
rig:CancelSequence()
rig:ReleaseLegs()
rig:LockCharacter(false)

-- ... ragdoll ...

-- DEPOIS de desligar, o rig volta a ser o dono
```

`ReleaseLegs()` não é opcional aqui. Perna soldada trava o corpo mole exatamente como
trava a caminhada — é o mesmo `Weld`, e o mesmo defeito.
