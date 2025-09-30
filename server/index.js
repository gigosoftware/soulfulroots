require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const db = require('./database');
const { authenticateToken, requireAdmin } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 5001;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Configuração do multer para upload de arquivos
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = file.fieldname === 'cover' ? 'uploads/covers' : 'uploads/songs';
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage,
  fileFilter: (req, file, cb) => {
    if (file.fieldname === 'cover') {
      if (file.mimetype.startsWith('image/')) {
        cb(null, true);
      } else {
        cb(new Error('Apenas imagens são permitidas para capa'));
      }
    } else if (file.fieldname === 'song') {
      if (file.mimetype === 'audio/mpeg' || file.mimetype === 'audio/wav') {
        cb(null, true);
      } else {
        cb(new Error('Apenas arquivos MP3 e WAV são permitidos'));
      }
    }
  }
});

// Rotas de autenticação
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  db.get('SELECT * FROM users WHERE email = ?', [email], (err, user) => {
    if (err) return res.status(500).json({ error: 'Erro no servidor' });
    if (!user) return res.status(401).json({ error: 'Credenciais inválidas' });
    
    if (bcrypt.compareSync(password, user.password)) {
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      res.json({ token, user: { id: user.id, email: user.email, role: user.role } });
    } else {
      res.status(401).json({ error: 'Credenciais inválidas' });
    }
  });
});

app.post('/api/auth/register', authenticateToken, requireAdmin, (req, res) => {
  const { email, password, role = 'listener' } = req.body;
  const hashedPassword = bcrypt.hashSync(password, 10);
  
  db.run('INSERT INTO users (email, password, role) VALUES (?, ?, ?)', 
    [email, hashedPassword, role], function(err) {
    if (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        return res.status(400).json({ error: 'Email já cadastrado' });
      }
      return res.status(500).json({ error: 'Erro ao criar usuário' });
    }
    res.json({ message: 'Usuário criado com sucesso', id: this.lastID });
  });
});

// Rotas de álbuns
app.get('/api/albums', authenticateToken, (req, res) => {
  const isAdmin = req.user.role === 'admin';
  const query = isAdmin 
    ? `SELECT a.*, COUNT(s.id) as song_count 
       FROM albums a 
       LEFT JOIN songs s ON a.id = s.album_id 
       GROUP BY a.id 
       ORDER BY a.created_at DESC`
    : `SELECT a.*, COUNT(s.id) as song_count 
       FROM albums a 
       LEFT JOIN songs s ON a.id = s.album_id 
       WHERE a.is_hidden = 0
       GROUP BY a.id 
       ORDER BY a.created_at DESC`;
       
  db.all(query, (err, albums) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar álbuns' });
    res.json(albums);
  });
});

app.post('/api/albums', authenticateToken, requireAdmin, upload.single('cover'), (req, res) => {
  const { name, description } = req.body;
  const coverImage = req.file ? `/uploads/covers/${req.file.filename}` : null;
  
  db.run('INSERT INTO albums (name, description, cover_image) VALUES (?, ?, ?)', 
    [name, description, coverImage], function(err) {
    if (err) return res.status(500).json({ error: 'Erro ao criar álbum' });
    res.json({ message: 'Álbum criado com sucesso', id: this.lastID });
  });
});

app.put('/api/albums/:id/release', authenticateToken, requireAdmin, (req, res) => {
  const { id } = req.params;
  const { is_released } = req.body;
  
  db.run('UPDATE albums SET is_released = ? WHERE id = ?', [is_released, id], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao atualizar álbum' });
    res.json({ message: 'Status do álbum atualizado' });
  });
});

app.put('/api/albums/:id/visibility', authenticateToken, requireAdmin, (req, res) => {
  const { id } = req.params;
  const { is_hidden } = req.body;
  
  db.run('UPDATE albums SET is_hidden = ? WHERE id = ?', [is_hidden, id], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao atualizar visibilidade' });
    res.json({ message: 'Visibilidade do álbum atualizada' });
  });
});

app.put('/api/albums/:id', authenticateToken, requireAdmin, upload.single('cover'), (req, res) => {
  const { id } = req.params;
  const { name, description } = req.body;
  const coverImage = req.file ? `/uploads/covers/${req.file.filename}` : null;
  
  let query = 'UPDATE albums SET name = ?, description = ?';
  let params = [name, description];
  
  if (coverImage) {
    query += ', cover_image = ?';
    params.push(coverImage);
  }
  
  query += ' WHERE id = ?';
  params.push(id);
  
  db.run(query, params, (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao atualizar álbum' });
    res.json({ message: 'Álbum atualizado com sucesso' });
  });
});

// Rotas de músicas
app.get('/api/albums/:id/songs', authenticateToken, (req, res) => {
  const { id } = req.params;
  
  db.all('SELECT * FROM songs WHERE album_id = ? ORDER BY track_number', [id], (err, songs) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar músicas' });
    res.json(songs);
  });
});

app.post('/api/albums/:id/songs', authenticateToken, requireAdmin, upload.single('song'), (req, res) => {
  const { id } = req.params;
  const { name, track_number, lyrics } = req.body;
  const filePath = req.file ? `/uploads/songs/${req.file.filename}` : null;
  
  db.run('INSERT INTO songs (album_id, name, track_number, file_path, lyrics) VALUES (?, ?, ?, ?, ?)', 
    [id, name, track_number, filePath, lyrics], function(err) {
    if (err) return res.status(500).json({ error: 'Erro ao adicionar música' });
    res.json({ message: 'Música adicionada com sucesso', id: this.lastID });
  });
});

app.put('/api/songs/:id', authenticateToken, requireAdmin, upload.single('song'), (req, res) => {
  const { id } = req.params;
  const { name, track_number, lyrics } = req.body;
  const filePath = req.file ? `/uploads/songs/${req.file.filename}` : null;
  
  let query = 'UPDATE songs SET name = ?, track_number = ?, lyrics = ?';
  let params = [name, track_number, lyrics];
  
  if (filePath) {
    query += ', file_path = ?';
    params.push(filePath);
  }
  
  query += ' WHERE id = ?';
  params.push(id);
  
  db.run(query, params, (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao atualizar música' });
    res.json({ message: 'Música atualizada com sucesso' });
  });
});

// Rotas de avaliação
app.post('/api/songs/:id/rate', authenticateToken, (req, res) => {
  const { id } = req.params;
  const { rating } = req.body;
  const userId = req.user.id;
  
  db.run('INSERT OR REPLACE INTO ratings (user_id, song_id, rating) VALUES (?, ?, ?)', 
    [userId, id, rating], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao avaliar música' });
    
    // Atualizar média
    db.get('SELECT AVG(rating) as avg_rating FROM ratings WHERE song_id = ?', [id], (err, result) => {
      if (!err && result) {
        db.run('UPDATE songs SET average_rating = ? WHERE id = ?', [result.avg_rating, id]);
      }
    });
    
    res.json({ message: 'Avaliação registrada' });
  });
});

app.get('/api/songs/:id/rating', authenticateToken, (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  
  db.get('SELECT rating FROM ratings WHERE user_id = ? AND song_id = ?', [userId, id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar avaliação' });
    res.json({ rating: result ? result.rating : null });
  });
});

app.get('/api/songs/:id', authenticateToken, (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT * FROM songs WHERE id = ?', [id], (err, song) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar música' });
    if (!song) return res.status(404).json({ error: 'Música não encontrada' });
    res.json(song);
  });
});

app.get('/api/albums/:id', authenticateToken, (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT * FROM albums WHERE id = ?', [id], (err, album) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar álbum' });
    if (!album) return res.status(404).json({ error: 'Álbum não encontrado' });
    res.json(album);
  });
});

// Rotas de administração de usuários
app.get('/api/users', authenticateToken, requireAdmin, (req, res) => {
  db.all('SELECT id, email, role, created_at FROM users ORDER BY created_at DESC', (err, users) => {
    if (err) return res.status(500).json({ error: 'Erro ao buscar usuários' });
    res.json(users);
  });
});

app.put('/api/users/:id/role', authenticateToken, requireAdmin, (req, res) => {
  const { id } = req.params;
  const { role } = req.body;
  
  if (!['admin', 'listener'].includes(role)) {
    return res.status(400).json({ error: 'Role inválido' });
  }
  
  db.run('UPDATE users SET role = ? WHERE id = ?', [role, id], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao atualizar role' });
    res.json({ message: 'Role atualizado com sucesso' });
  });
});

app.put('/api/users/:id/password', authenticateToken, requireAdmin, (req, res) => {
  const { id } = req.params;
  const { password } = req.body;
  
  const hashedPassword = bcrypt.hashSync(password, 10);
  
  db.run('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, id], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao resetar senha' });
    res.json({ message: 'Senha resetada com sucesso' });
  });
});

app.delete('/api/users/:id', authenticateToken, requireAdmin, (req, res) => {
  const { id } = req.params;
  
  // Não permitir deletar o próprio usuário
  if (parseInt(id) === req.user.id) {
    return res.status(400).json({ error: 'Não é possível deletar seu próprio usuário' });
  }
  
  db.run('DELETE FROM users WHERE id = ?', [id], (err) => {
    if (err) return res.status(500).json({ error: 'Erro ao deletar usuário' });
    res.json({ message: 'Usuário deletado com sucesso' });
  });
});

// Criar pastas de upload
const fs = require('fs');
['uploads/covers', 'uploads/songs'].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

app.listen(PORT, () => {
  console.log(`🎵 Soulful Roots Server rodando na porta ${PORT}`);
});