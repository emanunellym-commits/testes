import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(private readonly config: ConfigService) {}

  async send(phone: string, message: string) {
    const provider = this.config.get<string>('SMS_PROVIDER');

    if (!provider) {
      this.logger.warn(`SMS simulado para ${phone}: ${message}`);
      return { simulated: true };
    }

    // Integração real deve ser implementada com seu provedor:
    // Twilio, Zenvia, Infobip, AWS SNS, etc.
    // Não deixe credenciais dentro do app mobile.
    return { queued: true, provider };
  }
}
