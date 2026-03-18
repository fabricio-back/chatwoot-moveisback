# 🚀 Guia de Início Rápido - Chatwoot Customizado

## ✅ O que foi configurado?

Agora você tem um setup **completo** do Chatwoot com:

### Serviços Rodando:
1. **Rails** (`chatwoot-rails`) - Aplicação principal em http://localhost:3000
2. **Sidekiq** (`chatwoot-sidekiq`) - Workers para tarefas em background
3. **PostgreSQL** (`chatwoot-postgres`) - Banco de dados com pgvector
4. **Redis** (`chatwoot-redis`) - Cache e fila de jobs
5. **Baileys API** (`chatwoot-baileys`) - Integração WhatsApp

### Volumes Persistentes:
- `storage` - Anexos, uploads, dados do WhatsApp
- `postgres` - Dados do banco
- `redis` - Dados do cache

---

## 📦 Próximos Passos

### 1. Aguarde a aplicação iniciar (2-3 minutos na primeira vez)

```bash
# Acompanhar logs
docker compose logs -f rails
```

Aguarde até ver:
```
Puma starting in single mode...
* Listening on http://0.0.0.0:3000
```

### 2. Acesse o Chatwoot

Abra no navegador: **http://localhost:3000**

### 3. Criar conta admin

Na primeira vez, você precisará criar uma conta de administrador via interface web.

---

## 🎨 Customizar o Frontend

Veja o guia completo: [CUSTOMIZAR_FRONTEND.md](CUSTOMIZAR_FRONTEND.md)

**Resumo rápido:**

1. Prepare seus assets (logo.png, logo_thumbnail.png, banner.png)
2. Empacote em ZIP
3. Hospede em algum lugar acessível
4. Configure no `.env`:
```env
BRAND_ASSETS_URL=https://seusite.com/brand-assets.zip
```
5. Reinicie:
```bash
docker compose restart rails
```

---

## 🔑 Gerar SECRET_KEY_BASE segura

```bash
docker compose exec rails bundle exec rake secret
```

Copie o resultado e cole no `.env`:
```env
SECRET_KEY_BASE=resultado_do_comando_aqui
```

---

## 📧 Configurar Email (Opcional)

No `.env`, adicione suas credenciais do Resend:

```env
MAILER_SENDER_EMAIL=seu-email@dominio.com
RESEND_API_KEY=sua_chave_api_aqui
```

Reinicie:
```bash
docker compose restart rails sidekiq
```

---

## 📱 Configurar WhatsApp (Opcional)

O Baileys API já está rodando! Para conectar:

1. Acesse http://localhost:3000
2. Vá em **Settings** → **Inboxes** → **Add Inbox**
3. Selecione **WhatsApp**
4. Escolha **Cloud API** ou **On-Premise**
5. Siga as instruções na tela

---

## 🛠️ Comandos Úteis

```bash
# Ver todos os containers
docker compose ps

# Ver logs de todos os serviços
docker compose logs -f

# Ver logs de apenas um serviço
docker compose logs -f rails
docker compose logs -f sidekiq
docker compose logs -f postgres

# Reiniciar um serviço específico
docker compose restart rails

# Parar tudo
docker compose down

# Parar e remover volumes (CUIDADO: apaga dados!)
docker compose down -v

# Reconstruir imagem
docker compose build --no-cache

# Acessar console Rails
docker compose exec rails bundle exec rails console

# Acessar bash do container
docker compose exec rails bash

# Executar migrations
docker compose exec rails bundle exec rails db:migrate

# Ver status do Sidekiq
docker compose exec sidekiq ps aux | grep sidekiq
```

---

## 🐛 Troubleshooting

### Container reiniciando constantemente?

```bash
docker compose logs rails --tail 50
```

### Banco de dados não conecta?

```bash
# Verificar se PostgreSQL está healthy
docker compose ps postgres

# Ver logs
docker compose logs postgres
```

### Redis com problemas?

```bash
# Testar conexão
docker compose exec redis redis-cli ping
```

### WhatsApp não conecta?

```bash
# Ver logs do Baileys
docker compose logs baileys-api
```

### Resetar tudo e começar do zero:

```bash
# CUIDADO: Isso apaga TODOS os dados!
docker compose down -v
docker compose up -d
```

---

## 📦 Deploy em Produção

### 1. Atualizar variáveis de ambiente

Edite `.env` com valores de produção:
- Senhas seguras para Postgres e Redis
- SECRET_KEY_BASE gerada
- FRONTEND_URL com seu domínio real
- Configurações de email

### 2. Build da imagem

```bash
docker compose build --no-cache
```

### 3. Tag e Push

```bash
# Docker Hub
docker tag meu-chatwoot:latest seu-usuario/chatwoot-custom:latest
docker push seu-usuario/chatwoot-custom:latest

# GitHub Container Registry (GHCR)
docker tag meu-chatwoot:latest ghcr.io/seu-usuario/chatwoot-custom:latest
docker push ghcr.io/seu-usuario/chatwoot-custom:latest
```

### 4. Deploy no servidor

```bash
# No servidor de produção
git clone seu-repo
cd seu-repo
cp .env.example .env
# Edite o .env com valores de produção
docker compose up -d
```

---

## 📊 Monitoramento

### Verificar saúde dos serviços:

```bash
docker compose ps
```

Todos devem estar **healthy** após ~1 minuto.

### Métricas de uso:

```bash
# CPU e memória
docker stats

# Espaço em disco dos volumes
docker system df -v
```

---

## 🔒 Segurança

**ANTES DE IR PARA PRODUÇÃO:**

- [ ] Altere todas as senhas padrão
- [ ] Gere uma SECRET_KEY_BASE única
- [ ] Configure HTTPS/SSL (use Nginx ou Caddy como proxy reverso)
- [ ] Configure firewall (apenas portas 80/443 expostas)
- [ ] Configure backups automáticos
- [ ] Ative 2FA para contas admin
- [ ] Revise permissões de acesso

---

## 📚 Recursos

- [README.md](README.md) - Documentação geral
- [CUSTOMIZAR_FRONTEND.md](CUSTOMIZAR_FRONTEND.md) - Guia de branding
- [Documentação Oficial](https://www.chatwoot.com/docs)
- [GitHub fazer-ai](https://github.com/fazer-ai)

---

## 🆘 Precisa de Ajuda?

1. Verifique os logs: `docker compose logs -f`
2. Consulte a documentação oficial
3. Abra uma issue no repositório

---

**Feito! 🎉 Seu Chatwoot customizado está pronto para usar!**
