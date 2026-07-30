# Cronostase — estrutura no Studio

> Conjunto **Guardião do Tempo** · Marca um ponto no tempo e volta a ele
> Origem no modelo: `Chronostasis (X)`

**Regra nº 1 — tudo é filho da Tool.** Arraste esta Tool sozinha para um place vazio:
ela funciona por inteiro, sem Acervo, sem Núcleo, sem `ReplicatedStorage`.

```
Tool  "Cronostase"        CanBeDropped = false · RequiresHandle = true
├── Handle                          Part/MeshPart do relógio (do modelo)
├── DamageClass    StringValue      "Magic"
├── EnergyCost     NumberValue      0
├── RecargaGlobal  NumberValue      0   (0 = sem recarga global)
├── Cronostase_Server_V1        Script
├── Client                          LocalScript
├── VFXRemote                       RemoteEvent  servidor → cliente
├── R6CFrameAnimator                ModuleScript V2 (modo absoluto)
├── Poses                           ModuleScript ← Poses_GuardiaoDoTempo_Cronostase_V1.lua
├── VFXModule                       ModuleScript
├── SFX                             Folder
│   └── Marca                     Sound  588738949
│   └── Retorno                   Sound  782202168
└── Efeitos                         Folder  (opcional — sem ele o VFX é procedural)
```

## Habilidades

| Posição | Habilidade | Dispara por |
|---|---|---|
| Primária | Marca um ponto no tempo e volta a ele | `Tool.Activated` |
| Extra | — | — |

`ARQUETIPO = "MAGO"`

## VFX transmitidos

- `ESFERA_TEMPORAL`
- `MOSTRADOR_TEMPORAL`
- `TREMOR`

Todos rodam **no cliente**, disparados por `VFXRemote`. Zero `:Emit()` no servidor (§12.11).

## Montagem

1. Criar a `Tool`, nomear `Cronostase`, e pôr o `Handle` (Part/MeshPart do relógio).
2. Colar os cinco scripts com os nomes de objeto da árvore acima.
3. Criar os `Value`s da tabela acima. **`DamageClass` nunca pode faltar** (§12.4).
4. Criar `SFX/` e pôr um `Sound` por linha, com os IDs de
   `ACERVO_RETROVERSE/Guardiao_Do_Tempo/SFX/ids.md` — volume e pitch na instância.
5. `Efeitos/` é opcional: sem molde, o `VFXModule` desenha o efeito proceduralmente.
6. `Grip` configurado **no servidor** — as propriedades `Grip*` não replicam.

