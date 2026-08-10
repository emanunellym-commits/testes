import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AccountService } from './account.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';

@Controller('account')
export class AccountController {
  constructor(private readonly account: AccountService) {}

  @Post('forgot-password')
  forgotPassword(@Body() body: { email: string }) {
    return this.account.requestPasswordReset(body.email.trim().toLowerCase());
  }

  @Post('reset-password')
  resetPassword(
    @Body() body: { email: string; token: string; newPassword: string },
  ) {
    return this.account.resetPassword(
      body.email.trim().toLowerCase(),
      body.token,
      body.newPassword,
    );
  }

  @Post('verification/send')
  @UseGuards(JwtAuthGuard)
  sendVerification(@CurrentUser() user: any) {
    return this.account.requestEmailVerification(user.sub);
  }

  @Post('verification/confirm')
  @UseGuards(JwtAuthGuard)
  confirmVerification(
    @CurrentUser() user: any,
    @Body() body: { token: string },
  ) {
    return this.account.verifyEmail(user.sub, body.token);
  }

  @Post('delete/request')
  @UseGuards(JwtAuthGuard)
  deleteRequest(
    @CurrentUser() user: any,
    @Body() body: { password: string },
  ) {
    return this.account.requestDelete(user.sub, body.password);
  }

  @Post('delete/confirm')
  @UseGuards(JwtAuthGuard)
  deleteConfirm(
    @CurrentUser() user: any,
    @Body() body: { token: string },
  ) {
    return this.account.confirmDelete(user.sub, body.token);
  }
}
