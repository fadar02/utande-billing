#!/bin/bash

echo "=== Installing backend dependencies ==="
cd backend
npm install

echo "=== Installing frontend dependencies ==="
cd ../frontend
npm install || echo "Frontend npm install failed (non-fatal)"

echo "=== Building frontend ==="
./node_modules/.bin/vite build || echo "Frontend build failed (non-fatal)"

echo "=== Backend setup ==="
cd ../backend

echo "=== Selecting Prisma schema for environment ==="
if [ "$RENDER" = "true" ]; then
  cp prisma/schema.postgres.prisma prisma/schema.prisma
  echo "Using PostgreSQL schema"
else
  echo "Using SQLite schema"
fi

echo "=== Generating Prisma client ==="
./node_modules/.bin/prisma generate

echo "=== Compiling TypeScript (fast) ==="
./node_modules/.bin/tsc --declaration false --declarationMap false --sourceMap false --outDir dist

echo "=== Build complete ==="
