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

module "kasmvnc" {
  source  = "registry.coder.com/coder/kasmvnc/coder"
  version = "~> 1.2"

  agent_id            = coder_agent.main.id
  desktop_environment = "xfce"
  subdomain           = false

  depends_on = [coder_script.kde_xstartup]
}

resource "docker_image" "workspace" {
  name = "codercom/enterprise-desktop"
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