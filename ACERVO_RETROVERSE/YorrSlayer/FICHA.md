# Modelo: YorrSlayer

- **Autor original:** _(preencher)_
- **Origem:** `Yorrslayer.rbxm`
- **Licença / permissão:** _(preencher)_
- **Data de entrada:** _(preencher)_
- **Status: CRU**   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** _(nenhuma ainda — o passe §12.12.2 não foi executado)_
- **Excluído do acervo:** _(preencher ao rodar o passe)_
- **Já usado em:** —

> ⚠️ **Sem os quatro campos acima — autor, origem, licença, data — este material
> fica CRU e NÃO pode entrar em Tool** (§12.12.3).

Tool de origem no modelo: `YorrSlayer`

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
