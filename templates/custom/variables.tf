variable "enable_dri" {
  type        = bool
  description = "Mapea /dev/dri para aceleracion grafica (AMD/Intel)."
  default     = true
}

variable "enable_amd_kfd" {
  type        = bool
  description = "Mapea /dev/kfd para passthrough AMD (ROCm/OpenCL)."
  default     = true
}

variable "dri_node" {
  type        = string
  description = "Nodo DRI de render a usar en el contenedor (ej. /dev/dri/renderD128)."
  default     = "/dev/dri/renderD128"
}

variable "auth_user" {
  type        = string
  description = "Usuario Basic Auth para el escritorio web."
}

variable "auth_password" {
  type        = string
  description = "Password Basic Auth para el escritorio web."
  sensitive   = true
}

variable "image" {
  type        = string
  description = "Imagen del escritorio KDE."
  default     = "lscr.io/linuxserver/webtop:ubuntu-kde"
}

variable "host_mount_path" {
  type        = string
  description = "Ruta de mount en el host para activar usuario por UID."
  default     = ""
}

variable "host_mount_uid" {
  type        = string
  description = "UID a usar dentro del contenedor cuando hay host mount."
  default     = "coder"
}
