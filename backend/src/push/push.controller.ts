import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

@Controller('push')
@UseGuards(JwtAuthGuard)
export class PushController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('token')
  async register(
    @CurrentUser() user: any,
    @Body() body: { token: string; platform?: string },
  ) {
    return this.prisma.deviceToken.upsert({
      where: { token: body.token },
      update: {
        userId: user.sub,
        platform: body.platform,
      },
      create: {
        userId: user.sub,
        token: body.token,
        platform: body.platform,
      },
    });
  }

  @Delete('token')
  async remove(
    @CurrentUser() user: any,
    @Body() body: { token: string },
  ) {
    await this.prisma.deviceToken.deleteMany({
      where: { userId: user.sub, token: body.token },
    });
    return { ok: true };
  }
}
