# Plano — Fase 1 (API núcleo / AP2)

Contrato da API antes de implementar `cr-1-auth`, `cr-1-preco`, `cr-1-ciclo` e `cr-3-gateway`.  
Fonte: `CONTEXTO.md`, `INVENTARIO.md`, `api/prisma/schema.prisma`. Prefixo **`/api/v1`**. Erro: `{ "codigo", "mensagem", "campo?" }` via `RegraNegocioException`. Dinheiro JSON: número com 2 casas. Sem alterar `api/src` neste documento.

## Escopo por fase dona

| Fase | Implementa | Não implementa aqui |
| --- | --- | --- |
| `cr-1-auth` | clientes + login/refresh + me | `DELETE /clientes/me` (`cr-7-qualidade`) |
| `cr-1-preco` | produtos, kits, recomendações, simular | — |
| `cr-1-ciclo` | cep, lista-espera, endereços, assinaturas **sem Pix**, pausar/retomar/pular, ciclos, admin produto/fator/zona | cobrança Asaas |
| `cr-3-gateway` | Pix na criação, webhook, jobs, `POST /admin/jobs/gerar-cobrancas`, régua mínima | cartão/boleto (`cr-5`) |

Já na fundação: `GET /health` (`cr-0-api`).

---

## Códigos de erro exigidos nesta fase

| Código | HTTP | Onde |
| --- | --- | --- |
| `CPF_INVALIDO` | 400/422 | `cr-1-auth` cadastro |
| `MENOR_DE_IDADE` | 422 | `cr-1-auth` (CT24) |
| `MUITAS_TENTATIVAS` | 429 | `cr-1-auth` login 6ª/min (CT19, SEG06) |
| `CESTA_ABAIXO_MINIMO` | 422 | `cr-1-preco` (CT06) |
| `CESTA_ACIMA_MAXIMO` | 422 | `cr-1-preco` (CT07) |
| `EMBALAGEM_INVALIDA` | 422 | `cr-1-preco` (CT25) |
| `CEP_FORA_AREA` | 422 | `cr-1-ciclo` (CT08) |
| `BAIRRO_NAO_ATENDIDO` | 422 | `cr-1-ciclo` (CT23) |
| `APOS_CORTE` | 409 | `cr-1-ciclo` (CT09) |
| `SEM_PERMISSAO` | 403 | `cr-1-ciclo` / auth (CT16) |
| `LIMITE_PAUSAS` | 422 | `cr-1-ciclo` (CT20) |
| `TRANSICAO_INVALIDA` | 409 | máquinas de estado assinatura/ciclo |

Outros úteis (schema/contexto): `CPF_JA_CADASTRADO` 409, `CREDENCIAIS_INVALIDAS` 401, `NAO_AUTENTICADO` 401, `NAO_ENCONTRADO` 404, `LIMITE_PULOS` 422, `CUPOM_INVALIDO` 422, `COBRANCA_VENCIDA` 422 (RN26).

---

## Endpoints

### Fundação (já existe)

| Método | Rota | Acesso | Fase | DTO (resumo) | Erros |
| --- | --- | --- | --- | --- | --- |
| GET | `/health` | público | `cr-0-api` | resp. `{ status, banco, horario }` | 503 `SERVICO_INDISPONIVEL` |

### `cr-1-auth`

| Método | Rota | Acesso | DTO entrada | DTO saída | Erros-chave | CT |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/clientes` | público | `CriarClienteDto`: `nome`, `cpfCnpj`, `email`, `celular?`, `dataNascimento`, `senha`, `aceiteTermos` (bool), `marketingOk?` | 201 cliente sem `senhaHash` + tokens opcionais ou só cliente | `CPF_INVALIDO`, `MENOR_DE_IDADE`, `CPF_JA_CADASTRADO` | CT24 |
| POST | `/auth/login` | público | `LoginDto`: `email`, `senha` | 200 `{ accessToken, refreshToken, expiresIn }` | `CREDENCIAIS_INVALIDAS`, `MUITAS_TENTATIVAS` | CT19 |
| POST | `/auth/refresh` | público | `RefreshDto`: `refreshToken` | 200 novos tokens | `NAO_AUTENTICADO` | — |
| GET | `/clientes/me` | cliente | — | 200 perfil camelCase (schema `Cliente` sem hash) | `NAO_AUTENTICADO` | — |
| PUT | `/clientes/me` | cliente | `AtualizarClienteDto`: `nome?`, `celular?`, `marketingOk?` (sem CPF) | 200 perfil | `NAO_AUTENTICADO` | — |

**Fora:** `DELETE /clientes/me` → `cr-7-qualidade`.

SEG01–SEG06: JWT acesso 15 min / refresh 30 dias; bcrypt; papéis; throttling 5/min/IP no login.

### `cr-1-preco`

| Método | Rota | Acesso | DTO entrada | DTO saída | Erros-chave | CT |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/produtos` | público | query `tipo?` | 200 lista (`codigo`, `nome`, `tipo`, `volumeMl`, `ue`, `embalagemQtd`, `precoBase`, `precoPiso`, …) | — | — |
| GET | `/kits` | público | — | 200 kits + itens (`codigo` produto, `quantidade`) | — | — |
| POST | `/recomendacoes` | cliente | `CriarRecomendacaoDto`: `objetivo` (`TREINO`\|`EQUILIBRIO`\|`CASA`\|`ESCRITORIO`), `diasSemana` (faixa → d=2\|4\|6), `pessoas` (→ p), `flowFiber` bool, `comGas` bool | 201 ver exemplo abaixo | limites → perfil Empresa | CT03–05 |
| GET | `/recomendacoes` | cliente | — | 200 lista do cliente | `NAO_AUTENTICADO` | — |
| GET | `/recomendacoes/{id}` | cliente | — | 200 uma recomendação | `NAO_ENCONTRADO`, `SEM_PERMISSAO` | — |
| POST | `/precos/simular` | cliente | `SimularPrecoDto`: `itens[]` `{ produto, quantidade }`, `frequencia`, `plano`, `zonaId?` / `enderecoId?`, `cupom?`, `dataEntrega?`, `cicloAnteriorId?` | 200 `{ subtotal, frete, creditos, total, fatores, itens[] }` números 2 casas | `CESTA_ABAIXO_MINIMO`, `CESTA_ACIMA_MAXIMO`, `EMBALAGEM_INVALIDA`, `CUPOM_INVALIDO` | CT01–02, 06–07, 11–13, 25 |

Ordem de cálculo: exatamente a do `CONTEXTO` (`PrecoService`). Cobertura ≥ 80% em `PrecoService` e `RecomendacaoService`.

#### Exemplo — `POST /recomendacoes` 201 (caso A, CONTEXTO)

```json
{
  "id": "rec_8f2c",
  "kit": "KIT-TREINO",
  "multiplicador": 1,
  "frequencia": "QUINZENAL",
  "itens": [{ "produto": "WP500", "quantidade": 12 }],
  "ue": 12,
  "valorEstimado": 118.80,
  "perfilEmpresa": false
}
```

### `cr-1-ciclo`

| Método | Rota | Acesso | DTO entrada | DTO saída | Erros-chave | CT |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/cep/{cep}` | público | path CEP | 200 `{ cep, logradouro, bairro, localidade, uf, zona?, taxaEntrega?, diasEntrega? }` | `CEP_FORA_AREA`, `BAIRRO_NAO_ATENDIDO` | CT08, CT23 |
| POST | `/lista-espera` | público | `ListaEsperaDto`: `email`, `cep?`, `bairro?` | 201 registro | validação | CT23 |
| POST | `/enderecos` | cliente | `CriarEnderecoDto`: `apelido?`, `cep`, `numero`, `complemento?`, `referencia?`, `instrucoes?`, `principal?` (logradouro/bairro/zona via ViaCEP+seed; `lat`/`lng` nulos) | 201 endereço | `CEP_FORA_AREA`, `BAIRRO_NAO_ATENDIDO` | — |
| GET | `/enderecos` | cliente | — | 200 lista | — | — |
| PUT | `/enderecos/{id}` | cliente | parcial | 200 | `SEM_PERMISSAO`, `APOS_CORTE` se amarrado a ciclo | CT10 |
| DELETE | `/enderecos/{id}` | cliente | — | 204 | não remover principal; `SEM_PERMISSAO` | — |
| POST | `/assinaturas` | cliente | `CriarAssinaturaDto`: `recomendacaoId?`, `itens[]`, `frequencia`, `plano` (`FLEX`\|`TRIMESTRAL`; `EMPRESA` fora do app), `enderecoId`, `janela`, `formaPagamento` (`PIX` na AP2), `cupom?` | 201 assinatura `AGUARDANDO_PAGAMENTO` + ciclo + `detalhePreco` **sem** QR Pix nesta fase | erros de cesta/endereço; `COBRANCA_VENCIDA` (RN26) | CT02 (valor) |
| GET | `/assinaturas` | cliente | — | 200 | — | — |
| GET | `/assinaturas/{id}` | cliente | — | 200 | `SEM_PERMISSAO`, `NAO_ENCONTRADO` | CT16 |
| PUT | `/assinaturas/{id}` | cliente | alterar cesta/endereço/frequência/plano/cupom (respeita corte RN09) | 200 | `APOS_CORTE`, `CESTA_*`, `EMBALAGEM_INVALIDA`, `TRANSICAO_INVALIDA` | CT09–10, CT17 |
| DELETE | `/assinaturas/{id}` | cliente | cancelar (RN12/RN13) | 200/204 | `TRANSICAO_INVALIDA` | CT17 |
| POST | `/assinaturas/{id}/pausar` | cliente | `{ ciclos: 1\|2 }` | 200 | `LIMITE_PAUSAS`, `TRANSICAO_INVALIDA` | CT20 |
| POST | `/assinaturas/{id}/retomar` | cliente | — | 200 | `TRANSICAO_INVALIDA` | — |
| POST | `/assinaturas/{id}/pular-entrega` | cliente | — | 200 | `APOS_CORTE`, `LIMITE_PULOS` | CT09 |
| GET | `/assinaturas/{id}/ciclos` | cliente | — | 200 lista ciclos | `SEM_PERMISSAO` | — |
| PUT | `/admin/produtos/{id}` | admin | preço base/piso, estoque, ativo | 200 | `SEM_PERMISSAO` | — |
| PUT | `/admin/fatores-preco` | admin | chave, valor, vigência | 200 | `SEM_PERMISSAO` | — |
| PUT | `/admin/zonas/{id}` | admin | taxa, dias, bairros, ativa | 200 | `SEM_PERMISSAO` | — |

#### Exemplo — `POST /assinaturas` 201 (CT02, CONTEXTO; Pix QR só em `cr-3-gateway`)

```json
{
  "id": "ass_77d1",
  "status": "AGUARDANDO_PAGAMENTO",
  "proximaEntrega": "2026-11-16",
  "ciclo": {
    "id": "cic_001",
    "valor": 213.19,
    "vencimento": "2026-11-14"
  },
  "detalhePreco": [
    { "fator": "VOLUME", "percentual": -8 },
    { "fator": "COMPROMISSO", "percentual": -7 },
    { "fator": "FRETE", "valor": 9.90 }
  ]
}
```

Em `cr-1-ciclo`, **não** incluir `ciclo.pix`. Em `cr-3-gateway`, o mesmo 201 passa a trazer `pix.copiaECola` e `pix.qrCodeBase64`.

### `cr-3-gateway` (contrato fechado aqui; implementação depois)

| Método | Rota | Acesso | DTO / notas | Erros-chave | CT |
| --- | --- | --- | --- | --- | --- |
| (efeito) | `POST /assinaturas` | cliente | gera cobrança Pix; preenche `ciclo.pix` | gateway | — |
| POST | `/webhooks/asaas` | Asaas | header `asaas-access-token`; body evento; `@ApiExcludeEndpoint`; grava `id_evento` e 200; processa depois | 401 token inválido | CT14, CT15 |
| POST | `/admin/jobs/gerar-cobrancas` | admin | dispara job 06:00 (D+5) | `SEM_PERMISSAO` | — |
| jobs | schedule | sistema | 06:00 cobranças; 00:05 corte + AGUARDANDO+3; a cada min `EventoWebhook` | — | CT22 |

---

## Fora deste plano (pós-AP2 / outras fases)

- `DELETE /clientes/me` → `cr-7-qualidade`
- `POST /cartoes`, boleto, faturas, cupom admin, indicação, arrependimento → `cr-5-cobranca`
- ocorrências, separação, senha, push → `cr-6-operacao`
- App: telas 2–8 / aguardando → `cr-2-telas` / `cr-3-tela` (consomem este contrato)

---

## Ordem de implementação sugerida

1. `cr-1-auth` (CT19, CT24)  
2. `cr-1-preco` (CT01–07, 11–13, 25 + A–C)  
3. `cr-1-ciclo` (CT08–10, 16–17, 20, 23)  
4. `cr-3-gateway` (CT14, 15, 22 + Pix no `POST /assinaturas`)
