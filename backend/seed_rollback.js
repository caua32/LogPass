require('dotenv').config();
const { Pool } = require('pg');
const cloudinary = require('cloudinary').v2;

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Extrai o public_id de uma URL do Cloudinary
// Ex: https://res.cloudinary.com/xxx/image/upload/v123/logpass/chat/abc.jpg → logpass/chat/abc
function extrairPublicId(url) {
  try {
    const match = url.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-zA-Z0-9]+$/);
    return match ? match[1] : null;
  } catch (_) {
    return null;
  }
}

async function limparCloudinary(urls) {
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    console.log('⚠️  [0/5] Cloudinary não configurado no .env — pulando limpeza de imagens.');
    return;
  }
  if (urls.length === 0) {
    console.log('✅ [0/5] Nenhuma imagem para remover da Cloudinary.');
    return;
  }
  const publicIds = urls.map(extrairPublicId).filter(Boolean);
  let removidas = 0;
  for (const pid of publicIds) {
    try {
      const r = await cloudinary.uploader.destroy(pid, { invalidate: true });
      if (r.result === 'ok') removidas++;
      else console.log(`   ⚠️  ${pid} → ${r.result}`);
    } catch (err) {
      console.log(`   ⚠️  Falha ao remover ${pid}: ${err.message}`);
    }
  }
  console.log(`✅ [0/5] ${removidas}/${publicIds.length} imagens removidas da Cloudinary`);
}

async function rollback() {
  console.log('🔄 Iniciando rollback — mantendo apenas usuários...\n');

  const client = await pool.connect();
  try {
    // ─── 0. Imagens na Cloudinary (busca URLs antes de apagar) ────────────────
    const imgs = await client.query(
      `SELECT imagem_url FROM mensagem_chat WHERE imagem_url IS NOT NULL`
    );
    await limparCloudinary(imgs.rows.map(r => r.imagem_url));

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
