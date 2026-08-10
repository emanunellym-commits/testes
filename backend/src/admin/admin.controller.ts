import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { AdminGuard } from './admin.guard';
import { AdminService } from './admin.service';
import { SupportService } from '../support/support.service';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly support: SupportService,
  ) {}

  @Get('dashboard')
  dashboard() {
    return this.admin.dashboard();
  }

  @Get('reports')
  reports() {
    return this.admin.reports();
  }

  @Post('reports/:id/status')
  setReportStatus(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { status: string; note?: string },
  ) {
    return this.admin.setReportStatus(user.sub, id, body.status, body.note);
  }

  @Post('users/:id/suspend')
  suspend(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { hours?: number; note?: string },
  ) {
    return this.admin.suspend(user.sub, id, body.hours ?? 24, body.note);
  }

  @Post('users/:id/unsuspend')
  unsuspend(@Param('id') id: string) {
    return this.admin.unsuspend(id);
  }

  @Get('support')
  supportTickets() {
    return this.support.listAll();
  }

  @Post('support/:id/reply')
  supportReply(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { message: string },
  ) {
    return this.support.reply(user.sub, id, body.message, true);
  }


  @Get('device-bans')
  deviceBans() {
    return this.admin.deviceBans();
  }

  @Post('device-bans')
  banDevice(
    @CurrentUser() user: any,
    @Body() body: { deviceId: string; reason?: string; hours?: number },
  ) {
    return this.admin.banDevice(
      user.sub,
      body.deviceId,
      body.reason,
      body.hours,
    );
  }

  @Post('device-bans/remove')
  unbanDevice(@Body() body: { deviceId: string }) {
    return this.admin.unbanDevice(body.deviceId);
  }

}