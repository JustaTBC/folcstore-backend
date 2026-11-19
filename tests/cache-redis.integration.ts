import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, randomUUID, createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import jwt from 'jsonwebtoken';
import Redis from 'ioredis';
import request from 'supertest';
import type { Express } from 'express';
import type { PrismaClient } from '@prisma/client';

let app: Express, prisma: PrismaClient, redis: Redis, pasta: string;
let categoriaId: string, tokenArtesao: string;
let encerrarCache: () => void;

before(async () => {
  if (!process.env.TEST_REDIS_URL) throw new Error('Defina TEST_REDIS_URL para uma instância Redis de teste.');
  process.env.REDIS_URL = process.env.TEST_REDIS_URL;
  process.env.JWT_SECRET = randomBytes(32).toString('hex');
  pasta = await mkdtemp(path.join(tmpdir(), 'folcstore-cache-'));
  process.env.DATABASE_URL = `file:${path.join(pasta, 'test.db').replaceAll('\\', '/')}`;
  execFileSync(process.execPath, ['node_modules/tsx/dist/cli.mjs', 'scripts/migrate.ts'], {
    env: process.env, stdio: 'pipe',
  });
  redis = new Redis(process.env.TEST_REDIS_URL, { maxRetriesPerRequest: 0 });
  await redis.ping();
  ({ app } = await import('../src/app'));
  ({ prisma } = await import('../src/config/prisma'));
  ({ encerrarCache } = await import('../src/integrations/cache-catalogo'));
  categoriaId = (await prisma.categoria.create({ data: { nome: 'Cerâmica de teste' } })).id;
  const artesao = await prisma.usuario.create({
    data: { nome: 'Artesão teste', email: 'cache@example.com', senhaHash: 'teste', perfil: 'ARTESAO' },
  });
  tokenArtesao = token(artesao.id);
});

after(async () => {
  encerrarCache?.();
  redis?.disconnect();
  await prisma?.$disconnect();
  if (pasta) await rm(pasta, { recursive: true, force: true });
});

function token(id: string) {
  return jwt.sign({}, process.env.JWT_SECRET!, {
    subject: id, issuer: 'folcstore-backend', audience: 'folcstore', expiresIn: '1h',
  });
}

function produto(titulo: string) {
  return { titulo, descricao: 'Produto artesanal usado no teste de cache.', tecnica: 'Barro',
    regiaoProducao: 'Recife', categoriaId, precoCentavos: 1200, quantidadeEstoque: 5, tipo: 'LOTE' };
}

async function criar(titulo: string) {
  return (await request(app).post('/api/produtos').auth(tokenArtesao, { type: 'bearer' })
    .send(produto(titulo)).expect(201)).body;
}

test('Redis: reutiliza a listagem, separa filtros/páginas e define expiração', async t => {
  await criar('Vaso');
  await criar('Prato');
  const { produtoRepository } = await import('../src/repositories/produto.repository');
  const original = produtoRepository.listar;
  let consultas = 0;
  produtoRepository.listar = (...args) => { consultas++; return original(...args); };
  t.after(() => { produtoRepository.listar = original; });
  const primeira = await request(app).get('/api/produtos?limite=1&pagina=1').expect(200);
  const repetida = await request(app).get('/api/produtos?pagina=1&limite=1').expect(200);
  assert.deepEqual(repetida.body, primeira.body);
  assert.equal(primeira.headers['x-cache-catalogo'], 'BANCO');
  assert.equal(repetida.headers['x-cache-catalogo'], 'REDIS');
  assert.equal(consultas, 1);
  const pagina2 = await request(app).get('/api/produtos?pagina=2&limite=1').expect(200);
  assert.notEqual(pagina2.body.dados[0].id, primeira.body.dados[0].id);
  const filtrada = await request(app).get('/api/produtos?busca=Prato').expect(200);
  assert.equal(filtrada.body.total, 1);
  assert.equal(filtrada.body.dados[0].titulo, 'Prato');
  assert.equal(consultas, 3);
  const banco = createHash('sha256').update(process.env.DATABASE_URL!).digest('hex').slice(0, 16);
  const chaves = await redis.keys(`folcstore:${banco}:catalogo:*`);
  assert.equal(chaves.length, 3);
  for (const chave of chaves) assert.ok(await redis.ttl(chave) > 0);
});

test('Redis: criação, edição e exclusão invalidam listagens anteriores', async () => {
  const antes = (await request(app).get('/api/produtos').expect(200)).body;
  const novo = await criar('Escultura');
  const criado = (await request(app).get('/api/produtos').expect(200)).body;
  assert.equal(criado.total, antes.total + 1);
  await request(app).put(`/api/produtos/${novo.id}`).auth(tokenArtesao, { type: 'bearer' })
    .send({ ...produto('Escultura'), precoCentavos: 1800 }).expect(200);
  const editado = (await request(app).get('/api/produtos').expect(200)).body;
  assert.equal(editado.dados.find((p: { id: string }) => p.id === novo.id).precoCentavos, 1800);
  await request(app).delete(`/api/produtos/${novo.id}`).auth(tokenArtesao, { type: 'bearer' }).expect(204);
  assert.equal((await request(app).get('/api/produtos').expect(200)).body.total, antes.total);
});

test('Redis: checkout atualiza estoque no catálogo e repetição preserva a versão', async () => {
  const novo = await criar('Vaso para compra');
  const cliente = await prisma.usuario.create({ data: {
    nome: 'Cliente teste', email: 'cliente-cache@example.com', senhaHash: 'teste',
    enderecos: { create: { cep: '50000000', rua: 'Rua teste', numero: '1', bairro: 'Centro', cidade: 'Recife', estado: 'PE' } },
  }, include: { enderecos: true } });
  const autorizacao = token(cliente.id);
  await request(app).get('/api/produtos').expect(200);
  const carrinho = (await request(app).put(`/api/carrinho/itens/${novo.id}`)
    .auth(autorizacao, { type: 'bearer' }).send({ quantidade: 1 }).expect(200)).body;
  const corpo = { enderecoId: cliente.enderecos[0].id, metodoPagamento: 'PIX',
    versaoCarrinho: carrinho.versao, totalEsperadoCentavos: carrinho.totalCentavos };
  const chave = randomUUID();
  await request(app).post('/api/pedidos').auth(autorizacao, { type: 'bearer' })
    .set('Idempotency-Key', chave).send(corpo).expect(201);
  const lista = (await request(app).get('/api/produtos').expect(200)).body;
  assert.equal(lista.dados.find((p: { id: string }) => p.id === novo.id).quantidadeEstoque, 4);
  const versao = await prisma.versaoCatalogo.findUniqueOrThrow({ where: { id: 1 } });
  await request(app).post('/api/pedidos').auth(autorizacao, { type: 'bearer' })
    .set('Idempotency-Key', chave).send(corpo).expect(200);
  assert.deepEqual(await prisma.versaoCatalogo.findUniqueOrThrow({ where: { id: 1 } }), versao);
});

test('Redis: uma leitura iniciada antes da edição não repovoa a versão atual', async t => {
  const novo = await criar('Vaso concorrente');
  const { produtoRepository } = await import('../src/repositories/produto.repository');
  const original = produtoRepository.listar;
  let confirmarLeitura!: () => void;
  let liberarLeitura!: () => void;
  const carregou = new Promise<void>(resolve => { confirmarLeitura = resolve; });
  const continuar = new Promise<void>(resolve => { liberarLeitura = resolve; });
  produtoRepository.listar = async (...args) => {
    const resultado = await original(...args);
    confirmarLeitura();
    await continuar;
    return resultado;
  };
  t.after(() => { liberarLeitura(); produtoRepository.listar = original; });
  const pendente = request(app).get('/api/produtos?busca=concorrente').expect(200).then(res => res.body);
  await carregou;
  await request(app).put(`/api/produtos/${novo.id}`).auth(tokenArtesao, { type: 'bearer' })
    .send({ ...produto('Vaso concorrente'), precoCentavos: 2500 }).expect(200);
  liberarLeitura();
  assert.equal((await pendente).dados[0].precoCentavos, 1200);
  const atual = await request(app).get('/api/produtos?busca=concorrente').expect(200);
  assert.equal(atual.body.dados[0].precoCentavos, 2500);
});
