import { RequestHandler } from 'express';
import { produtoService } from '../services/produto.service';
import { filtrosSchema, idSchema, produtoSchema } from '../validators/produto.schema';
import { listarComCache } from '../integrations/cache-catalogo';

export const listar: RequestHandler = async (req, res) => {
  const filtros = filtrosSchema.parse(req.query);
  const resultado = await listarComCache(filtros, () => produtoService.listar(filtros));
  res.set('X-Cache-Catalogo', resultado.origem).type('json').send(resultado.corpo);
};
export const buscar: RequestHandler = async (req, res) => {
  res.json(await produtoService.buscar(idSchema.parse(req.params.id)));
};
export const criar: RequestHandler = async (req, res) => {
  res.status(201).json(await produtoService.criar(produtoSchema.parse(req.body), req.usuario!.id));
};
export const atualizar: RequestHandler = async (req, res) => {
  res.json(await produtoService.atualizar(idSchema.parse(req.params.id), produtoSchema.parse(req.body), req.usuario!.id));
};
export const excluir: RequestHandler = async (req, res) => {
  await produtoService.excluir(idSchema.parse(req.params.id), req.usuario!.id);
  res.sendStatus(204);
};
export const categorias: RequestHandler = async (_req, res) => {
  res.json(await produtoService.listarCategorias());
};
