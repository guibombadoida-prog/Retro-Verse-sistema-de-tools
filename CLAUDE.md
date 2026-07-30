# CLAUDE.md — Retro-Verse / Sistema de Tools

## Escopo desta sessão e deste repositório

**Somente ferramentas (`Tool`) do Roblox Studio.** O trabalho é converter modelos em Tools conformes.

Fora de escopo — recusar e redirecionar: NPCs, sistemas de mapa, economia, DataStore, UI de jogo,
matchmaking, e qualquer sistema que não seja uma `Tool` ou o Núcleo de Combate que as serve.

## Ordem de precedência das regras

1. `DIRETRIZES/REGRA_AUTOCONTENCAO_ABSOLUTA.md` — **regra nº 1, vence tudo**
2. `DIRETRIZES/REGRA_12_NUCLEO_DE_COMBATE_V3.md` — vence a base em qualquer conflito
3. `DIRETRIZES/REGRA_DISTRIBUICAO_DE_TOOLS.md` — quantas Tools saem de um modelo
4. `DIRETRIZES/REGRA_ENTREGA_RBXMX.md` — todo modelo convertido sai como `.rbxmx`
5. `DIRETRIZES/DIRETRIZES_SISTEMA_DE_TOOL.md` — base (Handle, debounce, proibições)
6. `DIRETRIZES/PIPELINE_MODELO_PARA_TOOL.md` — como converter
7. `DIRETRIZES/CHECKLIST_ENTREGA.md` — o que verificar antes de fechar

## Entrega é `.rbxmx`, não `.lua` solto

Todo modelo convertido sai como **arquivo `.rbxmx` da Tool montada**, um por Tool, pronto para
arrastar para o Studio. Instrução de montagem não é entrega.

O `.rbxmx` é **derivado** dos `.lua` — nunca escrito à mão:

```bash
python3 FERRAMENTAS/montar_rbxmx.py     # editou o .lua? monta de novo
python3 TESTES/verificar_rbxmx.py       # confere fonte byte a byte
```

## Quantas Tools saem de um modelo

**Piso 3, teto 7.** De 3 a 7 habilidades, uma Tool por habilidade. Com 8 ou mais, são 7 Tools
e o excedente vira habilidade **Extra** na Tool de tema mais próximo. Cada Tool comporta duas:
primária em `Tool.Activated`, Extra por tecla via `AcaoRemote`.

## Regra nº 1 — autocontenção absoluta

> **Nada de referência de script FORA da Tool.** Todo script, animação, VFX, SFX, mesh,
> MeshPart, textura, som, pose e módulo é **obrigatoriamente** filho da Tool.

**Teste que decide:** arraste a Tool sozinha para um place vazio — sem Acervo, sem Núcleo,
sem `ReplicatedStorage`, sem `ServerStorage`. **Ela funciona por inteiro.**

Não são violação: `_G.Combate` com guarda (global opcional, não caminho de instância),
`parte.Parent = workspace` (escrever no mundo é saída; **ler** dele é dependência), e
`rbxassetid://` dentro de instância que já é filha da Tool.

Verificar sempre antes de fechar: `bash TESTES/verificar_autocontencao.sh`

Ler as diretrizes **antes** de escrever qualquer Lua. Elas não são sugestão de estilo: várias
proibições existem porque o oposto já causou bug em produção (ordem de `Name`/`Parent` na tag
`creator`, `:Emit` no servidor, `tick()` alimentando `CFrame`).

## Invariantes que nunca podem ser quebrados

| Invariante | Verificação prática |
|---|---|
| **Tudo dentro da Tool** | `bash TESTES/verificar_autocontencao.sh` passa |
| **Entrega é `.rbxmx`** | `python3 TESTES/verificar_rbxmx.py` passa |
| Tool não conhece o Núcleo | Zero `require` de `NucleoCombate` em qualquer arquivo de `Tools/` |
| Tool é autocontida | Tool sozinha em place vazio funciona por inteiro |
| Asset vem de dentro | `Sound` clonado de `Tool/SFX/`; molde de VFX de `Tool/Efeitos/` |
| Núcleo é a única porta de regra de combate | Zero `canDamage` / `IsTeamMate` / `TagHumanoid` fora de `NucleoCombate.lua` |
| Servidor nunca emite VFX | Zero `:Emit(` em Server Script; `_G.Combate.transmitirVFX` + `VFXRemote` |
| Toda chamada ao Núcleo é opcional | Sempre `_G.Combate and _G.Combate.x(...) or <fallback>` |

## Proibições de sintaxe (valem em todo `.lua` do repositório)

| Proibido | Usar |
|---|---|
| `wait()` · `spawn()` · `delay()` | `task.wait` · `task.spawn` · `task.delay` |
| `tick()` | `os.clock()` para recarga; acumulador `dt` a partir de zero para animação |
| `part:Destroy()` · `:Remove()` | `Parent = nil` ou `Debris:AddItem` |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `math.random` em gameplay | Ângulo áureo / Vogel, jitter senoidal por contador, índice sequencial |
| `+=` · `-=` · `continue` | Sintaxe expandida: `x = x + 1`, `if/else` aninhado |
| `Instance.new("Explosion")` | `_G.Combate.detectarHumanoides` |
| `Health = Health - dano` | `TakeDamage` (respeita `ForceField`) |
| `ScreenGui` · `ColorCorrection` · `Sky` dentro da Tool | Efeito só no mundo 3D |
| `require(<id numérico>)` | Módulo copiado para dentro da Tool |
| `Animation` / `LoadAnimation` | Tabela de poses CFrame sob `R6CFrameAnimator` |

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
NucleoCombate.lua                  Script central — nome SEM versão
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
Commits em português, descritivos, no escopo de uma Tool ou do Núcleo por vez.
