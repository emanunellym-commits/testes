import { JwtService } from '@nestjs/jwt';
import { MessageType, PresenceStatus } from '@prisma/client';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ConversationsService } from '../conversations/conversations.service';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from '../push/push.service';

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private socketsPerUser = new Map<string, number>();
  private lastNudge = new Map<string, number>();
  private lastCall = new Map<string, number>();

  constructor(
    private readonly jwt: JwtService,
    private readonly conversations: ConversationsService,
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

  private async auth(client: Socket) {
    const token =
      client.handshake.auth?.token ||
      (client.handshake.headers.authorization as string | undefined)?.replace('Bearer ', '');

    if (!token) throw new Error('Token ausente');
    const payload = await this.jwt.verifyAsync(token);
    client.data.userId = payload.sub;
    client.data.displayName = payload.displayName ?? 'LiveChat';
    return payload.sub as string;
  }

  async handleConnection(client: Socket) {
    try {
      const userId = await this.auth(client);
      client.join(`user:${userId}`);

      const count = (this.socketsPerUser.get(userId) ?? 0) + 1;
      this.socketsPerUser.set(userId, count);

      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { status: true },
      });

      if (count === 1 && user?.status !== PresenceStatus.INVISIBLE) {
        await this.prisma.user.update({
          where: { id: userId },
          data: { status: PresenceStatus.ONLINE },
        });
        this.server.emit('presence.changed', { userId, status: PresenceStatus.ONLINE });
      }
    } catch {
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    const count = Math.max((this.socketsPerUser.get(userId) ?? 1) - 1, 0);

    if (count === 0) {
      this.socketsPerUser.delete(userId);
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { status: true },
      });

      if (user?.status !== PresenceStatus.INVISIBLE) {
        await this.prisma.user.update({
          where: { id: userId },
          data: { status: PresenceStatus.OFFLINE, lastSeenAt: new Date() },
        });
        this.server.emit('presence.changed', { userId, status: PresenceStatus.OFFLINE });
      }
    } else {
      this.socketsPerUser.set(userId, count);
    }
  }

  private async memberUserIds(conversationId: string, exceptUserId?: string) {
    const members = await this.prisma.conversationMember.findMany({
      where: {
        conversationId,
        ...(exceptUserId ? { userId: { not: exceptUserId } } : {}),
      },
      select: { userId: true },
    });
    return members.map(m => m.userId);
  }

  private async isBlockedBetween(a: string, b: string) {
    return !!(await this.prisma.blockedUser.findFirst({
      where: {
        OR: [
          { blockerId: a, blockedId: b },
          { blockerId: b, blockedId: a },
        ],
      },
    }));
  }

  @SubscribeMessage('join')
  async join(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string },
  ) {
    await this.conversations.ensureMember(client.data.userId, body.conversationId);
    client.join(`conversation:${body.conversationId}`);
    return { ok: true };
  }

  @SubscribeMessage('typing')
  async typing(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string; typing: boolean },
  ) {
    await this.conversations.ensureMember(client.data.userId, body.conversationId);

    client.to(`conversation:${body.conversationId}`).emit('typing', {
      conversationId: body.conversationId,
      userId: client.data.userId,
      typing: body.typing,
    });
  }

  @SubscribeMessage('message.send')
  async message(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: any,
  ) {
    const type = body.type ?? MessageType.TEXT;
    const text = (body.text ?? '').trim();

    const message = await this.conversations.createMessage(
      client.data.userId,
      body.conversationId,
      text || null,
      type,
      {
        mediaUrl: body.mediaUrl,
        mediaName: body.mediaName,
        mediaMime: body.mediaMime,
        mediaSize: body.mediaSize,
      },
    );

    this.server.to(`conversation:${body.conversationId}`).emit('message.new', message);

    const recipients = await this.memberUserIds(body.conversationId, client.data.userId);
    const allowed = await this.prisma.user.findMany({
      where: {
        id: { in: recipients },
        pushMessagesEnabled: true,
      },
      select: { id: true },
    });

    await this.push.sendToUsers(
      allowed.map(x => x.id),
      client.data.displayName ?? 'LiveChat',
      type === MessageType.TEXT ? (text || 'Nova mensagem') : 'Enviou uma mídia',
      {
        kind: 'message',
        conversationId: body.conversationId,
      },
    );

    return message;
  }

  @SubscribeMessage('nudge')
  async nudge(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string },
  ) {
    const userId = client.data.userId;
    await this.conversations.ensureMember(userId, body.conversationId);

    const me = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { nudgeEnabled: true },
    });
    if (me?.nudgeEnabled === false) return { ok: false };

    const key = `${userId}:${body.conversationId}`;
    const now = Date.now();
    if (now - (this.lastNudge.get(key) ?? 0) < 8000) {
      return { ok: false, error: 'Aguarde alguns segundos.' };
    }

    this.lastNudge.set(key, now);

    const message = await this.conversations.createMessage(
      userId,
      body.conversationId,
      'CHAMAR_ATENCAO',
      MessageType.NUDGE,
    );

    this.server.to(`conversation:${body.conversationId}`).emit('nudge', message);
    return message;
  }

  @SubscribeMessage('call.invite')
  async invite(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    body: {
      conversationId: string;
      calleeId: string;
      callId: string;
      video: boolean;
      sdp?: any;
    },
  ) {
    const callerId = client.data.userId;
    await this.conversations.ensureMember(callerId, body.conversationId);

    if (await this.isBlockedBetween(callerId, body.calleeId)) {
      return { ok: false, error: 'Chamada não permitida.' };
    }

    const key = `${callerId}:${body.calleeId}`;
    const now = Date.now();
    if (now - (this.lastCall.get(key) ?? 0) < 5000) {
      return { ok: false, error: 'Aguarde antes de ligar novamente.' };
    }
    this.lastCall.set(key, now);

    const caller = await this.prisma.user.findUnique({
      where: { id: callerId },
      select: { displayName: true, avatarUrl: true },
    });

    const payload = {
      callId: body.callId,
      conversationId: body.conversationId,
      callerId,
      callerName: caller?.displayName ?? 'LiveChat',
      callerAvatar: caller?.avatarUrl ?? '',
      calleeId: body.calleeId,
      video: body.video,
      sdp: body.sdp,
    };

    this.server.to(`user:${body.calleeId}`).emit('call.incoming', payload);

    const callee = await this.prisma.user.findUnique({
      where: { id: body.calleeId },
      select: { pushCallsEnabled: true },
    });

    if (callee?.pushCallsEnabled !== false) {
      await this.push.sendToUsers(
        [body.calleeId],
        body.video ? 'Videochamada recebida' : 'Chamada recebida',
        `${payload.callerName} está ligando`,
        {
          kind: 'incoming_call',
          callId: body.callId,
          conversationId: body.conversationId,
          callerId,
          callerName: payload.callerName,
          video: body.video ? '1' : '0',
        },
      );
    }

    return { ok: true };
  }

  @SubscribeMessage('call.answer')
  answer(@ConnectedSocket() client: Socket, @MessageBody() body: any) {
    this.server.to(`user:${body.callerId}`).emit('call.answer', {
      ...body,
      calleeId: client.data.userId,
    });
  }

  @SubscribeMessage('call.ice')
  ice(@ConnectedSocket() client: Socket, @MessageBody() body: any) {
    this.server.to(`user:${body.targetUserId}`).emit('call.ice', {
      ...body,
      senderId: client.data.userId,
    });
  }

  @SubscribeMessage('call.reject')
  reject(@ConnectedSocket() client: Socket, @MessageBody() body: any) {
    this.server.to(`user:${body.targetUserId}`).emit('call.reject', {
      callId: body.callId,
      senderId: client.data.userId,
    });
  }

  @SubscribeMessage('call.end')
  end(@ConnectedSocket() client: Socket, @MessageBody() body: any) {
    this.server.to(`user:${body.targetUserId}`).emit('call.end', {
      callId: body.callId,
      senderId: client.data.userId,
    });
  }

  @SubscribeMessage('conversation.read')
  async conversationRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string },
  ) {
    await this.conversations.markConversationRead(client.data.userId, body.conversationId);

    this.server.to(`conversation:${body.conversationId}`).emit('receipt.read', {
      conversationId: body.conversationId,
      userId: client.data.userId,
      readAt: new Date().toISOString(),
    });

    return { ok: true };
  }

  @SubscribeMessage('message.react')
  async react(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { conversationId: string; messageId: string; emoji: string },
  ) {
    await this.conversations.ensureMember(client.data.userId, body.conversationId);

    const reaction = await this.prisma.messageReaction.upsert({
      where: {
        messageId_userId_emoji: {
          messageId: body.messageId,
          userId: client.data.userId,
          emoji: body.emoji,
        },
      },
      update: {},
      create: {
        messageId: body.messageId,
        userId: client.data.userId,
        emoji: body.emoji,
      },
    });

    this.server.to(`conversation:${body.conversationId}`).emit('message.reaction', {
      ...reaction,
      conversationId: body.conversationId,
    });

    return reaction;
  }

}
