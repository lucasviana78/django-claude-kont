---
name: django-conventions
description: Esta skill deve ser usada quando o usuário está trabalhando em um projeto Django — criando models, views, forms, templates, URLs, signals, managers ou qualquer código relacionado ao Django. Fornece orientação automática de convenções e boas práticas.
version: 1.0.0
---

# Convenções e boas práticas Django

Esta skill fornece orientação automática para desenvolvimento Django, garantindo que o código siga as boas práticas da comunidade e a filosofia de design do Django.

## Quando esta skill se aplica

Ativa quando a solicitação do usuário envolve:
- Criar ou modificar models, views, forms, serializers ou templates Django
- Configurar settings, URLs ou middleware do Django
- Trabalhar com queries do ORM Django
- Configurar apps ou estrutura de projeto Django
- Escrever management commands do Django
- Trabalhar com signals, managers ou querysets do Django

## Convenções de estrutura do projeto

### Organização do app

```
app_name/
├── __init__.py
├── admin.py              # Registro de admin dos modelos
├── apps.py               # Configuração do app
├── models.py             # Modelos de dados (dividir em pacote models/ se >5 modelos)
├── views.py              # Views (dividir em pacote views/ se >10 views)
├── serializers.py        # Serializers DRF (se usar DRF)
├── urls.py               # Configuração de URLs do app
├── forms.py              # Formulários Django
├── managers.py           # Managers e querysets customizados
├── services.py           # Lógica de negócio (manter views enxutas)
├── selectors.py          # Queries de leitura complexas (opcional, para projetos grandes)
├── signals.py            # Handlers de signals
├── tasks.py              # Tasks Celery/assíncronas
├── constants.py          # Constantes do app
├── exceptions.py         # Exceções customizadas
├── permissions.py        # Permissões DRF ou customizadas
├── middleware.py         # Middleware customizado
├── templatetags/         # Template tags customizadas
│   └── app_name_tags.py
├── templates/
│   └── app_name/         # Templates com namespace
├── static/
│   └── app_name/         # Arquivos estáticos com namespace
├── migrations/
├── tests/
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_views.py
│   ├── test_forms.py
│   └── factories.py      # Factories de modelos (factory_boy)
└── fixtures/             # Dados de teste (prefira factories)
```

### Quando dividir em pacotes

- `models.py` > 300 linhas ou > 5 modelos → dividir em pacote `models/`
- `views.py` > 500 linhas ou > 10 views → dividir em pacote `views/`
- Sempre use `__init__.py` com imports explícitos ao dividir

## Convenções de modelo

### Ordenação de campos

1. Chave primária (se customizada)
2. Campos regulares (CharField, TextField, IntegerField, etc.)
3. Campos de relacionamento (ForeignKey, M2M, O2O)
4. Campos de timestamp (created_at, updated_at)

### Componentes obrigatórios do modelo

```python
class MyModel(models.Model):
    # campos...

    class Meta:
        verbose_name = "my model"
        verbose_name_plural = "my models"
        ordering = ["-created_at"]

    def __str__(self):
        return self.name  # Sempre implemente __str__
```

### Regras de nomenclatura

- Nomes de modelo: `PascalCase`, singular (`Post`, não `Posts`)
- Campos: `snake_case`
- `related_name` de ForeignKey: snake_case no plural do modelo filho (`posts`, `comments`)
- BooleanField: prefixo com `is_`, `has_`, `can_`, `should_` (`is_active`, `has_paid`)
- DateTimeField: sufixo com `_at` (`created_at`, `published_at`)
- DateField: sufixo com `_date` ou `_on` (`birth_date`, `hired_on`)

### Padrões comuns

- Sempre adicione timestamps `created_at` e `updated_at`
- Use `settings.AUTH_USER_MODEL` em vez de `User` diretamente para ForeignKeys
- Use `uuid.uuid4` para IDs públicos, mantenha PK auto-incremento para uso interno
- Prefira `TextChoices` / `IntegerChoices` em vez de tuplas de choices brutas
- Use objetos `F()` e `Q()` em vez de SQL bruto
- Use `select_related()` para FK/O2O e `prefetch_related()` para M2M/FK reversa

## Convenções de view

### Prefira Class-Based Views (CBVs)

- Use as views genéricas do Django quando se encaixarem
- Mantenha views enxutas — mova lógica de negócio para `services.py`
- Use mixins para comportamento compartilhado

### Padrão de view

```python
# views.py — enxuta, delega para services
class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    form_class = PostForm

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)
```

```python
# services.py — lógica de negócio
def publish_post(post: Post, user: User) -> Post:
    if not user.has_perm("blog.publish_post"):
        raise PermissionDenied
    post.published = True
    post.published_at = timezone.now()
    post.save(update_fields=["published", "published_at", "updated_at"])
    return post
```

## Convenções de settings

- Divida settings: `settings/base.py`, `settings/local.py`, `settings/production.py`
- Use variáveis de ambiente para segredos (via `python-decouple` ou `django-environ`)
- Nunca comite segredos, arquivos `.env` ou `SECRET_KEY` no controle de versão

## Convenções de URL

- Use `path()` em vez de `re_path()` a menos que regex seja realmente necessário
- Sempre defina `app_name` no `urls.py` do app para namespacing
- Sempre use `name=` em cada padrão de URL
- Use `reverse()` ou `{% url %}` — nunca escreva URLs fixas no código

## Convenções de teste

- Use `pytest-django` em vez do test runner embutido do Django
- Use `factory_boy` para dados de teste em vez de fixtures
- Nomeie arquivos de teste: `test_<módulo>.py`
- Nomeie funções de teste: `test_<o_que_testa>_<comportamento_esperado>`
- Use `APIClient` para testes de endpoints DRF

## Ordenação de imports

Siga os padrões do `isort`:
1. Biblioteca padrão
2. Pacotes de terceiros
3. Imports do Django
4. Imports locais do app

## Lembretes de segurança

- Sempre use `{% csrf_token %}` em formulários
- Use `get_object_or_404()` em vez de `.get()` simples nas views
- Valide e sanitize toda entrada do usuário
- Use o ORM do Django — evite SQL bruto a menos que absolutamente necessário
- Defina `AUTH_PASSWORD_VALIDATORS` em produção
- Use configurações `SECURE_*` em produção (HSTS, redirecionamento SSL, etc.)
