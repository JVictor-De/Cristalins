-- cr-6-operacao: item da ocorrência (RN15)
ALTER TABLE "ocorrencias" ADD COLUMN "produto_id" UUID;
ALTER TABLE "ocorrencias" ADD COLUMN "quantidade" INTEGER;
