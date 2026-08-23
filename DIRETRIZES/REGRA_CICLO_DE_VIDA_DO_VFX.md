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
> **Quando a Tool é removida ou destruída**, os moldes que ela pôs lá **vão junto**.

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
    │   ├── _refs   (IntValue)    <- quantas Tools vivas dependem desta pasta
    │   ├── Efeitos/              <- os moldes que vieram de dentro da Tool
    │   └── Pack/                 <- o pack de VFX, se a Tool tiver
    └── Drama_Corte_Frio/
        ├── _refs
        └── Efeitos/
```

### A chave é o MODELO, não a instância

Duas pessoas com a mesma Tool compartilham **uma** pasta. Se a chave fosse por instância,
o depósito teria oito cópias e não teríamos resolvido nada.

A chave sai de um `StringValue` chamado `ChaveVFX`, filho da Tool, escrito na montagem.
Nome de Tool não serve: dois modelos podem se chamar `Aura`.

### `_refs` não é enfeite

A regra diz "a Tool é destruída, os moldes vão junto". Com **um** jogador isso é literal.
Com **dois**, apagar no primeiro `Destroying` arrancaria o molde debaixo do segundo — a
segunda Tool continuaria viva e pararia de desenhar.

`_refs` é a contagem de Tools vivas que dependem daquela pasta:

- **instalar:** `_refs = _refs + 1`. Se a pasta não existir, criar e mover os moldes.
- **desinstalar:** `_refs = _refs - 1`. **Chegou a zero, a pasta some.**

É a leitura fiel do enunciado — "vão junto com a Tool" quer dizer *com a última*.

---

## Quem faz o quê

| Momento | Quem | O quê |
|---|---|---|
| Montagem (`.rbxm`) | `FERRAMENTAS/` | moldes ficam em `Tool/Efeitos/`, `ChaveVFX` escrito |
| `Tool.Equipped` **ou** entrar na mochila | **Server** | instala: move `Efeitos` e `Pack` para o depósito, `_refs + 1` |
| durante a habilidade | Client | clona do depósito; se não achar, clona de dentro da Tool |
| `Tool.Destroying` | **Server** | `_refs - 1`; zerou, apaga a pasta |

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
| Deixar o depósito para trás | Vazamento: a pasta fica no place depois da Tool sumir |

---

## O teste que decide, atualizado

**Arraste a Tool sozinha para um place vazio. Ela funciona por inteiro.**

O place não tem `RetroVerse_VFX` — ninguém montou nada. A Tool monta no primeiro
`Equipped`, e antes disso lê de dentro de si mesma. **O teste continua igual, e o
resultado também.**

Segundo teste, novo:

**Pegue a Tool, use, guarde, e apague a Tool. `ReplicatedStorage` volta a ficar vazio.**

Se sobrar `RetroVerse_VFX` com pasta dentro, a Tool vazou.

---

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh   # a Regra nº 1, com a porta dupla
python3 TESTES/verificar_deposito_vfx.py    # instala, conta, e apaga
```

O `verificar_deposito_vfx.py` confere, Tool a Tool:

1. tem `ChaveVFX`, e a chave é única no repositório;
2. quem instala é Server, nunca Client;
3. todo caminho que instala tem o par que desinstala — `Tool.Destroying` ligado;
4. quem lê tem as **duas** portas, na ordem certa;
5. `_refs` sobe e desce no mesmo arquivo.
