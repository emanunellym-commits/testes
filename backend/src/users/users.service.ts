import { BadRequestException, Injectable } from '@nestjs/common';
import { PresenceStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async search(meId: string, q: string) {
    const term = (q || '').trim();
    if (term.length < 2) return [];
    return this.prisma.user.findMany({
      where: {
        id: { not: meId },
        OR: [
          { username: { contains: term, mode: 'insensitive' } },
          { displayName: { contains: term, mode: 'insensitive' } },
          { email: { contains: term, mode: 'insensitive' } },
        ],
      },
      select: { id: true, username: true, displayName: true, avatarUrl: true, personalMsg: true, status: true },
      take: 20,
    });
  }

  async updateStatus(userId: string, status: PresenceStatus) {
    if (!Object.values(PresenceStatus).includes(status)) throw new BadRequestException('Status inválido');
    return this.prisma.user.update({ where: { id: userId }, data: { status }, select: { id: true, status: true } });
  }

  async updateProfile(userId: string, body: { displayName?: string; personalMsg?: string; avatarUrl?: string }) {
    const data: any = {};
    if (body.displayName !== undefined) {
      const name = body.displayName.trim();
      if (name.length < 2 || name.length > 50) throw new BadRequestException('Nome inválido');
      data.displayName = name;
    }
    if (body.personalMsg !== undefined) data.personalMsg = body.personalMsg.trim().slice(0, 100);
    if (body.avatarUrl !== undefined) data.avatarUrl = body.avatarUrl;
    return this.prisma.user.update({
      where: { id: userId }, data,
      select: { id: true, username: true, displayName: true, avatarUrl: true, personalMsg: true, status: true },
    });
  }
}
