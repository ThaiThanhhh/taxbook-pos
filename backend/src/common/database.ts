import { DynamicModule, Global, Injectable, Module, OnModuleDestroy } from '@nestjs/common';
import { Pool, QueryResultRow } from 'pg';

export interface SqlClient {
  query<T extends QueryResultRow = QueryResultRow>(sql: string, values?: unknown[]): Promise<{ rows: T[] }>;
}

@Injectable()
export class Database implements OnModuleDestroy {
  private readonly pool = new Pool({ connectionString: process.env.DATABASE_URL });

  query<T extends QueryResultRow = QueryResultRow>(sql: string, values?: unknown[]) {
    return this.pool.query<T>(sql, values);
  }

  async transaction<T>(work: (client: SqlClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async onModuleDestroy() { await this.pool.end(); }
}

@Global()
@Module({})
export class DatabaseModule {
  static register(database?: Database): DynamicModule {
    return { module: DatabaseModule, providers: [database ? { provide: Database, useValue: database } : Database], exports: [Database] };
  }
}
