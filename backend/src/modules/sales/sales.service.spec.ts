import { jest } from '@jest/globals';
import { NotFoundException } from '@nestjs/common';
import { SalesService } from './sales.service';
import { SalesRepository } from './sales.repository';

describe('SalesService', () => {
  let service: SalesService;


const repositoryMock = {
  findById: jest.fn<
    (
      householdId: string,
      saleId: string,
    ) => Promise<{
      id: string;
      total_vnd: string;
      status: string;
    } | null>
  >(),
};


  beforeEach(() => {
    jest.clearAllMocks();

    service = new SalesService(
      repositoryMock as unknown as SalesRepository,
    );
  });

  it('Trả về đơn hàng khi tìm thấy', async () => {
    const sale = {
      id: 'sale-001',
      total_vnd: '90000',
      status: 'SYNCED',
    };

    repositoryMock.findById.mockResolvedValue(sale);

    const result = await service.findById(
  'household-001',
  'sale-001',
);

    expect(result).toEqual(sale);
   expect(repositoryMock.findById).toHaveBeenCalledWith(
  'household-001',
  'sale-001',
);
  });

  it('Báo lỗi 404 khi không tìm thấy đơn hàng', async () => {
    repositoryMock.findById.mockResolvedValue(null);

    await expect(
      service.findById(
  'household-001',
  'sale-not-found',
)
    ).rejects.toThrow(NotFoundException);
  });
});
