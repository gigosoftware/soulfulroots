#!/bin/bash

echo "🔄 Monitorando atualização do domínio soulfulroots.live..."
echo ""

OPERATION_ID="edfce23d-5381-4b9f-b589-d108372ccfb2"

while true; do
    echo "⏰ $(date '+%H:%M:%S') - Verificando status..."
    
    STATUS=$(aws route53domains get-operation-detail --operation-id $OPERATION_ID --query 'Status' --output text)
    
    echo "📋 Status atual: $STATUS"
    
    if [ "$STATUS" = "SUCCESSFUL" ]; then
        echo ""
        echo "✅ SUCESSO! Atualização concluída!"
        echo ""
        echo "📧 Verifique seu email soulfulrootsmusic@gmail.com"
        echo "🔍 Procure por emails da AWS para verificação"
        echo ""
        echo "📋 Verificando status do domínio..."
        aws route53domains get-domain-detail --domain-name soulfulroots.live --query 'StatusList'
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo ""
        echo "❌ ERRO na atualização!"
        aws route53domains get-operation-detail --operation-id $OPERATION_ID
        break
    else
        echo "⏳ Aguardando... (pressione Ctrl+C para parar)"
        sleep 30
    fi
    echo ""
done