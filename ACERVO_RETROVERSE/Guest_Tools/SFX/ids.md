# SFX — Guest Tools

**Status: LIMPO.** 20 `Sound` — os 16 da origem mais 4 que a conversão acrescentou. É a
primeira entrada de **som de porrada** do Acervo: até aqui o repertório era explosão, corte
e feixe. Nenhum foi ouvido; o passe é de estrutura, não de audição.

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
| | `OpenSound` | `7244308623` ✅ |

> ✅ **O `OpenSound` do Abacate chegou com `SoundId` em branco**, e o `Tool.Equipped` chamava
> `:Play()` nele. Consertado em `FERRAMENTAS/preparar_guest.py` com o `OpenSound` do
> `Energetico` — mesmo modelo, mesmo gesto. Era o mesmo tipo de bug mudo do
> `rbxassetid://200` das bombas.

## Provocação

| Tool | `Sound` | id | Observação |
|---|---|---|---|
| `Humilhador` | `Provoca` | `7995127481` | era criado no código; agora é instância dentro da Tool |

## Os que a conversão acrescentou

`A arma` chegou com **zero `Sound`** — revólver mudo não é entrega. Os três abaixo vêm do
`Xester_Forma1`, que é a única entrada de SFX deste repositório com a ficha fechada nos
quatro campos de §12.12.3. É o mesmo critério que o `preparar_collector.py` já usa.

| `Sound` | id | Papel no Xester | Papel aqui |
|---|---|---|---|
| `Tiro` | `1910988873` | o raio, a sentença descendo | o disparo |
| `Tambor` | `472214107` | tique do contador | o tambor girando |
| `Fecha` | `54111471` | fechamento | o tambor fechando |

> São **escolha por papel, não por audição**: não dá para ouvir os arquivos daqui. Quando
> entrar um som de tiro com ficha fechada, a troca é de uma linha em
> `FERRAMENTAS/preparar_guest.py`, dicionário `SONS_QUE_FALTAM`.

O truque do `PlayOnRemove` é legítimo e vale registrar: o `Sound` é criado, marcado, e
`:Destroy()` imediatamente — o Roblox toca no ato de remover, sem deixar instância pendurada.
É a resposta mais limpa ao problema que apareceu nas bombas (som morto porque o pai sumiu na
linha seguinte). **Mas `:Destroy()` é proibido aqui**, então o caminho deste repositório
continua sendo a âncora com `Debris:AddItem`.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste de ouvido. Ver `../FICHA.md`.
