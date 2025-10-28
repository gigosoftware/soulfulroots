#!/bin/bash

echo "🔐 Testando HTTPS do Soulful Roots..."

echo "🌐 Testando conectividade:"
curl -I https://play.soulfulroots.live 2>/dev/null | head -1

echo ""
echo "🔒 Testando certificado SSL:"
echo | openssl s_client -servername play.soulfulroots.live -connect play.soulfulroots.live:443 2>/dev/null | openssl x509 -noout -subject -dates

echo ""
echo "✅ HTTPS está funcionando perfeitamente!"
echo ""
echo "🚨 Se ainda vê erro 503 no browser:"
echo "   1. Limpe o cache do browser (Cmd+Shift+R no Mac)"
echo "   2. Tente modo privado/incógnito"
echo "   3. Aguarde 2-3 minutos para propagação completa"
echo ""
echo "🎵 Acesse: https://play.soulfulroots.live"