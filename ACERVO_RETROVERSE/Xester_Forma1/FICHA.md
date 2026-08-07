# Modelo: Xester_Forma1

- **Autor original:** não declarado no material — o `Handler` traz `-- made by WRENCH#0104`, que é o autor do *wrapper* de FE, não necessariamente o do movelist. O cabeçalho do `un` diz que o script foi vazado (*"skidcentric leaked it"*)
- **Origem:** `Xester.rbxmx`, enviado pelo autor do projeto em 2026-08-07
- **Licença / permissão:** _(PENDENTE — ver nota abaixo)_
- **Data de entrada:** 2026-08-07
- **Status: CRU**   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** _(nenhuma ainda — o passe §12.12.2 não foi executado)_
- **Excluído do acervo:** _(preencher ao rodar o passe)_
- **Já usado em:** as 14 Tools do Xester (7 por forma)

> ⚠️ **LICENÇA PENDENTE.** Autor, origem e data estão preenchidos; a licença
> não, porque o material não a declara e eu não invento esse campo. Por
> §12.12.3 o status fica **CRU** até alguém preencher, e enquanto estiver CRU
> este material não deveria estar dentro de Tool.
>
> As Tools JÁ FORAM construídas a partir dele, a pedido. Isto está declarado
> aqui e no relatório de entrega em vez de ficar calado: quem preenche a
> licença é quem tem a permissão, não o conversor.

Tool de origem no modelo: `(sem Tool na raiz)`

---

## Conteúdo depositado

| Pasta | O que tem |
|---|---|
| `VFX/NOTAS.md` | Emissores com os parâmetros de verdade |
| `SFX/ids.md` | Sons com id, volume, pitch e rolloff |
| `MALHAS/ids.md` | `MeshId` e `TextureId` |
| `LOGICA/HABILIDADES.md` | Inventário do que os scripts faziam — **consulta, não reuso** |

## Como usar isto numa Tool nova

1. Ler o `VFX/NOTAS.md` e escolher o efeito.
2. Reescrever o efeito conforme (`_PADROES.md`): sem `math.random`, sem `wait`,
   sem `:Destroy()`, rodando **no cliente** por `VFXRemote`.
3. Copiar o `Sound` e o emitter **para dentro da Tool** (`SFX/` e `Efeitos/`).
4. Marcar o status na ficha: CRU → LIMPO → APROVADO.

---

## Triagem de segurança — feita antes de qualquer conversão

O formato deste material levanta suspeita legítima, então ele foi lido antes de
entrar em qualquer Tool. O resultado está aqui para ninguém precisar refazer a
leitura.

`MainModule.load(alvo)` clona um `Script` de 3477 linhas para dentro da
`PlayerGui` de um jogador **nomeado**, e um `replicator` faz proxy de
`UserInputService`, `SetCore`, `SetCoreGuiEnabled`, `CaptureFocus` e
`GetTextboxCode` por 24 Remotes. O `Handler` que fecha o circuito no cliente
está assinado `-- made by WRENCH#0104`.

**Marcadores procurados e NÃO encontrados nos dois arquivos:** `loadstring`,
`require(<id numérico>)`, `HttpService`, `getfenv`, `setfenv`,
`MarketplaceService`, `GetAsync`, `PostAsync`, webhook, Discord.

Os 8 casamentos de `https?://` são todos `http://www.roblox.com/asset/?id=`
de malha e textura.

**Conclusão:** não é backdoor. É o wrapper "FE bypass" da era pré-FilteringEnabled: um script de
free model antigo, empacotado para rodar num jogo com FilteringEnabled ligado.
O próprio autor deixou isso escrito no cabeçalho — *"This was made before FE so
using this may or may not lag the server"*.

Mesmo assim, **nenhum script da origem entrou nas Tools.** Toda a lógica foi
reescrita conforme as diretrizes; da origem vieram os números e os assets.
