# FERRAMENTAS/bin

## `xmx2rbxm`

Binário Linux x86-64 que converte `.rbxmx` (XML) em `.rbxm` (binário).

É um wrapper de ~15 linhas sobre o **rbx-dom** — `rbx_xml` para ler,
`rbx_binary` para escrever. O rbx-dom é a implementação de referência do
formato, a mesma que o Rojo usa.

**Por que não escrevemos o serializador aqui.** `.rbxm` não é `.rbxmx`
renomeado: é formato de chunks (`META`, `SSTR`, `INST`, `PROP`, `PRNT`, `END`)
com as propriedades transpostas por classe e codificação intercalada — int32
em zigzag, referente em delta acumulado, float com rotação de bit. Um encoding
sutilmente errado produz arquivo que o Studio recusa, ou — pior — aceita
religando propriedade no objeto errado, sem avisar.

### Recompilar

```toml
# Cargo.toml
[dependencies]
rbx_dom_weak = "2"
rbx_xml      = "0.13"
rbx_binary   = "0.7"
```

```rust
let dom = rbx_xml::from_reader_default(BufReader::new(File::open(&entrada)?))?;
let raizes: Vec<_> = dom.root().children().to_vec();
rbx_binary::to_writer(BufWriter::new(File::create(&saida)?), &dom, &raizes)?;
```

`cargo build --release`, e o binário vai para cá.

### Uso

```bash
python3 FERRAMENTAS/converter_para_rbxm.py <entrada.rbxmx> [saida.rbxm]
```

O wrapper Python cuida do `Tags`: o Studio grava como `SharedString`, o
rbx-dom recusa esse tipo nessa propriedade, e a troca é para `BinaryString`.
**Só troca se o valor compartilhado for vazio** — tag de `CollectionService`
é comportamento de jogo, e se alguma vier com conteúdo o script para e avisa
em vez de descartar em silêncio.
