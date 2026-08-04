# PulsoGravitacional

Tool autocontida do conjunto **Gravidade e Telecinese**.

## Hierarquia

```
PulsoGravitacional (Tool)
├── Handle (Part)
├── DamageClass (StringValue = Magic)
├── EnergyCost (NumberValue = 0)
├── RecargaGlobal (NumberValue = 16)
├── PulsoGravitacional_Server_V1 (Script)
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
