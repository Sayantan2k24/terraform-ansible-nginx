variable "region" {}

variable "access_key" {
  description = "my aws_access_key_id"
}

variable "secret_key" {
  description = "my aws_secret_access_key"
}

variable "publicKey" {
  type    = string
  default = "./id_rsa.pub"
}

variable "privateKey" {
  type    = string
  default = "./id_rsa"
}