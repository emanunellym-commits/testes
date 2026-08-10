import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('device-token')
  register(
    @CurrentUser() user: any,
    @Body() body: { token: string; platform?: string },
  ) {
    return this.notifications.register(user.sub, body.token, body.platform);
  }

  @Delete('device-token')
  remove(
    @CurrentUser() user: any,
    @Body() body: { token: string },
  ) {
    return this.notifications.remove(user.sub, body.token);
  }
}
