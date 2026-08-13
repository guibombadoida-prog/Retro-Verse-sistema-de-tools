# SFX — Guest Tools

**Status: CRU.** 16 `Sound`, nenhum ouvido ainda. É a primeira entrada de **som de porrada**
do Acervo — até aqui o repertório era explosão, corte e feixe.

## Corpo a corpo

| Tool | `Sound` | id |
|---|---|---|
| `Taco de Baseball` | `Swoosh` | `3755636638` |
| | `Hit` | `175024455` |
| | `Hit2` | `3932505023` |
| | `Ouch` | `4306991691` |
| | `Ouch2` | `4459572527` |
| | `Equip` | `769464514` |
| `Cano De Rua` | `Swoosh` | `1489705211` |
| | `Swoosh2` | `181894961` |
| | `MetalHit` | `933780081` |
| | `MetalHit2` | `546410481` |
| | `Hit` | `743886825` |
| | `unequip` | `769464514` |

**Todo som de impacto tem par.** `Hit`/`Hit2`, `Ouch`/`Ouch2`, `Swoosh`/`Swoosh2`,
`MetalHit`/`MetalHit2`. É exatamente o material para alternar golpe por **índice
sequencial**, que é o que a regra manda usar no lugar de `math.random`.

`769464514` aparece nas duas Tools — no `Taco` como `Equip`, no `Cano` como `unequip`.

## Consumível

| Tool | `Sound` | id |
|---|---|---|
| `Energetico` | `DrinkSound` | `1489917733` |
| | `OpenSound` | `7244308623` |
| `Abacate (roubado) do mexico` | `DrinkSound` | `2834628644` |
| | `OpenSound` | **vazio** ⚠️ |

> ⚠️ **O `OpenSound` do Abacate está com `SoundId` em branco.** O `Tool.Equipped` chama
> `:Play()` nele e não sai som nenhum. Defeito de origem — mesmo tipo de bug mudo que já foi
> consertado nas 6 Tools de bomba.

## Provocação

| Tool | id | Observação |
|---|---|---|
| `Humilhador` | `7995127481` | criado no código, `Volume = 3`, com `PlayOnRemove = true` |

O truque do `PlayOnRemove` é legítimo e vale registrar: o `Sound` é criado, marcado, e
`:Destroy()` imediatamente — o Roblox toca no ato de remover, sem deixar instância pendurada.
É a resposta mais limpa ao problema que apareceu nas bombas (som morto porque o pai sumiu na
linha seguinte). **Mas `:Destroy()` é proibido aqui**, então o caminho deste repositório
continua sendo a âncora com `Debris:AddItem`.

## Para sair de CRU

Falta autor, licença e o teste de ouvido. Ver `../FICHA.md`.
