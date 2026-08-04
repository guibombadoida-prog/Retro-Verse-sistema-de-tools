# Conjunto Gravidade / Telecinese — 7 Tools

Entrega: **`Tools/GravidadeTelecinese_7_Tools.rbxmx`** — as 7 Tools num arquivo só, na raiz
do arquivo. Arraste para a `StarterPack` e as sete chegam ao jogador.

Um `.rbxmx` individual por Tool também existe, na pasta de cada uma.

## As 7

| Tool | `DamageClass` | Recarga | Extra | Promessa do ToolTip |
|---|---|---|---|---|
| `PulsoGravitacional` | Magic | 16 s | X | comprime a gravidade ao redor; X lança singularidade |
| `CampoZeroG` | Debuff | 16 s | X | levita inimigos em órbita curta; X detona o campo |
| `MaoTelecinetica` | Magic | 16 s | X | empurra alvos com força mental; X puxa todos para você |
| `OrbitaPsi` | Hybrid | 16 s | X | anéis telecinéticos protegem e cortam; X expande a órbita |
| `LancaVetorial` | Ranged | 16 s | X | arremessa uma linha de força; X perfura em área |
| `PocoDeMassa` | Debuff | 16 s | X | cria um peso absurdo no chão; X colapsa o poço |
| `MarionetePsi` | Summon | 16 s | X | dobra a postura dos alvos; X explode o vínculo |

Primária em `Tool.Activated`. Extra na tecla **X**, via `AcaoRemote`.

---

## ⚠️ Estado real: as sete são a mesma Tool

**Isto precisa ser dito antes de qualquer outra coisa.** Comparando arquivo a arquivo, com o
nome normalizado:

| Arquivo | Diferença entre as 7 |
|---|---|
| `<Nome>_Server_V1.lua` | **nenhuma** além do nome |
| `Poses_GravidadeTelecinese_<Nome>_V1.lua` | **nenhuma** além do nome |
| `VFXModule.lua` | **nenhuma**, byte a byte |
| `Client.lua` | **nenhuma** além do nome |

O que de fato difere entre uma Tool e outra: o **nome**, o **ToolTip**, o **`DamageClass`**,
**um id de som** e a lista de moldes de efeito em `Tool/Efeitos/`.

Ou seja: as sete executam **o mesmo golpe em área** — 24 de dano num raio de 14, recarga de
0,75 s — e a mesma habilidade Extra. Nenhuma levita, nenhuma arremessa linha, nenhuma cria
poço, nenhuma dobra postura. **O ToolTip promete sete comportamentos; o código entrega um.**

As sete estão conformes: passam autocontenção, poses, `.rbxmx` e compilam. O que falta não é
conformidade, é **conteúdo** — a lógica de habilidade de seis delas.

### O que isso significa na prática

| | |
|---|---|
| Dá para arrastar para o Studio e jogar? | Sim. As sete funcionam, sem erro. |
| Dá para distinguir uma da outra jogando? | **Não**, fora o ícone e o texto. |
| É entrega fechada? | **Não.** Está declarado aqui, não escondido. |

**Trabalho disponível, em ordem de retorno:** escrever a lógica primária de cada habilidade,
uma Tool por vez, e as poses que correspondem a ela. O molde e o Núcleo já sustentam isso —
o que falta é a autoria de cada uma.

---

## O que já está certo

- **Autocontido.** Cada Tool traz seus scripts, sons, moldes de efeito e poses dentro de si.
  Apague o `ACERVO_RETROVERSE` do place e as sete continuam funcionando (Regra nº 1).
- **Animação no `R6CFrameAnimator` V2**, com as sequências encadeadas por `PlaySequence` —
  `Tween.Completed`, nunca `task.wait` por beat.
- **VFX no cliente.** O servidor transmite tipo e payload por `VFXRemote`; quem cria partícula
  é o `VFXModule`. Zero `:Emit()` no servidor.
- **Núcleo opcional.** Toda chamada a `_G.Combate` está sob guarda: apague o `NucleoCombate` e
  as Tools seguem funcionando, sem os bônus de combate.

## Dois defeitos corrigidos nesta passagem

**1. VFX morto.** Os sete Servers pediam dois tipos de efeito — um herdado de um conjunto
antigo e o `RAIO_TEMPORAL` — e o `VFXModule` delas implementava só `IMPACTO` e
`IMPACTO_NOVA`. `VFX.executar` faz `VFX[tipo]`, não acha, e **volta calado** — o efeito não
desenhava e nada avisava.

- O tipo herdado passou a `IMPACTO_NOVA`, que a Tool de fato implementa.
- `RAIO_TEMPORAL` **ganhou implementação**: os emissores `Plasma` e `Clarao` já estavam dentro
  da Tool, em `Tool/Efeitos/RAIO_TEMPORAL`, mas ninguém os ligava. Agora são ligados por
  `Enabled` + `Rate`, nunca por `:Emit()` — `:Emit()` dispara leva fixa e ignora a curva
  autorada no emissor, perdendo exatamente o que foi extraído do modelo de origem.
- `AURA` também ganhou implementação, pelo mesmo caminho.

`TESTES/verificar_rbxmx.py` ganhou a checagem que pega isso: **todo VFX transmitido tem de
existir no `VFXModule` da própria Tool**.

**2. Nome de arquivo mentindo.** Os arquivos de pose carregavam no nome o modelo de um
conjunto antigo, herança de quando este foi copiado do molde. Renomeados para
`Poses_GravidadeTelecinese_<Nome>_V1.lua`, que é o que eles de fato são.

## Verificação

```bash
bash    TESTES/verificar_autocontencao.sh
python3 TESTES/verificar_poses.py
python3 FERRAMENTAS/montar_rbxmx.py
python3 TESTES/verificar_rbxmx.py
```

## Origem

Conjunto criado no PR #2 a partir do `_TEMPLATE_Tool`. Não vem de modelo de terceiro: os
moldes de efeito são os do Acervo (`RAIO_TEMPORAL` e `AURA`, do Jupiter; `ESTILHACO_ESTELAR`,
`BRASA` e `FAISCA`, do Cosmic Entity), recolorizados para a paleta do repositório.
