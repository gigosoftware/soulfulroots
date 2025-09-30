# 🚀 Deploy do Soulful Roots

## 📋 Preparação para Deploy

### ✅ **Funcionalidades Completas:**
- ✅ Sistema de autenticação completo
- ✅ Gerenciamento de álbuns e músicas
- ✅ Player de áudio avançado
- ✅ Sistema de avaliações
- ✅ Busca inteligente
- ✅ Histórico e favoritas
- ✅ **Administração de usuários completa**
- ✅ Interface responsiva

### 🔧 **Administração de Usuários:**
- **👥 Listar usuários** - Ver todos os usuários cadastrados
- **👑 Alterar roles** - Admin ↔ Ouvinte
- **🔑 Resetar senhas** - Definir nova senha para qualquer usuário
- **🗑️ Deletar usuários** - Remover usuários (exceto próprio)
- **🛡️ Proteções** - Admin não pode deletar a si mesmo

## 🌐 Opções de Deploy

### 1. **AWS (Recomendado)**
```bash
# Preparar para AWS
npm run build
```

**Serviços necessários:**
- **EC2** - Servidor da aplicação
- **RDS** - Banco de dados PostgreSQL
- **S3** - Arquivos de mídia
- **CloudFront** - CDN

### 2. **Heroku (Mais Simples)**
```bash
# Instalar Heroku CLI
npm install -g heroku

# Login e criar app
heroku login
heroku create soulful-roots-app

# Deploy
git push heroku main
```

### 3. **DigitalOcean**
```bash
# Usar Docker
docker build -t soulful-roots .
docker run -p 80:3000 soulful-roots
```

### 4. **Vercel + Railway**
- **Frontend**: Vercel
- **Backend**: Railway
- **Banco**: Railway PostgreSQL

## 📦 Preparação dos Arquivos

### **1. Variáveis de Ambiente**
Criar `.env.production`:
```env
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/db
JWT_SECRET=seu-jwt-secret-super-seguro
PORT=5001
```

### **2. Build de Produção**
```bash
# Cliente
cd client && npm run build

# Servidor
cd server && npm install --production
```

### **3. Configurar CORS**
```javascript
// server/index.js
app.use(cors({
  origin: ['https://seudominio.com'],
  credentials: true
}));
```

## 🗄️ Migração do Banco

### **SQLite → PostgreSQL**
```sql
-- Criar tabelas no PostgreSQL
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'listener',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE albums (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  cover_image VARCHAR(255),
  is_released BOOLEAN DEFAULT FALSE,
  is_hidden BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE songs (
  id SERIAL PRIMARY KEY,
  album_id INTEGER REFERENCES albums(id),
  name VARCHAR(255) NOT NULL,
  track_number INTEGER,
  file_path VARCHAR(255),
  lyrics TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ratings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  song_id INTEGER REFERENCES songs(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, song_id)
);
```

## 🔒 Segurança para Produção

### **1. Configurações de Segurança**
```javascript
// Adicionar ao server/index.js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

app.use(helmet());
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100 // máximo 100 requests por IP
}));
```

### **2. HTTPS Obrigatório**
```javascript
// Redirecionar HTTP para HTTPS
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    res.redirect(`https://${req.header('host')}${req.url}`);
  } else {
    next();
  }
});
```

## 📱 PWA (Progressive Web App)

### **1. Manifest**
```json
// client/public/manifest.json
{
  "name": "Soulful Roots",
  "short_name": "SoulfulRoots",
  "description": "Streaming Privado da Soulful Roots",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#ff6b35",
  "background_color": "#1a1a2e",
  "icons": [
    {
      "src": "icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
```

### **2. Service Worker**
```javascript
// client/public/sw.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('soulful-roots-v1').then((cache) => {
      return cache.addAll([
        '/',
        '/static/js/bundle.js',
        '/static/css/main.css'
      ]);
    })
  );
});
```

## 🚀 Deploy Automático

### **GitHub Actions**
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install and Build
        run: |
          npm install
          npm run build
      - name: Deploy to AWS
        run: |
          # Comandos de deploy
```

## 📊 Monitoramento

### **1. Logs**
```javascript
// Adicionar logging
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### **2. Analytics**
- Google Analytics
- Sentry para erros
- New Relic para performance

## ✅ Checklist Final

- [ ] Todas as funcionalidades testadas
- [ ] Variáveis de ambiente configuradas
- [ ] Banco de dados migrado
- [ ] HTTPS configurado
- [ ] CORS configurado corretamente
- [ ] Rate limiting implementado
- [ ] Logs configurados
- [ ] Backup automático configurado
- [ ] Domínio personalizado configurado
- [ ] SSL certificado instalado

---

**🎵 Seu Spotify privado está pronto para o mundo! 🚀**