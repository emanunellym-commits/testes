import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import * as admin from 'firebase-admin';
import { existsSync, readFileSync } from 'fs';

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private app?: admin.app.App;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.initFirebase();
  }

  private initFirebase() {
    try {
      const path = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
      if (!path || !existsSync(path)) {
        this.logger.warn('Firebase service account não configurado; push ficará desativado.');
        return;
      }

      const serviceAccount = JSON.parse(readFileSync(path, 'utf8'));

      this.app = admin.apps.length
        ? admin.app()
        : admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });

      this.logger.log('Firebase Admin inicializado.');
    } catch (e) {
      this.logger.error('Falha ao inicializar Firebase Admin', e as Error);
    }
  }

  async sendToUsers(
    userIds: string[],
    title: string,
    body: string,
    data: Record<string, string> = {},
  ) {
    if (!this.app || userIds.length === 0) return { sent: 0 };

    const rows = await this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds } },
      select: { token: true },
    });

    const tokens = rows.map(r => r.token);
    if (!tokens.length) return { sent: 0 };

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: {
          channelId: data['kind'] === 'incoming_call' ? 'calls' : 'messages',
          sound: 'default',
        },
      },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
    });

    return { sent: response.successCount, failed: response.failureCount };
  }
}
