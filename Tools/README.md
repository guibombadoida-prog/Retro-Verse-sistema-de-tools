# Tools

Uma pasta por Tool entregue. `_TEMPLATE_Tool/` é o molde — **não é uma Tool**, não vai para o place.

```
Tools/
├── _TEMPLATE_Tool/          molde (§12.10)
└── [NomeDaTool]/
    ├── ESTRUTURA.md         hierarquia real desta Tool + Values declarados
    ├── [NomeDaTool]_Server_V[X].lua
    ├── Client.lua
    ├── R6CFrameAnimator.lua
    ├── Poses_[Modelo]_V[X].lua
    └── VFXModule.lua
```

## Regra de ouro

**Apague o `ACERVO_RETROVERSE` inteiro do place — toda Tool aqui continua funcionando.**
O material audiovisual é *copiado para dentro* da Tool na montagem. O Acervo é prateleira de
edição, nunca dependência de runtime (§12.16.4).

## Versionamento

V1 → V2 → V3, sequencial, incrementado a cada modificação. O arquivo antigo é **substituído** e a
substituição é declarada no relatório de entrega (§13).

## Antes de abrir uma Tool nova

1. Ler `ACERVO_RETROVERSE/_INDICE.md` — o efeito talvez já exista, testado e APROVADO.
2. Copiar `_TEMPLATE_Tool/`, renomear, trocar `Template` em todos os arquivos.
3. Declarar `DamageClass`. Sem ele, todo bônus por classe do jogo fica inerte (§12.4).
4. Fechar com o `CHECKLIST_ENTREGA.md` e com o **Delta do Acervo**.
