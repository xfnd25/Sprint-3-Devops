-- =====================================================================
-- SCRIPT DDL (Data Definition Language) para o banco de dados Mottu Location
-- Banco de Dados: PostgreSQL
-- =====================================================================

-- Tabela: MOTO
-- Armazena as informações das motocicletas da frota.
-- =====================================================================
CREATE TABLE MOTO (
    ID BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
    PLACA VARCHAR(255) NOT NULL UNIQUE,           -- Placa de identificação da moto (única)
    MODELO VARCHAR(255) NOT NULL,                 -- Modelo da moto
    ANO INT NOT NULL,                             -- Ano de fabricação
    RFID_TAG VARCHAR(255) NOT NULL UNIQUE,        -- Tag RFID para rastreamento (única)
    STATUS VARCHAR(255),                          -- Status atual (ex: DISPONIVEL, EM_MANUTENCAO)
    OBSERVACOES VARCHAR(255)                      -- Observações gerais
);

-- Tabela: SENSOR
-- Armazena as informações dos sensores de RFID posicionados no pátio.
-- =====================================================================
CREATE TABLE SENSOR (
    ID BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
    CODIGO VARCHAR(255) NOT NULL UNIQUE,          -- Código de identificação do sensor (único)
    posicao_x INT NOT NULL,                       -- Coordenada X da posição do sensor
    posicao_y INT NOT NULL,                       -- Coordenada Y da posição do sensor
    DESCRICAO VARCHAR(255)                        -- Descrição da localização do sensor (ex: "Entrada Portão A")
);

-- Tabela: MOVIMENTACAO
-- Registra cada vez que um sensor detecta uma moto, criando um histórico.
-- =====================================================================
CREATE TABLE MOVIMENTACAO (
    ID BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
    MOTO_ID BIGINT NOT NULL,                      -- Chave estrangeira para a tabela MOTO
    SENSOR_ID BIGINT NOT NULL,                    -- Chave estrangeira para a tabela SENSOR
    DATA_HORA TIMESTAMP,                          -- Data e hora exatas da detecção
    CONSTRAINT FK_MOVIMENTACAO_MOTO FOREIGN KEY (MOTO_ID) REFERENCES MOTO(ID),
    CONSTRAINT FK_MOVIMENTACAO_SENSOR FOREIGN KEY (SENSOR_ID) REFERENCES SENSOR(ID)
);

-- Tabela: USERS
-- Armazena os usuários do sistema para autenticação e autorização.
-- =====================================================================
CREATE TABLE USERS (
    ID BIGSERIAL PRIMARY KEY,                     -- ID único autoincremental
    USERNAME VARCHAR(255) NOT NULL UNIQUE,        -- Nome de usuário para login (único)
    PASSWORD VARCHAR(255) NOT NULL,               -- Senha criptografada
    ROLE VARCHAR(255) NOT NULL                    -- Perfil de acesso (ex: ROLE_ADMIN, ROLE_USER)
);

-- =====================================================================
-- DML (Data Manipulation Language) - Dados Iniciais
-- =====================================================================

-- Inserindo uma moto de teste inicial
INSERT INTO MOTO(PLACA, MODELO, ANO, RFID_TAG, STATUS, OBSERVACOES)
VALUES ('TST-0001', 'Honda CG Titan', 2024, 'RFID-TESTE-001', 'DISPONIVEL', 'Moto de teste');