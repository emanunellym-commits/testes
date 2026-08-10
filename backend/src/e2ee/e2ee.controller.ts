import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

@Controller('e2ee')
@UseGuards(JwtAuthGuard)
export class E2eeController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('identity-key')
  register(
    @CurrentUser() user: any,
    @Body() body: { deviceId: string; publicKey: string },
  ) {
    return this.prisma.identityKey.upsert({
      where: {
        userId_deviceId: {
          userId: user.sub,
          deviceId: body.deviceId,
        },
      },
      update: { publicKey: body.publicKey },
      create: {
        userId: user.sub,
        deviceId: body.deviceId,
        publicKey: body.publicKey,
      },
    });
  }

  @Get('identity-key/:userId')
  keys(@Param('userId') userId: string) {
    return this.prisma.identityKey.findMany({
      where: { userId },
      select: {
        deviceId: true,
        publicKey: true,
        updatedAt: true,
      },
    });
  }

  @Get('conversation/:conversationId/devices')
  async conversationDevices(
    @CurrentUser() user: any,
    @Param('conversationId') conversationId: string,
  ) {
    const member = await this.prisma.conversationMember.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId: user.sub,
        },
      },
    });

    if (!member) return [];

    const members = await this.prisma.conversationMember.findMany({
      where: { conversationId },
      select: { userId: true },
    });

    return this.prisma.identityKey.findMany({
      where: {
        userId: { in: members.map(m => m.userId) },
      },
      select: {
        userId: true,
        deviceId: true,
        publicKey: true,
        updatedAt: true,
      },
    });
  }
}
