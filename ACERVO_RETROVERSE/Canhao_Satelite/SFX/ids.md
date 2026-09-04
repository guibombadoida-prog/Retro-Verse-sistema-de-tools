# SFX — Canhão Satélite (`LowOrbitIonCannon`)

**Status: CRU.** 21 `Sound`, nenhum ouvido ainda.

## Na Tool (`Handle`)

| `Sound` | id | Volume |
|---|---|---|
| `Call` | `88858815` | 1 |
| `Equip` | `1616554` | 0.2 |
| `ClickAccept` | `1388726556` | 0.5 |
| `ClickDecline` | `550209561` | 0.5 |

Estes quatro são os **únicos com volume sensato**, e são de interface: equipar, aceitar,
recusar, chamar.

## No satélite (`LOIC/BaseSatellite`) — 17 sons, todos em `Volume = 10`

| `Sound` | id | Serve para |
|---|---|---|
| `Big Explosion` | `814635481` | impacto principal |
| `Electric Explosion` | `2674547670` | impacto elétrico |
| `Explosion SFX` | `1591825950` | impacto |
| `Explosion` | `165969964` | impacto |
| `Explosion` | `3313098116` | impacto |
| `Explosion 4` | `180199793` | impacto |
| `explosive` | `142070127` | impacto |
| `DBExplode` | `2691586` | impacto seco |
| `Gravity Hammer` | `1255794` | impacto pesado |
| `SFX: Gavel` | `131219241` | batida seca |
| `sfx_hit` | `145486953` | acerto |
| `sfx_swooshing` | `145486992` | passagem de ar |
| `SwordLunge` | `25256253` | estocada |
| `Berserk` | `2101137` | grito / estado |
| `Curse` | `13775494` | estado |
| `Defile` | `3264923` | estado |
| `SFX_Health` | `384105511` | cura / recuperação |

> ⚠️ **`Volume = 10` é o teto do Roblox.** Nenhum entra em Tool com esse valor. O padrão
> deste repositório é o volume de golpe entre 0.5 e 2, medido de ouvido no Studio.

## O que já cobre buraco conhecido

As 6 Tools de bomba e as 7 de escudo foram sonorizadas com o que havia. `Big Explosion`,
`DBExplode` e `Gravity Hammer` são candidatos diretos a substituir o que está lá — depois
de ouvidos, e com o volume refeito.

## Para sair de CRU

Falta autor, licença e o teste de ouvido. Ver `../FICHA.md`.
