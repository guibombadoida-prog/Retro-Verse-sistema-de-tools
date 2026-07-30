# CanhaoCronos — estrutura no Studio

> Conjunto **Guardião do Tempo** · Feixe reto concentrado
> Origem no modelo: `ChronosCannon (V)`

**Regra nº 1 — tudo é filho da Tool.** Arraste esta Tool sozinha para um place vazio:
ela funciona por inteiro, sem Acervo, sem Núcleo, sem `ReplicatedStorage`.

```
Tool  "CanhaoCronos"        CanBeDropped = false · RequiresHandle = true
├── Handle                          Part/MeshPart do relógio (do modelo)
├── DamageClass    StringValue      "Ranged"
├── EnergyCost     NumberValue      0
├── RecargaGlobal  NumberValue      9
├── CanhaoCronos_Server_V1      Script
├── Client                          LocalScript
├── VFXRemote                       RemoteEvent  servidor → cliente
├── R6CFrameAnimator                ModuleScript V2 (modo absoluto)
├── Poses                           ModuleScript ← Poses_GuardiaoDoTempo_CanhaoCronos_V1.lua
├── VFXModule                       ModuleScript
├── SFX                             Folder
│   └── Carga                     Sound  743521450
│   └── Disparo                   Sound  908895929
└── Efeitos                         Folder  (opcional — sem ele o VFX é procedural)
```

## Habilidades

| Posição | Habilidade | Dispara por |
|---|---|---|
| Primária | Feixe reto concentrado | `Tool.Activated` |
| Extra | — | — |

`ARQUETIPO = "ATIRADOR"`

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
| O Server Script, chamando `_G.Combate.recargaGlobal` | `"CanhaoCronos_V"` | **Bloqueia a habilidade.** É a proteção real contra clones na mochila |
| O Núcleo, lendo o `Value` `RecargaGlobal` | `"CanhaoCronos"` (o nome da Tool) | Trava o `Enabled` de todas as cópias — retorno visual |

As duas duram 9s e começam juntas, então não saem de sincronia.

> **Não crie um `ChaveRecarga` com o valor `"CanhaoCronos_V"`.** Isso faria as duas dividirem a
> mesma chave, e aí quem chegasse primeiro no `Activated` consumiria a recarga — se fosse o
> Núcleo, a chamada do script devolveria `false` e **a habilidade nunca dispararia**.
> A ordem entre as duas conexões de `Activated` não é garantida: o bug apareceria de forma
> intermitente.

Para desligar a redundância, zere o `Value` `RecargaGlobal` — o script continua protegendo.

## Montagem

1. Criar a `Tool`, nomear `CanhaoCronos`, e pôr o `Handle` (Part/MeshPart do relógio).
2. Colar os cinco scripts com os nomes de objeto da árvore acima.
3. Criar os `Value`s da tabela acima. **`DamageClass` nunca pode faltar** (§12.4).
4. Criar `SFX/` e pôr um `Sound` por linha, com os IDs de
   `ACERVO_RETROVERSE/Guardiao_Do_Tempo/SFX/ids.md` — volume e pitch na instância.
5. `Efeitos/` é opcional: sem molde, o `VFXModule` desenha o efeito proceduralmente.
6. `Grip` configurado **no servidor** — as propriedades `Grip*` não replicam.

