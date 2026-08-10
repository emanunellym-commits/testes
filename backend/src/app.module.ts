import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerModule } from '@nestjs/throttler';

import { AccountController } from './account/account.controller';
import { AccountService } from './account/account.service';
import { AdminController } from './admin/admin.controller';
import { AdminGuard } from './admin/admin.guard';
import { AdminService } from './admin/admin.service';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { ChatGateway } from './chat/chat.gateway';
import { ContactsController } from './contacts/contacts.controller';
import { ContactsService } from './contacts/contacts.service';
import { ConversationsController } from './conversations/conversations.controller';
import { ConversationsService } from './conversations/conversations.service';
import { E2eeController } from './e2ee/e2ee.controller';
import { GroupsController } from './groups/groups.controller';
import { GroupsService } from './groups/groups.service';
import { MailService } from './mail/mail.service';
import { MediaController } from './media/media.controller';
import { MessagesController } from './messages/messages.controller';
import { MessagesService } from './messages/messages.service';
import { PrismaService } from './prisma/prisma.service';
import { PushController } from './push/push.controller';
import { PushService } from './push/push.service';
import { ReportsController } from './reports/reports.controller';
import { ReportsService } from './reports/reports.service';
import { SecurityController } from './security/security.controller';
import { StoriesController } from './stories/stories.controller';
import { StoriesService } from './stories/stories.service';
import { UsersController } from './users/users.controller';
import { UsersService } from './users/users.service';
import { TwoFactorService } from './twofactor/twofactor.service';
import { TwoFactorController } from './twofactor/twofactor.controller';
import { SupportService } from './support/support.service';
import { SupportController } from './support/support.controller';
import { SmsService } from './sms/sms.service';
import { SessionsService } from './sessions/sessions.service';
import { SessionsController } from './sessions/sessions.controller';
import { PhoneService } from './phone/phone.service';
import { PhoneController } from './phone/phone.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 120 }]),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET') ?? 'dev-only-change-me',
        signOptions: { expiresIn: '7d' },
      }),
    }),
  ],
  controllers: [
    AccountController,
    AdminController,
    AuthController,
    UsersController,
    ContactsController,
    ConversationsController,
    E2eeController,
    GroupsController,
    MediaController,
    MessagesController,
    PushController,
    ReportsController,
    SecurityController,
    SessionsController,
    SupportController,
    TwoFactorController,
    PhoneController,
    StoriesController,
  ],
  providers: [
    PrismaService,
    MailService,
    AccountService,
    AdminGuard,
    AdminService,
    AuthService,
    JwtAuthGuard,
    UsersService,
    ContactsService,
    ConversationsService,
    GroupsService,
    MessagesService,
    ReportsService,
    SessionsService,
    SupportService,
    TwoFactorService,
    PhoneService,
    SmsService,
    StoriesService,
    PushService,
    ChatGateway,
  ],
})
export class AppModule {}
