require('dotenv').config();
const { Pool } = require('pg');
const cloudinary = require('cloudinary').v2;

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function limparCloudinary() {
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    console.log('⚠️  [0/5] Cloudinary não configurado no .env — pulando limpeza de imagens.');
    return;
  }
  try {
    // Apaga todas as imagens da pasta logpass/chat
    await cloudinary.api.delete_resources_by_prefix('logpass/chat/');
    // Remove a pasta vazia (ignora erro se não existir)
    try { await cloudinary.api.delete_folder('logpass/chat'); } catch (_) {}
    console.log('✅ [0/5] Imagens do chat removidas da Cloudinary');
  } catch (err) {
    console.log(`⚠️  [0/5] Falha ao limpar Cloudinary: ${err.message}`);
  }
}

async function rollback() {
  console.log('🔄 Iniciando rollback — mantendo apenas usuários...\n');

  // ─── 0. Imagens na Cloudinary (antes de apagar as URLs do banco) ──────────
  await limparCloudinary();

  const client = await pool.connect();
  try {
    // ─── 1. Mensagens de chat ─────────────────────────────────────────────────
    const delMsg = await client.query(`DELETE FROM mensagem_chat`);
    console.log(`✅ [1/5] ${delMsg.rowCount} mensagens de chat removidas`);

    // ─── 2. Reclamações ───────────────────────────────────────────────────────
    const delRec = await client.query(`DELETE FROM reclamacao`);
    console.log(`✅ [2/5] ${delRec.rowCount} reclamações removidas`);

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
    console.log(`✅ [4/5] ${delFunc.rowCount} funcionários e ${delPerm.rowCount} permissões removidos (admin preservado)`);

    // ─── 5. Configurações do sistema ──────────────────────────────────────────
    const delCfg = await client.query(`DELETE FROM configuracao_sistema`);
    console.log(`✅ [5/5] ${delCfg.rowCount} configurações removidas`);

    console.log('\n🎉 Rollback concluído!');
    console.log('   Mantidos: usuario, consumidor, empresa (todos os cadastros).');
    console.log('   Removidos: reclamações, mensagens, imagens, funcionários, configurações.\n');

  } catch (err) {
    console.error('❌ Erro durante o rollback:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

rollback();
