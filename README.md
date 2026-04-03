# django-kont — Plugin para Claude Code

Plugin para **Claude Code** que turbina o desenvolvimento Django com comandos inteligentes, skills automáticas de boas práticas e agentes especializados.

Transforma conhecimento recorrente de Django em ferramentas operacionais do Claude Code — reduzindo prompt manual e padronizando a geração e análise de código.

## Instalação

```bash
claude plugin add github:lucasviana78/django-claude-kont
```

> Requer [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado.

## O que está incluído

### Comandos (invocados pelo usuário no Claude Code)

| Comando | Descrição |
|---------|-----------|
| `/django-model` | Gera modelos Django a partir de uma sintaxe DSL simples |
| `/django-api` | Gera uma API DRF completa (Serializer + ViewSet + URLs) para um modelo |

### Skills (ativadas automaticamente pelo Claude Code)

Skills são ativadas automaticamente pelo Claude Code quando o contexto relevante é detectado no seu projeto Django.

| Skill | Ativa quando |
|-------|-------------|
| `django-conventions` | Trabalhando em qualquer código Django — fornece convenções e boas práticas |
| `django-security` | Mexendo em autenticação, formulários, queries — verifica OWASP e diretrizes de segurança Django |
| `django-performance` | Escrevendo queries ou views — detecta N+1, sugere otimizações |

### Agentes (Claude Code agents)

| Agente | Propósito |
|--------|-----------|
| `django-explorer` | Mapeia um projeto Django existente (models, views, URLs, signals) |
| `django-reviewer` | Revisa código com foco em boas práticas, segurança e performance Django |

## Compatibilidade

| Dependência | Versões suportadas |
|-------------|-------------------|
| Python | 3.10, 3.11, 3.12, 3.13 |
| Django | 4.2 LTS, 5.0, 5.1, 5.2 |
| Django REST Framework | 3.14, 3.15 |

> O plugin instrui o Claude Code a gerar código compatível com essas versões. Versões anteriores podem funcionar mas não são validadas.

## Exemplos de uso

### Gerar um modelo

**Entrada:**
```
/django-model blog Post title:str body:text slug:slug! author:fk:User published:bool published_at:datetime?
```

**Saída gerada em `blog/models.py`:**
```python
from django.conf import settings
from django.db import models


class Post(models.Model):
    title = models.CharField(max_length=255)
    body = models.TextField()
    slug = models.SlugField(unique=True)
    published = models.BooleanField(default=False)
    published_at = models.DateTimeField(null=True, blank=True)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="posts",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "post"
        verbose_name_plural = "posts"
        ordering = ["-created_at"]

    def __str__(self):
        return self.title
```

#### Tipos de campo da DSL

| DSL | Campo Django |
|-----|-------------|
| `str` | `CharField(max_length=255)` |
| `str:N` | `CharField(max_length=N)` |
| `text` | `TextField` |
| `int` | `IntegerField` |
| `float` | `FloatField` |
| `decimal` | `DecimalField` |
| `bool` | `BooleanField` |
| `date` | `DateField` |
| `datetime` | `DateTimeField` |
| `email` | `EmailField` |
| `url` | `URLField` |
| `slug` | `SlugField` |
| `uuid` | `UUIDField` |
| `json` | `JSONField` |
| `image` | `ImageField` |
| `file` | `FileField` |
| `fk:Model` | `ForeignKey(Model)` |
| `o2o:Model` | `OneToOneField(Model)` |
| `m2m:Model` | `ManyToManyField(Model)` |

**Modificadores:** `?` = anulável, `!` = único, `+` = indexado

### Gerar uma API

**Entrada:**
```
/django-api blog Post --filter=published,author --search=title,body --order=created_at
```

**Saída gerada:**

`blog/serializers.py`:
```python
from rest_framework import serializers

from .models import Post


class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]
```

`blog/viewsets.py`:
```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Post
from .serializers import PostSerializer


class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.select_related("author").all()
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ["published", "author"]
    search_fields = ["title", "body"]
    ordering_fields = ["created_at"]
    ordering = ["-created_at"]
    lookup_field = "slug"

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```

`blog/urls.py`:
```python
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .viewsets import PostViewSet

router = DefaultRouter()
router.register("posts", PostViewSet)

app_name = "blog"

urlpatterns = [
    path("", include(router.urls)),
]
```

### Explorar um projeto

Peça ao Claude Code para explorar seu projeto:

```
Explore this Django project and map out the architecture
```

O Claude Code ativa automaticamente o agente `django-explorer` para mapear apps, models, views, URLs, signals e retornar um relatório estruturado.

### Revisar código

Peça ao Claude Code uma revisão de código:

```
Review my Django code for best practices
```

O Claude Code ativa o agente `django-reviewer`, que analisa o código com foco em qualidade, segurança, performance e consistência.

## Convenções aplicadas

A skill `django-conventions` guia automaticamente o Claude Code para seguir:

- **Estrutura do projeto**: Organização adequada de apps com services, managers, selectors
- **Padrões de modelo**: Ordenação de campos, convenções de nomenclatura, classe Meta, `__str__`
- **Padrões de view**: Views enxutas, lógica de negócio em services
- **Settings**: Settings divididas, variáveis de ambiente para segredos
- **Testes**: pytest-django, factory_boy, nomenclatura adequada
- **Segurança**: CSRF, ORM em vez de SQL bruto, configurações de autenticação adequadas

## Como funciona

Este plugin adiciona **comandos**, **skills** e **agentes** ao Claude Code via o sistema de plugins. Quando instalado:

- **Comandos** ficam disponíveis como `/django-model` e `/django-api` no Claude Code
- **Skills** são ativadas automaticamente quando o Claude Code detecta que você está trabalhando em código Django relevante (autenticação, queries, models, etc.)
- **Agentes** são invocados pelo Claude Code quando você pede para explorar ou revisar seu projeto

Nenhuma dependência Python é instalada — o plugin opera inteiramente no nível do Claude Code.

## Roadmap

- [ ] `/django-startproject` — Criar um novo projeto com estrutura de boas práticas
- [ ] `/django-startapp` — Criar um novo app com boilerplate completo
- [ ] `/django-test` — Gerar ou executar testes para models/views/APIs
- [ ] `/django-migrate` — Fluxo de migração seguro com verificações
