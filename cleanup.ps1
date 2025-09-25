# ===================================================================
# Script de Limpeza - Apaga TODOS os recursos criados na Azure
# ===================================================================

$RM="555317"
$RESOURCE_GROUP="rg-motolocation-$RM"

echo "--------------------------------------------------------"
echo "Fazendo login na Azure..."
echo "--------------------------------------------------------"
az login

echo "--------------------------------------------------------"
echo "ATENÇÃO: O GRUPO DE RECURSOS '$RESOURCE_GROUP' E TUDO DENTRO DELE SERÁ PERMANENTEMENTE APAGADO."
echo "--------------------------------------------------------"

az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "========================================================"
echo "Comando de exclusão enviado. A limpeza pode levar alguns minutos na Azure."
echo "========================================================"