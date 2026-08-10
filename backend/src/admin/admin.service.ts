import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboard() {
    const [
      users,
      messages,
      conversations,
      openReports,
      suspendedUsers,
    ] = await Promise.all([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.message.count({ where: { deletedAt: null } }),
      this.prisma.conversation.count(),
      this.prisma.report.count({ where: { status: 'OPEN' } }),
      this.prisma.user.count({ where: { isSuspended: true, deletedAt: null } }),
    ]);

    return { users, messages, conversations, openReports, suspendedUsers };
  }

  reports() {
    return this.prisma.report.findMany({
      include: {
        reporter: {
          select: { id: true, displayName: true, username: true },
        },
        reportedUser: {
          select: { id: true, displayName: true, username: true },
        },
        message: {
          select: { id: true, body: true, type: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  async setReportStatus(adminUserId: string, reportId: string, status: any, note?: string) {
    await this.prisma.report.update({
      where: { id: reportId },
      data: { status },
    });

    await this.prisma.moderationAction.create({
      data: {
        adminUserId,
        reportId,
        type: status === 'DISMISSED' ? 'REPORT_DISMISS' : 'WARNING',
        note,
      },
    });

    return { ok: true };
  }

  async suspend(adminUserId: string, userId: string, hours: number, note?: string) {
    const expiresAt = hours > 0
      ? new Date(Date.now() + hours * 60 * 60 * 1000)
      : null;

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        isSuspended: true,
        suspendedUntil: expiresAt,
      },
    });

    await this.prisma.moderationAction.create({
      data: {
        adminUserId,
        targetUserId: userId,
        type: hours > 0 ? 'TEMP_SUSPEND' : 'PERMANENT_BAN',
        note,
        expiresAt,
      },
    });

    return { ok: true };
  }

  async unsuspend(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        isSuspended: false,
        suspendedUntil: null,
      },
    });
    return { ok: true };
  }

  async banDevice(adminUserId: string, deviceId: string, reason?: string, hours?: number) {
    const expiresAt = hours && hours > 0
      ? new Date(Date.now() + hours * 60 * 60 * 1000)
      : null;

    await this.prisma.deviceBan.upsert({
      where: { deviceId },
      update: { reason, createdBy: adminUserId, expiresAt },
      create: { deviceId, reason, createdBy: adminUserId, expiresAt },
    });

    await this.prisma.userSession.updateMany({
      where: { deviceId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    return { ok: true };
  }

  async unbanDevice(deviceId: string) {
    await this.prisma.deviceBan.deleteMany({ where: { deviceId } });
    return { ok: true };
  }

  deviceBans() {
    return this.prisma.deviceBan.findMany({
      orderBy: { createdAt: 'desc' },
      take: 300,
    });
  }

}