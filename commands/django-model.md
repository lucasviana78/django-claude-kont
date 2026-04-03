---
description: Gera modelos Django a partir de uma sintaxe DSL simples. Suporta tipos de campo, relacionamentos e opções comuns.
argument-hint: <NomeDoApp> <NomeDoModelo> <campo:tipo[:opções]>...
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Gerador de Modelos Django — Claude Code

Você é um comando do Claude Code para geração de modelos Django. Crie modelos Django bem estruturados seguindo boas práticas com base na entrada DSL do usuário.

## Argumentos

O usuário invocou isso com: $ARGUMENTS

## Sintaxe da DSL

```
/django-model <NomeDoApp> <NomeDoModelo> <campo1:tipo[:opção]> <campo2:tipo[:opção]> ...
```

### Tipos de campo suportados

| Tipo DSL | Campo Django | Exemplo |
|----------|-------------|---------|
| `str` | `CharField(max_length=255)` | `name:str` |
| `str:N` | `CharField(max_length=N)` | `code:str:10` |
| `text` | `TextField` | `body:text` |
| `int` | `IntegerField` | `quantity:int` |
| `float` | `FloatField` | `price:float` |
| `decimal` | `DecimalField(max_digits=10, decimal_places=2)` | `amount:decimal` |
| `decimal:D:P` | `DecimalField(max_digits=D, decimal_places=P)` | `price:decimal:8:2` |
| `bool` | `BooleanField(default=False)` | `is_active:bool` |
| `date` | `DateField` | `birth_date:date` |
| `datetime` | `DateTimeField` | `published_at:datetime` |
| `email` | `EmailField` | `email:email` |
| `url` | `URLField` | `website:url` |
| `slug` | `SlugField` | `slug:slug` |
| `uuid` | `UUIDField` | `uuid:uuid` |
| `ip` | `GenericIPAddressField` | `ip_address:ip` |
| `file` | `FileField` | `document:file` |
| `image` | `ImageField` | `avatar:image` |
| `json` | `JSONField` | `metadata:json` |
| `fk:Model` | `ForeignKey(Model)` | `author:fk:User` |
| `o2o:Model` | `OneToOneField(Model)` | `profile:o2o:User` |
| `m2m:Model` | `ManyToManyField(Model)` | `tags:m2m:Tag` |

### Modificadores de campo (adicione com `?` ou `!`)

- Adicione `?` para tornar um campo anulável/em branco: `bio:text?` -> `TextField(null=True, blank=True)`
- Adicione `!` para tornar um campo único: `email:email!` -> `EmailField(unique=True)`
- Adicione `+` para adicionar `db_index=True`: `name:str+` -> `CharField(max_length=255, db_index=True)`

## Instruções

1. **Analise os argumentos** seguindo a sintaxe DSL acima
2. **Localize ou crie o app**: Verifique se o app Django existe no projeto. Se não, pergunte ao usuário se deseja criá-lo.
3. **Verifique o models.py existente**: Leia o `models.py` alvo para entender imports e modelos existentes
4. **Gere o modelo** seguindo estas regras:

### Regras do modelo

- Sempre adicione `class Meta` com `verbose_name` e `verbose_name_plural`
- Sempre adicione o método `__str__` retornando o campo mais representativo
- Sempre adicione `created_at = models.DateTimeField(auto_now_add=True)` e `updated_at = models.DateTimeField(auto_now=True)` a menos que o usuário tenha explicitamente esses campos
- Use `related_name` em ForeignKey e OneToOneField (snake_case no plural do nome do modelo)
- ForeignKey usa `on_delete=models.CASCADE` por padrão — use `models.SET_NULL` se o campo for anulável
- Ordene os campos: PKs primeiro, depois campos regulares, depois relacionamentos, depois timestamps
- Adicione apenas os imports necessários (não duplique imports existentes)
- Se o modelo usa `UUIDField` como PK, importe `uuid` e defina `default=uuid.uuid4, editable=False`

### Exemplo

Entrada:
```
/django-model blog Post title:str body:text slug:slug! author:fk:User published:bool published_at:datetime?
```

Saída em `blog/models.py`:
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

## Após a geração

1. Mostre o modelo gerado ao usuário
2. Pergunte se deseja executar `makemigrations` e `migrate`
3. Sugira registrar o modelo em `admin.py` se ainda não estiver registrado
