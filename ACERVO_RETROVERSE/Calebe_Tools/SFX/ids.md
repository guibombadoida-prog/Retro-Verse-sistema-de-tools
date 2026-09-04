# SFX — Calebe Tools

**Status: LIMPO.** 28 `Sound` em 5 Tools, mais **6 `ReverbSoundEffect`**. Nenhum ouvido.

É a maior entrada de SFX por Tool que já chegou, e o `detainer` sozinho tem 14 — mais que
qualquer Tool do repositório, que costuma ficar em três.

## `CosmosStaff` — 4 sons

| `Sound` | id | Volume |
|---|---|---|
| `EquipSound` | `http://www.roblox.com/asset/?id=10756118` | 0.5 |
| `ScifiLiftSound` | `http://www.roblox.com/asset/?id=48577295` | 0.5 |
| `ScifiBlastSound` | `http://www.roblox.com/asset/?id=48577326` | 0.5 |
| `Bam` | `rbxassetid://367453005` | 5 |

## `Gravitron 1000` — 3 sons

| `Sound` | id | Volume |
|---|---|---|
| `Shift` | `rbxassetid://5589942956` | 3 |
| `Beep` | `rbxassetid://9125673453` | 2 |
| `Press` | `rbxassetid://12221967` | 0.5 |

## `GravityHammer` — 4 sons

| `Sound` | id | Volume |
|---|---|---|
| `Hit` | `http://www.roblox.com/asset/?id=30172281` | 2 |
| `SendOut` | `http://www.roblox.com/asset/?id=30172373` | 2 |
| `InitialHit` | `http://www.roblox.com/asset/?id=30299564` | 2 |
| `Whack` | `rbxassetid://4735222231` | 2 |

## `Quake Hammer` — 3 sons

| `Sound` | id | Volume |
|---|---|---|
| `Press` | `rbxassetid://12221967` | 0.5 |
| `Hit` | `rbxassetid://6787514780` | 10 |
| `Swing` | `rbxassetid://7171591581` | 5 |

## `detainer` — 14 sons

| `Sound` | id | Volume |
|---|---|---|
| `ClawsOpen` | `rbxassetid://7449454666` | 0.5 |
| `Drop` | `rbxassetid://7449454513` | 0.5 |
| `DryFire` | `rbxassetid://7451090718` | 1 |
| `Holding` | `rbxassetid://7449423195` | 1 |
| `Launch1` | `rbxassetid://7449437048` | 0.5 |
| `Launch3` | `rbxassetid://7449436988` | 0.5 |
| `Launch4` | `rbxassetid://7449436902` | 0.5 |
| `Pickup` | `rbxassetid://7449454869` | 0.5 |
| `Pull` | `rbxassetid://7449454666` | 0.5 |
| `ClawsClose` | `rbxassetid://7449454594` | 0.5 |
| `unequip` | `rbxassetid://5683584454` | 1 |
| `equip` | `rbxassetid://5683584058` | 1 |
| `Launch2` | `rbxassetid://7449437191` | 0.5 |
| `sfx` | `rbxassetid://4588405910` | 0.75 |

---

## O que salta

**O `detainer` tem vocabulário completo de máquina:** `ClawsOpen` / `ClawsClose`, `Pickup` /
`Drop` / `Pull`, `Holding` (o zumbido de segurar), `DryFire` (o clique de tentar sem carga) e
`Launch1..4` — quatro variantes do mesmo arremesso.

Quatro variantes é exatamente o material para **alternar por índice sequencial**, que é o que
a regra manda usar no lugar de `math.random`. As Tools deste repositório costumam ter um só e
variar o pitch.

⚠️ **`Hit` do `Quake Hammer` está em `Volume = 10`** — o teto do Roblox. Mesmo caso dos 17 sons
do `Canhao_Satelite`. Não entra em Tool com esse valor.

✅ **Três ids tinham espaço no fim** (`...48577295 `, `...48577326 `), no `CosmosStaff`, e
**seis estavam no formato antigo** `http://www.roblox.com/asset/?id=`. Os dois foram
consertados em `FERRAMENTAS/preparar_gravidade.py`, função `normalizar_som`. Espaço em URL
não dá erro visível: o som simplesmente não toca.

Os 6 `ReverbSoundEffect` são o segundo `SoundEffect` a chegar ao Acervo, depois dos
`DistortionSoundEffect` do `Dano_Verdadeiro`. Nenhuma Tool do repositório usa efeito de áudio
ainda.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste de ouvido. Ver `../FICHA.md`.
