-- =====================================================================
-- SCRIPT DDL (Data Definition Language) para o banco de dados Mottu Location
-- Banco de Dados: PostgreSQL
-- PADRÃO: Nomes de tabelas e colunas em snake_case (minúsculas)
-- =====================================================================

-- Tabela: moto
-- Armazena as informações das motocicletas da frota.
-- =====================================================================
CREATE TABLE moto (
id BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
placa VARCHAR(255) NOT NULL UNIQUE,           -- Placa de identificação da moto (única)
modelo VARCHAR(255) NOT NULL,                 -- Modelo da moto
ano INT NOT NULL,                             -- Ano de fabricação
rfid_tag VARCHAR(255) NOT NULL UNIQUE,        -- Tag RFID para rastreamento (única)
status VARCHAR(255),                          -- Status atual (ex: DISPONIVEL, EM_MANUTENCAO)
observacoes VARCHAR(255)                      -- Observações gerais
);

-- Tabela: sensor
-- Armazena as informações dos sensores de RFID posicionados no pátio.
-- =====================================================================
CREATE TABLE sensor (
id BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
codigo VARCHAR(255) NOT NULL UNIQUE,          -- Código de identificação do sensor (único)
posicao_x INT NOT NULL,                       -- Coordenada X da posição do sensor
posicao_y INT NOT NULL,                       -- Coordenada Y da posição do sensor
descricao VARCHAR(255)                        -- Descrição da localização do sensor (ex: "Entrada Portão A")
);

-- Tabela: movimentacao
-- Registra cada vez que um sensor detecta uma moto, criando um histórico.
-- =====================================================================
CREATE TABLE movimentacao (
id BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
moto_id BIGINT NOT NULL,                      -- Chave estrangeira para a tabela moto
sensor_id BIGINT NOT NULL,                    -- Chave estrangeira para a tabela sensor
data_hora TIMESTAMP,                          -- Data e hora exatas da detecção
CONSTRAINT fk_movimentacao_moto FOREIGN KEY (moto_id) REFERENCES moto(id),
CONSTRAINT fk_movimentacao_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(id)
);

-- Tabela: users
-- Armazena os usuários do sistema para autenticação e autorização.
-- =====================================================================
CREATE TABLE users (
id BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
username VARCHAR(255) NOT NULL UNIQUE,        -- Nome de usuário para login (único)
password VARCHAR(255) NOT NULL,               -- Senha criptografada
role VARCHAR(255) NOT NULL                    -- Perfil de acesso (ex: ROLE_ADMIN, ROLE_USER)
);

-- =====================================================================
-- DML (Data Manipulation Language) - Dados Iniciais
-- =====================================================================

-- Inserindo uma moto de teste inicial
INSERT INTO moto (placa, modelo, ano, rfid_tag, status, observacoes)
VALUES ('TST-0001', 'Honda CG Titan', 2024, 'RFID-TESTE-001', 'DISPONIVEL', 'Moto de teste');