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
  sensitive    = true
}

locals {
  host_mount_path              = trimspace(var.host_mount_path)
  host_mount_uid               = trimspace(var.host_mount_uid)
  git_email                    = trimspace(data.coder_parameter.git_email.value)
  github_ssh_private_key       = replace(trimspace(data.coder_parameter.github_ssh_private_key.value), "\\n", "\n")
  github_ssh_private_key_base64 = local.github_ssh_private_key != "" ? base64encode(local.github_ssh_private_key) : ""
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  startup_script = <<-EOT
    set -eu

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
  name = "ghcr.io/davidpoza/dps-desktop:latest"
}

resource "docker_volume" "coder_home" {
  name = "coder-${data.coder_workspace.me.id}-home"
}

resource "docker_container" "workspace" {
  name  = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  image = docker_image.workspace.name

  user       = local.host_mount_path != "" ? local.host_mount_uid : "coder"
  privileged = true

  shm_size   = 2048
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
