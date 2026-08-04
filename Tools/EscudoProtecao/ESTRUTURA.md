# EscudoProtecao — estrutura

Origem: **Protecao (Danilo_Escudos)**

## Hierarquia dentro da Tool

```
EscudoProtecao  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Defense"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 7
├── EscudoProtecao_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoProtecao_V1
├── VFXRemote                   RemoteEvent
├── SFX                         Folder
│   └── Orbita                   Sound
│   └── Rebate                   Sound
└── Efeitos                     Folder
    └── CLARAO_ESCUDO            Part ancora — Clarao
    └── AURA                     Part ancora — Aura
    └── FAISCA                   Part ancora — Faisca, Anel
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | o escudo orbita por 4 s e rebate projetil em quem atirou |
| **Extra** | não tem — a primária já é a habilidade inteira |

`ToolTip`: Escudo Protecao - um escudo orbita voce e rebate projetil de volta em quem atirou

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
