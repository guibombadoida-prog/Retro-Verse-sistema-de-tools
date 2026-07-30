# TESTES

Bancada de verificação. **Nada aqui vai para o place.**

```bash
lua5.4 TESTES/harness_NucleoCombate.lua
```

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
