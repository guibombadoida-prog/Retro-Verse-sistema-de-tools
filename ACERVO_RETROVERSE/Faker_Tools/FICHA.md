# Modelo: Faker Tools — o His Cube ORIGINAL

- Autor original:            **a confirmar** ⚠️
- Origem:                    `Faker_tools.rbxmx`, enviado no lote de 2026-08-13
- Licença / permissão:       **a confirmar** ⚠️
- Data de entrada:           2026-08-13
- Status:                    **CRU**
- Onde vive:                 `MODELOS_ENTRADA/Faker_Tools/` · notas em `VFX/NOTAS.md`

---

## O que é, e por que o nome do arquivo está certo

Uma `Tool` chamada `His Cube` — a **terceira** entrega do His Cube a chegar aqui. E é a mais
importante das três, porque é a **origem**: as outras duas já eram nossa conversão de volta.

| | `Faker_Tools` | `His_Cube` (V1) | `His_Cube_V2` |
|---|---|---|---|
| `Shoot` (servidor) | **40 linhas** | 830 | 830 |
| onde vive a habilidade | `AbbilityClient` + `Client`, **no cliente** | servidor | servidor |
| `TakeDamage` / `Health =` | **zero** | sim | sim |
| pack Stella | não | 40 `ModuleScript` | 40 `ModuleScript` |
| `Vfx pack` | não | não | 121 filhos |

### O `Shoot` inteiro tem 40 linhas, e não causa dano nenhum

```lua
remote.OnServerEvent:Connect(function()
	remote1:FireAllClients()
end)

remote2.OnServerEvent:Connect(function(Client, Key)
	if Client ~= Player or ... then return end
	if Key == Enum.KeyCode.Q then
		if cd1 == false then
			remote3:FireAllClients()
			...delay(15, function() cd1 = false end)
		end
	end
end)
```

É só isto: o servidor recebe um aviso e retransmite. **Nenhuma linha do modelo aplica dano** —
o scan não achou um único `TakeDamage` nem uma escrita em `Health`.

Toda a habilidade está em `AbbilityClient` (365 linhas) e `Client` (431 linhas), do lado do
cliente. Ou seja: **é uma casca de VFX.** Bonita, e sem combate.

Por isso o nome do arquivo faz sentido. Não é acusação de plágio — é a descrição técnica do
que ele é: **fake**, no sentido de que o efeito acontece e nada muda no jogo.

### E o que ele mostra sobre o próprio repositório

A conversão que este repositório fez do His Cube não "melhorou" o original — ela **escreveu o
combate que não existia**. Vale registrar, porque é o tipo de coisa que se esquece: as 830
linhas do nosso `Shoot` não são um refactor das 40, são código novo.

---

## O que vale de verdade: 7 `MeshPart` de VFX

Penduradas no `AbbilityClient`, e é a razão de o modelo ter entrado:

| Mesh | Provável papel |
|---|---|
| `Sphere` | núcleo da explosão |
| `Mushroom` | o cogumelo |
| `Ring` | anel de choque |
| `Spiral` | espiral |
| `WindSphere` | domo de vento |
| `E` · `Erlo` | (nome não diz; conferir no Studio) |

`Sphere` e `Mushroom` já vieram na V1 e estão em uso. As **outras cinco são novas** —
`Ring`, `Spiral` e `WindSphere` cobrem exatamente três formas que o `VFXModule` das Tools
desenha hoje com `Part` primitiva e Tween.

Ver `VFX/NOTAS.md`.

---

## O passe §12.12.2

| Achado | Quantos |
|---|---|
| `math.random` | **67** |
| `spawn(` | 20 |
| `:Destroy()` | 18 |
| `wait()` | 15 |
| `delay(` | 2 |

67 `math.random` em 859 linhas é a maior densidade de sorteio que já entrou — e faz sentido,
porque é VFX puro, onde variação aleatória é a técnica. Na conversão vira ângulo áureo e
jitter senoidal por contador, que é o que garante que **os dois clientes vejam a mesma coisa**.

**Nenhum** `ScreenGui`, `BreakJoints`, `Lighting` ou varredura de `workspace`. Para uma casca
de VFX de 859 linhas, é surpreendentemente contido.

## Segurança

Zero `loadstring`, zero `require(<id numérico>)`, zero `HttpService`, zero webhook, zero
`getfenv`/`setfenv`, e **zero referência a qualquer depósito fora da Tool**. É o modelo mais
limpo desse ponto de vista que já chegou.

## Não vira Tool nova

Já existe His Cube convertido neste repositório. Este entra como **fonte de VFX** e como
registro do que o original era — não como sexta, sétima ou oitava Tool de cubo.

## Passe de conformidade §12.12.2 — NÃO EXECUTADO
