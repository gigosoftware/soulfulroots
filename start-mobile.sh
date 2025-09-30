#!/bin/bash

echo "📱 Iniciando Soulful Roots App - Modo Mobile..."

# Matar processos nas portas se estiverem ocupadas
echo "🔧 Liberando portas..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true

# Verificar se as dependências estão instaladas
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm run install-all
fi

# Descobrir IP local
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo "🚀 Iniciando servidor (porta 5001) e cliente (porta 3000)..."
echo "📱 Acesse no celular: http://$IP:3000"
echo "🖥️  Acesse no computador: http://localhost:3000"

# Iniciar o aplicativo
npm run dev &

# Aguardar alguns segundos para o servidor iniciar
sleep 5

# Abrir browser em modo mobile (Chrome)
if command -v google-chrome &> /dev/null; then
    echo "🌐 Abrindo Chrome em modo mobile..."
    google-chrome --new-window --app="http://localhost:3000" --user-agent="Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1" --window-size=375,812 &
elif command -v chromium-browser &> /dev/null; then
    echo "🌐 Abrindo Chromium em modo mobile..."
    chromium-browser --new-window --app="http://localhost:3000" --user-agent="Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1" --window-size=375,812 &
else
    echo "🌐 Abra manualmente: http://localhost:3000"
    echo "📱 Para simular mobile, pressione F12 > Toggle Device Toolbar"
fi

wait