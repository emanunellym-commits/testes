import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { SupportService } from './support.service';

@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly support: SupportService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() body: any) {
    return this.support.create(user.sub, body);
  }

  @Get('mine')
  mine(@CurrentUser() user: any) {
    return this.support.listMine(user.sub);
  }

  @Post(':id/reply')
  reply(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { message: string },
  ) {
    return this.support.reply(user.sub, id, body.message, false);
  }
}
