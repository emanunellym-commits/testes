import { ForbiddenException, Injectable } from '@nestjs/common';
import { ConversationType, MessageType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type MediaPayload = {
  mediaUrl?: string;
  mediaName?: string;
  mediaMime?: string;
  mediaSize?: number;
};

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  async ensureMember(userId: string, conversationId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member) throw new ForbiddenException('Você não participa desta conversa');
    return member;
  }

  async direct(userId: string, otherUserId: string) {
    const candidates = await this.prisma.conversation.findMany({
      where: {
        type: ConversationType.DIRECT,
        AND: [
          { members: { some: { userId } } },
          { members: { some: { userId: otherUserId } } },
        ],
      },
      include: { members: true },
    });

    const existing = candidates.find(c => c.members.length === 2);
    if (existing) return existing;

    return this.prisma.conversation.create({
      data: {
        type: ConversationType.DIRECT,
        members: { create: [{ userId, isAdmin: true }, { userId: otherUserId }] },
      },
      include: { members: true },
    });
  }

  async listRecent(userId: string, archived = false) {
    const rows = await this.prisma.conversationMember.findMany({
      where: {
        userId,
        archivedAt: archived ? { not: null } : null,
      },
      include: {
        conversation: {
          include: {
            members: {
              include: {
                user: {
                  select: {
                    id: true,
                    displayName: true,
                    username: true,
                    avatarUrl: true,
                    status: true,
                    lastSeenAt: true,
                  },
                },
              },
            },
            messages: {
              where: { deletedAt: null },
              include: {
                receipts: true,
                reactions: true,
              },
              orderBy: { createdAt: 'desc' },
              take: 1,
            },
          },
        },
      },
      orderBy: [
        { pinnedAt: 'desc' },
        { conversation: { updatedAt: 'desc' } },
      ],
    });

    const result = [];
    for (const row of rows) {
      const unread = await this.prisma.message.count({
        where: {
          conversationId: row.conversationId,
          senderId: { not: userId },
          deletedAt: null,
          createdAt: row.lastReadAt ? { gt: row.lastReadAt } : undefined,
        },
      });

      result.push({
        ...row.conversation,
        pinnedAt: row.pinnedAt,
        archivedAt: row.archivedAt,
        unreadCount: unread,
      });
    }

    return result;
  }

  async messages(userId: string, conversationId: string, q?: string) {
    await this.ensureMember(userId, conversationId);

    return this.prisma.message.findMany({
      where: {
        conversationId,
        deletedAt: null,
        ...(q?.trim()
          ? { body: { contains: q.trim(), mode: 'insensitive' } }
          : {}),
      },
      include: {
        replyTo: {
          select: { id: true, senderId: true, body: true, type: true },
        },
        receipts: true,
        reactions: true,
      },
      orderBy: { createdAt: 'asc' },
      take: 500,
    });
  }

  async createMessage(
    userId: string,
    conversationId: string,
    body: string | null,
    type: MessageType = MessageType.TEXT,
    media: MediaPayload = {},
    extra: { replyToId?: string } = {},
  ) {
    await this.ensureMember(userId, conversationId);

    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId: userId,
        body,
        type,
        mediaUrl: media.mediaUrl,
        mediaName: media.mediaName,
        mediaMime: media.mediaMime,
        mediaSize: media.mediaSize,
        replyToId: extra.replyToId,
      },
      include: {
        replyTo: {
          select: { id: true, senderId: true, body: true, type: true },
        },
        receipts: true,
        reactions: true,
      },
    });

    const recipients = await this.prisma.conversationMember.findMany({
      where: { conversationId, userId: { not: userId } },
      select: { userId: true },
    });

    if (recipients.length) {
      await this.prisma.messageReceipt.createMany({
        data: recipients.map(r => ({
          messageId: message.id,
          userId: r.userId,
          status: 'SENT',
        })),
        skipDuplicates: true,
      });
    }

    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    return message;
  }

  async markConversationRead(userId: string, conversationId: string) {
    await this.ensureMember(userId, conversationId);
    const now = new Date();

    await this.prisma.conversationMember.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: now },
    });

    const messages = await this.prisma.message.findMany({
      where: {
        conversationId,
        senderId: { not: userId },
        deletedAt: null,
      },
      select: { id: true },
    });

    for (const m of messages) {
      await this.prisma.messageReceipt.upsert({
        where: { messageId_userId: { messageId: m.id, userId } },
        update: { status: 'READ' },
        create: { messageId: m.id, userId, status: 'READ' },
      });
    }

    return { ok: true, readAt: now };
  }

  async setPinned(userId: string, conversationId: string, pinned: boolean) {
    await this.ensureMember(userId, conversationId);
    return this.prisma.conversationMember.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { pinnedAt: pinned ? new Date() : null },
    });
  }

  async setArchived(userId: string, conversationId: string, archived: boolean) {
    await this.ensureMember(userId, conversationId);
    return this.prisma.conversationMember.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { archivedAt: archived ? new Date() : null },
    });
  }
}
