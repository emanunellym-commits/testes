import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ContactsService {
  constructor(private readonly prisma: PrismaService) {}

  list(ownerId: string) {
    return this.prisma.contact.findMany({
      where: { ownerId },
      include: { contact: { select: { id: true, username: true, displayName: true, avatarUrl: true, personalMsg: true, status: true } } },
      orderBy: [{ favorite: 'desc' }, { createdAt: 'asc' }],
    });
  }

  async add(ownerId: string, contactId: string) {
    if (ownerId === contactId) throw new BadRequestException('Você não pode adicionar a si mesmo');
    const target = await this.prisma.user.findUnique({ where: { id: contactId } });
    if (!target) throw new NotFoundException('Usuário não encontrado');
    return this.prisma.contact.upsert({
      where: { ownerId_contactId: { ownerId, contactId } },
      update: { blocked: false },
      create: { ownerId, contactId },
      include: { contact: { select: { id: true, username: true, displayName: true, avatarUrl: true, personalMsg: true, status: true } } },
    });
  }
}
