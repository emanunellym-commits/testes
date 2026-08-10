# Notas de segurança V10

Antes de produção pública:

1. Use HTTPS em todas as APIs.
2. Use um domínio próprio.
3. Coloque PostgreSQL em rede privada.
4. Não exponha Redis/PostgreSQL à internet.
5. Armazene secrets em secret manager.
6. Nunca versione:
   - firebase-service-account.json
   - .env
   - keystores
   - chaves privadas
7. Configure backup e restauração.
8. Adicione logs de auditoria administrativos.
9. Implemente refresh tokens rotativos.
10. Faça revisão independente de segurança.

## E2EE
Não implemente algoritmos criptográficos manualmente.
O scaffold da V10 serve apenas para encaixar uma biblioteca/protocolo auditado.
