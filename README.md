# Chatwoot Custom

Imagem Docker customizada baseada em [ghcr.io/fazer-ai/chatwoot:latest](https://github.com/fazer-ai)

## 📋 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+

## 🚀 Início Rápido

### 1. Configure as variáveis de ambiente

```bash
# Já existe um .env pronto! Edite se necessário:
code .env

# OU copie do exemplo:
cp .env.example .env
```

**Variáveis importantes:**
- `SECRET_KEY_BASE` - Gere uma chave segura (veja abaixo)
- `BRAND_ASSETS_URL` - URL dos seus assets customizados (opcional)
- `FRONTEND_URL` - URL do seu Chatwoot

### 2. Gerar SECRET_KEY_BASE (recomendado)

```bash
# Executar após iniciar pela primeira vez
docker compose exec rails bundle exec rake secret

# Copie o resultado e cole no arquivo .env
```

### 3. Executar

```bash
# Iniciar todos os serviços
docker compose up -d

# Ver logs
docker compose logs -f
```

Aguarde 2-3 minutos na primeira vez. Acesse: **http://localhost:3000**

## 📦 Serviços Incluídos

| Serviço | Container | Função | Porta |
|---------|-----------|--------|-------|
| **Rails** | `chatwoot-rails` | Aplicação principal | 3000 |
| **Sidekiq** | `chatwoot-sidekiq` | Workers/jobs | - |
| **PostgreSQL** | `chatwoot-postgres` | Banco de dados | 5432 |
| **Redis** | `chatwoot-redis` | Cache e filas | 6379 |
| **Baileys API** | `chatwoot-baileys` | WhatsApp (opcional) | 3025 |

## 🎨 Customizar o Frontend

### ✅ Customização Implementada e Ativa!

**Status:** 🟢 **FUNCIONANDO** com assets recompilados

**Imagem:** `meu-chatwoot-custom:v1.0`

#### Funcionalidade: Abas Ocultas para Agentes
- ✅ **Abas "All" e "Unassigned" ocultas para agentes**
- ✅ **Apenas administradores podem ver todas as conversas**
- ✅ **Agentes veem apenas "Mine" (suas conversas)**

**Arquivo modificado:** [custom/ChatList.vue](custom/ChatList.vue)  
**Build completo:** [BUILD_SUCESSO.md](BUILD_SUCESSO.md) ⭐  
**Como testar:** Veja instruções completas em [BUILD_SUCESSO.md](BUILD_SUCESSO.md#-como-testar)

---

### Branding (Logo, Cores, etc)

**Resumo:**
1. Prepare assets (logo.png, logo_thumbnail.png, banner.png)
2. Empacote em ZIP
3. Hospede online
4. Configure `BRAND_ASSETS_URL` no `.env`
5. Reinicie: `docker compose restart rails`

## 🛠️ Comandos Úteis

### Gerenciamento básico

```bash
# Status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f rails

# Parar serviços
docker compose down

# Reiniciar serviço específico
docker compose restart rails
```

### Build e Deploy

```bash
# Reconstruir imagem
docker compose build --no-cache

# Build e iniciar
docker compose up -d --build
```

### Manutenção

```bash
# Acessar console Rails
docker compose exec rails bundle exec rails console

# Executar migrations
docker compose exec rails bundle exec rails db:migrate

# Limpar tudo (CUIDADO: apaga dados!)
docker compose down -v
```

## 📤 Fazer Push da Sua Imagem

### Docker Hub

```bash
# Build
docker compose build

# Login
docker login

# Tag
docker tag meu-chatwoot:latest seu-usuario/chatwoot-custom:latest

# Push
docker push seu-usuario/chatwoot-custom:latest
```

### GitHub Container Registry (GHCR)

```bash
# Login (crie um Personal Access Token no GitHub primeiro)
echo $GITHUB_TOKEN | docker login ghcr.io -u seu-usuario --password-stdin

# Tag
docker tag meu-chatwoot:latest ghcr.io/seu-usuario/chatwoot-custom:latest

# Push
docker push ghcr.io/seu-usuario/chatwoot-custom:latest
```

**Tornar pública:**
1. https://github.com/seu-usuario?tab=packages
2. Selecione `chatwoot-custom`
3. Package settings → Change visibility → Public

## 📂 Estrutura do Projeto

```
.
├── Dockerfile                    # Imagem customizada
├── docker-compose.yml            # Orquestração (5 serviços)
├── .dockerignore                 # Otimização de build
├── .env                          # Variáveis de ambiente (NÃO COMMITAR!)
├── .env.example                  # Template das variáveis
├── .gitignore                    # Proteção de secrets
│
├── README.md                     # Esta documentação
├── INICIO_RAPIDO.md              # Guia de início rápido
├── CUSTOMIZAR_FRONTEND.md        # Guia de branding
│
├── config/                       # Configurações personalizadas
│   └── exemplo.yml
│
└── .github/
    └── copilot-instructions.md
```

## 🔍 Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker compose logs rails --tail 100

# Verificar saúde dos serviços
docker compose ps
```

### Banco de dados com problemas

```bash
# Verificar PostgreSQL
docker compose logs postgres

# Resetar banco (CUIDADO: apaga tudo!)
docker compose down -v
docker compose up -d
```

### Assets customizados não aparecem

```bash
# Ver se baixou
docker compose exec rails ls -la /app/public/brand-assets/

# Forçar re-download
docker compose exec rails rm -rf /app/public/brand-assets/*
docker compose restart rails
```

### WhatsApp não conecta

```bash
# Ver logs do Baileys API
docker compose logs baileys-api

# Verificar se está healthy
docker compose ps baileys-api
```

## 🔒 Segurança - Checklist de Produção

Antes de usar em produção:

- [ ] Alterar todas as senhas padrão (`POSTGRES_PASSWORD`, `REDIS_PASSWORD`)
- [ ] Gerar `SECRET_KEY_BASE` única
- [ ] Configurar SSL/HTTPS (usar proxy reverso: Nginx/Caddy)
- [ ] Restringir portas no firewall (apenas 80/443 públicas)
- [ ] Configurar backups automáticos dos volumes
- [ ] Ativar autenticação de 2 fatores
- [ ] Revisar permissões de usuários
- [ ] Configurar monitoramento (logs, métricas)

## 📧 Configurar Email

No `.env`:

```env
MAILER_SENDER_EMAIL=noreply@seudominio.com
RESEND_API_KEY=re_xxxxxxxxxxxxx
```

Depois: `docker compose restart rails sidekiq`

## 📚 Documentação

- **[INICIO_RAPIDO.md](INICIO_RAPIDO.md)** - Guia completo passo a passo
- **[CUSTOMIZAR_FRONTEND.md](CUSTOMIZAR_FRONTEND.md)** - Branding e assets
- [Documentação Oficial](https://www.chatwoot.com/docs)
- [Repositório fazer-ai](https://github.com/fazer-ai)

## 📝 Notas

- **Base**: `ghcr.io/fazer-ai/chatwoot:latest`
- **Fonte**: https://github.com/fazer-ai
- Não commite o arquivo `.env` (já está no `.gitignore`)
- Use `.env.example` como referência
- Teste localmente antes de fazer deploy

## 🆘 Precisa de Ajuda?

1. Consulte [INICIO_RAPIDO.md](INICIO_RAPIDO.md)
2. Verifique os logs: `docker compose logs -f`
3. Veja [issues do projeto original](https://github.com/fazer-ai)

## 📄 Licença

Veja a licença do projeto original: https://github.com/fazer-ai

---

**🎉 Pronto! Seu Chatwoot customizado está configurado!**

Para começar: `docker compose up -d` e acesse http://localhost:3000
