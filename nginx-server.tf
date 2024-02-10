#VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Declare the data source
data "aws_availability_zones" "available" {}

# subnet
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for ${data.aws_availability_zones.available.names[0]}"
  }
}

# create security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = [22, 80]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}



# create ssh key in AWS
resource "aws_key_pair" "nginx-server-key" {
  key_name   = "nginx-key"
  public_key = file("${path.module}/id_rsa.pub")
}

# output "printkey" {
#   value = aws_key_pair.nginx-server-key.public_key
# }


# Create ec2 instance with the ssh key
resource "aws_instance" "nginx_server" {
  ami                    = "ami-06b72b3b2a773be2b"
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = aws_key_pair.nginx-server-key.key_name

  tags = {
    Name = "nginx-server"
  }
}




resource "null_resource" "name" {

  #ssh into instance
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/id_rsa")
    host        = aws_instance.nginx_server.public_ip
  }


  provisioner "local-exec" {
    command = "echo [nginx-server] > inventory"
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.nginx_server.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.privateKey} >> inventory"
  }

  provisioner "local-exec" {
    command = "ansible-playbook nginx.yaml"
  }

  provisioner "local-exec" {
    command = "curl http://${aws_instance.nginx_server.public_ip}:80"
  }
}

output "nginx_ip" {
  value = aws_instance.nginx_server.public_ip
}
