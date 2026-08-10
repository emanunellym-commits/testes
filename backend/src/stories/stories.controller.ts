import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { StoriesService } from './stories.service';

@Controller('stories')
@UseGuards(JwtAuthGuard)
export class StoriesController {
  constructor(private readonly stories: StoriesService) {}

  @Get()
  feed(@CurrentUser() user: any) {
    return this.stories.feed(user.sub);
  }

  @Post()
  create(
    @CurrentUser() user: any,
    @Body() body: { text?: string; mediaUrl?: string; mediaType?: string },
  ) {
    return this.stories.create(user.sub, body);
  }

  @Post(':id/view')
  view(@CurrentUser() user: any, @Param('id') id: string) {
    return this.stories.view(user.sub, id);
  }
}
