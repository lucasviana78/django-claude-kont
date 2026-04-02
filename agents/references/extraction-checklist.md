# Checklist de extração por artefato Django

Referência detalhada do que extrair de cada tipo de arquivo durante a análise de um projeto Django.

## Models (`models.py` ou `models/*.py`)

Para cada model encontrado:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe | `Post` |
| Herança | Classe base se não for `models.Model` | `TimeStampedModel`, `AbstractUser` |
| Campos de negócio | Campos que representam dados do domínio (ignorar `created_at`, `updated_at`, `id`) | `title: CharField(255)`, `body: TextField` |
| ForeignKey | Model alvo + `related_name` + `on_delete` | `author → User (related_name=posts, CASCADE)` |
| OneToOneField | Model alvo + `related_name` | `profile → User (related_name=profile)` |
| ManyToManyField | Model alvo + `related_name` + through (se existir) | `tags ↔ Tag (through=PostTag)` |
| Meta | `ordering`, `constraints`, `indexes`, `unique_together`, `permissions` | `ordering=["-created_at"]` |
| Managers | Managers customizados | `published = PublishedManager()` |
| Métodos | Apenas nomes e propósito (uma frase) — não copiar código | `publish()` — marca como publicado |
| Properties | Nome e tipo de retorno se óbvio | `@property full_name → str` |
| Choices | Enums/TextChoices definidos | `Status(TextChoices): DRAFT, PUBLISHED` |

### Sinais de atenção em models (reportar na seção Observações)
- Model sem `__str__`
- ForeignKey sem `related_name` explícito
- `on_delete=models.CASCADE` em FK que deveria ser `SET_NULL`
- Model com >15 campos (pode indicar necessidade de decomposição)
- Ausência de `indexes` em campos usados para filtro

## Views (`views.py`, `viewsets.py`, ou `views/*.py`)

Para cada view encontrada:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe/função | `PostListView` |
| Tipo | FBV / CBV / ViewSet / APIView / genérica Django | `CBV (ListView)` |
| Model | Model principal associado | `Post` |
| Mixins | Todos os mixins na ordem de herança | `LoginRequiredMixin, PermissionRequiredMixin` |
| Permissões | `permission_classes` (DRF) ou `permission_required` | `[IsAuthenticated, IsOwner]` |
| Queryset | Se customizado, descrever filtros aplicados | `Post.objects.filter(published=True).select_related("author")` |
| Serializer | Serializer associado (DRF) | `PostSerializer` |
| Métodos HTTP | Métodos customizados ou actions (DRF) | `@action publish (POST)` |

### Sinais de atenção em views
- View com >30 linhas em um único método (lógica de negócio inline)
- Queryset sem `select_related`/`prefetch_related` acessando FKs no template/serializer
- View sem nenhuma permissão definida
- Lógica duplicada entre views

## URLs (`urls.py`)

Para cada pattern:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Path | Pattern completo (resolvido com prefixos) | `/api/v1/posts/<int:pk>/` |
| View | View/ViewSet associada | `PostViewSet` |
| Name | `name=` do pattern | `post-detail` |
| Namespace | `app_name` se definido | `blog:post-detail` |

### Como resolver includes
- Seguir cada `include()` recursivamente (máximo 5 níveis)
- Concatenar prefixos para montar o path completo
- Registrar routers DRF e seus registros

### DRF Routers (`DefaultRouter`, `SimpleRouter`)

Quando encontrar `router.register(prefix, viewset)`:
- Expanda os endpoints padrão gerados pelo router:
  - `GET {prefix}/` → list
  - `POST {prefix}/` → create
  - `GET {prefix}/{pk}/` → retrieve
  - `PUT {prefix}/{pk}/` → update
  - `PATCH {prefix}/{pk}/` → partial_update
  - `DELETE {prefix}/{pk}/` → destroy
- Liste também `@action` customizadas definidas no ViewSet
- Se for `ReadOnlyModelViewSet`, exclua create/update/destroy

## Serializers (`serializers.py`)

Para cada serializer:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe | `PostSerializer` |
| Model | Model associado | `Post` |
| Campos | `fields` ou `exclude` | `fields = ["id", "title", "body", "author"]` |
| Read-only | `read_only_fields` | `["id", "created_at"]` |
| Nested | Serializers aninhados | `author = UserSerializer()` |
| Validações | Métodos `validate_*` e `validate` — descrever regra, não copiar código | `validate_title: impede duplicatas` |
| Write fields | Campos `_id` para escrita de FK | `author_id = PrimaryKeyRelatedField(write_only)` |

## Signals (`signals.py`)

Para cada signal:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Signal | Tipo (`post_save`, `pre_delete`, custom) | `post_save` |
| Sender | Model que dispara | `Post` |
| Receiver | Função que recebe | `notify_followers` |
| Ação | O que faz (uma frase) | Envia notificação para seguidores do autor |
| Cross-app | Se o sender/receiver está em app diferente | `blog.Post → notifications.notify_followers` |

## Tasks (`tasks.py`)

Para cada task:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da função | `send_weekly_digest` |
| Tipo | Celery shared_task / periodic / etc. | `@shared_task` |
| Propósito | O que faz (uma frase) | Envia email semanal com posts novos |
| Schedule | Se periódica, qual a frequência | `crontab(hour=8, day_of_week=1)` |

## Admin (`admin.py`)

Para cada registro:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Model | Model registrado | `Post` |
| Classe | `ModelAdmin` customizado ou registro simples | `PostAdmin(ModelAdmin)` |
| Customizações notáveis | `list_display`, `list_filter`, `search_fields`, `inlines` | `list_display=["title", "author", "published"]` |

## Services (`services.py`) e Managers (`managers.py`)

Apenas listar:
- **Services**: nome da função + propósito (uma frase)
- **Managers**: nome do manager + querysets customizados que expõe

## Forms (`forms.py`)

Para cada form:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe | `PostForm` |
| Tipo | `ModelForm` / `Form` | `ModelForm` |
| Model | Model associado (se ModelForm) | `Post` |
| Campos | `fields` ou `exclude` | `fields = ["title", "body"]` |
| Validações | Métodos `clean_*` — descrever regra | `clean_title: mín 10 caracteres` |

## Permissions (`permissions.py`)

Para cada permission:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe | `IsOwnerOrReadOnly` |
| Tipo | DRF BasePermission / Django Permission | `BasePermission` |
| Regra | Lógica resumida (uma frase) | Permite escrita apenas se `obj.author == request.user` |

## Filters (`filters.py`)

Para cada filterset:

| Campo | O que extrair | Exemplo |
|-------|--------------|---------|
| Nome | Nome da classe | `PostFilter` |
| Model | Model associado | `Post` |
| Campos | Campos de filtro disponíveis | `title, author, published, created_at` |
