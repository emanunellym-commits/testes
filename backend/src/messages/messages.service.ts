import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConversationsService } from '../conversations/conversations.service';

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly conversations: ConversationsService,
  ) {}

  private async owned(userId: string, messageId: string) {
    const msg = await this.prisma.message.findUnique({ where: { id: messageId } });
    if (!msg) throw new NotFoundException('Mensagem não encontrada');
    if (msg.senderId !== userId) throw new ForbiddenException('Ação não permitida');
    return msg;
  }

  async edit(userId: string, messageId: string, text: string) {
    await this.owned(userId, messageId);
    return this.prisma.message.update({
      where: { id: messageId },
      data: { body: text.trim(), editedAt: new Date() },
      include: { receipts: true, reactions: true, replyTo: true },
    });
  }

  async remove(userId: string, messageId: string) {
    await this.owned(userId, messageId);
    return this.prisma.message.update({
      where: { id: messageId },
      data: {
        body: null,
        mediaUrl: null,
        deletedAt: new Date(),
      },
    });
  }

  async forward(userId: string, messageId: string, conversationId: string) {
    const original = await this.prisma.message.findUnique({ where: { id: messageId } });
    if (!original) throw new NotFoundException('Mensagem não encontrada');

    await this.conversations.ensureMember(userId, conversationId);

    return this.prisma.message.create({
      data: {
        conversationId,
        senderId: userId,
        type: original.type,
        body: original.body,
        mediaUrl: original.mediaUrl,
        mediaName: original.mediaName,
        mediaMime: original.mediaMime,
        mediaSize: original.mediaSize,
        forwardedFromId: original.id,
      },
      include: { reactions: true, receipts: true },
    });
  }

  async react(userId: string, messageId: string, emoji: string) {
    const existing = await this.prisma.message.findUnique({ where: { id: messageId } });
    if (!existing) throw new NotFoundException('Mensagem não encontrada');

    await this.conversations.ensureMember(userId, existing.conversationId);

    return this.prisma.messageReaction.upsert({
      where: {
        messageId_userId_emoji: {
          messageId,
          userId,
          emoji,
        },
      },
      update: {},
      create: { messageId, userId, emoji },
    });
  }

  async removeReaction(userId: string, messageId: string, emoji: string) {
    await this.prisma.messageReaction.deleteMany({
      where: { messageId, userId, emoji },
    });
    return { ok: true };
  }
}
