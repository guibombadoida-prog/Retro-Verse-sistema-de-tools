# Modelo: Trident

- Autor original:            **a confirmar** ⚠️ — sem cabeçalho de crédito em nenhum script
- Origem:                    `trident.rbxmx`
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Trident/` · notas em `R6_CFRAME/` e `SFX/`

---

## O que é

**Não é uma Tool.** São scripts soltos que se colam ao `Character`:

```
Determination [Script]        2034 linhas — o corpo inteiro do sistema
camshake / camshakealt        LocalScript de tremor de câmera
crefunnies                    LocalScript de 668 linhas (duplicado em duas instâncias)
input                         LocalScript de entrada
weapon [Model] · bigtrident · fire · hand · ball · ellipses · fireball
flash · guipopup [ScreenGui] · textgui [BillboardGui]
```

89 instâncias, 3900 linhas de Lua, 6 `ParticleEmitter`, 2 `Sound`, 2 `Trail`.

O `Determination` abre com o padrão clássico de script de personagem:

```lua
char = script.Parent
game:GetService("RunService").Heartbeat:wait()
script.Parent = nil
```

Ele escreve direto em `Motor6D.C0` — **214 ocorrências** — e monta a animação R6 à mão,
quadro a quadro, dentro de um loop de `Heartbeat`. É exatamente a família do Xester.

## Habilidades declaradas

`coloredswing` · `handfire` · `earthquake` · `ultrastab` · `swing` — mais o apoio
(`effect`, `kill`, `region3damage`, `rayCast`, `guichat`, `randomquote`, `chatmessage`).

**Cinco habilidades.** Cai dentro do piso 3 / teto 7 da regra de distribuição: cinco Tools,
uma por habilidade, sem excedente.

## O que este modelo é bom para

**Fonte de pose R6.** É o segundo maior banco de CFrame que entrou aqui depois do Saitama, e
o único com golpe de arma de haste (`ultrastab`, `swing`). Os 214 `C0 =` são poses
autorais legíveis — dá para medir a gramática deles como se mediu a do Saitama
(`FERRAMENTAS/medir_gramatica_r6.py`).

**Fonte de câmera.** `camshake` e `camshakealt` são a terceira e quarta implementação de
tremor a entrar no repositório, e a gramática de cutscene tem só três fontes hoje.

## O que precisa ser jogado fora

| Achado | Quantos | Por quê |
|---|---|---|
| `wait()` | 136 | proibido — `task.wait` |
| `:Destroy()` | 98 | proibido — `Parent = nil` / `Debris` |
| `math.random` | 24 | proibido em gameplay — ângulo áureo / jitter senoidal |
| `tick()` | 9 | proibido — `os.clock()` / acumulador `dt` |
| `setfenv` | 6 | ver abaixo |
| `ScreenGui` (`flash`, `guipopup`) | 2 | proibido dentro de Tool |
| escrita em `Motor6D.C0` | 214 | proibido — `R6CFrameAnimator` V2 solda `Weld` próprio |

### Os 6 `setfenv` — o que são

Estão todos no `crefunnies`, e são **contorno de FilteringEnabled**, não backdoor:

```lua
game:GetService("RunService").Heartbeat:Wait()
script.Parent = nil
local setfv = setfenv
setfenv = setfv
local plr = game:GetService("Players")[script.plr.Value]
if plr == game:GetService("Players").LocalPlayer then
```

e, dentro de um `RenderStepped`, um `setfenv(0, {})` para limpar o ambiente global.

**Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook** — o
scan não achou nada que saia da máquina. Mesma família dos wrappers que já vieram no Xester.
Nada disso sobrevive à conversão: a Tool não precisa de contorno de FE, porque ela nasce
com servidor e cliente separados por `RemoteEvent`.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO

Nada daqui entra em Tool antes do passe. Ver `R6_CFRAME/NOTAS.md` para o que vale extrair.
