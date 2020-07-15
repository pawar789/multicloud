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
  force_detach = true
}


resource "aws_s3_bucket" "ap25bucket" {
  bucket = "ap25bucket"
  acl    = "public-read"
  
  tags = {
    Name = "ap25bucket"
  }
}


resource "aws_s3_bucket_object" "ap25bucket" {
depends_on = [
    aws_s3_bucket.ap25bucket,
  ]
  bucket = "ap25bucket"
  key    = "ap_image.jpg"
  source = "C:/Users/hp/Downloads/vasily-koloda-8CqDvPuo_kI-unsplash.jpg"
  etag = filemd5("C:/Users/hp/Downloads/vasily-koloda-8CqDvPuo_kI-unsplash.jpg")
  acl = "public-read"
  content_type = "image/jpg"

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
      "sudo git clone https://github.com/pawar789/multicloud.git /var/www/html/",
        "sudo su << EOF",
      "echo 'http://${aws_cloudfront_distribution.cloud_dist.domain_name}/${aws_s3_bucket_object.ap25bucket.key}' > /var/www/html/url.txt",
      "EOF",
      
    ]
  }
}


resource "aws_cloudfront_distribution" "cloud_dist" {
  origin {
    domain_name = aws_s3_bucket.ap25bucket.bucket_regional_domain_name
    origin_id   = "S3-ap25bucket"

    custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }

  }

  enabled             = true
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id =  "S3-ap25bucket"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
     
    }
  }

  connection {
        type    = "ssh"
        user    = "ec2-user"
        host    = aws_instance.taskinstance.public_ip
        port    = 22
        private_key =  file("C:/Users/hp/Downloads/mykey1111.pem")
    }
provisioner "remote-exec" {

        inline  = [

            "sudo su << EOF",
      "echo 'http://${aws_cloudfront_distribution.cloud_dist.domain_name}/${aws_s3_bucket_object.ap25bucket.key}' > /var/www/html/url.txt",
      "EOF",
        ]
 
}
 
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


output "cloudfront_domain_name" {
       value = aws_cloudfront_distribution.cloud_dist.domain_name
}


 resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]


provisioner "local-exec" {
        command = "firefox  ${aws_instance.taskinstance.public_ip}"
      }
}











