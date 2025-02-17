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

variable "gcp_region" {
  description = "The GCP region."
  type        = string
}

variable "gcp_vpc_name" {
  description = "The GCP VPC name."
  type        = string
}

variable "gcp_router_name" {
  description = "The GCP VPN router name."
  type        = string
}

variable "azure_public_ip_1" {
  type        = string
  description = "The Azure Subscription ID"
}

variable "azure_public_ip_2" {
  type        = string
  description = "The Azure Subscription ID"
}

variable "gcp_bgp_asn" {
  description = "The GCP VPC Router ASN"
  type        = string
  default     = "65534"
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}