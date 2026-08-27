# MALHAS — `Time_Tools`

| Nome | MeshId | Textura | Onde é usado no conjunto novo |
|---|---|---|---|
| `ARC` | `1204910704` | — | Handle do `Cajado Celeste` (vem inteiro da origem) |
| `Meshes/C` | `3084463904` | — | Handle do `Cajado Celeste` (vem inteiro da origem) |
| `Photon` | `4610890646` | — | `Cajado Celeste` — a chuva de fótons |
| `CeleCutter` | `2578685003` | — | `Cajado Celeste` — a lâmina da lua |
| `SpotLight` | `1251157745` | — | `Cajado Celeste` — o holofote |
| `Ring` | `559831844` | — | `Fim do Relogio` — o mostrador |

E mais um que NÃO está numa `MeshPart`, e por isso quase passou batido: a esfera da parada do
tempo é um `SpecialMesh` criado em código dentro de `Para o tempo/Main`:

| `3732570516` | textura `5850567969` | a esfera de `Parada do Tempo` |

Id de malha não se inventa: malha invisível é o equivalente do som mudo, e nenhum verificador
estático pega nenhum dos dois.
