import { Body, Controller, Get, Patch, Query, UseGuards } from '@nestjs/common';
import { PresenceStatus } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('search')
  search(@CurrentUser() user: any, @Query('q') q = '') { return this.users.search(user.sub, q); }

  @Patch('me/status')
  updateStatus(@CurrentUser() user: any, @Body() body: { status: PresenceStatus }) {
    return this.users.updateStatus(user.sub, body.status);
  }

  @Patch('me')
  updateProfile(@CurrentUser() user: any, @Body() body: { displayName?: string; personalMsg?: string; avatarUrl?: string }) {
    return this.users.updateProfile(user.sub, body);
  }
}
