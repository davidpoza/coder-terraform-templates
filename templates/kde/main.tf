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

# App escritorio Kasm
module "kasmvnc" {
  source  = "registry.coder.com/coder/kasmvnc/coder"
  version = "~> 1.2"

  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"   # xfce = más rápido
  subdomain           = false
}

resource "docker_image" "workspace" {
  name = "ubuntu:24.04"
}

resource "docker_container" "workspace" {
  name  = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
  image = docker_image.workspace.name

  # Ejecutar como root simplifica permisos GPU
  user = "0"

  entrypoint = ["sh", "-c", coder_agent.main.init_script]

  shm_size = 2048

  # GPU AMD / Intel
  devices {
    host_path      = "/dev/dri"
    container_path = "/dev/dri"
    permissions    = "rwm"
  }

}