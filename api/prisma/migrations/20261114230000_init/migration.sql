-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "papel" AS ENUM ('CLIENTE', 'ADMIN');

-- CreateEnum
CREATE TYPE "tipo_produto" AS ENUM ('PRINCIPAL', 'COMPLEMENTO', 'B2B', 'ADDON');

-- CreateEnum
CREATE TYPE "objetivo_kit" AS ENUM ('TREINO', 'EQUILIBRIO', 'CASA', 'ESCRITORIO');

-- CreateEnum
CREATE TYPE "dia_semana" AS ENUM ('DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB');

-- CreateEnum
CREATE TYPE "plano" AS ENUM ('FLEX', 'TRIMESTRAL', 'EMPRESA');

-- CreateEnum
CREATE TYPE "frequencia" AS ENUM ('SEMANAL', 'QUINZENAL', 'MENSAL');

-- CreateEnum
CREATE TYPE "janela" AS ENUM ('MANHA', 'TARDE');

-- CreateEnum
CREATE TYPE "forma_pagamento" AS ENUM ('PIX', 'CARTAO', 'BOLETO');

-- CreateEnum
CREATE TYPE "status_assinatura" AS ENUM ('AGUARDANDO_PAGAMENTO', 'ATIVA', 'PAUSADA', 'SUSPENSA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "status_ciclo" AS ENUM ('AGENDADO', 'COBRADO', 'PAGO', 'SEPARADO', 'EM_ROTA', 'ENTREGUE', 'PULADO', 'CANCELADO', 'FALHOU');

-- CreateEnum
CREATE TYPE "status_pagamento" AS ENUM ('PENDENTE', 'PAGO', 'VENCIDO', 'CANCELADO', 'ESTORNADO');

-- CreateEnum
CREATE TYPE "tipo_ocorrencia" AS ENUM ('AVARIA', 'FALTA');

-- CreateEnum
CREATE TYPE "solucao_ocorrencia" AS ENUM ('REPOSICAO', 'CREDITO');

-- CreateEnum
CREATE TYPE "status_ocorrencia" AS ENUM ('ABERTA', 'RESOLVIDA');

-- CreateTable
CREATE TABLE "clientes" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "cpf_cnpj" VARCHAR(14) NOT NULL,
    "email" TEXT NOT NULL,
    "celular" VARCHAR(20),
    "data_nascimento" DATE,
    "senha_hash" TEXT NOT NULL,
    "papel" "papel" NOT NULL DEFAULT 'CLIENTE',
    "asaas_customer_id" TEXT,
    "aceite_termos_em" TIMESTAMPTZ(3),
    "marketing_ok" BOOLEAN NOT NULL DEFAULT false,
    "codigo_indicacao" TEXT,
    "indicado_por_id" UUID,
    "push_token" TEXT,
    "excluido_em" TIMESTAMPTZ(3),
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "clientes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "enderecos" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "apelido" TEXT,
    "cep" CHAR(8) NOT NULL,
    "logradouro" TEXT NOT NULL,
    "numero" TEXT NOT NULL,
    "complemento" TEXT,
    "bairro" TEXT NOT NULL,
    "zona_id" UUID NOT NULL,
    "referencia" TEXT,
    "instrucoes" TEXT,
    "lat" DECIMAL(9,6),
    "lng" DECIMAL(9,6),
    "principal" BOOLEAN NOT NULL DEFAULT false,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "enderecos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "zonas" (
    "id" UUID NOT NULL,
    "nome" TEXT NOT NULL,
    "bairros" TEXT[],
    "taxa_entrega" DECIMAL(10,2) NOT NULL,
    "dias_entrega" "dia_semana"[],
    "ativa" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "zonas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "produtos" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "tipo" "tipo_produto" NOT NULL,
    "volume_ml" INTEGER NOT NULL,
    "ue" DECIMAL(6,2) NOT NULL,
    "embalagem_qtd" INTEGER NOT NULL,
    "preco_base" DECIMAL(10,2) NOT NULL,
    "preco_piso" DECIMAL(10,2) NOT NULL,
    "peso_kg" DECIMAL(6,2) NOT NULL,
    "estoque" INTEGER,
    "validade_dias" INTEGER,
    "ativo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "produtos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kits" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "objetivo" "objetivo_kit" NOT NULL,

    CONSTRAINT "kits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kit_itens" (
    "kit_id" UUID NOT NULL,
    "produto_id" UUID NOT NULL,
    "quantidade" INTEGER NOT NULL,

    CONSTRAINT "kit_itens_pkey" PRIMARY KEY ("kit_id","produto_id")
);

-- CreateTable
CREATE TABLE "recomendacoes" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "respostas" JSONB NOT NULL,
    "kit_id" UUID,
    "multiplicador" INTEGER,
    "frequencia" "frequencia",
    "itens" JSONB NOT NULL,
    "ue" DECIMAL(8,2) NOT NULL,
    "valor_estimado" DECIMAL(10,2),
    "perfil_empresa" BOOLEAN NOT NULL DEFAULT false,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recomendacoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assinaturas" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "endereco_id" UUID NOT NULL,
    "plano" "plano" NOT NULL,
    "frequencia" "frequencia" NOT NULL,
    "janela" "janela" NOT NULL,
    "forma_pagamento" "forma_pagamento" NOT NULL DEFAULT 'PIX',
    "cartao_id" UUID,
    "cupom_id" UUID,
    "status" "status_assinatura" NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
    "inicio" DATE,
    "fim_compromisso" DATE,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "assinaturas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "itens_assinatura" (
    "assinatura_id" UUID NOT NULL,
    "produto_id" UUID NOT NULL,
    "quantidade" INTEGER NOT NULL,

    CONSTRAINT "itens_assinatura_pkey" PRIMARY KEY ("assinatura_id","produto_id")
);

-- CreateTable
CREATE TABLE "ciclos" (
    "id" UUID NOT NULL,
    "assinatura_id" UUID NOT NULL,
    "numero" INTEGER NOT NULL,
    "endereco_id" UUID NOT NULL,
    "janela" "janela" NOT NULL,
    "data_entrega" DATE NOT NULL,
    "data_corte" TIMESTAMPTZ(3) NOT NULL,
    "tentativas_entrega" INTEGER NOT NULL DEFAULT 0,
    "status" "status_ciclo" NOT NULL DEFAULT 'AGENDADO',
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "ciclos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "itens_ciclo" (
    "ciclo_id" UUID NOT NULL,
    "produto_id" UUID NOT NULL,
    "quantidade" INTEGER NOT NULL,
    "preco_unitario" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "itens_ciclo_pkey" PRIMARY KEY ("ciclo_id","produto_id")
);

-- CreateTable
CREATE TABLE "calculos_preco" (
    "id" UUID NOT NULL,
    "ciclo_id" UUID NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,
    "fatores" JSONB NOT NULL,
    "frete" DECIMAL(10,2) NOT NULL,
    "creditos" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "valor_final" DECIMAL(10,2) NOT NULL,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "calculos_preco_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pagamentos" (
    "id" UUID NOT NULL,
    "ciclo_id" UUID NOT NULL,
    "asaas_payment_id" TEXT,
    "forma" "forma_pagamento" NOT NULL,
    "valor" DECIMAL(10,2) NOT NULL,
    "vencimento" DATE NOT NULL,
    "link_pagamento" TEXT,
    "status" "status_pagamento" NOT NULL DEFAULT 'PENDENTE',
    "pago_em" TIMESTAMPTZ(3),
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "pagamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cartoes" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "asaas_token" TEXT NOT NULL,
    "bandeira" TEXT NOT NULL,
    "final" CHAR(4) NOT NULL,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cartoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "creditos" (
    "id" UUID NOT NULL,
    "cliente_id" UUID NOT NULL,
    "valor" DECIMAL(10,2) NOT NULL,
    "motivo" TEXT NOT NULL,
    "expira_em" TIMESTAMPTZ(3),
    "usado_em" TIMESTAMPTZ(3),
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "creditos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cupons" (
    "id" UUID NOT NULL,
    "codigo" TEXT NOT NULL,
    "percentual" DECIMAL(5,2) NOT NULL,
    "validade" DATE,
    "usos_max" INTEGER,
    "usos" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "cupons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ocorrencias" (
    "id" UUID NOT NULL,
    "ciclo_id" UUID NOT NULL,
    "tipo" "tipo_ocorrencia" NOT NULL,
    "foto_url" TEXT,
    "solucao" "solucao_ocorrencia",
    "status" "status_ocorrencia" NOT NULL DEFAULT 'ABERTA',
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ocorrencias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fatores_preco" (
    "id" UUID NOT NULL,
    "chave" TEXT NOT NULL,
    "valor" DECIMAL(6,4) NOT NULL,
    "ativo_de" DATE NOT NULL,
    "ativo_ate" DATE,

    CONSTRAINT "fatores_preco_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "eventos_webhook" (
    "id" UUID NOT NULL,
    "id_evento" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "recebido_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processado_em" TIMESTAMPTZ(3),
    "erro" TEXT,

    CONSTRAINT "eventos_webhook_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lista_espera" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "cep" CHAR(8) NOT NULL,
    "bairro" TEXT,
    "criado_em" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lista_espera_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "clientes_cpf_cnpj_key" ON "clientes"("cpf_cnpj");

-- CreateIndex
CREATE UNIQUE INDEX "clientes_email_key" ON "clientes"("email");

-- CreateIndex
CREATE UNIQUE INDEX "clientes_asaas_customer_id_key" ON "clientes"("asaas_customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "clientes_codigo_indicacao_key" ON "clientes"("codigo_indicacao");

-- CreateIndex
CREATE INDEX "enderecos_cliente_id_idx" ON "enderecos"("cliente_id");

-- CreateIndex
CREATE INDEX "enderecos_zona_id_idx" ON "enderecos"("zona_id");

-- CreateIndex
CREATE UNIQUE INDEX "zonas_nome_key" ON "zonas"("nome");

-- CreateIndex
CREATE UNIQUE INDEX "produtos_codigo_key" ON "produtos"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "kits_codigo_key" ON "kits"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "kits_objetivo_key" ON "kits"("objetivo");

-- CreateIndex
CREATE INDEX "recomendacoes_cliente_id_idx" ON "recomendacoes"("cliente_id");

-- CreateIndex
CREATE INDEX "assinaturas_cliente_id_idx" ON "assinaturas"("cliente_id");

-- CreateIndex
CREATE INDEX "assinaturas_status_idx" ON "assinaturas"("status");

-- CreateIndex
CREATE INDEX "ciclos_status_data_entrega_idx" ON "ciclos"("status", "data_entrega");

-- CreateIndex
CREATE UNIQUE INDEX "ciclos_assinatura_id_numero_key" ON "ciclos"("assinatura_id", "numero");

-- CreateIndex
CREATE UNIQUE INDEX "calculos_preco_ciclo_id_key" ON "calculos_preco"("ciclo_id");

-- CreateIndex
CREATE UNIQUE INDEX "pagamentos_asaas_payment_id_key" ON "pagamentos"("asaas_payment_id");

-- CreateIndex
CREATE INDEX "pagamentos_ciclo_id_idx" ON "pagamentos"("ciclo_id");

-- CreateIndex
CREATE INDEX "cartoes_cliente_id_idx" ON "cartoes"("cliente_id");

-- CreateIndex
CREATE INDEX "creditos_cliente_id_idx" ON "creditos"("cliente_id");

-- CreateIndex
CREATE UNIQUE INDEX "cupons_codigo_key" ON "cupons"("codigo");

-- CreateIndex
CREATE INDEX "ocorrencias_ciclo_id_idx" ON "ocorrencias"("ciclo_id");

-- CreateIndex
CREATE UNIQUE INDEX "fatores_preco_chave_ativo_de_key" ON "fatores_preco"("chave", "ativo_de");

-- CreateIndex
CREATE UNIQUE INDEX "eventos_webhook_id_evento_key" ON "eventos_webhook"("id_evento");

-- CreateIndex
CREATE INDEX "eventos_webhook_processado_em_idx" ON "eventos_webhook"("processado_em");

-- AddForeignKey
ALTER TABLE "clientes" ADD CONSTRAINT "clientes_indicado_por_id_fkey" FOREIGN KEY ("indicado_por_id") REFERENCES "clientes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "enderecos" ADD CONSTRAINT "enderecos_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "enderecos" ADD CONSTRAINT "enderecos_zona_id_fkey" FOREIGN KEY ("zona_id") REFERENCES "zonas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kit_itens" ADD CONSTRAINT "kit_itens_kit_id_fkey" FOREIGN KEY ("kit_id") REFERENCES "kits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kit_itens" ADD CONSTRAINT "kit_itens_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "produtos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recomendacoes" ADD CONSTRAINT "recomendacoes_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recomendacoes" ADD CONSTRAINT "recomendacoes_kit_id_fkey" FOREIGN KEY ("kit_id") REFERENCES "kits"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assinaturas" ADD CONSTRAINT "assinaturas_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assinaturas" ADD CONSTRAINT "assinaturas_endereco_id_fkey" FOREIGN KEY ("endereco_id") REFERENCES "enderecos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assinaturas" ADD CONSTRAINT "assinaturas_cartao_id_fkey" FOREIGN KEY ("cartao_id") REFERENCES "cartoes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assinaturas" ADD CONSTRAINT "assinaturas_cupom_id_fkey" FOREIGN KEY ("cupom_id") REFERENCES "cupons"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_assinatura" ADD CONSTRAINT "itens_assinatura_assinatura_id_fkey" FOREIGN KEY ("assinatura_id") REFERENCES "assinaturas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_assinatura" ADD CONSTRAINT "itens_assinatura_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "produtos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ciclos" ADD CONSTRAINT "ciclos_assinatura_id_fkey" FOREIGN KEY ("assinatura_id") REFERENCES "assinaturas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ciclos" ADD CONSTRAINT "ciclos_endereco_id_fkey" FOREIGN KEY ("endereco_id") REFERENCES "enderecos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_ciclo" ADD CONSTRAINT "itens_ciclo_ciclo_id_fkey" FOREIGN KEY ("ciclo_id") REFERENCES "ciclos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_ciclo" ADD CONSTRAINT "itens_ciclo_produto_id_fkey" FOREIGN KEY ("produto_id") REFERENCES "produtos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calculos_preco" ADD CONSTRAINT "calculos_preco_ciclo_id_fkey" FOREIGN KEY ("ciclo_id") REFERENCES "ciclos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pagamentos" ADD CONSTRAINT "pagamentos_ciclo_id_fkey" FOREIGN KEY ("ciclo_id") REFERENCES "ciclos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cartoes" ADD CONSTRAINT "cartoes_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creditos" ADD CONSTRAINT "creditos_cliente_id_fkey" FOREIGN KEY ("cliente_id") REFERENCES "clientes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ocorrencias" ADD CONSTRAINT "ocorrencias_ciclo_id_fkey" FOREIGN KEY ("ciclo_id") REFERENCES "ciclos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
