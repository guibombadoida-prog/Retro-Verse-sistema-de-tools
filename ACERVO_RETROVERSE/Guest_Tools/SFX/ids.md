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

## Os que a conversão acrescentou — todos do PRÓPRIO Guest

`A arma` chegou com **zero `Sound`** — revólver mudo não é entrega.

> **Correção de rumo registrada.** A primeira versão puxou três ids do `Xester_Forma1`,
> pelo argumento de que era a única entrada de SFX com a ficha fechada nos quatro campos.
> Foi corrigido a pedido, e o pedido está certo: **o conjunto tem de soar como ele mesmo.**
> O modelo já traz 16 sons — não faltava vocabulário, faltava ligar o que existe.

| `Sound` | id | De onde vem, no próprio Guest | Papel aqui |
|---|---|---|---|
| `Tiro` | `546410481` | `MetalHit2` do `Cano De Rua` | o disparo — metal seco e curto |
| `Tambor` | `933780081` | `MetalHit` do `Cano De Rua` | o tambor girando |
| `Fecha` | `769464514` | `Equip` do `Taco` / `unequip` do `Cano` | o tambor fechando, o *clack* |

> Segue sendo **escolha por papel, não por audição** — não dá para ouvir os arquivos daqui.
> A diferença é que agora todo id do conjunto vem do conjunto. Trocar é uma linha em
> `FERRAMENTAS/preparar_guest.py`, dicionário `SONS_QUE_FALTAM`.

O truque do `PlayOnRemove` é legítimo e vale registrar: o `Sound` é criado, marcado, e
`:Destroy()` imediatamente — o Roblox toca no ato de remover, sem deixar instância pendurada.
É a resposta mais limpa ao problema que apareceu nas bombas (som morto porque o pai sumiu na
linha seguinte). **Mas `:Destroy()` é proibido aqui**, então o caminho deste repositório
continua sendo a âncora com `Debris:AddItem`.

## Para sair de LIMPO e virar APROVADO

Falta a **licença** e o teste de ouvido. Ver `../FICHA.md`.
