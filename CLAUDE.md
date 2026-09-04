# CLAUDE.md — Retro-Verse / Sistema de Tools

## Escopo desta sessão e deste repositório

**Somente ferramentas (`Tool`) do Roblox Studio.** O trabalho é converter modelos em Tools conformes.

Fora de escopo — recusar e redirecionar: NPCs, sistemas de mapa, economia, DataStore, UI de jogo,
matchmaking, e qualquer sistema que não seja uma `Tool`. **Não há mais sistema central algum.**

## Ordem de precedência das regras

1. `DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md` — **regra nº 1, vence tudo**
2. `DIRETRIZES/REGRA_CICLO_DE_VIDA_DO_VFX.md` — **regra nº 2**, o depósito em `ReplicatedStorage`
3. `DIRETRIZES/REGRA_DISTRIBUICAO_DE_TOOLS.md` — quantas Tools saem de um modelo
4. `DIRETRIZES/REGRA_ENTREGA_RBXM.md` — todo modelo convertido sai como `.rbxm` binário
5. `DIRETRIZES/REGRA_ANIMACAO_R6.md` — Weld C0, animator canônico, perna sob demanda
6. `DIRETRIZES/REGRA_CAMERA_DE_CUTSCENE.md` — câmera é 100% cliente, e sempre devolvida
7. `DIRETRIZES/DIRETRIZES_SISTEMA_DE_TOOL.md` — base (Handle, debounce, proibições)
8. `DIRETRIZES/PIPELINE_MODELO_PARA_TOOL.md` — como converter
9. `DIRETRIZES/CHECKLIST_ENTREGA.md` — o que verificar antes de fechar

## Entrega é `.rbxm` binário, não `.lua` solto

Todo modelo convertido sai como **arquivo `.rbxm` do conjunto montado**, pronto para arrastar
para o Studio. Instrução de montagem não é entrega.

**`.rbxm` é a entrega; `.rbxmx` é a etapa do meio.** O XML fica versionado porque é o único
dos dois em que o `git diff` mostra o que mudou; o binário é o que se manda para quem vai
usar. Os dois são gerados sempre, e os dois abrem no Studio.

Os dois são **derivados** dos `.lua` — nunca escritos à mão:

```bash
python3 FERRAMENTAS/montar_rbxmx.py                        # Tool autoral
python3 FERRAMENTAS/clonar_tool.py montar <origem> <saída>  # Tool que chegou pronta
python3 FERRAMENTAS/converter_para_rbxm.py <x.rbxmx> <x.rbxm>   # o binário da entrega
python3 TESTES/verificar_rbxmx.py       # confere fonte byte a byte
python3 TESTES/verificar_poses.py       # poses × animator V2
python3 TESTES/verificar_vfx_chamadas.py # chamada de VFX sem definição
python3 TESTES/verificar_beats.py        # beat despachado que a sequência não tem
python3 TESTES/verificar_deposito_vfx.py  # o depósito instala, conta e apaga
```

## Quantas Tools saem de um modelo

**Piso 3, teto 7.** De 3 a 7 habilidades, uma Tool por habilidade. Com 8 ou mais, são 7 Tools
e o excedente vira habilidade **Extra** na Tool de tema mais próximo. Cada Tool comporta duas:
primária em `Tool.Activated`, Extra por tecla via `AcaoRemote`.

## Regra nº 1 — autocontenção absoluta

> **A Tool é a fronteira.** Todo script, animação, VFX, SFX, mesh, MeshPart, textura, som,
> pose e módulo **nasce dentro dela**, e nada do que ela precisa vem de fora.

**Teste que decide:** arraste a Tool sozinha para um place vazio — sem Acervo, sem
`ReplicatedStorage` povoado, sem `ServerStorage`. **Ela funciona por inteiro.**

Não são violação: `parte.Parent = workspace` (escrever no mundo é saída; **ler** dele é
dependência), **o depósito que a própria Tool montou** em `ReplicatedStorage` (regra nº 2),
`rbxassetid://` dentro de instância que já é filha da Tool, e `workspace.CurrentCamera`
**em `LocalScript`** (singleton por cliente, como `Players.LocalPlayer` — não é depósito de asset).

## Regra nº 2 — o VFX sai da Tool em runtime, e volta com ela

> Na **entrega**, todo molde de `Part`/`MeshPart`/mesh é filho da Tool. Ao chegar ao jogador
> — mochila **ou** mão —, o **Server** move os moldes para
> `ReplicatedStorage/RetroVerse_VFX/<ChaveVFX>/`. A pasta **cria ou reutiliza**, e fica lá
> até o servidor ser desligado.

Quem lê tem **duas portas**, nesta ordem: o depósito, e o interior da Tool. A segunda é o
que mantém o teste do place vazio verdadeiro.

Verificar: `python3 TESTES/verificar_deposito_vfx.py`

Verificar sempre antes de fechar: `bash TESTES/verificar_autocontencao.sh`

Ler as diretrizes **antes** de escrever qualquer Lua. Elas não são sugestão de estilo: várias
proibições existem porque o oposto já causou bug em produção (ordem de `Name`/`Parent` na tag
`creator`, `:Emit` no servidor, `tick()` alimentando `CFrame`).

## Invariantes que nunca podem ser quebrados

| Invariante | Verificação prática |
|---|---|
| **Tudo dentro da Tool** | `bash TESTES/verificar_autocontencao.sh` passa |
| **Entrega é `.rbxmx`** | `python3 TESTES/verificar_rbxmx.py` passa |
| Tool não conhece sistema nenhum | Zero `require` fora da Tool; **zero `_G.Combate`** em qualquer arquivo |
| Tool é autocontida | Tool sozinha em place vazio funciona por inteiro |
| Asset vem de dentro | `Sound` clonado de `Tool/SFX/`; molde de VFX de `Tool/Efeitos/` |
| Animação R6 usa o animator canônico | Zero escrita em `Motor6D.C0`; poses no formato `Weld` (RightArm/LeftArm/Head/HRP/RightLeg/LeftLeg) |
| Quem encadeia beat é o animator | Zero `task.wait(passo.…)`; `PlaySequence` / `PlayTrack` |
| Perna volta ao `Humanoid` | `ReleaseLegs` no fim; perna soldada permanentemente trava a caminhada |
| Câmera é 100% cliente | Zero `Camera` em Server Script; servidor manda beat por `RemoteEvent` |
| Câmera presa é devolvida | Quem escreve `CameraType` liga `Tool.Unequipped` **e** `Tool.Destroying` |
| O depósito é do MODELO | `ChaveVFX` presente e única; cria ou reutiliza; **ninguém apaga a pasta** |
| Servidor nunca emite VFX | Zero `:Emit(` em Server Script; `VFXRemote:FireAllClients` |
| Ragdoll e efeito de status voltam | O valor de ANTES é guardado e devolvido; guarda contra empilhar |

## Proibições de sintaxe (valem em todo `.lua` do repositório)

| Proibido | Usar |
|---|---|
| `wait()` · `spawn()` · `delay()` | `task.wait` · `task.spawn` · `task.delay` |
| `tick()` | `os.clock()` para recarga; acumulador `dt` a partir de zero para animação |
| `part:Destroy()` · `:Remove()` | `Parent = nil` ou `Debris:AddItem` |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `+=` · `-=` · `continue` | Sintaxe expandida: `x = x + 1`, `if/else` aninhado |
| `Instance.new("Explosion")` | `workspace:GetPartBoundsInRadius` com `OverlapParams` |
| `Health = Health - dano` | `TakeDamage` (respeita `ForceField`) |
| `ScreenGui` · `ColorCorrection` · `Sky` dentro da Tool | Efeito só no mundo 3D |
| `require(<id numérico>)` | Módulo copiado para dentro da Tool |
| `Animation` / `LoadAnimation` | Tabela de poses CFrame sob `R6CFrameAnimator` |
| **Escrever em `Motor6D.C0`** | **`R6CFrameAnimator` V2 canônico — ele solda `Weld`s próprios** |
| `task.wait(passo.duracao)` para encadear beat | `rig:PlaySequence` (Tween.Completed) ou `rig:PlayTrack` (acumulador `dt`) |
| `Camera` em Server Script | `RemoteEvent` com beat nomeado; quem enquadra é o `LocalScript` |
| Animator escrito na hora, dentro de uma Tool | O canônico do Acervo, copiado para dentro |

### O que passou a ser PERMITIDO

| Antes proibido | Agora | Ressalva |
|---|---|---|
| `math.random` | **liberado** | no cliente, cada um sorteia diferente e vê cena diferente — onde a cena precisa combinar, use o ângulo áureo |
| Ragdoll | **liberado** | `BallSocketConstraint`, sempre reversível; `rig:CancelSequence()` + `ReleaseLegs()` antes |

`BreakJoints` continua proibido: ragdoll sem volta é `BreakJoints` com outro nome.

Números mágicos espalhados pelo corpo do script são violação: bloco `CFG` único no topo,
junto do `ARQUETIPO`.

## Fluxo obrigatório de toda entrega

1. **Antes de criar efeito:** ler `ACERVO_RETROVERSE/_INDICE.md`. Se existe equivalente, reusar.
2. **Material de terceiro:** pasta do modelo → depositar **CRU** → passe §12.12.2 → **APROVADO**.
   Sem os quatro campos da ficha (autor, origem, licença, data) o material fica CRU e não entra em Tool.
3. **Ao finalizar:** montar o `.rbxmx` de cada Tool, verificar, e depositar todo VFX/SFX/pose
   novo ou modificado, atualizando `_INDICE.md`.
4. **No relatório:** seção **"Delta do Acervo"** — o que entrou, o que foi reusado, o que mudou de status.

Entrega sem Delta do Acervo é entrega incompleta.

## Nomenclatura

```
[NomeDaTool]_Server_V[X].lua       script de servidor da Tool
Poses_[Modelo]_V[X].lua            tabela de poses R6 CFrame
"[NomeDaTool]_[Habilidade]"        chave de recarga global — ex.: "AstralPulsar_X"
"[Sistema]_[Efeito]"               modificador — ex.: "Passiva_Frenesi"
"IMPACTO_NOVA"                     tipo de VFX — MAIUSCULA_COM_UNDERSCORE
Nome_Do_Modelo_De_Origem/          pasta de modelo no Acervo
```

Versionamento sequencial V1 → V2 → V3, incrementado a cada modificação. O arquivo antigo é
**substituído**, e a substituição é declarada no relatório de entrega.

## Git

Branch de desenvolvimento: `claude/roblox-tools-repository-zn3r68`.
Commits em português, descritivos, no escopo de um conjunto de Tools por vez.
