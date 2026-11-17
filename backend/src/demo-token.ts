import { sign } from 'jsonwebtoken';

if (process.env.NODE_ENV === 'production') throw new Error('Demo token tool is disabled in production');
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) throw new Error('Configure JWT_SECRET in backend/.env first');
console.log(sign({ household_id: process.argv[2] ?? 'demo-household', role: 'OWNER' }, process.env.JWT_SECRET, {
  algorithm: 'HS256', issuer: process.env.JWT_ISSUER ?? 'taxbook-pos',
  audience: process.env.JWT_AUDIENCE ?? 'taxbook-pos-api', expiresIn: '15m',
}));
