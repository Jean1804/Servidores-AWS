provider "aws" {
    region = "us-east-1"
    access_key = "AKIASTO3UJGY2DERDQWH"
    secret_key = "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"
}

resource "aws_eip" "web" {
  vpc = true
}

# Instalación Docker + Git
resource "aws_instance" "web" {
    ami = "ami-005f9685cb30f234b"
    instance_type = "t2.micro"
    key_name = "uresoft_key"
    vpc_security_group_ids = [aws_security_group.web.id]
    associate_public_ip_address = true

    user_data = <<-EOF
      #!/bin/bash
      sudo ip route add default via ${aws_internet_gateway.web.id}
      set -o errexit
      sudo yum update -y
      sudo yum install -y git
      sudo amazon-linux-extras install docker -y
      sudo service docker start
      sudo usermod -aG docker ec2-user
      sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      git clone https://github.com/Jean1804/Estudiantes.git /home/ec2-user/Estudiantes
      cd /home/ec2-user/Estudiantes
      sudo systemctl enable docker.service
      sudo systemctl start docker
      sudo chmod 666 /var/run/docker.sock
      docker-compose up -d
      EOF
    tags = {
        Name = "Servidor Terraform + Jenkins"
    }  
}

#Instalación Jenkins
resource "aws_instance" "Jenkins_Server" {
  ami           = "ami-005f9685cb30f234b"
  instance_type = "t2.micro"
  key_name      = "uresoft_key"
  vpc_security_group_ids = [aws_security_group.jenkins_server.id]
  associate_public_ip_address = true

  #security_groups = ["${aws_security_group.jenkins_server.name}"]

  user_data = <<EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install java-openjdk11 -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
              sudo yum install -y jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              EOF

  tags = {
    Name = "Jenkins Server"
  }
}

#Reglas de Servidor Terraform

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id
}

resource "aws_security_group" "web" {
  name_prefix = "web"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
}

#Reglas de Entradas en Servidor Jenkins
resource "aws_security_group" "jenkins_server" {
  name_prefix = "jenkins_server-"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "web" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "web-vpc"
  }

}

resource "aws_vpc" "jenkins_server" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins_server-vpc"
  }

}


output "public_ip" {
  value       = aws_instance.web.public_ip
}
