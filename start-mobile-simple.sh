#!/bin/bash

echo "📱 Iniciando Soulful Roots - Simulação Mobile..."

# Descobrir IP local para acesso mobile
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo ""
echo "🚀 Para testar no celular:"
echo "   📱 Conecte seu celular no mesmo WiFi"
echo "   🌐 Acesse: http://$IP:3000"
echo ""
echo "🖥️  Para simular no computador:"
echo "   1. Abra: http://localhost:3000"
echo "   2. Pressione F12"
echo "   3. Clique no ícone de celular 📱"
echo "   4. Escolha iPhone ou Android"
echo ""

# Iniciar normalmente
./start.sh