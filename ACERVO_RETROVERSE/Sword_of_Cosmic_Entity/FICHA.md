# Modelo: Sword_of_Cosmic_Entity

- **Autor original:** **não declarado no arquivo** — free model de toolbox.
  ⚠️ Campo obrigatório de §12.12.3: **você precisa preencher** antes de usar em Tool.
- **Origem:** `fb47f12a-Sword_of.rbxm`
- **Licença / permissão:** **a confirmar** — presumido free model público, uso audiovisual.
  ⚠️ Campo obrigatório de §12.12.3.
- **Data de entrada:** 2026-07-31
- **Status: LIMPO**   (CRU | LIMPO | APROVADO)
  Passe §12.12.2 executado sobre os emissores que entraram em Tool.
  O resto do modelo segue CRU.
- **Violações corrigidas:** nos emissores aproveitados — `Enabled` na origem e o cliente
  liga por `Enabled` + `Rate` (zero `:Emit()`); cor trocada para a paleta do repositório.
  O restante do modelo **não** foi reescrito — ver `LOGICA/HABILIDADES.md`
- **Excluído do acervo:** a definir no passe. Já identificados como insalváveis:
  `Animation` (asset), `ColorCorrectionEffect`, `ScreenGui`, `Sky`
- **Já usado em:** conjunto Gravidade / Telecinese — `ESTILHACO_ESTELAR` (Estrelas + Cintilar), `BRASA` (Brasa + Fumaça), `FAISCA` (Faísca)

> ⚠️ **Sem os quatro campos acima — autor, origem, licença, data — este material
> fica CRU e NÃO pode entrar em Tool** (§12.12.3).

Tool de origem no modelo: `Sword of Cosmic Entity (Revamped)`

Conteúdo: **11 scripts · 33 VFX · 15 SFX · 16 malhas/texturas**

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
