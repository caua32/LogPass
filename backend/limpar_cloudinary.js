// Remove TODAS as imagens da pasta logpass/chat na Cloudinary.
// Útil para limpar imagens órfãs (sem registro no banco).
// Uso: node limpar_cloudinary.js

require('dotenv').config();
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function limpar() {
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    console.error('❌ Cloudinary não configurado no .env');
    process.exit(1);
  }

  console.log('🔄 Buscando imagens em logpass/chat...\n');

  let totalRemovidas = 0;
  let nextCursor = undefined;

  try {
    do {
      // Lista recursos da pasta (até 500 por página)
      const res = await cloudinary.api.resources({
        type: 'upload',
        prefix: 'logpass/chat/',
        max_results: 500,
        next_cursor: nextCursor,
      });

      const ids = res.resources.map(r => r.public_id);

      if (ids.length > 0) {
        const del = await cloudinary.api.delete_resources(ids, { invalidate: true });
        const removidasAgora = Object.values(del.deleted)
          .filter(s => s === 'deleted').length;
        totalRemovidas += removidasAgora;
        console.log(`   Removidas ${removidasAgora} imagens neste lote...`);
      }

      nextCursor = res.next_cursor;
    } while (nextCursor);

    // Remove a pasta vazia
    try {
      await cloudinary.api.delete_folder('logpass/chat');
      console.log('   Pasta logpass/chat removida.');
    } catch (_) { /* pasta pode não existir ou ainda ter subpastas */ }

    console.log(`\n🎉 Concluído! ${totalRemovidas} imagens removidas da Cloudinary.`);
  } catch (err) {
    console.error('❌ Erro:', err.message);
    process.exit(1);
  }
}

limpar();
