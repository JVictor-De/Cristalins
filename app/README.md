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
