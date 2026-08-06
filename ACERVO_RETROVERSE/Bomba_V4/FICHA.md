# Modelo: bomba_v4

- Autor original:            **ICAN_REA0 (Absolument)** — declarado no cabeçalho
- Origem:                    `bomba_v4.rbxmx` — Tool "Múltiplas Bombas V1.1"
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-06
- Status:                    **LIMPO** — passe §12.12.2 executado
- Onde vive:                 `MODELOS_ENTRADA/Bomba_V4/` · clonado em `Tools/`

## O que saiu daqui

As **6 Tools** do conjunto BOMBAS. Todas com habilidade **única**, em
`Tool.Activated` — nenhuma tem Extra, então nenhuma tem `AcaoRemote`.

| Tool | Habilidade |
|---|---|
| `Multiplas Bombas` | 1 bomba → 3 mini bombas *(a do original)* |
| `Bomba Nuclear` | nuke: cogumelo, clarão, 3 anéis de dano expandindo |
| `Bomba Meteorica` | meteoro na diagonal, 1 s de queda com áudio, 10 mini para cima |
| `Bomba Basquete` | quica 3 vezes e estoura |
| `Bomba Doida` | 2 bombas-NPC R6 kamikaze, mais rápidas quanto mais tempo sem alvo |
| `Bomba Gelada` | congela e deixa chão de gelo escorregadio |

## Números do original, preservados

dano **20** · raio **20** · escala **2** · **3** mini a **20%** em raio **15** ·
delay **1 s** · recarga **1 s** · dispersão **30** · alcance máx **150** ·
explode ao **tocar Humanoid** OU por prazo.

## Passe de conformidade §12.12.2 — EXECUTADO

**Nenhuma linha do modelo entrou.** O código é autoral.

| Violação no original | O que foi feito |
|---|---|
| `require(8199013483)` | **id numérico = execução de código remoto.** Não entra. O VFX agora é próprio + o pack Stella conformado, dentro da Tool |
| `IsAlly` próprio, com `PossessFollow`/`SuitFollow`/`ControlFollow` | regra de combate tem **uma** porta: `_G.Combate` |
| `workspace:GetDescendants()` a cada explosão | consulta espacial (`GetPartBoundsInRadius`) |
| `tick()` alimentando geometria | `os.clock()`; e a expansão saiu do servidor |
| expansão da explosão animada **no servidor** por `Heartbeat` | replica a ~20 Hz sem interpolação. Virou Tween **no cliente** |
| `math.random` na dispersão das mini | ângulo áureo — os dois clientes veem a mesma leva |
| `:Destroy()` × vários | `Parent = nil` + `Debris` |
| `AncestryChanged` para limpeza | `Tool.Destroying` |
| `SetPartCollisionGroup` (API antiga, dentro de `pcall`) | removido |

## Decisões que valem registro

- **A bomba voa por FÍSICA** (`BodyVelocity`), não por `CFrame` no `Heartbeat`.
  Parte não-ancorada replica com interpolação; ancorada movida pelo servidor
  não. É a diferença entre voo liso e voo picotado.
- **O quique do basquete é propriedade física** (`CustomPhysicalProperties`),
  e o script só **conta** os pousos.
- **A bomba-NPC é montada em código**, com primitivas, dentro do Server —
  nada de modelo guardado fora da Tool (Regra nº 1). R6 mínimo:
  `HumanoidRootPart`, `Torso`, `Head`, `RootJoint`, `Neck`, `Humanoid`.
- **O áudio de queda do meteoro** é o `Throw` do próprio modelo, desacelerado
  para 0.45 e cortado em 1 s. O modelo só traz `Explode` e `Throw`; inventar
  um `rbxassetid` não conferido daria silêncio sem aviso.
- **A nuke fere o portador** se ele estiver no raio — 40, pelo Núcleo.

## Escopo

A `Bomba Doida` cria NPCs. Isso é **habilidade de Tool**, não sistema de NPC:
a bomba nasce no uso, persegue, estoura e some. Não há spawner, não há
respawn, e não existe nada dela fora da Tool.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste em jogo. O autor está declarado.
