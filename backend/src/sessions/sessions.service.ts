import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { createHash, randomBytes } from 'crypto';

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  private hash(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  async isDeviceBanned(deviceId?: string | null) {
    if (!deviceId) return false;
    const ban = await this.prisma.deviceBan.findUnique({ where: { deviceId } });
    if (!ban) return false;

    if (ban.expiresAt && ban.expiresAt <= new Date()) {
      await this.prisma.deviceBan.delete({ where: { deviceId } });
      return false;
    }

    return true;
  }

  async create(userId: string, meta: any = {}) {
    if (await this.isDeviceBanned(meta.deviceId)) {
      throw new BadRequestException('Este dispositivo não está autorizado.');
    }

    const refreshToken = randomBytes(48).toString('hex');

    const session = await this.prisma.userSession.create({
      data: {
        userId,
        refreshHash: this.hash(refreshToken),
        deviceId: meta.deviceId,
        deviceName: meta.deviceName,
        platform: meta.platform,
        ipAddress: meta.ipAddress,
        userAgent: meta.userAgent,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });

    return { session, refreshToken };
  }

  async rotate(refreshToken: string) {
    const session = await this.prisma.userSession.findUnique({
      where: { refreshHash: this.hash(refreshToken) },
    });

    if (!session || session.revokedAt || session.expiresAt <= new Date()) {
      throw new BadRequestException('Sessão inválida ou expirada');
    }

    if (await this.isDeviceBanned(session.deviceId)) {
      await this.prisma.userSession.update({
        where: { id: session.id },
        data: { revokedAt: new Date() },
      });
      throw new BadRequestException('Dispositivo bloqueado');
    }

    const next = randomBytes(48).toString('hex');

    await this.prisma.userSession.update({
      where: { id: session.id },
      data: {
        refreshHash: this.hash(next),
        lastUsedAt: new Date(),
      },
    });

    return { session, refreshToken: next };
  }

  list(userId: string) {
    return this.prisma.userSession.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      select: {
        id: true,
        deviceId: true,
        deviceName: true,
        platform: true,
        ipAddress: true,
        lastUsedAt: true,
        createdAt: true,
        expiresAt: true,
      },
      orderBy: { lastUsedAt: 'desc' },
    });
  }

  async revoke(userId: string, sessionId: string) {
    await this.prisma.userSession.updateMany({
      where: { id: sessionId, userId },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  async revokeAll(userId: string) {
    await this.prisma.userSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }
}
