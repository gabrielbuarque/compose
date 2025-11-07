#!/bin/bash
# Script para resolver problema de migração do Weaviate 1.19 -> 1.27
# Issue: https://github.com/weaviate/weaviate/issues/9626

echo "=== Fix Weaviate Migration Issue ==="
echo "Este script irá remover os dados antigos do Weaviate para permitir recriação com o novo schema"
echo ""
echo "ATENÇÃO: Isso irá DELETAR todos os dados vetoriais existentes!"
echo "Você precisará reimportar/reindexar seus documentos no Dify após isso."
echo ""
read -p "Tem certeza que deseja continuar? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo "1. Parando serviços..."
docker compose down

echo ""
echo "2. Removendo dados antigos do Weaviate..."
rm -rf ./volumes/weaviate/*

echo ""
echo "3. Reiniciando com Weaviate 1.27.0..."
docker compose up -d

echo ""
echo "=== Migração Concluída ==="
echo ""
echo "Próximos passos:"
echo "1. Aguarde o Weaviate inicializar completamente"
echo "2. No Dify, você precisará reindexar seus documentos/knowledge bases"
echo "3. O Weaviate agora criará os índices com o novo schema compatível com 1.27.0"
echo ""
echo "Para verificar o status:"
echo "  docker compose logs -f weaviate"
