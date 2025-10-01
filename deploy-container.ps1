# ===================================================================
# Script de Deploy - Versão ACR + ACI com Comentários para Apresentação
# ===================================================================

# Garante que o script pare imediatamente se qualquer erro inesperado ocorrer.
$ErrorActionPreference = "Stop"

# --- BLOCO 1: DEFINIÇÃO DE VARIÁVEIS ---
# "Neste primeiro bloco, definimos todas as variáveis que serão usadas no script.
# Isso inclui nomes para nossos recursos na nuvem, a localização e as credenciais.
# Adicionamos um sufixo aleatório para garantir que os nomes sejam sempre únicos e evitar conflitos."
$RM = "555317"
$RANDOM_SUFFIX = Get-Random -Minimum 1000 -Maximum 9999
$RESOURCE_GROUP = "rg-container-sprint3-$RM"
$LOCATION = "brazilsouth"
$POSTGRES_SERVER_NAME = "pgsrv-container-$RM-$RANDOM_SUFFIX"
$ACR_NAME = "acrmotolocation$RM$RANDOM_SUFFIX"
$ACI_NAME = "aci-motolocation-$RM-$RANDOM_SUFFIX"
$DNS_NAME_LABEL = "motolocation-app-$RM-$RANDOM_SUFFIX"
$POSTGRES_DB_NAME = "motolocation"
$POSTGRES_ADMIN_USER = "mottuadmin"
$POSTGRES_ADMIN_PASSWORD = "ChallengeFiap2025!"
$IMAGE_NAME = "motolocation-app:latest"

# --- BLOCO 2: VERIFICAÇÃO DO AMBIENTE LOCAL ---
# "Antes de começar, o script verifica se o Docker Desktop, que é um pré-requisito,
# está realmente rodando na minha máquina. Se não estiver, ele para com uma mensagem de erro."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Verificando pré-requisitos (Docker)..."
Write-Host "========================================================" -ForegroundColor Green
docker info > $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: O Docker Desktop não parece estar rodando." -ForegroundColor Red
    Write-Host "Por favor, inicie o Docker Desktop e execute o script novamente." -ForegroundColor Red
    exit 1
}
Write-Host "Docker está rodando!" -ForegroundColor Green

# --- BLOCO 3: AUTENTICAÇÃO NA AZURE ---
# "Agora, o script inicia a interação com a nuvem, pedindo meu login na Azure
# para que ele tenha as permissões necessárias para criar e gerenciar os recursos."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Autenticando na Azure..."
Write-Host "========================================================" -ForegroundColor Green
az login

# --- BLOCO 4: LIMPEZA DO AMBIENTE ---
# "Para garantir um deploy limpo, o script primeiro tenta destruir qualquer
# versão antiga do ambiente que possa existir na nuvem. Se não encontrar nada, ele apenas continua."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Limpando ambiente antigo..."
Write-Host "========================================================" -ForegroundColor Green
try {
    Write-Host "Tentando remover o grupo de recursos '$RESOURCE_GROUP'..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes
    Write-Host "Grupo de recursos antigo destruído com sucesso." -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*ResourceGroupNotFound*") {
        Write-Host "Nenhum grupo de recursos antigo para remover. Ótimo!" -ForegroundColor Green
    } else {
        throw $_.Exception
    }
}

# --- BLOCO 5: CRIAÇÃO DA INFRAESTRUTURA ---
# "Com o ambiente limpo, o script agora começa a construir nossa infraestrutura na Azure.
# Ele cria o Grupo de Recursos, o servidor de banco de dados PostgreSQL e o Container Registry,
# que é onde vamos armazenar a imagem da nossa aplicação."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Criando infraestrutura na Azure (Grupo, PostgreSQL e ACR)..."
Write-Host "========================================================" -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION
Write-Host "Criando servidor PostgreSQL (pode levar 10-20 min)..." -ForegroundColor Cyan
az postgres flexible-server create --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER_NAME --location $LOCATION --admin-user $POSTGRES_ADMIN_USER --admin-password $POSTGRES_ADMIN_PASSWORD --sku-name Standard_B1ms --tier Burstable --storage-size 32 --version 15 --yes
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $POSTGRES_SERVER_NAME --database-name $POSTGRES_DB_NAME
Write-Host "Criando Azure Container Registry..." -ForegroundColor Cyan
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# --- BLOCO 6: CONFIGURAÇÃO DO FIREWALL ---
# "Este é um passo crucial de segurança e conectividade. O script adiciona uma regra
# no firewall do nosso banco de dados para permitir que outros serviços da Azure,
# como o nosso futuro contêiner, possam se conectar a ele."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Configurando firewall do PostgreSQL..."
Write-Host "========================================================" -ForegroundColor Green
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER_NAME --rule-name "AllowAzureServices" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"

# --- BLOCO 7: BUILD E PUSH DA IMAGEM DOCKER ---
# "Agora, o script usa o Docker na minha máquina para construir a imagem da aplicação,
# usando nosso Dockerfile. Depois, ele 'carimba' a imagem com o endereço do nosso
# Container Registry e a envia para a nuvem."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Fazendo build e push da imagem Docker..."
Write-Host "========================================================" -ForegroundColor Green
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --query "loginServer" -o tsv
az acr login --name $ACR_NAME
docker build -t $IMAGE_NAME .
docker tag $IMAGE_NAME "$ACR_LOGIN_SERVER/$IMAGE_NAME"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME"
Write-Host "Imagem Docker enviada para o ACR com sucesso!" -ForegroundColor Green

# --- BLOCO 8: CRIAÇÃO E EXECUÇÃO DO CONTÊINER ---
# "Este é o passo final. O script cria o Azure Container Instance, dizendo a ele para
# baixar a imagem que acabamos de enviar. O mais importante é que aqui nós injetamos
# as credenciais do banco como variáveis de ambiente, de forma segura, e alocamos
# os recursos de CPU e memória para a aplicação rodar."
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Criando e executando o contêiner da aplicação (ACI)..."
Write-Host "========================================================" -ForegroundColor Green
$DB_URL = "jdbc:postgresql://$POSTGRES_SERVER_NAME.postgres.database.azure.com:5432/$POSTGRES_DB_NAME?sslmode=require"
$DB_USER = $POSTGRES_ADMIN_USER
$DB_PASS = $POSTGRES_ADMIN_PASSWORD
$ACR_PASSWORD = az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv

az container create `
    --resource-group $RESOURCE_GROUP `
    --name $ACI_NAME `
    --image "$ACR_LOGIN_SERVER/$IMAGE_NAME" `
    --registry-login-server $ACR_LOGIN_SERVER `
    --registry-username $ACR_NAME `
    --registry-password $ACR_PASSWORD `
    --dns-name-label $DNS_NAME_LABEL `
    --ports 8080 `
    --os-type Linux `
    --cpu 1 `
    --memory 1.5 `
    --environment-variables `
        "SPRING_PROFILES_ACTIVE=prod" `
        "DB_URL=$DB_URL" `
        "DB_USER=$DB_USER" `
        "DB_PASS=$DB_PASS"

# --- FINALIZAÇÃO ---
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "DEPLOY CONCLUIDO COM SUCESSO!"
Write-Host "Aguarde 2-3 minutos para o conteiner iniciar completamente." -ForegroundColor Magenta
Write-Host "Acesse sua aplicacao em: http://$DNS_NAME_LABEL.$LOCATION.azurecontainer.io:8080" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta
