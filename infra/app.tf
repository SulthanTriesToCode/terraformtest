resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "m4.large"

  key_name = aws_key_pair.admin.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  subnet_id = aws_subnet.public1.id

  tags = {
    Name = "app"
    lb_security_group_id = aws_security_group.app.id
  }
}

resource "aws_security_group" "app" {
  name = "a2_app"

  # SSH
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP in 
  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL in
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS out
  egress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL out
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
