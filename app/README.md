# cristalins_assinatura

App Flutter da assinatura Cristalins (Android + **Web** para demo/hml).

## Entradas

| Ambiente | Comando |
| --- | --- |
| Dev Android | `flutter run --flavor dev -t lib/main_dev.dart` |
| Hml Android | `flutter run --flavor hml -t lib/main_hml.dart --dart-define=API_URL=https://apicristalins.peladeiro.cloud` |
| Dev Web | `flutter run -d chrome -t lib/main_dev.dart` |
| Build Web hml | `flutter build web -t lib/main_hml.dart --release --base-href=/ --dart-define=API_URL=https://apicristalins.peladeiro.cloud` |

Deploy Coolify / DNS / CORS: ver [`docs/DEPLOY.md`](../docs/DEPLOY.md).

Dockerfile web: [`Dockerfile`](Dockerfile) (Nginx, porta 80).

## Termos e privacidade

HTML estático em `web/termos.html` e `web/privacidade.html` (copiados no `flutter build web`).

URLs default (override com `--dart-define=URL_TERMOS=` / `URL_PRIVACIDADE=`):

- https://cristalins.peladeiro.cloud/termos.html
- https://cristalins.peladeiro.cloud/privacidade.html

## WhatsApp de suporte

Default fictício `5521999999999` (`AppConfig.suporteWhatsappPadrao`). Override:
`--dart-define=SUPORTE_WHATSAPP=55…` (aceita formatação; o app sanitiza dígitos).
