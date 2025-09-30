#!/bin/bash

echo "🎵 Iniciando Soulful Roots App..."

# Matar processos nas portas se estiverem ocupadas
echo "🔧 Liberando portas..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true

# Verificar se as dependências estão instaladas
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm run install-all
fi

# Iniciar o aplicativo
echo "🚀 Iniciando servidor (porta 5001) e cliente (porta 3000)..."
npm run dev