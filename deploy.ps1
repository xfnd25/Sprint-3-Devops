# ===================================================================
# Script de Deploy FINAL E CORRIGIDO - Mottu Location na Azure
# ===================================================================

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
$RM="555317"
$RESOURCE_GROUP="rg-motolocation-$RM"
$LOCATION="westus" # Região final escolhida
$APPSERVICE_PLAN="plan-motolocation-$RM"
$POSTGES_SERVER_NAME="pgsrv-motolocation-$RM"
$POSTGRES_DB_NAME="motolocation"
$POSTGRES_ADMIN_USER="mottuadmin"
$POSTGRES_ADMIN_PASSWORD="Challenge_FIAP_2025!"
$WEBAPP_NAME="webapp-motolocation-$RM"

# --- PASSO 2: COMPILAR A APLICAÇÃO JAVA ---
echo "--------------------------------------------------------"
echo "PASSO 2: Compilando a aplicação..."
echo "--------------------------------------------------------"
./mvnw clean package -DskipTests

# --- PASSO 3: LOGIN NA AZURE ---
echo "--------------------------------------------------------"
echo "PASSO 3: Fazendo login na Azure..."
echo "--------------------------------------------------------"
az login

# --- PASSO 4: REGISTRAR OS PROVEDORES DE SERVIÇO ---
echo "--------------------------------------------------------"
echo "PASSO 4: Registrando provedores de serviço..."
echo "--------------------------------------------------------"
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Web

# --- PASSO 5: CRIAR O GRUPO DE RECURSOS ---
echo "--------------------------------------------------------"
echo "PASSO 5: Criando o Grupo de Recursos..."
echo "--------------------------------------------------------"
az group create --name $RESOURCE_GROUP --location $LOCATION

# --- PASSO 6: CRIAR O SERVIDOR POSTGRESQL (MAIS SEGURO) ---
echo "--------------------------------------------------------"
echo "PASSO 6: Criando o Servidor PostgreSQL (pode levar alguns minutos)..."
echo "--------------------------------------------------------"
az postgres flexible-server create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGES_SERVER_NAME `
    --location $LOCATION `
    --admin-user $POSTGRES_ADMIN_USER `
    --admin-password $POSTGRES_ADMIN_PASSWORD `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --storage-size 32 `
    --version 15

# --- PASSO 7: CONFIGURAR REGRA DE FIREWALL ---
# Permite que outros serviços DENTRO da Azure acessem o banco.
echo "--------------------------------------------------------"
echo "PASSO 7: Configurando firewall do banco de dados..."
echo "--------------------------------------------------------"
az postgres flexible-server firewall-rule create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGES_SERVER_NAME `
    --rule-name "AllowAzureServices" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0"

# --- PASSO 8: CRIAR O BANCO DE DADOS ---
echo "--------------------------------------------------------"
echo "PASSO 8: Criando o banco de dados '$POSTGRES_DB_NAME'..."
echo "--------------------------------------------------------"
az postgres flexible-server db create `
    --resource-group $RESOURCE_GROUP `
    --server-name $POSTGES_SERVER_NAME `
    --database-name $POSTGRES_DB_NAME

# --- PASSO 9: CRIAR O PLANO DE SERVIÇO DE APLICATIVO ---
echo "--------------------------------------------------------"
echo "PASSO 9: Criando o Plano de Serviço (Gratuito)..."
echo "--------------------------------------------------------"
az appservice plan create `
    --name $APPSERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --sku F1 `
    --is-linux

# --- PASSO 10: CRIAR A APLICAÇÃO WEB (APP SERVICE) ---
echo "--------------------------------------------------------"
echo "PASSO 10: Criando a Aplicação Web..."
echo "--------------------------------------------------------"
az webapp create `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APPSERVICE_PLAN `
    --runtime "JAVA:17-java17"

# --- PASSO 11: CONFIGURAR A CONEXÃO COM O BANCO (SINTAXE CORRIGIDA) ---
echo "--------------------------------------------------------"
echo "PASSO 11: Configurando as variáveis de ambiente..."
echo "--------------------------------------------------------"
$DB_URL="jdbc:postgresql://$POSTGES_SERVER_NAME.postgres.database.azure.com:5432/$POSTGRES_DB_NAME?sslmode=require"
$DB_USER="$POSTGRES_ADMIN_USER@$POSTGES_SERVER_NAME"

# Comando corrigido para uma única linha para evitar erros de parsing do PowerShell
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --settings "SPRING_PROFILES_ACTIVE=prod" "DB_URL=$DB_URL" "DB_USER=$DB_USER" "DB_PASS=$POSTGRES_ADMIN_PASSWORD"

# --- PASSO 12: DEPLOY DA APLICAÇÃO JAVA ---
echo "--------------------------------------------------------"
echo "PASSO 12: Fazendo o deploy do arquivo .jar..."
echo "--------------------------------------------------------"
az webapp deploy `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --src-path "target/motolocation-0.0.1-SNAPSHOT.jar" `
    --type jar

echo "========================================================"
echo "DEPLOY FINALIZADO!"
echo "Aguarde 1-2 minutos para a aplicação iniciar na nuvem."
echo "Acesse sua aplicação em:"
echo "http://$WEBAPP_NAME.azurewebsites.net"
echo "========================================================"