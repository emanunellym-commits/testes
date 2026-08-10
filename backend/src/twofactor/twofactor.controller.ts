import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { TwoFactorService } from './twofactor.service';

@Controller('2fa')
@UseGuards(JwtAuthGuard)
export class TwoFactorController {
  constructor(private readonly twoFactor: TwoFactorService) {}

  @Post('setup')
  setup(@CurrentUser() user: any) {
    return this.twoFactor.setup(user.sub);
  }

  @Post('enable')
  enable(@CurrentUser() user: any, @Body() body: { token: string }) {
    return this.twoFactor.enable(user.sub, body.token);
  }

  @Post('disable')
  disable(@CurrentUser() user: any, @Body() body: { token: string }) {
    return this.twoFactor.disable(user.sub, body.token);
  }
}
