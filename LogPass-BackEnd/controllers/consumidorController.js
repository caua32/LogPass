const pool = require('../db');

exports.addConsumidor = async (req, res) => {
  const { nome, cpf, email, telefone } = req.body;
  const usuarioId = req.user.id;

  try {
    const exists = await pool.query('SELECT id FROM consumidor WHERE cpf = $1', [cpf]);
    if (exists.rows.length > 0) {
      return res.status(409).json({ message: 'CPF já cadastrado.' });
    }

    const result = await pool.query(
      'INSERT INTO consumidor (usuario_id, nome, cpf, email, telefone) VALUES ($1,$2,$3,$4,$5) RETURNING id, nome, cpf, email, telefone',
      [usuarioId, nome, cpf, email, telefone]
    );

    res.status(201).json({ message: 'Consumidor cadastrado com sucesso!', consumidor: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Email ou CPF já cadastrado.' });
    }
    console.error(err);
    res.status(500).json({ message: 'Erro ao cadastrar consumidor.' });
  }
};

exports.getPerfil = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, cpf, email, telefone FROM consumidor WHERE usuario_id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Perfil de consumidor não encontrado.' });
    }
    res.json({ consumidor: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar perfil.' });
  }
};
