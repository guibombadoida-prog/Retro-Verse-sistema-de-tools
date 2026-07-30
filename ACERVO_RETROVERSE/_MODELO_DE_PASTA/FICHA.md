# Modelo: [Nome Do Modelo De Origem]

> Molde de `FICHA.md` (§12.16.3). Copiar esta pasta inteira ao importar um modelo novo,
> renomear para `Nome_Do_Modelo_De_Origem/` e preencher.

- Autor original:
- Origem:                    (Toolbox / arquivo .rbxm / URL)
- Licença / permissão:
- Data de entrada:           AAAA-MM-DD
- Status: CRU                (CRU | LIMPO | APROVADO)
- Violações corrigidas:
- Excluído do acervo:
- Já usado em:

---

> ⚠️ **Sem os quatro campos** — autor, origem, licença, data — o material fica **CRU**
> e **não pode entrar em Tool** (§12.12.3).

## Conteúdo

| Efeito | Tipo | Status | Já usado em |
|---|---|---|---|
| | VFX / SFX / R6_CFRAME | CRU | |

## Passe de conformidade (§12.12.2)

Marcar cada achado e o que foi feito. O que não foi encontrado, marcar como não aplicável.

- [ ] `:Emit(n)` no servidor → `Enabled` + `Rate`, burst pré-criado
- [ ] `require(<id numérico>)` → módulo copiado para dentro da Tool, ou efeito reescrito
- [ ] `math.random` em gameplay → ângulo áureo / índice sequencial
- [ ] `wait()` / `spawn()` / `delay()` → `task.*`
- [ ] `tick()` → acumulador `dt` a partir de zero
- [ ] `:Destroy()` em part/bodymover → `Parent = nil` / `Debris`
- [ ] `AncestryChanged` → `Tool.Destroying`
- [ ] `Instance.new("Explosion")` → `_G.Combate.detectarHumanoides`
- [ ] `ScreenGui` / `ColorCorrection` / `Sky` → removidos
- [ ] Clone para `ServerStorage` / `ReplicatedStorage` → material fica dentro da Tool
- [ ] `+=` / `continue` → sintaxe expandida
- [ ] `LoadAnimation` → tabela de poses CFrame
- [ ] **Zero lógica de combate importada** — só o que se vê e se ouve

Status só vira **APROVADO** depois de testado em jogo.
