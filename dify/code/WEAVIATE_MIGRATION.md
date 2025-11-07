# Solução para Erro de Migração do Weaviate 1.19.0 → 1.27.0

## Problema

Ao atualizar o Weaviate de 1.19.0 para 1.27.0, você pode encontrar o seguinte erro:

```
Query call with protocol GRPC search failed with message extract target vectors: 
class Vector_index_xxx does not have named vector default configured. 
Available named vectors map[].
```

**Causa**: O Weaviate 1.27.0 mudou a estrutura do schema de vetores:
- **Antes (1.19)**: `vectorIndexConfig`, `vectorIndexType`, `vectorizer`
- **Agora (1.27)**: `vectorConfig.default.vectorIndexConfig`, `vectorConfig.default.vectorIndexType`, `vectorConfig.default.vectorizer`

Os dados criados na versão 1.19.0 não são automaticamente migrados para o novo formato.

**Referência**: [Weaviate Issue #9626](https://github.com/weaviate/weaviate/issues/9626)

## Soluções

### Opção 1: Limpar e Recriar (Recomendado para desenvolvimento)

Se você pode reimportar seus dados no Dify:

#### Windows (PowerShell):
```powershell
.\fix-weaviate-migration.ps1
```

#### Linux/Mac:
```bash
chmod +x fix-weaviate-migration.sh
./fix-weaviate-migration.sh
```

Este script irá:
1. Parar todos os containers
2. Remover dados antigos do Weaviate (`./volumes/weaviate/`)
3. Reiniciar com Weaviate 1.27.0
4. O Weaviate criará novos índices com o schema correto

**Após executar**: No Dify, você precisará reindexar seus documentos/knowledge bases.

### Opção 2: Manter Versão Antiga (Temporário)

Se você **não pode** perder os dados e precisa de tempo para planejar a migração:

```yaml
# Em docker-compose.yaml, volte para:
weaviate:
  image: semitechnologies/weaviate:1.19.0
```

**Desvantagem**: Você não terá acesso às novas funcionalidades do Weaviate 1.27.0.

### Opção 3: Migração Manual (Avançado)

Para produção com dados importantes, você pode:

1. **Fazer backup dos dados**:
   ```bash
   docker compose exec weaviate curl -X POST \
     "http://localhost:8080/v1/backups/filesystem" \
     -H "Content-Type: application/json" \
     -d '{"id": "pre-migration-backup"}'
   ```

2. **Exportar dados via API do Dify** antes de limpar

3. **Limpar volumes do Weaviate**

4. **Reimportar dados** - eles serão criados com o novo schema

## Comandos Úteis

### Verificar status do Weaviate:
```bash
docker compose logs -f weaviate
```

### Verificar schema de uma classe:
```bash
docker compose exec weaviate curl -s \
  "http://localhost:8080/v1/schema/Vector_index_<ID>_Node" \
  -H "Authorization: Bearer WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih"
```

### Listar todas as classes:
```bash
docker compose exec weaviate curl -s \
  "http://localhost:8080/v1/schema" \
  -H "Authorization: Bearer WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih"
```

### Deletar uma classe específica (cuidado!):
```bash
docker compose exec weaviate curl -X DELETE \
  "http://localhost:8080/v1/schema/Vector_index_<ID>_Node" \
  -H "Authorization: Bearer WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih"
```

## Prevenção Futura

Para evitar esse problema em futuras atualizações:

1. **Sempre faça backup antes de atualizar** versões maiores do Weaviate
2. **Teste em ambiente de desenvolvimento** primeiro
3. **Leia as release notes** do Weaviate para breaking changes
4. **Use o mesmo processo de migração** quando atualizar o Dify

## Status da Issue

Esta é uma **issue conhecida** do Weaviate. A equipe está ciente, mas ainda não há migração automática.

- Issue: https://github.com/weaviate/weaviate/issues/9626
- Relacionado com Dify: https://github.com/langgenius/dify/issues/27291
