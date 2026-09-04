# CATÁLOGO — `Vfx pack` do His Cube
**Status: CRU.** Nada daqui entra em Tool antes do passe de estrutura da `FICHA.md`.

Levantado de `MODELOS_ENTRADA/His_Cube_V2/his_cube.rbxmx`, pasta `Vfx pack`.
Total: **281 `ParticleEmitter`, 21 `Beam`, 1 `Trail`, 45 `Decal`, 239 `Part`.**

---

## `Anime`

36 efeitos nomeados. É o grupo mais aproveitável: cada `Part` é um efeito fechado com os emissores presos a um `Attachment`.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Charge-01` | `Energy1`, `Energy2`, `Core1` | **3 de 3** |
| `Blood-02` | `Blood1` | **1 de 1** |
| `Blood-01` | `Blood1` | **1 de 1** |
| `Smoke-01` | `Smoke1` | **1 de 1** |
| `Slashes-01` | `Slashes1`, `Wind1`, `SlashesCrack` | **3 de 3** |
| `Blood-Punch-01` | `Blood1`, `Blood2` | **2 de 2** |
| `Shiny-01` | `Core1`, `Lines1` | **2 de 2** |
| `Lighting-02` | `Lighting1` | **1 de 1** |
| `Lighting-01` | `Lighting1` | **1 de 1** |
| `ForceField-Break-01` | `Break2`, `Break3`, `Break1`, `Break4` | **4 de 4** |
| `ForceField-01` | `ForceField1`, `ForceField3` | **2 de 2** |
| `Water-01` | `Water1` | **1 de 1** |
| `Water-02` | `Water1`, `Water2` | **2 de 2** |
| `Slash-01` | `Slash1` | **1 de 1** |
| `Fire-03` | `Fire1` | **1 de 1** |
| `Fire-02` | `Fire1` | **1 de 1** |
| `Fire-01` | `Fire1`, `FireSpecs1` | **2 de 2** |
| `Wind-01` | `Wind2`, `Wind1` | **2 de 2** |
| `Fire-Slash-01` | `SlashFireSpecs1`, `SlashFire1` | **2 de 2** |
| `Crack-01` | `Floor2`, `Floor1` | **2 de 2** |
| `Shoot-01` | `Shockwave1` | **1 de 1** |
| `Wind-02` | `Smoke2`, `Wind1`, `Smoke1` | **3 de 3** |
| `Punch-01` | `Hit1` | **1 de 1** |
| `Punch-02` | `Hit1` | **1 de 1** |
| `Punch-03` | `Hit1` | **1 de 1** |
| `Lighting-03` | `Lighting4`, `Lighting3`, `Lighting2`, `Lighting1` | **4 de 4** |
| `Smoke-01` | `Smoke1` | **1 de 1** |
| `Slash-Impact-01` | `SlashImpact1`, `Specs1`, `Specs2` | **3 de 3** |
| `Portal-01` | `PortalOutline`, `Portal`, `PortalSuck` | **3 de 3** |
| `Portal-Enter-01` | `PortalOutline`, `Portal`, `PortalSuck`, `PortalLines`, `PortalOutline` | **5 de 5** |
| `Stars-01` | `Stars`, `Light` | **2 de 2** |
| `Splash-01` | `ParticleEmitter`, `ParticleEmitter` | **2 de 2** |
| `Realistic-Explosion-01` | `ParticleEmitter`, `ParticleEmitter` | **2 de 2** |
| `Flamethrower-01` | `ParticleEmitter`, `ParticleEmitter` | **2 de 2** |
| `Shield-01` | `ParticleEmitter`, `ParticleEmitter` | **2 de 2** |
| `Shield-Break-01` | `Specs`, `Shockwave`, `Specs` | **3 de 3** |

## `Big`

5 efeitos de escala grande. Conferir `Rate` antes de usar dentro de Tool.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Explosion-01` | `Fire2`, `Fire1`, `SmokeDark1`, `Specks1`, `Fire3` | **5 de 5** |
| `Tornado-01` | `Windspin1`, `Impact1`, `Windspin5`, `Impact2`, `Windspin4`, `Windspin2`, `Windspin3` | **7 de 7** |
| `Ball-01` | `Fire1`, `Ash1`, `Circle`, `FireSpecs1` | **4 de 4** |
| `Lighting-01` | `Impact1`, `Impact2`, `Impact3`, `Lighting1`, `Lightning` | **5 de 5** |
| `Big-Crack-01` | `Impact1`, `Impact2`, `Ash1`, `Fire1` | **4 de 4** |

## `Beams`

Feixe contínuo (`Beam` + emissor). Serve para canalização e laser.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Waterfall-01` | `Beam`, `Beam`, `Beam`, `Beam`, `Clouds`, `Clouds`, `Clouds`, `Clouds` | **8 de 8** |
| `Wind-01` | `Wind1`, `Smoke1`, `Beam`, `Beam`, `Smoke1`, `Wind1` | **6 de 6** |
| `Lava-01` | `FireSpecs1`, `Fire1`, `Beam`, `Fire1`, `Beam`, `FireSpecs1`, `Beam` | **7 de 7** |

## `Heads`

Expressão facial via `Decal` + emissor. **Fora do escopo deste repositório** — mexe no personagem, não na Tool.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Glowing-Eyes-01` | `RedGlow1`, `RedGlow1` | **2 de 2** |
| `Angry-01` | `Angry` | **1 de 1** |
| `Surprised-01` | `Surprised` | **1 de 1** |
| `Surprised-02` | `Surprised` | **1 de 1** |
| `Confused-01` | `Confused` | **1 de 1** |
| `Flamming-Eyes-01` | `RedGlow1`, `RedGlow1` | **2 de 2** |

## `Auras`

**Vem com dummy R6 inteiro** (`Humanoid`, `Motor6D`, `HumanoidDescription`). Só os emissores aproveitam; o rig não entra em Tool.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Fire-Aura-01` | `H`, `T`, `LA`, `RA`, `LL`, `RL` | **6 de 6** |
| `Water-Aura-01` | `H`, `T`, `LA`, `RA`, `LL`, `RL` | **6 de 6** |
| `RNG-Aura-01` | `Floor1`, `Floor2`, `Floor3`, `Beam`, `Beam`, `Beam`, `Beam`, `Beam`, `Beam` | **9 de 9** |
| `RNG-Aura-02` | `Star`, `Beam`, `Beam`, `Circle`, `Collide`, `Stars`, `Star`, `Beam`, `Beam`, `Circle` | **10 de 10** |
| `RNG-Aura-03` | `idk`, `Beam`, `idk`, `Beam`, `idk`, `idk` | **6 de 6** |

## `vfx pack`

Peças soltas do pack de origem.

| Efeito | Emissores | Ligado de fábrica |
|---|---|---|
| `Explosion` | `2`, `3`, `4`, `5`, `7`, `Shards`, `Shards`, `Shockwave`, `Spark`, `Spark`, `Specs`, `Specs`, `SpecsDark`, `SpecsDark`, `SpecsDark`, `Star`, `Wind`, `Wind`, `Wind1`, `blue star 1` | **20 de 20** |
| `Part` | `Line2`, `Line1`, `star` | **3 de 3** |
| `Projectile` | `Smoke`, `Smoke`, `Spark`, `Spark`, `Trail` | **5 de 5** |
| `f` | `ParticleEmitter`, `ParticleEmitter`, `ParticleEmitter`, `ParticleEmitter`, `ParticleEmitter`, `ParticleEmitter`, `BLACKSHARDS`, `rocks(14`, `impact2`, `impact`, `ground1`, `glow(1)`, `flash(1`, `crescents`, `crescentblack(4`, `brightershards`, `ParticleEmitter`, `ParticleEmitter` | **18 de 18** |

---

## As 34 texturas

Cada uma vive numa `Part` solta com um `Decal`. **É o que mais vale do pack:** dá para
escrever `ParticleEmitter` autoral usando estas texturas sem copiar emissor de ninguém.

| Nome no pack | `rbxassetid` |
|---|---|
| `Part` | `rbxassetid://16501328414` |
| `pentagon` | `rbxassetid://8099267640` |
| `smoke flipbook` | `rbxassetid://11446801985` |
| `octagon` | `rbxassetid://8095997435` |
| `spinny` | `rbxassetid://1084969997` |
| `smoke/fog` | `rbxassetid://5872447086` |
| `smoke flipbook 2` | `rbxassetid://10034873151` |
| `stravant's lightning` | `rbxassetid://10713705343` |
| `lighting flipbook` | `rbxassetid://11515478646` |
| `light ray` | `rbxassetid://1053548563` |
| `fire flipbook` | `rbxassetid://11509655546` |
| `offcenter circle` | `rbxassetid://9918912100` |
| `flare` | `rbxassetid://14684195806` |
| `circle thing` | `rbxassetid://10847253852` |
| `lightning explosion flipbook` | `rbxassetid://12390096354` |
| `lightning ring` | `rbxassetid://7150933366` |
| `light rays` | `rbxassetid://1084975295` |
| `light ring` | `rbxassetid://8271495905` |
| `fire flipbook 2` | `rbxassetid://11534281007` |
| `fire flipbook 3` | `rbxassetid://12996605668` |
| `star thing` | `rbxassetid://1084970835` |
| `cresent` | `rbxassetid://8096189152` |
| `cresent 2` | `rbxassetid://8084911316` |
| `lightning ring 2` | `rbxassetid://7150932717` |
| `lightning ring 3` | `rbxassetid://6900421398` |
| `glow` | `rbxassetid://4509687978` |
| `glow 2` | `rbxassetid://6673021984` |
| `burst` | `rbxassetid://6490035152` |
| `thing` | `rbxassetid://8133845150` |
| `spinny thing` | `rbxassetid://917189380` |
| `vortex` | `rbxassetid://6700005265` |
| `tiny light ray` | `rbxassetid://7886908733` |
| `burst 2` | `rbxassetid://9573351641` |
| `thing` | `rbxassetid://346519018` |

---

## Emissores em `Part` solta (95)

| `Part` | Emissor | Textura |
|---|---|---|
| `Part` | `Flash` | `rbxassetid://11372606236` |
| `Part` | `Flash` | `rbxassetid://11372606236` |
| `Part` | `Flash` | `rbxassetid://11372587580` |
| `Part` | `Black` | `rbxassetid://14457094589` |
| `Part` | `Last Particle` | `rbxassetid://14494884246` |
| `Part` | `Lightning One` | `rbxassetid://14582813693` |
| `Part` | `Aura` | `rbxassetid://14447188478` |
| `Part` | `Yars` | `rbxassetid://14315288248` |
| `Part` | `ParticleEmitter2` | `rbxassetid://7216847765` |
| `Part` | `ParticleEmitter1` | `rbxassetid://7216847765` |
| `Part` | `Charged` | `http://www.roblox.com/asset/?id=249902641` |
| `Part` | `Spark` | `rbxassetid://7216979807` |
| `Part` | `Circle` | `rbxassetid://14425843511` |
| `Part` | `Wave` | `rbxassetid://1084996536` |
| `Part` | `Bits` | `rbxassetid://1084996976` |
| `Part` | `Wave` | `rbxassetid://1084965356` |
| `Part` | `Bits_Small` | `rbxassetid://1084997326` |
| `Part` | `Black Swirl` | `rbxassetid://14477910720` |
| `Part` | `Purple Expanding` | `rbxassetid://14435065552` |
| `Part` | `Flare` | `rbxassetid://867619398` |
| `Part` | `Sparkle` | `rbxassetid://1053546634` |
| `Part` | `Wave` | `rbxassetid://1084952073` |
| `Part` | `Wave` | `rbxassetid://1084952073` |
| `Part` | `Sparkles` | `rbxassetid://1053546634` |
| `Part` | `Flare` | `rbxassetid://867619398` |
| `Part` | `Sparkles_Beam` | `rbxassetid://1084970835` |
| `Part` | `Sparkles` | `rbxassetid://1084970835` |
| `Part` | `Core` | `http://www.roblox.com/asset/?id=243664672` |
| `Part` | `Shockwave` | `rbxassetid://14412529554` |
| `Part` | `MiniSparks` | `http://www.roblox.com/asset/?id=7587238412` |
| `Part` | `Swirling` | `rbxassetid://14426307916` |
| `Part` | `Twirl` | `rbxassetid://14426232568` |
| `Part` | `ParticleEmitter` | `rbxassetid://14066311352` |
| `Part` | `ParticleEmitter` | `rbxassetid://14442131728` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011456461` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011478368` |
| `Part` | `ParticleEmitter` | `rbxassetid://11941047152` |
| `Part` | `ParticleEmitter` | `rbxassetid://11447021694` |
| `Part` | `ParticleEmitter` | `rbxassetid://12830011666` |
| `Part` | `ParticleEmitter` | `rbxassetid://12779603482` |
| `Part` | `ParticleEmitter` | `rbxassetid://14393243408` |
| `Part` | `ParticleEmitter` | `rbxassetid://12865691168` |
| `Part` | `ParticleEmitter` | `rbxassetid://12865656309` |
| `Part` | `ParticleEmitter` | `rbxassetid://13455668887` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011454473` |
| `Part` | `ParticleEmitter` | `rbxassetid://12906276200` |
| `Part` | `ParticleEmitter` | `rbxassetid://14842257638` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011441052` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011447462` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011474319` |
| `Part` | `ParticleEmitter` | `rbxassetid://12602224662` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011471927` |
| `Part` | `ParticleEmitter` | `rbxassetid://14354336687` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011468690` |
| `Part` | `ParticleEmitter` | `rbxassetid://12930785601` |
| `Part` | `ParticleEmitter` | `rbxassetid://11517935503` |
| `Part` | `ParticleEmitter` | `rbxassetid://14200879082` |
| `Part` | `ParticleEmitter` | `rbxassetid://13980004222` |
| `Part` | `ParticleEmitter` | `rbxassetid://12683695494` |
| `Part` | `ParticleEmitter` | `rbxassetid://12123878312` |
| `Part` | `ParticleEmitter` | `rbxassetid://11794599322` |
| `Part` | `ParticleEmitter` | `rbxassetid://11917388916` |
| `Part` | `ParticleEmitter` | `rbxassetid://11749129449` |
| `Part` | `ParticleEmitter` | `rbxassetid://14550142746` |
| `Part` | `ParticleEmitter` | `rbxassetid://11895782540` |
| `Part` | `ParticleEmitter` | `rbxassetid://11846336638` |
| `Part` | `ParticleEmitter` | `rbxassetid://12780365055` |
| `Part` | `ParticleEmitter` | `rbxassetid://11844017484` |
| `Part` | `ParticleEmitter` | `rbxassetid://15011464541` |
| `Part` | `ParticleEmitter` | `rbxassetid://14483718869` |
| `Part` | `ParticleEmitter` | `rbxassetid://14480839965` |
| `Part` | `ParticleEmitter` | `rbxassetid://14471362207` |
| `Part` | `ParticleEmitter` | `rbxassetid://14394427356` |
| `Part` | `ParticleEmitter` | `rbxassetid://11515478646` |
| `Part` | `ParticleEmitter` | `rbxassetid://14496415643` |
| `Part` | `ParticleEmitter` | `rbxassetid://12169768457` |
| `Part` | `ParticleEmitter` | `rbxassetid://14431663347` |
| `Part` | `ParticleEmitter` | `rbxassetid://11861733639` |
| `Part` | `ParticleEmitter` | `rbxassetid://11862032588` |
| `Part` | `ParticleEmitter` | `rbxassetid://12878027420` |
| `Part` | `ParticleEmitter` | `rbxassetid://13669808632` |
| `Part` | `ParticleEmitter` | `rbxassetid://11389369395` |
| `Part` | `Rays` | `rbxassetid://1053548563` |
| `Part` | `Rays` | `rbxassetid://1084975295` |
| `Part` | `Flare` | `rbxassetid://867619398` |
| `Part` | `Circles` | `rbxassetid://1084982817` |
| `Part` | `ParticleEmitter` | `rbxassetid://13365068138` |
| `Part` | `ParticleEmitter` | `rbxassetid://13233046382` |
| `Part` | `ParticleEmitter` | `rbxassetid://13336761812` |
| `Part` | `ParticleEmitter` | `rbxassetid://14476165199` |
| `Part` | `ParticleEmitter` | `rbxassetid://13414392494` |
| `Part` | `Flash` | `rbxassetid://11372772717` |
| `Part` | `Dots 1` | `rbxassetid://14582794847` |
| `Part` | `Dots 2` | `rbxassetid://14582794847` |
| `Part` | `Sparkles` | `rbxassetid://1084970835` |
