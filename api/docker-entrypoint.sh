#!/bin/sh
set -e
# Aplica migrações pendentes antes de subir a API (homologação / Coolify).
npx prisma migrate deploy
exec node dist/src/main
