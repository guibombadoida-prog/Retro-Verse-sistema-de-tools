# _PADROES — convenções e armadilhas conhecidas

Este arquivo é memória de campo: cada armadilha aqui já custou um bug.

---

## Armadilhas que já quebraram alguma coisa

### A tag `creator` invisível
`Instance.new("ObjectValue", pai)` define o `Parent` **antes** do `Name`. Quem escuta
`ChildAdded` no Humanoid vê um objeto ainda chamado `"Value"` e vazio — e ignora.
**Ordem obrigatória:** `Name` → `Value` → `Parent`, sempre nessa sequência (§12.7).

### `tick()` alimentando `CFrame`
`tick()` devolve um número absoluto e grande. Em ponto flutuante, a animação **treme**.
Acumulador `dt` local, a partir de zero, sempre (§10.11.7).

### `Tool.Enabled` resetado em `Unequipped`
Vira cancelamento de recarga: desequipa, reequipa, dispara de novo. É exploit.
Recarga que precisa sobreviver a isso é **recarga global**, no Núcleo (§12.9).

### Três cópias da mesma Tool na mochila
`Tool.Enabled` é por instância — três cópias disparam três vezes. A recarga global é registrada
**no jogador**, por chave nomeada, e trava o `Enabled` de todas as cópias (§12.9).

### `:Emit()` no servidor
Força replicação de instância e anula o ganho de rede. O servidor **transmite dados**;
quem emite é o cliente (§12.11).

### Escudo órfão
Registro sem duração e sem cancelamento é escudo **permanente**. Guardar a função de
cancelamento em variável local e chamá-la em `Tool.Destroying`, `Humanoid.Died` e em **todo**
caminho de saída (§12.6).

---

## Substituições padrão (passe §12.12.2)

| Achado | Correção |
|---|---|
| `:Emit(n)` no servidor | `Enabled = true/false` + `Rate`; burst pré-criado e reusado |
| `require(<id numérico>)` | Módulo copiado para dentro da Tool, ou efeito reescrito |
| `math.random` em gameplay | Ângulo áureo / Vogel, jitter senoidal por contador, índice sequencial |
| `wait()` · `spawn()` · `delay()` | `task.wait` · `task.spawn` · `task.delay` |
| `tick()` | acumulador `dt` local a partir de zero |
| `:Destroy()` em part/bodymover | `Parent = nil` ou `Debris` |
| `AncestryChanged` para cleanup | `Tool.Destroying` |
| `Instance.new("Explosion")` | `_G.Combate.detectarHumanoides` |
| `ScreenGui` / overlay de tela | Removido — o efeito vive só no mundo 3D |
| Clone para `ServerStorage` / `ReplicatedStorage` | Material fica **dentro da Tool** |
| `+=` · `continue` | Sintaxe expandida |
| `LoadAnimation` | Tabela de poses CFrame para `R6CFrameAnimator` |

---

## Ângulo áureo — a substituição padrão de `math.random`

Mesma dispersão visual do random, determinística e reproduzível:

```lua
local ANGULO_AUREO = 2.39996322972865332  -- rad

local function direcaoVogel(indice, total)
	local angulo = indice * ANGULO_AUREO
	local raio = math.sqrt(indice / math.max(total, 1))
	return Vector3.new(math.cos(angulo) * raio, 0, math.sin(angulo) * raio)
end
```

Para variação entre golpes, **índice sequencial** com módulo:

```lua
contador = contador + 1
local indice = ((contador - 1) % #CICLO) + 1
```

---

## Parâmetros de referência

| Parâmetro | Faixa usual | Nota |
|---|---|---|
| Escala de impacto | 1.5 – 3.0 | acima de 4 come a tela em close |
| Vida de partícula | 0.6 – 1.5 s | acima de 2 s acumula em combate contínuo |
| Raio de área | 12 – 28 studs | acima de 30, o alvo não entende de onde veio |
| Volume de SFX | 0.4 – 0.8 | 1.0 satura junto com o SFX do alvo |
| `RollOffMaxDistance` | 40 – 80 | além disso, som de quem não está na luta |
| Duração de pose | 0.10 – 0.26 s | quadro abaixo de 0.08 s não é percebido |

---

## Nomenclatura (§12.15)

```
NOME_DO_EFEITO/                MAIUSCULA_COM_UNDERSCORE — ex.: SPIRAL_EXPLOSION
Nome_Do_Modelo_De_Origem/      ex.: Jupiter_Great_Pressure_Sword
Poses_[Modelo]_V[X].lua        ex.: Poses_Jupiter_V1.lua
"[NomeDaTool]_[Habilidade]"    chave de recarga — ex.: "AstralPulsar_X"
"[Sistema]_[Efeito]"           modificador — ex.: "Passiva_Frenesi"
```
