# Projeto de DevOps: Deploy da Aplicação Mottu Location na Azure

## Integrantes
* **RM555317** - Fernando Fontes
* **RM556814** - Guilherme Jardim

---

## 1. Descrição da Solução

Este projeto implementa um fluxo de **Infraestrutura como Código (IaC)** para automatizar o deploy da aplicação web **Mottu Location** na nuvem da **Microsoft Azure**. A solução utiliza a **Azure CLI** para provisionar todos os recursos necessários, incluindo um banco de dados PostgreSQL e um Serviço de Aplicativo (App Service) para hospedar a aplicação Java.

A aplicação em si é um sistema full-stack desenvolvido com Spring Boot e Thymeleaf, que permite o gerenciamento e rastreamento de uma frota de motocicletas.

---

## 2. Benefícios para o Negócio

A automação do deploy via scripts traz benefícios cruciais para o negócio:

* **Agilidade:** A criação de um ambiente completo (banco de dados + aplicação) é feita em minutos, executando um único script, o que acelera drasticamente o tempo de entrega.
* **Redução de Erros:** A automação elimina falhas manuais de configuração, garantindo que o ambiente seja sempre criado da mesma forma.
* **Reprodutibilidade:** Qualquer desenvolvedor pode recriar a infraestrutura exata com um único comando, garantindo consistência entre os ambientes de desenvolvimento e produção.
* **Segurança:** As credenciais do banco de dados são gerenciadas de forma segura como variáveis de ambiente na Azure, nunca sendo expostas no código-fonte.

---

## 3. Arquitetura da Solução na Nuvem

O projeto utiliza uma arquitetura baseada em serviços de plataforma (PaaS) na Azure para otimizar custos e simplificar o gerenciamento.

* **Usuário Final:** Acessa a aplicação através de um navegador.
* **Azure App Service:** Hospeda o arquivo `.jar` da aplicação Java. É responsável por servir as páginas web (Thymeleaf) e processar a lógica de negócio.
* **Azure Database for PostgreSQL:** Serviço gerenciado que armazena todos os dados da aplicação (motos, sensores, usuários, etc.). A comunicação entre o App Service e o banco de dados é segura e otimizada dentro da rede da Azure.
* **Azure CLI:** Ferramenta utilizada pelo desenvolvedor para automatizar a criação e configuração de todos os recursos acima.

*(Dica: Adicione o seu diagrama de arquitetura aqui como uma imagem)*

---

## 🛠️ Tecnologias Utilizadas

* **Nuvem:** Microsoft Azure
* **Banco de Dados:** Azure Database for PostgreSQL (PaaS)
* **Hospedagem da Aplicação:** Azure App Service (PaaS)
* **Automação:** Azure CLI com PowerShell
* **Aplicação:** Java 17, Spring Boot, Spring Security, Thymeleaf
* **Versionamento de Banco:** Flyway

---

## 🏁 Guia de Deploy Automatizado

Este guia descreve como provisionar toda a infraestrutura na Azure e publicar a aplicação usando um único script.

### Pré-requisitos
* **Azure CLI** instalada e configurada.
* **JDK 17** e **Maven 3.8+** para compilar o projeto.

### Passo a Passo para o Deploy
1.  **Clone este repositório:**
    ```bash
    git clone [https://github.com/xfnd25/motolocation-devops.git](https://github.com/xfnd25/motolocation-devops.git)
    cd motolocation-devops
    ```
2.  **Abra o PowerShell como Administrador** e navegue até a pasta do projeto.

3.  **Libere a Execução de Scripts (se necessário):**
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
4.  **Execute o Script de Deploy:**
    O script irá compilar o projeto, pedir seu login na Azure, criar todos os recursos na nuvem, configurar as variáveis de ambiente e publicar a aplicação.
    ```powershell
    ./deploy.ps1
    Observação, a tela de Login vai abrir atras do InteliJ, ou colada com o terminal no qual você executou, ou seja, não use o terminal em tela cheia para ver a tela de login.
    ```
    *Aguarde a execução completa (pode levar de 5 a 15 minutos).*

### Acesso e Credenciais (Após o Deploy)
* **URL da Aplicação:** Será exibida no final da execução do script (ex: `http://webapp-motolocation-555317.azurewebsites.net`).
* **Credenciais de Login:**
    * **Administrador:**
        * Usuário: `admin`
        * Senha: `admin`
    * **Usuário Comum:**
        * Usuário: `user`
        * Senha: `user`

---

## 🗑️ Limpando os Recursos da Nuvem

Para apagar **todos** os recursos criados na Azure e evitar custos, execute o script de limpeza:

```powershell
./cleanup.ps1