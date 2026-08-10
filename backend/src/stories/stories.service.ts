import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, body: { text?: string; mediaUrl?: string; mediaType?: string }) {
    if (!body.text?.trim() && !body.mediaUrl) {
      throw new BadRequestException('Story vazio');
    }

    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    return this.prisma.story.create({
      data: {
        userId,
        text: body.text?.trim() || null,
        mediaUrl: body.mediaUrl || null,
        mediaType: body.mediaType || null,
        expiresAt,
      },
    });
  }

  feed(userId: string) {
    return this.prisma.story.findMany({
      where: {
        expiresAt: { gt: new Date() },
        OR: [
          { userId },
          {
            user: {
              contactOf: {
                some: { ownerId: userId },
              },
            },
          },
        ],
      },
      include: {
        user: {
          select: { id: true, displayName: true, username: true, avatarUrl: true },
        },
        views: { where: { viewerId: userId }, select: { id: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async view(userId: string, storyId: string) {
    return this.prisma.storyView.upsert({
      where: { storyId_viewerId: { storyId, viewerId: userId } },
      update: {},
      create: { storyId, viewerId: userId },
    });
  }
}
