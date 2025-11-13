resource "aws_key_pair" "dev" {
  key_name   = "localstack-key"
  public_key = file("${path.module}/id_rsa_localstack.pub")
}

resource "aws_vpc" "v" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "s" {
  vpc_id            = aws_vpc.v.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "sg" {
  name   = "allow-8080-22"
  vpc_id = aws_vpc.v.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "keycloak" {
  ami                    = "ami-1234567890abcdef0" # REQUIRED for LocalStack
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.s.id
  key_name               = aws_key_pair.dev.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = file("${path.module}/userdata/keycloak_install.sh")
}
