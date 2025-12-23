-- ============================================
-- Script de migração: Impiricus - MVP Ativos Internacionais
-- Versão: 2.0
-- Data: 2025-12-09
-- ============================================

-- ============================================
-- 1. DROP das tabelas antigas (ordem correta - filhas antes das pais)
-- ============================================

DROP TABLE IF EXISTS preco_historico_ativo CASCADE;
DROP TABLE IF EXISTS carteira_recomendada_ativo CASCADE;
DROP TABLE IF EXISTS ativos CASCADE;
DROP TABLE IF EXISTS carteira_recomendada CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

-- Drop tabelas legadas
DROP TABLE IF EXISTS tipo_ativo CASCADE;

-- ============================================
-- 2. DROP dos TYPEs antigos (para recriar limpo)
-- ============================================

DROP TYPE IF EXISTS symbol_enum CASCADE;
DROP TYPE IF EXISTS tipo_usuario_enum CASCADE;
DROP TYPE IF EXISTS perfil_risco_enum CASCADE;
DROP TYPE IF EXISTS horizonte_enum CASCADE;
DROP TYPE IF EXISTS tipo_ativo_enum CASCADE;
DROP TYPE IF EXISTS exchange_enum CASCADE;
DROP TYPE IF EXISTS moeda_enum CASCADE;
DROP TYPE IF EXISTS pais_enum CASCADE;
DROP TYPE IF EXISTS setor_enum CASCADE;
DROP TYPE IF EXISTS industria_enum CASCADE;
DROP TYPE IF EXISTS fonte_dados_enum CASCADE;

-- ============================================
-- 3. CREATE TABLES
-- ============================================

-- Tabela USUARIO
CREATE TABLE usuario (
    id                  BIGSERIAL PRIMARY KEY,
    nome                VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL UNIQUE,
    senha_hash          VARCHAR(255) NOT NULL,
    tipo_usuario        VARCHAR(30) NOT NULL DEFAULT 'CLIENTE',
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT email_valido CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Tabela CARTEIRA_RECOMENDADA
CREATE TABLE carteira_recomendada (
    id                  BIGSERIAL PRIMARY KEY,
    nome                VARCHAR(255) NOT NULL,
    descricao           TEXT,
    perfil_risco        VARCHAR(30) NOT NULL,
    horizonte           VARCHAR(30) NOT NULL,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT nome_unico UNIQUE(nome)
);

CREATE TABLE ativos (
    id              BIGSERIAL PRIMARY KEY,

    symbol          VARCHAR(20) NOT NULL,
    name            VARCHAR(255) NOT NULL,

    type            VARCHAR(30) NOT NULL,           -- Enum AssetType
    exchange        VARCHAR(30) NOT NULL,           -- Enum Exchange
    currency        VARCHAR(20),                    -- Enum Currency
    country         VARCHAR(50),                    -- Enum Country
    sector          VARCHAR(50),                    -- Enum Sector
    industry        VARCHAR(50),                    -- Enum Industry

    isin_code       VARCHAR(12),
    cusip_code      VARCHAR(9),

    data_source     VARCHAR(30) NOT NULL,           -- Enum DataSource

    active          BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_symbol_exchange UNIQUE (symbol, exchange),
    CONSTRAINT valid_isin CHECK (isin_code IS NULL OR LENGTH(isin_code) = 12),
    CONSTRAINT valid_cusip CHECK (cusip_code IS NULL OR LENGTH(cusip_code) = 9)
);


-- Tabela CARTEIRA_RECOMENDADA_ATIVO (relação N:N)
CREATE TABLE carteira_recomendada_ativo (
    id                          BIGSERIAL PRIMARY KEY,
    id_carteira_recomendada     BIGINT NOT NULL,
    id_ativo                    BIGINT NOT NULL,
    peso_alvo                   NUMERIC(5,2) NOT NULL,
    ordem_exibicao              INTEGER,
    criado_em                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_carteira FOREIGN KEY (id_carteira_recomendada)
        REFERENCES carteira_recomendada(id) ON DELETE CASCADE,
    CONSTRAINT fk_ativo FOREIGN KEY (id_ativo)
        REFERENCES ativo(id) ON DELETE CASCADE,
    CONSTRAINT carteira_ativo_unico UNIQUE(id_carteira_recomendada, id_ativo),
    CONSTRAINT peso_valido CHECK (peso_alvo >= 0 AND peso_alvo <= 100)
);

-- Tabela PRECO_HISTORICO_ATIVO (com particionamento por data)
CREATE TABLE preco_historico_ativo (
    id                  BIGSERIAL,
    id_ativo            BIGINT NOT NULL,
    data                DATE NOT NULL,
    preco_abertura      NUMERIC(18,6),
    preco_maximo        NUMERIC(18,6),
    preco_minimo        NUMERIC(18,6),
    preco_fechamento    NUMERIC(18,6) NOT NULL,
    preco_ajustado      NUMERIC(18,6),
    volume              BIGINT,
    fonte_dados         VARCHAR(30) NOT NULL,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ativo_preco FOREIGN KEY (id_ativo)
        REFERENCES ativo(id) ON DELETE CASCADE,
    CONSTRAINT ativo_data_unico UNIQUE(id_ativo, data),
    CONSTRAINT preco_positivo CHECK (preco_fechamento > 0),
    CONSTRAINT volume_positivo CHECK (volume IS NULL OR volume >= 0),
    PRIMARY KEY (id, data)
) PARTITION BY RANGE (data);

-- Criar partições para os próximos 2 anos (exemplo)
CREATE TABLE preco_historico_ativo_2024 PARTITION OF preco_historico_ativo
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE preco_historico_ativo_2025 PARTITION OF preco_historico_ativo
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE preco_historico_ativo_2026 PARTITION OF preco_historico_ativo
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- ============================================
-- 4. CREATE INDEXES (para performance)
-- ============================================

-- Índices para USUARIO
CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_usuario_tipo ON usuario(tipo_usuario);
CREATE INDEX idx_usuario_ativo ON usuario(ativo) WHERE ativo = TRUE;

-- Índices para ATIVO
CREATE INDEX idx_ativo_symbol ON ativo(symbol);
CREATE INDEX idx_ativo_tipo ON ativo(tipo_ativo);
CREATE INDEX idx_ativo_exchange ON ativo(exchange);
CREATE INDEX idx_ativo_pais ON ativo(pais);
CREATE INDEX idx_ativo_setor ON ativo(setor);
CREATE INDEX idx_ativo_ativo ON ativo(ativo) WHERE ativo = TRUE;
CREATE INDEX idx_ativo_symbol_exchange ON ativo(symbol, exchange);

-- Índices para PRECO_HISTORICO_ATIVO
CREATE INDEX idx_preco_historico_ativo ON preco_historico_ativo(id_ativo);
CREATE INDEX idx_preco_historico_data ON preco_historico_ativo(data DESC);
CREATE INDEX idx_preco_historico_ativo_data ON preco_historico_ativo(id_ativo, data DESC);

-- Índices para CARTEIRA_RECOMENDADA_ATIVO
CREATE INDEX idx_carteira_ativo_carteira ON carteira_recomendada_ativo(id_carteira_recomendada);
CREATE INDEX idx_carteira_ativo_ativo ON carteira_recomendada_ativo(id_ativo);

-- Índices para CARTEIRA_RECOMENDADA
CREATE INDEX idx_carteira_perfil ON carteira_recomendada(perfil_risco);
CREATE INDEX idx_carteira_horizonte ON carteira_recomendada(horizonte);
CREATE INDEX idx_carteira_ativo ON carteira_recomendada(ativo) WHERE ativo = TRUE;

-- ============================================
-- 5. CREATE TRIGGERS (para atualizar automaticamente atualizado_em)
-- ============================================

-- Função genérica para atualizar timestamp
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para cada tabela
CREATE TRIGGER trigger_atualizar_usuario
    BEFORE UPDATE ON usuario
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_carteira
    BEFORE UPDATE ON carteira_recomendada
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_ativo
    BEFORE UPDATE ON ativo
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

CREATE TRIGGER trigger_atualizar_carteira_ativo
    BEFORE UPDATE ON carteira_recomendada_ativo
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_timestamp();

-- ============================================
-- 6. COMENTÁRIOS (documentação inline)
-- ============================================

COMMENT ON TABLE usuario IS 'Usuários da plataforma (clientes, admins, consultores)';
COMMENT ON TABLE carteira_recomendada IS 'Carteiras modelo recomendadas pela plataforma';
COMMENT ON TABLE ativo IS 'Ativos financeiros (stocks, ETFs, REITs, etc.)';
COMMENT ON TABLE carteira_recomendada_ativo IS 'Composição das carteiras recomendadas (ativos + peso alvo)';
COMMENT ON TABLE preco_historico_ativo IS 'Histórico de preços diários dos ativos (particionado por data)';

COMMENT ON COLUMN ativo.symbol IS 'Ticker do ativo (ex: AAPL, VNQ, BMW.DE, PETR4.SA)';
COMMENT ON COLUMN ativo.codigo_isin IS 'Código ISIN (International Securities Identification Number) - 12 caracteres';
COMMENT ON COLUMN ativo.codigo_cusip IS 'Código CUSIP (Committee on Uniform Securities Identification Procedures) - 9 caracteres';
COMMENT ON COLUMN ativo.fonte_dados IS 'Provedor de dados de onde o ativo foi importado';
COMMENT ON COLUMN carteira_recomendada_ativo.peso_alvo IS 'Percentual alvo do ativo na carteira (0-100)';
COMMENT ON COLUMN preco_historico_ativo.preco_ajustado IS 'Preço ajustado por splits e dividendos';

-- ============================================
-- 7. DADOS INICIAIS (OPCIONAL - para testes)
-- ============================================

-- Inserir usuário admin padrão (senha: admin123 - TROCAR EM PRODUÇÃO!)
INSERT INTO usuario (nome, email, senha_hash, tipo_usuario) VALUES
('Administrador', 'contatoalexsandroandre@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'SUPER_ADMIN');

-- ============================================
-- FIM DO SCRIPT
-- ============================================