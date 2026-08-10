# Configuração de SMS — V11

A V11 contém a abstração de SMS, mas não força um fornecedor.

Você pode integrar:
- Zenvia
- Twilio
- Infobip
- AWS SNS
- outro provedor compatível

No `.env`:

```env
SMS_PROVIDER="zenvia"
SMS_API_KEY="..."
SMS_API_SECRET="..."
```

Depois implemente a chamada real em:

`backend/src/sms/sms.service.ts`

Sem configuração, o backend apenas simula o envio e registra no log.
