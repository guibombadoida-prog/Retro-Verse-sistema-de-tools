# GRAMÁTICA DE CUTSCENE — como a câmera vende o golpe
**Retro-Verse / Studios** · regras medidas em três implementações reais

---

## As três fontes

| | `SeriousMode_CutsceneCam_V1` | `YorrSlayer_CutsceneCam_V1` | `Escudo Partido` |
|---|---|---|---|
| origem | molde da casa | modelo de terceiro, conformado | trilho do pack Saitama |
| enquadramento | um só, para todos | **um por espectador** | um só, e **só o portador vê** |
| movimento | estágios com aproximação | aproximação exponencial | trilho de keyframes, lerp linear |
| FOV | 70 → **38** → **96** → 70 | 70 → **52** → **86** → 70 | **nenhum** |
| tremor | senoidal determinístico | senoidal com envelope | nenhum na câmera |
| pular | segurar **E**, 1.5 s | segurar **E**, 1.5 s | **não tem** |
| devolve a câmera | sim | sim | sim (sem FOV, que não mexe) |

---

## As seis regras

### 1. FOV é a técnica principal, não o movimento

Os dois moldes fecham o FOV na carga e **estouram** no golpe. É a única coisa
que as três fontes tratam como central — o comentário do molde da casa diz
literalmente *"contraste é o que vende o golpe"*.

| | fecha | estoura | amplitude |
|---|---|---|---|
| SeriousMode | 38 | 96 | **58** |
| YorrSlayer | 52 | 86 | **34** |

Regra: **quanto mais íntimo o golpe, maior a amplitude.** O SeriousMode é um
soco na cara; o YorrSlayer é um dragão a 30 studs. Base 70 nos dois.

O `Escudo Partido` não mexe em FOV nenhum. É a maior lacuna dele.

### 2. Enquadramento POR ESPECTADOR — o achado do YorrSlayer

É o que nenhum molde da casa tinha:

```
quem invoca  →  30 studs à frente do dragão, +6 de altura
quem é alvo  →  15 studs atrás de si mesmo, +5 de altura, olhando a própria cara
```

Uma cutscene que mostra a mesma coisa para o algoz e para a vítima desperdiça
metade da cena. O alvo tem de **se ver sendo alcançado**.

### 3. Aproximação exponencial, nunca Tween bloqueante

```lua
local k = 1 - math.exp(-VELOC_CAM * dt)   -- VELOC_CAM = 3.2
curPos = curPos:Lerp(metaPos, k)
```

Independente de FPS, interrompível a qualquer quadro, e não trava o
`LocalScript`. O original do YorrSlayer usava `Tween...Completed:Wait()` dentro
do handler do Remote — que bloqueia tudo e não dá para cortar limpo.

### 4. Estágio troca por TEMPO, não por espera

`if elapsed > 1.5 then etapa = 2 end`. O corte que o original fazia com dois
tweens separados vira uma troca de alvo dentro do mesmo `RenderStepped`.

### 5. Tremor com envelope, e só na janela do golpe

```lua
local env = math.clamp(1 - janelaT, 0, 1)
return (math.sin(t * 24) * 0.35 + math.sin(t * 41) * 0.14) * env
```

Duas frequências que **não se repetem** (24 e 41 não são múltiplas), com
envelope que faz o tremor nascer forte e sumir sozinho. Janela: 2.5 s a 4.5 s —
só o instante do golpe, nunca a cena inteira. Zero `math.random`.

### 6. Pular é obrigatório, e é SÓ visual

Segurar **E** por 1.5 s solta a câmera. O servidor continua no tempo dele:
pular não adianta o dano nem cancela a habilidade. Sem isso, uma cutscene de 6
segundos vira punição para quem já a viu dez vezes.

---

## O contrato com o servidor

```
Remote:FireClient(jogador, "CUTSCENE", { ...papéis... })
```

**Um FireClient por espectador**, com o papel dele no payload — é assim que o
enquadramento por espectador funciona sem o cliente decidir nada. O servidor
sabe quem é o invocador e quem é o alvo; o cliente só desenha o que lhe cabe.

`duracao` é **teto de segurança**, não cronômetro: se a cena não se fechar
sozinha até lá, ela se fecha por prazo.

---

## O que sempre fecha a câmera

`Unequipped`, `Destroying`, alvo ou invocador saindo do jogo, prazo estourado,
e o pulo. Cinco portas. A regra chama câmera presa de *"o pior do repertório"*,
e é o bug que o original do YorrSlayer tinha: ele não mandava nada para o
cliente se o jogador desequipasse no meio.
