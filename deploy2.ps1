# ===================================================================
# Script de Deploy - VERSÃO DEFINITIVA FUNCIONAL
# ===================================================================

$ErrorActionPreference = "Stop"

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
$RM = "555317"
$RESOURCE_GROUP = "rg-motolocation-$RM"  # ← CORRIGIDO
$LOCATION = "brazilsouth"
$APPSERVICE_PLAN = "plan-motolocation-$RM"
$POSTGRES_SERVER_NAME = "pgsrv-motolocation-$RM"
$POSTGRES_DB_NAME = "motolocation"
$POSTGRES_ADMIN_USER = "mottuadmin"
$POSTGRES_ADMIN_PASSWORD = "ChallengeFiap2025"
$WEBAPP_NAME = "webapp-motolocation-$RM"

Write-Host "========================================================" -ForegroundColor Green
Write-Host "INICIANDO DEPLOY DEFINITIVO" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green

# --- PASSO 2: LOGIN NA AZURE ---
Write-Host "PASSO 2: Fazendo login na Azure..." -ForegroundColor Cyan
az login

# --- PASSO 3: LIMPEZA ---
Write-Host "PASSO 3: Limpando recursos antigos..." -ForegroundColor Cyan
if (az group exists --name $RESOURCE_GROUP) {
    Write-Host "Removendo grupo de recursos existente..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    Start-Sleep -Seconds 30
}

# --- PASSO 4: COMPILAR ---
Write-Host "PASSO 4: Compilando aplicação..." -ForegroundColor Cyan
./mvnw clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Compilação falhou!" -ForegroundColor Red
    exit 1
}

# --- PASSO 5: CRIAR GRUPO DE RECURSOS ---
Write-Host "PASSO 5: Criando grupo de recursos..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION

# --- PASSO 6: CRIAR POSTGRESQL ---
Write-Host "PASSO 6: Criando PostgreSQL..." -ForegroundColor Cyan
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

Write-Host "Aguardando PostgreSQL (3 minutos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 180

# --- PASSO 7: CRIAR BANCO ---
Write-Host "PASSO 7: Criando banco de dados..." -ForegroundColor Cyan
az postgres flexible-server db create `
    --resource-group $RESOURCE_GROUP `
    --server-name $POSTGRES_SERVER_NAME `
    --database-name $POSTGRES_DB_NAME

# --- PASSO 8: FIREWALL ---
Write-Host "PASSO 8: Configurando firewall..." -ForegroundColor Cyan
az postgres flexible-server firewall-rule create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGRES_SERVER_NAME `
    --rule-name "AllowAllAzure" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0"

# --- PASSO 9: APP SERVICE PLAN ---
Write-Host "PASSO 9: Criando App Service Plan..." -ForegroundColor Cyan
az appservice plan create `
    --name $APPSERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --sku B1 `  # ← Mudei para B1 (mais confiável)
    --is-linux

# --- PASSO 10: WEBAPP ---
Write-Host "PASSO 10: Criando WebApp..." -ForegroundColor Cyan
az webapp create `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APPSERVICE_PLAN `
    --runtime "JAVA:17-java17"

Start-Sleep -Seconds 30

# --- PASSO 11: VARIÁVEIS DE AMBIENTE (CORRETAS) ---
Write-Host "PASSO 11: Configurando variáveis..." -ForegroundColor Cyan
$DB_URL = "jdbc:postgresql://$POSTGRES_SERVER_NAME.postgres.database.azure.com:5432/$POSTGRES_DB_NAME?sslmode=require"
$DB_USER = "$POSTGRES_ADMIN_USER@$POSTGRES_SERVER_NAME"

az webapp config appsettings set `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --settings `
    SPRING_PROFILES_ACTIVE=prod `
    DB_URL=$DB_URL `
    DB_USER=$DB_USER `
    DB_PASS=$POSTGRES_ADMIN_PASSWORD `
    WEBSITES_PORT=8080 `
    JAVA_OPTS="-Dserver.port=8080"

# --- PASSO 12: DEPLOY ---
Write-Host "PASSO 12: Fazendo deploy..." -ForegroundColor Cyan
az webapp deploy `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --src-path "./target/motolocation-0.0.1-SNAPSHOT.jar" `
    --type jar

# --- PASSO 13: VERIFICAÇÃO ---
Write-Host "PASSO 13: Verificando deploy..." -ForegroundColor Cyan
Start-Sleep -Seconds 60

Write-Host "Verificando logs..." -ForegroundColor Yellow
az webapp log tail --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --lines 20

# --- FINAL ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "🎉 DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "🌐 URL: https://$WEBAPP_NAME.azurewebsites.net" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "🔐 LOGIN PARA TESTAR:" -ForegroundColor Yellow
Write-Host "Usuário: admin" -ForegroundColor White
Write-Host "Senha: admin" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "📋 SE NÃO FUNCIONAR:" -ForegroundColor Yellow
Write-Host "1. Aguarde 2-3 minutos" -ForegroundColor White
Write-Host "2. Verifique logs: az webapp log tail -g $RESOURCE_GROUP -n $WEBAPP_NAME" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Green