#!/usr/bin/env bash
# Django Project Inventory — quick sizing before detailed analysis
# Usage: bash assets/django-inventory.sh [project_root]
# Returns structured counts for the agent to decide analysis mode.

set -euo pipefail

ROOT="${1:-.}"

echo "=== Django Project Inventory ==="
echo ""

# Total .py files
PY_COUNT=$(find "$ROOT" -name "*.py" -not -path "*/migrations/*" -not -path "*/.venv/*" -not -path "*/venv/*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*" | wc -l)
echo "Total .py files (excl. migrations): $PY_COUNT"

# Find manage.py locations
echo ""
echo "--- manage.py locations ---"
find "$ROOT" -name "manage.py" -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null || echo "None found"

# Find settings
echo ""
echo "--- Settings files ---"
find "$ROOT" \( -name "settings.py" -o -path "*/settings/*.py" -o -path "*/config/settings*.py" \) -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null || echo "None found"

# Count apps (directories with apps.py or models.py, excluding venv)
echo ""
echo "--- Apps (dirs with apps.py) ---"
APP_DIRS=$(find "$ROOT" -name "apps.py" -not -path "*/.venv/*" -not -path "*/venv/*" -not -path "*/site-packages/*" 2>/dev/null | sed 's|/apps.py||' | sort)
APP_COUNT=0
for APP_DIR in $APP_DIRS; do
    APP_NAME=$(basename "$APP_DIR")
    MODEL_COUNT=$(grep -c "class.*models\.Model\|class.*Model)" "$APP_DIR/models.py" 2>/dev/null || echo 0)
    VIEW_FILES=$(find "$APP_DIR" \( -name "views.py" -o -name "viewsets.py" -o -path "*/views/*.py" \) 2>/dev/null | head -10)
    VIEW_COUNT=0
    for VF in $VIEW_FILES; do
        VC=$(grep -c "class\|^def " "$VF" 2>/dev/null || echo 0)
        VIEW_COUNT=$((VIEW_COUNT + VC))
    done
    HAS_TESTS="No"
    if [ -d "$APP_DIR/tests" ] || [ -f "$APP_DIR/tests.py" ] || ls "$APP_DIR"/test_*.py 1>/dev/null 2>&1; then
        HAS_TESTS="Yes"
    fi
    echo "  $APP_NAME: models=$MODEL_COUNT views=~$VIEW_COUNT tests=$HAS_TESTS"
    APP_COUNT=$((APP_COUNT + 1))
done
echo ""
echo "Total apps: $APP_COUNT"

# Dependencies
echo ""
echo "--- Dependencies ---"
for DEP_FILE in requirements.txt Pipfile pyproject.toml setup.cfg; do
    FOUND=$(find "$ROOT" -maxdepth 2 -name "$DEP_FILE" -not -path "*/.venv/*" -not -path "*/venv/*" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        echo "Found: $FOUND"
        DJANGO_VER=$(grep -i "django" "$FOUND" 2>/dev/null | head -3)
        if [ -n "$DJANGO_VER" ]; then
            echo "  Django: $DJANGO_VER"
        fi
    fi
done

echo ""
echo "=== End Inventory ==="
