# MaoTelecinetica

Tool autocontida do conjunto **Gravidade e Telecinese**.

## Hierarquia

```
MaoTelecinetica (Tool)
├── Handle (Part)
├── DamageClass (StringValue = Magic)
├── EnergyCost (NumberValue = 0)
├── RecargaGlobal (NumberValue = 16)
├── MaoTelecinetica_Server_V1 (Script)
├── Client (LocalScript)
├── R6CFrameAnimator (ModuleScript)
├── VFXModule (ModuleScript)
├── Poses (ModuleScript)
├── VFXRemote (RemoteEvent)
├── AcaoRemote (RemoteEvent)
├── SFX/
└── Efeitos/
```

## Valores declarados

- `DamageClass`: `Magic`
- `EnergyCost`: `0`
- `RecargaGlobal`: `16`

## Entrada

- Primária: `Tool.Activated`
- Extra: tecla `X` via `AcaoRemote`
