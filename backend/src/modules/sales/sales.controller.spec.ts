
import 'reflect-metadata';

import { jest } from '@jest/globals';
import { GUARDS_METADATA } from '@nestjs/common/constants';

import {
  LedgerAuthGuard,
  type Principal,
} from '../../common/http';

import { SalesController } from './sales.controller';
import { SalesService } from './sales.service';

describe('SalesController', () => {
  const findByIdMock = jest.fn<
    (householdId: string, saleId: string) =>
      Promise<{ id: string; status: string }>
  >();

  const controller = new SalesController({
    findById: findByIdMock,
  } as unknown as SalesService);

  const user: Principal = {
    household_id: 'household-001',
    role: 'OWNER',
  };

  beforeEach(() => {
    findByIdMock.mockReset();
  });

  it('Lấy đơn theo đúng hộ kinh doanh', async () => {
    const sale = {
      id: 'sale-001',
      status: 'SYNCED',
    };

    findByIdMock.mockResolvedValue(sale);

    const result = await controller.findById(
      user,
      'sale-001',
    );

    expect(result).toEqual(sale);
    expect(findByIdMock).toHaveBeenCalledWith(
      'household-001',
      'sale-001',
    );
  });

  it('Controller được bảo vệ bằng JWT guard', () => {
    const guards = Reflect.getMetadata(
      GUARDS_METADATA,
      SalesController,
    ) as unknown[];

    expect(guards).toContain(LedgerAuthGuard);
  });
});
