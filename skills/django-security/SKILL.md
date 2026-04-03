---
name: django-security
description: Esta skill deve ser usada quando o usuário está trabalhando em código Django que envolve autenticação, autorização, formulários, queries, middleware ou configurações de segurança. Fornece checklist OWASP e diretrizes de segurança específicas do Django.
version: 1.0.0
---

# Segurança Django — Claude Code Skill

Esta skill do Claude Code fornece orientação automática de segurança para projetos Django, baseada no OWASP Top 10 e nas recomendações oficiais do Django.

## Quando esta skill se aplica

Ativa quando a solicitação do usuário envolve:
- Autenticação e autorização (login, logout, permissões, tokens)
- Formulários e validação de entrada do usuário
- Queries ao banco de dados (ORM ou SQL bruto)
- Configurações de settings de produção
- Middleware de segurança
- Upload de arquivos
- APIs e endpoints expostos
- Manipulação de sessões e cookies
- Serialização/deserialização de dados

## OWASP Top 10 — Aplicado ao Django

### A01: Broken Access Control

- **Sempre** defina `permission_classes` em ViewSets e APIViews do DRF
- **Sempre** use `LoginRequiredMixin` ou `@login_required` em views que exigem autenticação
- Verifique permissões no nível do objeto, não apenas no nível da view
- Use `get_object_or_404()` com filtros de propriedade:
  ```python
  # Correto — garante que o usuário só acessa seus próprios objetos
  post = get_object_or_404(Post, pk=pk, author=request.user)
  
  # Incorreto — qualquer usuário autenticado acessa qualquer objeto
  post = get_object_or_404(Post, pk=pk)
  ```
- Nunca exponha IDs sequenciais em APIs públicas — use UUID ou slug
- Defina `DEFAULT_PERMISSION_CLASSES` no `REST_FRAMEWORK` settings

### A02: Cryptographic Failures

- **Nunca** armazene senhas em texto plano — use `make_password()` / `check_password()`
- **Nunca** comite `SECRET_KEY` no controle de versão
- Use variáveis de ambiente para todos os segredos (`python-decouple` ou `django-environ`)
- Em produção, ative:
  ```python
  SECURE_SSL_REDIRECT = True
  SECURE_HSTS_SECONDS = 31536000
  SECURE_HSTS_INCLUDE_SUBDOMAINS = True
  SECURE_HSTS_PRELOAD = True
  SESSION_COOKIE_SECURE = True
  CSRF_COOKIE_SECURE = True
  ```
- Use `django.contrib.auth.hashers` — não implemente hashing customizado

### A03: Injection

- **Sempre** use o ORM do Django em vez de SQL bruto
- Se SQL bruto for absolutamente necessário, **sempre** use parâmetros:
  ```python
  # Correto
  Model.objects.raw("SELECT * FROM app_model WHERE id = %s", [user_id])
  
  # NUNCA faça isso
  Model.objects.raw(f"SELECT * FROM app_model WHERE id = {user_id}")
  ```
- Valide e sanitize toda entrada do usuário via Forms ou Serializers
- Use `django.utils.html.escape()` para saída em contextos HTML
- Cuidado com `extra()`, `RawSQL()` e `cursor.execute()` — todos aceitam SQL bruto

### A04: Insecure Design

- Implemente rate limiting em endpoints sensíveis (login, reset de senha)
  ```python
  REST_FRAMEWORK = {
      "DEFAULT_THROTTLE_CLASSES": [
          "rest_framework.throttling.AnonRateThrottle",
          "rest_framework.throttling.UserRateThrottle",
      ],
      "DEFAULT_THROTTLE_RATES": {
          "anon": "100/hour",
          "user": "1000/hour",
      },
  }
  ```
- Não exponha informações internas em mensagens de erro (stack traces, nomes de tabelas)
- Em produção: `DEBUG = False` sempre

### A05: Security Misconfiguration

- Remova `DEBUG = True` em produção
- Configure `ALLOWED_HOSTS` explicitamente (nunca `["*"]` em produção)
- Remova apps desnecessários de `INSTALLED_APPS` (ex: `django.contrib.admindocs` se não usar)
- Configure `AUTH_PASSWORD_VALIDATORS`:
  ```python
  AUTH_PASSWORD_VALIDATORS = [
      {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
      {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 10}},
      {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
      {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
  ]
  ```
- Garanta que o middleware de segurança está presente e na ordem correta:
  ```python
  MIDDLEWARE = [
      "django.middleware.security.SecurityMiddleware",  # Primeiro
      # ...
      "django.middleware.csrf.CsrfViewMiddleware",
      "django.middleware.clickjacking.XFrameOptionsMiddleware",
  ]
  ```

### A06: Vulnerable and Outdated Components

- Mantenha Django e dependências atualizadas
- Use `pip-audit` ou `safety` para verificar vulnerabilidades conhecidas
- Monitore os Django Security Releases

### A07: Identification and Authentication Failures

- Use o sistema de autenticação do Django — não implemente o seu próprio
- Implemente bloqueio de conta após tentativas falhas (`django-axes`)
- Para APIs, prefira JWT com expiração curta + refresh tokens
- Valide tokens de reset de senha com expiração
- Use `SESSION_COOKIE_AGE` apropriado
- Defina `SESSION_COOKIE_HTTPONLY = True` (padrão do Django)

### A08: Software and Data Integrity Failures

- Valide todos os dados de entrada com Forms/Serializers antes de salvar
- Use `signed_cookies` ou armazenamento server-side para sessões
- Verifique integridade de arquivos uploaded (tipo MIME, tamanho máximo)
- Cuidado com deserialização insegura — evite `pickle` com dados do usuário

### A09: Security Logging and Monitoring Failures

- Configure logging de segurança:
  ```python
  LOGGING = {
      "version": 1,
      "handlers": {
          "security": {
              "class": "logging.FileHandler",
              "filename": "security.log",
          },
      },
      "loggers": {
          "django.security": {
              "handlers": ["security"],
              "level": "WARNING",
          },
      },
  }
  ```
- Logue tentativas de login falhas
- Logue acessos não autorizados

### A10: Server-Side Request Forgery (SSRF)

- Valide e sanitize URLs fornecidas pelo usuário antes de fazer requests
- Use allowlists para domínios externos permitidos
- Nunca passe URLs do usuário diretamente para `requests.get()` ou `urllib`

## Upload de arquivos

- **Sempre** valide tipo e tamanho do arquivo
- **Nunca** sirva uploads da mesma origem do app — use um domínio/bucket separado
- Use `FileExtensionValidator` e validação de content-type:
  ```python
  from django.core.validators import FileExtensionValidator
  
  document = models.FileField(
      upload_to="documents/%Y/%m/",
      validators=[FileExtensionValidator(allowed_extensions=["pdf", "doc", "docx"])],
  )
  ```
- Defina `FILE_UPLOAD_MAX_MEMORY_SIZE` e `DATA_UPLOAD_MAX_MEMORY_SIZE`

## CSRF

- **Nunca** use `@csrf_exempt` sem justificativa forte (APIs com autenticação por token são exceção)
- **Sempre** use `{% csrf_token %}` em formulários HTML
- Para SPAs com DRF, configure CORS adequadamente com `django-cors-headers`

## Checklist de deploy seguro

- [ ] `DEBUG = False`
- [ ] `SECRET_KEY` via variável de ambiente
- [ ] `ALLOWED_HOSTS` configurado explicitamente
- [ ] `SECURE_SSL_REDIRECT = True`
- [ ] `SECURE_HSTS_SECONDS >= 31536000`
- [ ] `SESSION_COOKIE_SECURE = True`
- [ ] `CSRF_COOKIE_SECURE = True`
- [ ] `SECURE_BROWSER_XSS_FILTER = True`
- [ ] `X_FRAME_OPTIONS = "DENY"`
- [ ] `AUTH_PASSWORD_VALIDATORS` configurados
- [ ] Logging de segurança ativo
- [ ] Dependências auditadas (`pip-audit`)
