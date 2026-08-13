# NOTAS VFX — Faker Tools (o His Cube original)

**Status: CRU.** Nada daqui entrou em Tool.

## As 7 `MeshPart` do `AbbilityClient`

| Mesh | `MeshId` | `TextureID` |
|---|---|---|
| `NeonCube` | `—` | `—` |
| `E` | `rbxassetid://1851169338` | `—` |
| `Erlo` | `rbxassetid://881809484` | `—` |
| `Sphere` | `—` | `—` |
| `Spiral` | `rbxassetid://6494560271` | `—` |
| `WindSphere` | `rbxassetid://5703242100` | `—` |
| `Ring` | `rbxassetid://863344136` | `—` |
| `Mushroom` | `http://www.roblox.com/asset/?id=153994027` | `—` |

São o motivo de este modelo ter entrado. `Sphere` e `Mushroom` já vinham na primeira entrega
do His Cube e estão em uso; as outras **cinco são novas**, e três delas cobrem formas que o
`VFXModule` das Tools deste repositório desenha hoje com `Part` primitiva mais Tween:

| Mesh nova | O que ela substituiria |
|---|---|
| `Ring` | `camadaAnel`, que hoje é um `Part` cilíndrico esticado |
| `Spiral` | `Spiral_Effect` do pack Stella, que é código |
| `WindSphere` | o domo de `Shockwave_Explosion` |

Malha de verdade lê melhor que primitiva esticada — foi o argumento que fez o `VFX_Pack_Meshes`
entrar no Acervo, e vale igual aqui.

## O que NÃO copiar

As 859 linhas de cliente. São 67 `math.random`, 20 `spawn(` e 18 `:Destroy()`, e o desenho
todo é client-side sem nenhum dano por trás — a habilidade não existe do lado do servidor.
O que se aproveita é **malha e forma**, não a lógica.

## Para sair de CRU

Falta autor, licença e conferir no Studio o que `E` e `Erlo` são: o nome não diz.
