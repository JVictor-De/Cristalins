# Estudo — Assinatura Cristalins

O sistema é um app Android em Flutter e uma API NestJS que vendem assinatura recorrente de Water Protein e complementos Cristalins só no Rio de Janeiro: o cliente faz um quiz, monta a cesta, valida o CEP/bairro, escolhe plano e paga o ciclo (Pix na AP2) via Asaas; a API concentra preço dinâmico, ciclos, jobs e webhooks, e o app só coleta dados e exibe o resultado.

## Usuários do seed (só desenvolvimento)

Senha de todos: `cristalins-dev-123` (bcrypt no banco). Nunca usar fora do ambiente local.

| E-mail | Papel |
| --- | --- |
| `admin@cristalins.local` | ADMIN |
| `ana.teste@cristalins.local` | CLIENTE (endereço em Copacabana, Zona Sul) |
| `bruno.teste@cristalins.local` | CLIENTE (endereço na Tijuca, Zona Norte) |

Cupom de exemplo: `BEMVINDO10` (10%, validade 31/12/2027, 100 usos).
