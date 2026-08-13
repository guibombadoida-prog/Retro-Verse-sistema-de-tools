# Modelo: Maria Tools — 8 cajados

- Autor original:            **a confirmar** ⚠️
- Origem:                    `mariatools.rbxmx`
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Maria_Tools/`

---

## O que é

**Oito `Tool` prontas**, na raiz do arquivo. É o único modelo que já entrou aqui como
conjunto de Tools em vez de um modelo para fatiar.

| Tool | Instâncias | VFX próprio |
|---|---|---|
| `Cajado Curador` | 32 | — |
| `Cajado Da Escuridão` | 41 | `ParticleEmitter` *Shadows* · `Trail` · `SpecialMesh` *Orb* |
| `Cajado Da Ilusão` | 83 | — (mas leva um `Animate` completo, 505 linhas) |
| `Cajado Das Estrelas` | 34 | `ParticleEmitter` *Particle* · `SpecialMesh` |
| `Cajado De Gelo` | 41 | — |
| `Cajado Do Meteoro` | 31 | `ParticleEmitter` *Particle* |
| `Cajado Relâmpago` | 33 | `SpecialMesh` |
| `Cajado Roubador de Hp` | 32 | — |

Estrutura repetida em todas: `Handle`, `LocalScript`, `Script`, `Sound` `Atk`,
`Folder` `ExtraTHICK`, `RemoteEvent` `GetMouse`, `Folder` `Animation`, `Folder` `Scripts`.

**Uma habilidade cada, no clique.** O scan não achou um único `KeyCode` nas oito.

## Isto é remaster, não Tool nova

Pela `DIRETRIZES/REGRA_REMASTER_VS_NOVA.md`, o teste é: *"existe um `.rbxmx` de origem que
alguém mandou converter?"* Existe, e ele já vem em formato `Tool`. Então **a estrutura é
lei**: cajado é cajado, o tema de cada um se mantém, e o que muda é a habilidade — melhorada.

## O choque com a regra de distribuição

São **oito temas** e o teto é **sete Tools**. Pela regra, saem 7 Tools e o oitavo tema vira
habilidade **Extra** na Tool de tema mais próximo. Os dois pares que mais se aproximam:

- `Cajado Curador` + `Cajado Roubador de Hp` — os dois mexem em vida, um dando e outro tirando
- `Cajado Das Estrelas` + `Cajado Do Meteoro` — os dois chamam coisa do céu

Qual dos dois pares se funde é escolha de quem manda converter.

## O que precisa ser jogado fora

| Achado | Quantos | Por quê |
|---|---|---|
| `LoadAnimation` | 18 | proibido — tabela de poses CFrame sob `R6CFrameAnimator` |
| `Animation` (instância) | 40 | idem |
| `wait()` | 71 | proibido — `task.wait` |
| `:Destroy()` | 33 | proibido — `Parent = nil` / `Debris` |
| `math.random` | 21 | proibido em gameplay |
| `Instance.new("Explosion")` | 1 | proibido — `_G.Combate.detectarHumanoides` |
| `tick()` | 1 | proibido |

### As 40 `Animation` não valem nada

É o achado que decide o trabalho. Os oito cajados compartilham **os mesmos três ids**:

| Papel | id |
|---|---|
| `Main` | `846744780` |
| `Main` (segunda) | `218504594` |
| `Idle` | `5333675877` |

Ou seja: **a animação não é do cajado, é genérica.** O `Cajado De Gelo` e o
`Cajado Relâmpago` fazem o mesmo gesto. Não há silhueta própria para preservar — e como
`Animation` é proibida de qualquer jeito, as oito precisam de **pose R6 autoral escrita do
zero**, pela gramática de `_AUTORAL_RetroVerse/R6_CFRAME/GRAMATICA_R6.md`.

Pela regra 6 da gramática, conjuração sai do **braço** (`RightArm`), não do tronco — os oito
são conjuração.

O `Cajado Da Ilusão` carrega ainda um `Animate` de 505 linhas com as 8 animações padrão de
locomoção do Roblox (`WalkAnim`, `RunAnim`, `JumpAnim`, `FallAnim`, `ClimbAnim`…). Isso é
sistema de personagem, **não entra em Tool**.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO
