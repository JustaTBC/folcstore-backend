/**
 * PI4-241 — verifica o acesso do Prisma 6.19.3 ao PostgreSQL SEM migrations.
 * Execute a partir da raiz de folcstore-backend:
 *     node scripts/pi4-241-verificar-postgres.mjs
 *
 * Le apenas .env.postgres, sem substituir o .env SQLite da equipe.
 */
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import process from 'node:process';
import { parse } from 'dotenv';

const raiz = process.cwd();
const arquivoEnv = resolve(raiz, '.env.postgres');
const schema = join(raiz, 'prisma', 'postgresql', 'schema.prisma');
const cli = join(raiz, 'node_modules', 'prisma', 'build', 'index.js');
const sql = join(raiz, 'scripts', 'pi4-241-conexao.sql');

function falhar(msg) {
  console.error(`ERRO PI4-241: ${msg}`);
  process.exit(1);
}

if (!existsSync(arquivoEnv)) falhar('Copie postgres.example.env para .env.postgres.');
if (!existsSync(schema)) falhar('Nao encontrei prisma/postgresql/schema.prisma. Execute na raiz do backend.');
if (!existsSync(cli)) falhar('Prisma nao instalado. Execute npm ci antes.');
if (!existsSync(sql)) falhar('Arquivo scripts/pi4-241-conexao.sql nao encontrado.');

let cfg;
try { cfg = parse(readFileSync(arquivoEnv)); }
catch (error) { falhar(`Nao foi possivel ler .env.postgres: ${error.message}`); }

const usuario = cfg.POSTGRES_USER || 'folcstore';
const banco = cfg.POSTGRES_DB || 'folcstore';
const senha = cfg.POSTGRES_PASSWORD || '';
const porta = Number(cfg.POSTGRES_PORT || '5433');

if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(usuario)) falhar('POSTGRES_USER invalido.');
if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(banco)) falhar('POSTGRES_DB invalido.');
if (!senha || senha === 'SUBSTITUA_POR_SENHA_FORTE') falhar('Defina uma senha em POSTGRES_PASSWORD.');
if (!Number.isInteger(porta) || porta < 1 || porta > 65535) falhar('POSTGRES_PORT invalida.');

// Codificacao da senha evita erros com caracteres como @, :, #, /.
const url = `postgresql://${encodeURIComponent(usuario)}:${encodeURIComponent(senha)}@127.0.0.1:${porta}/${encodeURIComponent(banco)}?schema=public`;
const env = {
  ...process.env,
  DATABASE_URL: url,
  DATABASE_URL_UNPOOLED: url,
};

function prisma(args, etapa) {
  console.log(etapa);
  const result = spawnSync(process.execPath, [cli, ...args], {
    cwd: raiz, env, stdio: 'inherit', shell: false,
  });
  if (result.error) falhar(`Falha ao iniciar Prisma: ${result.error.message}`);
  if (result.status !== 0) falhar(`Prisma retornou codigo ${result.status ?? 'desconhecido'}.`);
}

prisma(['validate', '--schema', schema], '1/2 — Validando schema Prisma PostgreSQL...');
prisma(['db', 'execute', '--schema', schema, '--file', sql], '2/2 — Testando SELECT 1 no PostgreSQL...');
console.log('\nSUCESSO PI4-241: PostgreSQL acessivel pelo Prisma. Nenhuma tabela foi criada.');
