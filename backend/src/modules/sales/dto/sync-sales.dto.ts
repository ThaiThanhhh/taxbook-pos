
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsISO8601,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

// Các phương thức thanh toán được hệ thống hỗ trợ
export enum PaymentMethod {
  CASH = 'CASH',
  QR_TRANSFER = 'QR_TRANSFER',
  CARD = 'CARD',
}

// Thông tin một sản phẩm trong đơn hàng
export class SaleItemInputDto {
  @IsString()
  @IsNotEmpty()
  product_id!: string;

  @IsInt()
  @Min(1)
  qty!: number;

  @IsInt()
  @Min(0)
  @Max(Number.MAX_SAFE_INTEGER)
  unit_price_vnd!: number;
}

// Thông tin thanh toán
export class PaymentInputDto {
  @IsEnum(PaymentMethod)
  method!: PaymentMethod;

  @IsInt()
  @Min(0)
  @Max(Number.MAX_SAFE_INTEGER)
  amount_vnd!: number;

  @IsOptional()
  @IsString()
  reference?: string;
}

// Thông tin một đơn bán trên thiết bị
export class SyncSaleDto {
  @IsUUID()
  client_op_id!: string;

  @IsInt()
  @Min(1)
  local_seq!: number;

  @IsISO8601({ strict: true })
  client_created_at!: string;

  @IsOptional()
  @IsString()
  tmp_number?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => SaleItemInputDto)
  items!: SaleItemInputDto[];

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(Number.MAX_SAFE_INTEGER)
  discount_vnd?: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => PaymentInputDto)
  payments!: PaymentInputDto[];
}

// Dữ liệu gửi lên API POST /sync/sales
export class SyncSalesRequestDto {
  @IsString()
  @IsNotEmpty()
  device_id!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @ValidateNested({ each: true })
  @Type(() => SyncSaleDto)
  sales!: SyncSaleDto[];
}
