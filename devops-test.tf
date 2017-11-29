output "server_url" {
  value = "http://${aws_elb.websrv.dns_name}"
}

variable "max_ec2_count" {
  description = "define the maximum of concurrent ec2 instances running behing the load balancer"
  default     = 50
}

variable "instance_type" {
  description = "choose the type of ec2 being started on the cluster"
  default     = "t2.micro"
}

variable "enable_ssh_access" {
  description = "If set to true, permit ssh access to EC2 instances"
  default     = false
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_availability_zones" "all" {}

resource "aws_key_pair" "ssh_admin" {
  key_name   = "admin"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArrZ2mCVwfKp402tdsz8Y/46XBrHqnVSFkDNB9RO5x/wcAatquVSI82GiAxvbsAEqTH64QaQDH1EscNw2x0mE4N07fAC/M208EIgn5SE8aFqtW0JXM4PIJDiVmyU0shKlTzSKQTFn66+RpL4tVEmJ//Orrmufw6owZkuqa4umL0R0H3NTwlG3+CsUa+Jqq9G3F6AvztElJOZi5vyb9Rw3K+LmkrQ2dUOo46AIt4jAhYt9CeCupJ1Hk5zzk7Zomu9ZfKQrTOBvbsYtql8erbz5eBAsp18g3QN/p7doHBFVRJtDQNc36UCfkiDS+1mhOF3aT5zkKrP2mnktcFBEDYki6w== cedric@cdj"
}

resource "aws_launch_configuration" "websrv" {
  image_id        = "ami-7e534d1a"
  instance_type   = "${var.instance_type}"
  key_name        = "${aws_key_pair.ssh_admin.key_name}"
  security_groups = ["${aws_security_group.ec2.id}"]

  user_data = <<-EOF
              #!/bin/sh
              curl -so /opt/bitnami/nginx/html/index.html https://raw.githubusercontent.com/cedrivard/DevOpsTest/master/html/index.html
              curl -so /opt/bitnami/nginx/html/aws_logo_smile_1200x630.png https://raw.githubusercontent.com/cedrivard/DevOpsTest/master/html/aws_logo_smile_1200x630.png
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "websrv" {
  launch_configuration = "${aws_launch_configuration.websrv.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.websrv.name}"]
  health_check_type = "ELB"

  min_size = 1
  max_size = "${var.max_ec2_count}"

  tag {
    key                 = "Name"
    value               = "asg-websrv"
    propagate_at_launch = true
  }
}

resource "aws_elb" "websrv" {
  name               = "asg-websrv"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    target              = "HTTP:80/"
  }
}

resource "aws_security_group" "ec2" {
  name = "websrv-ec2"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.ec2.id}"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count             = "${var.enable_ssh_access}"
  type              = "ingress"
  security_group_id = "${aws_security_group.ec2.id}"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.ec2.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "elb" {
  name = "websrv-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
