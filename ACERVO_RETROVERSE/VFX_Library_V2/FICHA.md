# Modelo: VFX_Library_V2

- **Autor original:** **não declarado no arquivo**. O conteúdo é de franquias de terceiros
  (One Punch Man, Jujutsu Kaisen, Hunter x Hunter, JoJo) — provável compilação de free models.
  ⚠️ Campo obrigatório de §12.12.3: **você precisa preencher**.
- **Origem:** `VFX_Library_V2_com_Logica.rbxmx` (10 MB, XML), enviado pelo autor do projeto.
  Cru guardado em `MODELOS_ENTRADA/VFX_Library_V2/`
- **Licença / permissão:** **a confirmar**. ⚠️ Ver a nota sobre franquias, abaixo.
- **Data de entrada:** 2026-07-31
- **Status: CRU**   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** nenhuma ainda. Inventariado e auditado, **não reescrito**
- **Excluído do acervo:** a definir no passe. Já identificados: 8 `ScreenGui`,
  13 `require(<id numérico>)`, 152 `BreakJoints`, 26 `LoadAnimation`
- **Já usado em:** —

> ⚠️ **Sem os quatro campos acima — autor, origem, licença, data — este material
> fica CRU e NÃO pode entrar em Tool** (§12.12.3).

Não há `Tool` no arquivo: é uma **biblioteca de efeitos**, organizada por personagem,
não uma ferramenta pronta.

## O que tem dentro — 38 habilidades em 7 pastas

| Pasta | Habilidades |
|---|---|
| `01_Saitama` | 9 |
| `02_Garou` | 7 |
| `03_Genos` | 5 |
| `04_Gojo` | 2 |
| `05_Killua` | 7 |
| `06_JoJo` | 7 |
| `07_Comum` | 1 (`Dash`) |

**782 `ParticleEmitter`** (416 únicos depois de deduplicar), 81 `Trail`, 14 `Beam`,
87 `MeshPart`, 5 `PointLight`. É, de longe, o maior acervo visual que entrou até aqui.

Índice de uso: [`CATALOGO_POR_HABILIDADE.md`](CATALOGO_POR_HABILIDADE.md) — diz qual
efeito mora em qual habilidade, que é como se procura na prática.

## ⚠️ Duas ressalvas antes de usar

**1. Franquias de terceiros.** Os nomes das pastas são personagens de obras licenciadas
(One Punch Man, Jujutsu Kaisen, Hunter x Hunter, JoJo). O material **visual** — curva de
partícula, textura, cor — é o que o Acervo aproveita, e isso é técnica, não personagem.
Mas nome de habilidade e identidade visual de obra licenciada são decisão sua, não minha.
Ao usar, renomeie para a nomenclatura do Retro-Verse.

**2. O código que vem junto é pesado em proibições.** O nome do arquivo diz
"com Lógica", e a lógica é justamente o que **não** entra em Tool (§12.12.1):

| Achado | Ocorrências |
|---|---|
| `math.random` | 1113 |
| `:Destroy()` | 911 |
| `wait()` | 344 |
| `tick()` | 181 |
| `:Emit(` | 177 |
| `BreakJoints` | 152 |
| `LoadAnimation` | 26 |
| `require(<id numérico>)` | 13 |
| `ScreenGui` | 8 instâncias |

Os 13 `require(<id numérico>)` são o achado sério: execução de código remoto, o mesmo
vetor. **Não rode este arquivo num place de produção sem antes
remover esses requires.**

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
