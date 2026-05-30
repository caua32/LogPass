const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

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
app.use('/api', chatRoutes);

// Handler de erros global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Erro interno do servidor.' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor LogPass rodando na porta ${PORT}`));
