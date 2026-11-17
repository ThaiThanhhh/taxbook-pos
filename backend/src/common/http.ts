import {
  ArgumentsHost, CanActivate, Catch, createParamDecorator, ExceptionFilter,
  ExecutionContext, ForbiddenException, HttpException, Injectable, UnauthorizedException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Request, Response } from 'express';
import { verify } from 'jsonwebtoken';

export interface Principal { household_id: string; role: 'OWNER' | 'ACCOUNTANT' | 'ADMIN' }
type AuthRequest = Request & { principal?: Principal };

@Injectable()
export class LedgerAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<AuthRequest>();
    const token = /^Bearer (\S+)$/.exec(request.headers.authorization ?? '')?.[1];
    if (!token) throw new UnauthorizedException('Bearer token required');
    let claims;
    try {
      claims = verify(token, process.env.JWT_SECRET!, {
        algorithms: ['HS256'], issuer: process.env.JWT_ISSUER ?? 'taxbook-pos',
        audience: process.env.JWT_AUDIENCE ?? 'taxbook-pos-api',
      });
    } catch { throw new UnauthorizedException('Invalid or expired token'); }
    if (typeof claims === 'string' || typeof claims.household_id !== 'string' ||
        !claims.household_id.trim() || claims.household_id.length > 200 || typeof claims.exp !== 'number') {
      throw new UnauthorizedException('Token requires household_id and expiry');
    }
    if (!['OWNER', 'ACCOUNTANT', 'ADMIN'].includes(claims.role)) throw new ForbiddenException();
    request.principal = { household_id: claims.household_id, role: claims.role };
    return true;
  }
}

export const CurrentUser = createParamDecorator((_data: unknown, context: ExecutionContext) =>
  context.switchToHttp().getRequest<AuthRequest>().principal!);

export function invalid(field: string, reason: string): never {
  throw new UnprocessableEntityException({ message: 'Invalid input', details: [{ field, reason }] });
}

@Catch()
export class ApiErrorFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost) {
    const originalStatus = error instanceof HttpException ? error.getStatus() : 500;
    const status = [400, 413].includes(originalStatus) ? 422 : originalStatus;
    const body = error instanceof HttpException ? error.getResponse() : null;
    const value = typeof body === 'object' && body !== null ? body as Record<string, unknown> : {};
    const codes: Record<number, string> = {
      401: 'UNAUTHENTICATED', 403: 'FORBIDDEN', 404: 'NOT_FOUND',
      409: 'CONFLICT', 422: 'VALIDATION_FAILED', 503: 'PROVIDER_UNAVAILABLE',
    };
    if (status >= 500) console.error(error);
    host.switchToHttp().getResponse<Response>().status(status).json({ error: {
      code: value.code ?? codes[status] ?? 'PROVIDER_UNAVAILABLE',
      message: status >= 500 ? 'Service unavailable' : value.message ?? body,
      details: value.details ?? [], trace_id: randomUUID(),
    } });
  }
}
