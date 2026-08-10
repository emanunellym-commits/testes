import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, body: { subject: string; category?: string; priority?: any; message: string }) {
    return this.prisma.supportTicket.create({
      data: {
        userId,
        subject: body.subject.trim(),
        category: body.category?.trim() || null,
        priority: body.priority ?? 'NORMAL',
        messages: {
          create: {
            authorId: userId,
            body: body.message.trim(),
          },
        },
      },
      include: { messages: true },
    });
  }

  listMine(userId: string) {
    return this.prisma.supportTicket.findMany({
      where: { userId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async reply(userId: string, ticketId: string, body: string, staff = false) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: { user: { select: { id: true } } },
    });
    if (!ticket) throw new NotFoundException('Ticket não encontrado');

    if (!staff && ticket.userId !== userId) {
      throw new ForbiddenException('Acesso negado');
    }

    const msg = await this.prisma.supportMessage.create({
      data: {
        ticketId,
        authorId: userId,
        body: body.trim(),
      },
    });

    await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        updatedAt: new Date(),
        status: staff ? 'WAITING_USER' : 'WAITING_SUPPORT',
      },
    });

    return msg;
  }

  listAll() {
    return this.prisma.supportTicket.findMany({
      include: {
        user: {
          select: { id: true, displayName: true, username: true, email: true },
        },
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: [
        { priority: 'desc' },
        { updatedAt: 'desc' },
      ],
      take: 300,
    });
  }
}
