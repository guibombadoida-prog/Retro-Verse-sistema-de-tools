# REGRA DE ENTREGA — TODO MODELO CONVERTIDO SAI COMO `.rbxmx`
**Retro-Verse / Studios** · regra de entrega

---

## O enunciado

> **Todo modelo convertido é entregue como arquivo `.rbxmx` da Tool montada.**
> Um por Tool, pronto para arrastar para o Studio. `.lua` solto **não é entrega**.

Instrução de montagem não é entrega. Se para usar o resultado alguém precisa criar `Instance`
na mão, colar script por script e criar `Value` por `Value`, a conversão não terminou.

---

## O que o arquivo tem de conter

```
Tool  "[NomeDaTool]"                CanBeDropped=false · RequiresHandle=true · ToolTip
├── Handle                          Part/MeshPart, nome EXATO "Handle"
├── DamageClass · EnergyCost · RecargaGlobal    Values (§12.4)
├── [NomeDaTool]_Server_V[X]        Script       fonte embutida
├── Client                          LocalScript  fonte embutida
├── R6CFrameAnimator · Poses · VFXModule         ModuleScripts, fonte embutida
├── VFXRemote                       RemoteEvent
├── AcaoRemote                      RemoteEvent  só se houver habilidade Extra
├── SFX/                            Folder com os Sound já configurados
└── Efeitos/                        Folder dos moldes visuais
```

**Teste que decide** — o mesmo da Regra nº 1, agora sobre o arquivo:
importe o `.rbxmx` sozinho num place vazio, ponha na `StarterPack`, e **funciona por inteiro**.

---

## O `.rbxmx` é DERIVADO, nunca escrito à mão

O arquivo é gerado a partir dos `.lua` da pasta da Tool:

```bash
python3 FERRAMENTAS/montar_rbxmx.py              # monta todas
python3 FERRAMENTAS/montar_rbxmx.py AvoDoTempo   # monta uma
```

**Editou o `.lua`, roda o montador de novo.** Editar o XML na mão é proibido: cria divergência
silenciosa entre o que está no repositório e o que foi para o Studio — e essa divergência só
aparece quando alguém depura o código errado.

O `.lua` continua sendo a fonte de verdade, e é ele que entra em revisão.

---

## Verificação obrigatória

```bash
python3 TESTES/verificar_rbxmx.py
```

Confere, em cada `.rbxmx`:

| # | Verificação |
|---|---|
| 1 | O XML abre e a raiz é uma `Tool` |
| 2 | `CanBeDropped = false`, `RequiresHandle = true`, `ToolTip` preenchido |
| 3 | Existe `Handle`, com esse nome exato |
| 4 | `DamageClass` declarado e não vazio (§12.4) |
| 5 | Os cinco scripts do §12.10, com o nome de objeto certo |
| 6 | **A fonte embutida é byte a byte igual ao `.lua` do repositório** |
| 7 | `VFXRemote` presente; `AcaoRemote` só onde há Extra que o use |
| 8 | Todo `Sound` citado no `CFG` existe dentro de `Tool/SFX` |
| 9 | Nenhum script referencia depósito fora da Tool (Regra nº 1) |

A verificação 6 é a que sustenta a regra: sem ela, o `.rbxmx` vira uma cópia velha em que
ninguém repara.

---

## Quando o modelo de origem não tem geometria aproveitável

Acontece: `.rbxmx` salvo sem as `SharedStrings` de malha faz toda `UnionOperation` apontar
para um blob de **0 byte**, e no Studio ela aparece como caixa cinza.

Nesse caso o `Handle` é **construído com primitivas** no montador — nunca copiado quebrado.
O achado vai para a `AUDITORIA.md` do modelo, e o `.rbxmx` entregue sai com geometria de
verdade, que é o que a Regra nº 1 exige.

---

## No relatório de entrega

```
## Arquivos .rbxmx entregues
  [NomeDaTool].rbxmx — [tamanho] — [nº de scripts embutidos]
  Montados por: FERRAMENTAS/montar_rbxmx.py
  Verificados por: TESTES/verificar_rbxmx.py — [resultado]
```
