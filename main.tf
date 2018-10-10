provider "aws" {
  region  = "eu-west-1"
}

# create a vpc
resource "aws_vpc" "app" {
  cidr_block = "${var.cidr_block}"

  tags {
    Name = "${var.name}"
  }
}

# internet gateway
resource "aws_internet_gateway" "app" {
  vpc_id = "${aws_vpc.app.id}"

  tags {
    Name = "${var.name}"
  }
}

module "app" {
  source = "./modules/app_tier"
  vpc_id = "${aws_vpc.app.id}"
  name = "hanad-app"
  user_data = "${data.template_file.app_init.rendered}"
  ig_id = "${aws_internet_gateway.app.id}"
  ami_id = "${var.app_ami_id}"
}
module "db" {
  source = "./modules/db_tier"
  name = "hanad-db"
  db_ami_id = "${var.db_ami_id}"
  vpc_id = "${aws_vpc.app.id}"
  app_sg = "${module.app.security_group_id}"
  app_subnet_cidr_block = "${module.app.subnet_cidr_block}"

}
# load the init template
data "template_file" "app_init" {
   template = "${file("./scripts/app/init.sh.tpl")}"
   vars {
      db_host="mongodb://${module.db.db_instance}:27017/posts"
   }
}


### load_balancers
resource "aws_security_group" "elb"  {
  name = "${var.name}-elb"
  description = "Allow all inbound traffic through port 80 and 443."
  vpc_id = "${aws_vpc.app.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.name}-elb"
  }
}

### ELB ####

resource "aws_elb" "elb" {
  name = "${var.name}-app-elb"
  subnets = ["${module.app.subnet_app_id}",]
  security_groups = ["${aws_security_group.elb.id}"]
  internal = "${var.internal}"

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  tags {
    Name = "${var.name}-elb"
  }
}

### AUTOSCALING GROUP ####

resource "aws_launch_configuration" "app" {
  name_prefix = "${var.name}-app"
  image_id = "${var.app_ami_id}"
  instance_type = "t2.micro"
  user_data = "${data.template_file.app_init.rendered}"
  security_groups = ["${module.app.security_group_id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  load_balancers = ["${aws_elb.elb.id}"]
  name = "${var.name}-${aws_launch_configuration.app.name}-app"
  # name = "${var.name}-app"
  min_size = 1
  max_size = 3
  min_elb_capacity = 1
  desired_capacity = 2
  vpc_zone_identifier = ["${module.app.subnet_app_id}"]
  launch_configuration = "${aws_launch_configuration.app.id}"
  tags {
    key = "Name"
    value = "${var.name}-app-${count.index + 1 }"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "hanadapp" {
  zone_id = "${var.zone_id}"
  name    = "hanadapp.spartaglobal.education"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.elb.dns_name}"]
}
