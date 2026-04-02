# django-claude-kont

Um plugin do Claude Code que turbina o desenvolvimento Django com comandos inteligentes, skills automáticas de boas práticas e agentes especializados.

## Instalação

```bash
claude plugin add django-claude-kont
```

Ou instale pelo GitHub:

```bash
claude plugin add github:lucasviana/django-claude-kont
```

## O que está incluído

### Comandos (invocados pelo usuário)

| Comando | Descrição |
|---------|-----------|
| `/django-model` | Gera modelos Django a partir de uma sintaxe DSL simples |
| `/django-api` | Gera uma API DRF completa (Serializer + ViewSet + URLs) para um modelo |

### Skills (automáticas)

Skills são ativadas automaticamente quando o Claude detecta contexto relevante no seu projeto Django.

| Skill | Ativa quando |
|-------|-------------|
| `django-conventions` | Trabalhando em qualquer código Django — fornece convenções e boas práticas |
| `django-security` | Mexendo em autenticação, formulários, queries — verifica OWASP e diretrizes de segurança Django |
| `django-performance` | Escrevendo queries ou views — detecta N+1, sugere otimizações |

### Agentes (criados pelo Claude)

| Agente | Propósito |
|--------|-----------|
| `django-explorer` | Mapeia um projeto Django existente (models, views, URLs, signals) |
| `django-reviewer` | Revisa código com foco em boas práticas Django |

## Exemplos de uso

### Gerar um modelo

```
/django-model blog Post title:str body:text slug:slug! author:fk:User published:bool published_at:datetime?
```

Isso cria um modelo `Post` em `blog/models.py` com:
- Todos os campos especificados com os tipos de campo Django apropriados
- Timestamps `created_at` / `updated_at`
- Classe `Meta`, `__str__`, e `related_name` nas FKs

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

```
/django-api blog Post --filter=published,author --search=title,body --order=created_at
```

Isso gera:
- `blog/serializers.py` — `PostSerializer` com campos somente leitura apropriados
- `blog/viewsets.py` — `PostViewSet` com filtragem, busca, ordenação
- `blog/urls.py` — Configuração do Router
- Verifica se `rest_framework` está em `INSTALLED_APPS`

### Explorar um projeto

Basta pedir ao Claude para explorar seu projeto:

```
Explore this Django project and map out the architecture
```

O Claude usará automaticamente o agente `django-explorer`.

## Convenções aplicadas

A skill `django-conventions` guia automaticamente o Claude a seguir:

- **Estrutura do projeto**: Organização adequada de apps com services, managers, selectors
- **Padrões de modelo**: Ordenação de campos, convenções de nomenclatura, classe Meta, `__str__`
- **Padrões de view**: Views enxutas, lógica de negócio em services
- **Settings**: Settings divididas, variáveis de ambiente para segredos
- **Testes**: pytest-django, factory_boy, nomenclatura adequada
- **Segurança**: CSRF, ORM em vez de SQL bruto, configurações de autenticação adequadas

## Roadmap

- [ ] `/django-startproject` — Criar um novo projeto com estrutura de boas práticas
- [ ] `/django-startapp` — Criar um novo app com boilerplate completo
- [ ] `/django-test` — Gerar ou executar testes para models/views/APIs
- [ ] `/django-migrate` — Fluxo de migração seguro com verificações
- [ ] Skill `django-security` — Checklist OWASP + segurança Django
- [ ] Skill `django-performance` — Detecção de N+1, otimização de queries
- [ ] Agente `django-reviewer` — Revisão de código com foco em Django

## Contribuição

Contribuições são bem-vindas! Abra uma issue ou PR.