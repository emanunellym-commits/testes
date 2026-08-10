import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { authenticator } from 'otplib';
import QRCode from 'qrcode';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'crypto';

@Injectable()
export class TwoFactorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  private key() {
    const raw = this.config.get<string>('TWO_FACTOR_MASTER_KEY') ?? 'dev-only-change-me';
    return createHash('sha256').update(raw).digest();
  }

  private hash(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private encrypt(value: string) {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key(), iv);
    const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
    return Buffer.concat([iv, cipher.getAuthTag(), encrypted]).toString('base64');
  }

  private decrypt(value: string) {
    const data = Buffer.from(value, 'base64');
    const decipher = createDecipheriv('aes-256-gcm', this.key(), data.subarray(0, 12));
    decipher.setAuthTag(data.subarray(12, 28));
    return Buffer.concat([
      decipher.update(data.subarray(28)),
      decipher.final(),
    ]).toString('utf8');
  }

  async setup(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true },
    });
    if (!user) throw new BadRequestException('Usuário não encontrado');

    const secret = authenticator.generateSecret();
    const otpauth = authenticator.keyuri(user.email, 'LiveChat Messenger', secret);

    await this.prisma.user.update({
      where: { id: userId },
      data: { twoFactorSecretEnc: this.encrypt(secret) },
    });

    return {
      secret,
      qrDataUrl: await QRCode.toDataURL(otpauth),
    };
  }

  async enable(userId: string, token: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { twoFactorSecretEnc: true },
    });

    if (!user?.twoFactorSecretEnc) {
      throw new BadRequestException('Configure o 2FA primeiro');
    }

    const secret = this.decrypt(user.twoFactorSecretEnc);
    if (!authenticator.verify({ token, secret })) {
      throw new BadRequestException('Código inválido');
    }

    const recoveryCodes = Array.from(
      { length: 8 },
      () => randomBytes(5).toString('hex').toUpperCase(),
    );

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { twoFactorEnabled: true },
      }),
      this.prisma.twoFactorRecoveryCode.deleteMany({ where: { userId } }),
      this.prisma.twoFactorRecoveryCode.createMany({
        data: recoveryCodes.map(code => ({
          userId,
          codeHash: this.hash(code),
        })),
      }),
    ]);

    return { ok: true, recoveryCodes };
  }

  async verify(userId: string, token: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { twoFactorSecretEnc: true, twoFactorEnabled: true },
    });

    if (!user?.twoFactorEnabled || !user.twoFactorSecretEnc) return true;
    return authenticator.verify({
      token,
      secret: this.decrypt(user.twoFactorSecretEnc),
    });
  }

  async useRecoveryCode(userId: string, code: string) {
    const row = await this.prisma.twoFactorRecoveryCode.findUnique({
      where: { codeHash: this.hash(code.trim().toUpperCase()) },
    });

    if (!row || row.userId !== userId || row.usedAt) return false;

    await this.prisma.twoFactorRecoveryCode.update({
      where: { id: row.id },
      data: { usedAt: new Date() },
    });

    return true;
  }

  async disable(userId: string, token: string) {
    if (!await this.verify(userId, token)) {
      throw new BadRequestException('Código inválido');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: {
          twoFactorEnabled: false,
          twoFactorSecretEnc: null,
        },
      }),
      this.prisma.twoFactorRecoveryCode.deleteMany({ where: { userId } }),
    ]);

    return { ok: true };
  }
}
