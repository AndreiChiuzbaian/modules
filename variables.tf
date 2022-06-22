variable "service_bus" {
  type = any
  default = null
}

variable "client_project_code" {
  type = string
  default = null
}

variable "client_apps" {
  type = list(string)
  default = []
}

variable "client_envs" {
  type = list(string)
  default = []
}

variable "key_vault_ids" {
  type = list(string)
  default = []
}

variable "topics_to_create" {
  type = list(string)
  default = []
}

variable "topics" {
  type = set(object({
    name  = string
    subscriptions = list(string)
  }))
  default = []
}
