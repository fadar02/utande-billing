#!/bin/bash
set -e

echo "=== Installing frontend dependencies ==="
cd frontend
npm install

echo "=== Building frontend ==="
npm run build

echo "=== Installing backend dependencies ==="
cd ../backend
npm install

echo "=== Generating Prisma client ==="
npx prisma generate

echo "=== Pushing database schema ==="
npx prisma db push --skip-generate --accept-data-loss

echo "=== Compiling TypeScript ==="
npx tsc

echo "=== Build complete ==="
