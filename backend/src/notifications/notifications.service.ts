import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  register(userId: string, token: string, platform?: string) {
    return this.prisma.deviceToken.upsert({
      where: { token },
      update: { userId, platform },
      create: { userId, token, platform },
    });
  }

  async remove(userId: string, token: string) {
    await this.prisma.deviceToken.deleteMany({ where: { userId, token } });
    return { ok: true };
  }

  // V3 deixa o cadastro do token pronto.
  // Para envio real em produção, integrar FCM/APNs aqui.
  async tokensForUsers(userIds: string[]) {
    return this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds } },
      select: { token: true, platform: true, userId: true },
    });
  }
}
