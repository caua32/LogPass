require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function rollback() {
  const client = await pool.connect();
  try {
    console.log('🔄 Iniciando rollback — mantendo apenas usuários...\n');

    // ─── 1. Mensagens de chat ─────────────────────────────────────────────────
    const delMsg = await client.query(`DELETE FROM mensagem_chat`);
    console.log(`✅ [1/4] ${delMsg.rowCount} mensagens de chat removidas`);

    // ─── 2. Reclamações ───────────────────────────────────────────────────────
    const delRec = await client.query(`DELETE FROM reclamacao`);
    console.log(`✅ [2/4] ${delRec.rowCount} reclamações removidas`);

    // ─── 3. Funcionários + permissões (preserva o admin) ─────────────────────
    const delPerm = await client.query(
      `DELETE FROM permissao_funcionario
       WHERE funcionario_id IN (
         SELECT id FROM funcionario WHERE email != 'admin@logpass.com'
       )`
    );
    const delFunc = await client.query(
      `DELETE FROM funcionario WHERE email != 'admin@logpass.com'`
    );
    console.log(`✅ [3/4] ${delFunc.rowCount} funcionários e ${delPerm.rowCount} permissões removidos (admin preservado)`);

    // ─── 4. Configurações do sistema ──────────────────────────────────────────
    const delCfg = await client.query(`DELETE FROM configuracao_sistema`);
    console.log(`✅ [4/4] ${delCfg.rowCount} configurações removidas`);

    console.log('\n🎉 Rollback concluído!');
    console.log('   Mantidos: usuario, consumidor, empresa (todos os cadastros).');
    console.log('   Removidos: reclamações, mensagens, funcionários, configurações.\n');

  } catch (err) {
    console.error('❌ Erro durante o rollback:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

rollback();
