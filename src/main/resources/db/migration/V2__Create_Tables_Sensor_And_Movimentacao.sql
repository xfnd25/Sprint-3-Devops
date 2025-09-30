-- Tabelas sensor e movimentacao com sintaxe para PostgreSQL
CREATE TABLE sensor (
    id BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(255) NOT NULL UNIQUE,
    posicao_x INT NOT NULL,
    posicao_y INT NOT NULL,
    descricao VARCHAR(255)
);

CREATE TABLE movimentacao (
    id BIGSERIAL PRIMARY KEY,
    moto_id BIGINT NOT NULL,
    sensor_id BIGINT NOT NULL,
    data_hora TIMESTAMP,
    CONSTRAINT fk_movimentacao_moto FOREIGN KEY (moto_id) REFERENCES moto(id),
    CONSTRAINT fk_movimentacao_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(id)
);