import { Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { SessionsService } from './sessions.service';

@Controller('sessions')
@UseGuards(JwtAuthGuard)
export class SessionsController {
  constructor(private readonly sessions: SessionsService) {}

  @Get()
  list(@CurrentUser() user: any) {
    return this.sessions.list(user.sub);
  }

  @Delete(':id')
  revoke(@CurrentUser() user: any, @Param('id') id: string) {
    return this.sessions.revoke(user.sub, id);
  }

  @Post('revoke-all')
  revokeAll(@CurrentUser() user: any) {
    return this.sessions.revokeAll(user.sub);
  }
}
