-- Tabela moto com sintaxe para PostgreSQL
CREATE TABLE moto (
    id BIGSERIAL PRIMARY KEY,
    placa VARCHAR(255) NOT NULL UNIQUE,
    modelo VARCHAR(255) NOT NULL,
    ano INT NOT NULL,
    rfid_tag VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(255),
    observacoes VARCHAR(255)
);