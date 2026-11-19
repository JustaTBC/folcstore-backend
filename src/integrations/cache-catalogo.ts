import { createHash } from 'node:crypto';
import Redis from 'ioredis';
import { env } from '../config/env';
import { prisma } from '../config/prisma';

const redis = env.REDIS_URL ? new Redis(env.REDIS_URL, {
  lazyConnect: true,
  connectTimeout: 500,
  commandTimeout: 700,
  maxRetriesPerRequest: 0,
  enableOfflineQueue: false,
  retryStrategy: () => null,
}) : undefined;

// Falhas do Redis usam o banco. Nunca registre a URL, que pode conter senha.
redis?.on('error', () => {});
const banco = createHash('sha256').update(env.DATABASE_URL).digest('hex').slice(0, 16);

export async function listarComCache(
  filtros: Record<string, unknown>,
  carregar: () => Promise<unknown>,
): Promise<{ corpo: string; origem: 'REDIS' | 'BANCO' }> {
  if (!redis) return { corpo: JSON.stringify(await carregar()), origem: 'BANCO' };
  let chave: string | undefined;
  try {
    if (redis.status === 'wait' || redis.status === 'end') await redis.connect();
    if (redis.status === 'ready') {
      const { versao } = await prisma.versaoCatalogo.findUniqueOrThrow({ where: { id: 1 } });
      const parametros = JSON.stringify(Object.entries(filtros).sort(([a], [b]) => a.localeCompare(b)));
      const hash = createHash('sha256').update(parametros).digest('hex');
      chave = `folcstore:${banco}:catalogo:v${versao}:${hash}`;
      const salvo = await redis.get(chave);
      if (salvo !== null) {
        JSON.parse(salvo);
        return { corpo: salvo, origem: 'REDIS' };
      }
    }
  } catch {
    chave = undefined;
  }

  const corpo = JSON.stringify(await carregar());
  if (chave) {
    try {
      await redis.set(chave, corpo, 'EX', env.CACHE_CATALOGO_TTL_SEGUNDOS);
    } catch {
      // O resultado já veio do banco e pode ser devolvido.
    }
  }
  return { corpo, origem: 'BANCO' };
}

export function encerrarCache() {
  redis?.disconnect();
}
