#!/usr/bin/env bash
# validate-md.sh — Hook PostToolUse de validação para .md operacionais de .claude/
#
# Schema source-of-truth: conventions/frontmatter.md (sincronizar manualmente).
# Última sincronização: 2026-05-19 (b1).
#
# Saída: exit 0 sempre. Warnings em stderr (texto puro, PT).
# Decisão: warning-only permanente (b7, 2026-05-19).

set -u

# 1. Ler JSON do stdin e extrair file_path
INPUT="$(cat)"
FILE_PATH="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Normalizar path (backslash → forward-slash)
NORMALIZED="$(printf '%s' "$FILE_PATH" | tr '\\' '/')"

# 2. Pular se não for .md
case "$NORMALIZED" in
    *.md) ;;
    *) exit 0 ;;
esac

# 3. Detectar pasta operacional e tipo
WORKSPACE_ROOT='C:/reposit/CoreonCap/.claude'
case "$NORMALIZED" in
    "$WORKSPACE_ROOT"/specs/features/*) TYPE='features' ;;
    "$WORKSPACE_ROOT"/specs/bugs/*)     TYPE='bugs' ;;
    "$WORKSPACE_ROOT"/plans/*)          TYPE='plans' ;;
    "$WORKSPACE_ROOT"/analyses/*)       TYPE='analyses' ;;
    "$WORKSPACE_ROOT"/conventions/*)    TYPE='conventions' ;;
    *) exit 0 ;;
esac

# 4. Excluir subpastas completed/ e future/
case "$NORMALIZED" in
    */completed/*|*/future/*) exit 0 ;;
esac

BASENAME="$(basename "$NORMALIZED")"

WARNINGS=""
warn() { WARNINGS="${WARNINGS}- ${1}"$'\n'; }

# 5. Validar naming
case "$BASENAME" in
    _*.md|README.md|INDEX.md)
        # exceção — sem validação de naming
        ;;
    *)
        if [ "$TYPE" = 'conventions' ]; then
            # conventions: kebab-case.md (sem data)
            if ! printf '%s' "$BASENAME" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*\.md$'; then
                warn "Naming fora do padrão em conventions/: esperado kebab-case.md (sem data). Atual: $BASENAME"
            fi
        else
            # demais: YYYY-MM-DD-kebab-case.md
            if ! printf '%s' "$BASENAME" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.md$'; then
                warn "Naming fora do padrão em $TYPE/: esperado YYYY-MM-DD-kebab-case.md. Atual: $BASENAME"
            fi
        fi
        ;;
esac

# 6. Extrair frontmatter (linhas entre o primeiro e o segundo ---)
if [ ! -f "$NORMALIZED" ]; then
    # arquivo ainda não está no disco (raro pós-Write) — pular validação de frontmatter
    [ -n "$WARNINGS" ] && printf 'validate-md: warnings em %s\n%s' "$BASENAME" "$WARNINGS" >&2
    exit 0
fi

FRONTMATTER="$(awk '/^---$/{f++; if (f==2) exit; next} f==1' "$NORMALIZED")"

if [ -z "$FRONTMATTER" ]; then
    warn "Frontmatter YAML ausente. Esperado bloco entre --- ... --- no topo do arquivo."
    printf 'validate-md: warnings em %s\n%s' "$BASENAME" "$WARNINGS" >&2
    exit 0
fi

field_value() {
    printf '%s' "$FRONTMATTER" | grep -E "^${1}:" | head -n1 | sed -E "s/^${1}:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]+$//"
}

has_field() {
    printf '%s' "$FRONTMATTER" | grep -Eq "^${1}:"
}

check_required() {
    if ! has_field "$1"; then
        warn "Campo obrigatório ausente no frontmatter: $1"
    fi
}

check_enum() {
    local field="$1"; shift
    local value
    value="$(field_value "$field")"
    if [ -z "$value" ]; then return; fi
    for allowed in "$@"; do
        if [ "$value" = "$allowed" ]; then return; fi
    done
    warn "Valor inválido para $field: '$value'. Esperado um de: $*"
}

# 7. Validar por tipo
case "$TYPE" in
    features)
        check_required title
        check_required status
        check_required created
        check_required tem-ui
        check_enum status draft aprovado em-implementação concluído
        ;;
    bugs)
        check_required title
        check_required status
        check_required created
        check_required severidade
        check_required tem-ui
        check_enum status draft aprovado em-implementação concluído
        check_enum severidade baixa média alta crítica
        ;;
    plans)
        check_required title
        check_required status
        check_required created
        check_required spec
        check_enum status draft em-execução concluído
        ;;
    analyses)
        check_required title
        check_required status
        check_required created
        check_enum status draft concluído
        ;;
    conventions)
        check_required title
        check_required status
        check_required last-reviewed
        check_enum status active deprecated
        ;;
esac

# 8. Emitir warnings (se houver) — exit 0 sempre
if [ -n "$WARNINGS" ]; then
    printf 'validate-md: warnings em %s\n%s' "$BASENAME" "$WARNINGS" >&2
fi

exit 0
