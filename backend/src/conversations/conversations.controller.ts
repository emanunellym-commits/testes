import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { ConversationsService } from './conversations.service';

@Controller('conversations')
@UseGuards(JwtAuthGuard)
export class ConversationsController {
  constructor(private readonly conversations: ConversationsService) {}

  @Get()
  list(
    @CurrentUser() user: any,
    @Query('archived') archived?: string,
  ) {
    return this.conversations.listRecent(user.sub, archived === '1');
  }

  @Post('direct/:userId')
  direct(@CurrentUser() user: any, @Param('userId') userId: string) {
    return this.conversations.direct(user.sub, userId);
  }

  @Get(':id/messages')
  messages(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('q') q?: string,
  ) {
    return this.conversations.messages(user.sub, id, q);
  }

  @Post(':id/read')
  read(@CurrentUser() user: any, @Param('id') id: string) {
    return this.conversations.markConversationRead(user.sub, id);
  }

  @Post(':id/pin')
  pin(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { pinned: boolean },
  ) {
    return this.conversations.setPinned(user.sub, id, body.pinned);
  }

  @Post(':id/archive')
  archive(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { archived: boolean },
  ) {
    return this.conversations.setArchived(user.sub, id, body.archived);
  }
}
