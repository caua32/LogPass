const pool = require('../db');

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

exports.addEmpresa = async (req, res) => {
  const { nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep } = req.body;
  const usuarioId = req.user.id;

  try {
    const cnpjExists = await pool.query('SELECT id FROM empresa WHERE cnpj = $1', [cnpj]);
    if (cnpjExists.rows.length > 0) {
      return res.status(409).json({ message: 'CNPJ já cadastrado.' });
    }

    const result = await pool.query(
      `INSERT INTO empresa (usuario_id, nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING id, nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep`,
      [usuarioId, nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep]
    );

    res.status(201).json({ message: 'Empresa cadastrada com sucesso!', empresa: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'CNPJ já cadastrado.' });
    }
    console.error(err);
    res.status(500).json({ message: 'Erro ao cadastrar empresa.' });
  }
};

exports.getPerfil = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep FROM empresa WHERE usuario_id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Perfil de empresa não encontrado.' });
    }
    res.json({ empresa: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar perfil da empresa.' });
  }
};

exports.updatePerfil = async (req, res) => {
  const { nomeempresa, contato, logradouro, numero, bairro, cidade, cep } = req.body;

  try {
    const result = await pool.query(
      `UPDATE empresa
       SET nomeempresa = COALESCE($1, nomeempresa),
           contato = COALESCE($2, contato),
           logradouro = COALESCE($3, logradouro),
           numero = COALESCE($4, numero),
           bairro = COALESCE($5, bairro),
           cidade = COALESCE($6, cidade),
           cep = COALESCE($7, cep)
       WHERE usuario_id = $8
       RETURNING id, nomeempresa, cnpj, contato, logradouro, numero, bairro, cidade, cep`,
      [nomeempresa, contato, logradouro, numero, bairro, cidade, cep, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Empresa não encontrada.' });
    }

    res.json({ message: 'Perfil atualizado com sucesso!', empresa: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao atualizar perfil.' });
  }
};
