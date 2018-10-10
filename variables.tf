variable "name" {
  default="app-hanad"
}

variable "db_ami_id" {
  default="ami-0fc457fe0e90a6289"
}

variable "app_ami_id" {
  default="ami-0e510ca515b493960"
}

variable "cidr_block" {
  default="10.10.0.0/16"
}

variable "internal" {
  description = "should the ELB be internal or external"
  default = "false"
}
variable "zone_id" {
  default = "Z3CCIZELFLJ3SC"
}
