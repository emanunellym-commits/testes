import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';

@Injectable()
export class AccountService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mail: MailService,
  ) {}

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private async createToken(userId: string, type: any, minutes = 30) {
    const token = randomBytes(32).toString('hex');
    await this.prisma.verificationToken.create({
      data: {
        userId,
        type,
        tokenHash: this.hashToken(token),
        expiresAt: new Date(Date.now() + minutes * 60 * 1000),
      },
    });
    return token;
  }

  async requestEmailVerification(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const token = await this.createToken(userId, 'EMAIL', 60);
    await this.mail.send(
      user.email,
      'Verifique sua conta LiveChat',
      `Seu código de verificação é:\n\n${token}\n\nEste código expira em 60 minutos.`,
    );

    return { ok: true };
  }

  async verifyEmail(userId: string, token: string) {
    const row = await this.prisma.verificationToken.findFirst({
      where: {
        userId,
        type: 'EMAIL',
        tokenHash: this.hashToken(token),
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (!row) throw new BadRequestException('Código inválido ou expirado');

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { emailVerifiedAt: new Date() },
      }),
      this.prisma.verificationToken.update({
        where: { id: row.id },
        data: { usedAt: new Date() },
      }),
    ]);

    return { ok: true };
  }

  async requestPasswordReset(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });

    // Resposta neutra para evitar enumeração de contas.
    if (!user) return { ok: true };

    const token = await this.createToken(user.id, 'PASSWORD_RESET', 30);

    await this.mail.send(
      user.email,
      'Redefinição de senha LiveChat',
      `Use este código para redefinir sua senha:\n\n${token}\n\nExpira em 30 minutos.`,
    );

    return { ok: true };
  }

  async resetPassword(email: string, token: string, newPassword: string) {
    if (newPassword.length < 8) {
      throw new BadRequestException('A senha deve ter pelo menos 8 caracteres');
    }

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new BadRequestException('Código inválido ou expirado');

    const row = await this.prisma.verificationToken.findFirst({
      where: {
        userId: user.id,
        type: 'PASSWORD_RESET',
        tokenHash: this.hashToken(token),
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (!row) throw new BadRequestException('Código inválido ou expirado');

    const passwordHash = await bcrypt.hash(newPassword, 12);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.verificationToken.update({
        where: { id: row.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.deviceToken.deleteMany({
        where: { userId: user.id },
      }),
    ]);

    return { ok: true };
  }

  async requestDelete(userId: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const matches = await bcrypt.compare(password, user.passwordHash);
    if (!matches) throw new UnauthorizedException('Senha incorreta');

    const token = await this.createToken(user.id, 'DELETE_ACCOUNT', 15);
    await this.mail.send(
      user.email,
      'Confirmação de exclusão da conta LiveChat',
      `Código para confirmar a exclusão:\n\n${token}\n\nExpira em 15 minutos.`,
    );

    return { ok: true };
  }

  async confirmDelete(userId: string, token: string) {
    const row = await this.prisma.verificationToken.findFirst({
      where: {
        userId,
        type: 'DELETE_ACCOUNT',
        tokenHash: this.hashToken(token),
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (!row) throw new BadRequestException('Código inválido ou expirado');

    const tombstone = `deleted-${userId}-${Date.now()}`;

    await this.prisma.$transaction([
      this.prisma.verificationToken.update({
        where: { id: row.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.deviceToken.deleteMany({ where: { userId } }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          email: `${tombstone}@deleted.local`,
          username: tombstone,
          displayName: 'Conta excluída',
          avatarUrl: null,
          personalMsg: null,
          deletedAt: new Date(),
          isSuspended: true,
          status: 'OFFLINE',
        },
      }),
    ]);

    return { ok: true };
  }
}
