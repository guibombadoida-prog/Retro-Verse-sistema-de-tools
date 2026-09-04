# Origem — Danilo_Escudos_V4 (remasterização de referência)

| Campo | Valor |
|---|---|
| Arquivo | `DANILO_TOOLS_ESCUDOS_V4.rbxmx` |
| Data de entrada | 2026-08-05 |
| Conteúdo | 7 Tools · 79 Sound · 21 ModuleScript |

**Não foi convertido em Tool.** Entrou como **referência de qualidade** — foi
lido para descobrir por que o VFX e a animação do nosso conjunto Escudos
estavam duros. Três lições saíram daqui e estão aplicadas:

1. **Impacto é composição em camadas**, não um efeito só: flash → disco →
   linhas → detrito, com durações diferentes. Uma camada só lê chapado por
   melhor que seja a curva do emissor.
2. **Pose de pack se lê como DADO, não se copia como pose.** A V4 mapeia
   keyframes para poses nomeadas. Nós fomos além: medimos a *cadência* e
   autoramos silhueta nova.
3. **`:Emit()` no cliente é legítimo.** A proibição do projeto é para Server
   Script — no cliente não há replicação envolvida.

Ver `Tools/ESCUDOS.md`, seção "V2 — o que a remasterização ensinou".
