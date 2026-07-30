# Guardião do Tempo — VFX

Um módulo serve os cinco efeitos: `VFXModule_GuardiaoDoTempo.lua`.
É copiado **para dentro** de cada Tool com o nome de objeto `VFXModule` (Regra nº 1).

## Efeitos

| Tipo transmitido | Origem no modelo | O que faz |
|---|---|---|
| `ONDA_TEMPORAL` | `WACKYEFFECT` EffectType `Wave` | Cilindro que abre no chão, girando enquanto desbota |
| `ESFERA_TEMPORAL` | `WACKYEFFECT` EffectType `Sphere` | Esfera que infla e some |
| `MOSTRADOR_TEMPORAL` | `ClockEffect` | 12 marcas de hora se afastando + ponteiro girando |
| `DETRITOS` | `Debree` | Estilhaços em parábola, girando por fase própria |
| `TREMOR` | `CamShake` (LocalScript) | Tremor de câmera, atenuado por distância |

## Parâmetros

| Parâmetro | Padrão | Faixa útil |
|---|---|---|
| `escala` | 1.0 | 0.7 – 4.2 |
| `cor` | `Color3.fromRGB(154, 205, 50)` — o `BASECOLOR` do modelo | — |
| Vida da onda | 1,25 s | 0,8 – 1,6 |
| Vida da esfera | 0,90 s | 0,6 – 1,2 |
| Vida do mostrador | 1,60 s | 1,2 – 2,2 |
| Vida dos detritos | 1,60 s | 1,2 – 2,0 |
| Vida do tremor | 0,55 s | 0,3 – 0,8 |
| Alcance do tremor | 90 studs | 60 – 120 |

Escala acima de 4 come a tela em close (`_PADROES.md`).

## Custo por disparo

| Efeito | Partes | Conexões |
|---|---|---|
| `ONDA_TEMPORAL` | 1 | 1 `RenderStepped` |
| `ESFERA_TEMPORAL` | 1 | 1 |
| `MOSTRADOR_TEMPORAL` | 13 + 1 Folder | 1 |
| `DETRITOS` | 10 + 1 Folder | 1 |
| `TREMOR` | 0 | 1 |

Toda conexão se desliga sozinha ao fim do acumulador, e toda parte sai por `Parent = nil`
com `Debris` de rede de segurança. Nenhuma usa `:Destroy()`.

O pico é a ultimate: 12 badaladas × `ONDA_TEMPORAL` + o fechamento. Se pesar em servidor cheio,
o primeiro corte é a escala das badaladas, não a quantidade — o ritmo das 12 é a assinatura
da habilidade.

## O que foi corrigido do original

| Achado | Correção |
|---|---|
| `math.random` na dispersão e no `CamShake` | ângulo áureo (Vogel) e jitter senoidal de 3 frequências |
| `wait()` / `Swait()` | acumulador `dt` em `RenderStepped` |
| `SINE` global alimentando `CFrame` | `t` local, a partir de zero |
| `:remove()` | `Parent = nil` / `Debris` |
| `ColorCorrectionEffect` (`Permachrome`) | removido — o efeito vive só no mundo 3D |
| `ScreenGui` (`WEAPONGUI`) | removido |
| Efeito criado no servidor | criado no cliente, disparado por `VFXRemote` |

### O jitter do tremor

O `CamShake` original sorteava o deslocamento com `MRANDOM` a cada quadro. A substituição usa
três senos de frequências primas entre si (37, 43, 29), com decaimento linear:

```lua
humanoide.CameraOffset = Vector3.new(
	math.sin(t * 37) * forca * decaimento,
	math.sin(t * 43) * forca * decaimento,
	math.sin(t * 29) * forca * decaimento
)
```

Determinístico, reproduzível, e visualmente indistinguível do sorteio.

## Moldes opcionais

Se existir `Tool/Efeitos/<NOME>`, o módulo **clona** o molde em vez de desenhar a parte
procedural. Nomes que ele procura:

```
ONDA_TEMPORAL · ESFERA_TEMPORAL · MOSTRADOR_MARCA · MOSTRADOR_PONTEIRO · DETRITO
```

Sem molde, o efeito continua funcionando — a Tool **degrada, não quebra**.

## Onde já foi usado

As 7 Tools do conjunto Guardião do Tempo. Ver `../FICHA.md`.
