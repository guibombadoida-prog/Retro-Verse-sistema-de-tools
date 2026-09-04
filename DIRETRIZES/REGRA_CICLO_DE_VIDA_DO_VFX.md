# REGRA DO CICLO DE VIDA DO VFX
**Retro-Verse / Studios** · **Regra nº 2 — só perde para a autocontenção**

Substitui a parte da Regra nº 1 que dizia "o molde nunca sai da Tool". Ele sai — mas
**quem o tira é a própria Tool**, e ela o leva de volta quando morre.

---

## O enunciado

> **Na entrega**, todo VFX de geometria — `Part`, `MeshPart`, `SpecialMesh`, `Attachment`,
> `ParticleEmitter`, `Beam`, `Trail` — é **filho da Tool**.
>
> **Em runtime**, quando a Tool chega ao jogador — na mochila **ou** na mão —, esses moldes
> **saem da Tool** e vão para `ReplicatedStorage`.
>
> **A pasta CRIA ou REUTILIZA.** A primeira Tool que chegar monta; toda Tool depois dela
> encontra pronto e usa. A pasta fica no `ReplicatedStorage` **até o servidor ser
> desligado**.

---

## Por que mudou

A regra antiga mandava clonar de `Tool/Efeitos/` toda vez. Isso significa que **cada
jogador carrega uma cópia inteira dos moldes**, e a mesma Tool na mão de oito pessoas é
oito cópias do mesmo `MeshPart` replicando para os mesmos clientes.

`ReplicatedStorage` existe exatamente para isto: uma cópia, replicada uma vez, visível para
todo mundo.

**O que NÃO mudou é o artefato de entrega.** O `.rbxm` continua sendo um arquivo que se
arrasta para o Studio e funciona. Ninguém precisa montar pasta em `ReplicatedStorage` à
mão — a Tool monta a dela sozinha, no primeiro `Equipped`.

---

## A forma do depósito

```
ReplicatedStorage/
└── RetroVerse_VFX/               <- criada pela primeira Tool que chegar
    ├── Jupiter_Raio_Joviano/     <- uma pasta por MODELO de Tool
    │   ├── Efeitos/              <- os moldes que vieram de dentro da Tool
    │   └── Pack/                 <- o pack de VFX, se a Tool tiver
    └── Drama_Corte_Frio/
        └── Efeitos/
```

### A chave é o MODELO, não a instância

Duas pessoas com a mesma Tool compartilham **uma** pasta. Se a chave fosse por instância,
o depósito teria oito cópias e não teríamos resolvido nada.

A chave sai de um `StringValue` chamado `ChaveVFX`, filho da Tool, escrito na montagem.
Nome de Tool não serve: dois modelos podem se chamar `Aura`.

### Criar ou reutilizar — e nunca apagar

A primeira Tool daquele modelo que chegar ao jogador **monta** a pasta e move os moldes
para dentro. Da segunda em diante, a pasta já está lá: a Tool **encontra pronto e usa**.

A pasta **não é apagada**. Ela fica no `ReplicatedStorage` até o servidor ser desligado, e
some com ele — que é o fim de vida de qualquer coisa que viva em `ReplicatedStorage`.

**Por que não apagar quando a Tool morre.** Porque a pasta não é da Tool: é do MODELO. Dois
jogadores com a mesma Tool dependem da mesma pasta, e o instante em que um deles guarda ou
morre não diz nada sobre o outro. Apagar ali arrancaria o molde debaixo de quem ainda está
com ela na mão — e o sintoma é a Tool parar de desenhar, em silêncio.

Contar referência para saber quando é seguro apagar resolveria isso, e foi a primeira
versão desta regra. Não vale o preço: é estado a mais para manter certo, num caminho que
tem de estar certo em todo `Destroying` de todas as Tools, e o que se ganha é liberar
algumas pastas de molde num servidor que vai cair de qualquer jeito.

**O que NÃO cresce sem limite.** A chave é por modelo, então o teto é o número de modelos
de Tool que apareceram na partida — não o número de jogadores, nem o de Tools equipadas.
Um servidor com 30 pessoas usando as mesmas 7 Tools tem 7 pastas.

---

---

## Quem faz o quê

| Momento | Quem | O quê |
|---|---|---|
| Montagem (`.rbxm`) | `FERRAMENTAS/` | moldes ficam em `Tool/Efeitos/`, `ChaveVFX` escrito |
| Chegar ao jogador — mochila **ou** mão | **Server** | pasta existe? usa. Não existe? cria e move `Efeitos` e `Pack` |
| durante a habilidade | Client | clona do depósito; se não achar, clona de dentro da Tool |
| servidor desligado | Roblox | a pasta some junto com o place |

### Instalar é trabalho do SERVER, sempre

`ReplicatedStorage` replica do servidor para os clientes. Um cliente que mova instância
para lá move **só para ele mesmo** — os outros oito não veem nada, e o efeito volta a ser
local, que é o bug que já custou uma leva inteira neste repositório.

### Ler tem DUAS portas, nesta ordem

```lua
local molde = doDeposito(nome) or dentroDaTool(nome)
```

A segunda porta não é redundância defensiva: é o que mantém verdadeiro o teste da Regra
nº 1. Enquanto a instalação não aconteceu — e no quadro exato em que ela está
acontecendo — o molde ainda está dentro da Tool, e é de lá que ele tem de sair.

---

## O que continua proibido

A Tool escreve no depósito **dela** e lê do depósito **dela**. Nada mais mudou:

| ❌ Continua proibido | Por quê |
|---|---|
| Ler pasta de `ReplicatedStorage` que a Tool não criou | É dependência externa, e o teste do place vazio falha |
| `ServerStorage` / `ServerScriptService` para buscar asset | Idem |
| `InsertService:LoadAsset(...)` | Traz instância de fora em runtime |
| `require(<id numérico>)` | Código de fora, não auditável |
| Instalar pelo **cliente** | Não replica; o efeito volta a ser local |
| Apagar a pasta do depósito | Ela é do MODELO: outro jogador pode estar usando |

---

## O teste que decide, atualizado

**Arraste a Tool sozinha para um place vazio. Ela funciona por inteiro.**

O place não tem `RetroVerse_VFX` — ninguém montou nada. A Tool monta no primeiro
`Equipped`, e antes disso lê de dentro de si mesma. **O teste continua igual, e o
resultado também.**

Segundo teste, novo:

**Duas pessoas com a mesma Tool. Uma guarda e morre; a outra continua desenhando.**

É o teste que a versão anterior desta regra não passava. A pasta é do MODELO, e o
`Destroying` de uma instância não diz nada sobre a outra.

---

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh   # a Regra nº 1, com a porta dupla
python3 TESTES/verificar_deposito_vfx.py    # instala, conta, e apaga
```

O `verificar_deposito_vfx.py` confere, Tool a Tool:

1. tem `ChaveVFX`, e a chave é única no repositório;
2. quem instala é Server, nunca Client — cliente não replica;
3. quem lê tem as **duas** portas, na ordem certa;
4. ninguém apaga a pasta do depósito — ela é do modelo, não da instância.
