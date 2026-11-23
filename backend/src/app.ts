import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Database, DatabaseModule } from './common/database';
import { ApiErrorFilter } from './common/http';
import { AppModule } from './app.module';
import { UnprocessableEntityException } from '@nestjs/common';

export async function createApp(database?: Database) {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must contain at least 32 characters');
  }
  if (!database && !process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const app = await NestFactory.create({ module: AppModule, imports: [DatabaseModule.register(database)] }, { logger: false });
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe({
    transform: true, whitelist: true, forbidNonWhitelisted: true,
    exceptionFactory: errors => new UnprocessableEntityException({ message: 'Invalid input',
      details: errors.map(error => ({ field: error.property, reason: Object.values(error.constraints ?? {}).join('; ') })),
    }),
  }));
  app.useGlobalFilters(new ApiErrorFilter());
  app.enableShutdownHooks();
  return app;
}
