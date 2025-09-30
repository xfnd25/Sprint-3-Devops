# ===================================================================
# Script de Deploy - Versão Final e Definitiva (por DevOps Sênior)
# ===================================================================

# Garante que o script pare imediatamente se qualquer erro ocorrer
$ErrorActionPreference = "Stop"

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
$RM = "555317"
$RESOURCE_GROUP = "rg-devops-25s2-sprint3-$RM"
$LOCATION = "brazilsouth"
$APPSERVICE_PLAN = "plan-motolocation-$RM"
$POSTGRES_SERVER_NAME = "pgsrv-motolocation-$RM"
$POSTGRES_DB_NAME = "motolocation"
$POSTGRES_ADMIN_USER = "mottuadmin"
$POSTGRES_ADMIN_PASSWORD = "ChallengeFiap2025"
$WEBAPP_NAME = "webapp-motolocation-$RM"

# --- PASSO 2: LOGIN NA AZURE ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 2: Fazendo login na Azure..."
Write-Host "========================================================" -ForegroundColor Green
az login

# --- PASSO 3: LIMPEZA DE RECURSOS ANTIGOS ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 3: Verificando e limpando recursos antigos..."
Write-Host "========================================================" -ForegroundColor Green
if (az group exists --name $RESOURCE_GROUP) {
    Write-Host "Grupo de recursos '$RESOURCE_GROUP' já existe. Removendo..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    Write-Host "Aguardando a exclusão completa..."
    az group wait --name $RESOURCE_GROUP --deleted
    Write-Host "Grupo de recursos removido com sucesso." -ForegroundColor Green
} else {
    Write-Host "Nenhum grupo de recursos antigo encontrado."
}

# --- PASSO 4: COMPILAR A APLICAÇÃO JAVA ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 4: Compilando a aplicação..."
Write-Host "========================================================" -ForegroundColor Green
./mvnw clean package -DskipTests

# --- PASSO 5: REGISTRAR OS PROVEDORES ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 5: Registrando provedores de serviço..."
Write-Host "========================================================" -ForegroundColor Green
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Web
do {
    $statusDB = az provider show --namespace Microsoft.DBforPostgreSQL --query "registrationState" -o tsv
    $statusWeb = az provider show --namespace Microsoft.Web --query "registrationState" -o tsv
    Write-Host "Status: PostgreSQL=$statusDB | Web=$statusWeb"
    if ($statusDB -ne "Registered" -or $statusWeb -ne "Registered") { Start-Sleep -s 10 }
} while ($statusDB -ne "Registered" -or $statusWeb -ne "Registered")
Write-Host "Provedores registrados com sucesso!" -ForegroundColor Green

# --- PASSO 6: CRIAR GRUPO DE RECURSOS ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 6: Criando grupo de recursos..."
Write-Host "========================================================" -ForegroundColor Green
az group create --name $RESOURCE_GROUP --location $LOCATION

# --- PASSO 7: CRIAR SERVIDOR POSTGRESQL ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 7: Criando servidor PostgreSQL (pode levar 10-20 min)"
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

# --- ESPERA INTELIGENTE PELO SERVIDOR ---
Write-Host "Iniciando verificação de status do servidor PostgreSQL..." -ForegroundColor Yellow
$maxWait = 20; $waitInterval = 30; $i = 0; $pgStatus = "Creating"
do {
    $i++; try { $pgStatus = az postgres flexible-server show --name $POSTGRES_SERVER_NAME --resource-group $RESOURCE_GROUP --query "userVisibleState" -o tsv } catch {}
    Write-Host "[$i/$maxWait] Status: $pgStatus"
    if ($pgStatus -eq "Ready") { Write-Host "Servidor PostgreSQL pronto!" -ForegroundColor Green; break }
    if ($i -ge $maxWait) { Write-Host "ERRO: Timeout atingido." -ForegroundColor Red; break }
    Start-Sleep -s $waitInterval
} while ($pgStatus -ne "Ready")

# --- PASSO 8: FIREWALL ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 8: Configurando firewall..."
Write-Host "========================================================" -ForegroundColor Green
az postgres flexible-server firewall-rule create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGRES_SERVER_NAME `
    --rule-name "AllowAzureServices" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0"

# --- PASSO 9: BANCO DE DADOS ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 9: Criando banco de dados..."
Write-Host "========================================================" -ForegroundColor Green
az postgres flexible-server db create `
    --resource-group $RESOURCE_GROUP `
    --server-name $POSTGRES_SERVER_NAME `
    --database-name $POSTGRES_DB_NAME

# --- PASSO 10: APP SERVICE PLAN ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 10: Criando App Service Plan (Gratuito)..."
Write-Host "========================================================" -ForegroundColor Green
az appservice plan create `
    --name $APPSERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --sku F1 `
    --is-linux

# --- PASSO 11: WEBAPP ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 11: Criando WebApp..."
Write-Host "========================================================" -ForegroundColor Green
az webapp create `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APPSERVICE_PLAN `
    --runtime "JAVA:17-java17"

# --- PASSO 12: VARIÁVEIS DE AMBIENTE (CORREÇÃO CRÍTICA) ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 12: Configurando variáveis de ambiente padrão do Spring Boot..."
Write-Host "========================================================" -ForegroundColor Green
$SPRING_DATASOURCE_URL = "jdbc:postgresql://$POSTGRES_SERVER_NAME.postgres.database.azure.com:5432/$POSTGRES_DB_NAME?sslmode=require"
$SPRING_DATASOURCE_USERNAME = "$POSTGRES_ADMIN_USER@$POSTGRES_SERVER_NAME"
$SPRING_DATASOURCE_PASSWORD = $POSTGRES_ADMIN_PASSWORD

az webapp config appsettings set `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --settings `
    "SPRING_PROFILES_ACTIVE=prod" `
    "SPRING_DATASOURCE_URL=$SPRING_DATASOURCE_URL" `
    "SPRING_DATASOURCE_USERNAME=$SPRING_DATASOURCE_USERNAME" `
    "SPRING_DATASOURCE_PASSWORD=$SPRING_DATASOURCE_PASSWORD"

# --- PASSO 13: PREPARAR PACOTE ZIP PARA DEPLOY (NOVA LÓGICA) ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 13: Preparando pacote ZIP para o deploy..."
Write-Host "========================================================" -ForegroundColor Green

# Encontra o JAR correto (não o .original)
$JAR_FILE = Get-ChildItem -Path "target" -Filter "*.jar" | Where-Object { $_.Name -notlike "*.original.jar" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $JAR_FILE) {
    Write-Host "ERRO: Nenhum arquivo JAR executável encontrado em target/" -ForegroundColor Red
    exit 1
}
Write-Host "Arquivo JAR encontrado: $($JAR_FILE.Name)" -ForegroundColor Green

# Cria uma pasta temporária para o deploy
$deployFolder = "deploy_temp"
if (Test-Path $deployFolder) { Remove-Item -Recurse -Force $deployFolder }
New-Item -ItemType Directory -Path $deployFolder

# Copia o JAR para a pasta e o renomeia para app.jar
Copy-Item -Path $JAR_FILE.FullName -Destination "$deployFolder/app.jar"
Write-Host "JAR copiado e renomeado para app.jar"

# Cria o arquivo ZIP
$zipFile = "deploy.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile }
Compress-Archive -Path "$deployFolder/*" -DestinationPath $zipFile
Write-Host "Arquivo '$zipFile' criado com sucesso." -ForegroundColor Green


# --- PASSO 14: DEPLOY DO ZIP (MÉTODO ROBUSTO) ---
Write-Host "========================================================" -ForegroundColor Green
Write-Host "PASSO 14: Fazendo deploy do arquivo ZIP..."
Write-Host "========================================================" -ForegroundColor Green

az webapp deploy `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --src-path $zipFile `
    --type zip

# --- FINALIZAÇÃO ---
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "DEPLOY FINALIZADO COM SUCESSO!" -ForegroundColor Magenta
Write-Host "Aguarde 1-2 minutos para a aplicação iniciar na nuvem."
Write-Host "Acesse sua aplicação em: http://$WEBAPP_NAME.azurewebsites.net" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta