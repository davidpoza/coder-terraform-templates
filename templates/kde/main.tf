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

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  startup_script = <<-EOT
    set -eux

    export DEBIAN_FRONTEND=noninteractive
    apt-get update

    # Base gráfica para KasmVNC + XFCE
    apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal dbus-x11 xauth \
    xorg x11-xserver-utils x11-utils \
    fonts-dejavu

    # (opcional) utilidades para comprobar aceleración
    apt-get install -y --no-install-recommends mesa-utils

    rm -rf /var/lib/apt/lists/*
    EOT
}

# Escritorio por navegador (KasmVNC). XFCE = más ligero.
module "kasmvnc" {
  source  = "registry.coder.com/coder/kasmvnc/coder"
  version = "~> 1.2"

  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"
  subdomain           = false
}

resource "docker_image" "workspace" {
  name = "codercom/example-base:ubuntu"
}

resource "docker_container" "workspace" {
  name  = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  image = docker_image.workspace.name

  # root simplifica permisos y evita líos de grupos dentro del contenedor
  user = "0"

  shm_size  = 2048
  entrypoint = ["sh", "-lc"]
  command    = [coder_agent.main.init_script]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "TZ=Europe/Madrid",
  ]

  dynamic "devices" {
    for_each = var.enable_dri ? ["/dev/dri"] : []
    content {
      host_path      = devices.value
      container_path = devices.value
      permissions    = "rwm"
    }
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