import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly config: ConfigService) {}

  private transport() {
    const host = this.config.get<string>('SMTP_HOST');
    const port = Number(this.config.get<string>('SMTP_PORT') ?? 587);
    const user = this.config.get<string>('SMTP_USER');
    const pass = this.config.get<string>('SMTP_PASS');

    if (!host || !user || !pass) return null;

    return nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });
  }

  async send(to: string, subject: string, text: string) {
    const transport = this.transport();
    if (!transport) {
      this.logger.warn(`SMTP não configurado. E-mail simulado para ${to}: ${subject}`);
      return { simulated: true };
    }

    await transport.sendMail({
      from: this.config.get<string>('MAIL_FROM') ?? 'LiveChat <no-reply@livechat.local>',
      to,
      subject,
      text,
    });

    return { sent: true };
  }
}
