Projeto de DevOps: Deploy da Aplicação Mottu Location na Azure
Integrantes

RM555317 - Fernando Fontes
RM556814 - Guilherme Jardim

1. Descrição da Solução:
Este projeto implementa um fluxo de Infraestrutura como Código (IaC) para automatizar o deploy da aplicação web Mottu Location na nuvem da Microsoft Azure. A solução adota uma arquitetura moderna baseada em contêineres, utilizando Docker para empacotar a aplicação, Azure Container Registry (ACR) para armazenar a imagem de forma segura, e Azure Container Instance (ACI) para executar a aplicação em um ambiente isolado e escalável.
A aplicação em si é um sistema full-stack desenvolvido com Spring Boot e Thymeleaf, que permite o gerenciamento e rastreamento de uma frota de motocicletas, com os dados persistidos em um banco de dados Azure Database for PostgreSQL.

2. Benefícios para o Negócio:
A automação do deploy e o uso de contêineres trazem benefícios cruciais para o negócio:
Agilidade: A criação de um ambiente completo (banco de dados + aplicação em contêiner) é feita em minutos, executando um único script, o que acelera drasticamente o tempo de entrega.
Portabilidade e Consistência: A "containerização" com Docker garante que a aplicação rode da mesma forma no ambiente do desenvolvedor e na nuvem, eliminando o clássico problema de "funciona na minha máquina".
Reprodutibilidade: Qualquer desenvolvedor pode recriar a infraestrutura e o ambiente de execução exatos com um único comando, garantindo consistência total.
Segurança: As credenciais do banco de dados são injetadas de forma segura como variáveis de ambiente no contêiner em tempo de execução, nunca sendo expostas no código-fonte ou na imagem Docker.

4. Arquitetura da Solução na Nuvem:
O projeto utiliza uma arquitetura baseada em contêineres e serviços gerenciados (PaaS) na Azure para otimizar a portabilidade, segurança e gerenciamento. A automação é feita via Azure CLI, que orquestra a criação de todos os recursos.
O fluxo se inicia na máquina do desenvolvedor, onde o Docker cria uma imagem da aplicação. Essa imagem é enviada para o Azure Container Registry (ACR), nosso repositório privado na nuvem. Em paralelo, um banco de dados Azure Database for PostgreSQL é provisionado.
Finalmente, o Azure Container Instance (ACI) é criado, recebendo a instrução para baixar a imagem do ACR e executá-la. Durante a inicialização, o ACI injeta as credenciais do banco de dados no contêiner, permitindo que a aplicação se conecte e se torne acessível ao usuário final através de uma URL pública.

Fluxo de Funcionamento:

Desenvolvedor: Inicia todo o processo executando um único script PowerShell em sua máquina local.
PowerShell com Azure CLI: O script orquestra todas as ações, desde o build local até a criação dos recursos na nuvem.
Docker: O Docker, rodando localmente, utiliza o Dockerfile do projeto para compilar a aplicação Java e empacotá-la em uma imagem de contêiner auto-suficiente.
Azure Container Registry (ACR): O script envia (push) a imagem Docker recém-criada para o ACR, que funciona como nosso repositório privado e seguro de imagens na nuvem.
Azure Database for PostgreSQL: O script provisiona um servidor de banco de dados gerenciado para persistir todos os dados da aplicação.
Azure Container Instance (ACI): O script provisiona uma instância de contêiner, instruindo-a a baixar (pull) a imagem da nossa aplicação diretamente do ACR.
Conexão Segura: Durante a criação do ACI, o script injeta as credenciais do banco de dados como variáveis de ambiente, permitindo que a aplicação se conecte de forma segura.
Usuário Final: Acessa a aplicação através de uma URL pública fornecida pelo ACI.

🛠️ Tecnologias Utilizadas
Nuvem: Microsoft Azure

Banco de Dados: Azure Database for PostgreSQL (PaaS)
Containerização: Docker, Azure Container Registry (ACR), Azure Container Instance (ACI)
Automação: Azure CLI com PowerShell
Aplicação: Java 17, Spring Boot, Spring Security, Thymeleaf
Versionamento de Banco: Flyway

🏁 Guia de Deploy Automatizado
Este guia descreve como provisionar toda a infraestrutura na Azure e publicar a aplicação em contêiner usando um único script.

Pré-requisitos
Azure CLI instalada e configurada.
Docker Desktop instalado e em execução na sua máquina.
JDK 17 e Maven 3.8+ para compilação local (usado pelo Docker).

Passo a Passo para o Deploy
Clone este repositório:

git clone https://github.com/xfnd25/Sprint-3-Devops
cd [NOME_DA_PASTA_DO_PROJETO]

Abra o PowerShell e navegue até a pasta do projeto.

Execute o Script de Deploy:
O script irá verificar se o Docker está rodando, pedir seu login na Azure, destruir qualquer ambiente antigo, criar todos os recursos na nuvem (PostgreSQL, ACR), construir a imagem Docker localmente, enviá-la para o ACR e, finalmente, criar o ACI para rodar a aplicação.

./deploy-container.ps1
Aguarde a execução completa (pode levar de 15 a 25 minutos, principalmente na criação do banco e no envio da imagem Docker).

Acesso e Credenciais (Após o Deploy)
URL da Aplicação: Será exibida no final da execução do script (ex: http://motolocation-app-555317-xxxx.brazilsouth.azurecontainer.io:8080).

Credenciais de Login:

Administrador:
Usuário: admin
Senha: admin
Usuário Comum:
Usuário: user
Senha: user

🗑️ Limpando os Recursos da Nuvem
O próprio script deploy-container.ps1 já executa a limpeza no início de cada execução. No entanto, se você quiser apagar todos os recursos criados na Azure a qualquer momento e evitar custos, execute o seguinte comando no PowerShell (após logar com az login):

az group delete --name rg-container-sprint3-555317 --yes

