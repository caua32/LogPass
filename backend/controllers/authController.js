const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

exports.registrar = async (req, res) => {
  const { nome, email, senha, tipo } = req.body;

  if (!nome || !email || !senha || !tipo) {
    return res.status(400).json({ message: 'Campos obrigatórios: nome, email, senha, tipo.' });
  }
  if (!['empresa', 'consumidor'].includes(tipo)) {
    return res.status(400).json({ message: 'Tipo deve ser "empresa" ou "consumidor".' });
  }

  try {
    const hashed = await bcrypt.hash(senha, 10);
    const result = await pool.query(
      'INSERT INTO usuario (nome, email, senha, tipo) VALUES ($1, $2, $3, $4) RETURNING id, nome, email, tipo',
      [nome, email, hashed, tipo]
    );
    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.id, email: user.email, tipo: user.tipo },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );
    res.status(201).json({ message: 'Usuário cadastrado com sucesso!', token, usuario: user });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Email já cadastrado.' });
    }
    console.error(err);
    res.status(500).json({ message: 'Erro ao cadastrar usuário.' });
  }
};

exports.login = async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ message: 'Email e senha são obrigatórios.' });
  }

  try {
    const result = await pool.query('SELECT * FROM usuario WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(senha, user.senha);
    if (!valid) {
      return res.status(401).json({ message: 'Senha incorreta.' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, tipo: user.tipo },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );

    res.json({
      message: 'Login realizado com sucesso!',
      token,
      usuario: { id: user.id, nome: user.nome, email: user.email, tipo: user.tipo },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao realizar login.' });
  }
};

exports.me = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, email, tipo, created_at FROM usuario WHERE id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Usuário não encontrado.' });
    }
    res.json({ usuario: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar dados do usuário.' });
  }
};
