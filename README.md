# 🎵 Soulful Roots - Streaming Privado

Aplicativo de streaming privado da produtora Soulful Roots para gerenciar álbuns e músicas em produção.

## 🚀 Funcionalidades

### 🎯 Principais
- **Sistema de Autenticação**: Login com email/senha (admin/ouvinte)
- **Gerenciamento de Álbuns**: Criar, visualizar e marcar status (produção/lançado)
- **Gerenciamento de Músicas**: Adicionar músicas com MP3/WAV, letras e numeração
- **Player Completo**: Reprodução com controles, playlist, volume
- **Sistema de Avaliação**: Avaliação de 1-5 estrelas para cada música
- **Interface Responsiva**: Funciona perfeitamente em mobile e desktop

### 🎨 Design
- **Tema Soulful Roots**: Cores laranja/amarelo com gradientes
- **Interface Moderna**: Cards com blur, animações suaves
- **Badges de Status**: Diferenciação visual entre álbuns em produção e lançados
- **Player Fixo**: Player sempre visível na parte inferior

### 🔐 Permissões
- **Administrador**: Criar álbuns, adicionar músicas, gerenciar usuários, alterar status
- **Ouvinte**: Visualizar, reproduzir e avaliar músicas

## 🛠️ Tecnologias

### Backend
- **Node.js + Express**: API REST
- **SQLite**: Banco de dados local
- **JWT**: Autenticação
- **Multer**: Upload de arquivos
- **bcryptjs**: Criptografia de senhas

### Frontend
- **React + TypeScript**: Interface moderna
- **Styled Components**: Estilização
- **React Router**: Navegação
- **Axios**: Requisições HTTP
- **Context API**: Gerenciamento de estado

## 📦 Instalação

1. **Clone e instale dependências:**
```bash
cd soulfulroots
npm run install-all
```

2. **Execute o projeto:**
```bash
npm run dev
```

3. **Acesse:**
- Frontend: http://localhost:3000
- Backend: http://localhost:5001

## 👤 Login Padrão

- **Email**: admin@soulfulroots.com
- **Senha**: admin123
- **Tipo**: Administrador

## 📱 Uso Mobile

O aplicativo é totalmente responsivo e funciona como um PWA:
- **Reprodução**: Integra com Bluetooth do carro/caixas
- **Controles**: Player otimizado para touch
- **Interface**: Adaptada para telas pequenas

## 🎵 Formatos Suportados

- **Áudio**: MP3, WAV
- **Imagens**: JPG, PNG, GIF (capas de álbum)

## 📂 Estrutura do Projeto

```
soulfulroots/
├── server/                 # Backend Node.js
│   ├── database.js        # Configuração SQLite
│   ├── index.js          # Servidor principal
│   ├── middleware/       # Middlewares de auth
│   └── uploads/          # Arquivos enviados
├── client/               # Frontend React
│   ├── src/
│   │   ├── components/   # Componentes React
│   │   ├── contexts/     # Context API
│   │   ├── services/     # API calls
│   │   └── types/        # TypeScript types
└── package.json         # Scripts principais
```

## 🚀 Deploy AWS (Próximo Passo)

O projeto está preparado para deploy na AWS com:
- **EC2**: Servidor da aplicação
- **S3**: Armazenamento de arquivos
- **RDS**: Banco de dados (migração do SQLite)
- **CloudFront**: CDN para arquivos de mídia

## 🎯 Próximas Funcionalidades

- [ ] Playlists personalizadas
- [ ] Comentários nas músicas
- [ ] Histórico de reprodução
- [ ] Notificações push
- [ ] Modo offline
- [ ] Compartilhamento de músicas
- [ ] Analytics de reprodução

## 📞 Suporte

Para dúvidas ou sugestões, entre em contato com a equipe da Soulful Roots.

---

**Desenvolvido com ❤️ para a Soulful Roots**