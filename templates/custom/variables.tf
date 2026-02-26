variable "enable_dri" {
  type        = bool
  description = "Mapea /dev/dri para aceleración gráfica (AMD/Intel)."
  default     = true
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