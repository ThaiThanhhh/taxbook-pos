import { Type } from 'class-transformer';
import { IsDateString, IsIn, IsInt, IsString, Matches, Max, MaxLength, Min, MinLength, ValidateIf } from 'class-validator';

const Optional = () => ValidateIf((_object, value) => value !== undefined);

export class ExpenseInput {
  @IsDateString({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) date!: string;
  @IsInt() @Min(1) @Max(Number.MAX_SAFE_INTEGER) amount_vnd!: number;
  @IsString() @MinLength(1) @MaxLength(200) category!: string;
  @Optional() @IsString() @MaxLength(200) vendor?: string;
  @Optional() @IsString() @MaxLength(2000) image_url?: string;
  @Optional() @IsIn(['MANUAL', 'OCR']) source?: 'MANUAL' | 'OCR';
}

export class PageQuery {
  @Optional() @IsString() @MaxLength(2000) cursor?: string;
  @Optional() @Type(() => Number) @IsInt() @Min(1) @Max(200) limit = 50;
}
export class LedgerQuery extends PageQuery {
  @Optional() @IsString() @MinLength(1) @MaxLength(100) book?: string;
  @Optional() @IsDateString({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) from?: string;
  @Optional() @IsDateString({ strict: true }) @Matches(/^\d{4}-\d{2}-\d{2}$/) to?: string;
}
export class BankQuery extends PageQuery {
  @Optional() @IsIn(['MATCHED', 'UNMATCHED']) status?: string;
}
export class BankMatchInput {
  @IsIn(['CONFIRM', 'UNMATCH']) action!: 'CONFIRM' | 'UNMATCH';
  @Optional() @IsString() ledger_id?: string;
}
