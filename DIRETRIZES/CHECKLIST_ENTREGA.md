# CHECKLIST DE ENTREGA
**Retro-Verse / Studios** · copiar e preencher a cada Tool entregue

Consolida o §14 das DIRETRIZES base e o §12.14 da REGRA 12 V3.

---

## Base da Tool (§14)

- [ ] `CanBeDropped = false`
- [ ] `RequiresHandle = true`
- [ ] Handle presente (`Part` ou `MeshPart`), nome **exato** `"Handle"`
- [ ] `ToolTip` definido e descritivo
- [ ] Debounce com `Enabled`
- [ ] **`Tool.Enabled` NÃO resetado em `Unequipped`**
- [ ] `Equipped` / `Unequipped` tratados
- [ ] Propriedades `Grip` configuradas **no servidor** (não replicam do cliente)
- [ ] Versionamento e nomenclatura corretos
- [ ] Testada em equip / unequip / activate

## Núcleo (§12.14)

- [ ] `NucleoCombate` (Script) em `ServerScriptService`, **um só**, não Disabled
- [ ] `_G.Combate` disponível — confirmado no Output: `[NucleoCombate] _G.Combate pronto — v3`
- [ ] Zero ModuleScript de combate exigido por Tool

## Todas as Tools

- [ ] Zero `require` do Núcleo
- [ ] Zero `require(<id numérico>)` externo
- [ ] **`DamageClass` declarado** ← sem ele, todo bônus por classe fica inerte
- [ ] Zero `canDamage` / `IsTeamMate` / `TagHumanoid` reimplementados
- [ ] Bloco `CFG` no topo; **zero números mágicos** no corpo
- [ ] `ARQUETIPO` declarado
- [ ] Zero efeito colateral fora da Tool
- [ ] Zero leitura do Acervo em runtime

## Modo preciso (§12.6) — opcional, mas esperado em gear editável

- [ ] `_G.Combate.calcular` antes do `TakeDamage`, com guarda `_G.Combate and`
- [ ] `Instance.new("Explosion")` substituído por `detectarHumanoides`

## Escudo, redução ou buff

- [ ] Registro via `_G.Combate.registrar*`
- [ ] Função de cancelamento guardada em variável local
- [ ] Cancelamento em `Tool.Destroying`, `Humanoid.Died` **e em todo caminho de saída**
- [ ] Zero registro órfão (registro sem cancelamento = escudo permanente)

## VFX

- [ ] `VFXRemote` unidirecional — **zero `OnServerEvent` nele**
- [ ] Payload de dados puros — **zero `Instance`**
- [ ] Zero `:Emit()` no servidor
- [ ] Ordem §8 V2 respeitada: **SFX → física → VFX → dano**

## Sintaxe proibida (varredura)

```bash
grep -rn 'math\.random\|tick()\|[^.]wait(\|spawn(\|delay(' Tools/[NomeDaTool]/
grep -rn ':Destroy()\|AncestryChanged\|Instance\.new("Explosion")' Tools/[NomeDaTool]/
grep -rn 'ScreenGui\|ColorCorrection\|LoadAnimation' Tools/[NomeDaTool]/
grep -rn '+=\|-=\|continue' Tools/[NomeDaTool]/
grep -rn 'require(' Tools/[NomeDaTool]/       # só Poses / VFXModule / R6CFrameAnimator
```

- [ ] Varredura limpa

## Material de terceiros (§12.12)

- [ ] Só VFX, SFX e pose R6 CFrame — **zero lógica de combate importada**
- [ ] Passe §12.12.2 executado e registrado na `FICHA.md`
- [ ] Ficha com **autor, origem, licença e data**
- [ ] Status **APROVADO** antes de entrar na Tool

## Acervo (§12.16) — obrigatório em toda entrega

- [ ] Busca no `_INDICE.md` feita **antes** de criar efeito novo
- [ ] Todo VFX, SFX e pose R6 da entrega depositado na pasta do modelo
- [ ] `FICHA.md` preenchida e `_INDICE.md` atualizado
- [ ] Acervo não referenciado por nenhum script em runtime

## Testes de aceitação

- [ ] **Acervo deletado do place → toda Tool continua funcionando**
- [ ] **Núcleo removido → a Tool continua funcionando, só sem os bônus**
- [ ] Duas cópias na mochila → a recarga global trava as duas
- [ ] Desequipar durante a recarga → a recarga não zera
- [ ] Aliado do mesmo time e alvo com `ForceField` → não recebem dano
- [ ] Morte pela Tool → tag `creator` no Humanoid, com o jogador certo

---

## Relatório (§13)

```
## Scripts Entregues — [Nome da Tool]
Versão Atual: V[X]

Scripts Novos:
Scripts Modificados:
Scripts Substituídos:
Scripts Reutilizados:

## Delta do Acervo
  Entrou:
  Reusado:
  Status:
```

- [ ] **Delta do Acervo preenchido** — sem ele a entrega está incompleta
