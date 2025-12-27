FROM node:20-alpine AS base

# 1. Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b43f934ea938b47a716700259561621746e16275#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app/src/Clients/admin-portal

# Install dependencies based on the preferred package manager
COPY package.json .
COPY package-lock.json .
RUN npm install --frozen-lockfile

# 2. Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app/src/Clients/admin-portal
COPY . .
COPY --from=deps /app/src/Clients/admin-portal/node_modules ./node_modules

# Next.js collects completely anonymous telemetry data about usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line to disable telemetry.
ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

# 3. Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app/src/Clients/admin-portal
COPY . .
COPY --from=builder /app/src/Clients/admin-portal/public ./public
COPY --from=builder /app/src/Clients/admin-portal/.next ./.next
COPY --from=builder /app/src/Clients/admin-portal/node_modules ./node_modules
COPY --from=builder /app/src/Clients/admin-portal/package.json ./package.json

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["npm", "start"]
