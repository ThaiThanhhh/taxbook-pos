import { createApp } from './app';

async function main() {
  const app = await createApp();
  // Local by default; deployment must explicitly configure HOST and JWT settings.
  await app.listen(Number(process.env.PORT ?? 3000), process.env.HOST ?? '127.0.0.1');
}
void main().catch(error => { console.error(error.message); process.exitCode = 1; });
