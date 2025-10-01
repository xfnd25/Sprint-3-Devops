# ===================================================================
# Script de Deploy - Versão Xeque-Mate Final (Firewall Corrigido)
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
Write-Host "PASSO 2: Verificando se o Docker esta em execucao..."
Write-Host "========================================================" -ForegroundColor Green
docker info > $null
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO: O Docker Desktop nao esta rodando." -ForegroundColor Red; exit 1 }
Write-Host "Docker esta rodando!" -ForegroundColor Green

# --- PASSO 3: LOGIN NA AZURE ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 3: Fazendo login na Azure..."
Write-Host "========================================================" -ForegroundColor Green
az login

# --- PASSO 4: LIMPEZA TOTAL E GARANTida ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 4: Garantindo que o ambiente antigo seja destruido..."
Write-Host "========================================================" -ForegroundColor Green
try {
    Write-Host "Tentando remover o grupo de recursos '$RESOURCE_GROUP'..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes
    Write-Host "Grupo de recursos antigo destruido com sucesso." -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*ResourceGroupNotFound*") { Write-Host "Nenhum grupo de recursos antigo para remover. Otimo!" -ForegroundColor Green }
    else { throw $_.Exception }
}

# --- PASSO 5: CRIAR INFRAESTRUTURA NA AZURE ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 5: Criando infraestrutura (Grupo, PostgreSQL e ACR)..."
Write-Host "========================================================" -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION
Write-Host "Criando servidor PostgreSQL (pode levar 10-20 min)..." -ForegroundColor Cyan
az postgres flexible-server create --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER_NAME --location $LOCATION --admin-user $POSTGRES_ADMIN_USER --admin-password $POSTGRES_ADMIN_PASSWORD --sku-name Standard_B1ms --tier Burstable --storage-size 32 --version 15 --yes
az postgres flexible-server db create --resource-group $RESOURCE_GROUP --server-name $POSTGRES_SERVER_NAME --database-name $POSTGRES_DB_NAME
Write-Host "Criando Azure Container Registry..." -ForegroundColor Cyan
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# ===== A CORREÇÃO FINAL ESTÁ AQUI =====
# Adicionando a regra de firewall para permitir que serviços da Azure (como o ACI) se conectem.
Write-Host "Configurando firewall para servicos da Azure..." -ForegroundColor Cyan
az postgres flexible-server firewall-rule create --resource-group $RESOURCE_GROUP --name $POSTGRES_SERVER_NAME --rule-name "AllowAzureServices" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"


# --- PASSO 6: BUILD, TAG E PUSH DA IMAGEM DOCKER ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 6: Fazendo build, tag e push da imagem Docker..."
Write-Host "========================================================" -ForegroundColor Green
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --query "loginServer" -o tsv
az acr login --name $ACR_NAME
docker build -t $IMAGE_NAME .
docker tag $IMAGE_NAME "$ACR_LOGIN_SERVER/$IMAGE_NAME"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME"
Write-Host "Imagem Docker enviada para o ACR com sucesso!" -ForegroundColor Green

# --- PASSO 7: CRIAR O AZURE CONTAINER INSTANCE (ACI) ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 7: Criando o Azure Container Instance (ACI)..."
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