# Chatwoot Custom - Instruções do Projeto

Este é um projeto Docker para customizar a imagem ghcr.io/fazer-ai/chatwoot:latest.

## Estrutura do Projeto

- `Dockerfile` - Imagem customizada baseada no Chatwoot
- `docker-compose.yml` - Configuração para desenvolvimento local
- `config/` - Arquivos de configuração personalizados
- `.dockerignore` - Arquivos a ignorar no build

## Comandos Principais

### Build e Deploy
```bash
# Build da imagem
docker build -t meu-chatwoot:latest .

# Executar localmente
docker-compose up -d

# Push para registry
docker push seu-usuario/chatwoot-custom:latest
```

## Notas de Desenvolvimento

- Base: ghcr.io/fazer-ai/chatwoot:latest
- Fonte: https://github.com/fazer-ai
