# TESTES

Bancada de verificação. **Nada aqui vai para o place.**

```bash
bash TESTES/verificar_autocontencao.sh     # Regra nº 1 — roda primeiro
lua5.4 TESTES/harness_NucleoCombate.lua    # pipeline de dano do Núcleo
```

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

**Limite conhecido:** é lint por texto, não análise de fluxo. Ele pega
`local x = game:GetService("ReplicatedStorage")`, mas não rastreia o uso de `x` depois.
A guarda de `_G.Combate` é aceita se houver `if _G.Combate` até 15 linhas acima.
O checklist manual continua valendo — o verificador reduz o esforço, não o substitui.

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
