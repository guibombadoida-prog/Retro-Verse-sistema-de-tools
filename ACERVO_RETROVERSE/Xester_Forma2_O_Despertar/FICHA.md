# Modelo: Xester_Forma2_O_Despertar

- **Autor original:** não declarado no material
- **Origem:** `Xester_O_despertar.rbxmx`, enviado pelo autor do projeto em 2026-08-07
- **Licença / permissão:** material de terceiro obtido e enviado pelo autor do
  projeto para conversão; uso interno no Retro-Verse. A procedência que o próprio
  material declara está registrada na triagem, no fim desta ficha.
- **Data de entrada:** 2026-08-07
- **Status: LIMPO** — passe §12.12.2 executado   (CRU | LIMPO | APROVADO)
- **Violações corrigidas:** todo script da origem foi removido, não convertido —
  `MainModule`, `replicator`, `Handler`, `Weld`, `ai`, `core`, `skullscript`.
  A lógica das habilidades foi reescrita do zero conforme as diretrizes.
  Também saíram: `Animation`, `ScreenGui`/`BillboardGui`, e os Sound padrão de
  personagem (`rbxasset://sounds/...`) cujo script disparador foi removido.
- **Excluído do acervo:** os scripts acima. O que entrou nas Tools foi ASSET —
  cartas, cajado, machado, malhas, sons e as poses R6 extraídas do CFrame.
- **Já usado em:** as 14 Tools do Xester (7 por forma)

> Os quatro campos de §12.12.3 estão preenchidos. Nenhum script da origem
> entrou nas Tools — a lógica é reescrita, e da origem vem asset e número.

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


---

## Correção de 2026-08-14 — quatro coisas escritas e nunca chamadas

As 7 Tools desta forma passavam nos cinco verificadores e traziam quatro
defeitos da mesma família: **código entregue e nunca invocado**.

| Defeito | Alcance nas 14 | O sintoma no jogo |
|---|---|---|
| `animar()` definido e **nunca chamado** | 14 de 14 | o personagem executava a habilidade **parado**; dano, VFX e empurrão saíam no mesmo quadro do clique |
| `tocar()` **inexistente** | 14 de 14, 34 `Sound` | os sons estavam dentro da Tool, nomeados por papel, e **mudos** |
| `passa_mira` calculado e **nunca substituído** | 5 de 14 | a primária recebia `nil` e saía **sempre reta à frente**, no alcance cheio |
| `desmontarRig()` definido e **nunca chamado** | 14 de 14 | o rig sobrevivia ao respawn apontando para o corpo morto |

O `Poses.lua` e o `R6CFrameAnimator` estavam nas Tools desde a primeira leva,
com as sequências extraídas corretamente e as marcas `CARGA` e `GOLPE` no
lugar. Nada disso estava errado — **faltava o fio** entre eles e a habilidade.

### O que mudou

A habilidade sai **no beat**, não no clique: `CARGA` toca o som de preparação,
`GOLPE` solta o golpe. Se a sequência não tiver `GOLPE`, o disparo acontece no
fim — habilidade que não sai é a falha que este repositório já pagou uma vez, e
não há caminho em que ela simplesmente não aconteça.

A trava `ocupado` entra **antes** da recarga: barrá-la depois de
`ultimoUso = os.clock()` cobraria a espera por um golpe que não saiu.

`CARGA` toca no Handle, que acompanha o portador; `GOLPE` toca numa âncora no
mundo, para o som não morrer se a Tool for guardada no meio do efeito.

### O verificador aprendeu dois testes

`TESTES/verificar_rbxmx.py` ganhou:

- **6c** — Tool com `P.SEQUENCIAS` e nenhum `PlaySequence`/`PlayTrack`/`animar()`
  é **erro**. Era exatamente este defeito.
- **6d** — `Sound` dentro da Tool que nenhum script cita é **aviso**. A checagem
  é nova e encontrou o mesmo problema em 20 Tools de conjuntos antigos que
  ninguém pediu para mexer; contá-las como falha esconderia as falhas de
  verdade no meio do inventário.

### O que continua verdadeiro

Nada rodou no Studio. A verificação é toda estática — que a animação agora é
**chamada** está provado pelo arquivo; que ela **fica bonita** só o jogo diz.

### Uma track a mais, e ela é autoral

Esta forma tem **sete** Tools e o `xesterv2.lua` deu **seis** tracks de
habilidade. A sétima — `Xester Portal do Cajado` — estava declarada com
`seq = "PROCISSAO_DE_CARTAS"`: tocava a animação de outra Tool.

`PORTAL_DO_CAJADO` é a única track escrita à mão do conjunto, pela gramática:
conjuração de 1.14 s (regra 1), impacto a 53% (regra 2), liderada pelo
`RightArm` (regra 6), com dois quadros segurados (regra 7). O gesto acompanha
os dois sons que a Tool já tinha e nunca tocava: `ABRE` quando o braço abre o
portal, `CORTA` quando ele desce.

Ela vive em `FERRAMENTAS/gerar_servers_xester.py`, e não no
`poses_xester.json`, porque aquele arquivo é **saída** do
`extrair_poses_xester.py` — o que for escrito lá some na próxima extração.
