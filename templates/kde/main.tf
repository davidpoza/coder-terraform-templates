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
}

# App del escritorio KDE (sin subdominios)
resource "coder_app" "kde" {
  agent_id     = coder_agent.main.id
  slug         = "kde"
  display_name = "KDE Desktop"
  icon         = "/icon/desktop.svg"
  url          = "http://localhost:3000/"
  share        = "owner"

  healthcheck {
    url       = "http://localhost:3000/"
    interval  = 10
    threshold = 30
  }
}

resource "docker_image" "kde" {
  name = var.image
}

resource "docker_volume" "config" {
  name = "coder-${data.coder_workspace.me.id}-kde-config"
}

resource "docker_container" "kde" {
  name  = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}-kde"
  image = docker_image.kde.name

  # Recomendado por linuxserver/webtop para buen rendimiento del escritorio
  shm_size = 1024

  # Persistencia del /config (ajustes del escritorio, etc.)
  volumes {
    volume_name    = docker_volume.config.name
    container_path = "/config"
  }

  # Autenticación básica (recomendado si no hay reverse proxy)
  env = [
    "TZ=Europe/Madrid",
    "CUSTOM_USER=${var.auth_user}",
    "PASSWORD=${var.auth_password}",
  ]

  # Web UI
  ports {
    internal = 3000
    external = 0
  }

  # (Opcional) HTTPS interno del contenedor
  # ports {
  #   internal = 3001
  #   external = 0
  # }

  # GPU AMD/Intel por /dev/dri
  dynamic "devices" {
    for_each = var.enable_dri ? ["/dev/dri"] : []
    content {
      host_path      = devices.value
      container_path = devices.value
      permissions    = "rwm"
    }
  }
}