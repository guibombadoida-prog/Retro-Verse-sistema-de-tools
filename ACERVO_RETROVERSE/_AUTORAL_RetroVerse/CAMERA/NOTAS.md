# Câmera de cutscene — o molde do projeto

`SeriousMode_CutsceneCam_V1.lua` — **LocalScript**, filho direto da Tool, nome de objeto
`CutsceneCam`. É o molde de toda câmera dramática do repositório.

## A regra que sustenta o arquivo: câmera é 100% cliente

O servidor **nunca** toca em câmera. Não existe câmera "do jogo": existe uma por cliente,
e ela é do dono daquele cliente. O servidor manda **beats** por `RemoteEvent`; quem
interpreta é o LocalScript.

```
Servidor                          Cliente
  |  CutsceneRemote:FireClient(jogador, "START", 15)
  |------------------------------------->  prende a câmera, começa a órbita
  |  ... "ORBIT"                        >  troca o estágio da órbita
  |  ... "CLOSE"                        >  fecha o FOV (tensão)
  |  ... "PUNCH"                        >  estoura o FOV (impacto)
  |  ... "STOP"                         >  devolve a câmera ao jogador
```

Beat é **nome**, não CFrame. O servidor não sabe onde a câmera está, e não deve saber.

## `workspace.CurrentCamera` não viola a Regra nº 1

Parece leitura do mundo, e a Regra nº 1 proíbe ler o mundo. Não é o mesmo caso:

- `workspace:FindFirstChild("PastaDeEfeitos")` é **dependência**: se o place não tiver
  aquela pasta, a Tool quebra. É isso que a regra proíbe.
- `workspace.CurrentCamera` é um **singleton por cliente**, que existe em todo place,
  sempre, sem ninguém precisar depositar nada. É acesso de serviço, igual a
  `Players.LocalPlayer` ou `game:GetService("RunService")`.

O teste da Regra nº 1 continua passando: arraste a Tool sozinha para um place vazio e a
cutscene roda inteira.

## As quatro obrigações de qualquer câmera de cutscene

1. **Guardar e restaurar o `CameraType`.** Guardar o valor anterior antes de pôr
   `Scriptable`, e devolver exatamente aquele valor no fim — não `Custom` chutado.
2. **Restaurar o `FieldOfView`.** Sair da cutscene com FOV 38 deixa o jogador de telefoto
   pelo resto da partida.
3. **Desligar em `Unequipped`, `Destroying` e morte.** Câmera presa com a Tool fora da mão
   é o pior bug possível: o jogador perde o controle e não tem como recuperar.
4. **Ser pulável.** Segurar `E` por 1,5 s solta a câmera. E o pulo é **puramente visual**:
   solta a câmera, não encurta a timeline do servidor. Se o skip mexesse no servidor,
   ele viraria vantagem de combate.

O `stopCutscene()` deste arquivo faz as quatro, e está ligado em `Tool.Unequipped` e
`Tool.Destroying` nas duas últimas linhas. Copie esse fim de arquivo junto.

## As técnicas que valem reuso

| Técnica | Como | Por que |
|---|---|---|
| Órbita bezier de 2 estágios | `bezier(t, p0, p1, p2)` sobre pontos derivados do HRP | arco de grua; linha reta lê como câmera de vigilância |
| Contraste de FOV | 70 base → **38** na carga → **96** no burst → 70 | é o contraste que vende o golpe, não o valor absoluto |
| Shake por acumulador | `sin(elapsed*24)*0.03*t + sin(elapsed*41)*0.012*t` | duas frequências incomensuráveis não repetem padrão; sem `math.random` |
| Roll sutil | `sin(t*π) * rad(3)` | sobe e volta a zero sozinho nas pontas |
| Pontos determinísticos | `hrp.CFrame * CFrame.new(...)` | mesma câmera toda vez; replay idêntico |

O shake cresce com `t` de propósito: a tensão sobe junto com a carga.

## Proibições que continuam valendo dentro da câmera

Nada de `ScreenGui`, `ColorCorrection`, `BlurEffect` ou `Sky`. Efeito de cutscene é
**enquadramento e lente** — posição, alvo, FOV, roll, shake. Pós-processamento é global
ao cliente e vaza para fora da Tool.

`math.random` e `tick()` seguem proibidos aqui como em todo lugar: shake vem de senoide
com acumulador `dt` a partir de zero.

## Status

**LIMPO** — passou o crivo §12.12.2, ainda não rodou em jogo. Nenhuma Tool do
repositório usa cutscene ainda; entra como molde para a próxima que precisar.
