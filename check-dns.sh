#!/bin/bash

echo "🌐 Verificando propagação DNS do soulfulroots.live..."
echo ""

echo "✅ Status do domínio: OK (clientHold removido!)"
echo "📧 Email atualizado para: soulfulrootsmusic@gmail.com"
echo ""

echo "🔍 Testando DNS em diferentes servidores..."
echo ""

# Testar diferentes DNS servers
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")

for dns in "${DNS_SERVERS[@]}"; do
    echo "📡 Testando DNS $dns:"
    result=$(dig +short soulfulroots.live @$dns 2>/dev/null)
    if [ -n "$result" ]; then
        echo "   ✅ Resolvendo: $result"
    else
        echo "   ❌ Não resolvendo ainda"
    fi
done

echo ""
echo "⏰ Propagação DNS pode levar até 48h"
echo "🎵 Aplicação continua funcionando em: http://54.173.50.224"
echo ""
echo "🔄 Para testar novamente: ./check-dns.sh"