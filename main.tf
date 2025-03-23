# Provider Info
provider "aws" {
    profile = "default"
    region = "us-east-1"
  
}

# Resource Info
resource "aws_instance" "app_server" {
    ami = "ami-08b5b3a93ed654d19"
    instance_type = "t2.micro"
    key_name = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [ aws_security_group.terraform-sg.id ]
    user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOF

    tags = {
        Name = "james_instance"
    }
  
}

# Provide key pair resource. A key pair is used to control login access to EC2 instances
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.rsa-key-pem.public_key_openssh

}


# Creates a PEM formatted private and public key
resource "tls_private_key" "rsa-key-pem" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Generates a local file and will write the private key pem to the file
resource "local_file" "priv-key" {
  content  = tls_private_key.rsa-key-pem.private_key_pem
  filename = "terraform-private-key"
}


resource "aws_security_group" "terraform-sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_tls"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]

  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}


output "instance_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP of the EC2 instance"
}

output "instance_subnet_id" {
  value = aws_instance.app_server.subnet_id
}