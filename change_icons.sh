#!/bin/bash

# =============================================================================
# change_icons.sh — Gera ícones do app para os flavors especificados
#
# Usa o pacote flutter_launcher_icons com suporte a flavors.
# O pacote detecta flavors automaticamente via arquivos separados:
#   flutter_launcher_icons-<flavor>.yaml
#
# Uso:
#   ./change_icons.sh <flavor> [flavor2 ...]
#   ./change_icons.sh --all
#   ./change_icons.sh --clean --all
#   ./change_icons.sh --flavor <flavor> --icon <path>
#
# Exemplos:
#   ./change_icons.sh development
#   ./change_icons.sh staging production
#   ./change_icons.sh --all
#   ./change_icons.sh --clean --all
#   ./change_icons.sh --flavor development --icon assets/icons/dev_icon.png
#
# Estrutura de ícones esperada:
#   assets/icons/
#   ├── development/
#   │   └── icon.png          (obrigatório, mínimo 1024x1024)
#   ├── staging/
#   │   └── icon.png
#   └── production/
#       └── icon.png
#
# Para ícones adaptativos (Android), adicione também:
#   assets/icons/<flavor>/icon_foreground.png
#   assets/icons/<flavor>/icon_background.png
#
# IMPORTANTE:
#   - O AndroidManifest.xml referencia @mipmap/launcher_icon
#   - Cada flavor gera um arquivo flutter_launcher_icons-<flavor>.yaml
#   - O pacote auto-detecta esses arquivos e gera ícones em:
#     Android: android/app/src/<flavor>/res/mipmap-*/launcher_icon.png
#     iOS: ios/Runner/Assets.xcassets/AppIcon-<flavor>.appiconset/
#   - O .pbxproj do iOS é atualizado com o AppIcon correto por flavor
# =============================================================================

set -e

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Constantes ---
ICONS_DIR="assets/icons"
VALID_FLAVORS=("development" "staging" "production")
# Nome do ícone no AndroidManifest.xml — DEVE ser consistente
ANDROID_ICON_NAME="launcher_icon"
CLEAN_MODE=false
IOS_FLATTEN_BACKGROUND_HEX="FFFFFF"
LEGACY_IOS_WORK_DIR=".dart_tool/change_icons_ios"
PREPARED_IOS_ICON=""

# --- Helpers ---
log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_step()    { echo -e "${CYAN}▶  $1${NC}"; }

# Valida se o flavor é reconhecido
is_valid_flavor() {
  local flavor="$1"
  for f in "${VALID_FLAVORS[@]}"; do
    [[ "$f" == "$flavor" ]] && return 0
  done
  return 1
}

# Retorna o caminho do ícone de um flavor
icon_path_for_flavor() {
  local flavor="$1"
  local custom_path="$2"

  if [ -n "$custom_path" ]; then
    echo "$custom_path"
  else
    echo "$ICONS_DIR/$flavor/icon.png"
  fi
}

# Retorna o nome do YAML de config para um flavor
yaml_file_for_flavor() {
  local flavor="$1"
  echo "flutter_launcher_icons-${flavor}.yaml"
}

ios_generated_icon_path() {
  local flavor="$1"
  echo "$ICONS_DIR/$flavor/icon_ios.jpg"
}

prepare_ios_icon() {
  local icon="$1"
  local flavor="$2"
  local output

  if ! command -v swift >/dev/null 2>&1; then
    log_warn "swift não encontrado; mantendo o PNG original para iOS no flavor '$flavor'" >&2
    PREPARED_IOS_ICON="$icon"
    return 0
  fi

  output=$(ios_generated_icon_path "$flavor")
  mkdir -p "$(dirname "$output")"

  if ! swift -e '
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
  fatalError("usage: swift -e <script> <input> <output> <backgroundHex>")
}

let input = URL(fileURLWithPath: arguments[1])
let output = URL(fileURLWithPath: arguments[2])
let backgroundHex = arguments[3].trimmingCharacters(in: CharacterSet(charactersIn: "#"))

guard backgroundHex.count == 6 else {
  fatalError("backgroundHex must be 6 hex chars")
}

func component(_ start: String.Index) -> CGFloat {
  let end = backgroundHex.index(start, offsetBy: 2)
  let value = Int(backgroundHex[start..<end], radix: 16)!
  return CGFloat(value) / 255.0
}

let redIndex = backgroundHex.startIndex
let greenIndex = backgroundHex.index(redIndex, offsetBy: 2)
let blueIndex = backgroundHex.index(greenIndex, offsetBy: 2)
let backgroundColor = NSColor(
  red: component(redIndex),
  green: component(greenIndex),
  blue: component(blueIndex),
  alpha: 1.0
)

guard
  let image = NSImage(contentsOf: input),
  let tiff = image.tiffRepresentation,
  let source = NSBitmapImageRep(data: tiff),
  let target = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: source.pixelsWide,
    pixelsHigh: source.pixelsHigh,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ),
  let context = NSGraphicsContext(bitmapImageRep: target)
else {
  fatalError("failed to load icon")
}

let size = NSSize(width: source.pixelsWide, height: source.pixelsHigh)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
backgroundColor.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
image.draw(
  in: NSRect(origin: .zero, size: size),
  from: .zero,
  operation: .sourceOver,
  fraction: 1
)
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let data = target.representation(using: .jpeg, properties: [.compressionFactor: 1.0]) else {
  fatalError("failed to encode flattened icon")
}

try data.write(to: output)
' "$icon" "$output" "$IOS_FLATTEN_BACKGROUND_HEX"; then
    log_error "Falha ao preparar o ícone de iOS para o flavor '$flavor'" >&2
    return 1
  fi

  PREPARED_IOS_ICON="$output"
  log_info "Ícone iOS preparado para '$flavor': $output" >&2
}

# Verifica se o arquivo de ícone existe
check_icon_exists() {
  local icon="$1"
  local flavor="$2"

  if [ ! -f "$icon" ]; then
    log_error "Ícone não encontrado para o flavor '$flavor': $icon"
    echo ""
    echo "  Crie o arquivo em: $icon"
    echo "  Ou use: ./change_icons.sh --flavor $flavor --icon <caminho_do_icone>"
    return 1
  fi
  return 0
}

# Limpa ícones antigos gerados pelo flutter_launcher_icons
clean_generated_icons() {
  log_step "Limpando ícones gerados anteriormente..."

  # Android: limpa mipmap com launcher_icon nos diretórios de flavor
  for flavor in "${VALID_FLAVORS[@]}"; do
    local android_flavor_dir="android/app/src/$flavor/res"
    if [ -d "$android_flavor_dir" ]; then
      find "$android_flavor_dir" -name "${ANDROID_ICON_NAME}*" -delete 2>/dev/null || true
      find "$android_flavor_dir" -name "ic_launcher*" -delete 2>/dev/null || true
      # Remove diretórios mipmap vazios
      find "$android_flavor_dir" -type d -name "mipmap-*" -empty -delete 2>/dev/null || true
      log_info "  Limpo: $android_flavor_dir"
    fi
  done

  # Android: limpa ícones com nomes antigos errados no main
  local android_main_dir="android/app/src/main/res"
  if [ -d "$android_main_dir" ]; then
    find "$android_main_dir" -name "launcher_icon_dev*" -delete 2>/dev/null || true
    find "$android_main_dir" -name "launcher_icon_stg*" -delete 2>/dev/null || true
    log_info "  Limpo: nomes antigos em $android_main_dir"
  fi

  # iOS: limpa appiconsets de flavors (mantém AppIcon.appiconset com Contents.json)
  local ios_assets="ios/Runner/Assets.xcassets"
  if [ -d "$ios_assets" ]; then
    for flavor in "${VALID_FLAVORS[@]}"; do
      local appiconset="$ios_assets/AppIcon-${flavor}.appiconset"
      if [ -d "$appiconset" ]; then
        rm -rf "$appiconset"
        log_info "  Limpo: $appiconset"
      fi
    done
    # Default AppIcon.appiconset: limpa apenas PNGs, mantém pasta e Contents.json
    local default_appiconset="$ios_assets/AppIcon.appiconset"
    if [ -d "$default_appiconset" ]; then
      find "$default_appiconset" -name "*.png" -delete 2>/dev/null || true
      log_info "  Limpo PNGs: $default_appiconset (pasta mantida)"
    fi
  fi

  # Remove YAML de flavor antigos
  for flavor in "${VALID_FLAVORS[@]}"; do
    local yaml_file
    yaml_file=$(yaml_file_for_flavor "$flavor")
    if [ -f "$yaml_file" ]; then
      rm "$yaml_file"
      log_info "  Limpo: $yaml_file"
    fi

    local ios_generated_icon
    ios_generated_icon=$(ios_generated_icon_path "$flavor")
    if [ -f "$ios_generated_icon" ]; then
      rm "$ios_generated_icon"
      log_info "  Limpo: $ios_generated_icon"
    fi
  done

  # Remove o YAML principal antigo (com o formato errado de flavors:)
  if [ -f "flutter_launcher_icons.yaml" ]; then
    rm "flutter_launcher_icons.yaml"
    log_info "  Limpo: flutter_launcher_icons.yaml"
  fi

  if [ -d "$LEGACY_IOS_WORK_DIR" ]; then
    rm -rf "$LEGACY_IOS_WORK_DIR"
    log_info "  Limpo legado: $LEGACY_IOS_WORK_DIR"
  fi

  log_success "Limpeza concluída!"
  echo ""
}

# Exibe o uso do script
show_usage() {
  echo ""
  echo -e "${CYAN}Uso:${NC}"
  echo "  ./change_icons.sh <flavor> [flavor2 ...]"
  echo "  ./change_icons.sh --all"
  echo "  ./change_icons.sh --clean --all"
  echo "  ./change_icons.sh --flavor <flavor> --icon <path>"
  echo ""
  echo -e "${CYAN}Flavors disponíveis:${NC}"
  echo "  development | staging | production"
  echo ""
  echo -e "${CYAN}Opções:${NC}"
  echo "  --all       Processa todos os flavors que possuem ícone"
  echo "  --clean     Limpa ícones gerados antes de regenerar"
  echo "  --init      Cria estrutura de pastas de exemplo"
  echo ""
  echo -e "${CYAN}Exemplos:${NC}"
  echo "  ./change_icons.sh development"
  echo "  ./change_icons.sh staging production"
  echo "  ./change_icons.sh --all"
  echo "  ./change_icons.sh --clean --all"
  echo "  ./change_icons.sh --flavor development --icon assets/icons/dev_icon.png"
  echo ""
  echo -e "${CYAN}Estrutura de ícones esperada:${NC}"
  echo "  assets/icons/"
  echo "  ├── development/"
  echo "  │   └── icon.png       (mínimo 1024x1024)"
  echo "  ├── staging/"
  echo "  │   └── icon.png"
  echo "  └── production/"
  echo "      └── icon.png"
  echo ""
  echo -e "${CYAN}Como funciona:${NC}"
  echo "  O pacote flutter_launcher_icons detecta flavors automaticamente"
  echo "  via arquivos separados: flutter_launcher_icons-<flavor>.yaml"
  echo "  O AndroidManifest.xml usa @mipmap/$ANDROID_ICON_NAME"
  echo ""
}

# Gera o YAML de configuração para UM flavor específico
# Cada flavor gera um arquivo: flutter_launcher_icons-<flavor>.yaml
generate_flavor_yaml_file() {
  local flavor="$1"
  local icon="$2"
  local yaml_file
  yaml_file=$(yaml_file_for_flavor "$flavor")
  local foreground="$ICONS_DIR/$flavor/icon_foreground.png"
  local background="$ICONS_DIR/$flavor/icon_background.png"
  local ios_icon

  if ! prepare_ios_icon "$icon" "$flavor"; then
    return 1
  fi
  ios_icon="$PREPARED_IOS_ICON"

  cat > "$yaml_file" <<EOF
# Gerado automaticamente por change_icons.sh
# Para regenerar: ./change_icons.sh --all
#
# Flavor: $flavor
# Ícone: $icon
flutter_launcher_icons:
  image_path: "$icon"
  image_path_ios: "$ios_icon"

  android: "$ANDROID_ICON_NAME"
  min_sdk_android: 21

  ios: true
  remove_alpha_ios: false
EOF

  # Ícone adaptativo (Android) — adiciona se existirem
  if [ -f "$foreground" ] && [ -f "$background" ]; then
    cat >> "$yaml_file" <<EOF

  adaptive_icon_foreground: "$foreground"
  adaptive_icon_background: "$background"
EOF
  fi

  # Adiciona timestamp
  echo "" >> "$yaml_file"
  echo "## Gerado em: $(date '+%Y-%m-%d %H:%M:%S')" >> "$yaml_file"
}

# Atualiza .pbxproj do iOS com o AppIcon correto por flavor
# O flutter_launcher_icons nem sempre atualiza o .pbxproj automaticamente,
# então esta função garante que cada build config use o AppIcon correto.
update_pbxproj_appicon() {
  local pbxproj="ios/Runner.xcodeproj/project.pbxproj"

  if [ ! -f "$pbxproj" ]; then
    log_warn "Arquivo .pbxproj não encontrado — configuração iOS manual necessária"
    return
  fi

  log_step "Atualizando .pbxproj com AppIcon por flavor..."

  for flavor in "${SELECTED_FLAVORS[@]}"; do
    local appicon_name="AppIcon-${flavor}"

    # Skip if already configured
    if grep -q "\"${appicon_name}\"" "$pbxproj" 2>/dev/null; then
      log_info "  $flavor → já configurado"
      continue
    fi

    # Use awk to find build config sections matching the flavor and update APPICON
    # Sections look like: SomeID /* Debug-development */ = {
    #   ...
    #   ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
    awk -v flavor="-${flavor} " -v appicon="${appicon_name}" '
    {
      if (index($0, "/* ") > 0 && index($0, flavor) > 0 && index($0, "*/") > 0 && index($0, "= {") > 0) {
        in_section = 1
      }
      if (in_section && index($0, "ASSETCATALOG_COMPILER_APPICON_NAME") > 0) {
        sub(/ASSETCATALOG_COMPILER_APPICON_NAME = [^;]+/, "ASSETCATALOG_COMPILER_APPICON_NAME = \"" appicon "\"")
        in_section = 0
      }
      if (index($0, "};") > 0) {
        in_section = 0
      }
      print
    }' "$pbxproj" > "${pbxproj}.tmp" && mv "${pbxproj}.tmp" "$pbxproj"

    # Verify
    if grep -q "\"${appicon_name}\"" "$pbxproj" 2>/dev/null; then
      log_success "  $flavor → $appicon_name"
    else
      log_warn "  $flavor → falha ao atualizar .pbxproj"
    fi
  done
}

# Cria a estrutura de diretórios de exemplo
create_sample_structure() {
  log_info "Criando estrutura de diretórios de ícones..."
  for flavor in "${VALID_FLAVORS[@]}"; do
    mkdir -p "$ICONS_DIR/$flavor"
    log_success "  $ICONS_DIR/$flavor/"
  done
  echo ""
  log_warn "Adicione os arquivos 'icon.png' (mínimo 1024x1024) em cada pasta de flavor."
  log_info "Formatos suportados: .png (recomendado), .jpg, .jpeg"
  echo ""
}

# =============================================================================
# Entrada principal
# =============================================================================

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🎨  change_icons.sh            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# --- Sem argumentos ---
if [ $# -eq 0 ]; then
  show_usage
  exit 0
fi

# --- Parse flag --clean (pode vir antes de qualquer comando) ---
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--clean" ]; then
    CLEAN_MODE=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

# --- Modo --init: cria estrutura de pastas ---
if [ "$1" = "--init" ]; then
  create_sample_structure
  exit 0
fi

# --- Modo --flavor --icon ---
if [ "$1" = "--flavor" ]; then
  if [ -z "$2" ]; then
    log_error "Especifique o flavor após --flavor"
    show_usage
    exit 1
  fi

  SINGLE_FLAVOR="$2"

  if ! is_valid_flavor "$SINGLE_FLAVOR"; then
    log_error "Flavor inválido: '$SINGLE_FLAVOR'"
    echo "  Flavors válidos: ${VALID_FLAVORS[*]}"
    exit 1
  fi

  CUSTOM_ICON=""
  if [ "$3" = "--icon" ]; then
    if [ -z "$4" ]; then
      log_error "Especifique o caminho do ícone após --icon"
      exit 1
    fi
    CUSTOM_ICON="$4"
  fi

  SELECTED_FLAVORS=("$SINGLE_FLAVOR")
  SELECTED_ICONS=("$(icon_path_for_flavor "$SINGLE_FLAVOR" "$CUSTOM_ICON")")

# --- Modo --all ---
elif [ "$1" = "--all" ]; then
  SELECTED_FLAVORS=()
  SELECTED_ICONS=()

  for flavor in "${VALID_FLAVORS[@]}"; do
    icon=$(icon_path_for_flavor "$flavor" "")
    if [ -f "$icon" ]; then
      SELECTED_FLAVORS+=("$flavor")
      SELECTED_ICONS+=("$icon")
      log_info "Encontrado: $flavor → $icon"
    else
      log_warn "Pulando '$flavor': ícone não encontrado em $icon"
    fi
  done

  if [ ${#SELECTED_FLAVORS[@]} -eq 0 ]; then
    log_error "Nenhum ícone encontrado em $ICONS_DIR/"
    echo ""
    echo "  Execute './change_icons.sh --init' para criar a estrutura de pastas."
    exit 1
  fi

# --- Modo lista de flavors ---
else
  SELECTED_FLAVORS=()
  SELECTED_ICONS=()

  for arg in "$@"; do
    if ! is_valid_flavor "$arg"; then
      log_error "Flavor desconhecido: '$arg'"
      echo "  Flavors válidos: ${VALID_FLAVORS[*]}"
      exit 1
    fi

    icon=$(icon_path_for_flavor "$arg" "")
    SELECTED_FLAVORS+=("$arg")
    SELECTED_ICONS+=("$icon")
  done
fi

# --- Validação dos ícones ---
echo ""
log_step "Verificando ícones..."
for i in "${!SELECTED_FLAVORS[@]}"; do
  flavor="${SELECTED_FLAVORS[$i]}"
  icon="${SELECTED_ICONS[$i]}"

  if ! check_icon_exists "$icon" "$flavor"; then
    exit 1
  fi

  log_success "  $flavor → $icon"
done

# --- Limpeza (se --clean foi passado) ---
if [ "$CLEAN_MODE" = true ]; then
  echo ""
  clean_generated_icons
fi

# --- Remove YAML de flavors NÃO selecionados (para evitar processamento indesejado)
# O pacote auto-detecta TODOS os flutter_launcher_icons-*.yaml — então
# precisamos garantir que só existam os dos flavors selecionados
echo ""
log_step "Gerando arquivos YAML por flavor..."

# Remove YAMLs de flavors não selecionados
for flavor in "${VALID_FLAVORS[@]}"; do
  yaml_file=$(yaml_file_for_flavor "$flavor")
  is_selected=false
  for sel in "${SELECTED_FLAVORS[@]}"; do
    if [ "$sel" = "$flavor" ]; then
      is_selected=true
      break
    fi
  done
  if [ "$is_selected" = false ] && [ -f "$yaml_file" ]; then
    rm "$yaml_file"
    log_warn "Removido $yaml_file (flavor não selecionado)"
  fi
done

# Remove o YAML principal (o pacote ignora ele quando existem flavor files)
if [ -f "flutter_launcher_icons.yaml" ]; then
  rm "flutter_launcher_icons.yaml"
fi

# Gera YAML para cada flavor selecionado
for i in "${!SELECTED_FLAVORS[@]}"; do
  flavor="${SELECTED_FLAVORS[$i]}"
  icon="${SELECTED_ICONS[$i]}"
  generate_flavor_yaml_file "$flavor" "$icon"
  yaml_file=$(yaml_file_for_flavor "$flavor")
  log_success "  $yaml_file → $icon"
done

# --- Exibir flavors que serão processados ---
echo ""
log_step "Flavors a processar:"
for i in "${!SELECTED_FLAVORS[@]}"; do
  echo "  • ${SELECTED_FLAVORS[$i]} → ${SELECTED_ICONS[$i]}"
done

# --- Exibir configuração Android/iOS ---
echo ""
log_info "Android: cada flavor gera @mipmap/$ANDROID_ICON_NAME em android/app/src/<flavor>/res/"
log_info "iOS: cada flavor gera AppIcon-<flavor>.appiconset e atualiza o .pbxproj"

# --- Executa o gerador de ícones ---
echo ""
log_step "Executando dart run flutter_launcher_icons..."
echo ""

if dart run flutter_launcher_icons; then
  echo ""
  log_success "Ícones gerados com sucesso!"

  # Atualiza .pbxproj do iOS com AppIcon correto por flavor
  echo ""
  update_pbxproj_appicon

  echo ""
  echo -e "  ${CYAN}Flavors processados:${NC}"
  for flavor in "${SELECTED_FLAVORS[@]}"; do
    echo "    ✅ $flavor"
  done

  echo ""
  echo -e "  ${CYAN}Resultado Android:${NC}"
  for flavor in "${SELECTED_FLAVORS[@]}"; do
    local_dir="android/app/src/$flavor/res"
    count=$(find "$local_dir" -name "${ANDROID_ICON_NAME}.png" 2>/dev/null | wc -l | tr -d ' ')
    echo "    📁 $local_dir → $count ícones"
  done

  echo ""
  echo -e "  ${CYAN}Resultado iOS:${NC}"
  ios_assets="ios/Runner/Assets.xcassets"
  for flavor in "${SELECTED_FLAVORS[@]}"; do
    appiconset="$ios_assets/AppIcon-${flavor}.appiconset"
    if [ -d "$appiconset" ]; then
      count=$(find "$appiconset" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
      echo "    📁 AppIcon-${flavor}.appiconset → $count ícones"
    else
      echo "    ⚠️  AppIcon-${flavor}.appiconset não encontrado"
    fi
  done

  # Verifica se .pbxproj foi atualizado
  echo ""
  echo -e "  ${CYAN}iOS .pbxproj:${NC}"
  for flavor in "${SELECTED_FLAVORS[@]}"; do
    if grep -q "AppIcon-${flavor}" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null; then
      echo "    ✅ $flavor → ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-${flavor}"
    else
      echo "    ⚠️  $flavor → .pbxproj NÃO atualizado (pode precisar configurar manualmente)"
    fi
  done
else
  echo ""
  log_error "Falha ao gerar ícones."
  exit 1
fi

echo ""
