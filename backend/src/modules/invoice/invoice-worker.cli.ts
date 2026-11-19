
import 'reflect-metadata';

import { Module } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import {
  Database,
  DatabaseModule,
} from '../../common/database';

import { InvoiceModule } from './invoice.module';
import { InvoiceOutboxWorkerService } from './invoice-outbox-worker.service';

@Module({
  imports: [
    DatabaseModule.register(),
    InvoiceModule,
  ],
})
class InvoiceWorkerCliModule {}

async function main() {
  const connection = process.env.DATABASE_URL;

  if (!connection) {
    throw new Error('Thiếu DATABASE_URL');
  }

  const url = new URL(connection);

  // Chỉ cho phép PostgreSQL chạy trên máy cá nhân.
  if (
    !['postgres:', 'postgresql:'].includes(url.protocol) ||
    !['localhost', '127.0.0.1'].includes(url.hostname)
  ) {
    throw new Error(
      'Worker thử nghiệm chỉ hỗ trợ PostgreSQL local',
    );
  }

  // Luôn dùng database thử nghiệm, không dùng dt13.
  url.pathname = '/taxbook_sales_test';
  process.env.DATABASE_URL = url.toString();

  const app = await NestFactory.createApplicationContext(
    InvoiceWorkerCliModule,
    { logger: ['error', 'warn'] },
  );

  try {
    const database = app.get(Database);

    const check = await database.query<{
      db: string;
      outbox_table: string | null;
    }>(
      `SELECT
        current_database() AS db,
        to_regclass('public.invoice_outbox')::text
          AS outbox_table`,
    );

    if (
      check.rows[0]?.db !== 'taxbook_sales_test' ||
      !check.rows[0]?.outbox_table
    ) {
      throw new Error(
        'Database thử nghiệm chưa có bảng invoice_outbox',
      );
    }

    const worker = app.get(
      InvoiceOutboxWorkerService,
    );

    // Chỉ xử lý một công việc mỗi lần chạy.
    const result = await worker.processNext();

    console.log('Ket qua Invoice Worker:', result);
  } finally {
    await app.close();
  }
}

void main().catch((error: unknown) => {
  console.error(
    'Invoice Worker loi:',
    error instanceof Error ? error.message : error,
  );
  process.exitCode = 1;
});
