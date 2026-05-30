-- LogPass - Schema PostgreSQL
-- Execute: psql -U postgres -d logpass -f schema_postgresql.sql

-- ============================================================
-- TABELAS
-- ============================================================

-- Autenticação (empresa e consumidor)
CREATE TABLE usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('empresa', 'consumidor')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Perfil do consumidor
CREATE TABLE consumidor (
    id SERIAL PRIMARY KEY,
    usuario_id INT UNIQUE REFERENCES usuario(id) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20)
);

-- Perfil da empresa
CREATE TABLE empresa (
    id SERIAL PRIMARY KEY,
    usuario_id INT UNIQUE REFERENCES usuario(id) ON DELETE CASCADE,
    nomeempresa VARCHAR(100) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    contato VARCHAR(50),
    logradouro VARCHAR(150),
    numero VARCHAR(10),
    bairro VARCHAR(80),
    cidade VARCHAR(80),
    cep VARCHAR(10)
);

-- Funcionários (painel administrativo)
CREATE TABLE funcionario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    cargo VARCHAR(20) NOT NULL CHECK (cargo IN ('Analista', 'Gerente', 'Supervisor', 'admin')),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Status de reclamação
CREATE TABLE status_reclamacao (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(50) NOT NULL
);

-- Reclamações
CREATE TABLE reclamacao (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    consumidor_id INT REFERENCES consumidor(id) ON DELETE SET NULL,
    numero_pedido VARCHAR(50) NOT NULL,
    motivo TEXT NOT NULL,
    forma_solucao VARCHAR(20) DEFAULT 'Não Informado',
    status_id INT NOT NULL DEFAULT 1 REFERENCES status_reclamacao(id),
    data_abertura TIMESTAMP DEFAULT NOW(),
    data_resolucao TIMESTAMP,
    CONSTRAINT data_resolucao_valida CHECK (data_resolucao IS NULL OR data_resolucao >= data_abertura)
);

-- Permissões de funcionário por empresa
CREATE TABLE permissao_funcionario (
    id SERIAL PRIMARY KEY,
    funcionario_id INT NOT NULL REFERENCES funcionario(id) ON DELETE CASCADE,
    empresa_id INT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    UNIQUE (funcionario_id, empresa_id)
);

-- Mensagens de chat por reclamação
CREATE TABLE mensagem_chat (
    id SERIAL PRIMARY KEY,
    reclamacao_id INT NOT NULL REFERENCES reclamacao(id) ON DELETE CASCADE,
    remetente_id INT NOT NULL,
    remetente_tipo VARCHAR(20) NOT NULL CHECK (remetente_tipo IN ('consumidor', 'empresa', 'admin')),
    mensagem TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES
-- ============================================================

CREATE INDEX idx_usuario_email      ON usuario(email);
CREATE INDEX idx_consumidor_cpf     ON consumidor(cpf);
CREATE INDEX idx_empresa_cnpj       ON empresa(cnpj);
CREATE INDEX idx_reclamacao_empresa ON reclamacao(empresa_id);
CREATE INDEX idx_reclamacao_status  ON reclamacao(status_id);
CREATE INDEX idx_reclamacao_data    ON reclamacao(data_abertura);
CREATE INDEX idx_chat_reclamacao    ON mensagem_chat(reclamacao_id);
CREATE INDEX idx_chat_created       ON mensagem_chat(created_at);

-- ============================================================
-- DADOS INICIAIS
-- ============================================================

INSERT INTO status_reclamacao (descricao) VALUES
    ('Pendente'),
    ('Em Análise'),
    ('Resolvida'),
    ('Não Resolvida');

-- Admin padrão (senha: logpass2024)
-- Gere o hash antes de usar em produção: bcrypt.hash('logpass2024', 10)
INSERT INTO funcionario (nome, email, senha, cargo) VALUES
    ('Administrador', 'admin@logpass.com', '$2a$10$placeholder_hash_aqui', 'admin');
