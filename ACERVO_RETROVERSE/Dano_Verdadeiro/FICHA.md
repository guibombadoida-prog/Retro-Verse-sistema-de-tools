# Modelo: Damage First True ("dano verdadeiro")

- Autor original:            **a confirmar** ⚠️
- Origem:                    `dano_verdaderio.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU** — e com uma ressalva que não é burocrática
- Onde vive:                 `MODELOS_ENTRADA/Dano_Verdadeiro/`

---

## O que ele é de fato

Uma `Tool` chamada `Damage First True`: 28 instâncias, **um** `Script` de 90 linhas,
8 `MeshPart` soldados por `Motor6D`, 5 `Sound`.

O corpo é curto e faz duas coisas bem diferentes.

### A primeira metade é excelente

```
Activated        → toca "activate"
Activated:Once   → 15 s de carga com TweenService (Quint/In) num NumberValue 0 → 100
                   o valor alimenta jitter crescente em 6 Motor6D + 1 spinweld
                   "charge" toca no início; "alarm" toca 3 vezes, de 2 em 2 s
    t = 12.5 s   → estouro
```

Isso é **exatamente** um ultimate pela gramática medida: `GRAMATICA_R6.md` regra 5 diz
*"ultimate é 7–9 s com 64–86% de preparação"*. Este é 12.5 s de 13, ou **96%** — acima da
faixa medida, mas a intenção é a mesma e o alarme de 3 batidas resolve o problema que a
regra 5 aponta (*"7 segundos de preparação sem enquadramento é tempo morto"*): aqui o tempo
morto é preenchido por som, não por câmera.

### A segunda metade não é uma habilidade

O que roda em `t = 12.5 s` varre `workspace:GetDescendants()` e, **para cada descendente do
mundo inteiro**:

| Linha | Efeito real |
|---|---|
| `if v1:IsA("Humanoid") then Debris:AddItem(v1, 0)` | **apaga todo `Humanoid` do servidor** — todo jogador e todo NPC, sem checar time, distância ou dono |
| `BallSocketConstraint` / `HingeConstraint` → `AddItem(v1,0)` | desmonta toda articulação do mapa |
| `v1.Anchored = false` + `v1:BreakJoints()` | **solta o mapa inteiro** abaixo de 300 de massa, sem volta |
| `v1.CFrame *= CFrame.new(rng…)` | embaralha a posição de cada peça |
| `Instance.new("Explosion")` com `BlastRadius = math.huge` | **uma explosão POR PEÇA**, raio infinito |
| `Instance.new("Fire")` em cada peça | fogo em tudo |
| `ColorCorrectionEffect` em `Lighting`, `Brightness = 100` | branco total por 30 s |
| `sfx.Parent = SoundService` | som depositado fora da Tool |

Não há raio, não há alvo, não há dono, não há recarga, e o `:Once` faz disso um gatilho de
uso único e irreversível. **Isto não é uma habilidade de Tool — é um apagador de servidor.**
Uma `Explosion` por `BasePart` do `workspace` também trava o servidor por si só.

Digo isso como leitura do código, não como julgamento de quem mandou o modelo: é
provavelmente um "botão de nuke" de sandbox, e sandbox é onde ele faz sentido.

### Contra as regras deste repositório

São **oito** proibições diretas num script de 90 linhas — recorde do Acervo:

| Proibido | Onde | O que a regra manda |
|---|---|---|
| `Instance.new("Explosion")` | payload | `_G.Combate.detectarHumanoides` |
| apagar `Humanoid` | payload | `TakeDamage` (respeita `ForceField`) |
| `ColorCorrection` | `Lighting` | efeito só no mundo 3D |
| som em `SoundService` | 2× | `Sound` clonado de `Tool/SFX/`; o verificador cobra isso por nome |
| ler `workspace:GetDescendants()` | payload | ler o mundo é dependência (Regra nº 1) |
| `spawn()` | 3× | `task.spawn` |
| `Random.new` em gameplay | 1× | ângulo áureo / jitter senoidal por contador |
| escrever `Motor6D.C1` | carga | `R6CFrameAnimator` V2 solda `Weld`s próprios |

## Como isto vira Tool

**A carga fica inteira. O payload é substituído.** Não é censura — é o que a regra de
distribuição e o Núcleo já mandam para qualquer Tool:

1. `detectarHumanoides` num raio declarado no `CFG`, com o Núcleo decidindo quem pode levar.
2. `TakeDamage` em vez de apagar `Humanoid`.
3. O clarão vira VFX no mundo 3D — o `Vfx pack` do His Cube tem
   `Realistic-Explosion-01` e `Big/Explosion-01` prontos para isso.
4. `BreakJoints` e `Anchored = false` **saem**: destruição permanente de mapa não é dano.
5. Os sons ficam dentro da Tool e tocam numa âncora, como nas Tools de bomba.
6. Recarga global e `EnergyCost` declarados; nada de `:Once`.

## O que vale guardar

| | |
|---|---|
| 8 `MeshPart` | `tank`, `rocket`, `holder`, `ring`, `piece remake`, `v2`, `sender` e o `Handle` — ogiva montada, com `Motor6D` já soldados |
| 5 `Sound` | `activate`, `alarm`, `charge`, `boom`, `hum` |
| 3 `DistortionSoundEffect` + 2 `PitchShiftSoundEffect` | **os primeiros `SoundEffect` a entrar no Acervo** — nenhuma Tool do repositório usa efeito de áudio ainda |
| a curva de carga | `TweenInfo.new(15, Quint, In)` num `NumberValue` que alimenta jitter crescente — é um molde reaproveitável de "carregando" |

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`. **Não é backdoor.** O estrago que ele faz é o estrago que ele declara.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO
