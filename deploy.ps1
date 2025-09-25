# ===================================================================
# Script de Deploy COMPLETO e Autossuficiente - Mottu Location
# Compila, registra serviços, cria a infraestrutura e faz o deploy.
# ===================================================================

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
$RM="555317" # Seu RM para garantir nomes únicos
$RESOURCE_GROUP="rg-motolocation-$RM"
$LOCATION="eastus"
$APPSERVICE_PLAN="plan-motolocation-$RM"
$POSTGRES_SERVER_NAME="pgsrv-motolocation-$RM"
$POSTGRES_DB_NAME="motolocation"
$POSTGRES_ADMIN_USER="mottuadmin"
$POSTGRES_ADMIN_PASSWORD="Challenge_FIAP_2025!" # Senha forte já definida
$WEBAPP_NAME="webapp-motolocation-$RM" # Nome globalmente único

# --- PASSO 2: COMPILAR A APLICAÇÃO JAVA ---
echo "--------------------------------------------------------"
echo "PASSO 2: Limpando builds antigos (mvn clean) e compilando a aplicação (mvn package)..."
echo "--------------------------------------------------------"
./mvnw clean package -DskipTests

# --- PASSO 3: LOGIN NA AZURE ---
echo "--------------------------------------------------------"
echo "PASSO 3: Fazendo login na Azure..."
echo "--------------------------------------------------------"
az login

# --- PASSO 4: REGISTRAR OS PROVEDORES DE SERVIÇO ---
echo "--------------------------------------------------------"
echo "PASSO 4: Registrando os provedores de serviço na Azure..."
echo "--------------------------------------------------------"
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Web

# --- PASSO 5: CRIAR O GRUPO DE RECURSOS ---
echo "--------------------------------------------------------"
echo "PASSO 5: Criando o Grupo de Recursos: $RESOURCE_GROUP"
echo "--------------------------------------------------------"
az group create --name $RESOURCE_GROUP --location $LOCATION

# --- PASSO 6: CRIAR O SERVIDOR POSTGRESQL ---
echo "--------------------------------------------------------"
echo "PASSO 6: Criando o Servidor PostgreSQL: $POSTGRES_SERVER_NAME."
echo "(Esta etapa pode levar de 5 a 10 minutos...)"
echo "--------------------------------------------------------"
az postgres flexible-server create `
    --resource-group $RESOURCE_GROUP `
    --name $POSTGRES_SERVER_NAME `
    --location $LOCATION `
    --admin-user $POSTGRES_ADMIN_USER `
    --admin-password $POSTGRES_ADMIN_PASSWORD `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --public-access 0.0.0.0 `
    --storage-size 32 `
    --version 15

# --- PASSO 7: CRIAR O BANCO DE DADOS ---
echo "--------------------------------------------------------"
echo "PASSO 7: Criando o banco de dados '$POSTGRES_DB_NAME'..."
echo "--------------------------------------------------------"
az postgres flexible-server db create `
    --resource-group $RESOURCE_GROUP `
    --server-name $POSTGRES_SERVER_NAME `
    --database-name $POSTGRES_DB_NAME

# --- PASSO 8: CRIAR O PLANO DE SERVIÇO DE APLICATIVO ---
echo "--------------------------------------------------------"
echo "PASSO 8: Criando o Plano de Serviço (Gratuito)..."
echo "--------------------------------------------------------"
az appservice plan create `
    --name $APPSERVICE_PLAN `
    --resource-group $RESOURCE_GROUP `
    --sku F1 `
    --is-linux

# --- PASSO 9: CRIAR A APLICAÇÃO WEB (APP SERVICE) ---
echo "--------------------------------------------------------"
echo "PASSO 9: Criando a Aplicação Web..."
echo "--------------------------------------------------------"
az webapp create `
    --name $WEBAPP_NAME `
    --resource-group $RESOURCE_GROUP `
    --plan $APPSERVICE_PLAN `
    --runtime "JAVA:17-java17"

# --- PASSO 10: CONFIGURAR A CONEXÃO COM O BANCO ---
echo "--------------------------------------------------------"
echo "PASSO 10: Configurando as variáveis de ambiente na aplicação..."
echo "--------------------------------------------------------"
$DB_URL="jdbc:postgresql://$POSTGRES_SERVER_NAME.postgres.database.azure.com:5432/$POSTGRES_DB_NAME?sslmode=require"
$DB_USER="$POSTGRES_ADMIN_USER@$POSTGRES_SERVER_NAME"

az webapp config appsettings set `
    --resource-group $RESOURCE_GROUP `
    --name $WEBAPP_NAME `
    --settings `
        "SPRING_PROFILES_ACTIVE=prod" `
        "DB_URL=$DB_URL" `
        "DB_USER=$DB_USER" `
        "DB_PASS=$POSTGRES_ADMIN_PASSWORD"

# --- PASSO 11: DEPLOY DA APLICAÇÃO JAVA ---
echo "--------------------------------------------------------"
echo "PASSO 11: Fazendo o deploy do arquivo .jar para o App Service..."
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