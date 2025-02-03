variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The Region of the Google Cloud project."
  type        = string
}

variable "project_id_trusted" {
  description = "The ID of trusted the Google Cloud project."
  type        = string
}

variable "shared_vpc" {
  type = string
}

variable "shared_vpc_project" {
  type = string
}

variable "shared_subnet" {
  type = string
}

variable "ic_vpc_name" {
  type = string
}
