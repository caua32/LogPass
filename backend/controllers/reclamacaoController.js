const pool = require('../db');

exports.criar = async (req, res) => {
  const { empresa_cnpj, numero_pedido, motivo, forma_solucao } = req.body;
  const usuarioId = req.user.id;

  try {
    const consumResult = await pool.query('SELECT id FROM consumidor WHERE usuario_id = $1', [usuarioId]);
    if (consumResult.rows.length === 0) {
      return res.status(400).json({ message: 'Complete seu perfil de consumidor antes de abrir uma reclamação.' });
    }

    const empresaResult = await pool.query('SELECT id FROM empresa WHERE cnpj = $1', [empresa_cnpj]);
    if (empresaResult.rows.length === 0) {
      return res.status(404).json({ message: 'Empresa não encontrada com este CNPJ.' });
    }

    const result = await pool.query(
      `INSERT INTO reclamacao (empresa_id, consumidor_id, numero_pedido, motivo, forma_solucao)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, numero_pedido, motivo, forma_solucao, status_id, data_abertura`,
      [empresaResult.rows[0].id, consumResult.rows[0].id, numero_pedido, motivo, forma_solucao || 'Não Informado']
    );

    res.status(201).json({ message: 'Reclamação aberta com sucesso!', reclamacao: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao abrir reclamação.' });
  }
};

exports.getByEmpresa = async (req, res) => {
  try {
    const empresaResult = await pool.query('SELECT id FROM empresa WHERE usuario_id = $1', [req.user.id]);
    if (empresaResult.rows.length === 0) {
      return res.status(404).json({ message: 'Perfil de empresa não encontrado.' });
    }

    const result = await pool.query(
      `SELECT r.id, r.numero_pedido, r.motivo, r.forma_solucao, r.data_abertura, r.data_resolucao,
              r.status_id,
              s.descricao AS status,
              c.nome AS consumidor_nome, c.email AS consumidor_email
       FROM reclamacao r
       JOIN status_reclamacao s ON s.id = r.status_id
       LEFT JOIN consumidor c ON c.id = r.consumidor_id
       WHERE r.empresa_id = $1
       ORDER BY r.data_abertura DESC`,
      [empresaResult.rows[0].id]
    );

    res.json({ reclamacoes: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar reclamações.' });
  }
};

exports.getByConsumidor = async (req, res) => {
  try {
    const consumResult = await pool.query('SELECT id FROM consumidor WHERE usuario_id = $1', [req.user.id]);
    if (consumResult.rows.length === 0) {
      return res.status(404).json({ message: 'Perfil de consumidor não encontrado.' });
    }

    const result = await pool.query(
      `SELECT r.id, r.numero_pedido, r.motivo, r.forma_solucao, r.data_abertura, r.data_resolucao,
              r.status_id, r.avaliacao, r.comentario,
              s.descricao AS status, e.nomeempresa
       FROM reclamacao r
       JOIN status_reclamacao s ON s.id = r.status_id
       JOIN empresa e ON e.id = r.empresa_id
       WHERE r.consumidor_id = $1
       ORDER BY r.data_abertura DESC`,
      [consumResult.rows[0].id]
    );

    res.json({ reclamacoes: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao buscar reclamações.' });
  }
};

exports.editarReclamacaoConsumidor = async (req, res) => {
  const { id } = req.params;
  const { numero_pedido, motivo, forma_solucao } = req.body;

  if (!numero_pedido || !motivo || motivo.trim().length < 10) {
    return res.status(400).json({ message: 'Dados inválidos. Motivo deve ter no mínimo 10 caracteres.' });
  }

  try {
    const check = await pool.query(
      `SELECT r.status_id FROM reclamacao r
       JOIN consumidor c ON c.id = r.consumidor_id
       WHERE r.id = $1 AND c.usuario_id = $2`,
      [id, req.user.id]
    );
    if (check.rows.length === 0)
      return res.status(404).json({ message: 'Reclamação não encontrada.' });
    if (check.rows[0].status_id !== 1)
      return res.status(403).json({ message: 'Só é possível editar reclamações com status Pendente.' });

    await pool.query(
      `UPDATE reclamacao SET numero_pedido=$1, motivo=$2, forma_solucao=$3 WHERE id=$4`,
      [numero_pedido.trim(), motivo.trim(), forma_solucao || 'Não Informado', id]
    );
    res.json({ message: 'Reclamação atualizada com sucesso.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao editar reclamação.' });
  }
};

exports.deletarReclamacaoConsumidor = async (req, res) => {
  const { id } = req.params;

  try {
    const check = await pool.query(
      `SELECT r.status_id FROM reclamacao r
       JOIN consumidor c ON c.id = r.consumidor_id
       WHERE r.id = $1 AND c.usuario_id = $2`,
      [id, req.user.id]
    );
    if (check.rows.length === 0)
      return res.status(404).json({ message: 'Reclamação não encontrada.' });
    if (check.rows[0].status_id !== 1)
      return res.status(403).json({ message: 'Só é possível excluir reclamações com status Pendente.' });

    await pool.query(`DELETE FROM reclamacao WHERE id = $1`, [id]);
    res.json({ message: 'Reclamação excluída com sucesso.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao excluir reclamação.' });
  }
};

exports.updateStatus = async (req, res) => {
  const { id } = req.params;
  const { status_id } = req.body;

  if (!status_id || ![1, 2, 3, 4].includes(Number(status_id))) {
    return res.status(400).json({ message: 'Status inválido. Use 1=Pendente, 2=Em Análise, 3=Resolvida, 4=Não Resolvida.' });
  }

  try {
    const dataResolucao = [3, 4].includes(Number(status_id)) ? new Date() : null;

    const result = await pool.query(
      `UPDATE reclamacao SET status_id = $1, data_resolucao = $2 WHERE id = $3
       RETURNING id, status_id, data_resolucao`,
      [status_id, dataResolucao, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Reclamação não encontrada.' });
    }

    res.json({ message: 'Status atualizado!', reclamacao: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao atualizar status.' });
  }
};

exports.avaliarReclamacao = async (req, res) => {
  const { id } = req.params;
  const { nota, comentario } = req.body;

  if (!nota || ![1, 2, 3, 4, 5].includes(Number(nota))) {
    return res.status(400).json({ message: 'Nota inválida. Use um valor entre 1 e 5.' });
  }
  if (!comentario || comentario.trim().length < 20) {
    return res.status(400).json({ message: 'Feedback obrigatório (mínimo 20 caracteres).' });
  }

  try {
    const check = await pool.query(
      `SELECT r.status_id FROM reclamacao r
       JOIN consumidor c ON c.id = r.consumidor_id
       WHERE r.id = $1 AND c.usuario_id = $2`,
      [id, req.user.id]
    );
    if (check.rows.length === 0)
      return res.status(404).json({ message: 'Reclamação não encontrada.' });
    if (![3, 4].includes(check.rows[0].status_id))
      return res.status(403).json({ message: 'Só é possível avaliar reclamações concluídas (Resolvida ou Não Resolvida).' });

    await pool.query(
      `UPDATE reclamacao SET avaliacao = $1, comentario = $2 WHERE id = $3`,
      [Number(nota), comentario.trim(), id]
    );
    res.json({ message: 'Avaliação registrada com sucesso.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erro ao registrar avaliação.' });
  }
};
