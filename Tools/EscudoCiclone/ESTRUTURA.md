# EscudoCiclone — estrutura

Origem: **AUTORAL**

## Hierarquia dentro da Tool

```
EscudoCiclone  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Debuff"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 14
├── EscudoCiclone_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoCiclone_V1
├── VFXRemote                   RemoteEvent
├── AcaoRemote                  RemoteEvent — tecla X
├── SFX                         Folder
│   └── Ciclone                  Sound
│   └── Colapso                  Sound
│   └── Puxao                    Sound
└── Efeitos                     Folder
    └── ONDA_ESCUDO              Part ancora — Onda
    └── POEIRA_ESCUDO            Part ancora — Poeira
    └── AURA                     Part ancora — Aura
    └── IMPACTO_ESCUDO           Part ancora — Impacto
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | cinco escudos orbitam e puxam quem entra no raio 22, por 8 s |
| **Extra** (tecla X) | Colapso: os cinco convergem, 62 de dano no raio 14 |

`ToolTip`: Escudo Ciclone - cinco escudos giram em volta e puxam quem chega perto. X colapsa o ciclone

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
