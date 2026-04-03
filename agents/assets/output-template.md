# Template de saída — Django Explorer (Claude Code Agent)

Use exatamente esta estrutura. Preencha os dados, remova seções que não se aplicam (ex: DRF em projeto sem DRF). Não adicione seções extras.

---

## 0. Sumário executivo

> Resumo em 3-5 linhas: o que o projeto faz, tamanho (apps/models/views), stack principal, e o padrão de arquitetura dominante.

**Métricas rápidas:**

| Métrica | Valor |
|---------|-------|
| Apps próprios | [N] |
| Models total | [N] |
| Views total | [N] |
| Endpoints de URL | [N] |
| Linhas de código (.py) | [~N estimado] |

## 1. Visão geral

- **Django**: [versão]
- **Python**: [versão ou "não declarada"]
- **Banco de dados**: [engine — ex: PostgreSQL, SQLite]
- **Apps próprios**: [N] apps
- **Apps terceiros notáveis**: [lista — ex: rest_framework, celery, django-filter]
- **Dependências principais**: [lista das top 5-10 do requirements]

## 2. Apps

| App | Propósito | Models | Views | Tem testes |
|-----|-----------|--------|-------|------------|
| [app_name] | [uma frase] | [N] | [N] | Sim/Não |

## 3. Mapa de models

### [app_name]

| Model | Campos chave | Relacionamentos | Métodos notáveis |
|-------|-------------|-----------------|------------------|
| [ModelName] | [campo: tipo, ...] | [→ Model (FK), ↔ Model (M2M)] | [método1, método2] |

> Repetir tabela para cada app.

## 4. Grafo de relacionamentos

```
ModelA → ModelB (FK: campo_name)
ModelA → ModelC (FK: campo_name)
ModelD ↔ ModelE (M2M: campo_name)
ModelF — ModelG (O2O: campo_name)
```

**Models centrais** (≥3 FKs recebidas): [lista]

> Se a análise foi parcial, avise: "⚠ Grafo parcial — baseado apenas nos apps analisados."

## 5. Árvore de URLs

```
/ → home (FBV) [name=home]
/admin/ → Django Admin
/api/
  /api/v1/
    /api/v1/posts/ → PostViewSet (CRUD) [name=post-list]
    /api/v1/posts/<pk>/ → PostViewSet (CRUD) [name=post-detail]
    /api/v1/users/ → UserViewSet (readonly) [name=user-list]
/auth/
  /auth/login/ → LoginView (CBV) [name=login]
  /auth/logout/ → LogoutView (CBV) [name=logout]
```

## 6. Padrões de arquitetura

- **Organização de lógica**: [fat models / thin models + services / misto]
- **Views**: [FBV / CBV / ViewSets / misto]
- **Interface**: [template-based / API-only / híbrido]
- **Autenticação**: [session / JWT / token / OAuth / misto]
- **Task queue**: [Celery / Django-Q / nenhum]
- **Cache**: [Redis / Memcached / nenhum]
- **Testes**: [pytest-django / unittest / nenhum visível]

## 7. Arquivos principais para leitura

Ordenados por relevância (mais dependências + mais lógica de negócio):

| # | Arquivo | Por que ler |
|---|---------|-------------|
| 1 | [path/to/file.py] | [razão concreta — ex: "model central com 8 FKs recebidas"] |
| 2 | [path/to/file.py] | [razão] |
| ... | | |

> Liste 10-15 arquivos. Critérios de rankeamento:
> 1. Número de dependências (outros apps importam deste)
> 2. Quantidade de lógica de negócio
> 3. Complexidade de relacionamentos

## 8. Observações

Reporte **apenas itens factuais verificáveis**. Use esta checklist:

- [ ] Models sem `__str__`
- [ ] ForeignKeys sem `related_name` explícito
- [ ] Views com lógica de negócio inline (>20 linhas no método)
- [ ] Apps sem diretório/arquivo de testes
- [ ] Migrations com `RunPython` sem `reverse_code`
- [ ] Querysets sem `select_related`/`prefetch_related` em views que acessam FKs
- [ ] Settings com `DEBUG = True` hardcoded (sem variável de ambiente)
- [ ] `SECRET_KEY` hardcoded no settings
- [ ] Ausência de `AUTH_PASSWORD_VALIDATORS`

> Marque apenas os itens que **de fato encontrou**. Remova os que não se aplicam. Não especule.

## 9. Próximos passos sugeridos

Liste 3-5 ações concretas que o desenvolvedor poderia tomar, baseadas no que foi encontrado. Exemplos:
- "Para gerar uma API para o model X, use `/django-api app Model`"
- "O app Y tem 15 models sem testes — priorizar cobertura"
- "Considere extrair lógica de negócio das views de Z para services.py"
