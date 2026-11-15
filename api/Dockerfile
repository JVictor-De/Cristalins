# API Cristalins — multi-stage (Node 22 Alpine).
# Build: prisma generate + nest build
# Runtime: migrate deploy → node dist/src/main
# Health: GET /api/v1/health · TZ=America/Sao_Paulo

# ---------- build ----------
FROM node:22-alpine AS build
WORKDIR /app

RUN apk add --no-cache openssl libc6-compat

COPY package.json package-lock.json ./
COPY prisma ./prisma
COPY prisma.config.ts ./
RUN npm ci

COPY . .
RUN npx prisma generate && npm run build

# Mantém prisma CLI no runtime para `migrate deploy` (está em devDependencies).
RUN npm prune --omit=dev \
  && npm install prisma@7.10.1 --no-save --omit=dev

# ---------- runtime ----------
FROM node:22-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV TZ=America/Sao_Paulo
ENV PORT=3000

RUN apk add --no-cache openssl libc6-compat \
  && addgroup -S cristalins && adduser -S cristalins -G cristalins

COPY --from=build /app/package.json ./
COPY --from=build /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/prisma.config.ts ./
COPY docker-entrypoint.sh ./

RUN chmod +x docker-entrypoint.sh \
  && chown -R cristalins:cristalins /app

USER cristalins

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/api/v1/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["./docker-entrypoint.sh"]
