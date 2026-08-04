# MarionetePsi

Tool autocontida do conjunto **Gravidade e Telecinese**.

## Hierarquia

```
MarionetePsi (Tool)
├── Handle (Part)
├── DamageClass (StringValue = Summon)
├── EnergyCost (NumberValue = 0)
├── RecargaGlobal (NumberValue = 16)
├── MarionetePsi_Server_V1 (Script)
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

- `DamageClass`: `Summon`
- `EnergyCost`: `0`
- `RecargaGlobal`: `16`

## Entrada

- Primária: `Tool.Activated`
- Extra: tecla `X` via `AcaoRemote`
