variable "vpc_id" {
  description = "the vpc to launch the resource to"
}
variable "name" {
  description = "the name of the user"
}
variable "user_data" {
  description = "the user data to provide to the instance"
}
variable "ig_id" {
  description = "the ig attached to the route table"
}
variable "ami_id" {
  description = "the id of the ami"
}
