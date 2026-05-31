const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

exports.getTodasReclamacoes = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT r.id, r.numero_pedido, r.motivo, r.forma_solucao, r.data_abertura, r.data_resolucao,
              r.status_id,
              s.descricao AS status,
              e.nomeempresa,
              c.nome AS consumidor_nome, c.email AS consumidor_email
       FROM reclamacao r
       JOIN status_reclamacao s ON s.id = r.status_id
       JOIN empresa e ON e.id = r.empresa_id
       LEFT JOIN consumidor c ON c.id = r.consumidor_id
       ORDER BY r.data_abertura DESC`
    );
    res.json({ reclamacoes: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar reclamações.' });
  }
};

exports.getConfiguracoes = async (req, res) => {
  try {
    const result = await pool.query(`SELECT chave, valor FROM configuracao_sistema`);
    const config = {};
    result.rows.forEach(r => { config[r.chave] = Number(r.valor); });
    res.json({ configuracoes: config });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar configurações.' });
  }
};

exports.updateConfiguracoes = async (req, res) => {
  const { nivel_aceitavel_horas, nivel_ruim_horas, nivel_critico_horas } = req.body;

  const a = Number(nivel_aceitavel_horas);
  const r = Number(nivel_ruim_horas);
  const c = Number(nivel_critico_horas);

  if (!Number.isInteger(a) || !Number.isInteger(r) || !Number.isInteger(c) ||
      a <= 0 || r <= 0 || c <= 0 || a >= r || r >= c) {
    return res.status(400).json({
      message: 'Valores inválidos. Garanta que Aceitável < Ruim < Crítico e todos positivos.'
    });
  }

  try {
    await pool.query(`UPDATE configuracao_sistema SET valor=$1 WHERE chave='nivel_aceitavel_horas'`, [a]);
    await pool.query(`UPDATE configuracao_sistema SET valor=$1 WHERE chave='nivel_ruim_horas'`, [r]);
    await pool.query(`UPDATE configuracao_sistema SET valor=$1 WHERE chave='nivel_critico_horas'`, [c]);
    res.json({ message: 'Configurações atualizadas com sucesso.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao atualizar configurações.' });
  }
};

exports.getUsuarios = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT u.id, u.nome, u.email, u.tipo, u.created_at,
              c.cpf, c.telefone,
              e.nomeempresa, e.cnpj
       FROM usuario u
       LEFT JOIN consumidor c ON c.usuario_id = u.id
       LEFT JOIN empresa e ON e.usuario_id = u.id
       ORDER BY u.created_at DESC`
    );
    res.json({ usuarios: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar usuários.' });
  }
};

exports.criarUsuario = async (req, res) => {
  const { nome, email, senha, tipo, cpf, cnpj, nomeempresa } = req.body;

  if (!nome || !email || !senha || !tipo) {
    return res.status(400).json({ message: 'Campos obrigatórios: nome, email, senha, tipo.' });
  }
  if (!['consumidor', 'empresa'].includes(tipo)) {
    return res.status(400).json({ message: 'Tipo deve ser "consumidor" ou "empresa".' });
  }
  if (tipo === 'consumidor' && !cpf) {
    return res.status(400).json({ message: 'CPF é obrigatório para consumidor.' });
  }
  if (tipo === 'empresa' && !cnpj) {
    return res.status(400).json({ message: 'CNPJ é obrigatório para empresa.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const hashed = await bcrypt.hash(senha, 10);
    const uRes = await client.query(
      `INSERT INTO usuario (nome, email, senha, tipo) VALUES ($1, $2, $3, $4) RETURNING id, nome, email, tipo`,
      [nome, email, hashed, tipo]
    );
    const user = uRes.rows[0];

    if (tipo === 'consumidor') {
      await client.query(
        `INSERT INTO consumidor (usuario_id, nome, cpf, email) VALUES ($1, $2, $3, $4)`,
        [user.id, nome, cpf, email]
      );
    } else {
      await client.query(
        `INSERT INTO empresa (usuario_id, nomeempresa, cnpj) VALUES ($1, $2, $3)`,
        [user.id, nomeempresa || nome, cnpj]
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ message: 'Usuário criado com sucesso!', usuario: user });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Email, CPF ou CNPJ já cadastrado.' });
    }
    console.error(err);
    res.status(500).json({ message: 'Erro ao criar usuário.' });
  } finally {
    client.release();
  }
};

exports.loginFuncionario = async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ message: 'Email e senha são obrigatórios.' });
  }

  try {
    const result = await pool.query(
      'SELECT * FROM funcionario WHERE email = $1 AND ativo = TRUE',
      [email]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Funcionário não encontrado ou inativo.' });
    }

    const funcionario = result.rows[0];
    const valid = await bcrypt.compare(senha, funcionario.senha);
    if (!valid) {
      return res.status(401).json({ message: 'Credenciais inválidas.' });
    }

    const token = jwt.sign(
      { id: funcionario.id, email: funcionario.email, cargo: funcionario.cargo, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.json({
      message: 'Login administrativo realizado com sucesso!',
      token,
      funcionario: {
        id: funcionario.id,
        nome: funcionario.nome,
        email: funcionario.email,
        cargo: funcionario.cargo,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao realizar login administrativo.' });
  }
};
