import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { SessionsService } from '../sessions/sessions.service';
import { TwoFactorService } from '../twofactor/twofactor.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly sessions: SessionsService,
    private readonly twoFactor: TwoFactorService,
  ) {}

  private accessToken(user: any) {
    return this.jwt.signAsync(
      {
        sub: user.id,
        email: user.email,
        displayName: user.displayName,
      },
      { expiresIn: '15m' },
    );
  }

  async login(email: string, password: string, meta: any = {}) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    if (!user || user.deletedAt) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    if (
      user.isSuspended &&
      (!user.suspendedUntil || user.suspendedUntil > new Date())
    ) {
      throw new UnauthorizedException('Conta suspensa');
    }

    if (!await bcrypt.compare(password, user.passwordHash)) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    if (user.twoFactorEnabled) {
      let verified = false;

      if (meta.twoFactorToken) {
        verified = await this.twoFactor.verify(user.id, meta.twoFactorToken);
      } else if (meta.recoveryCode) {
        verified = await this.twoFactor.useRecoveryCode(
          user.id,
          meta.recoveryCode,
        );
      }

      if (!verified) {
        return { requiresTwoFactor: true };
      }
    }

    const { session, refreshToken } =
      await this.sessions.create(user.id, meta);

    return {
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        status: user.status,
      },
      accessToken: await this.accessToken(user),
      refreshToken,
      sessionId: session.id,
    };
  }

  async refresh(refreshToken: string) {
    const rotated = await this.sessions.rotate(refreshToken);

    const user = await this.prisma.user.findUnique({
      where: { id: rotated.session.userId },
    });

    if (!user || user.deletedAt) {
      throw new BadRequestException('Conta inválida');
    }

    return {
      accessToken: await this.accessToken(user),
      refreshToken: rotated.refreshToken,
    };
  }
}
