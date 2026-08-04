# VFX_Library_V2

- **Autor original:** não declarado no arquivo — provável compilação de free models
- **Origem:** `VFX_Library_V2_com_Logica.rbxmx` (10 MB, XML), enviado pelo autor do projeto
- **Licença / permissão:** a confirmar
- **Data de entrada:** 2026-07-31
- **Destino pretendido:** biblioteca de efeitos para Tools futuras

> ⚠️ Faltam **autor** e **licença**, dois dos quatro campos de §12.12.3.
> Enquanto faltarem, o material fica **CRU** e não entra em Tool nenhuma.

## Formato

`.rbxmx` — XML. Para abrir:

```bash
python3 FERRAMENTAS/ler_rbxmx.py MODELOS_ENTRADA/VFX_Library_V2/VFX_Library_V2_com_Logica.rbxmx
```

## Conteúdo

3.522 instâncias · 38 habilidades em 7 pastas de personagem ·
782 `ParticleEmitter` (416 únicos) · 81 `Trail` · 14 `Beam` · 87 `MeshPart` · 5 `PointLight`

Não há `Tool` no arquivo: é biblioteca de efeitos, não ferramenta pronta.

## ⚠️ Não rode em produção como está

13 `require(<id numérico>)` — execução de código remoto, o mesmo vetor achado no
código remoto. Mais 152 `BreakJoints`, 911 `:Destroy()`, 1113 `math.random`.
Ver `ACERVO_RETROVERSE/VFX_Library_V2/FICHA.md`.

## Já depositado no Acervo

`ACERVO_RETROVERSE/VFX_Library_V2/` — VFX com parâmetros (330 KB de catálogo),
catálogo por habilidade, malhas, SFX e inventário de lógica. Status **CRU**.
