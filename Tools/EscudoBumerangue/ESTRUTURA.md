# EscudoBumerangue — estrutura

Origem: **Escudo Bumerangue (Danilo_Escudos)**

## Hierarquia dentro da Tool

```
EscudoBumerangue  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Ranged"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 3
├── EscudoBumerangue_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoBumerangue_V1
├── VFXRemote                   RemoteEvent
├── AcaoRemote                  RemoteEvent — tecla X
├── SFX                         Folder
│   └── Arremesso                Sound
│   └── Impacto                  Sound
│   └── Retorno                  Sound
└── Efeitos                     Folder
    └── IMPACTO_ESCUDO           Part ancora — Impacto
    └── ESTILHACO_ESCUDO         Part ancora — Estilhaco
    └── FAISCA                   Part ancora — Faisca, Anel
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | arremessa o disco, que vai ate 50 studs e VOLTA para a mao |
| **Extra** (tecla X) | Trinca: tres discos em leque de 15 graus |

`ToolTip`: Escudo Bumerangue - arremessa o escudo, que volta a sua mao. X lanca tres de uma vez

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
