# Conjunto: JODRO — 7 Tools de meme, autorais inteiras

- Autor original:            **este repositório** — não há modelo de terceiro
- Origem:                    nenhuma. Pedido direto, sem `.rbxmx` de entrada
- Licença / permissão:       **própria** — §12.12.3 nasce resolvido
- Data de entrada:           2026-08-18
- Status:                    **APROVADO**
- Onde vive:                 `Tools/jodro.rbxm`

---

## O que é

Sete Tools de meme, e o primeiro conjunto do repositório com **três habilidades
por Tool**: M1 no clique, `R` e `T` nas teclas.

| Tool | M1 | R | T |
|---|---|---|---|
| **Bonk** | bonk, 24 + tombo | Mega Bonk — área 14, 52/26 | Cadeia — prende 4 s |
| **Chinelo Voador** | chinelada, 18 | Teleguiado — vai e **volta**, 34 | Mãe Brava — medo em 20 studs |
| **Sussy** | facada 26, **+60% pelas costas** | Vent — teleporte de 45 | Reunião — puxa todos de 30 |
| **Caixa de Som** | onda sonora, 16 + empurrão | Nunca Te Abandono — prende 2.5 s | Troca de Faixa — troca de lugar |
| **Privada Sonora** | jato em linha, 22 | Descarga — puxa e estoura, 46/24 | Coro — 3 cabeças por 8 s |
| **Pombo Correio** | bicada, 16 | Revoada — 7 aves perseguindo, 6 s | Encomenda — cai do céu, 60/30 |
| **Deu Ruim** | o dedo, 20 | Stonks — +50% velocidade, +40% dano | Not Stonks — lentidão e sangria |

---

## Três decisões que valem para o próximo conjunto assim

### Um `AcaoRemote` para duas Extras, não dois

Quem separa é o **nome da tecla no payload**, conferido no servidor antes de
qualquer coisa. Dois remotes seriam duas portas para o mesmo cômodo, e duas
superfícies para validar. Tecla fora de `"R"` e `"T"` é descartada sem resposta.

### Nenhum `SoundId` foi inventado

Os 15 ids usados **já tocam em Tools entregues deste repositório**. Id chutado é
som mudo que nenhum verificador pega: o `.rbxmx` fica válido, o `.rbxm` converte,
e o jogo fica em silêncio. A tabela `SONS` do preparador diz, por id, onde ele já
vive.

### O andaime do `VFXModule` foi reusado, os efeitos não

`novaParte`, `tween`, `registrar`, as cinco `camada*` e o `pk` do pack Stella
vieram do `VFXModule_Guest`. Reescrever tudo seria criar uma segunda versão de
cada bug já consertado. O que é novo são os **23 efeitos**, um ou mais por
habilidade — mais dois helpers que faltavam no andaime do Guest e teriam
quebrado dentro do `pcall`, em silêncio: `angulo` e `registroDe`.

---

## Handle: primitiva, e por isso sem licença a resolver

23 `Part` em 7 assembleias, soldadas por `Weld` ao Handle. Martelo de cabo e
cabeça; chinelo de sola e tira em V; faca de lâmina e guarda; caixa com dois
cones e uma luz; privada com tampa e cano; pombo com bico e carta; mão com dedo
apontado.

Nenhuma malha de terceiro, nenhum `rbxassetid` de mesh — nada a licenciar.

## Armadilha que custou a primeira conversão

`<token name="MaterialVariantSerialized" />` sem conteúdo. O `rbx-dom` tenta ler
inteiro de string vazia e a conversão para `.rbxm` morre com `ParseIntError` na
coluna 778. `token` vazio não existe: ou tem número, ou a propriedade não entra.

## Delta do Acervo

Entrou: 23 efeitos autorais em `VFXModule_Jodro.lua`, 21 sequências de pose R6,
7 assembleias de Handle primitivo. Reusado: o andaime de VFX do Guest, o
`R6CFrameAnimator` canônico, o pack Stella, e 15 `SoundId` já provados.
