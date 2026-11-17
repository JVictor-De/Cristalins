-- Gates demo AP2 — estoque dos produtos (mesmos valores de api/prisma/seed.ts).
-- Idempotente: só UPDATE por código; não cria nem apaga linhas.
-- precoAvulso, claims e tabelaNutricional NÃO estão no banco: vêm de
-- api/src/produtos/produto-descricoes.ts (mapas demo) após deploy do código da API.
--
-- Rodar no PostgreSQL da API (psql / terminal do Coolify), dentro de uma transação:
--   psql "$DATABASE_URL" -f scripts/sql/seed_gates_demo_produtos.sql

BEGIN;

UPDATE produtos SET estoque = 1200 WHERE codigo = 'WP500';
UPDATE produtos SET estoque = 900  WHERE codigo = 'FF500';
UPDATE produtos SET estoque = 2400 WHERE codigo = 'AMS500';
UPDATE produtos SET estoque = 1800 WHERE codigo = 'AMC510';
UPDATE produtos SET estoque = 1200 WHERE codigo = 'AMN1500';
UPDATE produtos SET estoque = 400  WHERE codigo = 'AMN5000';
UPDATE produtos SET estoque = 4800 WHERE codigo = 'AMC200';
-- Esgotado de propósito: card mostra "Esgotado" + "Avise-me" (POST /lista-espera).
UPDATE produtos SET estoque = 0    WHERE codigo = 'GUA2000';

SELECT codigo, estoque FROM produtos ORDER BY codigo;

COMMIT;
