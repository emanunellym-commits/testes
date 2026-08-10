# LiveChat V13 Online Backend

Servidor WebSocket leve para teste real entre dois celulares.

## Rodar localmente

```bash
cd online-backend
npm install
npm start
```

Por padrão usa a porta `8080`.

## Teste de saúde

Abra:

```text
http://localhost:8080/health
```

## Hospedar

Este diretório pode ser publicado em um serviço que aceite Node.js e WebSocket.

Configuração típica:

- Root directory: `online-backend`
- Build command: `npm install`
- Start command: `npm start`
- Port: usar a variável `PORT` fornecida pelo serviço

Depois copie o endereço WebSocket público, por exemplo:

```text
wss://seu-app.onrender.com
```

No APK V13, informe esse endereço na tela inicial em `Servidor WebSocket`.

## Limitações da V13

Esta primeira versão online é propositalmente simples:

- usuários identificados por apelido;
- presença online em memória;
- mensagens em tempo real;
- Chamar Atenção;
- sem banco de dados;
- sem histórico após reinício do servidor;
- sem autenticação por senha.

A próxima etapa pode adicionar contas, PostgreSQL, histórico e mídia.
