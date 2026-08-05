# Tools

**Vazio de propósito.** Todas as Tools foram removidas a pedido. As próximas
nascem dos modelos que você enviar.

## O método mudou — e o motivo

A leva anterior foi feita **reescrevendo** as Tools do zero a partir da lógica do
modelo. Isso produziu Tools que passavam em todo verificador e mesmo assim
entregavam outra coisa visualmente, porque:

| O que eu fiz | O que devia ter feito |
|---|---|
| Montei o Handle com primitivas em código | **Clonar** o Handle do modelo, com o `SpecialMesh` dele |
| Autorei poses a olho | Ler a animação do modelo e autorar em cima da **cadência** dela |
| Usei a V1 do modelo como base | Usar a versão **mais nova** que você enviou |
| Um efeito por impacto | **Camadas** — flash, disco, linhas, detrito, com durações diferentes |

O ponto que resume: **clonar a Tool que chegou, e trocar só o que a regra exige
trocar.** Não remontar do zero e chamar de conversão.

## Ponto de partida da próxima

O material está todo aqui, pronto:

| Onde | O que tem |
|---|---|
| `MODELOS_ENTRADA/Danilo_Escudos_V4/` | a remasterização — **é esta a base para clonar** |
| `MODELOS_ENTRADA/Danilo_Escudos/` | a V1, para comparação |
| `ACERVO_RETROVERSE/Jupiter_Great_Pressure_Sword/` | emissores + 21 sons |
| `ACERVO_RETROVERSE/Sword_of_Cosmic_Entity/` | emissores + 15 sons |
| `ACERVO_RETROVERSE/VFX_Library_V2/` | 782 emissores, 38 habilidades, `01_Saitama` incluso |
| `ACERVO_RETROVERSE/Judgement_Cut_End/` | sons de corte + meshes de lâmina |
| `ACERVO_RETROVERSE/Saitama_Animacoes_Referencia/` | 2417 keyframes já em `Weld.C0` |
| `ACERVO_RETROVERSE/Domain_Expansion_Elemental/` | pack elemental, ainda CRU |
| `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/` | `R6CFrameAnimator_V2` + molde de câmera |

Índice completo: [`ACERVO_RETROVERSE/_INDICE.md`](../ACERVO_RETROVERSE/_INDICE.md)

## O que continua valendo

As regras, as ferramentas e os verificadores ficaram — são o que sobrou de útil
da leva anterior, e vários deles nasceram de defeito real encontrado em jogo:

```bash
bash    TESTES/verificar_autocontencao.sh   # 23 checagens
python3 TESTES/verificar_poses.py           # poses × animator V2
python3 TESTES/verificar_rbxmx.py           # as Tools entregues
lua5.4  TESTES/harness_NucleoCombate.lua    # pipeline de dano
```

Entre as checagens, quatro que só existem porque a coisa quebrou em jogo:

- `registrarAtaque` não é aplicador de dano (7 Tools saíram com **dano zero**)
- `Players:GetPlayers()` não enxerga NPC
- servidor não move geometria por frame (**replica a ~20 Hz**, e é o que
  deixava o VFX picotado)
- sequência de pose inteiramente neutra é animação morta

`FERRAMENTAS/montar_rbxmx.py` tem `CATALOGO` e `CONJUNTOS` **vazios** — não
falta nada, é que não há Tool cadastrada. Ao cadastrar uma, ela precisa de
`tooltip · classe · energia · recarga · extra · poses · handle · sfx`, e
`"cutscene": True` se tiver cutscene.
