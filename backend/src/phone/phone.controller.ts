import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { PhoneService } from './phone.service';

@Controller('phone')
@UseGuards(JwtAuthGuard)
export class PhoneController {
  constructor(private readonly phone: PhoneService) {}

  @Post('send-code')
  send(@CurrentUser() user: any, @Body() body: { phone: string }) {
    return this.phone.sendCode(user.sub, body.phone);
  }

  @Post('confirm')
  confirm(@CurrentUser() user: any, @Body() body: { code: string }) {
    return this.phone.confirm(user.sub, body.code);
  }
}
