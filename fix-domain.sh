#!/bin/bash

echo "🔍 Verificando status do domínio soulfulroots.live..."

# Verificar status atual
echo "📋 Status atual:"
aws route53domains get-domain-detail --domain-name soulfulroots.live --query 'StatusList'

echo ""
echo "🔧 Para resolver o clientHold:"
echo "1. Verifique o email admin@soulfulroots.live"
echo "2. Complete qualquer verificação pendente"
echo "3. Ou atualize o email de contato para um válido"

echo ""
echo "📧 Para atualizar email de contato:"
echo "aws route53domains update-domain-contact --domain-name soulfulroots.live --admin-contact Email=SEU_EMAIL_VALIDO@gmail.com --registrant-contact Email=SEU_EMAIL_VALIDO@gmail.com --tech-contact Email=SEU_EMAIL_VALIDO@gmail.com"

echo ""
echo "⏰ Aguarde até 48h para propagação após resolver o clientHold"