import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { mkdirSync } from 'fs';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

const uploadPath = 'uploads';
mkdirSync(uploadPath, { recursive: true });

@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: uploadPath,
        filename: (_, file, callback) => {
          const safeExt = extname(file.originalname).toLowerCase();
          const random = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          callback(null, `${random}${safeExt}`);
        },
      }),
      limits: { fileSize: 25 * 1024 * 1024 },
    }),
  )
  upload(@UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Arquivo não enviado');

    return {
      url: `/uploads/${file.filename}`,
      name: file.originalname,
      mime: file.mimetype,
      size: file.size,
    };
  }
}
