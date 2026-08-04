# TESTES

Bancada de verificação. **Nada aqui vai para o place.**

```bash
bash    TESTES/verificar_autocontencao.sh   # Regra nº 1 — roda primeiro
python3 TESTES/verificar_poses.py           # tabelas de pose × animator V2
python3 TESTES/verificar_rbxmx.py           # as Tools entregues
lua5.4  TESTES/harness_NucleoCombate.lua    # pipeline de dano do Núcleo
```

## `verificar_rbxmx.py`

Confere que cada `.rbxmx` é uma Tool conforme e autocontida: raiz `Tool`, `CanBeDropped=false`,
`RequiresHandle=true`, `Handle` com o nome exato, `DamageClass` preenchido, os cinco scripts do
§12.10, `VFXRemote`, os `Sound` citados pelo `CFG`, e nenhuma referência fora da Tool.

A verificação que sustenta a regra de entrega é a **6ª**: a fonte embutida no `.rbxmx` tem de
ser **byte a byte** igual ao `.lua` do repositório. Sem ela, o arquivo entregue vira uma cópia
velha em que ninguém repara.

A **9ª** nasceu de defeito real: **todo VFX transmitido tem de existir no `VFXModule` da
própria Tool**. `VFX.executar` faz `VFX[tipo]` e volta calado se não achar — um tipo herdado de
outro conjunto não quebra nada, não avisa nada, e simplesmente não desenha. Sete Tools
transmitiam dois tipos que não implementavam.

Também confere que cada **conjunto** só tem Tools do seu próprio modelo: Tool de outro modelo
dentro de um conjunto é entrega errada, porque quem importa o arquivo recebe o que não pediu.

Testado contra uma Tool sabotada de propósito: pegou as 5 falhas e saiu com 1.

## `verificar_autocontencao.sh`

Varre `Tools/` e falha se qualquer script referenciar algo **fora da Tool** (Regra nº 1).
Comentários de linha e de bloco são removidos antes da comparação — documentar a proibição
é obrigatório, não é violação.

| Verifica | Achado é falha porque |
|---|---|
| `ReplicatedStorage` · `ServerStorage` · `ServerScriptService` | Depósito de asset fora da Tool |
| `StarterGui` · `StarterPack` · `StarterPlayer` · `Lighting` | Idem |
| `SoundService` como depósito · `InsertService` | Idem |
| Referência a `ACERVO` | O Acervo é prateleira de edição, não runtime |
| `workspace:FindFirstChild` / `WaitForChild` | Ler de `workspace` é dependência (escrever nele é permitido) |
| `require(<id numérico>)` · `require` do Núcleo | Código de fora |
| `require` que não aponte para módulo da própria Tool | Referência externa |
| `_G.Combate.` sem guarda | A Tool tem de funcionar com o Núcleo deletado |
| Escrita em `Motor6D.C0` | Briga com o script `Animate` padrão — a animação treme |
| `Animation` · `LoadAnimation` · `AnimationTrack` | Animação é tabela de poses CFrame |
| `task.wait(passo.…)` encadeando beat | Some ~1 frame por beat; quem encadeia é o animator |
| `Camera` em Server Script | Câmera é 100% cliente; o servidor manda beat |
| `CameraType` sem `Unequipped` **e** `Destroying` | Câmera presa é bug sem saída para o jogador |

`workspace.CurrentCamera` em `LocalScript` **não** é falha: é singleton por cliente, como
`Players.LocalPlayer`. Em Server Script é.

Testado contra um violador proposital: pegou as 4 falhas novas e saiu com 1.

**Limite conhecido:** é lint por texto, não análise de fluxo. Ele pega
`local x = game:GetService("ReplicatedStorage")`, mas não rastreia o uso de `x` depois.
A guarda de `_G.Combate` é aceita se houver `if _G.Combate` até 15 linhas acima.
O checklist manual continua valendo — o verificador reduz o esforço, não o substitui.

## `verificar_poses.py`

Confere cada `Poses_*.lua` contra o `R6CFrameAnimator_V2`.

| Verifica | Achado é falha porque |
|---|---|
| Junta citada existe no animator | Nome errado é **erro silencioso**: o animator ignora e a pose não sai |
| `pose = "X"` de sequência aponta para pose existente | O beat é pulado sem aviso |
| Nenhuma sequência é inteiramente neutra | Sequência que não move nada é **animação morta** |
| Sequência usa `time`/`style`/`dir`, não `duracao`/`easing` | Formato do V1; o V2 ignora as chaves velhas |
| Pose com perna cita `ReleaseLegs` | Perna soldada permanentemente trava a caminhada |

A terceira checagem nasceu de defeito real: duas Tools tinham a sequência inteira com as
poses **iguais à base do Weld**. As habilidades não animavam nada, e o Studio não
reclamaria disso — pose neutra é pose válida. Só uma comparação contra a base pega.

Testado contra uma tabela sabotada de propósito: pegou junta inexistente, pose fantasma,
chaves do V1 e sequência morta, e saiu com 1.

## `harness_NucleoCombate.lua`

Stubs mínimos da API Roblox para exercitar o pipeline de dano do Núcleo fora do Studio.

| Verifica | Seção |
|---|---|
| Aumento aditivo, com teto de +300% | §12.5 |
| Redução multiplicativa, com teto de 90% — três de 40% dão 78,4%, nunca 120% | §12.5 |
| Escudo consumido **antes** de a vida assentar | §12.5 |
| Modificadores entram no mesmo grupo aditivo | §12.5 |
| Cancelamentos idempotentes, sem resíduo | §12.6 |
| Guardas de entrada (dano zero, negativo, alvo nulo) | §12.6 |
| Recarga global por chave, isolada entre chaves | §12.9 |

**Rodar depois de qualquer edição em `NucleoCombate.lua`.**

## O que a bancada NÃO cobre

| Fora de alcance | Por quê | Onde testar |
|---|---|---|
| Modo observado (§12.8) | Depende de `HealthChanged` real | Studio |
| Detecção em área | Depende de `GetPartBoundsInRadius` real | Studio |
| Trava de `Tool.Enabled` em clones | Depende de Backpack real | Studio |
| Tag `creator` | Depende de hierarquia de Instance real | Studio |

Esses estão nos **testes de aceitação** do `DIRETRIZES/CHECKLIST_ENTREGA.md`. A bancada cobre a
aritmética; o Studio cobre a integração. Nenhum dos dois substitui o outro.

## Varredura de sintaxe proibida

```bash
luac5.4 -p $(find . -name "*.lua")     # sintaxe

grep -rn 'math\.random\|tick()\|[^.k]wait(\|[^.]spawn(\|[^.]delay(' --include=*.lua .
grep -rn ':Destroy()\|AncestryChanged\|Instance\.new("Explosion")' --include=*.lua .
grep -rn 'ScreenGui\|ColorCorrection\|LoadAnimation\|:Emit(' --include=*.lua .
```

Toda ocorrência precisa ser comentário/documentação, nunca código.
