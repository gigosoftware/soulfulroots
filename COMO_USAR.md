# 🎵 Como Usar o Soulful Roots App

## 🚀 Iniciar o App

### 🖥️ **Modo Desktop:**
```bash
./start.sh
```

### 📱 **Modo Mobile (com instruções):**
```bash
./start-mobile-simple.sh
```

### 📱 **Modo Mobile (abre browser simulado):**
```bash
./start-mobile.sh
```

## 🌐 Acessar o App

Após iniciar, acesse:
- **App:** http://localhost:3000

## 👤 Login Inicial

- **Email:** admin@soulfulroots.com
- **Senha:** admin123

## 📱 Testando no Celular

1. Descubra o IP do seu Mac: `ifconfig | grep inet`
2. Acesse no celular: `http://SEU_IP:3000`
3. Exemplo: `http://192.168.1.100:3000`

## 🎵 Fluxo de Teste

1. **Login** como admin
2. **Criar álbum** com capa
3. **Adicionar músicas** (MP3/WAV)
4. **Testar player** 
5. **Criar usuário ouvinte**
6. **Testar avaliações**

## ⚠️ Problemas Comuns

- **Porta ocupada:** Feche outros apps na porta 3000/5001
- **Arquivos não tocam:** Verifique se são MP3 ou WAV válidos
- **Não conecta:** Verifique se ambos servidores iniciaram

## 🛑 Parar o App

Pressione `Ctrl + C` no terminal