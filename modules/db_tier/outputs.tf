
output db_instance {
  description = "the id of the subnet"
  value = "${aws_instance.db.private_ip}"
}
