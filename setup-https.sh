#!/bin/bash

echo "🔐 Configurando HTTPS para Soulful Roots..."

# Variáveis
CERT_ARN="arn:aws:acm:us-east-1:963900948667:certificate/0aa50d37-5cb8-49ff-8978-a45e71e8c2b8"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:963900948667:loadbalancer/app/soulful-roots-alb/e564c582fa452667"
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:963900948667:targetgroup/soulful-roots-targets/a9d0d82701ee12b8"

# Aguardar validação do certificado
echo "⏳ Aguardando validação do certificado SSL..."
while true; do
    STATUS=$(aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status' --output text)
    echo "Status do certificado: $STATUS"
    
    if [ "$STATUS" = "ISSUED" ]; then
        echo "✅ Certificado validado!"
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
  --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

if [ $? -eq 0 ]; then
    echo "✅ Listener HTTPS criado com sucesso!"
else
    echo "❌ Erro ao criar listener HTTPS"
    exit 1
fi

# Verificar health check
echo "🏥 Verificando health check..."
sleep 60

HEALTH_STATUS=$(aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text)
echo "Status do health check: $HEALTH_STATUS"

echo "🎉 Configuração concluída!"
echo ""
echo "🌐 Seus domínios:"
echo "   • https://soulfulroots.live"
echo "   • https://play.soulfulroots.live"
echo ""
echo "⚠️  Aguarde alguns minutos para propagação DNS completa"