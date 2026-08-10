import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

@Controller('security')
@UseGuards(JwtAuthGuard)
export class SecurityController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('preferences')
  getPreferences(@CurrentUser() user: any) {
    return this.prisma.user.findUnique({
      where: { id: user.sub },
      select: {
        pushMessagesEnabled: true,
        pushCallsEnabled: true,
        nudgeEnabled: true,
      },
    });
  }

  @Post('preferences')
  setPreferences(
    @CurrentUser() user: any,
    @Body() body: {
      pushMessagesEnabled?: boolean;
      pushCallsEnabled?: boolean;
      nudgeEnabled?: boolean;
    },
  ) {
    return this.prisma.user.update({
      where: { id: user.sub },
      data: body,
      select: {
        pushMessagesEnabled: true,
        pushCallsEnabled: true,
        nudgeEnabled: true,
      },
    });
  }

  @Post('block/:userId')
  block(@CurrentUser() user: any, @Param('userId') userId: string) {
    return this.prisma.blockedUser.upsert({
      where: { blockerId_blockedId: { blockerId: user.sub, blockedId: userId } },
      update: {},
      create: { blockerId: user.sub, blockedId: userId },
    });
  }

  @Delete('block/:userId')
  async unblock(@CurrentUser() user: any, @Param('userId') userId: string) {
    await this.prisma.blockedUser.deleteMany({
      where: { blockerId: user.sub, blockedId: userId },
    });
    return { ok: true };
  }
}
