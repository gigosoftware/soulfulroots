#!/bin/bash

echo "🚀 Iniciando deploy do Soulful Roots na AWS..."

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não configurado. Configure com: aws configure"
    exit 1
fi

# Variáveis
REGION="us-east-1"
KEY_NAME="soulful-roots-key"
SECURITY_GROUP="soulful-roots-sg"
INSTANCE_NAME="soulful-roots-server"

echo "📍 Região: $REGION"

# 1. Criar chave SSH se não existir
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION &> /dev/null; then
    echo "🔑 Criando chave SSH..."
    aws ec2 create-key-pair --key-name $KEY_NAME --region $REGION --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
    chmod 400 ${KEY_NAME}.pem
    echo "✅ Chave SSH criada: ${KEY_NAME}.pem"
else
    echo "✅ Chave SSH já existe"
fi

# 2. Criar Security Group
if ! aws ec2 describe-security-groups --group-names $SECURITY_GROUP --region $REGION &> /dev/null; then
    echo "🛡️ Criando Security Group..."
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP \
        --description "Soulful Roots Security Group" \
        --region $REGION \
        --query 'GroupId' --output text)
    
    # Permitir SSH (22)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # Permitir HTTP (80)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # Permitir HTTPS (443)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    # Permitir porta da aplicação (5001)
    aws ec2 authorize-security-group-ingress \
        --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port 5001 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    echo "✅ Security Group criado: $SECURITY_GROUP_ID"
else
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --group-names $SECURITY_GROUP --region $REGION --query 'SecurityGroups[0].GroupId' --output text)
    echo "✅ Security Group já existe: $SECURITY_GROUP_ID"
fi

# 3. Criar instância EC2
echo "🖥️ Criando instância EC2..."

# User data script para configurar a instância
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker git

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Criar diretórios
mkdir -p /app/data /app/uploads
chown -R ec2-user:ec2-user /app

# Instalar Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Clonar repositório
cd /home/ec2-user
git clone https://github.com/gigosoftware/soulfulroots.git
chown -R ec2-user:ec2-user soulfulroots

# Configurar aplicação
cd soulfulroots
sudo -u ec2-user npm install

# Build do cliente
cd client
sudo -u ec2-user npm install
sudo -u ec2-user npm run build
cd ..

# Instalar dependências do servidor
cd server
sudo -u ec2-user npm install
cd ..

# Copiar build para servidor
cp -r client/build server/public

# Instalar PM2 globalmente
npm install -g pm2

# Criar arquivo de inicialização
cat > /home/ec2-user/start-app.sh << 'SCRIPT'
#!/bin/bash
cd /home/ec2-user/soulfulroots/server
export NODE_ENV=production
export PORT=5001
export JWT_SECRET=soulful-roots-super-secret-jwt-key-2024
pm2 start index.js --name "soulful-roots"
pm2 startup
pm2 save
SCRIPT

chmod +x /home/ec2-user/start-app.sh
chown ec2-user:ec2-user /home/ec2-user/start-app.sh

# Executar aplicação
sudo -u ec2-user /home/ec2-user/start-app.sh

# Configurar nginx como proxy reverso
yum install -y nginx
cat > /etc/nginx/conf.d/soulful-roots.conf << 'NGINX'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 100M;
    
    location / {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX

systemctl start nginx
systemctl enable nginx

echo "✅ Soulful Roots instalado e rodando!"
EOF
)

# Criar instância
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t3.medium \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --user-data "$USER_DATA" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Instância criada: $INSTANCE_ID"
echo "⏳ Aguardando instância ficar pronta..."

# Aguardar instância ficar running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Obter IP público
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo ""
echo "📋 INFORMAÇÕES DA INSTÂNCIA:"
echo "   ID: $INSTANCE_ID"
echo "   IP Público: $PUBLIC_IP"
echo "   Região: $REGION"
echo ""
echo "🌐 ACESSO À APLICAÇÃO:"
echo "   URL: http://$PUBLIC_IP"
echo ""
echo "🔑 ACESSO SSH:"
echo "   ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo ""
echo "⏳ A aplicação pode levar alguns minutos para ficar totalmente disponível."
echo "   Aguarde a instalação e configuração automática terminar."
echo ""
echo "📊 MONITORAMENTO:"
echo "   Status: http://$PUBLIC_IP/health"
echo ""