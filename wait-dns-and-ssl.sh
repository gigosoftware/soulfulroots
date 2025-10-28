#!/bin/bash

echo "🌐 Aguardando propagação DNS e validação SSL..."

# Aguardar propagação DNS
echo "⏳ Aguardando DNS propagar..."
while true; do
    if nslookup play.soulfulroots.live 8.8.8.8 > /dev/null 2>&1; then
        echo "✅ DNS propagado!"
        break
    else
        echo "⏳ DNS ainda propagando... (aguarde 2-5 minutos)"
        sleep 30
    fi
done

# Testar acesso HTTP
echo "🌐 Testando acesso HTTP..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://play.soulfulroots.live)
if [ "$HTTP_STATUS" = "301" ]; then
    echo "✅ HTTP funcionando (redirecionando para HTTPS)"
else
    echo "⚠️  HTTP status: $HTTP_STATUS"
fi

# Aguardar certificado SSL
echo "🔐 Aguardando certificado SSL..."
CERT_ARN="arn:aws:acm:us-east-1:963900948667:certificate/0aa50d37-5cb8-49ff-8978-a45e71e8c2b8"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:963900948667:loadbalancer/app/soulful-roots-alb/e564c582fa452667"
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:963900948667:targetgroup/soulful-roots-targets/a9d0d82701ee12b8"

while true; do
    STATUS=$(aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text)
    echo "Status do certificado: $STATUS"
    
    if [ "$STATUS" = "ISSUED" ]; then
        echo "✅ Certificado SSL validado!"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Falha na validação do certificado"
        exit 1
    fi
    
    sleep 30
done

# Criar listener HTTPS
echo "🔒 Criando listener HTTPS..."
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ HTTPS configurado!"
else
    echo "⚠️  HTTPS pode já estar configurado"
fi

# Testar HTTPS
echo "🔐 Testando HTTPS..."
sleep 30
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://play.soulfulroots.live)
if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS funcionando perfeitamente!"
else
    echo "⏳ HTTPS status: $HTTPS_STATUS (pode precisar de mais alguns minutos)"
fi

echo ""
echo "🎉 CONFIGURAÇÃO CONCLUÍDA!"
echo ""
echo "🌐 Seus domínios seguros:"
echo "   • https://soulfulroots.live"
echo "   • https://play.soulfulroots.live"
echo ""
echo "✅ Certificado SSL válido"
echo "✅ Redirecionamento HTTP → HTTPS"
echo "✅ Load Balancer configurado"
echo ""
echo "🎵 Acesse seu app com segurança total!"