#!/bin/bash

echo "🚀 Deploy Soulful Roots - Versão Corrigida"

REGION="us-east-1"
KEY_NAME="soulful-roots-key"
SECURITY_GROUP="soulful-roots-sg"

# User data com configuração completa
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y

# Instalar dependências
yum install -y git curl

# Instalar Node.js via NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 16
nvm use 16

# Instalar nginx
amazon-linux-extras install nginx1 -y

# Clonar repositório
cd /home/ec2-user
git clone https://github.com/gigosoftware/soulfulroots.git
chown -R ec2-user:ec2-user soulfulroots

# Build do frontend
cd soulfulroots/client
sudo -u ec2-user bash -c 'source ~/.bashrc && nvm use 16 && npm install && npm run build'

# Instalar dependências do servidor
cd ../server
sudo -u ec2-user bash -c 'source ~/.bashrc && nvm use 16 && npm install'

# Copiar build para servidor
cp -r ../client/build ./public
chown -R ec2-user:ec2-user public

# Criar diretórios
mkdir -p uploads/covers uploads/songs
chown -R ec2-user:ec2-user uploads

# Configurar nginx
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

# Iniciar nginx
systemctl start nginx
systemctl enable nginx

# Criar script de inicialização
cat > /home/ec2-user/start-app.sh << 'SCRIPT'
#!/bin/bash
cd /home/ec2-user/soulfulroots/server
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 16
export NODE_ENV=production
export PORT=5001
export JWT_SECRET=soulful-roots-super-secret-jwt-key-2024
node index.js
SCRIPT

chmod +x /home/ec2-user/start-app.sh
chown ec2-user:ec2-user /home/ec2-user/start-app.sh

# Criar serviço systemd
cat > /etc/systemd/system/soulful-roots.service << 'SERVICE'
[Unit]
Description=Soulful Roots App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/soulfulroots/server
ExecStart=/home/ec2-user/start-app.sh
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=5001
Environment=JWT_SECRET=soulful-roots-super-secret-jwt-key-2024

[Install]
WantedBy=multi-user.target
SERVICE

# Iniciar serviço
systemctl daemon-reload
systemctl enable soulful-roots
systemctl start soulful-roots

echo "✅ Soulful Roots configurado e rodando!"
EOF
)

# Criar nova instância
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t3.medium \
    --key-name $KEY_NAME \
    --security-group-ids $(aws ec2 describe-security-groups --group-names $SECURITY_GROUP --region $REGION --query 'SecurityGroups[0].GroupId' --output text) \
    --user-data "$USER_DATA" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=soulful-roots-server-v2}]" \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Nova instância criada: $INSTANCE_ID"
echo "⏳ Aguardando instância ficar pronta..."

aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
echo "🎉 NOVA INSTÂNCIA CRIADA!"
echo "   ID: $INSTANCE_ID"
echo "   IP: $PUBLIC_IP"
echo "   URL: http://$PUBLIC_IP"
echo ""
echo "⏳ Aguarde 5-10 minutos para instalação completa"