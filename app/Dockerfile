# Flutter Web (homologação/demo) — multi-stage.
# Coolify: contexto `app/`, Dockerfile `app/Dockerfile`, porta 80.
# Domínio sugerido: https://cristalins.peladeiro.cloud
# API: build-arg API_URL=https://apicristalins.peladeiro.cloud

# ---------- build ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

ARG API_URL=https://apicristalins.peladeiro.cloud
ARG SUPORTE_WHATSAPP=5521999999999
ARG URL_TERMOS=https://cristalins.peladeiro.cloud/termos.html
ARG URL_PRIVACIDADE=https://cristalins.peladeiro.cloud/privacidade.html

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web \
    -t lib/main_hml.dart \
    --release \
    --base-href=/ \
    --no-wasm-dry-run \
    --dart-define=API_URL=${API_URL} \
    --dart-define=SUPORTE_WHATSAPP=${SUPORTE_WHATSAPP} \
    --dart-define=URL_TERMOS=${URL_TERMOS} \
    --dart-define=URL_PRIVACIDADE=${URL_PRIVACIDADE}

# ---------- runtime ----------
FROM nginx:1.27-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
