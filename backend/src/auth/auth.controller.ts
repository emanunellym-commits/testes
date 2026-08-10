import { Body, Controller, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('login')
  login(@Req() req: Request, @Body() body: any) {
    return this.auth.login(body.email, body.password, {
      deviceId: body.deviceId,
      deviceName: body.deviceName,
      platform: body.platform,
      twoFactorToken: body.twoFactorToken,
      recoveryCode: body.recoveryCode,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });
  }

  @Post('refresh')
  refresh(@Body() body: { refreshToken: string }) {
    return this.auth.refresh(body.refreshToken);
  }
}
