import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    reporterId: string,
    body: {
      reportedUserId?: string;
      conversationId?: string;
      messageId?: string;
      reason: any;
      details?: string;
    },
  ) {
    if (!body.reportedUserId && !body.messageId) {
      throw new BadRequestException('Informe um usuário ou mensagem para denunciar');
    }

    return this.prisma.report.create({
      data: {
        reporterId,
        reportedUserId: body.reportedUserId,
        conversationId: body.conversationId,
        messageId: body.messageId,
        reason: body.reason,
        details: body.details?.trim() || null,
      },
    });
  }

  mine(reporterId: string) {
    return this.prisma.report.findMany({
      where: { reporterId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
