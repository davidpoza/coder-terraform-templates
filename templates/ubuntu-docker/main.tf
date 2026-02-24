terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

variable "docker_socket" {
  default     = "unix:///var/run/docker.sock"
  description = "(Optional) Docker socket URI (use unix:// prefix)"
  type        = string
}

variable "users_storage" {
  default     = ""
  description = "Ruta base para storage de usuarios (ej. $TF_VAR_users_storage)."
  type        = string
}

variable "default_repo_url" {
  default     = ""
  description = "Repositorio Git por defecto (ej. $TF_VAR_default_repo_url)."
  type        = string
}

variable "opencode_default_base_url" {
  default     = ""
  description = "Base URL OpenAI-compatible por defecto (si no se define en parámetros)."
  type        = string
}

variable "mks_key_endpoint" {
  default     = ""
  description = "Endpoint para solicitar keys MakeSpace (autoprovision)."
  type        = string
}


# ================================
#   Parámetros visibles en Coder
# ================================

data "coder_parameter" "p01_enable_gpu" {
  name         = "01_enable_gpu"
  display_name = "[Compute] GPU"
  description  = "Activa --gpus all en el contenedor."
  type         = "bool"
  default      = false
  mutable      = true
}

data "coder_parameter" "p01_enable_dri" {
  name         = "01_enable_dri"
  display_name = "[Compute] DRI (/dev/dri)"
  description  = "Mapea /dev/dri para aceleracion grafica (Intel/AMD o NVIDIA via EGL/GL)."
  type         = "bool"
  default      = false
  mutable      = true
}

data "coder_parameter" "p02_expose_ports" {
  name         = "02_00_expose_ports"
  display_name = "[Network] Exponer puertos del host"
  description  = "Mapea un rango de puertos del host hacia el workspace. Elige un rango alto y raro para evitar colisiones."
  type         = "bool"
  default      = false
  mutable      = true
}

data "coder_parameter" "p02_port_range_start" {
  name         = "02_01_port_range_start"
  display_name = "[Network] Puerto inicial a exponer"
  description  = "Puerto inicial del rango publicado cuando expones puertos."
  type         = "number"
  default      = 15000
  mutable      = true
}

data "coder_parameter" "p02_port_range_end" {
  name         = "02_02_port_range_end"
  display_name = "[Network] Puerto final a exponer"
  description  = "Puerto final (incluido) del rango publicado cuando expones puertos."
  type         = "number"
  default      = 15050
  mutable      = true
}

data "coder_parameter" "p03_persist_home_storage" {
  name         = "03_01_persist_home_storage"
  display_name = "[Storage] Persistir home en el host"
  description  = "Monta /home/coder en TF_VAR_users_storage/<usuario>/<workspace>. Si no lo activas, /home/coder se guarda en un volumen Docker; si el workspace esta apagado y se limpia Docker en el host, ese volumen puede desaparecer."
  type         = "bool"
  default      = false
  mutable      = true
}

data "coder_parameter" "p03_persist_projects_storage" {
  name         = "03_02_persist_projects_storage"
  display_name = "[Storage] Persistir solo ~/Projects"
  description  = "Monta /home/coder/Projects en TF_VAR_users_storage/<usuario>/<workspace>/Projects."
  type         = "bool"
  default      = false
  mutable      = true
}

data "coder_parameter" "p03_host_mount_path" {
  name         = "03_03_host_mount_path"
  display_name = "[Storage] Montar ruta host en ~/host"
  description  = "Ruta del host que se monta en /home/coder/host dentro del workspace."
  type         = "string"
  default      = ""
  mutable      = true
}

data "coder_parameter" "p03_host_mount_uid" {
  name         = "03_04_host_mount_uid"
  display_name = "[Storage] Especificar UID para montar la ruta host"
  description  = "UID para ejecutar el contenedor cuando montas ~/host. Por defecto 1000."
  type         = "string"
  default      = "1000"
  mutable      = true
}

data "coder_parameter" "p04_git_repo_url" {
  name         = "04_git_repo_url"
  display_name = "[Code] Repositorio Git (opcional)"
  description  = "URL para clonar en ~/Projects/<repo> en el primer arranque."
  type         = "string"
  default      = var.default_repo_url
  mutable      = true
}

data "coder_parameter" "p05_claude_token" {
  name         = "05_claude_token"
  display_name = "[AI/Claude] Token"
  description  = "Token de Claude (oauth). Si se rellena se usa Claude y se omite el módulo OpenCode. Obténlo con `claude setup-token`."
  type         = "string"
  default      = ""
  mutable      = true
}

data "coder_parameter" "p05_autoprovision_mks_key" {
  name         = "05_autoprovision_mks_key"
  display_name = "[AI/OpenCode] Provisionar API_KEY de MakeSpace automáticamente"
  description  = "Genera y precarga una API key de MakeSpace (30 días) y exporta MKS_BASE_URL/MKS_API_KEY. Desactiva si prefieres aportar tu URL/key."
  type         = "bool"
  default      = true
  mutable      = true
}

data "coder_parameter" "p05_opencode_provider_url" {
  name         = "05_opencode_provider_url"
  display_name = "[AI/OpenAI] Base URL (opcional)"
  description  = "Base URL compatible con OpenAI (ej. https://api.tu-proveedor.com/v1)."
  type         = "string"
  default      = ""
  mutable      = true
}

data "coder_parameter" "p05_opencode_api_key" {
  name         = "05_opencode_api_key"
  display_name = "[AI/OpenAI] API key (opcional)"
  description  = "API key para el proveedor OpenAI compatible. Activa la casilla de autoprovisionado para usar una llave MakeSpace."
  type         = "string"
  default      = ""
  mutable      = true
}

data "coder_parameter" "p06_vscode_extensions" {
  name         = "06_vscode_extensions"
  display_name = "[Code] Extensiones VS Code (preinstalar)"
  description  = "Lista separada por comas de extensiones a preinstalar en VS Code/code-server."
  type         = "string"
  default      = join(", ", local.vscode_extensions_default)
  mutable      = true
}

locals {
  username             = data.coder_workspace_owner.me.name
  workspace_image      = "ghcr.io/makespacemadrid/coder-mks-developer:latest"
  port_range           = data.coder_parameter.p02_expose_ports.value ? range(data.coder_parameter.p02_port_range_start.value, data.coder_parameter.p02_port_range_end.value + 1) : []
  enable_gpu           = data.coder_parameter.p01_enable_gpu.value
  enable_dri           = data.coder_parameter.p01_enable_dri.value
  persist_home_storage           = data.coder_parameter.p03_persist_home_storage.value
  persist_projects_storage       = data.coder_parameter.p03_persist_projects_storage.value
  host_mount_path                = trimspace(data.coder_parameter.p03_host_mount_path.value)
  host_mount_uid                 = trimspace(data.coder_parameter.p03_host_mount_uid.value)
  workspace_storage_root         = trimspace(var.users_storage)
  workspace_storage_home         = local.workspace_storage_root != "" ? "${local.workspace_storage_root}/${local.username}/${lower(data.coder_workspace.me.name)}" : ""
  workspace_storage_projects     = local.workspace_storage_root != "" ? "${local.workspace_storage_root}/${local.username}/${lower(data.coder_workspace.me.name)}/Projects" : ""
  home_mount_host_path           = local.persist_home_storage && local.workspace_storage_root != "" ? local.workspace_storage_home : ""
  projects_mount_host_path       = local.persist_projects_storage && local.workspace_storage_root != "" ? local.workspace_storage_projects : ""
  opencode_default_base_url      = trimspace(var.opencode_default_base_url)
  mks_key_endpoint               = trimspace(var.mks_key_endpoint)
  home_volume_resolved = "coder-${data.coder_workspace.me.id}-home"
  docker_data_volume_name = "coder-${data.coder_workspace.me.id}-docker-data"
  repo_url                = trimspace(data.coder_parameter.p04_git_repo_url.value)
  repo_name               = local.repo_url != "" ? trimsuffix(basename(local.repo_url), ".git") : ""
  default_repo_path       = local.repo_name != "" ? "/home/coder/Projects/${local.repo_name}" : "/home/coder/Projects"
  openai_base_url         = trimspace(data.coder_parameter.p05_opencode_provider_url.value)
  openai_api_key          = trimspace(data.coder_parameter.p05_opencode_api_key.value)
  auto_provision_mks_key  = data.coder_parameter.p05_autoprovision_mks_key.value
  claude_token            = trimspace(data.coder_parameter.p05_claude_token.value)
  install_claude          = trimspace(data.coder_parameter.p05_claude_token.value) != ""
  vscode_extensions_default = [
    "coder.coder-remote",
    "openai.chatgpt",
    "Anthropic.claude-code",
    "Continue.continue"
  ]
  vscode_extensions_input = trimspace(data.coder_parameter.p06_vscode_extensions.value)
  vscode_extensions = local.vscode_extensions_input != "" ? [
    for ext in split(",", local.vscode_extensions_input) : trimspace(ext)
    if trimspace(ext) != ""
  ] : local.vscode_extensions_default
  continue_default_config = file("${path.module}/continue-config.yaml")
}

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    set -e

    # Levantar dbus (necesario para apps Electron)
    if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
      sudo mkdir -p /run/dbus
      sudo dbus-daemon --system --fork || true
    fi

    # Configurar PulseAudio para soporte de audio en KasmVNC
    sudo usermod -aG audio "$USER" || true
    mkdir -p ~/.config/pulse
    if [ ! -f ~/.config/pulse/client.conf ]; then
      cat > ~/.config/pulse/client.conf <<'PULSECFG'
autospawn = yes
daemon-binary = /usr/bin/pulseaudio
enable-shm = false
PULSECFG
    fi
    # Iniciar PulseAudio si no está corriendo
    if ! pgrep -u "$USER" pulseaudio >/dev/null 2>&1; then
      pulseaudio --start --exit-idle-time=-1 || true
    fi

    # Asegurar /home/coder como HOME efectivo incluso si se ejecuta como root
    sudo mkdir -p /home/coder
    sudo chown "$USER:$USER" /home/coder || true

    if [ "${tostring(local.enable_dri)}" = "true" ]; then
      # Alinear grupos para /dev/dri (rendering GPU) sin tocar permisos del host
      for dev in /dev/dri/renderD128 /dev/dri/card0; do
        if [ -e "$dev" ]; then
          dev_gid=$(stat -c '%g' "$dev" 2>/dev/null || echo "")
          if [ -n "$dev_gid" ]; then
            dev_group=$(getent group "$dev_gid" | cut -d: -f1)
            if [ -z "$dev_group" ]; then
              dev_group="hostgpu_$dev_gid"
              if ! getent group "$dev_group" >/dev/null; then
                sudo groupadd -g "$dev_gid" "$dev_group" || true
              fi
            fi
            sudo usermod -aG "$dev_group" "$USER" || true
          fi
          if command -v setfacl >/dev/null 2>&1; then
            sudo setfacl -m "u:$USER:rw" "$dev" 2>/dev/null || true
          fi
        fi
      done
    fi

    # Asegurar permisos de pipx para el usuario actual
    sudo mkdir -p /opt/pipx /opt/pipx/bin
    sudo chown -R "$USER:$USER" /opt/pipx || true

    # Configurar PATH para .local/bin (siempre útil)
    mkdir -p /home/coder/.local/bin
    if [ ! -f /home/coder/.profile ]; then
      echo '# ~/.profile: executed by the command interpreter for login shells.' > /home/coder/.profile
      echo 'if [ -n "$BASH_VERSION" ]; then' >> /home/coder/.profile
      echo '    if [ -f "$HOME/.bashrc" ]; then' >> /home/coder/.profile
      echo '        . "$HOME/.bashrc"' >> /home/coder/.profile
      echo '    fi' >> /home/coder/.profile
      echo 'fi' >> /home/coder/.profile
    fi

    # Solo configurar OpenCode si NO se está usando Claude Code
    if [ "${tostring(local.install_claude)}" = "false" ]; then
      # Symlink de opencode cuando se instale bajo /root
      if [ -d /root/.opencode ] && [ ! -e /home/coder/.opencode ]; then
        sudo ln -s /root/.opencode /home/coder/.opencode || true
      fi
      # Añadir OpenCode CLI al PATH
      if ! grep -q "/.opencode/bin" /home/coder/.profile 2>/dev/null; then
        echo 'export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"' >> /home/coder/.profile
      fi
    else
      # Si usamos Claude Code, solo añadir .local/bin al PATH
      if ! grep -q "/.local/bin" /home/coder/.profile 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/coder/.profile
      fi
    fi

    # Alinear binarios instalados como root (ej. jupyter)
    sudo mkdir -p /home/coder/.local/bin
    # Fuerza enlace al path de pipx aunque aún no exista; se arregla cuando pipx instale jupyterlab
    sudo ln -sf /opt/pipx/bin/jupyter-lab /home/coder/.local/bin/jupyter-lab || true
    for path in /root/.local/bin/jupyter-lab /usr/local/bin/jupyter-lab; do
      if [ -x "$path" ]; then
        sudo ln -sf "$path" /home/coder/.local/bin/jupyter-lab || true
      fi
    done
    sudo chown -R "$USER:$USER" /home/coder/.local || true

    mkdir -p ~/Projects
    if [ -n "$${DEFAULT_REPO_PATH:-}" ]; then
      mkdir -p "$DEFAULT_REPO_PATH"
    fi
    python3 - <<'PY'
import json
import os

paths = [
    os.path.expanduser("~/Projects/.vscode/settings.json"),
    os.path.expanduser("~/.vscode-server/data/Machine/settings.json"),
]
for path in paths:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = {}
    if os.path.exists(path):
        try:
            with open(path) as f:
                data = json.load(f)
        except Exception:
            data = {}
    data["terminal.integrated.cwd"] = "/home/coder/Projects"
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
PY
    if [ ! -f "$HOME/Projects/.vscode/extensions.json" ]; then
      mkdir -p "$HOME/Projects/.vscode"
      cat > "$HOME/Projects/.vscode/extensions.json" <<'VSCODEEXT'
{
  "recommendations": [
${join(",\n", formatlist("    \"%s\"", local.vscode_extensions))}
  ]
}
VSCODEEXT
    fi
    mkdir -p ~/.opencode ~/.config/opencode
    if [ ! -f ~/.opencode/opencode.json ]; then
      cat > ~/.opencode/opencode.json <<'JSONCFG'
{}
JSONCFG
    fi
    ln -sf ~/.opencode/opencode.json ~/.opencode/config.json || true
    ln -sf ~/.opencode/opencode.json ~/.config/opencode/opencode.json || true

    # Inicializar /etc/skel la primera vez
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~ || true
      touch ~/.init_done
    fi

    # Refrescar accesos directos en el escritorio (si faltan)
    mkdir -p ~/Desktop
    for f in code.desktop github-desktop.desktop claude-desktop.desktop firefox.desktop google-chrome.desktop geany.desktop appimagepool.desktop; do
      src="/usr/share/applications/$f"
      if [ -f "$src" ] && [ ! -e "$HOME/Desktop/$f" ]; then
        ln -sf "$src" "$HOME/Desktop/$f"
      fi
    done
    chmod +x ~/Desktop/*.desktop 2>/dev/null || true

    # Entorno virtual de Python listo para usar
    mkdir -p "$HOME/.venvs"
    if [ ! -d "$HOME/.venvs/base" ]; then
      python3 -m venv "$HOME/.venvs/base" || true
      "$HOME/.venvs/base/bin/pip" install --upgrade pip setuptools wheel || true
    fi
    if ! grep -q "source \\$HOME/.venvs/base/bin/activate" "$HOME/.bashrc" 2>/dev/null; then
      echo 'if [ -f "$HOME/.venvs/base/bin/activate" ]; then source "$HOME/.venvs/base/bin/activate"; fi' >> "$HOME/.bashrc"
    fi

    # Autoprovisionar clave OpenCode MakeSpace si está habilitado
    auto_flag="$${AUTO_PROVISION_MKS_API_KEY:-true}"
    if [ -z "$${OPENCODE_PROVIDER_URL:-}" ] && [ -n "$${OPENCODE_DEFAULT_BASE_URL:-}" ]; then
      OPENCODE_PROVIDER_URL="$${OPENCODE_DEFAULT_BASE_URL}"
      export OPENCODE_PROVIDER_URL
    fi
    if printf '%s' "$auto_flag" | grep -Eq '^(1|true|TRUE|yes|on)$'; then
      MKS_BASE_URL="$${MKS_BASE_URL:-$OPENCODE_PROVIDER_URL}"
      export MKS_BASE_URL
      payload=""
      if [ -z "$${OPENCODE_API_KEY:-}" ]; then
        KEY_ENDPOINT="$${MKS_KEY_ENDPOINT:-}"
        if [ -z "$KEY_ENDPOINT" ]; then
          echo "MKS_KEY_ENDPOINT no configurado; omitiendo autoprovision de key" >&2
        else
        alias="coder-$(tr -dc 0-9 </dev/urandom 2>/dev/null | head -c 8 | sed 's/^$/00000000/')"
        payload=$(printf '{"email":"%s","alias":"%s"}' "$${CODER_USER_EMAIL:-}" "$alias")
        resp=$(curl -fsSL -X POST "$KEY_ENDPOINT" -H "Content-Type: application/json" -d "$payload" 2>/dev/null || true)
        key=$(printf '%s' "$resp" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("key",""))' 2>/dev/null || true)
        if [ -n "$key" ]; then
          OPENCODE_API_KEY="$key"
          export OPENCODE_API_KEY
          MKS_API_KEY="$key"
          export MKS_API_KEY
          mkdir -p /home/coder/.opencode
          printf "%s" "$key" > /home/coder/.opencode/.latest_mks_key || true
          printf "%s" "$payload" > /home/coder/.opencode/.latest_mks_request || true
        fi
      fi
      if [ -n "$${OPENCODE_API_KEY:-}" ]; then
        export OPENCODE_API_KEY
        MKS_API_KEY="$${MKS_API_KEY:-$OPENCODE_API_KEY}"
        export MKS_API_KEY
        mkdir -p /home/coder/.opencode
        if [ -n "$payload" ] && [ -n "$${OPENCODE_API_KEY:-}" ]; then
          printf "%s" "$${OPENCODE_API_KEY:-}" > /home/coder/.opencode/.latest_mks_key || true
          printf "%s" "$payload" > /home/coder/.opencode/.latest_mks_request || true
        fi
        fi
      fi
    fi

    # Propagar variables a nuevas shells interactivas
    if [ -n "$${OPENCODE_PROVIDER_URL:-}" ]; then
      MKS_BASE_URL="$${MKS_BASE_URL:-$OPENCODE_PROVIDER_URL}"
      export MKS_BASE_URL
      if ! grep -q "MKS_BASE_URL=" ~/.bashrc 2>/dev/null; then
        echo "export MKS_BASE_URL=\"$MKS_BASE_URL\"" >> ~/.bashrc
      fi
      if ! grep -q "OPENCODE_PROVIDER_URL=" ~/.bashrc 2>/dev/null; then
        echo "export OPENCODE_PROVIDER_URL=\"$OPENCODE_PROVIDER_URL\"" >> ~/.bashrc
      fi
    fi
    if [ -n "$${OPENCODE_API_KEY:-}" ]; then
      MKS_API_KEY="$${MKS_API_KEY:-$OPENCODE_API_KEY}"
      export MKS_API_KEY
      if ! grep -q "MKS_API_KEY=" ~/.bashrc 2>/dev/null; then
        echo "export MKS_API_KEY=\"$MKS_API_KEY\"" >> ~/.bashrc
      fi
      if ! grep -q "OPENCODE_API_KEY=" ~/.bashrc 2>/dev/null; then
        echo "export OPENCODE_API_KEY=\"$OPENCODE_API_KEY\"" >> ~/.bashrc
      fi
    fi

    # Instalar OpenCode CLI si Claude está activo (sin módulo)
    if printf '%s' "$${INSTALL_CLAUDE:-false}" | grep -Eq '^(1|true|TRUE|yes|on)$'; then
      if ! command -v opencode >/dev/null 2>&1; then
        echo ">> Installing OpenCode CLI (Claude active, module disabled)..."
        curl -fsSL https://opencode.ai/install | bash || true
      fi
    fi

    # Configuración de Continue solo cuando se autoprovisiona la key OpenAI-compatible
    if printf '%s' "$${AUTO_PROVISION_MKS_API_KEY:-false}" | grep -Eq '^(1|true|TRUE|yes|on)$' \
      && [ -n "$${MKS_API_KEY:-}" ] && [ -n "$${MKS_BASE_URL:-}" ]; then
      if [ ! -f ~/.continue/config.yaml ]; then
        mkdir -p ~/.continue
        cat > ~/.continue/config.yaml <<'CONTINUECFG'
${local.continue_default_config}
CONTINUECFG
        sed -i "s|MKS_BASE_PLACEHOLDER|$${MKS_BASE_URL}|g" ~/.continue/config.yaml
        sed -i "s|MKS_API_KEY_PLACEHOLDER|$${MKS_API_KEY}|g" ~/.continue/config.yaml
      fi
    fi

    # Script para regenerar y aplicar nueva key de MakeSpace
    sudo tee /usr/local/bin/gen_mks_litellm_key >/dev/null <<'GENMKS'
#!/usr/bin/env bash
set -euo pipefail
KEY_ENDPOINT="$${MKS_KEY_ENDPOINT:-}"
PROVIDER="$${OPENCODE_PROVIDER_URL:-$${OPENCODE_DEFAULT_BASE_URL:-}}"
EMAIL="$${CODER_USER_EMAIL:-}"
alias="coder-$(tr -dc 0-9 </dev/urandom 2>/dev/null | head -c 8 | sed 's/^$/00000000/')"
if [ -z "$EMAIL" ]; then
  echo "Falta CODER_USER_EMAIL para solicitar la key" >&2
  exit 1
fi
if [ -z "$KEY_ENDPOINT" ]; then
  echo "Falta MKS_KEY_ENDPOINT para solicitar la key" >&2
  exit 1
fi
payload=$(printf '{"email":"%s","alias":"%s"}' "$EMAIL" "$alias")
resp=$(curl -fsSL -X POST "$KEY_ENDPOINT" -H "Content-Type: application/json" -d "$payload")
key=$(printf '%s' "$resp" | python3 - <<'PY'
import json,sys
try:
  print(json.load(sys.stdin).get("key",""))
except Exception:
  print("")
PY
)
if [ -z "$key" ]; then
  echo "No se obtuvo key de MakeSpace" >&2
  exit 1
fi
export OPENCODE_API_KEY="$key"
export OPENCODE_PROVIDER_URL="$PROVIDER"
export MKS_BASE_URL="$PROVIDER"
export MKS_API_KEY="$key"
mkdir -p /home/coder/.opencode
printf "%s" "$key" > /home/coder/.opencode/.latest_mks_key || true
printf "%s" "$payload" > /home/coder/.opencode/.latest_mks_request || true
python3 - <<'PY'
import json,os
path="/home/coder/.opencode/opencode.json"
data={}
if os.path.exists(path):
  try:
    with open(path) as f:
      data=json.load(f)
  except Exception:
    data={}
prov=data.setdefault("provider",{}).setdefault("custom",{}).setdefault("options",{})
prov["baseURL"]=os.environ.get("OPENCODE_PROVIDER_URL") or os.environ.get("OPENCODE_DEFAULT_BASE_URL","")
prov["apiKey"]=os.environ.get("OPENCODE_API_KEY","")
data.setdefault("default_provider","custom")
os.makedirs(os.path.dirname(path),exist_ok=True)
with open(path,"w") as f:
  json.dump(data,f,indent=2)
PY
ln -sf /home/coder/.opencode/opencode.json /home/coder/.opencode/config.json || true
echo "Nueva key guardada y aplicada"
GENMKS
    sudo chmod +x /usr/local/bin/gen_mks_litellm_key || true

    # Config inicial de OpenCode (opcional)
    if [ -n "$${OPENCODE_API_KEY:-}" ]; then
      mkdir -p /home/coder/.opencode
      cat > /home/coder/.opencode/opencode.json <<'JSONCFG'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-openai-codex-auth@4.0.2",
    "opencode-gemini-auth@latest",
    "opencode-antigravity-auth@beta",
    "opencode-agent-memory",
    "opencode-mystatus",
    "opencode-handoff"
  ],
  "provider": {
    "openai": {
      "options": {
        "reasoningEffort": "medium",
        "reasoningSummary": "auto",
        "textVerbosity": "medium",
        "include": [
          "reasoning.encrypted_content"
        ],
        "store": false
      },
      "models": {
        "gpt-5.1-codex-low": {
          "name": "GPT 5.1 Codex Low (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "low",
            "reasoningSummary": "auto",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-medium": {
          "name": "GPT 5.1 Codex Medium (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "medium",
            "reasoningSummary": "auto",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-high": {
          "name": "GPT 5.1 Codex High (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "high",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-max": {
          "name": "GPT 5.1 Codex Max (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "high",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-max-low": {
          "name": "GPT 5.1 Codex Max Low (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "low",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-max-medium": {
          "name": "GPT 5.1 Codex Max Medium (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "medium",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-max-high": {
          "name": "GPT 5.1 Codex Max High (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "high",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-max-xhigh": {
          "name": "GPT 5.1 Codex Max Extra High (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "xhigh",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-mini-medium": {
          "name": "GPT 5.1 Codex Mini Medium (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "medium",
            "reasoningSummary": "auto",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-codex-mini-high": {
          "name": "GPT 5.1 Codex Mini High (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "high",
            "reasoningSummary": "detailed",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-low": {
          "name": "GPT 5.1 Low (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "low",
            "reasoningSummary": "auto",
            "textVerbosity": "low",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-medium": {
          "name": "GPT 5.1 Medium (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "medium",
            "reasoningSummary": "auto",
            "textVerbosity": "medium",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        },
        "gpt-5.1-high": {
          "name": "GPT 5.1 High (OAuth)",
          "limit": {
            "context": 272000,
            "output": 128000
          },
          "options": {
            "reasoningEffort": "high",
            "reasoningSummary": "detailed",
            "textVerbosity": "high",
            "include": [
              "reasoning.encrypted_content"
            ],
            "store": false
          }
        }
      }
    },
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "MakeSpace IA",
      "options": {
        "baseURL": "OPENCODE_PROVIDER_URL_VALUE",
        "api_key": "OPENCODE_API_KEY_VALUE"
      },
      "models": {
        "devstral:24b": { "name": "Devstral 24b" },
        "qwen2.5-coder:14b": { "name": "Qwen2.5 Coder 14b" },
        "qwen2.5-coder:7b": { "name": "Qwen2.5 Coder 7b" },
        "qwen3-coder:30b": { "name": "Qwen3 Coder 30b" },
        "gpt-oss:20b": { "name": "GPT-OSS 20b" },
        "magistral:24b": { "name": "Magistral 24b" },
        "mistral-small3.1:24b": { "name": "Mistral Small3.1 24b" }
      }
    },
    "google": {
      "models": {
        "antigravity-claude-opus-4-5-thinking": {
          "name": "Claude Opus 4.5 Thinking (Antigravity)",
          "options": { "thinkingBudget": 10000, "includeThoughts": true }
        },
        "antigravity-claude-sonnet-4-5-thinking": {
          "name": "Claude Sonnet 4.5 Thinking (Antigravity)",
          "options": { "thinkingBudget": 5000, "includeThoughts": true }
        },
        "antigravity-gemini-3-pro": {
          "name": "Gemini 3 Pro (Antigravity)",
          "options": { "thinkingLevel": "high", "includeThoughts": true }
        },
        "antigravity-gemini-3-flash": { "name": "Gemini 3 Flash (Antigravity)" },
        "gemini-2.5-pro": {
          "name": "Gemini 2.5 Pro (Free Tier)",
          "options": { "thinkingBudget": 5000, "includeThoughts": true }
        },
        "gemini-2.5-flash": { "name": "Gemini 2.5 Flash (Free Tier)" },
        "gemini-3-pro-preview": {
          "name": "Gemini 3 Pro Preview (Free Tier)",
          "options": { "thinkingLevel": "high", "includeThoughts": true }
        },
        "gemini-3-flash-preview": { "name": "Gemini 3 Flash Preview (Free Tier)" }
      }
    }
  }
}
JSONCFG
      base_url="$${OPENCODE_PROVIDER_URL:-$${OPENCODE_DEFAULT_BASE_URL:-}}"
      sed -i "s|OPENCODE_PROVIDER_URL_VALUE|$base_url|g" /home/coder/.opencode/opencode.json
      sed -i "s|OPENCODE_API_KEY_VALUE|$${OPENCODE_API_KEY}|g" /home/coder/.opencode/opencode.json
      chown -R "$USER:$USER" /home/coder/.opencode || true
    fi

    # --------------------------------------------------------------------------------
    # UV: instalador universal para CLIs Python (opcional)
    # --------------------------------------------------------------------------------
    if ! command -v uv >/dev/null 2>&1; then
      echo ">> Installing uv (Python package/CLI installer)..."
      curl -LsSf https://astral.sh/uv/install.sh | sh || true

      # Intentar dejar uv en el PATH del sistema
      if [ -f "/root/.local/bin/uv" ]; then
        sudo ln -sf /root/.local/bin/uv /usr/local/bin/uv || true
      fi
      if [ -f "$HOME/.local/bin/uv" ]; then
        sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv || true
      fi

      hash -r || true
    fi

    # --------------------------------------------------------------------------------
    # Docker in Docker: preparar cgroup v2 para anidar contenedores con límites
    # --------------------------------------------------------------------------------
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
      echo ">> Enabling cgroup v2 delegation for DinD..."
      sudo mkdir -p /sys/fs/cgroup/init
      if [ ! -w /sys/fs/cgroup/init/cgroup.procs ] || [ ! -w /sys/fs/cgroup/cgroup.subtree_control ]; then
        echo ">> cgroup v2 not writable; skipping delegation (likely already handled by host)"
      else
        for _ in $(seq 1 20); do
          sudo xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true
          if sudo sh -c 'sed -e "s/ / +/g" -e "s/^/+/" < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control'; then
            break
          fi
          sleep 0.1
        done
      fi
    fi

    # --------------------------------------------------------------------------------
    # Docker in Docker: arrancar dockerd si no está corriendo
    # --------------------------------------------------------------------------------
    if ! pgrep dockerd >/dev/null 2>&1; then
      echo ">> Starting dockerd (DinD)..."
      sudo dockerd --host=unix:///var/run/docker.sock --storage-driver=overlay2 >/tmp/dockerd.log 2>&1 &
      for i in $(seq 1 30); do
        if sudo docker info >/dev/null 2>&1; then
          echo ">> dockerd ready"
          break
        fi
        sleep 1
      done
    fi
  EOT

  env = {
    GIT_AUTHOR_NAME            = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL           = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME         = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL        = data.coder_workspace_owner.me.email
    HOME                       = "/home/coder"
    OPENCODE_PROVIDER_URL      = local.openai_base_url
    OPENCODE_API_KEY           = local.openai_api_key
    OPENCODE_DEFAULT_BASE_URL  = local.opencode_default_base_url
    MKS_KEY_ENDPOINT           = local.mks_key_endpoint
    MKS_BASE_URL               = local.openai_base_url
    MKS_API_KEY                = local.openai_api_key
    AUTO_PROVISION_MKS_API_KEY = tostring(local.auto_provision_mks_key)
    CODER_USER_EMAIL           = data.coder_workspace_owner.me.email
    INSTALL_CLAUDE             = tostring(local.install_claude)
    AGENTAPI_CHAT_BASE_PATH    = local.install_claude ? "/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.id}/apps/ccw/chat" : "/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.id}/apps/opencode/chat"
    DEFAULT_REPO_PATH          = local.default_repo_path
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    script       = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | \
      awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "7_swap_host"
    script       = <<EOT
      free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024/1024/1024, $2/1024/1024/1024) }'
    EOT
    interval     = 10
    timeout      = 1
  }
}

# ---------------------------------------------------------------
# MÓDULOS DE CODER
# ---------------------------------------------------------------

# Script de preparación de pipx (debe ejecutarse antes de jupyterlab)
resource "coder_script" "setup_pipx" {
  agent_id           = coder_agent.main.id
  display_name       = "Setup pipx environment"
  icon               = "/icon/folder.svg"
  script             = <<-EOT
    #!/bin/bash
    set -e
    # Asegurar que /opt/pipx existe con permisos correctos
    sudo mkdir -p /opt/pipx /opt/pipx/bin
    sudo chown -R coder:coder /opt/pipx || true
    echo "✓ pipx environment ready"
  EOT
  run_on_start       = true
  start_blocks_login = false
}

# Script para crear venv y kernel por defecto de JupyterLab
resource "coder_script" "setup_jupyter_kernel" {
  agent_id           = coder_agent.main.id
  display_name       = "Setup Jupyter kernel"
  icon               = "/icon/folder.svg"
  script             = <<-EOT
    #!/bin/bash
    set -e

    VENV_DIR="$HOME/.venvs/jupyter"
    KERNEL_NAME="coder-py"
    DISPLAY_NAME="Python (coder)"

    if [ ! -d "$VENV_DIR" ]; then
      python3 -m venv "$VENV_DIR"
    fi

    "$VENV_DIR/bin/python" -m pip install --upgrade pip
    "$VENV_DIR/bin/python" -m pip install --upgrade ipykernel
    "$VENV_DIR/bin/python" -m ipykernel install --user --name "$KERNEL_NAME" --display-name "$DISPLAY_NAME"

    python3 - <<'PY'
from pathlib import Path

config = Path.home() / ".jupyter" / "jupyter_server_config.py"
config.parent.mkdir(parents=True, exist_ok=True)

block = """# >>> coder-managed-kernel
try:
    c
except NameError:
    c = get_config()

c.MappingKernelManager.default_kernel_name = "coder-py"
try:
    c.MultiKernelManager.default_kernel_name = "coder-py"
except Exception:
    pass
# <<< coder-managed-kernel
"""

text = config.read_text() if config.exists() else ""
start = text.find("# >>> coder-managed-kernel")
end = text.find("# <<< coder-managed-kernel")

if start != -1 and end != -1 and end > start:
    end += len("# <<< coder-managed-kernel")
    new = text[:start] + block + text[end:]
else:
    new = text.rstrip()
    if new:
        new += "\n\n"
    new += block + "\n"

config.write_text(new)
PY

    echo "✓ Jupyter kernel '$KERNEL_NAME' ready"
  EOT
  run_on_start       = true
  start_blocks_login = false
}

module "code-server" {
  count      = data.coder_workspace.me.start_count
  source     = "registry.coder.com/coder/code-server/coder"
  version    = "~> 1.1"
  agent_id   = coder_agent.main.id
  folder     = "/home/coder/Projects"
  extensions = local.vscode_extensions
  order      = 1
}

module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-config/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

module "git-clone" {
  count    = data.coder_parameter.p04_git_repo_url.value != "" ? data.coder_workspace.me.start_count : 0
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "~> 1.2"
  agent_id = coder_agent.main.id
  url      = data.coder_parameter.p04_git_repo_url.value
  base_dir = "~/Projects"
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "~> 1.1"
  agent_id = coder_agent.main.id
}

module "tmux" {
  source   = "registry.coder.com/anomaly/tmux/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

module "kasmvnc" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/coder/kasmvnc/coder"
  version             = "~> 1.2"
  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"
  subdomain           = true
}

module "github-upload-public-key" {
  count    = 0 # Deshabilitado temporalmente (external-auth no configurado)
  source   = "registry.coder.com/coder/github-upload-public-key/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

module "cursor" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/cursor/coder"
  version  = "~> 1.4"
  agent_id = coder_agent.main.id
}

module "filebrowser" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/filebrowser/coder"
  version  = "~> 1.1"
  agent_id = coder_agent.main.id
  folder   = "/home/coder"
}

module "opencode" {
  count          = local.install_claude ? 0 : 1
  source         = "registry.coder.com/coder-labs/opencode/coder"
  version        = "~> 0.1"
  agent_id       = coder_agent.main.id
  workdir        = "/home/coder/Projects"
  report_tasks   = true
  cli_app        = false
}

module "claude-code" {
  count                   = local.install_claude ? 1 : 0
  source                  = "registry.coder.com/coder/claude-code/coder"
  version                 = "~> 4.2"
  agent_id                = coder_agent.main.id
  workdir                 = "/home/coder/Projects"
  claude_code_oauth_token = local.claude_token
  subdomain               = false
  report_tasks            = true
  depends_on              = [module.opencode]
}

module "antigravity" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/antigravity/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/Projects"
}

module "jupyterlab" {
  count      = data.coder_workspace.me.start_count
  source     = "registry.coder.com/coder/jupyterlab/coder"
  version    = "~> 1.2"
  agent_id   = coder_agent.main.id
  depends_on = [coder_script.setup_pipx, coder_script.setup_jupyter_kernel]
}

resource "coder_ai_task" "opencode_task" {
  app_id = local.install_claude ? module.claude-code[0].task_app_id : module.opencode[0].task_app_id
  depends_on = [module.opencode, module.claude-code]
}

# ---------------------------------------------------------------
# HOME Y DOCKER DATA PERSISTENTES
# ---------------------------------------------------------------

resource "docker_volume" "home_volume" {
  count = local.home_mount_host_path == "" ? 1 : 0
  name  = local.home_volume_resolved

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_volume" "docker_data" {
  count = 1
  name  = local.docker_data_volume_name

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "null_resource" "ensure_host_paths" {
  count = (local.home_mount_host_path != "" || local.projects_mount_host_path != "" || local.host_mount_path != "") ? 1 : 0
  triggers = {
    home     = local.home_mount_host_path
    projects = local.projects_mount_host_path
    host     = local.host_mount_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      if [ -n "${self.triggers.home}" ]; then mkdir -p "${self.triggers.home}"; fi
      if [ -n "${self.triggers.projects}" ]; then mkdir -p "${self.triggers.projects}"; fi
      if [ -n "${self.triggers.host}" ]; then mkdir -p "${self.triggers.host}"; fi
    EOT
  }
}

# ---------------------------------------------------------------
# CONTENEDOR PRINCIPAL DEL WORKSPACE (DinD)
# ---------------------------------------------------------------

resource "docker_container" "workspace" {
  depends_on = [null_resource.ensure_host_paths]
  image = local.workspace_image

  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name

  user = local.host_mount_path != "" ? local.host_mount_uid : "coder"

  privileged = true

  entrypoint = [
    "sh",
    "-c",
    <<-EOT
      set -e
      mkdir -p /home/coder/.opencode /home/coder/.config/opencode
      if [ ! -f /home/coder/.opencode/opencode.json ]; then
        printf '{}' > /home/coder/.opencode/opencode.json
      fi
      ln -sf /home/coder/.opencode/opencode.json /home/coder/.opencode/config.json || true
      ln -sf /home/coder/.opencode/opencode.json /home/coder/.config/opencode/opencode.json || true
      ${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
    EOT
  ]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "TZ=Europe/Madrid",
    "NVIDIA_VISIBLE_DEVICES=${local.enable_gpu ? "all" : ""}",
    "NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video"
  ]
  gpus = local.enable_gpu ? "all" : null
  dynamic "devices" {
    for_each = local.enable_dri ? ["/dev/dri"] : []
    content {
      host_path      = devices.value
      container_path = devices.value
      permissions    = "rwm"
    }
  }

  # Solo mapea puertos si expose_ports = true
  dynamic "ports" {
    for_each = local.port_range
    content {
      internal = ports.value
      external = ports.value
      ip       = "0.0.0.0"
    }
  }

  shm_size = 2 * 1024 * 1024 * 1024

  dynamic "mounts" {
    for_each = local.home_mount_host_path != "" ? [local.home_mount_host_path] : []
    content {
      target = "/home/coder"
      type   = "bind"
      source = mounts.value
    }
  }

  dynamic "volumes" {
    for_each = local.home_mount_host_path == "" ? [local.home_volume_resolved] : []
    content {
      container_path = "/home/coder"
      volume_name    = volumes.value
    }
  }

  dynamic "mounts" {
    for_each = local.projects_mount_host_path != "" ? [local.projects_mount_host_path] : []
    content {
      target = "/home/coder/Projects"
      type   = "bind"
      source = mounts.value
    }
  }

  dynamic "mounts" {
    for_each = local.host_mount_path != "" ? [local.host_mount_path] : []
    content {
      target = "/home/coder/host"
      type   = "bind"
      source = mounts.value
    }
  }

  dynamic "volumes" {
    for_each = [local.docker_data_volume_name]
    content {
      container_path = "/var/lib/docker"
      volume_name    = volumes.value
    }
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
  labels {
    label = "com.centurylinklabs.watchtower.enable"
    value = "true"
  }
  labels {
    label = "com.centurylinklabs.watchtower.scope"
    value = "coder-workspaces"
  }
}
