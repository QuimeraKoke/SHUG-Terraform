variable "AMI_ID" {
	type = "string"
}

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}

data "aws_availability_zones" "all" {}

data "aws_security_group" "http-ssh" {
	filter {
		name = "tag:Name"
		values = ["HTTP/S-SSH"]
	}
} 

resource "aws_launch_configuration" "example" {
  image_id = "${var.AMI_ID}"
  instance_type = "t2.micro"
  security_groups = ["${data.aws_security_group.http-ssh.id}"]


  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1e"]

  min_size = 2
  max_size = 10

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "SHUG-ASG-example"
    propagate_at_launch = true
  }
}


resource "aws_elb" "example" {
  name = "SHUG-ELB"
  security_groups = ["${data.aws_security_group.http-ssh.id}"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1e"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
}

output "address" {
  value = "${aws_elb.example.dns_name}"
}

output "holita" {
  value = ["${data.aws_availability_zones.all.*.names}"]
}

output "holit" {
  value = "${data.aws_security_group.http-ssh.id}"
}
