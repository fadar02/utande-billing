FROM node:20-slim

RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json* frontend/
RUN cd frontend && npm install

COPY frontend/ frontend/
RUN cd frontend && npm run build

COPY backend/package.json backend/package-lock.json* backend/
RUN cd backend && npm install

COPY backend/ backend/
RUN cd backend && npx prisma generate && npx tsc

EXPOSE 3000

CMD cd backend && npx prisma db push --skip-generate --accept-data-loss && node dist/index.js
