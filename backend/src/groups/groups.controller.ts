import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { GroupsService } from './groups.service';

@Controller('groups')
@UseGuards(JwtAuthGuard)
export class GroupsController {
  constructor(private readonly groups: GroupsService) {}

  @Get()
  list(@CurrentUser() user: any) {
    return this.groups.list(user.sub);
  }

  @Post()
  create(
    @CurrentUser() user: any,
    @Body() body: { title: string; memberIds?: string[] },
  ) {
    return this.groups.create(user.sub, body.title, body.memberIds ?? []);
  }

  @Post(':id/members/:userId')
  addMember(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('userId') userId: string,
  ) {
    return this.groups.addMember(user.sub, id, userId);
  }
}
