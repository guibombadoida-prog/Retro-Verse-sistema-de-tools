# Modelo: Danilo — Escudos V4 (remasterizada)

- Autor original:            **Danilo** / enviado pelo dono do repositório
- Origem:                    `DANILO_TOOLS_ESCUDOS_V4.rbxmx` — 7 Tools num arquivo
- Licença / permissão:       material do próprio projeto
- Data de entrada:           2026-08-05
- Status:                    APROVADO — é a base clonada em `Tools/`
- Onde vive:                 `MODELOS_ENTRADA/Danilo_Escudos_V4/` · clonado em `Tools/`

## O que saiu daqui

As **7 Tools** de `Tools/`, clonadas byte a byte por `FERRAMENTAS/clonar_tool.py`:

`Salvador` · `Proteção` · `Escudo Skate` · `Escudo Bumerangue` · `Escudo Bloqueador` ·
`Escudo Cyclone` · `Escudo Partido`

Handle, `SpecialMesh`, Model, `Sound` e `Value`: **intactos, da origem**. A única coisa
reescrita foi o `Source` do `VFXModule`, para ligar o pack de VFX compartilhado.

Censo conferido contra a origem: 7 `Tool`, 7 `Part`, 7 `SpecialMesh`, 79 `Sound`,
21 `ModuleScript`, 14 `RemoteEvent`, 14 `StringValue`, 14 `NumberValue`, 7 `Script`,
7 `LocalScript` — idêntico, e os `SpecialMesh` batem propriedade a propriedade.

## Achados não corrigidos

Estão registrados porque são reais, e **não foram tocados** por estarem fora do que foi
autorizado nesta leva (só o VFX):

| Achado | Onde | Custo |
|---|---|---|
| `ToolTip` vazio | as 7 Tools | a mochila mostra a Tool sem descrição |
| Servidor move `Part` ancorada por frame | Bumerangue, Partido, Proteção, Salvador | replica a ~20 Hz sem interpolação — é o "não está fluido" |
