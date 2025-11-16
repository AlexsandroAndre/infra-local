CREATE TYPE tipo_ativo AS ENUM (
    'acao',
    'fii',
    'etf',
    'bdr',
    'cripto',
    'rf_publica',
    'rf_privada'
);

CREATE TABLE IF NOT EXISTS ativo (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) UNIQUE NOT NULL,
    tipo tipo_ativo NOT NULL,
    setor VARCHAR(100),
    data_cadastro TIMESTAMP DEFAULT NOW()
);