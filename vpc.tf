provider "aws" {
  region     = "ap-south-1"
  profile    = "fayazlinux"
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "fayaz-vpc"
  }
}


resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "fayaz-pub-1a"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.2.0/24"

  tags = {
    Name = "fayaz-prvt-1b"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "fayaz-int-gw"
  }
}



resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block       = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "fayaz-public"
  }
}


resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}






resource "aws_security_group" "fayaz_grp" {
  name         = "fayaz_grp"
  description  = "allow ssh and httpd and mysql"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPD Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  ingress {
    description = "HTTPD Port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  ingress {
    description = "Icmp"
    from_port   =  0
    to_port     =  0
    protocol    =  -1
    cidr_blocks = ["0.0.0.0/0"]
  } 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "fayaz_sec_grp"
  }
}
variable ssh_key_name {
default = "keywithtf"
}

resource "tls_private_key" "key-pair" {
algorithm = "RSA"
rsa_bits = 4096

}



resource "local_file" "private-key" {
content = tls_private_key.key-pair.private_key_pem
filename = "${var.ssh_key_name}.pem"
file_permission = "0400"

}


resource "aws_key_pair" "deployer" {
key_name   = var.ssh_key_name
public_key = tls_private_key.key-pair.public_key_openssh

}


resource "aws_instance" "web" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  subnet_id   = "${aws_subnet.subnet1.id}"
  associate_public_ip_address  = true
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids =  [ "${aws_security_group.fayaz_grp.id}" ]
  tags = {
    Name = "fayazOS"
  }

}

resource "aws_instance" "mysql-os" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id   = "${aws_subnet.subnet2.id}"
  
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids =  [ "${aws_security_group.fayaz_grp.id}" ]
  tags = {
    Name = "fayazOS-mysql"
  }

}






