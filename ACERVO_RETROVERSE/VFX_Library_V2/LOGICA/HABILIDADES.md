# VFX_Library_V2 — inventário de lógica

> ⚠️ **Isto é CONSULTA, não material de reuso.** Lógica de combate de
> terceiro **não entra em Tool** (§12.12.1). Está catalogada para se saber
> o que cada habilidade fazia, e então reimplementá-la conforme, pelo Núcleo.

## Teclas encontradas

`Space`

## Dano aplicado

| Script | Chamada |
|---|---|
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `mainscript` | `Health = hum.MaxHealth` |
| `mainscript` | `Health = oldmaxhealth` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `Ragdoll` | `Health = 0` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `Ragdoll` | `Health = 0` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `mainscript` | `Health = -1` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Script` | `Health = hum.MaxHealth` |
| `Script` | `Health = oldmaxhealth` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Ragdoll` | `Health = 0` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |
| `Ragdoll` | `Health = 0` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |
| `Script` | `Health = -1` |

## Achados do passe §12.12.2

| Achado | Ocorrências | Situação |
|---|---|---|
| `ScreenGui` — ScreenGui é proibido dentro da Tool (§12.12.4) | 8 | ❌ excluir |
| math.random em gameplay — proibido (§10) | 1113 | ❌ corrigir |
| :Destroy() em instância — usar Parent = nil / Debris | 911 | ❌ corrigir |
| spawn() — usar task.spawn | 430 | ❌ corrigir |
| wait() — usar task.wait | 344 | ❌ corrigir |
| tick() — usar acumulador dt / os.clock | 181 | ❌ corrigir |
| :Emit no servidor — o servidor transmite, não emite | 177 | ❌ corrigir |
| BreakJoints — fura ForceField | 152 | ❌ corrigir |
| LoadAnimation — virar pose CFrame | 26 | ❌ corrigir |
| require de id numérico — proibido (§12.12.1) | 13 | ❌ corrigir |

## Scripts

| Linhas | Classe | Caminho |
|---|---|---|
| 826 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script` |
| 800 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script` |
| 725 | `Script` | `03_Genos/M1/Script` |
| 485 | `Script` | `01_Saitama/Normal Punch/mainscript` |
| 549 | `Script` | `02_Garou/Hunter's Grasp/Script` |
| 559 | `Script` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script` |
| 511 | `Script` | `06_JoJo/I cannot attack ____./Script` |
| 475 | `Script` | `01_Saitama/Consecutive Normal Punches/mainscript` |
| 495 | `Script` | `06_JoJo/And now, you're going to have to disappear./Script` |
| 492 | `Script` | `01_Saitama/Normal Shove/mainscript` |
| 516 | `Script` | `02_Garou/Lethal Whirlwind Stream/Script` |
| 557 | `Script` | `02_Garou/Flowing Water/Script` |
| 485 | `Script` | `05_Killua/Raging Sokudo/Func/Beatdown/script` |
| 398 | `Script` | `05_Killua/Godspeed Rush/Func` |
| 393 | `Script` | `05_Killua/Lightning Palm/Func` |
| 387 | `ModuleScript` | `02_Garou/Flowing Water/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/Rampage/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/The Final Hunt/Script/Ragdoll` |
| 387 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/Ragdoll` |
| 387 | `ModuleScript` | `03_Genos/Blitz Shot/Script/Ragdoll` |
| 387 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Ragdoll` |
| 387 | `ModuleScript` | `03_Genos/Jet Dive/Script/Ragdoll` |
| 387 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/Ragdoll` |
| 385 | `ModuleScript` | `03_Genos/M1/Script/Ragdoll` |
| 385 | `ModuleScript` | `04_Gojo/Purple/Script/Ragdoll` |
| 385 | `ModuleScript` | `07_Comum/Dash/Script/Ragdoll` |
| 376 | `Script` | `05_Killua/Thunderbolt/Func` |
| 410 | `Script` | `03_Genos/Machine Gun Blows/Script` |
| 387 | `Script` | `04_Gojo/Red/Script` |
| 389 | `Script` | `05_Killua/Raging Sokudo/Func` |
| 368 | `Script` | `02_Garou/Hunter's Cruelty/Script` |
| 349 | `Script` | `04_Gojo/Purple/Script` |
| 390 | `Script` | `03_Genos/Ignition Burst/Script` |
| 320 | `Script` | `02_Garou/The Final Hunt/Script` |
| 335 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript` |
| 334 | `Script` | `01_Saitama/Serious Punch/mainscript` |
| 253 | `ModuleScript` | `02_Garou/Rampage/Script/Smash/Modules/RockModule` |
| 253 | `ModuleScript` | `02_Garou/The Final Hunt/Script/RockModule` |
| 253 | `ModuleScript` | `02_Garou/Flowing Water/Script/RockModule` |
| 253 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/RockModule` |
| 253 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/RockModule` |
| 253 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/RockModule` |
| 253 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/RockModule` |
| 253 | `ModuleScript` | `03_Genos/Blitz Shot/Script/RockModule` |
| 253 | `ModuleScript` | `03_Genos/Ignition Burst/Script/RockModule` |
| 253 | `ModuleScript` | `03_Genos/Jet Dive/Script/RockModule` |
| 253 | `ModuleScript` | `03_Genos/M1/Script/RockModule` |
| 253 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/RockModule` |
| 253 | `ModuleScript` | `07_Comum/Dash/Script/RockModule` |
| 318 | `Script` | `07_Comum/Dash/Script` |
| 307 | `Script` | `02_Garou/Water Stream Rock Smashing/Script` |
| 290 | `Script` | `01_Saitama/Normal Uppercut/mainscript` |
| 317 | `Script` | `03_Genos/Jet Dive/Script` |
| 309 | `Script` | `01_Saitama/Table Flip/mainscript` |
| 219 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Beatdown/script/LightningBolt` |
| 291 | `Script` | `06_JoJo/What's it feel like when time stands still?/Script` |
| 292 | `Script` | `02_Garou/Rampage/Script` |
| 267 | `Script` | `03_Genos/Blitz Shot/Script` |
| 263 | `Script` | `06_JoJo/7 Page Muda/Script` |
| 208 | `Script` | `05_Killua/Mutilate/Func` |
| 209 | `Script` | `01_Saitama/Death Counter/mainscript` |
| 148 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/Modules/RocksModule` |
| 146 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/Modules/RocksModule` |
| 146 | `ModuleScript` | `04_Gojo/Purple/Script/Modules/RocksModule` |
| 236 | `Script` | `05_Killua/Instant Death/Func` |
| 163 | `Script` | `05_Killua/The Snake Awakens/Func` |
| 182 | `ModuleScript` | `06_JoJo/7 Page Muda/Script/Animator` |
| 182 | `ModuleScript` | `06_JoJo/And now, you're going to have to disappear./Script/Animator` |
| 182 | `ModuleScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Animator` |
| 182 | `ModuleScript` | `06_JoJo/What's it feel like when time stands still?/Script/Animator` |
| 182 | `ModuleScript` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/Animator` |
| 208 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Normal Shove/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Serious Mode/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Flowing Water/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Rampage/Script/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/The Final Hunt/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `03_Genos/Blitz Shot/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `03_Genos/Jet Dive/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `03_Genos/M1/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/Assets/Shaker/CameraShaker` |
| 208 | `ModuleScript` | `04_Gojo/Purple/Script/CameraShaker` |
| 208 | `ModuleScript` | `04_Gojo/Red/Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/7 Page Muda/Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/And now, you're going to have to disappear./Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/I cannot attack ____./Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/What's it feel like when time stands still?/Script/CameraShaker` |
| 208 | `ModuleScript` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/CameraShaker` |
| 208 | `ModuleScript` | `07_Comum/Dash/Script/Assets/Shaker/CameraShaker` |
| 167 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Beatdown/script/LightningBolt/LightningExplosion` |
| 164 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Beatdown/script/LightningBolt/LightningSparks` |
| 168 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Normal Shove/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Serious Mode/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Flowing Water/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Rampage/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/The Final Hunt/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `03_Genos/Blitz Shot/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `03_Genos/Jet Dive/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `03_Genos/M1/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `04_Gojo/Purple/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `04_Gojo/Red/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/7 Page Muda/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/And now, you're going to have to disappear./Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/I cannot attack ____./Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/What's it feel like when time stands still?/Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/CameraShaker/CameraShakeInstance` |
| 168 | `ModuleScript` | `07_Comum/Dash/Script/Assets/Shaker/CameraShaker/CameraShakeInstance` |
| 92 | `LocalScript` | `02_Garou/Water Stream Rock Smashing/Script/Assets/BarrageEff` |
| 88 | `LocalScript` | `01_Saitama/Consecutive Normal Punches/mainscript/BarrageEff` |
| 88 | `Script` | `01_Saitama/Table Flip/mainscript/rocks/mainscript` |
| 151 | `LocalScript` | `01_Saitama/Consecutive Normal Punches/mainscript/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Death Counter/mainscript/Animation/paunch/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Normal Punch/mainscript/Animation/paunch/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Normal Shove/mainscript/Animation/shove/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Normal Uppercut/mainscript/Animation/upper/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Serious Mode/mainscript/Animation/angry/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Animation/flip/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Animation2/cam/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation/flip/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation2/cam/AnimationPlayer` |
| 151 | `LocalScript` | `01_Saitama/Table Flip/mainscript/Animation/flip/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Flowing Water/Script/Animation/water/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Flowing Water/Script/Animation/flowing/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Hunter's Cruelty/Script/Animation/smash/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Hunter's Cruelty/Script/Animation/cruel/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Hunter's Grasp/Script/Animation/grasp/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Hunter's Grasp/Script/Animation/cruel/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Hunter's Grasp/Script/Animation/smash/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Lethal Whirlwind Stream/Script/Animation/stream/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Lethal Whirlwind Stream/Script/Animation/lethal/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Rampage/Script/Animation/smash/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/The Final Hunt/Script/Animation/final2/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/The Final Hunt/Script/Animation/final1/AnimationPlayer` |
| 151 | `LocalScript` | `02_Garou/Water Stream Rock Smashing/Script/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Blitz Shot/Script/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Ignition Burst/Script/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Ignition Burst/Script/Animation/ignition/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Jet Dive/Script/Animation/land/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Jet Dive/Script/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/2/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/1/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/3/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/4/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/slam/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/M1/Script/Animation/uppercut/AnimationPlayer` |
| 151 | `LocalScript` | `03_Genos/Machine Gun Blows/Script/Animation/barrage/AnimationPlayer` |
| 151 | `LocalScript` | `04_Gojo/Purple/Script/Animation/paunch/AnimationPlayer` |
| 151 | `LocalScript` | `04_Gojo/Red/Script/Animation/paunch/AnimationPlayer` |
| 151 | `LocalScript` | `07_Comum/Dash/Script/Animation/water/AnimationPlayer` |
| 151 | `LocalScript` | `07_Comum/Dash/Script/Animation/flowing/AnimationPlayer` |
| 76 | `LocalScript` | `03_Genos/Machine Gun Blows/Script/Assets/BarrageEff` |
| 63 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/rocks/Modules/RocksModule` |
| 62 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/rocks/Modules/RocksModule` |
| 62 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Assets/rocks/Modules/RocksModule` |
| 54 | `Script` | `02_Garou/Rampage/Script/Smash/mainscript` |
| 133 | `LocalScript` | `06_JoJo/And now, you're going to have to disappear./Script/Animation/Attack/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Godspeed Rush/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Instant Death/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Lightning Palm/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Mutilate/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Raging Sokudo/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Raging Sokudo/Func/Animation2/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/The Snake Awakens/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Thunderbolt/Func/Animation/Anim/AnimationPlayer` |
| 129 | `LocalScript` | `05_Killua/Thunderbolt/Func/Animation2/Anim/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/I cannot attack ____./Script/Animation/Attack/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/I cannot attack ____./Script/Animation/Pen/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Animation/Attack/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Idle/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Kick/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Barrage/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Finisher/AnimationPlayer` |
| 127 | `LocalScript` | `06_JoJo/What's it feel like when time stands still?/Script/Animation/Attack/AnimationPlayer` |
| 69 | `Script` | `01_Saitama/Serious Punch/mainscript/rocks/mainscript` |
| 65 | `Script` | `01_Saitama/Death Counter/mainscript/rocks/mainscript` |
| 105 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Normal Shove/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Serious Mode/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Flowing Water/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Rampage/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/The Final Hunt/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `03_Genos/Blitz Shot/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `03_Genos/Jet Dive/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `03_Genos/M1/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `04_Gojo/Purple/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `04_Gojo/Red/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/7 Page Muda/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/And now, you're going to have to disappear./Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/I cannot attack ____./Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/What's it feel like when time stands still?/Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/CameraShaker/CameraShakePresets` |
| 105 | `ModuleScript` | `07_Comum/Dash/Script/Assets/Shaker/CameraShaker/CameraShakePresets` |
| 56 | `ModuleScript` | `01_Saitama/Normal Shove/mainscript/RocksModule` |
| 56 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/rocks/Modules/RocksModule` |
| 56 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/rocks/Modules/RocksModule` |
| 83 | `Script` | `01_Saitama/Serious Mode/mainscript` |
| 59 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/rocks/Modules/RocksModule` |
| 65 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/rocks/Modules/DebrisModule` |
| 65 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/rocks/Modules/DebrisModule` |
| 65 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/rocks/Modules/DebrisModule` |
| 65 | `ModuleScript` | `04_Gojo/Purple/Script/Modules/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Flowing Water/Script/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Rampage/Script/Smash/Modules/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/The Final Hunt/Script/DebrisModule` |
| 62 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/DebrisModule` |
| 62 | `ModuleScript` | `03_Genos/Blitz Shot/Script/DebrisModule` |
| 62 | `ModuleScript` | `03_Genos/Ignition Burst/Script/DebrisModule` |
| 62 | `ModuleScript` | `03_Genos/Jet Dive/Script/DebrisModule` |
| 62 | `ModuleScript` | `03_Genos/M1/Script/DebrisModule` |
| 62 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/DebrisModule` |
| 62 | `ModuleScript` | `07_Comum/Dash/Script/DebrisModule` |
| 52 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Assets/crush/Modules/RockModule2` |
| 52 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Assets/crush/Modules/RockModule2` |
| 58 | `LocalScript` | `01_Saitama/Death Counter/mainscript/localcutscene` |
| 52 | `ModuleScript` | `02_Garou/Flowing Water/Script/RockModule2` |
| 52 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/RockModule2` |
| 52 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/RockModule2` |
| 52 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/RocksModule2` |
| 52 | `ModuleScript` | `02_Garou/The Final Hunt/Script/RockModule2` |
| 52 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/RockModule2` |
| 52 | `ModuleScript` | `03_Genos/Blitz Shot/Script/RockModule2` |
| 52 | `ModuleScript` | `03_Genos/Ignition Burst/Script/RockModule2` |
| 52 | `ModuleScript` | `03_Genos/Jet Dive/Script/RockModule2` |
| 52 | `ModuleScript` | `03_Genos/M1/Script/RockModule2` |
| 52 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/RockModule2` |
| 52 | `ModuleScript` | `07_Comum/Dash/Script/RockModule2` |
| 58 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Assets/crush/Modules/DebrisModule` |
| 58 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Assets/crush/Modules/DebrisModule` |
| 78 | `ModuleScript` | `05_Killua/Godspeed Rush/Func/Lightning` |
| 78 | `ModuleScript` | `05_Killua/Lightning Palm/Func/Lightning` |
| 78 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Lightning` |
| 78 | `ModuleScript` | `05_Killua/Thunderbolt/Func/Lightning` |
| 61 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/rocks/mainscript` |
| 54 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/CamPos/Camera` |
| 58 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/rocks/mainscript/debris/DebrisModule` |
| 44 | `Script` | `01_Saitama/Normal Punch/mainscript/rocks/mainscript` |
| 54 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/rocks/Modules/DebrisModule` |
| 54 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/Modules/DebrisModule` |
| 54 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/Modules/DebrisModule` |
| 54 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/rocks/Modules/DebrisModule` |
| 54 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Assets/rocks/Modules/DebrisModule` |
| 31 | `LocalScript` | `06_JoJo/7 Page Muda/Script/CamPos/Camera` |
| 29 | `Script` | `02_Garou/Hunter's Cruelty/Script/Assets/crush/mainscript` |
| 29 | `Script` | `02_Garou/Hunter's Grasp/Script/Assets/crush/mainscript` |
| 42 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Cutscene` |
| 42 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Cutscene` |
| 54 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Text/LocalScript` |
| 35 | `LocalScript` | `06_JoJo/And now, you're going to have to disappear./Script/LocalViewPort` |
| 39 | `LocalScript` | `03_Genos/M1/LocalScript` |
| 16 | `LocalScript` | `02_Garou/Flowing Water/Script/Assets/Shaker` |
| 16 | `LocalScript` | `02_Garou/Hunter's Cruelty/Script/Assets/Shaker` |
| 16 | `LocalScript` | `02_Garou/Hunter's Grasp/Script/Assets/Shaker` |
| 16 | `LocalScript` | `02_Garou/Lethal Whirlwind Stream/Script/Assets/Shaker` |
| 16 | `LocalScript` | `02_Garou/The Final Hunt/Script/Assets/Shaker` |
| 16 | `LocalScript` | `02_Garou/Water Stream Rock Smashing/Script/Assets/Shaker` |
| 16 | `LocalScript` | `03_Genos/Blitz Shot/Script/Assets/Shaker` |
| 16 | `LocalScript` | `03_Genos/Ignition Burst/Script/Assets/Shaker` |
| 16 | `LocalScript` | `03_Genos/Jet Dive/Script/Assets/Shaker` |
| 16 | `LocalScript` | `03_Genos/M1/Script/Assets/Shaker` |
| 16 | `LocalScript` | `03_Genos/Machine Gun Blows/Script/Assets/Shaker` |
| 16 | `LocalScript` | `07_Comum/Dash/Script/Assets/Shaker` |
| 23 | `Script` | `05_Killua/Godspeed Rush/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Instant Death/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Lightning Palm/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Mutilate/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Raging Sokudo/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Raging Sokudo/Func/Animation2/Anim` |
| 23 | `Script` | `05_Killua/The Snake Awakens/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Thunderbolt/Func/Animation/Anim` |
| 23 | `Script` | `05_Killua/Thunderbolt/Func/Animation2/Anim` |
| 23 | `Script` | `06_JoJo/And now, you're going to have to disappear./Script/Animation/Attack` |
| 23 | `Script` | `06_JoJo/I cannot attack ____./Script/Animation/Attack` |
| 23 | `Script` | `06_JoJo/I cannot attack ____./Script/Animation/Pen` |
| 23 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Animation/Attack` |
| 23 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Idle` |
| 23 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Kick` |
| 23 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Barrage` |
| 23 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Finisher` |
| 23 | `Script` | `06_JoJo/What's it feel like when time stands still?/Script/Animation/Attack` |
| 27 | `LocalScript` | `05_Killua/Godspeed Rush/Func/LocalViewPort` |
| 27 | `LocalScript` | `01_Saitama/Death Counter/mainscript/LocalViewPort` |
| 27 | `LocalScript` | `05_Killua/Instant Death/Func/LocalViewPort` |
| 27 | `LocalScript` | `05_Killua/Mutilate/Func/LocalViewPort` |
| 27 | `LocalScript` | `05_Killua/Raging Sokudo/Func/LocalViewPort` |
| 19 | `LocalScript` | `03_Genos/Jet Dive/LocalScript` |
| 6 | `Script` | `01_Saitama/Normal Punch/mainscript/ring/mainscript` |
| 19 | `LocalScript` | `03_Genos/Blitz Shot/LocalScript` |
| 19 | `LocalScript` | `03_Genos/Ignition Burst/LocalScript` |
| 19 | `LocalScript` | `03_Genos/Machine Gun Blows/LocalScript` |
| 24 | `LocalScript` | `01_Saitama/Table Flip/mainscript/Effects` |
| 19 | `Script` | `03_Genos/Ignition Burst/Script/Assets/rocks/mainscript` |
| 14 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Shake3` |
| 14 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Shake3` |
| 14 | `LocalScript` | `01_Saitama/Table Flip/mainscript/Shake3` |
| 16 | `Script` | `01_Saitama/Serious Punch/mainscript/Animation2/cam` |
| 16 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation2/cam` |
| 16 | `Script` | `01_Saitama/Consecutive Normal Punches/mainscript/Animation/barrage` |
| 16 | `Script` | `01_Saitama/Death Counter/mainscript/Animation/paunch` |
| 16 | `Script` | `01_Saitama/Normal Punch/mainscript/Animation/paunch` |
| 16 | `Script` | `01_Saitama/Normal Shove/mainscript/Animation/shove` |
| 16 | `Script` | `01_Saitama/Normal Uppercut/mainscript/Animation/upper` |
| 16 | `Script` | `01_Saitama/Serious Mode/mainscript/Animation/angry` |
| 16 | `Script` | `01_Saitama/Serious Punch/mainscript/Animation/flip` |
| 16 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation/flip` |
| 16 | `Script` | `01_Saitama/Table Flip/mainscript/Animation/flip` |
| 16 | `Script` | `02_Garou/Flowing Water/Script/Animation/water` |
| 16 | `Script` | `02_Garou/Flowing Water/Script/Animation/flowing` |
| 16 | `Script` | `02_Garou/Hunter's Cruelty/Script/Animation/smash` |
| 16 | `Script` | `02_Garou/Hunter's Cruelty/Script/Animation/cruel` |
| 16 | `Script` | `02_Garou/Hunter's Grasp/Script/Animation/grasp` |
| 16 | `Script` | `02_Garou/Hunter's Grasp/Script/Animation/cruel` |
| 16 | `Script` | `02_Garou/Hunter's Grasp/Script/Animation/smash` |
| 16 | `Script` | `02_Garou/Lethal Whirlwind Stream/Script/Animation/stream` |
| 16 | `Script` | `02_Garou/Lethal Whirlwind Stream/Script/Animation/lethal` |
| 16 | `Script` | `02_Garou/Rampage/Script/Animation/smash` |
| 16 | `Script` | `02_Garou/The Final Hunt/Script/Animation/final2` |
| 16 | `Script` | `02_Garou/The Final Hunt/Script/Animation/final1` |
| 16 | `Script` | `02_Garou/Water Stream Rock Smashing/Script/Animation/barrage` |
| 16 | `Script` | `03_Genos/Blitz Shot/Script/Animation/barrage` |
| 16 | `Script` | `03_Genos/Ignition Burst/Script/Animation/barrage` |
| 16 | `Script` | `03_Genos/Ignition Burst/Script/Animation/ignition` |
| 16 | `Script` | `03_Genos/Jet Dive/Script/Animation/land` |
| 16 | `Script` | `03_Genos/Jet Dive/Script/Animation/barrage` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/2` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/1` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/3` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/4` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/slam` |
| 16 | `Script` | `03_Genos/M1/Script/Animation/uppercut` |
| 16 | `Script` | `03_Genos/Machine Gun Blows/Script/Animation/barrage` |
| 16 | `Script` | `04_Gojo/Purple/Script/Animation/paunch` |
| 16 | `Script` | `04_Gojo/Red/Script/Animation/paunch` |
| 16 | `Script` | `07_Comum/Dash/Script/Animation/water` |
| 16 | `Script` | `07_Comum/Dash/Script/Animation/flowing` |
| 14 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Viewport/LocalScript` |
| 10 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Viewport/LocalScript/R1` |
| 14 | `LocalScript` | `01_Saitama/Table Flip/mainscript/rocks/mainscript/debris` |
| 9 | `LocalScript` | `06_JoJo/7 Page Muda/Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/I cannot attack ____./Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/What's it feel like when time stands still?/Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/Shake2` |
| 9 | `LocalScript` | `06_JoJo/And now, you're going to have to disappear./Script/Shake2` |
| 11 | `Script` | `05_Killua/Instant Death/Func/HeartWeld/script` |
| 8 | `Script` | `05_Killua/Instant Death/Func/Dash/script` |
| 8 | `Script` | `05_Killua/Raging Sokudo/Func/Dash/script` |
| 9 | `LocalScript` | `01_Saitama/Death Counter/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Normal Punch/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Normal Shove/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Normal Uppercut/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Serious Mode/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Shake2` |
| 9 | `LocalScript` | `01_Saitama/Table Flip/mainscript/Shake2` |
| 11 | `LocalScript` | `04_Gojo/Red/Script/Effects2` |
| 9 | `LocalScript` | `04_Gojo/Red/Script/Shake2` |
| 17 | `LocalScript` | `01_Saitama/Serious Punch/mainscript/Effects` |
| 17 | `LocalScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Effects` |
| 18 | `LocalScript` | `02_Garou/Flowing Water/Script/Assets/Afterimage` |
| 9 | `LocalScript` | `04_Gojo/Purple/Script/Shake2` |
| 9 | `LocalScript` | `02_Garou/Rampage/Script/Shake2` |
| 9 | `LocalScript` | `04_Gojo/Purple/Script/Shake3` |
| 16 | `Script` | `01_Saitama/Consecutive Normal Punches/mainscript/SplatTemplate/Despawn` |
| 16 | `Script` | `01_Saitama/Normal Shove/mainscript/SplatTemplate/Despawn` |
| 18 | `LocalScript` | `01_Saitama/Table Flip/mainscript/Camera` |
| 18 | `LocalScript` | `02_Garou/Rampage/Script/Camera` |
| 10 | `Script` | `03_Genos/Jet Dive/Script/Assets/boom/mainscript` |
| 7 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Stand/Head/Script` |
| 10 | `LocalScript` | `05_Killua/Godspeed Rush/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Instant Death/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Lightning Palm/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Mutilate/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Raging Sokudo/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Raging Sokudo/Func/Animation2/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/The Snake Awakens/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Thunderbolt/Func/Animation/Anim/FPS` |
| 10 | `LocalScript` | `05_Killua/Thunderbolt/Func/Animation2/Anim/FPS` |
| 10 | `LocalScript` | `06_JoJo/And now, you're going to have to disappear./Script/Animation/Attack/FPS` |
| 10 | `LocalScript` | `06_JoJo/I cannot attack ____./Script/Animation/Attack/FPS` |
| 10 | `LocalScript` | `06_JoJo/I cannot attack ____./Script/Animation/Pen/FPS` |
| 10 | `LocalScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Animation/Attack/FPS` |
| 10 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Idle/FPS` |
| 10 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Kick/FPS` |
| 10 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Barrage/FPS` |
| 10 | `LocalScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation/Finisher/FPS` |
| 10 | `LocalScript` | `06_JoJo/What's it feel like when time stands still?/Script/Animation/Attack/FPS` |
| 7 | `LocalScript` | `05_Killua/Thunderbolt/LocalFunc` |
| 9 | `LocalScript` | `04_Gojo/Red/Script/Effects` |
| 9 | `LocalScript` | `04_Gojo/Purple/Script/Effects` |
| 2 | `Script` | `06_JoJo/7 Page Muda/Script/Wave/script` |
| 2 | `Script` | `06_JoJo/I cannot attack ____./Script/Wave/script` |
| 2 | `Script` | `06_JoJo/I cannot attack ____./Script/Smash/script` |
| 2 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Wave/script` |
| 2 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Smash/script` |
| 2 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Wave/script` |
| 2 | `Script` | `06_JoJo/What's it feel like when time stands still?/Script/Wave/script` |
| 2 | `Script` | `06_JoJo/What's it feel like when time stands still?/Script/Smash/script` |
| 2 | `Script` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/Wave/script` |
| 2 | `Script` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/Smash/script` |
| 7 | `LocalScript` | `01_Saitama/Death Counter/mainlocalscript` |
| 2 | `Script` | `03_Genos/M1/Script/Assets/ring/mainscript` |
| 2 | `Script` | `01_Saitama/Normal Shove/mainscript/ring/mainscript` |
| 2 | `Script` | `07_Comum/Dash/Script/Assets/ring/mainscript` |
| 7 | `ModuleScript` | `03_Genos/M1/Script/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Consecutive Normal Punches/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Death Counter/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Normal Punch/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Normal Shove/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Normal Uppercut/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Serious Mode/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Serious Punch/mainscript/Animation2` |
| 5 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation` |
| 5 | `ModuleScript` | `01_Saitama/Serious Punch (OLD)/mainscript/Animation2` |
| 5 | `ModuleScript` | `01_Saitama/Table Flip/mainscript/Animation` |
| 5 | `ModuleScript` | `02_Garou/Flowing Water/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/Hunter's Cruelty/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/Hunter's Grasp/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/Lethal Whirlwind Stream/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/Rampage/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/The Final Hunt/Script/Animation` |
| 5 | `ModuleScript` | `02_Garou/Water Stream Rock Smashing/Script/Animation` |
| 5 | `ModuleScript` | `03_Genos/Blitz Shot/Script/Animation` |
| 5 | `ModuleScript` | `03_Genos/Ignition Burst/Script/Animation` |
| 5 | `ModuleScript` | `03_Genos/Jet Dive/Script/Animation` |
| 5 | `ModuleScript` | `03_Genos/Machine Gun Blows/Script/Animation` |
| 5 | `ModuleScript` | `04_Gojo/Purple/Script/Animation` |
| 5 | `ModuleScript` | `04_Gojo/Red/Script/Animation` |
| 5 | `ModuleScript` | `06_JoJo/And now, you're going to have to disappear./Script/Animation` |
| 5 | `ModuleScript` | `06_JoJo/I cannot attack ____./Script/Animation` |
| 5 | `ModuleScript` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Animation` |
| 5 | `ModuleScript` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Animation` |
| 5 | `ModuleScript` | `06_JoJo/What's it feel like when time stands still?/Script/Animation` |
| 5 | `ModuleScript` | `07_Comum/Dash/Script/Animation` |
| 5 | `ModuleScript` | `05_Killua/Godspeed Rush/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Instant Death/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Lightning Palm/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Mutilate/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Raging Sokudo/Func/Animation2` |
| 5 | `ModuleScript` | `05_Killua/The Snake Awakens/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Thunderbolt/Func/Animation` |
| 5 | `ModuleScript` | `05_Killua/Thunderbolt/Func/Animation2` |
| 1 | `Script` | `05_Killua/Instant Death/Func/Indicator/script` |
| 3 | `Script` | `01_Saitama/Death Counter/mainscript/localcutscene/Script` |
| 3 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Text/LocalScript/R2` |
| 3 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Viewport/LocalScript/R2` |
| 3 | `Script` | `01_Saitama/Death Counter/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Normal Punch/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Normal Shove/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Normal Uppercut/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Mode/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Punch/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Punch/mainscript/Shake3/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Shake3/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Table Flip/mainscript/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Table Flip/mainscript/Shake3/RemovalRemote` |
| 3 | `Script` | `02_Garou/Rampage/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `04_Gojo/Purple/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `04_Gojo/Purple/Script/Shake3/RemovalRemote` |
| 3 | `Script` | `04_Gojo/Red/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/7 Page Muda/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/7 Page Muda/Script/CamPos/Camera/R2` |
| 3 | `Script` | `06_JoJo/And now, you're going to have to disappear./Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/I cannot attack ____./Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/If I heal you first, then it's not cheating is it?/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/Sunlight Yellow Overdrive!/Script/CamPos/Camera/R2` |
| 3 | `Script` | `06_JoJo/What's it feel like when time stands still?/Script/Shake2/RemovalRemote` |
| 3 | `Script` | `06_JoJo/You're going to fail, no matter what, when you're a piece of ____./Script/Shake2/RemovalRemote` |
| 3 | `Script` | `01_Saitama/Serious Punch/mainscript/Effects/RemoteEvent/Script` |
| 3 | `Script` | `01_Saitama/Serious Punch/mainscript/Cutscene/RemoteEvent/Script` |
| 3 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Effects/RemoteEvent/Script` |
| 3 | `Script` | `01_Saitama/Serious Punch (OLD)/mainscript/Cutscene/RemoteEvent/Script` |
| 3 | `Script` | `01_Saitama/Table Flip/mainscript/Effects/RemoteEvent/Script` |
| 3 | `Script` | `04_Gojo/Purple/Script/Effects/RemoteEvent/Script` |
| 3 | `Script` | `04_Gojo/Red/Script/Effects/RemoteEvent/Script` |
| 3 | `Script` | `04_Gojo/Red/Script/Effects2/RemoteEvent/Script` |

