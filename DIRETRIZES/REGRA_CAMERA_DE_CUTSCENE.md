# REGRA DA CÂMERA DE CUTSCENE
**Retro-Verse / Studios** · precedência: junto da animação R6, acima da base

---

## O enunciado

> **Câmera é 100% cliente.** O servidor manda *beat*, nunca `CFrame`.
> Toda câmera presa é devolvida em `Unequipped`, `Destroying` e morte — sem exceção.

---

## Por que o servidor não toca em câmera

Não existe "a câmera do jogo". Existe **uma por cliente**, e ela pertence ao dono daquele
cliente. Servidor mexendo em câmera é, na prática, escrever numa instância que só existe
na máquina do jogador — não replica, ou replica errado, e em qualquer caso tira do jogador
o controle da própria visão sem que ele possa recuperar.

O contrato é de **beats nomeados**:

```
Servidor                                      Cliente
  |  CutsceneRemote:FireClient(jogador, "START", 15)
  |------------------------------------------->  prende a câmera, começa a órbita
  |  ... "ORBIT"                              >  troca o estágio da órbita
  |  ... "CLOSE"                              >  fecha o FOV (tensão)
  |  ... "PUNCH"                              >  estoura o FOV (impacto)
  |  ... "STOP"                               >  devolve a câmera ao jogador
```

Beat é **nome e duração**. O servidor não sabe onde a câmera está e não precisa saber.
Enquadramento é decisão do cliente; timeline é decisão do servidor.

---

## As cinco obrigações

### 1. Guardar e restaurar o `CameraType`
Guardar o valor **anterior** antes de pôr `Scriptable`, e devolver aquele valor.
Devolver `Custom` chutado quebra quem estava em `Follow`, `Attach` ou `Scriptable` por
outro sistema.

### 2. Restaurar o `FieldOfView`
Sair da cutscene com FOV 38 deixa o jogador de telefoto pelo resto da partida — e ele não
tem como consertar.

### 3. Desligar em `Unequipped`, `Destroying` e morte
```lua
Tool.Unequipped:Connect(stopCutscene)
Tool.Destroying:Connect(stopCutscene)
```
Câmera presa com a Tool fora da mão é o pior bug do repertório: o jogador perde o
controle e não tem saída a não ser sair do jogo.

### 4. Ser pulável — e o pulo é só visual
Segurar uma tecla por ~1,5 s solta a câmera. O pulo **não** encurta a timeline do
servidor: solta a câmera e nada mais. Se o skip mexesse no servidor, pular a cutscene
viraria vantagem de combate, e todo mundo pularia sempre.

### 5. Só `LocalScript`
Câmera em Server Script é violação da Regra nº 1 e desta. Se o Server Script precisa que
algo aconteça na tela, ele manda um beat.

---

## `workspace.CurrentCamera` e a Regra nº 1

A Regra nº 1 proíbe **ler** o mundo. `workspace.CurrentCamera` é exceção declarada, pelo
mesmo motivo que `Players.LocalPlayer` é: é um **singleton por cliente**, presente em todo
place, sem ninguém depositar nada.

O teste do place vazio continua valendo e continua passando — arraste a Tool sozinha e a
cutscene roda inteira.

Ver `REGRA_AUTOCONTENCAO_ABSOLUTA.md`, item 4 das coisas que não são violação.

---

## Técnica — o que faz a câmera ler como cinema

Molde: `ACERVO_RETROVERSE/_AUTORAL_RetroVerse/CAMERA/SeriousMode_CutsceneCam_V1.lua`.

| Técnica | Como | Por que |
|---|---|---|
| Órbita bezier | `bezier(t, p0, p1, p2)` sobre pontos derivados do HRP | arco de grua; reta lê como câmera de vigilância |
| Dois estágios | abertura alta e distante → carga baixa e perto | aproximar dá peso sem cortar |
| Contraste de FOV | 70 base → **38** na carga → **96** no burst → 70 | é o contraste que vende o golpe, não o valor |
| Shake por acumulador | `sin(elapsed*24)*0.03*t + sin(elapsed*41)*0.012*t` | duas frequências que não se repetem; sem `math.random` |
| Roll sutil | `sin(t*π) * rad(3)` | sobe e volta a zero sozinho nas pontas |
| Pontos determinísticos | `hrp.CFrame * CFrame.new(...)` | mesma câmera toda vez |

O shake cresce com `t` de propósito: a tensão sobe junto com a carga.

**Contraste de FOV é a técnica principal.** Fechar a 38 comprime a perspectiva e prende;
estourar a 96 no frame de impacto abre tudo de uma vez. Um FOV fixo, por mais bem
escolhido, não produz esse efeito.

---

## Proibições

| Proibido | Por quê |
|---|---|
| `ScreenGui` · `BillboardGui` dentro da Tool | UI é sistema de jogo, não é Tool (§base) |
| `ColorCorrectionEffect` · `BlurEffect` · `Sky` | pós-processamento é global e vaza para fora da Tool |
| Servidor escrevendo em `Camera` | não replica; tira o controle do jogador |
| Servidor mandando `CFrame` de câmera | enquadramento é do cliente; manda beat |
| `math.random` no shake | shake tem de ser reproduzível |
| `tick()` alimentando a câmera | acumulador `dt` a partir de zero |
| Skip que encurta a timeline do servidor | vira vantagem de combate |
| Prender a câmera sem guardar o estado anterior | não tem como devolver |

Efeito de cutscene é **enquadramento e lente** — posição, alvo, FOV, roll, shake.

---

## Verificação

```bash
bash TESTES/verificar_autocontencao.sh
```

Checa `camera só no cliente` e `câmera presa é sempre devolvida` — este último exige que
todo script que escreve em `CameraType` também ligue `Tool.Unequipped` e `Tool.Destroying`.

Manual, no Studio:

- [ ] Rodar a cutscene inteira → câmera volta sozinha, com `CameraType` e FOV originais
- [ ] Desequipar no meio → câmera volta na hora
- [ ] Morrer no meio → câmera volta, respawn normal
- [ ] Segurar a tecla de skip → solta em ~1,5 s
- [ ] Skip no meio → **o efeito no servidor acontece igual**, no mesmo tempo
- [ ] Dois jogadores, um pula e o outro não → a timeline dos dois termina junto
