# LiveChat Messenger V10

## Conta
- recuperação de senha por código
- verificação de e-mail
- exclusão de conta com senha + código
- invalidar tokens push após reset de senha

## Segurança
- tokens com hash SHA-256 no banco
- senha com bcrypt
- respostas neutras no "esqueci minha senha"
- suspensão de usuários
- scaffold de identidade E2EE por dispositivo

## Moderação
- denunciar usuário
- denunciar mensagem
- motivos padronizados
- status de denúncia
- ações de moderação
- suspensão temporária ou permanente

## Administração
- dashboard web simples
- totais de usuários/mensagens/conversas
- denúncias
- usuários suspensos

## Voz e vídeo
- configuração TURN com coturn
- docker compose de exemplo para TURN

## Importante sobre E2EE
A V10 NÃO afirma criptografia ponta a ponta completa.
Ela inclui a estrutura de chaves de identidade e campos no banco.
Para E2EE real, recomenda-se protocolo auditado (por exemplo, Signal Protocol)
e biblioteca criptográfica madura.
