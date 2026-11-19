
import 'reflect-metadata';

import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { jest } from '@jest/globals';
import { sign } from 'jsonwebtoken';

import { LedgerAuthGuard } from '../../common/http';
import { SalesController } from './sales.controller';
import { SalesService } from './sales.service';

describe('SalesController - HTTP JWT', () => {
  let app: INestApplication;
  let baseUrl: string;

  const secret = 'sales-http-test-secret-at-least-32-characters';
  const previousSecret = process.env.JWT_SECRET;

  const findByIdMock = jest.fn<
    (householdId: string, saleId: string) =>
      Promise<{ id: string; status: string }>
  >();

  function makeToken(role = 'OWNER') {
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

  beforeAll(async () => {
    process.env.JWT_SECRET = secret;

    const moduleRef = await Test.createTestingModule({
      controllers: [SalesController],
      providers: [
        LedgerAuthGuard,
        {
          provide: SalesService,
          useValue: { findById: findByIdMock },
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');

    await app.listen(0, '127.0.0.1');
    baseUrl = await app.getUrl();
  });

  beforeEach(() => {
    findByIdMock.mockReset();
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
    const response = await fetch(
      `${baseUrl}/api/v1/sales/sale-001`,
    );

    expect(response.status).toBe(401);
    expect(findByIdMock).not.toHaveBeenCalled();
  });

  it('Từ chối vai trò STAFF', async () => {
    const response = await fetch(
      `${baseUrl}/api/v1/sales/sale-001`,
      {
        headers: {
          Authorization: `Bearer ${makeToken('STAFF')}`,
        },
      },
    );

    expect(response.status).toBe(403);
    expect(findByIdMock).not.toHaveBeenCalled();
  });

  it('JWT hợp lệ được xem đơn đúng hộ kinh doanh', async () => {
    findByIdMock.mockResolvedValue({
      id: 'sale-001',
      status: 'SYNCED',
    });

    const response = await fetch(
      `${baseUrl}/api/v1/sales/sale-001`,
      {
        headers: {
          Authorization: `Bearer ${makeToken()}`,
        },
      },
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      id: 'sale-001',
      status: 'SYNCED',
    });

    expect(findByIdMock).toHaveBeenCalledWith(
      'household-001',
      'sale-001',
    );
  });
});
