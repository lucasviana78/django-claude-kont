---
name: django-performance
description: Esta skill deve ser usada quando o usuário está escrevendo queries do ORM, views, serializers ou qualquer código Django onde performance é relevante. Detecta problemas N+1, sugere otimizações de queries e boas práticas de cache.
version: 1.0.0
---

# Performance Django — Claude Code Skill

Esta skill do Claude Code fornece orientação automática de performance para projetos Django, focando em queries do ORM, views, serializers e cache.

## Quando esta skill se aplica

Ativa quando a solicitação do usuário envolve:
- Escrever ou modificar queries do ORM Django
- Criar views que acessam o banco de dados
- Escrever serializers que acessam relacionamentos
- Trabalhar com listagens, paginação ou filtros
- Configurar cache
- Otimizar endpoints lentos
- Trabalhar com Celery/tasks assíncronas
- Criar management commands que processam dados em massa

## Problema N+1 — Detecção e Correção

O problema N+1 é o vilão de performance mais comum em Django.

### Como identificar

**Padrão perigoso**: view ou serializer acessa campos de relacionamento (FK, O2O, M2M) sem `select_related` ou `prefetch_related` no queryset.

```python
# N+1 — 1 query para posts + N queries para authors
posts = Post.objects.all()
for post in posts:
    print(post.author.name)  # Query individual para cada author

# Corrigido — 1 query com JOIN
posts = Post.objects.select_related("author").all()
```

### Regras de uso

| Tipo de relacionamento | Método | Quando usar |
|------------------------|--------|-------------|
| ForeignKey (acesso direto) | `select_related` | Sempre que acessar o campo FK |
| OneToOneField | `select_related` | Sempre que acessar o campo O2O |
| ManyToManyField | `prefetch_related` | Sempre que acessar o campo M2M |
| ForeignKey reversa | `prefetch_related` | Quando acessar `model_set` ou `related_name` |
| Cadeia de FKs | `select_related("fk1__fk2")` | Para JOINs encadeados |

### Em serializers DRF

```python
# Incorreto — N+1 no serializer
class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name")  # N+1!
    
    class Meta:
        model = Post
        fields = ["id", "title", "author_name"]

# O queryset do ViewSet DEVE incluir:
class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.select_related("author").all()
    serializer_class = PostSerializer
```

### Nested serializers

```python
# Cada serializer aninhado que acessa FKs precisa de prefetch
class PostSerializer(serializers.ModelSerializer):
    comments = CommentSerializer(many=True, source="comments_set")  # N+1!
    tags = TagSerializer(many=True)  # N+1!

# Correção no ViewSet:
queryset = Post.objects.prefetch_related(
    "comments_set",
    "tags",
    Prefetch("comments_set", queryset=Comment.objects.select_related("author")),
).select_related("author")
```

## Otimização de queries

### Use `.only()` e `.defer()` para limitar campos

```python
# Carrega TODOS os campos (incluindo TextField grande)
posts = Post.objects.all()

# Carrega apenas os campos necessários
posts = Post.objects.only("id", "title", "created_at")

# Carrega tudo exceto campos pesados
posts = Post.objects.defer("body", "metadata")
```

### Use `.values()` e `.values_list()` para consultas leves

```python
# Retorna dicionários em vez de objetos Model — mais rápido
titles = Post.objects.values_list("title", flat=True)

# Para contagens e agregações
from django.db.models import Count
author_counts = Post.objects.values("author").annotate(total=Count("id"))
```

### Use `.exists()` em vez de `.count()` para verificação

```python
# Incorreto — conta todos os registros
if Post.objects.filter(published=True).count() > 0:
    ...

# Correto — para no primeiro resultado
if Post.objects.filter(published=True).exists():
    ...
```

### Use `.update()` e `.delete()` em massa

```python
# Incorreto — N queries individuais
for post in Post.objects.filter(published=False):
    post.published = True
    post.save()

# Correto — 1 query
Post.objects.filter(published=False).update(published=True)
```

### Use `bulk_create()` e `bulk_update()`

```python
# Incorreto — N queries de INSERT
for item in data:
    Model.objects.create(**item)

# Correto — 1 query (ou poucos batches)
Model.objects.bulk_create([Model(**item) for item in data], batch_size=1000)
```

### Use objetos `F()` para operações atômicas

```python
from django.db.models import F

# Incorreto — race condition
post = Post.objects.get(pk=1)
post.view_count += 1
post.save()

# Correto — atômico no banco
Post.objects.filter(pk=1).update(view_count=F("view_count") + 1)
```

## Indexação

### Quando adicionar índices

- Campos usados frequentemente em `filter()`, `exclude()`, `order_by()`
- Campos usados em `JOIN` (ForeignKey já tem índice automático)
- Campos usados em lookups únicos (`get()`, `get_or_create()`)

```python
class Post(models.Model):
    title = models.CharField(max_length=255, db_index=True)  # Filtrado frequentemente
    slug = models.SlugField(unique=True)  # unique=True já cria índice
    
    class Meta:
        indexes = [
            models.Index(fields=["published", "-created_at"]),  # Índice composto
            models.Index(fields=["author", "published"], name="author_published_idx"),
        ]
```

### Quando NÃO adicionar índices

- Tabelas pequenas (< 1000 registros) — scan sequencial é mais rápido
- Campos com baixa cardinalidade (ex: `BooleanField` com 50/50)
- Tabelas com muitas escritas e poucas leituras

## Paginação

- **Sempre** pagine listagens — nunca retorne todos os registros
- Use `CursorPagination` do DRF para datasets grandes (mais eficiente que offset)
- `LimitOffsetPagination` fica lento com offsets grandes (>10k)

```python
# settings.py
REST_FRAMEWORK = {
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.CursorPagination",
    "PAGE_SIZE": 25,
}
```

## Cache

### Níveis de cache no Django

| Nível | Quando usar | Como |
|-------|-------------|------|
| Queryset | Dados que mudam pouco | `cache.get_or_set()` |
| View | Páginas inteiras | `@cache_page(timeout)` |
| Template fragment | Partes do template | `{% cache timeout key %}` |
| Low-level | Qualquer dado computado | `cache.set()` / `cache.get()` |

### Padrão recomendado para cache de queryset

```python
from django.core.cache import cache

def get_published_posts():
    cache_key = "published_posts"
    posts = cache.get(cache_key)
    if posts is None:
        posts = list(Post.objects.filter(published=True).select_related("author"))
        cache.set(cache_key, posts, timeout=300)  # 5 minutos
    return posts
```

### Invalidação de cache

```python
from django.db.models.signals import post_save, post_delete

def invalidate_post_cache(sender, **kwargs):
    cache.delete("published_posts")

post_save.connect(invalidate_post_cache, sender=Post)
post_delete.connect(invalidate_post_cache, sender=Post)
```

## Ferramentas de diagnóstico

- **django-debug-toolbar**: mostra queries por request em desenvolvimento
- **django-silk**: profiling de requests e queries
- **nplusone**: detecta N+1 automaticamente em desenvolvimento
- **EXPLAIN ANALYZE**: para queries individuais via `queryset.explain()`

```python
# Ver o plano de execução de uma query
print(Post.objects.filter(published=True).select_related("author").explain(analyze=True))
```

## Checklist de performance para views/endpoints

- [ ] Queryset usa `select_related` para FKs acessadas
- [ ] Queryset usa `prefetch_related` para M2M e FKs reversas
- [ ] Listagens são paginadas
- [ ] Campos desnecessários são excluídos com `only()` ou `defer()`
- [ ] Operações em massa usam `bulk_create`/`bulk_update`
- [ ] Contagens usam `.exists()` quando possível
- [ ] Campos frequentemente filtrados têm `db_index`
- [ ] Dados estáticos ou pouco mutáveis estão em cache
