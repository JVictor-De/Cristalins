/**
 * Seed da AP2 — idempotente (upsert por chave natural). Rode com `npx prisma db seed` na pasta api.
 * Valores de preço, peso e taxas são de EXEMPLO (Anexo); os reais vêm da Cristalins.
 * Senha dos usuários de teste é só de desenvolvimento (ver docs/ESTUDO.md). Nunca use em produção.
 * Bairros oficiais: `prisma/data/bairros-rj.json` (cr-8-bairros); taxas/dias das zonas continuam do Anexo.
 */
import { PrismaPg } from '@prisma/adapter-pg';
import * as bcrypt from 'bcrypt';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  DiaSemana,
  ObjetivoKit,
  Papel,
  PrismaClient,
  TipoProduto,
} from './generated/prisma/client';

const SENHA_DEV = 'cristalins-dev-123';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL não definida (copie .env.example para .env).');
}

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

// estoque: demo AP2 (gates). GUA2000 = 0 mostra “Esgotado” + Avise-me; os demais têm folga
// para a separação (RN06) não pular itens na apresentação. Igual a scripts/sql/seed_gates_demo_produtos.sql.
const produtos = [
  { codigo: 'WP500', nome: 'Water Protein (água com colágeno)', tipo: TipoProduto.PRINCIPAL, volumeMl: 500, ue: '1', embalagemQtd: 6, precoBase: '9.90', precoPiso: '7.50', pesoKg: '0.53', estoque: 1200 },
  { codigo: 'FF500', nome: 'Flow Fiber', tipo: TipoProduto.PRINCIPAL, volumeMl: 500, ue: '1', embalagemQtd: 6, precoBase: '8.90', precoPiso: '6.70', pesoKg: '0.53', estoque: 900 },
  { codigo: 'AMS500', nome: 'Água mineral sem gás', tipo: TipoProduto.COMPLEMENTO, volumeMl: 500, ue: '1', embalagemQtd: 12, precoBase: '2.20', precoPiso: '1.50', pesoKg: '0.52', estoque: 2400 },
  { codigo: 'AMC510', nome: 'Água mineral com gás', tipo: TipoProduto.COMPLEMENTO, volumeMl: 510, ue: '1.02', embalagemQtd: 12, precoBase: '2.90', precoPiso: '2.00', pesoKg: '0.53', estoque: 1800 },
  { codigo: 'AMN1500', nome: 'Água mineral natural', tipo: TipoProduto.COMPLEMENTO, volumeMl: 1500, ue: '3', embalagemQtd: 6, precoBase: '3.90', precoPiso: '2.70', pesoKg: '1.55', estoque: 1200 },
  { codigo: 'AMN5000', nome: 'Água mineral natural (galão)', tipo: TipoProduto.COMPLEMENTO, volumeMl: 5000, ue: '10', embalagemQtd: 1, precoBase: '9.90', precoPiso: '7.00', pesoKg: '5.20', estoque: 400 },
  { codigo: 'AMC200', nome: 'Água mineral no copo', tipo: TipoProduto.B2B, volumeMl: 200, ue: '0.4', embalagemQtd: 48, precoBase: '0.90', precoPiso: '0.60', pesoKg: '0.21', estoque: 4800 },
  { codigo: 'GUA2000', nome: 'Guaraná Cristalins', tipo: TipoProduto.ADDON, volumeMl: 2000, ue: '4', embalagemQtd: 1, precoBase: '7.90', precoPiso: '5.50', pesoKg: '2.10', estoque: 0 },
];

const kits: { codigo: string; nome: string; objetivo: ObjetivoKit; itens: Record<string, number> }[] = [
  { codigo: 'KIT-TREINO', nome: 'Kit Treino', objetivo: ObjetivoKit.TREINO, itens: { WP500: 12 } },
  { codigo: 'KIT-EQUILIBRIO', nome: 'Kit Equilíbrio', objetivo: ObjetivoKit.EQUILIBRIO, itens: { WP500: 6, FF500: 6 } },
  { codigo: 'KIT-CASA', nome: 'Kit Casa', objetivo: ObjetivoKit.CASA, itens: { WP500: 6, AMN5000: 2 } },
  { codigo: 'KIT-ESCRITORIO', nome: 'Kit Escritório', objetivo: ObjetivoKit.ESCRITORIO, itens: { WP500: 12, AMC200: 48 } },
];

const { SEG, TER, QUA, QUI, SEX, SAB } = DiaSemana;

/** Metadados de frete do Anexo (não inventar taxa). Bairros vêm do JSON oficial. */
const zonasMeta: { nome: string; taxaEntrega: string; diasEntrega: DiaSemana[]; exemplosAp2: string[] }[] = [
  { nome: 'Centro', taxaEntrega: '9.90', diasEntrega: [SEG, QUA, SEX], exemplosAp2: ['Centro', 'Lapa', 'Santa Teresa'] },
  { nome: 'Zona Sul', taxaEntrega: '9.90', diasEntrega: [SEG, QUA, SEX], exemplosAp2: ['Copacabana', 'Ipanema', 'Leblon', 'Botafogo', 'Flamengo'] },
  { nome: 'Barra e Recreio', taxaEntrega: '12.90', diasEntrega: [TER, QUI, SAB], exemplosAp2: ['Barra da Tijuca', 'Recreio', 'Jacarepaguá'] },
  { nome: 'Zona Norte', taxaEntrega: '12.90', diasEntrega: [TER, QUI], exemplosAp2: ['Tijuca', 'Méier', 'Vila Isabel', 'Ilha do Governador'] },
  { nome: 'Zona Oeste', taxaEntrega: '19.90', diasEntrega: [SAB], exemplosAp2: ['Campo Grande', 'Bangu', 'Santa Cruz'] },
];

type BairrosRj = {
  fonte: { orgao: string; documento: string; url: string };
  bairros: { bairro: string; zona: string }[];
};

function carregarBairrosPorZona(): Record<string, string[]> {
  const caminho = join(process.cwd(), 'prisma', 'data', 'bairros-rj.json');
  const doc = JSON.parse(readFileSync(caminho, 'utf8')) as BairrosRj;
  if (!doc?.fonte?.orgao || !Array.isArray(doc.bairros) || doc.bairros.length === 0) {
    throw new Error(`bairros-rj.json inválido ou sem fonte: ${caminho}`);
  }
  const porZona: Record<string, string[]> = {};
  for (const item of doc.bairros) {
    if (!item.bairro || !item.zona) continue;
    (porZona[item.zona] ??= []).push(item.bairro);
  }
  return porZona;
}

function unirBairros(...listas: string[][]): string[] {
  const visto = new Set<string>();
  const saida: string[] = [];
  for (const lista of listas) {
    for (const b of lista) {
      const chave = b.normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim().toLowerCase();
      if (visto.has(chave)) continue;
      visto.add(chave);
      saida.push(b);
    }
  }
  return saida.sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

const bairrosPorZona = carregarBairrosPorZona();
const zonas = zonasMeta.map((z) => ({
  nome: z.nome,
  taxaEntrega: z.taxaEntrega,
  diasEntrega: z.diasEntrega,
  bairros: unirBairros(z.exemplosAp2, bairrosPorZona[z.nome] ?? []),
}));

// valor = fração. Vigência aberta (ativoAte nulo) salvo a demanda de verão.
const INICIO_VIGENCIA = '2026-01-01';
const fatores = [
  { chave: 'VOLUME_24_47', valor: '0.08', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'VOLUME_48_MAIS', valor: '0.12', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'COMPROMISSO_TRIMESTRAL', valor: '0.07', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'COMPROMISSO_EMPRESA', valor: '0.10', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'FIDELIDADE_POR_CICLO', valor: '0.01', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'FIDELIDADE_MAXIMO', valor: '0.05', ativoDe: INICIO_VIGENCIA, ativoAte: null },
  { chave: 'DEMANDA_VERAO', valor: '0.05', ativoDe: '2026-12-01', ativoAte: '2027-03-31' },
];

// CPFs com dígito verificador válido, só para desenvolvimento.
const usuarios = [
  { email: 'admin@cristalins.local', nome: 'Admin Cristalins', cpfCnpj: '00000000191', papel: Papel.ADMIN, dataNascimento: '1990-01-01' },
  { email: 'ana.teste@cristalins.local', nome: 'Ana Teste', cpfCnpj: '00000000272', papel: Papel.CLIENTE, dataNascimento: '1995-05-10' },
  { email: 'bruno.teste@cristalins.local', nome: 'Bruno Teste', cpfCnpj: '00000000353', papel: Papel.CLIENTE, dataNascimento: '1988-09-20' },
];

// Endereços de exemplo dos clientes de teste (ids fixos para o upsert ser idempotente). lat/lng nulos até cr-6.
const enderecos = [
  { id: '00000000-0000-4000-8000-000000000001', email: 'ana.teste@cristalins.local', zona: 'Zona Sul', apelido: 'Casa', cep: '22041001', logradouro: 'Rua de Teste', numero: '100', bairro: 'Copacabana' },
  { id: '00000000-0000-4000-8000-000000000002', email: 'bruno.teste@cristalins.local', zona: 'Zona Norte', apelido: 'Casa', cep: '20520050', logradouro: 'Rua de Teste', numero: '200', bairro: 'Tijuca' },
];

const cupom = { codigo: 'BEMVINDO10', percentual: '10.00', validade: '2027-12-31', usosMax: 100 };

const data = (iso: string) => new Date(`${iso}T00:00:00.000Z`);

async function main() {
  const produtoIds: Record<string, string> = {};
  for (const p of produtos) {
    const r = await prisma.produto.upsert({ where: { codigo: p.codigo }, update: p, create: p });
    produtoIds[p.codigo] = r.id;
  }

  for (const k of kits) {
    const { itens, ...dadosKit } = k;
    const kit = await prisma.kit.upsert({ where: { codigo: k.codigo }, update: dadosKit, create: dadosKit });
    await prisma.kitItem.deleteMany({ where: { kitId: kit.id, produtoId: { notIn: Object.keys(itens).map((c) => produtoIds[c]) } } });
    for (const [codigo, quantidade] of Object.entries(itens)) {
      const produtoId = produtoIds[codigo];
      await prisma.kitItem.upsert({
        where: { kitId_produtoId: { kitId: kit.id, produtoId } },
        update: { quantidade },
        create: { kitId: kit.id, produtoId, quantidade },
      });
    }
  }

  const zonaIds: Record<string, string> = {};
  for (const z of zonas) {
    const r = await prisma.zona.upsert({ where: { nome: z.nome }, update: z, create: z });
    zonaIds[z.nome] = r.id;
  }

  for (const f of fatores) {
    const valores = { valor: f.valor, ativoAte: f.ativoAte ? data(f.ativoAte) : null };
    await prisma.fatorPreco.upsert({
      where: { chave_ativoDe: { chave: f.chave, ativoDe: data(f.ativoDe) } },
      update: valores,
      create: { chave: f.chave, ativoDe: data(f.ativoDe), ...valores },
    });
  }

  const senhaHash = await bcrypt.hash(SENHA_DEV, 10);
  const clienteIds: Record<string, string> = {};
  for (const u of usuarios) {
    const dados = { ...u, dataNascimento: data(u.dataNascimento), senhaHash, aceiteTermosEm: new Date() };
    const r = await prisma.cliente.upsert({
      where: { email: u.email },
      update: { nome: u.nome, papel: u.papel },
      create: dados,
    });
    clienteIds[u.email] = r.id;
  }

  for (const e of enderecos) {
    const { id, email, zona, ...resto } = e;
    const dados = { ...resto, clienteId: clienteIds[email], zonaId: zonaIds[zona], principal: true, lat: null, lng: null };
    await prisma.endereco.upsert({ where: { id }, update: dados, create: { id, ...dados } });
  }

  const dadosCupom = { percentual: cupom.percentual, validade: data(cupom.validade), usosMax: cupom.usosMax };
  await prisma.cupom.upsert({ where: { codigo: cupom.codigo }, update: dadosCupom, create: { codigo: cupom.codigo, ...dadosCupom } });

  const totalBairros = zonas.reduce((n, z) => n + z.bairros.length, 0);
  console.log(
    `Seed ok: ${produtos.length} produtos, ${kits.length} kits, ${zonas.length} zonas (${totalBairros} bairros), ${fatores.length} fatores, ` +
      `${usuarios.length} usuários (1 admin), ${enderecos.length} endereços, 1 cupom.`,
  );
}

main()
  .catch((erro) => {
    console.error(erro);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
