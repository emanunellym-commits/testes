# 2FA — V11

No `.env`, defina uma chave longa e aleatória:

```env
TWO_FACTOR_MASTER_KEY="uma-chave-grande-aleatoria-e-secreta"
```

Essa chave protege o segredo TOTP armazenado no banco.

Em produção:
- armazene a chave em secret manager;
- faça backup seguro;
- nunca envie essa chave ao app;
- limite tentativas de código 2FA;
- ofereça códigos de recuperação.
