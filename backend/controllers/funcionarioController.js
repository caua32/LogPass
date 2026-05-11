const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

exports.getTodasReclamacoes = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT r.id, r.numero_pedido, r.motivo, r.forma_solucao, r.data_abertura, r.data_resolucao,
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
