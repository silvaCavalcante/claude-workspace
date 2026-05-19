#!/usr/bin/env bash
#
# sonar-analyze.sh — Análise local SonarQube pra projetos .NET
# 
# Uso:
#   ./sonar-analyze.sh                    # roda análise completa
#   ./sonar-analyze.sh --skip-scan        # pula scan, só busca issues
#   ./sonar-analyze.sh --json             # saída em JSON puro
#
# Pré-requisitos:
#   - SonarQube rodando (default: http://localhost:9000)
#   - dotnet-sonarscanner instalado: dotnet tool install --global dotnet-sonarscanner
#   - jq instalado pra parsear JSON
#   - Variáveis abaixo configuradas (ou via .env)

set -euo pipefail

# ============================================================
# CONFIGURAÇÃO — ajuste aqui ou exporte como env vars
# ============================================================
SONAR_HOST="${SONAR_HOST:-http://localhost:9000}"
SONAR_TOKEN="${SONAR_TOKEN:-}"
PROJECT_KEY="${SONAR_PROJECT_KEY:-meu-projeto-local}"
PROJECT_NAME="${SONAR_PROJECT_NAME:-Meu Projeto Local}"
SOLUTION_FILE="${SOLUTION_FILE:-}"  # ex: MinhaSolution.sln (autodetect se vazio)

# Carrega .env se existir
if [[ -f .env.sonar ]]; then
  # shellcheck disable=SC1091
  source .env.sonar
fi

# ============================================================
# CORES E HELPERS
# ============================================================
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $*"; }
ok()     { echo -e "${GREEN}✓${NC} $*"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $*"; }
err()    { echo -e "${RED}✗${NC} $*" >&2; }
die()    { err "$*"; exit 1; }

# ============================================================
# VALIDAÇÕES
# ============================================================
[[ -z "$SONAR_TOKEN" ]] && die "SONAR_TOKEN não definido. Exporta a variável ou cria .env.sonar"

command -v dotnet >/dev/null || die "dotnet não encontrado no PATH"
command -v jq >/dev/null || die "jq não encontrado. Instala com 'apt install jq' ou 'brew install jq'"
command -v curl >/dev/null || die "curl não encontrado"

# Verifica se o scanner tá instalado
if ! dotnet tool list --global | grep -q dotnet-sonarscanner; then
  warn "dotnet-sonarscanner não instalado. Instalando..."
  dotnet tool install --global dotnet-sonarscanner
fi

# Autodetect da solution se não foi passada
if [[ -z "$SOLUTION_FILE" ]]; then
  SOLUTION_FILE=$(find . -maxdepth 2 -name "*.sln" -type f | head -n1)
  [[ -z "$SOLUTION_FILE" ]] && die "Nenhum .sln encontrado. Defina SOLUTION_FILE."
  log "Solution detectada: $SOLUTION_FILE"
fi

# Verifica conexão com Sonar
if ! curl -fsS -u "$SONAR_TOKEN:" "$SONAR_HOST/api/system/status" >/dev/null 2>&1; then
  die "Não consegui conectar em $SONAR_HOST. SonarQube tá rodando?"
fi

# ============================================================
# PARSE DE ARGS
# ============================================================
SKIP_SCAN=false
OUTPUT_JSON=false
for arg in "$@"; do
  case $arg in
    --skip-scan) SKIP_SCAN=true ;;
    --json)      OUTPUT_JSON=true ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) die "Argumento desconhecido: $arg" ;;
  esac
done

# ============================================================
# ETAPA 1: SCAN
# ============================================================
if [[ "$SKIP_SCAN" == "false" ]]; then
  log "Iniciando análise SonarQube..."
  
  dotnet sonarscanner begin \
    /k:"$PROJECT_KEY" \
    /n:"$PROJECT_NAME" \
    /d:sonar.host.url="$SONAR_HOST" \
    /d:sonar.token="$SONAR_TOKEN" \
    /d:sonar.scanner.scanAll=false \
    > /tmp/sonar-begin.log 2>&1 || { cat /tmp/sonar-begin.log; die "Falha no begin"; }
  ok "Scanner inicializado"

  log "Compilando solution..."
  dotnet build "$SOLUTION_FILE" --no-incremental > /tmp/sonar-build.log 2>&1 \
    || { tail -50 /tmp/sonar-build.log; die "Build falhou"; }
  ok "Build concluído"

  log "Enviando resultados pro SonarQube..."
  dotnet sonarscanner end /d:sonar.token="$SONAR_TOKEN" \
    > /tmp/sonar-end.log 2>&1 || { cat /tmp/sonar-end.log; die "Falha no end"; }
  ok "Análise enviada"
  
  # Espera o Sonar processar (background task)
  log "Aguardando processamento server-side..."
  for i in {1..30}; do
    STATUS=$(curl -fsS -u "$SONAR_TOKEN:" \
      "$SONAR_HOST/api/ce/component?component=$PROJECT_KEY" \
      | jq -r '.current.status // "PENDING"')
    if [[ "$STATUS" == "SUCCESS" ]]; then
      ok "Processamento concluído"
      break
    elif [[ "$STATUS" == "FAILED" || "$STATUS" == "CANCELED" ]]; then
      die "Processamento falhou no servidor: $STATUS"
    fi
    sleep 2
  done
fi

# ============================================================
# ETAPA 2: BUSCAR ISSUES NOVOS
# ============================================================
log "Buscando issues novos (new code period)..."

ISSUES_JSON=$(curl -fsS -u "$SONAR_TOKEN:" \
  "$SONAR_HOST/api/issues/search?componentKeys=$PROJECT_KEY&sinceLeakPeriod=true&resolved=false&ps=500&s=SEVERITY&asc=false")

QG_JSON=$(curl -fsS -u "$SONAR_TOKEN:" \
  "$SONAR_HOST/api/qualitygates/project_status?projectKey=$PROJECT_KEY")

if [[ "$OUTPUT_JSON" == "true" ]]; then
  echo "$ISSUES_JSON" | jq .
  exit 0
fi

# ============================================================
# ETAPA 3: RESUMO FORMATADO
# ============================================================
TOTAL=$(echo "$ISSUES_JSON" | jq '.total')
QG_STATUS=$(echo "$QG_JSON" | jq -r '.projectStatus.status')

echo
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Resumo da Análise — $PROJECT_KEY${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"

# Quality Gate
case "$QG_STATUS" in
  OK)    echo -e "Quality Gate: ${GREEN}✓ PASSED${NC}" ;;
  ERROR) echo -e "Quality Gate: ${RED}✗ FAILED${NC}" ;;
  *)     echo -e "Quality Gate: ${YELLOW}$QG_STATUS${NC}" ;;
esac

echo -e "Issues novos: ${BOLD}$TOTAL${NC}"
echo

if [[ "$TOTAL" == "0" ]]; then
  ok "Nenhum issue novo introduzido. Bom pra abrir PR!"
  exit 0
fi

# Contagem por severidade
echo -e "${BOLD}Por severidade:${NC}"
echo "$ISSUES_JSON" | jq -r '
  .issues
  | group_by(.severity)
  | map({sev: .[0].severity, count: length})
  | sort_by(
      if .sev == "BLOCKER" then 0
      elif .sev == "CRITICAL" then 1
      elif .sev == "MAJOR" then 2
      elif .sev == "MINOR" then 3
      else 4 end)
  | .[]
  | "  \(.sev): \(.count)"
'
echo

# Lista detalhada (top 20)
echo -e "${BOLD}Detalhes (top 20):${NC}"
echo "$ISSUES_JSON" | jq -r '
  .issues[:20][]
  | "\(.severity)|\(.component | split(":")[-1])|\(.line // "?")|\(.rule)|\(.message)"
' | while IFS='|' read -r sev file line rule msg; do
  case "$sev" in
    BLOCKER|CRITICAL) color="$RED" ;;
    MAJOR)            color="$YELLOW" ;;
    *)                color="$GRAY" ;;
  esac
  echo -e "  ${color}[$sev]${NC} ${BOLD}$file${NC}:$line"
  echo -e "    ${GRAY}$rule${NC}"
  echo -e "    $msg"
  echo
done

if [[ "$TOTAL" -gt 20 ]]; then
  echo -e "${GRAY}... e mais $((TOTAL - 20)) issues. Use --json pra ver tudo.${NC}"
fi

echo -e "${BOLD}Ver no browser:${NC} $SONAR_HOST/project/issues?id=$PROJECT_KEY&sinceLeakPeriod=true&resolved=false"
echo

# Exit code reflete o Quality Gate (útil pra pre-commit hook)
[[ "$QG_STATUS" == "ERROR" ]] && exit 1 || exit 0
