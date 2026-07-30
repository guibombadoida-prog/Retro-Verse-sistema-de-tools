# _TEMPLATE_Tool — molde de Tool conforme

Copiar esta pasta, renomear para o nome real da Tool e trocar `Template` em **todos** os arquivos.

## Hierarquia no Studio (§12.10)

```
Tool                              CanBeDropped = false · RequiresHandle = true · ToolTip preenchido
├── Handle                        Part ou MeshPart, nome exato "Handle" (case-sensitive)
├── DamageClass                   StringValue  "Melee" | "Ranged" | "Magic" | "Summon" | "Debuff"
├── EnergyCost                    NumberValue  custo por ativação
├── RecargaGlobal                 NumberValue  segundos; 0 ou ausente = sem recarga
├── ChaveRecarga                  StringValue  opcional — Tools irmãs que dividem recarga
├── [NomeDaTool]_Server_V1        Script       ← Template_Server_V1.lua
├── Client                        LocalScript  ← Client.lua
├── VFXRemote                     RemoteEvent  unidirecional: servidor → cliente
├── AcaoRemote                    RemoteEvent  input da habilidade Extra: cliente → servidor
├── R6CFrameAnimator              ModuleScript ← R6CFrameAnimator.lua
├── Poses                         ModuleScript ← Poses_Template_V1.lua
└── VFXModule                     ModuleScript ← VFXModule.lua
```

> ⚠️ Os ModuleScripts mantêm os nomes `R6CFrameAnimator`, `Poses` e `VFXModule` **no Studio** —
> é assim que os scripts os encontram. O nome versionado (`Poses_Template_V1.lua`) é do arquivo
> no repositório e do depósito no Acervo.

## Arquivo por arquivo

| Arquivo | Vira, no Studio | Papel |
|---|---|---|
| `Template_Server_V1.lua` | `Script` | Dano, recarga, ordem de impacto, ciclo de vida. **Sem `require` do Núcleo.** |
| `Client.lua` | `LocalScript` | Só input da Extra + recepção de VFX |
| `R6CFrameAnimator.lua` | `ModuleScript` | Poses CFrame com acumulador `dt` |
| `Poses_Template_V1.lua` | `ModuleScript` `Poses` | Pose, ritmo, dramaturgia — **autoral** |
| `VFXModule.lua` | `ModuleScript` | Efeitos, executados **no cliente** |

## Os dois Remotes, e por que são dois

| Remote | Direção | Regra |
|---|---|---|
| `VFXRemote` | servidor → cliente | **Unidirecional. Zero `OnServerEvent`.** Payload de dados puros, zero `Instance` |
| `AcaoRemote` | cliente → servidor | Só o pedido de input da Extra. O servidor confere que quem pediu é o dono da Tool |

Misturar os dois num só é a forma mais rápida de abrir um remote de VFX explorável.

## Ao renomear

1. `CFG.NOME` e `CFG.TOOLTIP` no Server Script.
2. `CFG.ACAO_EXTRA` no Client (`"[NomeDaTool]_Extra"`).
3. Chave de recarga: `CFG.NOME .. "_X"` já resolve, desde que `CFG.NOME` esteja certo.
4. Arquivo de poses: `Poses_[Modelo]_V1.lua`.
5. `ARQUETIPO` — `LUTADOR` | `ATIRADOR` | `MAGO` | `INVOCADOR` | `HIBRIDO`.

## O que este molde já garante

- Zero `require` do Núcleo; toda chamada com guarda `_G.Combate and`
- `Tool.Enabled` **não** resetado em `Unequipped`
- Ordem de impacto §8 V2: SFX → física → VFX → dano
- Modo preciso (§12.6) no `TakeDamage`
- `detectarHumanoides` no lugar de `Instance.new("Explosion")`
- Recarga global por chave, imune a clone na mochila
- Cancelamentos guardados e liberados em `Died` e `Destroying`
- Zero `math.random`, `tick()`, `wait()`, `:Destroy()` em part, `+=`, `continue`
