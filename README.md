# Aplicação Web - Mottu Location

## Integrantes
* **RM555317** - Fernando Fontes
* **RM556814** - Guilherme Jardim

---

## 🚀 Sobre o Projeto

Esta é uma **Aplicação Web completa** desenvolvida com **Java e Spring Boot** para o gerenciamento da frota de motos da Mottu. O sistema permite o controle de motos e sensores, além de registrar e visualizar as movimentações, tudo através de uma interface web segura e intuitiva.

O projeto foi desenvolvido para a disciplina "Advanced Java Development" e cumpre todos os requisitos técnicos solicitados, incluindo:
* **Thymeleaf:** Para a camada de visualização (frontend).
* **Flyway:** Para o controle de versionamento do banco de dados PostgreSQL.
* **Spring Security:** Para autenticação via formulário e controle de acesso baseado em perfis.

---

## 🏛️ Arquitetura

O projeto utiliza uma **Arquitetura em Camadas (Layered Architecture)** para garantir uma clara separação de responsabilidades:

* **`Controller`:** Camada responsável por receber as requisições HTTP da interface web (`@Controller`) e da API REST (`@RestController`).
* **`Service`:** Camada que contém a lógica de negócio principal e orquestra as operações.
* **`Repository`:** Camada de acesso a dados, utilizando Spring Data JPA para interagir com o banco.
* **`Entity`:** Camada que representa as tabelas do banco de dados.

---

## 🛠️ Tecnologias e Funcionalidades Implementadas

* **Backend:** Java 17, Spring Boot, Spring Security
* **Frontend:** Thymeleaf, HTML5, CSS3
* **Banco de Dados:** PostgreSQL (rodando em Docker) com gerenciamento de schema via **Flyway**
* **Autenticação:** Sistema de login e logout com perfis de usuário (`ADMIN`, `USER`).
* **Interface Web:** CRUD completo para Motos e Sensores, registro e visualização de movimentações.
* **Lógica de Negócio:** Geração automática de RFID na criação de motos.
* **Qualidade:** Validações de dados nos formulários e DTOs.

---

## 🏁 Como Executar o Projeto

### Pré-requisitos
* **JDK 17** ou superior
* **Maven 3.8** ou superior
* **Docker Desktop** (precisa estar rodando)

### Passo a Passo para Execução
1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/xfnd25/motolocation.git](https://github.com/xfnd25/motolocation.git)
    cd motolocation
    ```
2.  **Inicie o Banco de Dados com Docker:**
    Abra um terminal na pasta raiz do projeto e execute o comando abaixo para iniciar o container do PostgreSQL.
    ```bash
    docker-compose up -d
    ```
    Aguarde um minuto para o banco de dados iniciar completamente na primeira vez.

3.  **Execute a Aplicação Spring Boot:**
    Você pode executar diretamente pela sua IDE (rodando a classe `MotolocationApplication.java`) ou pelo terminal com o seguinte comando Maven:
    ```bash
    ./mvnw spring-boot:run
    ```

### Acesso e Credenciais
* Acesse a aplicação no seu navegador: **[http://localhost:8080](http://localhost:8080)**
* Você será redirecionado para a tela de login. Use as seguintes credenciais:
    * **Administrador:**
        * Usuário: `admin`
        * Senha: `admin`
    * **Usuário Comum:**
        * Usuário: `user`
        * Senha: `user`

---

## 💻 Funcionalidades da Aplicação Web

A aplicação possui dois níveis de acesso:

### Perfil: Administrador (`ROLE_ADMIN`)
O administrador tem acesso total ao sistema:
* **Gerenciar Motos:** Listar, cadastrar, editar e excluir motos. O RFID é gerado automaticamente no cadastro.
* **Gerenciar Sensores:** Listar, cadastrar, editar e excluir sensores.
* **Registrar Movimentação:** Simular a detecção de uma moto por um sensor através de um formulário.
* **Ver Histórico:** Visualizar o histórico completo de movimentações para cada moto.

### Perfil: Usuário Comum (`ROLE_USER`)
O usuário comum tem permissões limitadas de visualização:
* **Visualizar Motos e Sensores:** Pode ver as listas, mas os botões de "Adicionar", "Editar" e "Deletar" não são exibidos.
* **Ver Histórico:** Pode visualizar o histórico de movimentações das motos.

---

## 🗄️ Estrutura das Migrações (Flyway)

O banco de dados é versionado utilizando Flyway para garantir consistência. As migrações estão organizadas da seguinte forma:
* **V1:** Cria a tabela `MOTO`.
* **V2:** Cria as tabelas `SENSOR` e `MOVIMENTACAO`.
* **V3:** Cria a tabela `USERS` para o sistema de segurança.
* **V4:** Insere os dados iniciais: os usuários `admin` e `user`, e uma moto de teste.
