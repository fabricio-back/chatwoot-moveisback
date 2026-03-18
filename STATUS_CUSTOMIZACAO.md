# ⚠️ Status da Customização - ChatList.vue

## ✅ O que foi feito

1. **Arquivo modificado:** [custom/ChatList.vue](custom/ChatList.vue)
2. **Lógica implementada:** Abordagem 2 (computed property)
3. **Dockerfile atualizado:** Copia o arquivo durante o build
4. **Imagem rebuilded:** `meu-chatwoot:latest`

### Código Adicionado

```js
// Computed property para verificar se é admin
const isAdmin = computed(() => {
  return currentUser.value?.role === 'administrator';
});

// assigneeTabItems modificado para filtrar tabs
const assigneeTabItems = computed(() => {
  const allTabs = filterItemsByPermission(
    ASSIGNEE_TYPE_TAB_PERMISSIONS,
    userPermissions.value,
    item => item.permissions
  ).map(({ key, count: countKey }) => ({
    key,
    name: t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
    count: conversationStats.value[countKey] || 0,
  }));
  
  // Oculta abas "All" e "Unassigned" para não-administradores
  if (isAdmin.value) {
    return allTabs;
  }
  
  return allTabs.filter(
    tab => tab.key !== 'all' && tab.key !== 'unassigned'
  );
});
```

---

## ⚠️ IMPORTANTE: Limitação de Assets Pré-Compilados

### O Problema

A imagem `ghcr.io/fazer-ai/chatwoot:latest` vem com **assets frontend pré-compilados** (JavaScript/CSS já bundled via Vite). Simplesmente copiar o arquivo `.vue` **NÃO recompila automaticamente** os assets.

### Por que não funciona imediatamente?

1. Os arquivos `.vue` são compilados em JavaScript durante o build
2. O container de produção **não tem** Node.js/pnpm instalados
3. Os assets compilados estão em `/app/public/packs/` (imutáveis)

---

## ✅ Soluções Possíveis

### Opção 1: Build Completo do Chatwoot (Recomendado para Produção)

**Vantagens:** Funciona 100%, profissional
**Desvantagens:** Mais complexo, leva mais tempo

#### Passos:

1. **Clone o repositório original:**
```bash
git clone https://github.com/fazer-ai/chatwoot.git
cd chatwoot
```

2. **Aplique sua modificação:**
```bash
# Copie o ChatList.vue modificado
cp ../custom/ChatList.vue app/javascript/dashboard/components/ChatList.vue
```

3. **Build da imagem completa:**
```bash
# Edite docker/Dockerfile se necessário
docker build -t seu-usuario/chatwoot-custom:latest -f docker/Dockerfile .
```

4. **Use sua imagem no docker-compose.yml:**
```yaml
services:
  rails:
    image: seu-usuario/chatwoot-custom:latest
    # ... resto da config
```

---

### Opção 2: Build Multi-Stage Dockerfile (Intermediário)

Crie um `Dockerfile.custom`:

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Clone e instale dependências
RUN apk add --no-cache git
RUN git clone https://github.com/fazer-ai/chatwoot.git .

# Copie modificações
COPY ./custom/ChatList.vue /app/app/javascript/dashboard/components/ChatList.vue

# Instale deps e compile
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install
RUN pnpm build

# Stage 2: Runtime
FROM ghcr.io/fazer-ai/chatwoot:latest

# Copie assets compilados do builder
COPY --from=builder /app/public/packs /app/public/packs
COPY --from=builder /app/app/javascript/dashboard/components/ChatList.vue /app/app/javascript/dashboard/components/ChatList.vue
```

Build:
```bash
docker build -f Dockerfile.custom -t meu-chatwoot-custom:latest .
```

---

### Opção 3: Hot Reload com Vite (Apenas Desenvolvimento)

**Para desenvolvimento local:**

1. Clone o repo completo do Chatwoot
2. Edite `app/javascript/dashboard/components/ChatList.vue`
3. Execute em modo desenvolvimento:
```bash
bin/setup
foreman start -f Procfile.dev
```

Vite fará hot-reload automático das mudanças.

---

### Opção 4: Patch em Runtime (Hack - NÃO recomendado)

Modificar o JavaScript compilado diretamente:

```bash
# Localizar o bundle compilado
docker compose exec rails find /app/public/packs -name "*.js" -exec grep -l "ASSIGNEE_TYPE_TABS" {} \;

# Editar manualmente (MUITO arriscado e temporário)
docker compose exec rails vi /app/public/packs/js/xxx.js
```

❌ **NÃO RECOMENDADO:** Mudanças serão perdidas no próximo restart.

---

## 🎯 Recomendação Final

### Para Produção:
Use **Opção 1** (Build completo do source) ou **Opção 2** (Multi-stage Dockerfile)

### Para Teste Rápido:
Use **Opção 3** (Desenvolvimento local com Vite)

---

## 📝 Próximos Passos

1. **Escolher qual abordagem seguir** (recomendo Opção 1 ou 2)
2. **Fazer o build completo** com assets recompilados
3. **Testar:**
   - Login como admin → deve ver "All | Unassigned | Mine"
   - Login como agent → deve ver apenas "Mine"

---

## 🔍 Como Verificar se Funcionou

```bash
# 1. Abrir DevTools do navegador (F12)
# 2. Console > digitar:
window.$chatwoot.store.getters.getCurrentUser

# 3. Verificar a role:
# { id: ..., role: 'administrator' } ou { id: ..., role: 'agent' }

# 4. Verificar se as tabs estão sendo filtradas:
# Admin vê: All, Unassigned, Mine
# Agent vê: Mine
```

---

## 📚 Referências

- [Chatwoot Build Process](https://www.chatwoot.com/docs/contributing-guide/project-setup)
- [Vite Documentation](https://vitejs.dev/)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

## ✅ Arquivos Criados/Modificados

- ✅ [custom/ChatList.vue](custom/ChatList.vue) - Componente modificado
- ✅ [Dockerfile](Dockerfile) - Atualizado com COPY
- ✅ Este documento (STATUS_CUSTOMIZACAO.md)

---

**Status Atual:** ⚠️ Código modificado mas **assets não recompilados**  
**Ação Necessária:** Escolher Opção 1 ou 2 e fazer build completo
