---
description: Gera uma API completa do Django REST Framework (Serializer + ViewSet + configuração de URLs) para um modelo existente.
argument-hint: <NomeDoApp> <NomeDoModelo> [--readonly] [--fields=campo1,campo2,...] [--nested=relação1,relação2,...]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Gerador de API Django REST Framework — Claude Code

Você é um comando do Claude Code para geração de APIs DRF. Crie uma camada de API completa (serializer, viewset e configuração de URLs) para um modelo Django existente.

## Argumentos

O usuário invocou isso com: $ARGUMENTS

## Análise dos argumentos

```
/django-api <NomeDoApp> <NomeDoModelo> [opções]
```

### Opções

- `--readonly` — Gera um ReadOnlyModelViewSet em vez de ModelViewSet
- `--fields=f1,f2,f3` — Inclui apenas estes campos no serializer (padrão: todos os campos)
- `--exclude=f1,f2` — Exclui estes campos do serializer
- `--nested=relação1,relação2` — Cria serializers aninhados para essas relações
- `--filter=f1,f2` — Adiciona campos de filtro
- `--search=f1,f2` — Adiciona campos de busca
- `--order=f1,f2` — Adiciona campos de ordenação
- `--pagination=N` — Define o tamanho da página (padrão: usa o padrão do projeto)

## Instruções

### Passo 1: Localizar o modelo

1. Encontre o modelo em `<app>/models.py`
2. Leia-o completamente para entender todos os campos e relacionamentos
3. Se o modelo não existir, pare e informe o usuário — sugira usar `/django-model` primeiro

### Passo 2: Gerar o Serializer

Crie ou atualize `<app>/serializers.py`:

```python
from rest_framework import serializers

from .models import ModelName


class ModelNameSerializer(serializers.ModelSerializer):
    class Meta:
        model = ModelName
        fields = "__all__"  # ou campos específicos
        read_only_fields = ["id", "created_at", "updated_at"]
```

**Regras do serializer:**
- `id`, `created_at`, `updated_at` são sempre `read_only_fields`
- Se `--nested` for usado, crie serializers inline para essas relações
- Para campos ForeignKey, adicione um campo de escrita `<campo>_id` junto com a representação de leitura aninhada
- Use `SlugRelatedField` para campos que referenciam modelos com campos óbvios de slug/nome
- Adicione métodos de validação para campos que precisam (ex.: restrições de unicidade, lógica customizada)

### Passo 3: Gerar o ViewSet

Crie ou atualize `<app>/views.py` (ou `<app>/viewsets.py` se esse padrão existir):

```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import ModelName
from .serializers import ModelNameSerializer


class ModelNameViewSet(viewsets.ModelViewSet):
    queryset = ModelName.objects.all()
    serializer_class = ModelNameSerializer
    permission_classes = [IsAuthenticated]
```

**Regras do ViewSet:**
- Use `ReadOnlyModelViewSet` se a flag `--readonly` estiver presente
- Adicione `select_related` / `prefetch_related` ao queryset para campos ForeignKey e M2M
- Adicione `filterset_fields`, `search_fields`, `ordering_fields` se as opções correspondentes forem fornecidas
- Se o modelo tiver um campo `slug`, defina `lookup_field = "slug"`
- Se o modelo tiver uma ForeignKey `author` ou `user`, adicione `perform_create` para definí-lo automaticamente:
  ```python
  def perform_create(self, serializer):
      serializer.save(author=self.request.user)
  ```
- Siga os padrões de permissão existentes no projeto, se houver

### Passo 4: Configurar URLs

Encontre a configuração de URLs e adicione o router:

1. Verifique se `<app>/urls.py` existe — crie se não existir
2. Verifique se um `DefaultRouter` do DRF já existe no app ou projeto
3. Registre o novo viewset:

```python
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .viewsets import ModelNameViewSet

router = DefaultRouter()
router.register("model-names", ModelNameViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
```

4. Verifique se as URLs do app estão incluídas no `urls.py` raiz do projeto — se não, sugira adicionar:
   ```python
   path("api/app-name/", include("app_name.urls")),
   ```

**Regras de URL:**
- Use kebab-case para prefixos de URL (ex.: `blog-posts`, não `blogposts`)
- Use a forma plural do nome do modelo
- Siga os padrões de URL existentes no projeto, se houver

### Passo 5: Verificar dependências

- Verifique se `rest_framework` está em `INSTALLED_APPS`
- Se `--filter` for usado, verifique se `django_filters` está instalado e em `INSTALLED_APPS`
- Avise sobre quaisquer dependências faltando

## Exemplo

Entrada:
```
/django-api blog Post --filter=published,author --search=title,body --order=created_at,title
```

Arquivos gerados:

**blog/serializers.py:**
```python
from rest_framework import serializers

from .models import Post


class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]
```

**blog/viewsets.py:**
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
    ordering_fields = ["created_at", "title"]
    ordering = ["-created_at"]
    lookup_field = "slug"

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```

## Após a geração

1. Mostre todos os arquivos gerados/modificados
2. Liste os endpoints de API disponíveis (CRUD)
3. Sugira executar o servidor de desenvolvimento para testar: `python manage.py runserver`
4. Sugira próximos passos úteis (permissões, throttling, testes)
