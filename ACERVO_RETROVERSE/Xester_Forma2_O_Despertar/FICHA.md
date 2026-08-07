# Modelo: Xester_Forma2_O_Despertar

- **Autor original:** não declarado no material
- **Origem:** `Xester_O_despertar.rbxmx`, enviado pelo autor do projeto em 2026-08-07
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

`MainModule.load(jogador)` clona o `Script` `xesterv2` para o `Backpack` do
jogador. O script substitui o personagem por um `char` próprio e monta a
entrada com um `RemoteEvent` `UserInput_Event` e uma tabela de eventos falsos.
É o mesmo padrão da Forma 1, uma geração depois.

**Marcadores procurados e NÃO encontrados nos dois arquivos:** `loadstring`,
`require(<id numérico>)`, `HttpService`, `getfenv`, `setfenv`,
`MarketplaceService`, `GetAsync`, `PostAsync`, webhook, Discord.

Os 0 casamentos de `https?://` são todos `http://www.roblox.com/asset/?id=`
de malha e textura.

**Conclusão:** não é backdoor. É um morph de personagem com movelist, empacotado do mesmo jeito
que a Forma 1.

Mesmo assim, **nenhum script da origem entrou nas Tools.** Toda a lógica foi
reescrita conforme as diretrizes; da origem vieram os números e os assets.
