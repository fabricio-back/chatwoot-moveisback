# 🎨 Como Adicionar Logo e Imagens Personalizadas

## ✅ O que foi preparado

A estrutura já está configurada! Você só precisa adicionar suas imagens.

```
brand-assets/
├── logo.png            ← Adicione aqui (200x50px)
├── logo_thumbnail.png  ← Adicione aqui (32x32px)
└── banner.png          ← (Opcional) Adicione aqui (1200x600px)
```

---

## 📋 Passo a Passo

### 1️⃣ Prepare suas imagens

Crie ou obtenha 3 arquivos de imagem:

| Arquivo | Tamanho | Formato | Onde aparece |
|---------|---------|---------|--------------|
| **logo.png** | 200x50px | PNG transparente | Header, sidebar, emails |
| **logo_thumbnail.png** | 32x32px | PNG/ICO | Favicon (ícone da aba) |
| **banner.png** | 1200x600px | PNG/JPG | Tela de login (opcional) |

**Dicas:**
- Use **PNG com fundo transparente** para logo
- Mantenha o favicon **simples e reconhecível**
- Logo deve ser **horizontal** (largura > altura)

---

### 2️⃣ Adicione os arquivos na pasta

Copie suas imagens para a pasta `brand-assets/`:

```powershell
# Exemplo no Windows (adapte os caminhos)
Copy-Item "C:\Downloads\meu-logo.png" -Destination ".\brand-assets\logo.png"
Copy-Item "C:\Downloads\meu-favicon.png" -Destination ".\brand-assets\logo_thumbnail.png"
Copy-Item "C:\Downloads\meu-banner.png" -Destination ".\brand-assets\banner.png"
```

Ou simplesmente **arraste e solte** os arquivos para a pasta via Explorer.

---

### 3️⃣ Verifique se os arquivos estão corretos

```powershell
Get-ChildItem .\brand-assets\
```

Você deve ver:
```
Mode         LastWriteTime     Length Name
----         -------------     ------ ----
-a---   18/03/2026   10:30       25KB logo.png
-a---   18/03/2026   10:30        5KB logo_thumbnail.png
-a---   18/03/2026   10:30      150KB banner.png
```

---

### 4️⃣ Rebuild da imagem Docker

**Importante:** Pare os containers antes do rebuild:

```powershell
# Parar containers
docker compose down

# Rebuild da imagem (isso vai demorar ~2-5 minutos)
docker build -f Dockerfile.full -t meu-chatwoot-custom:v1.1 .

# Iniciar novamente
docker compose up -d
```

**Durante o build (~3 minutos):**
```
[+] Building 180.5s (18/18) FINISHED
 ✔ Stage 1: Cloning and building assets...
 ✔ Stage 2: Copying brand assets...
 ✔ Successfully tagged meu-chatwoot-custom:v1.1
```

---

### 5️⃣ Atualizar docker-compose.yml

Atualize a versão da imagem no `docker-compose.yml`:

**Antes:**
```yaml
rails:
  image: meu-chatwoot-custom:v1.0
```

**Depois:**
```yaml
rails:
  image: meu-chatwoot-custom:v1.1
```

**E também para o sidekiq:**
```yaml
sidekiq:
  image: meu-chatwoot-custom:v1.1
```

Reinicie:
```powershell
docker compose up -d
```

---

### 6️⃣ Testar no navegador

1. Acesse: **http://localhost:3000**
2. Verifique:
   - ✅ Logo aparece no header (canto superior esquerdo)
   - ✅ Favicon aparece na aba do navegador
   - ✅ Banner aparece na tela de login (se adicionou)

---

## 🔍 Verificar se os assets foram copiados corretamente

```powershell
# Entrar no container
docker compose exec rails sh

# Listar arquivos
ls -la /app/public/brand-assets/

# Deve aparecer:
# logo.png
# logo_thumbnail.png
# banner.png
```

---

## 🎨 Não tem imagens ainda?

### Opção 1: Criar no Canva (Grátis)
1. Acesse https://www.canva.com
2. Crie um design personalizado:
   - **Logo**: 200 x 50 pixels
   - **Favicon**: 32 x 32 pixels
   - **Banner**: 1200 x 600 pixels
3. Baixe como PNG

### Opção 2: Usar Photopea (Editor Online Grátis)
1. Acesse https://www.photopea.com
2. File → New → Defina as dimensões
3. Crie seu design
4. File → Export as → PNG

### Opção 3: Logo Temporário (Texto)
Use qualquer editor de imagem para criar um PNG com o nome da empresa em texto.

---

## ⚡ Atalho Rápido

Se você já tem as imagens prontas:

```powershell
# 1. Copie as imagens para brand-assets/
Copy-Item "caminho\logo.png" -Destination ".\brand-assets\"
Copy-Item "caminho\logo_thumbnail.png" -Destination ".\brand-assets\"

# 2. Stop e rebuild
docker compose down
docker build -f Dockerfile.full -t meu-chatwoot-custom:v1.1 .

# 3. Atualizar docker-compose.yml (mudar v1.0 → v1.1)
# Edite manualmente ou use:
(Get-Content docker-compose.yml) -replace 'v1.0', 'v1.1' | Set-Content docker-compose.yml

# 4. Start
docker compose up -d

# 5. Ver logs
docker compose logs -f rails
```

---

## 🚀 Resultado Final

Após seguir os passos, você terá:
- ✅ Logo personalizado no header
- ✅ Favicon personalizado na aba do navegador
- ✅ Banner personalizado na tela de login
- ✅ Imagens embedadas na imagem Docker (prontas para produção)

---

## 📞 Problemas?

### Imagens não aparecem?
```powershell
# Verificar se foram copiadas no build
docker compose exec rails ls -la /app/public/brand-assets/

# Se não aparecer, verificar .dockerignore
cat .dockerignore | Select-String "brand-assets"
```

### Build muito lento?
- Normal na primeira vez (~20min)
- Builds subsequentes são mais rápidos (~3-5min) com cache
- Use Docker Desktop com alocação de RAM adequada (mín. 4GB)

### Logo aparece cortado?
- Verifique as dimensões recomendadas
- Logo deve ser 200x50px (horizontal)
- Use fundo transparente
