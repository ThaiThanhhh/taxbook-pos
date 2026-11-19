
import 'reflect-metadata';

import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { jest } from '@jest/globals';
import { sign } from 'jsonwebtoken';

import { LedgerAuthGuard } from '../../common/http';
import { SalesSyncController } from './sales-sync.controller';
import { SalesAccountingContextService } from './sales-accounting-context.service';
import { SalesPostingService } from './sales-posting.service';
import { SalesRepository } from './sales.repository';
import { SalesService } from './sales.service';
import { SalesLedgerAdapter } from './sales-ledger.adapter';

describe('SalesSyncController - HTTP', () => {
  let app: INestApplication;
  let baseUrl: string;

  const previousSecret = process.env.JWT_SECRET;
  const secret = 'sales-sync-test-secret-at-least-32-characters';
  const createSale = jest.fn();

  const validBody = {
    device_id: 'dev-001',
    sales: [
      {
        client_op_id: 'b3c1d2e4-5f60-4a7b-9c8d-0e1f2a3b4c5d',
        local_seq: 1,
        client_created_at: '2026-11-19T05:12:44Z',
        items: [
          {
            product_id: 'p-001',
            qty: 2,
            unit_price_vnd: 45000,
          },
        ],
        payments: [
          {
            method: 'CASH',
            amount_vnd: 90000,
          },
        ],
      },
    ],
  };

  function token(role: string) {
    return sign(
      { household_id: 'household-001', role },
      secret,
      {
        algorithm: 'HS256',
        issuer: process.env.JWT_ISSUER ?? 'taxbook-pos',
        audience: process.env.JWT_AUDIENCE ?? 'taxbook-pos-api',
        expiresIn: '5m',
      },
    );
  }

  async function post(body: unknown, role?: string) {
    return fetch(`${baseUrl}/api/v1/sync/sales`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(role
          ? { Authorization: `Bearer ${token(role)}` }
          : {}),
      },
      body: JSON.stringify(body),
    });
  }

  beforeAll(async () => {
    process.env.JWT_SECRET = secret;

    const moduleRef = await Test.createTestingModule({
      controllers: [SalesSyncController],
      providers: [
        LedgerAuthGuard,
        SalesAccountingContextService,
        SalesPostingService,
        SalesService,
        {
          provide: SalesRepository,
          useValue: { createSale },
        },
        {
          provide: SalesLedgerAdapter,
          useValue: { recordAcceptedSale: jest.fn() },
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.listen(0, '127.0.0.1');
    baseUrl = await app.getUrl();
  });

  beforeEach(() => {
    createSale.mockClear();
  });

  afterAll(async () => {
    if (app) await app.close();

    if (previousSecret === undefined) {
      delete process.env.JWT_SECRET;
    } else {
      process.env.JWT_SECRET = previousSecret;
    }
  });

  it('Từ chối request không có JWT', async () => {
    const response = await post(validBody);

    expect(response.status).toBe(401);
    expect(createSale).not.toHaveBeenCalled();
  });

  it('Từ chối vai trò STAFF', async () => {
    const response = await post(validBody, 'STAFF');

    expect(response.status).toBe(403);
    expect(createSale).not.toHaveBeenCalled();
  });

  it('Từ chối lô đơn hàng rỗng', async () => {
    const response = await post(
      { device_id: 'dev-001', sales: [] },
      'OWNER',
    );

    expect(response.status).toBe(400);
    expect(createSale).not.toHaveBeenCalled();
  });

  it('Chưa có mã ngành thì trả 503 và không lưu đơn', async () => {
    const response = await post(validBody, 'OWNER');

    expect(response.status).toBe(503);
    expect(createSale).not.toHaveBeenCalled();
  });
});
