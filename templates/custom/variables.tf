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

variable "dri_card" {
  type        = string
  description = "Nodo DRI de tarjeta a usar en el contenedor (ej. /dev/dri/card0)."
  default     = "/dev/dri/card1"
}

variable "dri_render_gid" {
  type        = string
  description = "GID del nodo renderD del host (ej. 993) para group_add del contenedor."
  default     = "993"
}

variable "mesa_driver_override" {
  type        = string
  description = "Driver Mesa a forzar (AMD suele ser radeonsi)."
  default     = "radeonsi"
}

variable "image" {
  type        = string
  description = "Imagen del escritorio."
  default     = "ghcr.io/davidpoza/dps-desktop:latest"
}

variable "host_mount_path" {
  type        = string
  description = "Ruta de mount en el host para activar usuario por UID."
  default     = ""
}

variable "host_mount_uid" {
  type        = string
  description = "UID a usar dentro del contenedor cuando hay host mount."
  default     = "root"
}
