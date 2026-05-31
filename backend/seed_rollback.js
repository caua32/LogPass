require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const SEED_PEDIDOS = [
  'TS-2024-001',
  'TS-2024-002',
  'TS-2024-003',
  'TS-2024-004',
  'TS-2024-005',
];

const SEED_FUNCIONARIOS = [
  'ana@techstore.com',
  'carlos@techstore.com',
  'mariana@techstore.com',
];

async function rollback() {
  const client = await pool.connect();
  try {
    console.log('🔄 Iniciando rollback do seed...\n');

    // ─── 1. Reclamações + mensagens (cascade automático) ────────────────────
    const delRec = await client.query(
      `DELETE FROM reclamacao
       WHERE numero_pedido = ANY($1::text[])`,
      [SEED_PEDIDOS]
    );
    console.log(`✅ [1/4] ${delRec.rowCount} reclamações removidas (mensagens apagadas em cascade)`);

    // ─── 2. Permissões dos funcionários seed ─────────────────────────────────
    const delPerm = await client.query(
      `DELETE FROM permissao_funcionario
       WHERE funcionario_id IN (
         SELECT id FROM funcionario WHERE email = ANY($1::text[])
       )`,
      [SEED_FUNCIONARIOS]
    );
    console.log(`✅ [2/4] ${delPerm.rowCount} permissões removidas`);

    // ─── 3. Funcionários seed ────────────────────────────────────────────────
    const delFunc = await client.query(
      `DELETE FROM funcionario
       WHERE email = ANY($1::text[])`,
      [SEED_FUNCIONARIOS]
    );
    console.log(`✅ [3/4] ${delFunc.rowCount} funcionários removidos`);

    // ─── 4. Configurações do sistema ─────────────────────────────────────────
    const delCfg = await client.query(`DELETE FROM configuracao_sistema`);
    console.log(`✅ [4/4] ${delCfg.rowCount} configurações removidas`);

    console.log('\n🎉 Rollback concluído! Banco voltou ao estado pré-seed.');
    console.log('   Personas base intactas: João Silva, Tech Store, Administrador.');
    console.log('   Obs: hash do admin foi mantido corrigido (123456).\n');

  } catch (err) {
    console.error('❌ Erro durante o rollback:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

rollback();
