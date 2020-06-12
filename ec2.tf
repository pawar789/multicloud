provider "aws" {
         
 region    =  "ap-south-1"
 profile   =   "rajat"
}



resource "aws_security_group" "tasksg" {
  name        = "tasksg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-f89a8790"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "tasksg"
  }
}




resource "aws_instance" "taskinstance" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name=        "mykey1111"
  security_groups= [ "tasksg" ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/hp/Downloads/mykey1111.pem")
    host     = aws_instance.taskinstance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  
   tags = {
    Name = "taskinstance"
  }


}

output  "myoutaztask1" {
	value = aws_instance.taskinstance.availability_zone
}


resource "aws_ebs_volume" "taskebs" {
  availability_zone = aws_instance.taskinstance.availability_zone
  size              = 1

  tags = {
    Name = "taskebs"
  }
}


resource "aws_volume_attachment" "taskattach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.taskebs.id
  instance_id = aws_instance.taskinstance.id
}




resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.taskattach,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/hp/Downloads/mykey1111.pem")
    host     = aws_instance.taskinstance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/pawar789/multicloud.git /var/www/html/"
    ]
  }
}










