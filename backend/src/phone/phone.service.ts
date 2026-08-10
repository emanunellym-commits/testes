import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SmsService } from '../sms/sms.service';
import { createHash, randomInt } from 'crypto';

@Injectable()
export class PhoneService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sms: SmsService,
  ) {}

  private hash(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  async sendCode(userId: string, phone: string) {
    const normalized = phone.replace(/[^\d+]/g, '');
    if (normalized.length < 10) throw new BadRequestException('Número inválido');

    const code = String(randomInt(100000, 999999));

    await this.prisma.verificationToken.create({
      data: {
        userId,
        type: 'PHONE',
        tokenHash: this.hash(code),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { phoneNumber: normalized },
    });

    await this.sms.send(normalized, `Seu código LiveChat é ${code}. Expira em 10 minutos.`);
    return { ok: true };
  }

  async confirm(userId: string, code: string) {
    const row = await this.prisma.verificationToken.findFirst({
      where: {
        userId,
        type: 'PHONE',
        tokenHash: this.hash(code),
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (!row) throw new BadRequestException('Código inválido ou expirado');

    await this.prisma.$transaction([
      this.prisma.verificationToken.update({
        where: { id: row.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { phoneVerifiedAt: new Date() },
      }),
    ]);

    return { ok: true };
  }
}
