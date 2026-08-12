# YorrSlayer — VFX

Extraído por `FERRAMENTAS/extrair_rbxm.py`. Os parâmetros abaixo são os do
modelo original, não estimativas: dá para reconstruir o efeito só com esta tabela.

**Status: CRU.** Nenhum destes entra em Tool antes do passe §12.12.2.

## Resumo

| Tipo | Quantidade |
|---|---|
| `ParticleEmitter` | 30 |
| `Trail` | 1 |
| `PointLight` | 1 |

## Emissores

### `BloodHit` — ParticleEmitter

Caminho: `YorrSlayer/Handle/Attachment1/BloodHit`

| Propriedade | Valor |
|---|---|
| `Texture` | http://www.roblox.com/asset/?id=4581839269 |
| `Rate` | 350 |
| `Lifetime` | 0.7 |
| `Speed` | 30 |
| `Size` | 0→0.25 · 1→0 |
| `Transparency` | 0→1 · 0.1009→0 · 1→0 |
| `Color` | 0→rgb(0,255,17) · 1→rgb(0,255,17) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, -15, 0) |
| `Drag` | 2 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1.2 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `ButterfliesBlue` — ParticleEmitter

Caminho: `YorrSlayer/Server/HitEffect/ButterfliesBlue`

| Propriedade | Valor |
|---|---|
| `Texture` | http://www.roblox.com/asset/?id=9143341648 |
| `Rate` | 60 |
| `Lifetime` | 1 – 2 |
| `Speed` | 10 – 30 |
| `Size` | 0→1.5625 · 1→0 |
| `Transparency` | 0→1 · 0.5025→0 · 1→1 |
| `Color` | 0→rgb(4,255,0) · 1→rgb(4,255,0) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | -135 – -120 |
| `RotSpeed` | -1 – 1 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0 |
| `EmissionDirection` | 0 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | true |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 0.75 |

### `Defenseless_Effect` — ParticleEmitter

Caminho: `YorrSlayer/Server/Curse_of_Defenseless/Defenseless_Effect`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://242911609 |
| `Rate` | 100 |
| `Lifetime` | 0.5 – 1 |
| `Speed` | 5 – 10 |
| `Size` | 0→0.35 · 1→0 |
| `Transparency` | 0→0.25 · 1→1 |
| `Color` | 0→rgb(126,206,72) · 1→rgb(38,62,21) |
| `LightEmission` | 0.5 |
| `LightInfluence` | 0.5 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | -90 – 90 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Dots` — ParticleEmitter

Caminho: `YorrSlayer/Server/HitEffect/Dots`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://11404829064 |
| `Rate` | 55 |
| `Lifetime` | 1 – 2 |
| `Speed` | 40 – 100 |
| `Size` | 0→0 · 0.3668→1.3813 · 1→0 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(38,255,0) · 1→rgb(38,255,0) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | -120 – 120 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 5 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0 |
| `EmissionDirection` | 3 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Dots1` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/Dots1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://10205180639 |
| `Rate` | 60 |
| `Lifetime` | 0.45 – 0.76 |
| `Speed` | 1 – 120 |
| `Size` | 0→0 · 0.4352→3.3877 · 1→0 |
| `Transparency` | 0→1 · 0.3211→0 · 0.6063→0 · 1→1 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | -10 |
| `LightInfluence` | 0 |
| `Brightness` | 3 |
| `Rotation` | 0 – 360 |
| `RotSpeed` | -400 – 400 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 3 |
| `VelocityInheritance` | 1 |
| `ZOffset` | 1.2 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Explosion_Smoke` — ParticleEmitter

Caminho: `YorrSlayer/Yorr the Jungle Dragon v1.5/Torso/SlashHolder/Explosion_Smoke`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxasset://textures/particles/smoke_main.dds |
| `Rate` | 300 |
| `Lifetime` | 2 |
| `Speed` | 20 |
| `Size` | 0→0.125 · 1→10 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(94,70,41) · 1→rgb(94,70,41) |
| `LightEmission` | 0 |
| `LightInfluence` | 1 |
| `Brightness` | 1 |
| `Rotation` | -180 – 180 |
| `RotSpeed` | 0 – 180 |
| `Acceleration` | (0, 8, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0 |
| `EmissionDirection` | 0 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Eye` — ParticleEmitter

Caminho: `YorrSlayer/Server/HitEffect/Eye`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://10455603612 |
| `Rate` | 1 |
| `Lifetime` | 1 |
| `Speed` | 0 |
| `Size` | 0→10 · 1→10 |
| `Transparency` | 0→1 · 0.5574→0 · 1→1 |
| `Color` | 0→rgb(0,255,0) · 1→rgb(0,255,0) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | 0 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 15 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→-1.0125 · 0.2494→0.4875 · 0.5224→-1.875 · 0.8204→0.675 · 1→0.4875 |
| `TimeScale` | 1 |

### `Fire` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/Fire`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://13765238618 |
| `Rate` | 20 |
| `Lifetime` | 0.65 – 0.85 |
| `Speed` | 0 |
| `Size` | 0→0 · 1→32.4278 |
| `Transparency` | 0→0 · 0.1→0.0001 · 0.2→0.0011 · 0.3→0.0044 · 0.4→0.0122 · 0.5→0.0287 · 0.6→0.0614 · 0.7→0.1255 · 0.8→0.2538 · 0.9→0.5154 · 1→1 |
| `Color` | 0→rgb(131,255,135) · 1→rgb(131,255,135) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 14 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 5 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0.05 |
| `EmissionDirection` | 0 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Fire` — ParticleEmitter

Caminho: `YorrSlayer/Handle/Hitbox/Fire`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://8612048548 |
| `Rate` | 50 |
| `Lifetime` | 1 |
| `Speed` | 1 |
| `Size` | 0→2.12 · 0.0935→3.125 · 0.4695→1 · 1→0 |
| `Transparency` | 0→1 · 1→0 |
| `Color` | 0→rgb(0,255,0) · 1→rgb(0,255,0) |
| `LightEmission` | 0.4 |
| `LightInfluence` | 0 |
| `Brightness` | 1.675 |
| `Rotation` | -180 – 180 |
| `RotSpeed` | -50 – 50 |
| `Acceleration` | (0, 3, 0) |
| `Drag` | 3 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 3 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | true |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Fire spec` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/Fire spec`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://14008134527 |
| `Rate` | 23 |
| `Lifetime` | 0.7 |
| `Speed` | 50 |
| `Size` | 0→0 · 0.1796→10 · 1→0 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(84,255,164) · 1→rgb(84,255,164) |
| `LightEmission` | -0.5 |
| `LightInfluence` | 0 |
| `Brightness` | 10 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 336.051, 0) |
| `Drag` | 10 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `FlashCircle` — ParticleEmitter

Caminho: `YorrSlayer/Server/Undying_Effect/FlashCircle`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://483229625 |
| `Rate` | 1 |
| `Lifetime` | 0.4 |
| `Speed` | 0 |
| `Size` | 0→2 · 1→3 |
| `Transparency` | 0→1 · 0.2→0 · 1→1 |
| `Color` | 0→rgb(0,255,17) · 1→rgb(0,255,17) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | 0 – 135 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 1 |
| `ZOffset` | 15 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | true |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `HeartRateLine` — ParticleEmitter

Caminho: `YorrSlayer/Server/Undying_Effect/HeartRateLine`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://878492795 |
| `Rate` | 1 |
| `Lifetime` | 1 |
| `Speed` | 0 |
| `Size` | 0→1 · 0.1→10 · 0.2→0 · 1→0 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(0,170,255) · 1→rgb(255,255,255) |
| `LightEmission` | 1 |
| `LightInfluence` | 1 |
| `Brightness` | 1 |
| `Rotation` | 0 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 15 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `ParticleEmitter` — ParticleEmitter

Caminho: `YorrSlayer/Handle/Attachment1/ParticleEmitter`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://243664729 |
| `Rate` | 240 |
| `Lifetime` | 1 |
| `Speed` | 30 |
| `Size` | 0→1.94 · 1→0 |
| `Transparency` | 0→1 · 0.0262→0 · 0.802→0 · 1→1 |
| `Color` | 0→rgb(0,167,11) · 1→rgb(0,167,11) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, -40, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1.4 |
| `EmissionDirection` | 4 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Slash1` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/A1/Slash1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://15077160455 |
| `Rate` | 200 |
| `Lifetime` | 0.15 – 0.25 |
| `Speed` | 1 – 30 |
| `Size` | 0→15.0729 · 0.4012→24.1403 · 1→31.1128 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | -5 |
| `LightInfluence` | 0 |
| `Brightness` | 3 |
| `Rotation` | -90 – 90 |
| `RotSpeed` | 1000 |
| `Acceleration` | (0, 7, 0) |
| `Drag` | 1 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 2.4262 |
| `EmissionDirection` | 1 |
| `Orientation` | 3 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Slash2` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/A1/Slash2`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://15077160455 |
| `Rate` | 200 |
| `Lifetime` | 0.15 – 0.25 |
| `Speed` | 1 – 30 |
| `Size` | 0→15.0729 · 0.4012→24.1403 · 1→31.1128 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 0 |
| `Rotation` | -90 – 90 |
| `RotSpeed` | 1000 |
| `Acceleration` | (0, 7, 0) |
| `Drag` | 1 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 2.4262 |
| `EmissionDirection` | 1 |
| `Orientation` | 3 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Smoke` — ParticleEmitter

Caminho: `YorrSlayer/Server/Vine_Trap/Smoke`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxasset://textures/particles/smoke_main.dds |
| `Rate` | 50 |
| `Lifetime` | 1 |
| `Speed` | 1 |
| `Size` | 0→2 · 1→0 |
| `Transparency` | 0→1 · 0.1→0 · 1→1 |
| `Color` | 0→rgb(0,255,0) · 0.5552→rgb(105,255,115) · 0.6388→rgb(87,255,32) · 1→rgb(0,255,0) |
| `LightEmission` | 0.5 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | -360 – 360 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 0 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Smoke1` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/Smoke1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://13410359900 |
| `Rate` | 200 |
| `Lifetime` | 0.45 – 1 |
| `Speed` | 1 – 120 |
| `Size` | 0→0 · 0.0392→11.4663 · 0.1512→18.1346 · 0.3772→22.3332 · 1→24.6976 |
| `Transparency` | 0→1 · 0.1784→0.7812 · 1→1 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | 0.1 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, -4, 0) |
| `Drag` | 5 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1 |
| `EmissionDirection` | 5 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Sparks` — ParticleEmitter

Caminho: `YorrSlayer/Handle/Hitbox/Sparks`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://8612024759 |
| `Rate` | 50 |
| `Lifetime` | 1 |
| `Speed` | 5 |
| `Size` | 0→0 · 0.1252→0.1875 · 1→0 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(0,255,0) · 1→rgb(0,255,0) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 1.675 |
| `Rotation` | 0 |
| `RotSpeed` | -30 – 30 |
| `Acceleration` | (0, 5, 0) |
| `Drag` | 2 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 3 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | true |
| `Squash` | 0→-0.4125 · 1→0 |
| `TimeScale` | 1 |

### `Sparks1` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/Sparks1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://7994629137 |
| `Rate` | 70 |
| `Lifetime` | 0.15 – 0.25 |
| `Speed` | 15 – 60 |
| `Size` | 0→0 · 0.1332→10.4565 · 1→0 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | -10 |
| `LightInfluence` | 0 |
| `Brightness` | 3 |
| `Rotation` | 0 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 4 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1.2 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→-6.6091 |
| `TimeScale` | 1 |

### `Star Sparks` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/Star Sparks`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://8611887703 |
| `Rate` | 20 |
| `Lifetime` | 0.5 – 3 |
| `Speed` | 50 – 100 |
| `Size` | 0→0 · 0.1493→0.6875 · 1→0 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(4,255,0) · 1→rgb(4,255,0) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 10 |
| `Rotation` | -30 – 30 |
| `RotSpeed` | -30 – 30 |
| `Acceleration` | (0, 3, 0) |
| `Drag` | 3 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 2 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `StarFlash` — ParticleEmitter

Caminho: `YorrSlayer/Server/Undying_Effect/StarFlash`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://1141830599 |
| `Rate` | 1 |
| `Lifetime` | 0.4 |
| `Speed` | 0 |
| `Size` | 0→3.5 · 0.5→10 · 1→3 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(0,255,17) · 1→rgb(0,255,17) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -180 – 180 |
| `RotSpeed` | 360 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 1 |
| `ZOffset` | 15 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | true |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Stars1` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectFolderSlash/Stars1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://7216848960 |
| `Rate` | 60 |
| `Lifetime` | 0.15 – 0.25 |
| `Speed` | 120 – 240 |
| `Size` | 0→0 · 0.1772→4.0329 · 1→0 |
| `Transparency` | 0→1 · 0.3211→0 · 0.6063→0 · 1→1 |
| `Color` | 0→rgb(0,125,29) · 1→rgb(0,125,29) |
| `LightEmission` | -10 |
| `LightInfluence` | 0 |
| `Brightness` | 3 |
| `Rotation` | 0 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 3 |
| `VelocityInheritance` | 1 |
| `ZOffset` | 1.2 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→-2.299 |
| `TimeScale` | 1 |

### `Stone` — ParticleEmitter

Caminho: `YorrSlayer/Yorr the Jungle Dragon v1.5/Torso/SlashHolder/Stone`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://110971351869251 |
| `Rate` | 75 |
| `Lifetime` | 3 |
| `Speed` | 50 |
| `Size` | 0→1 · 1→0.9836 |
| `Transparency` | 0→0.9875 · 0.0995→0.2375 · 0.8011→0.2437 · 1→0.975 |
| `Color` | 0→rgb(255,138,70) · 1→rgb(255,138,70) |
| `LightEmission` | 0 |
| `LightInfluence` | 1 |
| `Brightness` | 10 |
| `Rotation` | -180 – 180 |
| `RotSpeed` | -180 – 180 |
| `Acceleration` | (0, -50, 0) |
| `Drag` | 2.25 |
| `VelocityInheritance` | 0.25 |
| `ZOffset` | 4 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Test` — ParticleEmitter

Caminho: `YorrSlayer/Server/HitEffect/Test`

| Propriedade | Valor |
|---|---|
| `Texture` | http://www.roblox.com/asset/?id=16465031704 |
| `Rate` | 45 |
| `Lifetime` | 0.8 |
| `Speed` | 0.0006 |
| `Size` | 0→10 · 1→10 |
| `Transparency` | 0→0 · 1→0 |
| `Color` | 0→rgb(0,255,30) · 1→rgb(0,255,30) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1 |
| `EmissionDirection` | 3 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `Trail` — Trail

Caminho: `YorrSlayer/Handle/Trail`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://6091329339 |
| `Lifetime` | 1 |
| `MinLength` | 0.1 |
| `MaxLength` | 0 |
| `WidthScale` | 0→1 · 1→0 |
| `Color` | 0→rgb(0,163,0) · 1→rgb(0,163,0) |
| `Transparency` | 0→0.5 · 1→1 |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `FaceCamera` | false |
| `Enabled` | false |

### `TrailFire` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/TrailFire`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://14897103841 |
| `Rate` | 20 |
| `Lifetime` | 0.75 – 1 |
| `Speed` | 0 |
| `Size` | 0→10 · 0.3466→10 · 1→28.0507 |
| `Transparency` | 0→0 · 0.1→0.0001 · 0.2→0.0011 · 0.3→0.0044 · 0.4→0.0122 · 0.5→0.0287 · 0.6→0.0614 · 0.7→0.1255 · 0.8→0.2538 · 0.9→0.5154 · 1→1 |
| `Color` | 0→rgb(255,255,255) · 1→rgb(255,255,255) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 1 |
| `Rotation` | -360 – 360 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 5 |
| `VelocityInheritance` | 0 |
| `ZOffset` | -1 |
| `EmissionDirection` | 0 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `a` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/a`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://11843575561 |
| `Rate` | 8 |
| `Lifetime` | 0.7 – 0.8 |
| `Speed` | 50 |
| `Size` | 0→0 · 0.0739→0 · 0.2781→10 · 0.4521→10 · 0.6504→10 · 0.842→10 · 1→10 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(4,255,0) · 1→rgb(4,255,0) |
| `LightEmission` | 0.25 |
| `LightInfluence` | 0 |
| `Brightness` | 12 |
| `Rotation` | -90 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 0 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 1 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0.25 · 1→0.25 |
| `TimeScale` | 1 |

### `poison specks` — ParticleEmitter

Caminho: `YorrSlayer/Handle/Attachment1/poison specks`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://8511527728 |
| `Rate` | 100 |
| `Lifetime` | 1 – 2 |
| `Speed` | 30 – 50 |
| `Size` | 0→0 · 0.036→0.6875 · 0.0829→1.0625 · 0.125→0.5 · 0.854→0.3125 · 1→0 |
| `Transparency` | 0→0 · 1→1 |
| `Color` | 0→rgb(13,255,0) · 1→rgb(13,255,0) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | -180 – 180 |
| `RotSpeed` | -200 – 200 |
| `Acceleration` | (0, 0, 0) |
| `Drag` | 5 |
| `VelocityInheritance` | 0 |
| `ZOffset` | -0.13 |
| `EmissionDirection` | 1 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→-0.3 · 0.1068→0.225 · 0.2113→-0.5625 · 0.2832→0 · 1→0 |
| `TimeScale` | 1 |

### `shards` — ParticleEmitter

Caminho: `YorrSlayer/Server/EffectExplode/shards`

| Propriedade | Valor |
|---|---|
| `Texture` | http://www.roblox.com/asset/?id=13711999895 |
| `Rate` | 20 |
| `Lifetime` | 1 |
| `Speed` | 100 – 250 |
| `Size` | 0→4.5 · 1→0 |
| `Transparency` | 0→0 · 0.1035→0.9 · 0.2993→0 · 0.4476→0.875 · 0.616→0 · 0.7818→0.8625 · 1→0 |
| `Color` | 0→rgb(255,255,255) · 1→rgb(255,255,255) |
| `LightEmission` | 0.65 |
| `LightInfluence` | 0 |
| `Brightness` | 6.795 |
| `Rotation` | 90 |
| `RotSpeed` | 0 |
| `Acceleration` | (0, 100, 0) |
| `Drag` | 10 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 2 |
| `EmissionDirection` | 1 |
| `Orientation` | 2 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→1 · 1→0.1125 |
| `TimeScale` | 1 |

### `shine` — ParticleEmitter

Caminho: `YorrSlayer/Server/Undying_Effect/shine`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://14762356114 |
| `Rate` | 35 |
| `Lifetime` | 0.3 – 1.6 |
| `Speed` | 50 – 100 |
| `Size` | 0→0 · 0.1→3 · 0.2→0 · 0.3→3 · 0.4→0 · 0.5→3 · 0.599→0 · 0.7→3 · 0.8005→0 · 0.897→3 · 1→0 |
| `Transparency` | 0→0 · 0.1→0.75 · 0.2→0 · 0.3→0.75 · 0.4→0 · 0.5→0.75 · 0.6→0 · 0.7→0.75 · 0.8→0 · 0.9→0.75 · 1→0 |
| `Color` | 0→rgb(13,255,0) · 1→rgb(13,255,0) |
| `LightEmission` | 1 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | 0 |
| `RotSpeed` | -4 – 4 |
| `Acceleration` | (0, 4, 0) |
| `Drag` | 8 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 15 |
| `EmissionDirection` | 5 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

### `shine1` — ParticleEmitter

Caminho: `YorrSlayer/Server/Undying_Effect/shine1`

| Propriedade | Valor |
|---|---|
| `Texture` | rbxassetid://14834478801 |
| `Rate` | 35 |
| `Lifetime` | 0.3 – 1.6 |
| `Speed` | 50 – 100 |
| `Size` | 0→0 · 0.1→3 · 0.2→0 · 0.3→3 · 0.4→0 · 0.5→3 · 0.599→0 · 0.7→3 · 0.8005→0 · 0.897→3 · 1→0 |
| `Transparency` | 0→0 · 0.1→0.75 · 0.2→0 · 0.3→0.75 · 0.4→0 · 0.5→0.75 · 0.6→0 · 0.7→0.75 · 0.8→0 · 0.9→0.75 · 1→0 |
| `Color` | 0→rgb(13,255,0) · 1→rgb(13,255,0) |
| `LightEmission` | 0 |
| `LightInfluence` | 0 |
| `Brightness` | 5 |
| `Rotation` | 0 |
| `RotSpeed` | -4 – 4 |
| `Acceleration` | (0, 4, 0) |
| `Drag` | 8 |
| `VelocityInheritance` | 0 |
| `ZOffset` | 15 |
| `EmissionDirection` | 5 |
| `Orientation` | 0 |
| `Shape` | 0 |
| `LockedToPart` | false |
| `Enabled` | false |
| `Squash` | 0→0 · 1→0 |
| `TimeScale` | 1 |

## Luz e realce

| Nome | Classe | Caminho |
|---|---|---|
| `PointLight` | `PointLight` | `YorrSlayer/Handle/PointLight` |

