# EscudoSkate — estrutura

Origem: **Escudo Skate (Danilo_Escudos)**

## Hierarquia dentro da Tool

```
EscudoSkate  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Mobility"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 8
├── EscudoSkate_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoSkate_V1
├── VFXRemote                   RemoteEvent
├── SFX                         Folder
│   └── Atropelo                 Sound
│   └── Partida                  Sound
└── Efeitos                     Folder
    └── POEIRA_ESCUDO            Part ancora — Poeira
    └── IMPACTO_ESCUDO           Part ancora — Impacto
    └── FAISCA                   Part ancora — Faisca, Anel
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | monta no escudo: +35 de velocidade por 5 s, atropela por 10 |
| **Extra** | não tem — a primária já é a habilidade inteira |

`ToolTip`: Escudo Skate - monta no escudo e corre atropelando quem estiver na frente

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
