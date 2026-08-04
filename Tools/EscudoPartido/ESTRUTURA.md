# EscudoPartido — estrutura

Origem: **AUTORAL**

## Hierarquia dentro da Tool

```
EscudoPartido  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Melee"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 22
├── EscudoPartido_Server_V1   Script
├── Client                      LocalScript
├── CutsceneCam                 LocalScript — camera 100%% cliente
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoPartido_V1
├── VFXRemote                   RemoteEvent
├── AcaoRemote                  RemoteEvent — tecla X
├── CutsceneRemote              RemoteEvent — beats da cutscene
├── SFX                         Folder
│   └── Corte                    Sound
│   └── Estilhaco                Sound
│   └── Sentenca                 Sound
└── Efeitos                     Folder
    └── ESTILHACO_ESCUDO         Part ancora — Estilhaco
    └── CLARAO_ESCUDO            Part ancora — Clarao
    └── ONDA_ESCUDO              Part ancora — Onda
    └── IMPACTO_ESCUDO           Part ancora — Impacto
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | lanca uma lamina que vai reto ate 62 studs e NAO volta |
| **Extra** (tecla X) | Sentenca: cutscene com 6 cortes + golpe mortal de 299 |

`ToolTip`: Escudo Partido - o escudo vira lamina e corta sem voltar. X executa a sentenca

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
