import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/current-user.decorator';
import { ReportsService } from './reports.service';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() body: any) {
    return this.reports.create(user.sub, body);
  }

  @Get('mine')
  mine(@CurrentUser() user: any) {
    return this.reports.mine(user.sub);
  }
}
