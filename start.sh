#!/bin/bash
set -e

cd backend

echo "=== Running schema push ==="
./node_modules/.bin/prisma db push --skip-generate --accept-data-loss 2>&1 || echo "prisma db push failed (non-fatal)"

echo "=== Starting app ==="
exec node dist/index.js 2>&1