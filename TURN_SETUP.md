# TURN / coturn — LiveChat V10

Arquivos:
- `turn/coturn.conf.example`
- `turn/docker-compose.turn.yml`

Fluxo recomendado:

1. Crie um subdomínio, por exemplo `turn.seudominio.com`.
2. Aponte o DNS para o servidor TURN.
3. Copie:
   `coturn.conf.example` -> `coturn.conf`
4. Troque a senha.
5. Abra portas necessárias no firewall.
6. Suba:
   `docker compose -f docker-compose.turn.yml up -d`

Depois configure o app/backend para utilizar seu TURN.

Para produção em escala, prefira credenciais TURN temporárias em vez de senha fixa no aplicativo.
