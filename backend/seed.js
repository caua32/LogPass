require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function seed() {
  const client = await pool.connect();
  try {
    console.log('🌱 Iniciando seed...\n');

    // ─── 0. Tabela e valores de configuração ─────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS configuracao_sistema (
        chave     VARCHAR(50) PRIMARY KEY,
        valor     INT         NOT NULL,
        descricao VARCHAR(150)
      )
    `);
    await client.query(`
      INSERT INTO configuracao_sistema (chave, valor, descricao) VALUES
        ('nivel_aceitavel_horas', 24, 'Horas máximas para nível Aceitável'),
        ('nivel_ruim_horas',      48, 'Horas máximas para nível Ruim'),
        ('nivel_critico_horas',   72, 'Horas máximas para nível Crítico')
      ON CONFLICT DO NOTHING
    `);
    console.log('✅ [0/6] Tabela configuracao_sistema criada e populada');

    // ─── 1. Corrigir hash do admin ───────────────────────────────────────────
    const adminHash = await bcrypt.hash('123456', 10);
    await client.query(
      `UPDATE funcionario SET senha = $1 WHERE email = 'admin@logpass.com'`,
      [adminHash]
    );
    console.log('✅ [1/6] Hash do admin corrigido  →  admin@logpass.com / 123456');

    // ─── 2. Inserir funcionários ─────────────────────────────────────────────
    const senhaFunc = await bcrypt.hash('123456', 10);

    const funcionarios = [
      { nome: 'Ana Lima',      email: 'ana@techstore.com',     cargo: 'Analista'    },
      { nome: 'Carlos Souza',  email: 'carlos@techstore.com',  cargo: 'Gerente'     },
      { nome: 'Mariana Costa', email: 'mariana@techstore.com', cargo: 'Supervisor' },
    ];

    const funcIds = [];
    for (const f of funcionarios) {
      const res = await client.query(
        `INSERT INTO funcionario (nome, email, senha, cargo)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (email) DO NOTHING
         RETURNING id`,
        [f.nome, f.email, senhaFunc, f.cargo]
      );
      if (res.rows.length > 0) {
        funcIds.push(res.rows[0].id);
        console.log(`   + Funcionário: ${f.nome} (${f.cargo})`);
      } else {
        const existing = await client.query(
          `SELECT id FROM funcionario WHERE email = $1`, [f.email]
        );
        funcIds.push(existing.rows[0].id);
        console.log(`   ~ Funcionário já existe: ${f.email} (usando id existente)`);
      }
    }
    console.log('✅ [2/6] 3 funcionários inseridos');

    // ─── 3. Permissões dos funcionários → Tech Store (empresa_id = 1) ────────
    for (const fid of funcIds) {
      await client.query(
        `INSERT INTO permissao_funcionario (funcionario_id, empresa_id)
         VALUES ($1, 1)
         ON CONFLICT DO NOTHING`,
        [fid]
      );
    }
    console.log('✅ [3/6] Permissões vinculadas à Tech Store');

    // ─── 4. Reclamações ──────────────────────────────────────────────────────
    const reclamacoes = [
      {
        numero_pedido:  'TS-2024-001',
        motivo:         'Produto chegou com a tela completamente quebrada, sem qualquer sinal de uso por parte do consumidor. A embalagem estava íntegra, indicando dano ocorrido durante o transporte.',
        forma_solucao:  'Troca',
        status_id:      3,
        data_abertura:  '2024-11-01',
        data_resolucao: '2024-11-03',
      },
      {
        numero_pedido:  'TS-2024-002',
        motivo:         'Meu pedido foi despachado há mais de 15 dias e nunca chegou ao endereço de entrega. O código de rastreio parou de atualizar e a transportadora não dá retorno.',
        forma_solucao:  'Reembolso',
        status_id:      2,
        data_abertura:  '2024-11-10',
        data_resolucao: null,
      },
      {
        numero_pedido:  'TS-2024-003',
        motivo:         'Recebi um produto completamente diferente do que constava no pedido. Pedi um notebook e recebi uma impressora de outra marca.',
        forma_solucao:  'Troca',
        status_id:      1,
        data_abertura:  '2024-11-15',
        data_resolucao: null,
      },
      {
        numero_pedido:  'TS-2024-004',
        motivo:         'O produto parou de funcionar completamente após apenas dois dias de uso dentro das condições normais especificadas no manual.',
        forma_solucao:  'Reembolso',
        status_id:      4,
        data_abertura:  '2024-10-20',
        data_resolucao: '2024-10-25',
      },
      {
        numero_pedido:  'TS-2024-005',
        motivo:         'A embalagem chegou aberta e com o lacre de segurança claramente violado. O produto pode ter sido usado ou adulterado antes da entrega.',
        forma_solucao:  'Troca',
        status_id:      3,
        data_abertura:  '2024-10-05',
        data_resolucao: '2024-10-08',
      },
    ];

    const recIds = [];
    for (const r of reclamacoes) {
      const res = await client.query(
        `INSERT INTO reclamacao
           (empresa_id, consumidor_id, numero_pedido, motivo, forma_solucao, status_id, data_abertura, data_resolucao)
         VALUES (1, 1, $1, $2, $3, $4, $5, $6)
         ON CONFLICT DO NOTHING
         RETURNING id`,
        [r.numero_pedido, r.motivo, r.forma_solucao, r.status_id, r.data_abertura, r.data_resolucao]
      );
      if (res.rows.length > 0) {
        recIds.push(res.rows[0].id);
        console.log(`   + Reclamação: ${r.numero_pedido}`);
      } else {
        const existing = await client.query(
          `SELECT id FROM reclamacao WHERE numero_pedido = $1`, [r.numero_pedido]
        );
        recIds.push(existing.rows[0].id);
        console.log(`   ~ Reclamação já existe: ${r.numero_pedido}`);
      }
    }
    console.log('✅ [4/6] 5 reclamações inseridas');

    // ─── 5. Mensagens de chat ────────────────────────────────────────────────
    // remetente_id: consumidor usa id=1 (consumidor.id), empresa usa id=2 (usuario.id da empresa)
    const CONS = { id: 1, tipo: 'consumidor' };
    const EMP  = { id: 2, tipo: 'empresa'    };

    const chats = [
      // TS-2024-001 — Troca aprovada (5 msgs)
      { recId: recIds[0], msgs: [
        { ...CONS, texto: 'Olá, meu produto chegou com a tela completamente quebrada. Estou muito insatisfeito.' },
        { ...EMP,  texto: 'Lamentamos muito pelo ocorrido! Vamos abrir um processo de troca imediatamente.' },
        { ...CONS, texto: 'Preciso de uma solução rápida, pois utilizo o produto para trabalho.' },
        { ...EMP,  texto: 'Entendido! A troca foi aprovada. Você receberá o produto novo em até 3 dias úteis.' },
        { ...CONS, texto: 'Ótimo, muito obrigado pela agilidade na resolução!' },
      ]},
      // TS-2024-002 — Em análise (3 msgs)
      { recId: recIds[1], msgs: [
        { ...CONS, texto: 'Meu pedido foi despachado há mais de 2 semanas e ainda não chegou.' },
        { ...EMP,  texto: 'Estamos verificando a situação junto à transportadora. Retornaremos em breve.' },
        { ...CONS, texto: 'Por favor, agilizem. Caso não seja resolvido prefiro o reembolso.' },
      ]},
      // TS-2024-003 — Pendente (1 msg)
      { recId: recIds[2], msgs: [
        { ...CONS, texto: 'Recebi um produto totalmente diferente do pedido. Quero a troca com urgência!' },
      ]},
      // TS-2024-004 — Não resolvida (5 msgs)
      { recId: recIds[3], msgs: [
        { ...CONS, texto: 'Produto parou de funcionar completamente após 2 dias. Exijo reembolso.' },
        { ...EMP,  texto: 'Vamos analisar o caso. Por favor, envie fotos do produto para nosso email.' },
        { ...CONS, texto: 'Enviei as fotos conforme solicitado. Aguardo retorno.' },
        { ...EMP,  texto: 'Após análise, não identificamos defeito de fabricação. A solicitação foi negada.' },
        { ...CONS, texto: 'Inadmissível! Vou registrar reclamação nos órgãos de defesa do consumidor.' },
      ]},
      // TS-2024-005 — Troca confirmada (3 msgs)
      { recId: recIds[4], msgs: [
        { ...CONS, texto: 'A embalagem chegou aberta e com lacre violado. Produto pode estar comprometido.' },
        { ...EMP,  texto: 'Lamentamos o ocorrido. Vamos providenciar a substituição do produto imediatamente.' },
        { ...CONS, texto: 'Produto novo recebido em perfeito estado. Obrigado pela resolução rápida!' },
      ]},
    ];

    let totalMsgs = 0;
    for (const chat of chats) {
      for (const msg of chat.msgs) {
        await client.query(
          `INSERT INTO mensagem_chat (reclamacao_id, remetente_id, remetente_tipo, mensagem)
           VALUES ($1, $2, $3, $4)`,
          [chat.recId, msg.id, msg.tipo, msg.texto]
        );
        totalMsgs++;
      }
    }
    console.log(`✅ [5/6] ${totalMsgs} mensagens de chat inseridas`);

    console.log('✅ [6/6] Seed finalizado');
    console.log('\n🎉 Seed concluído com sucesso!\n');
    console.log('Credenciais disponíveis:');
    console.log('  Consumidor  →  joao@email.com          /  123456');
    console.log('  Empresa     →  techstore@email.com     /  123456');
    console.log('  Admin       →  admin@logpass.com       /  123456');
    console.log('  Analista    →  ana@techstore.com       /  123456');
    console.log('  Gerente     →  carlos@techstore.com    /  123456');
    console.log('  Supervisora →  mariana@techstore.com   /  123456');

  } catch (err) {
    console.error('❌ Erro durante o seed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
