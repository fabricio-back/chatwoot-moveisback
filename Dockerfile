# Dockerfile customizado para Chatwoot
FROM ghcr.io/fazer-ai/chatwoot:latest

# Metadata
LABEL maintainer="seu-email@exemplo.com"
LABEL description="Chatwoot customizado - Abas All/Unassigned ocultas para agentes"

# ==========================================
# CUSTOMIZAÇÕES DO FRONTEND
# ==========================================

# Copiar componente ChatList.vue modificado
# Oculta abas "All" e "Unassigned" para usuários não-administradores
COPY ./custom/ChatList.vue /app/app/javascript/dashboard/components/ChatList.vue

# ==========================================
# CUSTOMIZAÇÕES ADICIONAIS (OPCIONAL)
# ==========================================

# Atualizar sistema e instalar pacotes adicionais (se necessário)
# RUN apt-get update && apt-get install -y \
#     vim \
#     curl \
#     && rm -rf /var/lib/apt/lists/*

# Copiar outros arquivos de configuração customizados
# COPY ./config/custom-config.yml /app/config/

# Variáveis de ambiente personalizadas
# ENV RAILS_ENV=production
# ENV NODE_ENV=production
# ENV CUSTOM_FEATURE_FLAG=true

# Expor portas (já expostas na imagem base, mas você pode adicionar outras)
# EXPOSE 3000

# Criar diretórios adicionais se necessário
# RUN mkdir -p /app/custom_data

# Copiar scripts customizados
# COPY ./scripts /app/scripts
# RUN chmod +x /app/scripts/*.sh

# Healthcheck customizado (opcional)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
#   CMD curl -f http://localhost:3000/health || exit 1

# Comando de inicialização (usar o padrão da imagem base)
# CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
