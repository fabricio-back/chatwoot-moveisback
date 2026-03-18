# 🔧 Build Completo com Assets Recompilados

Este guia mostra como fazer um **build completo** do Chatwoot com suas customizações e assets recompilados corretamente.

## 📋 Pré-requisitos

- Docker e Docker Compose
- Git
- 10GB de espaço em disco
- Boa conexão com internet

---

## 🚀 Opção 1: Build a partir do Source (Recomendado)

### 1. Clone o repositório original

```bash
# Em outro diretório (não neste projeto)
cd ..
git clone https://github.com/fazer-ai/ chatwoot.git chatwoot-source
cd chatwoot-source
```

### 2. Aplique as customizações

```bash
# Copie o arquivo modificado
cp "../chatwood - SalesHub/custom/ChatList.vue" app/javascript/dashboard/components/ChatList.vue

# Verifique se foi copiado corretamente
cat app/javascript/dashboard/components/ChatList.vue | grep "isAdmin"
```

### 3. Build da imagem

```bash
# Usando o Dockerfile oficial do Chatwoot
docker build \
  -f docker/Dockerfile \
  -t meu-chatwoot-custom:latest \
  .
```

⏱️ **Tempo estimado:** 20-40 minutos (primeira vez)

### 4. Atualize o docker-compose.yml

No arquivo `docker-compose.yml`, altere:

```yaml
services:
  rails:
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    image: meu-chatwoot-custom:latest  # <- Use sua imagem
    # ... resto
  
  sidekiq:
    image: meu-chatwoot-custom:latest  # <- Use sua imagem também
    # ... resto
```

### 5. Reinicie

```bash
docker compose down -v  # CUIDADO: apaga dados!
docker compose up -d
```

---

## 🎯 Opção 2: Dockerfile Multi-Stage

Mais eficiente se você vai fazer builds frequentes.

### 1. Crie `Dockerfile.full`

```dockerfile
# ========================================
# Stage 1: Clone e Build dos Assets
# ========================================
FROM node:20-alpine AS assets-builder

WORKDIR /build

# Instalar dependências do sistema
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    postgresql-dev

# Clonar repositório
ARG CHATWOOT_VERSION=latest
RUN git clone --depth 1 https://github.com/fazer-ai/chatwoot.git .

# Copiar customizações
COPY ./custom/ChatList.vue app/javascript/dashboard/components/ChatList.vue

# Instalar pnpm e dependências
RUN corepack enable && \
    corepack prepare pnpm@latest --activate

RUN pnpm install --frozen-lockfile

# Build dos assets
ENV NODE_ENV=production
ENV RAILS_ENV=production
RUN pnpm build

# ========================================
# Stage 2: Build da Aplicação Rails
# ========================================
FROM ghcr.io/fazer-ai/chatwoot:latest

# Copiar assets compilados
COPY --from=assets-builder /build/public/packs /app/public/packs
COPY --from=assets-builder /build/app/javascript /app/app/javascript

# Metadata
LABEL maintainer="seu-email@exemplo.com"
LABEL description="Chatwoot Custom - Build completo com assets"

WORKDIR /app
```

### 2. Build

```bash
docker build -f Dockerfile.full -t meu-chatwoot-custom:latest .
```

### 3. Use no docker-compose.yml (mesmo que Opção 1, passo 4)

---

## 🧪 Opção 3: Desenvolvimento Local (Teste Rápido)

Para testar rapidamente sem Docker:

### 1. Clone e configure

```bash
git clone https://github.com/fazer-ai/chatwoot.git
cd chatwoot
cp ../chatwood - SalesHub/custom/ChatList.vue app/javascript/dashboard/components/ChatList.vue
```

### 2. Instale dependências

```bash
# Ruby
bundle install

# Node
corepack enable
pnpm install
```

### 3. Configure banco de dados

```bash
cp .env.example .env
# Edite .env com suas configurações

# Setup database
bundle exec rails db:create
bundle exec rails db:schema:load
bundle exec rails db:seed
```

### 4. Inicie em modo desenvolvimento

```bash
# Terminal 1 - Rails
bundle exec rails server

# Terminal 2 - Vite (assets com hot-reload)
bin/vite dev

# Terminal 3 - Sidekiq
bundle exec sidekiq -C config/sidekiq.yml
```

Acesse: http://localhost:3000

Vite fará hot-reload automático quando você salvar mudanças!

---

## ✅ Verificar se Funcionou

### 1. Criar usuários de teste

```bash
# Admin
docker compose exec rails bundle exec rails runner "
  account = Account.create!(name: 'Test Account')
  admin = User.create!(
    email: 'admin@test.com',
    password: 'password123',
    name: 'Admin User',
    account: account,
    role: :administrator
  )
  AccountUser.create!(account: account, user: admin, role: :administrator)
"

# Agent
docker compose exec rails bundle exec rails runner "
  account = Account.first
  agent = User.create!(
    email: 'agent@test.com',
    password: 'password123',
    name: 'Agent User',
    account: account,
    role: :agent
  )
  AccountUser.create!(account: account, user: agent, role: :agent)
"
```

### 2. Teste no navegador

**Login como Admin (admin@test.com):**
- ✅ Deve ver: `All | Unassigned | Mine`

**Login como Agent (agent@test.com):**
- ✅ Deve ver: `Mine` (apenas)

### 3. Debug via Console do Navegador

```javascript
// Abrir DevTools (F12) > Console
// Verificar usuário atual
$chatwoot.store.getters.getCurrentUser
// { role: 'administrator' } ou { role: 'agent' }

// Verificar tabs renderizadas
document.querySelectorAll('[role="tab"]')
```

---

## 🐛 Troubleshooting

### Build falha com erro de memória

```bash
# Aumentar memória do Docker Desktop
# Settings > Resources > Memory: 8GB+

# Ou usar --memory flag
docker build --memory=8g -t meu-chatwoot-custom:latest .
```

### Assets não recompilam

```bash
# Limpar cache do Docker
docker builder prune -af

# Rebuild completo
docker compose build --no-cache
```

### pnpm install falha

```bash
# Limpar node_modules e lockfile
rm -rf node_modules pnpm-lock.yaml

# Reinstalar
pnpm install
```

---

## 📦 Push da Imagem Customizada

Depois do build bem-sucedido:

```bash
# Tag
docker tag meu-chatwoot-custom:latest seu-usuario/chatwoot-custom:v1.0

# Login
docker login  # ou docker login ghcr.io

# Push
docker push seu-usuario/chatwoot-custom:v1.0

# Ou para GHCR
docker tag meu-chatwoot-custom:latest ghcr.io/seu-usuario/chatwoot-custom:v1.0
docker push ghcr.io/seu-usuario/chatwoot-custom:v1.0
```

---

## 📊 Comparação das Opções

| Aspecto | Opção 1 (Source) | Opção 2 (Multi-stage) | Opção 3 (Dev Local) |
|---------|------------------|----------------------|---------------------|
| **Complexidade** | Média | Alta | Alta |
| **Tempo Build** | 30-40min | 20-30min (cache) | 5min (já tem deps) |
| **Para Produção** | ✅ Sim | ✅ Sim | ❌ Não |
| **Hot Reload** | ❌ Não | ❌ Não | ✅ Sim |
| **Recomendado para** | Deploy final | CI/CD | Desenvolvimento |

---

## 🎯 Próximos Passos

1. ✅ Escolha uma opção (recomendo Opção 1 para primeira vez)
2. ✅ Faça o build completo
3. ✅ Teste com usuários admin e agent
4. ✅ Faça push da imagem (opcional)
5. ✅ Use em produção

---

**Sucesso! 🎉** Sua customização agora funciona corretamente com assets recompilados.
