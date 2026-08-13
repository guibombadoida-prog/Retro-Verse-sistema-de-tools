# Modelo: NPC For Tools

- Autor original:            **ArceusInator** — declarado no cabeçalho do `ZombieScript`
                             (*"Basic Monster by ArceusInator"*)
- Origem:                    `npc_for_tools.rbxmx`
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/NPC_For_Tools/`

---

## Isto não vira Tool, e não é engano meu

O `CLAUDE.md` deste repositório é explícito:

> Fora de escopo — recusar e redirecionar: **NPCs**, sistemas de mapa, economia, DataStore,
> UI de jogo, matchmaking, e qualquer sistema que não seja uma `Tool` ou o Núcleo de Combate
> que as serve.

É um `Model` chamado `NPC`: rig R6 completo (`Humanoid`, 6 `Motor6D`, `Head` com
`BillboardGui` de vida), `ZombieScript` de 460 linhas, dois `Animate` (515 e 505 linhas),
`Respawn`, `Wander`, `ControlFollow`, e um `Configuration` com
`MaximumDetectionDistance` / `AttackDamage` / `AttackFrequency` / `AttackRange`.

Nenhuma Tool sai daqui. **Nenhuma linha deste modelo entra em Tool nenhuma.**

## Para o que ele serve — e é útil

Bancada de teste. É o que o nome do arquivo diz: *NPC **for tools***.

Todo o trabalho deste repositório foi verificado **estaticamente** — cinco verificadores
Python, zero execução em Studio. Uma parte grande do que não dá para verificar assim é
justamente o que este modelo exercita:

| O que só um alvo vivo mostra | Onde está prometido |
|---|---|
| `TakeDamage` respeitando `ForceField` | invariante do `CLAUDE.md` |
| `_G.Combate.detectarHumanoides` achando alvo de verdade | Núcleo de Combate |
| a cutscene enquadrando **quem é alvo** | `GRAMATICA_CUTSCENE.md`, regra 2 |
| `canDamage` / `IsTeamMate` — o `FriendlyTeam` do `Configuration` testa direto | Núcleo |
| se a pose R6 lê como força ou como flutuação | `GRAMATICA_R6.md`, regra 7 |

A regra 2 da gramática de cutscene é a que mais precisa dele: o enquadramento por
espectador foi escrito, verificado por leitura, e **nunca visto**. Sem um segundo
`Humanoid` no lugar, ele não tem como ser visto.

## Como usar sem quebrar a Regra nº 1

Ele vive **no place de teste**, largado no `Workspace`. Nunca dentro de uma Tool, nunca
referenciado por script de Tool. A Tool continua achando alvo por
`_G.Combate.detectarHumanoides` — que varre o mundo — e não por caminho de instância.

O teste de autocontenção não muda: arrastar a Tool sozinha para um place vazio, ela funciona
por inteiro. O NPC é o que se põe **na frente** dela depois.

## O que ele carrega que é proibido em Tool

`LoadAnimation` ×7, 18 `Animation`, `wait()` ×17, `tick()` ×11, `:Destroy()` ×14,
`math.random` ×10. Nada disso importa: **ele não vai entrar em Tool.** Fica registrado só
para o caso de alguém se tentar a reaproveitar um pedaço.
