#!/bin/bash

# =============================================================================
# change_app_name.sh — Atualiza o nome do app no Android e iOS
#
# Atualiza:
#   - Android: manifestPlaceholders["appName"] em android/app/build.gradle.kts
#   - iOS: FLAVOR_APP_NAME em ios/Runner.xcodeproj/project.pbxproj
#
# Uso:
#   ./change_app_name.sh --base-name "Drift Space" --all
#   ./change_app_name.sh --flavor staging --name "[STG] Biblia IA"
#   ./change_app_name.sh development staging --name "Biblia IA"
#   ./change_app_name.sh --production-name "Biblia IA" --staging-name "[HML] Biblia IA"
#
# Regras:
#   - --base-name gera nomes padrao por flavor:
#       production  -> <base>
#       staging     -> [STG] <base>
#       development -> [DEV] <base>
#   - --name aplica o mesmo nome aos flavors selecionados
#   - --production-name/--staging-name/--development-name sobrescrevem casos
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

VALID_FLAVORS=("development" "staging" "production")
ANDROID_GRADLE_FILE="android/app/build.gradle.kts"
IOS_PBXPROJ_FILE="ios/Runner.xcodeproj/project.pbxproj"

APP_NAME_PRODUCTION=""
APP_NAME_STAGING=""
APP_NAME_DEVELOPMENT=""
OVERRIDE_NAME_PRODUCTION=""
OVERRIDE_NAME_STAGING=""
OVERRIDE_NAME_DEVELOPMENT=""

SELECTED_FLAVORS=()
APPLY_TO_ALL=false
BASE_NAME=""
SHARED_NAME=""

log_info()    { echo -e "${BLUE}INFO  $1${NC}"; }
log_success() { echo -e "${GREEN}OK    $1${NC}"; }
log_warn()    { echo -e "${YELLOW}WARN  $1${NC}"; }
log_error()   { echo -e "${RED}ERROR $1${NC}"; }
log_step()    { echo -e "${CYAN}STEP  $1${NC}"; }

show_usage() {
  echo ""
  echo "Uso:"
  echo "  ./change_app_name.sh --base-name \"Biblia IA\" --all"
  echo "  ./change_app_name.sh --flavor staging --name \"[STG] Biblia IA\""
  echo "  ./change_app_name.sh development staging --name \"Biblia IA\""
  echo "  ./change_app_name.sh --production-name \"Biblia IA\" --staging-name \"[HML] Biblia IA\""
  echo ""
  echo "Flavors disponiveis:"
  echo "  development | staging | production"
  echo ""
  echo "Opcoes:"
  echo "  --all                  Atualiza todos os flavors"
  echo "  --flavor <flavor>      Seleciona um flavor especifico"
  echo "  --name <nome>          Aplica o mesmo nome aos flavors selecionados"
  echo "  --base-name <nome>     Gera nomes padrao por flavor"
  echo "  --production-name <n>  Define nome explicito do production"
  echo "  --staging-name <n>     Define nome explicito do staging"
  echo "  --development-name <n> Define nome explicito do development"
  echo "  --help                 Exibe esta ajuda"
  echo ""
  echo "Exemplos:"
  echo "  ./change_app_name.sh --base-name \"Biblia IA\" --all"
  echo "  ./change_app_name.sh --base-name \"Biblia IA\""
  echo "  ./change_app_name.sh --flavor production --name \"Biblia IA\""
  echo "  ./change_app_name.sh staging development --name \"Biblia IA Preview\""
  echo ""
}

is_valid_flavor() {
  local flavor="$1"
  for item in "${VALID_FLAVORS[@]}"; do
    [ "$item" = "$flavor" ] && return 0
  done
  return 1
}

append_selected_flavor() {
  local flavor="$1"
  local current

  for current in "${SELECTED_FLAVORS[@]}"; do
    [ "$current" = "$flavor" ] && return 0
  done

  SELECTED_FLAVORS+=("$flavor")
}

select_all_flavors() {
  local flavor
  for flavor in "${VALID_FLAVORS[@]}"; do
    append_selected_flavor "$flavor"
  done
}

set_name_for_flavor() {
  local flavor="$1"
  local value="$2"

  case "$flavor" in
    production) APP_NAME_PRODUCTION="$value" ;;
    staging) APP_NAME_STAGING="$value" ;;
    development) APP_NAME_DEVELOPMENT="$value" ;;
    *)
      log_error "Flavor invalido para set_name_for_flavor: $flavor"
      exit 1
      ;;
  esac
}

get_name_for_flavor() {
  local flavor="$1"

  case "$flavor" in
    production) printf '%s' "$APP_NAME_PRODUCTION" ;;
    staging) printf '%s' "$APP_NAME_STAGING" ;;
    development) printf '%s' "$APP_NAME_DEVELOPMENT" ;;
    *)
      log_error "Flavor invalido para get_name_for_flavor: $flavor"
      exit 1
      ;;
  esac
}

get_override_name_for_flavor() {
  local flavor="$1"

  case "$flavor" in
    production) printf '%s' "$OVERRIDE_NAME_PRODUCTION" ;;
    staging) printf '%s' "$OVERRIDE_NAME_STAGING" ;;
    development) printf '%s' "$OVERRIDE_NAME_DEVELOPMENT" ;;
    *)
      log_error "Flavor invalido para get_override_name_for_flavor: $flavor"
      exit 1
      ;;
  esac
}

default_name_for_flavor() {
  local flavor="$1"
  local base_name="$2"

  case "$flavor" in
    production) printf '%s' "$base_name" ;;
    staging) printf '[STG] %s' "$base_name" ;;
    development) printf '[DEV] %s' "$base_name" ;;
    *)
      log_error "Flavor invalido para default_name_for_flavor: $flavor"
      exit 1
      ;;
  esac
}

validate_name() {
  local label="$1"
  local value="$2"

  if [ -z "$value" ]; then
    log_error "Nome vazio para $label"
    exit 1
  fi

  if [[ "$value" == *$'\n'* ]]; then
    log_error "O nome '$label' nao pode conter quebra de linha"
    exit 1
  fi

  if [[ "$value" == *'"'* ]]; then
    log_error "O nome '$label' nao pode conter aspas duplas"
    exit 1
  fi
}

ensure_required_files() {
  [ -f "$ANDROID_GRADLE_FILE" ] || { log_error "Arquivo nao encontrado: $ANDROID_GRADLE_FILE"; exit 1; }
  [ -f "$IOS_PBXPROJ_FILE" ] || { log_error "Arquivo nao encontrado: $IOS_PBXPROJ_FILE"; exit 1; }
}

update_android_name() {
  local flavor="$1"
  local app_name="$2"
  local tmp_file

  tmp_file=$(mktemp)

  if ! APP_NAME="$app_name" FLAVOR="$flavor" perl -0e '
    use strict;
    use warnings;

    local $/;
    my $content = <>;
    my $flavor = quotemeta($ENV{FLAVOR});
    my $name = $ENV{APP_NAME};
    my $count = ($content =~ s{(create\("$flavor"\)\s*\{.*?manifestPlaceholders\["appName"\]\s*=\s*")[^"]*(")}{$1.$name.$2}egs);

    die "Falha ao atualizar appName do Android para $ENV{FLAVOR}\n" if $count == 0;
    print $content;
  ' "$ANDROID_GRADLE_FILE" > "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$ANDROID_GRADLE_FILE"
}

update_ios_name() {
  local flavor="$1"
  local app_name="$2"
  local tmp_file

  tmp_file=$(mktemp)

  if ! APP_NAME="$app_name" FLAVOR="$flavor" perl -0e '
    use strict;
    use warnings;

    local $/;
    my $content = <>;
    my $flavor = $ENV{FLAVOR};
    my $name = $ENV{APP_NAME};

    # Anchors to the correct flavor block and stays within its buildSettings = { ... }
    # to avoid spanning across blocks of other flavors.
    # [^{]*?  -- content before buildSettings (stops at any {, so no cross-block scanning)
    # [^}]*?  -- content inside buildSettings before FLAVOR_APP_NAME (stops at })
    my $count = ($content =~ s{
      ( /\* \ (?:Debug|Release|Profile) - \Q$flavor\E \ \*/ \ = \ \{ )
      ( [^{]*? )
      ( buildSettings \ = \ \{ )
      ( [^}]*? )
      ( FLAVOR_APP_NAME \ = \ )
      (?: "[^"]*" | [^\s;]+ )
      ( ; )
    }{$1$2$3$4$5"$name"$6}gxs);

    die "Falha ao atualizar FLAVOR_APP_NAME do iOS para $ENV{FLAVOR}\n" if $count == 0;
    print $content;
  ' "$IOS_PBXPROJ_FILE" > "$tmp_file"; then
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$IOS_PBXPROJ_FILE"
}

build_name_plan() {
  local flavor
  local desired_name

  if [ "$APPLY_TO_ALL" = true ]; then
    select_all_flavors
  fi

  if [ -n "$BASE_NAME" ]; then
    if [ ${#SELECTED_FLAVORS[@]} -eq 0 ]; then
      select_all_flavors
    fi

    for flavor in "${SELECTED_FLAVORS[@]}"; do
      desired_name=$(default_name_for_flavor "$flavor" "$BASE_NAME")
      set_name_for_flavor "$flavor" "$desired_name"
    done
  fi

  if [ -n "$SHARED_NAME" ]; then
    if [ ${#SELECTED_FLAVORS[@]} -eq 0 ]; then
      log_error "Use --name com flavors explicitos ou com --all"
      exit 1
    fi

    for flavor in "${SELECTED_FLAVORS[@]}"; do
      set_name_for_flavor "$flavor" "$SHARED_NAME"
    done
  fi

  for flavor in "${VALID_FLAVORS[@]}"; do
    desired_name=$(get_override_name_for_flavor "$flavor")
    if [ -n "$desired_name" ]; then
      set_name_for_flavor "$flavor" "$desired_name"
    fi
  done

  for flavor in "${VALID_FLAVORS[@]}"; do
    desired_name=$(get_name_for_flavor "$flavor")
    if [ -n "$desired_name" ]; then
      append_selected_flavor "$flavor"
    fi
  done

  if [ ${#SELECTED_FLAVORS[@]} -eq 0 ]; then
    log_error "Nenhum flavor selecionado"
    show_usage
    exit 1
  fi

  for flavor in "${SELECTED_FLAVORS[@]}"; do
    desired_name=$(get_name_for_flavor "$flavor")
    if [ -z "$desired_name" ]; then
      log_error "Nenhum nome definido para o flavor '$flavor'"
      exit 1
    fi
    validate_name "$flavor" "$desired_name"
  done
}

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}        change_app_name.sh            ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

if [ $# -eq 0 ]; then
  show_usage
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      show_usage
      exit 0
      ;;
    --all)
      APPLY_TO_ALL=true
      shift
      ;;
    --flavor)
      [ -n "$2" ] || { log_error "Informe o flavor apos --flavor"; exit 1; }
      is_valid_flavor "$2" || { log_error "Flavor invalido: '$2'"; exit 1; }
      append_selected_flavor "$2"
      shift 2
      ;;
    --name)
      [ -n "$2" ] || { log_error "Informe o nome apos --name"; exit 1; }
      SHARED_NAME="$2"
      shift 2
      ;;
    --base-name)
      [ -n "$2" ] || { log_error "Informe o nome apos --base-name"; exit 1; }
      BASE_NAME="$2"
      shift 2
      ;;
    --production-name)
      [ -n "$2" ] || { log_error "Informe o nome apos --production-name"; exit 1; }
      OVERRIDE_NAME_PRODUCTION="$2"
      shift 2
      ;;
    --staging-name)
      [ -n "$2" ] || { log_error "Informe o nome apos --staging-name"; exit 1; }
      OVERRIDE_NAME_STAGING="$2"
      shift 2
      ;;
    --development-name)
      [ -n "$2" ] || { log_error "Informe o nome apos --development-name"; exit 1; }
      OVERRIDE_NAME_DEVELOPMENT="$2"
      shift 2
      ;;
    --*)
      log_error "Opcao desconhecida: $1"
      show_usage
      exit 1
      ;;
    *)
      is_valid_flavor "$1" || { log_error "Flavor invalido: '$1'"; exit 1; }
      append_selected_flavor "$1"
      shift
      ;;
  esac
done

ensure_required_files
build_name_plan

echo ""
log_step "Plano de atualizacao:"
for flavor in "${VALID_FLAVORS[@]}"; do
  name="$(get_name_for_flavor "$flavor")"
  if [ -n "$name" ]; then
    echo "  - $flavor -> $name"
  fi
done

echo ""
log_step "Atualizando Android e iOS..."
for flavor in "${VALID_FLAVORS[@]}"; do
  name="$(get_name_for_flavor "$flavor")"
  if [ -z "$name" ]; then
    continue
  fi

  update_android_name "$flavor" "$name"
  update_ios_name "$flavor" "$name"
  log_success "$flavor atualizado para '$name'"
done

echo ""
log_success "Nomes do app atualizados com sucesso!"
echo ""
log_info "Android -> $ANDROID_GRADLE_FILE"
log_info "iOS     -> $IOS_PBXPROJ_FILE"
echo ""
