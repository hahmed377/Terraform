variable "vpc_id" {
  description = "the vpc to launch the resource to"
}
variable "name" {
  description = "name of the database"
}
variable "db_ami_id" {
  description = "the ami id of the database"
}
variable "app_sg" {
  description = "security group for app"
}
variable "app_subnet_cidr_block" {
  description = "security group for app"
}
