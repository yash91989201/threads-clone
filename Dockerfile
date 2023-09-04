# Install dependencies only when needed
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install -g npm@10.0.0
RUN npm install

# Rebuild the source code only when needed
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED 1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm install -g npm@10.0.0
RUN npx prisma generate
RUN npm run build

# Production image, copy all the files and run next
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV="production"
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm install -g npm@10.0.0
RUN npm install prisma
COPY --from=builder ./app/.next/standalone ./
COPY --from=builder ./app/.next/static ./.next/static
COPY --from=builder ./app/public ./public
COPY --from=builder ./app/prisma ./prisma

CMD ["/bin/sh","-c","npx prisma migrate deploy && node server.js"]

# docker network create --driver=bridge app
# docker run -itd --rm --network=app -p 80:3000 --env-file=.env --name=threads-clone threads-clone
# docker run -itd --rm --network=app -p 5234:5432 -e POSTGRES_PASSWORD=password -e POSTGRES_USER=root -e POSTGRES_DB=threads-db  --name=postgres postgres:latest