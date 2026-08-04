# PocoDeMassa

Tool autocontida do conjunto **Gravidade e Telecinese**.

## Hierarquia

```
PocoDeMassa (Tool)
├── Handle (Part)
├── DamageClass (StringValue = Debuff)
├── EnergyCost (NumberValue = 0)
├── RecargaGlobal (NumberValue = 16)
├── PocoDeMassa_Server_V1 (Script)
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

- `DamageClass`: `Debuff`
- `EnergyCost`: `0`
- `RecargaGlobal`: `16`

## Entrada

- Primária: `Tool.Activated`
- Extra: tecla `X` via `AcaoRemote`
