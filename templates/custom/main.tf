terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "coder" {}
provider "docker" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "git_email" {
  name         = "git_email"
  display_name = "[Git] Email"
  description  = "Email para git config --global user.email."
  type         = "string"
  default      = ""
  mutable      = true
}

data "coder_parameter" "github_ssh_private_key" {
  name         = "github_ssh_private_key"
  display_name = "[GitHub] SSH private key"
  description  = "Pega tu clave privada SSH (id_ed25519) para clonar repos por SSH."
  type         = "string"
  default      = ""
  mutable      = true
}

locals {
  host_mount_path              = trimspace(var.host_mount_path)
  host_mount_uid               = trimspace(var.host_mount_uid)
  dri_card                     = trimspace(var.dri_card)
  dri_node                     = trimspace(var.dri_node)
  git_email                    = trimspace(data.coder_parameter.git_email.value)
  github_ssh_private_key       = replace(trimspace(data.coder_parameter.github_ssh_private_key.value), "\\n", "\n")
  github_ssh_private_key_base64 = local.github_ssh_private_key != "" ? base64encode(local.github_ssh_private_key) : ""
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  startup_script = <<-EOT
    set -eu

    # Levantar dbus (Chrome/Electron emiten errores si falta).
    if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
      sudo mkdir -p /run/dbus
      sudo dbus-daemon --system --fork || true
    fi

    if [ "${tostring(var.enable_dri)}" = "true" ]; then
      runtime_uid=$(id -u)
      runtime_user=$(id -un 2>/dev/null || echo "")

      if [ ! -e "${local.dri_card}" ] || [ ! -e "${local.dri_node}" ]; then
        echo "GPU warning: nodos DRI configurados no presentes."
        echo "  DRI card esperado:  ${local.dri_card}"
        echo "  DRI node esperado:  ${local.dri_node}"
        echo "  Nodos disponibles en /dev/dri:"
        ls -l /dev/dri 2>/dev/null || true
      fi

      # Alinear grupos/ACL de todos los nodos DRI presentes (card* y renderD*).
      for dev in /dev/dri/renderD* /dev/dri/card*; do
        [ -e "$dev" ] || continue

        dev_gid=$(stat -c '%g' "$dev" 2>/dev/null || echo "")
        if [ -n "$dev_gid" ]; then
          dev_group=$(getent group "$dev_gid" | cut -d: -f1)
          if [ -z "$dev_group" ]; then
            dev_group="hostgpu_$dev_gid"
            if ! getent group "$dev_group" >/dev/null; then
              sudo groupadd -g "$dev_gid" "$dev_group" || true
            fi
          fi
          if [ -n "$runtime_user" ] && getent passwd "$runtime_user" >/dev/null 2>&1; then
            sudo usermod -aG "$dev_group" "$runtime_user" || true
            sudo chown "$runtime_user:$runtime_user" "$dev" 2>/dev/null || true
          fi
        fi

        if command -v setfacl >/dev/null 2>&1; then
          sudo setfacl -m "u:$runtime_uid:rw" "$dev" 2>/dev/null || true
        fi

        # Fallback para entornos donde setfacl/usermod no aplican en caliente.
        sudo chmod a+rw "$dev" 2>/dev/null || true
      done

      # Modo VirtualGL: asegurar vglrun disponible en la ruta esperada por Kasm.
      if [ ! -x /opt/VirtualGL/bin/vglrun ] && [ ! -x /usr/bin/vglrun ]; then
        if command -v apt-get >/dev/null 2>&1; then
          candidate="$(apt-cache policy virtualgl 2>/dev/null | awk '/Candidate:/ {print $2}' | head -n1)"
          if [ -z "$candidate" ] || [ "$candidate" = "(none)" ]; then
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://packagecloud.io/dcommander/virtualgl/gpgkey | sudo gpg --dearmor -o /etc/apt/keyrings/virtualgl.gpg || true
            sudo chmod a+r /etc/apt/keyrings/virtualgl.gpg || true
            echo "deb [signed-by=/etc/apt/keyrings/virtualgl.gpg] https://packagecloud.io/dcommander/virtualgl/any any main" | sudo tee /etc/apt/sources.list.d/virtualgl.list >/dev/null || true
          fi
          sudo apt-get update -y || true
          sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends virtualgl || true
        fi
      fi
      if [ -x /opt/VirtualGL/bin/vglrun ] && [ ! -x /usr/local/bin/vglrun ]; then
        sudo ln -sf /opt/VirtualGL/bin/vglrun /usr/local/bin/vglrun || true
      fi
      if [ -x /usr/bin/vglrun ]; then
        sudo mkdir -p /opt/VirtualGL/bin
        sudo ln -sf /usr/bin/vglrun /opt/VirtualGL/bin/vglrun
        sudo ln -sf /usr/bin/vglrun /usr/local/bin/vglrun
      fi
      if ! command -v vglrun >/dev/null 2>&1; then
        echo "GPU warning: vglrun no encontrado. Instala virtualgl en la imagen base."
      fi

      # Wrapper para arrancar Chrome sobre VirtualGL en modo GLX/X11.
      mkdir -p "$HOME/.local/bin"
      cat > "$HOME/.local/bin/chrome-gpu" <<'CHROME_GPU'
#!/bin/sh
exec vglrun -d "$${KASM_EGL_CARD:-/dev/dri/card1}" google-chrome \
  --no-sandbox \
  --disable-gpu-sandbox \
  --disable-dev-shm-usage \
  --enable-features=UseOzonePlatform \
  --ozone-platform=x11 \
  --use-gl=angle \
  --use-angle=default \
  --ignore-gpu-blocklist \
  --user-data-dir=/tmp/chrome-gpu-profile \
  "$@"
CHROME_GPU
      chmod +x "$HOME/.local/bin/chrome-gpu"
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [ -n "${local.github_ssh_private_key_base64}" ]; then
      printf '%s' '${local.github_ssh_private_key_base64}' | base64 -d | tr -d '\r' > "$HOME/.ssh/id_ed25519"
      chmod 600 "$HOME/.ssh/id_ed25519"
    fi

    touch "$HOME/.ssh/known_hosts"
    chmod 600 "$HOME/.ssh/known_hosts"
    ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null || ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

    if [ -n "${local.git_email}" ]; then
      git config --global user.email "${local.git_email}"
    fi
  EOT
}

module "kasmvnc" {
  source  = "registry.coder.com/coder/kasmvnc/coder"
  version = "~> 1.2"

  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"
  subdomain           = false
}

resource "docker_image" "workspace" {
  name = var.image
}

resource "docker_volume" "coder_home" {
  name = "coder-${data.coder_workspace.me.id}-home"
}

resource "docker_container" "workspace" {
  name  = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  image = docker_image.workspace.name

  user       = local.host_mount_path != "" ? local.host_mount_uid : "coder"
  privileged = true
  group_add  = var.enable_dri ? compact(["video", "render", var.dri_render_gid]) : []

  shm_size   = 2048
  entrypoint = ["sh", "-lc"]
  command    = [coder_agent.main.init_script]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "TZ=Europe/Madrid",
    "LIBGL_ALWAYS_SOFTWARE=0",
    "VGL_DISPLAY=${local.dri_card}",
    "KASM_EGL_CARD=${local.dri_card}",
    "KASM_RENDERD=${local.dri_node}",
  ]

  dynamic "devices" {
    for_each = var.enable_dri ? compact([
      "/dev/dri",
      var.enable_amd_kfd ? "/dev/kfd" : "",
    ]) : []
    content {
      host_path      = devices.value
      container_path = devices.value
      permissions    = "rwm"
    }
  }

  volumes {
    volume_name    = docker_volume.coder_home.name
    container_path = "/home/coder"
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
