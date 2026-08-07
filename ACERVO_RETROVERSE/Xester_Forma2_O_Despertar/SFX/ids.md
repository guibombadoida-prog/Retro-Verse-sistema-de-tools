# Xester_Forma2_O_Despertar — SFX

**Status: CRU.** Volume e pitch são os do modelo original.

Ao montar a Tool, cada um vira um `Sound` **dentro** dela, em `Tool/SFX/`
(Regra nº 1). O script clona o molde; nunca cria `SoundId` solto.

| Nome | ID | Volume | Pitch | RollOff | Loop | Caminho |
|---|---|---|---|---|---|---|
| `Climbing` | (sem id) | 0.65 | 1 | 150 | true | `enemy/Head/Climbing` |
| `Died` | (sem id) | 0.65 | 1 | 150 | false | `enemy/Head/Died` |
| `FreeFalling` | (sem id) | 0 | 1 | 150 | true | `enemy/Head/FreeFalling` |
| `GettingUp` | (sem id) | 0.65 | 1 | 150 | false | `enemy/Head/GettingUp` |
| `Jumping` | (sem id) | 0.65 | 1 | 150 | false | `enemy/Head/Jumping` |
| `Landing` | (sem id) | 1 | 1 | 150 | false | `enemy/Head/Landing` |
| `Running` | (sem id) | 0.65 | 1.85 | 150 | true | `enemy/Head/Running` |
| `Splash` | (sem id) | 0.65 | 1 | 150 | false | `enemy/Head/Splash` |
| `Swimming` | (sem id) | 0.65 | 1.6 | 150 | true | `enemy/Head/Swimming` |

