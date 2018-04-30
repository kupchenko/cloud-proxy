variable aws_profile {
  type = "string"
  default = "default"
}

variable aws_region {
  type = "string"
  default = "us-west-1"
}

variable aws_ami {
  type = "string"
  default = "ami-97785bed"
}

provider "aws" {
    alias = "default"
    region = "${var.aws_region}"
    profile = "${var.aws_profile}"
}

resource "aws_key_pair" "default" {
    provider = "aws.default"
    key_name   = "kupchenko"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfUbbV/lToAL54wnHXun6tSFp9yCH/3xxLb9Yi/bF9g5Wm7sqnojyAwmhYSckTzK/++Jl0miVmkyC5GcaweWjUiqpTdNkBR2n7xWNQ0jN875O0qUuGzd8Vs5IPjU0v5XiIe2XuL+qrbj74XhUbPeOgLHqZR5/lZvhj6TCqVR7nX2E3Axlli8gVmBPF7kK+meBJWAYkYMFd7lYETvOOu4Fyrb21e3hHAxk0c7sMVHHiEWVA6mORCqq+25lsBtL9HWYHRN1me049SQj6wK1PgBOe5XTH9nu+g/w3FL1m7xRP4KO4AlYaHvCKT1oAw+0AHCGE1AaaODvTiZ8qDwhqfBCV kupchenko@gmail.com"
}

resource "aws_vpc" "tf-vpc" {
    provider = "aws.default"
    enable_dns_support = true
    enable_dns_hostnames = true
    assign_generated_ipv6_cidr_block = true
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "tf-subnet" {
    provider = "aws.default"
    vpc_id = "${aws_vpc.tf-vpc.id}"
    cidr_block = "${cidrsubnet(aws_vpc.tf-vpc.cidr_block, 4, 1)}"
    map_public_ip_on_launch = true
    ipv6_cidr_block = "${cidrsubnet(aws_vpc.tf-vpc.ipv6_cidr_block, 8, 1)}"
    assign_ipv6_address_on_creation = true
}

resource "aws_internet_gateway" "tf-igw" {
    provider = "aws.default"
    vpc_id = "${aws_vpc.tf-vpc.id}"
}

resource "aws_default_route_table" "tf-rt" {
    provider = "aws.default"
    default_route_table_id = "${aws_vpc.tf-vpc.default_route_table_id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tf-igw.id}"
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = "${aws_internet_gateway.tf-igw.id}"
    }
}

resource "aws_route_table_association" "tf-rt-a" {
    provider = "aws.default"
    subnet_id      = "${aws_subnet.tf-subnet.id}"
    route_table_id = "${aws_default_route_table.tf-rt.id}"
}

resource "aws_security_group" "tf-sg" {
    provider = "aws.default"
    name = "ssh-from-anywhere"
    vpc_id = "${aws_vpc.tf-vpc.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_instance" "tf-instance" {
    provider = "aws.default"
    ami = "${var.aws_ami}"
    key_name = "kupchenko"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.tf-subnet.id}"
    ipv6_address_count = 1
    vpc_security_group_ids = ["${aws_security_group.tf-sg.id}"]
    tags {
        Name = "proxy-001"
    }
    depends_on = ["aws_internet_gateway.eu-central-1"]
}

output "eu-central-1 public IPv4" {
  value = "${aws_instance.tf-instance.public_ip}"
}

output "eu-central-1 IPv6" {
  value = ["${aws_instance.tf-instance.ipv6_addresses}"]
}
