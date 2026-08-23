# CHECKLIST DE ENTREGA
**Retro-Verse / Studios** · copiar e preencher a cada Tool entregue

Consolida a Regra nº 1, a Regra nº 2 (ciclo de vida do VFX) e o §14 das DIRETRIZES base.

---

## REGRA Nº 1 — AUTOCONTENÇÃO ABSOLUTA

Roda primeiro. Falhou aqui, o resto não importa.

```bash
bash TESTES/verificar_autocontencao.sh
```

- [ ] Verificador passa sem nenhuma falha
- [ ] Zero `ReplicatedStorage` / `ServerStorage` / `ServerScriptService` em script de Tool
- [ ] Zero `InsertService`, zero `require(<id numérico>)`
- [ ] Zero busca em `workspace` (`FindFirstChild` / `WaitForChild`)
- [ ] Zero referência ao `ACERVO_RETROVERSE`
- [ ] Todo `require` aponta para ModuleScript **filho da própria Tool**
- [ ] Todo `Sound` é filho da Tool (`Tool/SFX/`), clonado — nunca buscado fora
- [ ] Todo mesh, MeshPart, textura, `ParticleEmitter`, `Beam` e `Trail` é filho da Tool
- [ ] Toda pose/animação é tabela CFrame no ModuleScript `Poses`, dentro da Tool
- [ ] **Zero** menção a `_G.Combate` — a global foi aposentada

**Teste manual que decide:**

- [ ] **Tool sozinha em place vazio → funciona por inteiro**
- [ ] `ACERVO_RETROVERSE` deletado → funciona
- [ ] Place vazio, sem `RetroVerse_VFX` montado → a Tool monta o dela e funciona
- [ ] `ReplicatedStorage` e `ServerStorage` vazios → funciona

---

## ENTREGA — o `.rbxmx` da Tool montada

```bash
python3 FERRAMENTAS/montar_rbxmx.py
python3 TESTES/verificar_rbxmx.py
```

- [ ] Existe um `.rbxmx` por Tool, na pasta da Tool
- [ ] Foi **gerado pelo montador**, não editado à mão
- [ ] `verificar_rbxmx.py` passa sem nenhuma falha
- [ ] A fonte embutida bate byte a byte com os `.lua` do repositório
- [ ] `Handle`, `Value`s, os 5 scripts, `VFXRemote` e `SFX/` estão dentro do arquivo
- [ ] **Importar o `.rbxmx` sozinho num place vazio → a Tool funciona por inteiro**

---

## ANIMAÇÃO R6 (`REGRA_ANIMACAO_R6.md`)

```bash
python3 TESTES/verificar_poses.py
```

- [ ] `verificar_poses.py` passa sem nenhuma falha
- [ ] O `R6CFrameAnimator` dentro da Tool é o **V2 canônico**, byte a byte
- [ ] Zero escrita em `Motor6D.C0`; zero `Animation` / `LoadAnimation`
- [ ] Toda junta citada está entre as seis do animator
- [ ] Nenhuma sequência é inteiramente neutra — **animação morta não é animação**
- [ ] Sequência encadeada por `PlaySequence`/`PlayTrack`, nunca por `task.wait(passo…)`
- [ ] Até ~10 beats → `PlaySequence`; acima disso → `PlayTrack`
- [ ] Se usa perna: é solta no fim (`ReleaseLegs`, ou via `PlaySequence`)
- [ ] `rig:Destroy()` ligado em `Unequipped`, `Destroying` **e** `Died`

**Teste manual:**

- [ ] Equipar e andar/correr/pular → caminhada normal
- [ ] Tocar sequência com perna, esperar acabar, **andar de novo** → voltou ao normal
- [ ] Desequipar no meio da sequência → nada fica preso
- [ ] Morrer no meio → respawn limpo, sem `Weld` órfão
- [ ] O dano entra no **quadro de impacto**, não no fim da animação

---

## CÂMERA DE CUTSCENE (`REGRA_CAMERA_DE_CUTSCENE.md`)

Só se a Tool tiver cutscene. Se não tiver, pular a seção inteira.

- [ ] Toda escrita em câmera está em `LocalScript` — zero `Camera` em Server Script
- [ ] O servidor manda **beat nomeado**, nunca `CFrame` de câmera
- [ ] `CameraType` anterior é guardado e restaurado (não `Custom` chutado)
- [ ] `FieldOfView` volta ao valor base
- [ ] Desligada em `Unequipped`, `Destroying` e morte
- [ ] É pulável, e o pulo **não** encurta a timeline do servidor
- [ ] Zero `ScreenGui` / `ColorCorrection` / `Blur` / `Sky`

**Teste manual:**

- [ ] Cutscene inteira → câmera volta sozinha, com `CameraType` e FOV originais
- [ ] Desequipar no meio → câmera volta na hora
- [ ] Morrer no meio → câmera volta, respawn normal
- [ ] Dois jogadores, um pula e o outro não → a timeline dos dois termina junto

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

## Depósito de VFX (Regra nº 2)

- [ ] `ChaveVFX` (StringValue) presente na Tool, e a chave é única no repositório
- [ ] Quem instala é **Server**, nunca Client — Client não replica
- [ ] A pasta **cria ou reutiliza** — a primeira Tool monta, as outras usam
- [ ] Quem lê tem **duas portas**: depósito primeiro, interior da Tool depois
- [ ] **Ninguém apaga a pasta**: ela é do MODELO, e outro jogador pode estar usando
- [ ] Duas Tools iguais: uma guarda e morre, a outra continua desenhando

## Todas as Tools

- [ ] Zero `require` de qualquer coisa fora da Tool
- [ ] Zero `require(<id numérico>)` externo
- [ ] Zero menção a `_G.Combate` — a global foi aposentada
- [ ] Bloco `CFG` no topo; **zero números mágicos** no corpo
- [ ] `ARQUETIPO` declarado
- [ ] Zero efeito colateral fora da Tool
- [ ] Zero leitura do Acervo em runtime

## Dano

- [ ] `TakeDamage`, nunca `Health = Health - x` — `TakeDamage` respeita `ForceField`
- [ ] Etiqueta `creator` escrita na vítima, com prazo pelo `Debris`
- [ ] Alvo por `workspace:GetPartBoundsInRadius` com `OverlapParams`, nunca varredura do mundo
- [ ] `Instance.new("Explosion")` substituído por consulta espacial

## Escudo, redução, buff ou ragdoll — tudo que TEM VOLTA

- [ ] O valor de ANTES é guardado, e é ELE que volta — nunca um número fixo
- [ ] Guarda contra empilhar (atributo ou flag): dois efeitos em cima do mesmo alvo
      não podem gravar o estado já modificado como "o de antes"
- [ ] A volta acontece em `Tool.Destroying`, `Humanoid.Died` **e em todo caminho de saída**
- [ ] Zero registro órfão (efeito sem volta = permanente)
- [ ] Ragdoll: `rig:CancelSequence()` + `rig:ReleaseLegs()` ANTES de ligar

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

- [ ] **Tool sozinha em place vazio → funciona por inteiro** (Regra nº 1)
- [ ] **Acervo deletado do place → toda Tool continua funcionando**
- [ ] **Place vazio → a Tool funciona por inteiro, sem nada montado fora dela**
- [ ] Duas cópias na mochila → a recarga global trava as duas
- [ ] Desequipar durante a recarga → a recarga não zera
- [ ] Aliado do mesmo time e alvo com `ForceField` → não recebem dano
- [ ] Morte pela Tool → tag `creator` no Humanoid, com o jogador certo

---

## Relatório (§13)

```
## Arquivos .rbxmx entregues
  [NomeDaTool].rbxmx — [tamanho] — [nº de scripts embutidos]

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
