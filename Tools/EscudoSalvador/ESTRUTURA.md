# EscudoSalvador — estrutura

Origem: **Salvador (Danilo_Escudos)**

## Hierarquia dentro da Tool

```
EscudoSalvador  (Tool)
├── Handle                      Part — escudo montado com primitivas
│   ├── Face · AroExterno · AroInterno · Bossa
│   └── NervuraA · NervuraB · Alca      (WeldConstraint em cada)
├── DamageClass                 StringValue = "Support"
├── EnergyCost                  NumberValue = 0
├── RecargaGlobal               NumberValue = 10
├── EscudoSalvador_Server_V1   Script
├── Client                      LocalScript
├── R6CFrameAnimator            ModuleScript — V2 canonico, byte a byte
├── VFXModule                   ModuleScript
├── Poses                       ModuleScript — Poses_Escudos_EscudoSalvador_V1
├── VFXRemote                   RemoteEvent
├── SFX                         Folder
│   └── Transferencia            Sound
│   └── Vinculo                  Sound
└── Efeitos                     Folder
    └── CLARAO_ESCUDO            Part ancora — Clarao
    └── AURA                     Part ancora — Aura
    └── ESTILHACO_ESTELAR        Part ancora — Estrelas, Cintilar
```

## Habilidades

| | O que faz |
|---|---|
| **Primária** (`Tool.Activated`) | vincula a um aliado por 7 s: o dano dele vem para voce |
| **Extra** | não tem — a primária já é a habilidade inteira |

`ToolTip`: Escudo Salvador - assume o dano de um aliado por sete segundos. Voce sangra no lugar dele

## Regra nº 1

Todo `Sound`, molde de efeito, pose e módulo acima é **filho da Tool**.
Arraste este `.rbxmx` sozinho para um place vazio e a Tool funciona por inteiro —
sem Acervo, sem `ReplicatedStorage`, e sem o `NucleoCombate` (aí sem os bônus).
