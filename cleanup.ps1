# ===================================================================
# Script de Limpeza - Apaga TODOS os recursos criados na Azure
# ===================================================================

# --- PASSO 1: DEFINIÇÃO DE VARIÁVEIS ---
# Garanta que estes valores são os mesmos do seu script de deploy.
$RM="555317"
$RESOURCE_GROUP="rg-motolocation-$RM"

# --- PASSO 2: LOGIN NA AZURE ---
echo "--------------------------------------------------------"
echo "PASSO 2: Fazendo login na Azure..."
echo "--------------------------------------------------------"
az login

# --- PASSO 3: DELETAR O GRUPO DE RECURSOS ---
# Este comando é DESTRUTIVO e vai apagar tudo dentro do grupo.
echo "--------------------------------------------------------"
echo "ATENÇÃO: O GRUPO DE RECURSOS '$RESOURCE_GROUP' E TUDO DENTRO DELE SERÁ PERMANENTEMENTE APAGADO."
echo "--------------------------------------------------------"

az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "========================================================"
echo "Comando de exclusão enviado."
echo "A limpeza está acontecendo em segundo plano na Azure e pode levar alguns minutos."
echo "Você pode verificar o status no Portal da Azure."
echo "========================================================"