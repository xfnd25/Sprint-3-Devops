# ===================================================================
# Script de Deploy - Versão Xeque-Mate Final
# ===================================================================

$ErrorActionPreference = "Stop"

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
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

# --- PASSO 2: VERIFICAR DOCKER ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Verificando Docker..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Docker Desktop nao esta rodando!" -ForegroundColor Red
    exit 1
}
Write-Host "Docker OK!" -ForegroundColor Green

# --- PASSO 3: LOGIN NA AZURE ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Login na Azure..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
az login

# --- PASSO 4: LIMPAR AMBIENTE ANTIGO ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Limpando ambiente antigo..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
if (az group exists --name $RESOURCE_GROUP) {
    Write-Host "Removendo grupo antigo..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    Write-Host "Exclusao iniciada! Aguardando conclusao..."
    az group wait --name $RESOURCE_GROUP --deleted
    Write-Host "Grupo de recursos removido com sucesso." -ForegroundColor Green
}
else {
    Write-Host "Nenhum grupo antigo encontrado." -ForegroundColor Green
}

# --- PASSO 5: CRIAR GRUPO DE RECURSOS ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Criando Resource Group..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION

# --- PASSO 6: CRIAR POSTGRESQL E ACR ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Criando PostgreSQL (pode demorar 10-20 min)..." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Green
az postgres flexible-server create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGRES_SERVER_NAME `
    --location $LOCATION `
    --admin-user $POSTGRES_ADMIN_USER `
    --admin-password $POSTGRES_ADMIN_PASSWORD `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --storage-size 32 `
    --version 15 `
    --yes

az postgres flexible-server db create `
    --resource-group $RESOURCE_GROUP `
    --server-name $POSTGRES_SERVER_NAME `
    --database-name $POSTGRES_DB_NAME

Write-Host "Configurando firewall do PostgreSQL..." -ForegroundColor Cyan
az postgres flexible-server firewall-rule create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGRES_SERVER_NAME `
    --rule-name "AllowAzureServices" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0"

Write-Host "Criando Azure Container Registry..." -ForegroundColor Cyan
az acr create `
    --resource-group $RESOURCE_GROUP `
    --name $ACR_NAME `
    --sku Basic `
    --admin-enabled true

# --- PASSO 7: BUILD E PUSH DA IMAGEM DOCKER ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Build e Push da imagem Docker..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --query "loginServer" -o tsv
az acr login --name $ACR_NAME
docker build -t $IMAGE_NAME .
docker tag $IMAGE_NAME "$ACR_LOGIN_SERVER/$IMAGE_NAME"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME"
Write-Host "Imagem enviada com sucesso!" -ForegroundColor Green

# --- PASSO 8: CRIAR AZURE CONTAINER INSTANCE (COM A CORREÇÃO) ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Criando Azure Container Instance..." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green

# ===== A CORREÇÃO FINAL ESTÁ AQUI =====
# Passamos as PEÇAS da URL, em vez da URL inteira, para evitar o bug do PowerShell.
# O application-prod.properties deve ser ajustado para montar a URL a partir destas peças.
$DB_HOST = "$POSTGRES_SERVER_NAME.postgres.database.azure.com"
$DB_NAME = $POSTGRES_DB_NAME
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
        "DB_HOST=$DB_HOST" `
        "DB_NAME=$DB_NAME" `
        "DB_USER=$DB_USER" `
        "DB_PASS=$DB_PASS"

# --- FINALIZAÇÃO ---
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Magenta
Write-Host "Aguarde 2-3 minutos para o container iniciar." -ForegroundColor Magenta
Write-Host "URL: http://$DNS_NAME_LABEL.$LOCATION.azurecontainer.io:8080" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta