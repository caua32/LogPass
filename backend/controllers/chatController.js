const pool = require('../db');

async function _verificarAcesso(reclamacaoId, usuarioId, tipo) {
  if (tipo === 'consumidor') {
    const r = await pool.query(
      `SELECT r.id FROM reclamacao r
       JOIN consumidor c ON c.id = r.consumidor_id
       WHERE r.id = $1 AND c.usuario_id = $2`,
      [reclamacaoId, usuarioId]
    );
    return r.rows.length > 0;
  }
  if (tipo === 'empresa') {
    const r = await pool.query(
      `SELECT r.id FROM reclamacao r
       JOIN empresa e ON e.id = r.empresa_id
       WHERE r.id = $1 AND e.usuario_id = $2`,
      [reclamacaoId, usuarioId]
    );
    return r.rows.length > 0;
  }
  return false;
}

exports.getMensagens = async (req, res) => {
  const { reclamacao_id } = req.params;
  const usuarioId = req.user.id;
  const tipo = req.user.tipo;

  try {
    const ok = await _verificarAcesso(reclamacao_id, usuarioId, tipo);
    if (!ok) return res.status(403).json({ message: 'Acesso negado a esta reclamação.' });

    const result = await pool.query(
      `SELECT m.id, m.remetente_id, m.remetente_tipo, m.mensagem, m.created_at,
              CASE
                WHEN m.remetente_tipo = 'consumidor' THEN c.nome
                WHEN m.remetente_tipo = 'empresa' THEN e.nomeempresa
                ELSE 'Admin'
              END AS remetente_nome
       FROM mensagem_chat m
       LEFT JOIN consumidor c ON c.id = m.remetente_id AND m.remetente_tipo = 'consumidor'
       LEFT JOIN empresa e ON e.id = m.remetente_id AND m.remetente_tipo = 'empresa'
       WHERE m.reclamacao_id = $1
       ORDER BY m.created_at ASC`,
      [reclamacao_id]
    );

    res.json({ mensagens: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar mensagens.' });
  }
};

exports.enviarMensagem = async (req, res) => {
  const { reclamacao_id } = req.params;
  const { mensagem } = req.body;
  const usuarioId = req.user.id;
  const tipo = req.user.tipo;

  if (!mensagem || !mensagem.trim()) {
    return res.status(400).json({ message: 'Mensagem não pode estar vazia.' });
  }
  if (mensagem.trim().length > 1000) {
    return res.status(400).json({ message: 'Mensagem muito longa (máx. 1000 caracteres).' });
  }

  try {
    const ok = await _verificarAcesso(reclamacao_id, usuarioId, tipo);
    if (!ok) return res.status(403).json({ message: 'Acesso negado a esta reclamação.' });

    let remetenteId;
    if (tipo === 'consumidor') {
      const r = await pool.query('SELECT id FROM consumidor WHERE usuario_id = $1', [usuarioId]);
      if (r.rows.length === 0) return res.status(400).json({ message: 'Perfil de consumidor não encontrado.' });
      remetenteId = r.rows[0].id;
    } else {
      const r = await pool.query('SELECT id FROM empresa WHERE usuario_id = $1', [usuarioId]);
      if (r.rows.length === 0) return res.status(400).json({ message: 'Perfil de empresa não encontrado.' });
      remetenteId = r.rows[0].id;
    }

    const result = await pool.query(
      `INSERT INTO mensagem_chat (reclamacao_id, remetente_id, remetente_tipo, mensagem)
       VALUES ($1, $2, $3, $4)
       RETURNING id, remetente_id, remetente_tipo, mensagem, created_at`,
      [reclamacao_id, remetenteId, tipo, mensagem.trim()]
    );

    res.status(201).json({ mensagem: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao enviar mensagem.' });
  }
};
