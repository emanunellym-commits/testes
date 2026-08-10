import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { ContactsService } from './contacts.service';

@Controller('contacts')
@UseGuards(JwtAuthGuard)
export class ContactsController {
  constructor(private readonly contacts: ContactsService) {}
  @Get() list(@CurrentUser() user: any) { return this.contacts.list(user.sub); }
  @Post(':contactId') add(@CurrentUser() user: any, @Param('contactId') contactId: string) {
    return this.contacts.add(user.sub, contactId);
  }
}
