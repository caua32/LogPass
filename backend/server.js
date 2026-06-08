const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const cloudinary = require('cloudinary').v2;
const multer = require('multer');
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    const extOk = /\.(jpe?g|png|gif|webp|heic|bmp)$/i.test(file.originalname || '');
    const mimeOk = (file.mimetype || '').startsWith('image/');
    if (mimeOk || extOk) cb(null, true);
    else cb(new Error('Apenas imagens são permitidas.'));
  },
});

const authRoutes = require('./routes/authRoutes');
const empresaRoutes = require('./routes/empresaRoutes');
const consumidorRoutes = require('./routes/consumidorRoutes');
const funcionarioRoutes = require('./routes/funcionarioRoutes');
const reclamacaoRoutes = require('./routes/reclamacaoRoutes');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

// CORS — ajuste ALLOWED_ORIGINS no .env para produção
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000', 'http://10.0.2.2:3000'];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error('Origem não permitida pelo CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '10kb' }));

// Rate limit geral
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Muitas requisições. Tente novamente em 15 minutos.' },
}));

// Rate limit reforçado para autenticação
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Muitas tentativas de login. Tente novamente em 15 minutos.' },
});

app.use('/api/login', authLimiter);
app.use('/api/registrar', authLimiter);
app.use('/api/admin/login', authLimiter);

app.use('/api', authRoutes);
app.use('/api', empresaRoutes);
app.use('/api', consumidorRoutes);
app.use('/api', funcionarioRoutes);
app.use('/api', reclamacaoRoutes);
app.use('/api', chatRoutes(upload));

// Handler de erros global
app.use((err, req, res, next) => {
  console.error(err.stack || err.message || err);
  // Erros de upload (Multer / filtro de arquivo) → 400 com mensagem clara
  if (err instanceof multer.MulterError || /imagens são permitidas/.test(err.message || '')) {
    return res.status(400).json({ message: err.message });
  }
  res.status(500).json({ message: 'Erro interno do servidor.' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor LogPass rodando na porta ${PORT}`));
