# EscudoBloqueador — estrutura

Origem: **Escudo Bloqueador (Danilo_Escudos)**

## Hierarquia dentro da Tool

```
EscudoBloqueador  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Defense"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 8
├── EscudoBloqueador_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoBloqueador_V1
├── VFXRemote                   RemoteEvent
├── AcaoRemote                  RemoteEvent — tecla X
├── SFX                         Folder
│   └── Barreira                 Sound
│   └── Bloqueio                 Sound
│   └── Reflexo                  Sound
└── Efeitos                     Folder
    └── CLARAO_ESCUDO            Part ancora — Clarao
    └── IMPACTO_ESCUDO           Part ancora — Impacto
    └── AURA                     Part ancora — Aura
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | postura de bloqueio: 25% de reducao e 15% refletido |
| **Extra** (tecla X) | Barreira em cupula: 52% para aliados no raio 15, empurrao 90 |

`ToolTip`: Escudo Bloqueador - reduz o dano que voce toma e devolve parte ao atacante. X ergue a barreira

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
