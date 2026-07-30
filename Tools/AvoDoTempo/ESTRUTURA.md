# AvoDoTempo — estrutura no Studio

> Conjunto **Guardião do Tempo** · Ultimate: as doze badaladas
> Origem no modelo: `GrandfatherTime (Q)`

**Regra nº 1 — tudo é filho da Tool.** Arraste esta Tool sozinha para um place vazio:
ela funciona por inteiro, sem Acervo, sem Núcleo, sem `ReplicatedStorage`.

```
Tool  "AvoDoTempo"        CanBeDropped = false · RequiresHandle = true
├── Handle                          Part/MeshPart do relógio (do modelo)
├── DamageClass    StringValue      "Magic"
├── EnergyCost     NumberValue      0
├── RecargaGlobal  NumberValue      45
├── AvoDoTempo_Server_V1        Script
├── Client                          LocalScript
├── VFXRemote                       RemoteEvent  servidor → cliente
├── AcaoRemote                      RemoteEvent  cliente → servidor (Extra)
├── R6CFrameAnimator                ModuleScript V2 (modo absoluto)
├── Poses                           ModuleScript ← Poses_GuardiaoDoTempo_AvoDoTempo_V1.lua
├── VFXModule                       ModuleScript
├── SFX                             Folder
│   └── Badalada                  Sound  850256806
│   └── Voz                       Sound  819312817
│   └── Provocacao                Sound  819373088
└── Efeitos                         Folder  (opcional — sem ele o VFX é procedural)
```

## Habilidades

| Posição | Habilidade | Dispara por |
|---|---|---|
| Primária | Ultimate: as doze badaladas | `Tool.Activated` |
| Extra | Provocação | tecla `T` → `AcaoRemote` |

`ARQUETIPO = "MAGO"`

## VFX transmitidos

- `ONDA_TEMPORAL`
- `ESFERA_TEMPORAL`
- `MOSTRADOR_TEMPORAL`
- `DETRITOS`
- `TREMOR`

Todos rodam **no cliente**, disparados por `VFXRemote`. Zero `:Emit()` no servidor (§12.11).

## ⚠️ As DUAS recargas globais desta Tool — não unifique as chaves

Esta Tool tem recarga global por **dois** caminhos, de propósito:

| Quem | Chave | O que faz |
|---|---|---|
| O Server Script, chamando `_G.Combate.recargaGlobal` | `"AvoDoTempo_Q"` | **Bloqueia a habilidade.** É a proteção real contra clones na mochila |
| O Núcleo, lendo o `Value` `RecargaGlobal` | `"AvoDoTempo"` (o nome da Tool) | Trava o `Enabled` de todas as cópias — retorno visual |

As duas duram 45s e começam juntas, então não saem de sincronia.

> **Não crie um `ChaveRecarga` com o valor `"AvoDoTempo_Q"`.** Isso faria as duas dividirem a
> mesma chave, e aí quem chegasse primeiro no `Activated` consumiria a recarga — se fosse o
> Núcleo, a chamada do script devolveria `false` e **a habilidade nunca dispararia**.
> A ordem entre as duas conexões de `Activated` não é garantida: o bug apareceria de forma
> intermitente.

Para desligar a redundância, zere o `Value` `RecargaGlobal` — o script continua protegendo.

## Montagem

1. Criar a `Tool`, nomear `AvoDoTempo`, e pôr o `Handle` (Part/MeshPart do relógio).
2. Colar os cinco scripts com os nomes de objeto da árvore acima.
3. Criar os `Value`s da tabela acima. **`DamageClass` nunca pode faltar** (§12.4).
4. Criar `SFX/` e pôr um `Sound` por linha, com os IDs de
   `ACERVO_RETROVERSE/Guardiao_Do_Tempo/SFX/ids.md` — volume e pitch na instância.
5. `Efeitos/` é opcional: sem molde, o `VFXModule` desenha o efeito proceduralmente.
6. `Grip` configurado **no servidor** — as propriedades `Grip*` não replicam.

