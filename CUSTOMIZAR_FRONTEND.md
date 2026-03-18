# 🎨 Como Customizar o Frontend do Chatwoot

## 📦 Método 1: BRAND_ASSETS_URL (Recomendado)

### 1. Prepare seus assets

Crie uma pasta com seus arquivos customizados:

```
brand-assets/
├── logo.png            # Logo principal (recomendado: 200x50px)
├── logo_thumbnail.png  # Favicon/ícone (recomendado: 32x32px)
└── banner.png          # Banner de login (recomendado: 1200x600px)
```

### 2. Empacote os assets

```bash
# Crie um arquivo ZIP
zip -r brand-assets.zip brand-assets/

# Ou TAR.GZ
tar -czf brand-assets.tar.gz brand-assets/
```

### 3. Hospede o arquivo

Opções:
- GitHub Releases
- AWS S3
- Servidor web próprio
- Dropbox/Google Drive (link direto de download)

### 4. Configure a variável de ambiente

No arquivo `.env`:

```env
BRAND_ASSETS_URL=https://seusite.com/brand-assets.zip
```

### 5. Reinicie os containers

```bash
docker compose down
docker compose up -d
```

Os assets serão extraídos automaticamente para `/app/public/brand-assets/`

---

## 🔧 Método 2: Copiar Assets via Dockerfile

Edite o `Dockerfile`:

```dockerfile
FROM ghcr.io/fazer-ai/chatwoot:latest

# Copiar assets personalizados
COPY ./brand-assets/logo.png /app/public/brand-assets/logo.png
COPY ./brand-assets/logo_thumbnail.png /app/public/brand-assets/logo_thumbnail.png
COPY ./brand-assets/banner.png /app/public/brand-assets/banner.png

# Rebuild a aplicação com os novos assets
RUN bundle exec rails assets:precompile
```

Reconstrua a imagem:

```bash
docker compose build --no-cache
docker compose up -d
```

---

## 🎨 Método 3: Customização via Interface Admin

1. Acesse http://localhost:3000
2. Faça login como admin
3. Vá em **Settings** → **Branding**
4. Faça upload de:
   - Logo
   - Favicon
   - Banner de login

---

## 📝 Estrutura dos Assets

### Logo Principal (`logo.png`)
- **Formato**: PNG com transparência
- **Tamanho recomendado**: 200x50px
- **Usado em**: Header, emails, interface

### Logo Thumbnail (`logo_thumbnail.png`)
- **Formato**: PNG ou ICO
- **Tamanho**: 32x32px ou 64x64px
- **Usado em**: Favicon, ícone do app

### Banner (`banner.png`)
- **Formato**: PNG ou JPG
- **Tamanho recomendado**: 1200x600px
- **Usado em**: Página de login/cadastro

---

## 🚀 Exemplo Completo

### 1. Crie o `.env`:

```env
# Branding
BRAND_ASSETS_URL=https://github.com/seu-usuario/seu-repo/releases/download/v1.0/brand-assets.zip

# Outros
FRONTEND_URL=https://chat.seudominio.com
MAILER_SENDER_EMAIL=suporte@seudominio.com
```

### 2. Teste localmente:

```bash
# Parar containers
docker compose down

# Limpar volumes (opcional - CUIDADO: apaga dados)
docker compose down -v

# Iniciar
docker compose up -d

# Ver logs
docker compose logs -f rails
```

### 3. Verificar se funcionou:

```bash
# Verificar se os assets foram baixados
docker compose exec rails ls -la /app/public/brand-assets/
```

Você deve ver:
```
logo.png
logo_thumbnail.png
banner.png
```

---

## 🔍 Troubleshooting

### Assets não aparecem?

```bash
# Ver logs do rails
docker compose logs rails | grep -i brand

# Entrar no container
docker compose exec rails bash

# Verificar manualmente
ls -la /app/public/brand-assets/

# Executar manualmente o script
deployment/extract_brand_assets.sh "https://seu-url.com/assets.zip"
```

### Forçar re-download dos assets:

```bash
docker compose exec rails rm -rf /app/public/brand-assets/*
docker compose restart rails
```

---

## 📚 Recursos Adicionais

- Documentação oficial: https://www.chatwoot.com/docs/self-hosted/configuration/branding
- Exemplos de assets: https://github.com/chatwoot/chatwoot/tree/develop/public

---

## ✅ Checklist

- [ ] Assets criados (logo.png, logo_thumbnail.png, banner.png)
- [ ] Assets empacotados em ZIP/TAR.GZ
- [ ] Arquivo hospedado e URL acessível
- [ ] Variável BRAND_ASSETS_URL configurada no .env
- [ ] Containers reiniciados
- [ ] Assets verificados em /app/public/brand-assets/
- [ ] Frontend testado no navegador
