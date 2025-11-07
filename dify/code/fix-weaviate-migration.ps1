# Script para resolver problema de migração do Weaviate 1.19 -> 1.27
# Issue: https://github.com/weaviate/weaviate/issues/9626

Write-Host "=== Fix Weaviate Migration Issue ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script irá remover os dados antigos do Weaviate para permitir recriação com o novo schema" -ForegroundColor Yellow
Write-Host ""
Write-Host "ATENÇÃO: Isso irá DELETAR todos os dados vetoriais existentes!" -ForegroundColor Red
Write-Host "Você precisará reimportar/reindexar seus documentos no Dify após isso." -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Tem certeza que deseja continuar? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Operação cancelada." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "1. Parando serviços..." -ForegroundColor Green
docker compose down

Write-Host ""
Write-Host "2. Removendo dados antigos do Weaviate..." -ForegroundColor Green
Remove-Item -Path ".\volumes\weaviate\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "3. Reiniciando com Weaviate 1.27.0..." -ForegroundColor Green
docker compose up -d

Write-Host ""
Write-Host "=== Migração Concluída ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Aguarde o Weaviate inicializar completamente"
Write-Host "2. No Dify, você precisará reindexar seus documentos/knowledge bases"
Write-Host "3. O Weaviate agora criará os índices com o novo schema compatível com 1.27.0"
Write-Host ""
Write-Host "Para verificar o status:" -ForegroundColor Cyan
Write-Host "  docker compose logs -f weaviate"
