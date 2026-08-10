import { Body, Controller, Delete, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { MessagesService } from './messages.service';

@Controller('messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  @Patch(':id')
  edit(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { text: string },
  ) {
    return this.messages.edit(user.sub, id, body.text);
  }

  @Delete(':id')
  remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.messages.remove(user.sub, id);
  }

  @Post(':id/forward')
  forward(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { conversationId: string },
  ) {
    return this.messages.forward(user.sub, id, body.conversationId);
  }

  @Post(':id/reactions')
  react(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() body: { emoji: string },
  ) {
    return this.messages.react(user.sub, id, body.emoji);
  }

  @Delete(':id/reactions/:emoji')
  unreact(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('emoji') emoji: string,
  ) {
    return this.messages.removeReaction(user.sub, id, emoji);
  }
}
