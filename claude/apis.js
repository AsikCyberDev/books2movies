// package.json
{
    "name": "book-to-movie-api",
    "version": "1.0.0",
    "description": "API for book to movie suggestion platform",
    "main": "src/app.js",
    "scripts": {
      "start": "node src/app.js",
      "dev": "nodemon src/app.js",
      "test": "jest"
    },
    "dependencies": {
      "express": "^4.18.2",
      "pg": "^8.11.3",
      "jsonwebtoken": "^9.0.2",
      "bcryptjs": "^2.4.3",
      "cors": "^2.8.5",
      "dotenv": "^16.3.1",
      "express-validator": "^7.0.1",
      "helmet": "^7.1.0",
      "winston": "^3.11.0"
    },
    "devDependencies": {
      "jest": "^29.7.0",
      "nodemon": "^3.0.2",
      "supertest": "^6.3.3"
    }
  }
  
  // src/app.js
  const express = require('express');
  const cors = require('cors');
  const helmet = require('helmet');
  const { errorHandler } = require('./middleware/errorHandler');
  const authRoutes = require('./routes/auth');
  const suggestionRoutes = require('./routes/suggestions');
  const commentRoutes = require('./routes/comments');
  const searchRoutes = require('./routes/search');
  const adminRoutes = require('./routes/admin');
  const notificationRoutes = require('./routes/notifications');
  
  const app = express();
  
  app.use(helmet());
  app.use(cors());
  app.use(express.json());
  
  // Routes
  app.use('/api/auth', authRoutes);
  app.use('/api/suggestions', suggestionRoutes);
  app.use('/api/comments', commentRoutes);
  app.use('/api/search', searchRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/notifications', notificationRoutes);
  
  app.use(errorHandler);
  
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  
  module.exports = app;
  
  // src/config/db.js
  const { Pool } = require('pg');
  
  const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });
  
  module.exports = {
    query: (text, params) => pool.query(text, params),
  };
  
  // src/middleware/auth.js
  const jwt = require('jsonwebtoken');
  
  const auth = async (req, res, next) => {
    try {
      const token = req.header('Authorization').replace('Bearer ', '');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded;
      next();
    } catch (error) {
      res.status(401).send({ error: 'Please authenticate.' });
    }
  };
  
  const checkRole = (roles) => {
    return (req, res, next) => {
      if (!roles.includes(req.user.role)) {
        return res.status(403).send({ error: 'Access denied.' });
      }
      next();
    };
  };
  
  module.exports = { auth, checkRole };
  
  // src/routes/auth.js
  const express = require('express');
  const router = express.Router();
  const bcrypt = require('bcryptjs');
  const jwt = require('jsonwebtoken');
  const db = require('../config/db');
  
  router.post('/register', async (req, res) => {
    try {
      const { email, password, username, role } = req.body;
      const hashedPassword = await bcrypt.hash(password, 10);
      
      const result = await db.query(
        'INSERT INTO users (email, password_hash, username, role) VALUES ($1, $2, $3, $4) RETURNING id, email, username, role',
        [email, hashedPassword, username, role]
      );
  
      const token = jwt.sign({ id: result.rows[0].id, role }, process.env.JWT_SECRET);
      res.status(201).json({ user: result.rows[0], token });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  router.post('/login', async (req, res) => {
    try {
      const { email, password } = req.body;
      const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
      const user = result.rows[0];
  
      if (!user || !await bcrypt.compare(password, user.password_hash)) {
        throw new Error('Invalid login credentials');
      }
  
      const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET);
      res.json({ user: { id: user.id, email, role: user.role }, token });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // src/routes/suggestions.js
  const express = require('express');
  const router = express.Router();
  const { auth, checkRole } = require('../middleware/auth');
  const db = require('../config/db');
  
  // Create suggestion
  router.post('/', auth, async (req, res) => {
    try {
      const { title, author, isbn, pitch, genre } = req.body;
      const result = await db.query(
        'INSERT INTO book_suggestions (title, author, isbn, pitch, genre, suggested_by) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [title, author, isbn, pitch, genre, req.user.id]
      );
      res.status(201).json(result.rows[0]);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  // Get all suggestions with filters
  router.get('/', async (req, res) => {
    try {
      const { genre, status, sort = 'created_at' } = req.query;
      let query = 'SELECT * FROM book_suggestions WHERE 1=1';
      const params = [];
  
      if (genre) {
        query += ' AND $1 = ANY(genre)';
        params.push(genre);
      }
  
      if (status) {
        query += ` AND status = $${params.length + 1}`;
        params.push(status);
      }
  
      query += ` ORDER BY ${sort} DESC`;
      const result = await db.query(query, params);
      res.json(result.rows);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  // Get single suggestion
  router.get('/:id', async (req, res) => {
    try {
      const result = await db.query('SELECT * FROM book_suggestions WHERE id = $1', [req.params.id]);
      if (!result.rows[0]) {
        return res.status(404).json({ error: 'Suggestion not found' });
      }
      res.json(result.rows[0]);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  // Upvote a suggestion
  router.post('/:id/upvote', auth, async (req, res) => {
    try {
      await db.query('INSERT INTO upvotes (user_id, suggestion_id) VALUES ($1, $2)', 
        [req.user.id, req.params.id]
      );
      res.status(201).json({ message: 'Upvote recorded' });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // src/routes/comments.js
  const express = require('express');
  const router = express.Router();
  const { auth } = require('../middleware/auth');
  const db = require('../config/db');
  
  router.post('/:suggestionId', auth, async (req, res) => {
    try {
      const { content } = req.body;
      const result = await db.query(
        'INSERT INTO comments (content, user_id, suggestion_id) VALUES ($1, $2, $3) RETURNING *',
        [content, req.user.id, req.params.suggestionId]
      );
      res.status(201).json(result.rows[0]);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  router.get('/:suggestionId', async (req, res) => {
    try {
      const result = await db.query(
        'SELECT comments.*, users.username FROM comments JOIN users ON comments.user_id = users.id WHERE suggestion_id = $1 ORDER BY created_at DESC',
        [req.params.suggestionId]
      );
      res.json(result.rows);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // src/routes/search.js
  const express = require('express');
  const router = express.Router();
  const db = require('../config/db');
  
  router.get('/', async (req, res) => {
    try {
      const { q, genre, minUpvotes } = req.query;
      let query = `
        SELECT bs.*, 
               ts_rank_cd(search_vector, plainto_tsquery($1)) as rank
        FROM book_suggestions bs
        WHERE search_vector @@ plainto_tsquery($1)
      `;
      const params = [q];
  
      if (genre) {
        query += ` AND $2 = ANY(genre)`;
        params.push(genre);
      }
  
      if (minUpvotes) {
        query += ` AND upvote_count >= $${params.length + 1}`;
        params.push(minUpvotes);
      }
  
      query += ` ORDER BY rank DESC`;
      const result = await db.query(query, params);
      res.json(result.rows);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // src/routes/admin.js
  const express = require('express');
  const router = express.Router();
  const { auth, checkRole } = require('../middleware/auth');
  const db = require('../config/db');
  
  router.get('/suggestions/pending', auth, checkRole(['admin']), async (req, res) => {
    try {
      const result = await db.query(
        'SELECT * FROM book_suggestions WHERE status = $1 ORDER BY created_at DESC',
        ['pending']
      );
      res.json(result.rows);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  router.put('/suggestions/:id/status', auth, checkRole(['admin']), async (req, res) => {
    try {
      const { status } = req.body;
      const result = await db.query(
        'UPDATE book_suggestions SET status = $1 WHERE id = $2 RETURNING *',
        [status, req.params.id]
      );
      res.json(result.rows[0]);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // src/routes/notifications.js
  const express = require('express');
  const router = express.Router();
  const { auth } = require('../middleware/auth');
  const db = require('../config/db');
  
  router.get('/', auth, async (req, res) => {
    try {
      const result = await db.query(
        'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
        [req.user.id]
      );
      res.json(result.rows);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  router.put('/:id/read', auth, async (req, res) => {
    try {
      const result = await db.query(
        'UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2 RETURNING *',
        [req.params.id, req.user.id]
      );
      res.json(result.rows[0]);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  module.exports = router;
  
  // .env
  PORT=3000
  DB_USER=your_db_user
  DB_HOST=localhost
  DB_NAME=book_to_movie
  DB_PASSWORD=your_db_password
  DB_PORT=5432
  JWT_SECRET=your_jwt_secret