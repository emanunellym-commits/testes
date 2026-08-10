import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { ConversationType, MessageType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class GroupsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(ownerId: string, title: string, memberIds: string[]) {
    const cleanTitle = (title ?? '').trim();
    if (cleanTitle.length < 2) throw new BadRequestException('Informe um nome para o grupo');

    const uniqueIds = [...new Set([ownerId, ...(memberIds ?? [])])];

    const group = await this.prisma.conversation.create({
      data: {
        type: ConversationType.GROUP,
        title: cleanTitle,
        members: {
          create: uniqueIds.map(userId => ({
            userId,
            isAdmin: userId === ownerId,
          })),
        },
        messages: {
          create: {
            senderId: ownerId,
            type: MessageType.SYSTEM,
            body: `Grupo "${cleanTitle}" criado.`,
          },
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, displayName: true, username: true, avatarUrl: true, status: true },
            },
          },
        },
      },
    });

    return group;
  }

  async list(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        type: ConversationType.GROUP,
        members: { some: { userId } },
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, displayName: true, username: true, avatarUrl: true, status: true },
            },
          },
        },
        messages: {
          where: { deletedAt: null },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  private async ensureAdmin(userId: string, conversationId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member?.isAdmin) throw new ForbiddenException('Somente administradores do grupo podem fazer isso');
    return member;
  }

  async addMember(adminId: string, conversationId: string, userId: string) {
    await this.ensureAdmin(adminId, conversationId);
    return this.prisma.conversationMember.upsert({
      where: { conversationId_userId: { conversationId, userId } },
      update: {},
      create: { conversationId, userId },
    });
  }
}
