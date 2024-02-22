variable "location" {
  default = "Central India"
}

variable "main_resourcegroup" {
  default = "rgp1"
}

variable "log_analytics_name" {
  default = "la1"
}

variable "prefix" {
  default = "jwanztf"
}


variable "vm_name" {
  default = "ivm001"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "public_ip_name" {
  default = "pip1"
}

variable "network_interface_name" {
  default = "ni1"
}

variable "vnet_name" {
  default = "vnet1"
}

variable "subnet_name" {
  default = "subnet1"
}

variable "tfc_agent_version_vm1" {
  description = "This is the version of the agent you would like to deploy to this first node"
  type        = string
  default     = "1.14.3"
}

variable "tfc_agent_token_vm_1_agent_1" {
  description = "TFC Agent Token for the 1st agent on first node"
  type        = string

}
variable "username" {
  description = "local Admin of the terraform runner"
  type        = string

}

variable "userpassword" {
  description = "The password of the local Admin of the terraform runner"
  type        = string

}
