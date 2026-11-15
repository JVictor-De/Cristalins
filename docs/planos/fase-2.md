# Plano — Fase 2 (app completo, AP2)

## Esta etapa (`cr-2-telas`)

Telas 2 a 8 no visual da skill `apple-style-flutter`, ligadas à API local (`/api/v1`). O app só coleta, chama a API e exibe: preço, quiz, corte e ciclos vêm da API.

| Tela | Arquivo | API | Intent |
| --- | --- | --- | --- |
| 2 Cadastro e login | `features/auth/presentation/cadastro_login_screen.dart` | `POST /clientes`, `POST /auth/login`, `GET /assinaturas` (decide 3 ou 8) | — |
| 3 Quiz | `features/quiz/presentation/quiz_screen.dart` | `POST /recomendacoes` | — |
| 4 Resultado | `features/quiz/presentation/resultado_screen.dart` | `GET /recomendacoes/{id}` | Compartilhar (`share_plus`) |
| 5 Catálogo e cesta | `features/catalog/presentation/catalogo_screen.dart` | `GET /produtos`, `GET /kits`, `POST /precos/simular`, `PUT /assinaturas/{id}` (alterar cesta) | — |
| 6 Endereço | `features/address/presentation/endereco_screen.dart` | `GET /cep/{cep}`, `GET/POST /enderecos`, `POST /lista-espera` | Mapa (`geo:`) |
| 7 Plano e pagamento | `features/subscription/presentation/plano_pagamento_screen.dart` | `POST /precos/simular`, `POST /assinaturas` | — |
| 8 Minha assinatura | `features/subscription/presentation/minha_assinatura_screen.dart` | `GET /assinaturas`, `GET …/ciclos`, pausar, retomar, pular, `DELETE` | WhatsApp (`https://wa.me/`) |

### Como

- `core/network/api_client.dart`: dio com Bearer do `flutter_secure_storage`. Interceptor renova o token no 401 (`POST /auth/refresh`); se falhar, limpa a sessão e volta ao login
- Erro da API `{ codigo, mensagem, campo? }` → `ApiErro`; a tela mostra a `mensagem`
- Cada feature em `data` (repositório + mapeamento JSON), `domain` (entidades sem JSON) e `presentation` (tela + `ChangeNotifier`)
- Dinheiro no app: `Dinheiro` em centavos inteiros, só para exibir (nenhuma conta de preço no app)
- Passagem entre telas por rotas nomeadas com argumentos (`PedidoAssinatura`: cesta, frequência, endereço, janela)
- `core/widgets/`: tela com título grande, seção agrupada, rodapé de ação, estados (carregando, vazio, erro com "Tentar de novo"), seletor de quantidade, card de produto, selo de status, folha com picker, resumo de preço
- Testes desta etapa: só os de widget que sustentam o checklist (render a 100% e 130%, acessibilidade) e um teste de navegação 1→8 com repositórios falsos. O `integration_test` é da `cr-2-testes`

### Fora desta etapa

- QR Code Pix e tela "Aguardando pagamento" (`cr-3-tela`)
- `integration_test` contra a API local (`cr-2-testes`)
- Imagens reais dos produtos (não há arquivos da marca no repositório; os cards usam ícone)

Gate humano: ao terminar, o João revisa as telas antes dos testes.
